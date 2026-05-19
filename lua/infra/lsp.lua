local M = {}

local spec = require("infra.spec")

-- Internal state to track initialized global components and enabled servers
local initialized = false
local enabled_servers = {}

-- Global override for floating windows to ensure rounded borders
local orig_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	return orig_open_floating_preview(contents, syntax, opts, ...)
end

-- LSP capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()

local function setup_diagnostics()
	vim.diagnostic.config({
		virtual_text = false,
		severity_sort = true,
		underline = true,
		update_in_insert = false,

		float = {
			border = "rounded",
			source = "if_many",
		},

		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = " ",
				[vim.diagnostic.severity.WARN] = " ",
				[vim.diagnostic.severity.HINT] = "󰠠 ",
				[vim.diagnostic.severity.INFO] = " ",
			},
		},
	})
end

local function init_global()
	if initialized then
		return
	end
	initialized = true

	-- Basic LspInfo command for native-first observability
	vim.api.nvim_create_user_command("LspInfo", function()
		local clients = vim.lsp.get_clients()
		if #clients == 0 then
			vim.notify("No active LSP clients", vim.log.levels.WARN)
			return
		end

		local lines = { "Active LSP Clients:" }
		for _, client in ipairs(clients) do
			table.insert(lines, string.format("- %s (id: %d, root: %s)", client.name, client.id, client.config.root_dir or "nil"))
			local bufs = vim.lsp.get_buffers_by_client_id(client.id)
			table.insert(lines, string.format("  Attached buffers: %s", table.concat(bufs, ", ")))
		end
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, { desc = "Show active LSP clients" })

	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd("tabnew " .. vim.lsp.get_log_path())
	end, { desc = "Open LSP log" })

	vim.api.nvim_create_user_command("LspStart", function(opts)
		local name = opts.args
		if name == "" then
			vim.notify("Usage: LspStart <server_name>", vim.log.levels.ERROR)
			return
		end
		-- Force start regardless of current filetype
		if spec.lsp_servers[name] then
			M.enable_server(name, spec.lsp_servers[name], 0)
		else
			vim.notify(string.format("LSP server '%s' not found in spec", name), vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Start LSP server",
		complete = function()
			return vim.tbl_keys(spec.lsp_servers)
		end,
	})

	vim.api.nvim_create_user_command("LspStop", function(opts)
		local name = opts.args
		local clients = name == "" and vim.lsp.get_clients({ bufnr = 0 }) or vim.lsp.get_clients({ name = name })
		for _, client in ipairs(clients) do
			client.stop()
		end
	end, {
		nargs = "?",
		desc = "Stop LSP server",
		complete = function()
			return vim.tbl_map(function(c)
				return c.name
			end, vim.lsp.get_clients())
		end,
	})

	vim.api.nvim_create_user_command("LspRestart", function()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		for _, client in ipairs(clients) do
			local name = client.name
			client.stop()
			vim.defer_fn(function()
				local bufnr = vim.api.nvim_get_current_buf()
				local ft = vim.bo[bufnr].filetype
				M.start(ft, bufnr)
			end, 500)
		end
	end, { desc = "Restart LSP clients for current buffer" })

	-- Use LspAttach for buffer-local setup (keymaps, inlay hints)
	local lsp_group = vim.api.nvim_create_augroup("LspSetup", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_group,
		callback = function(args)
			local bufnr = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client then
				return
			end

			local function map(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, {
					buffer = bufnr,
					silent = true,
					desc = desc,
				})
			end

			-- Navigation
			map("gd", vim.lsp.buf.definition, "LSP: go to definition")
			map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
			map("K", vim.lsp.buf.hover, "LSP: hover")

			-- Actions
			map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
			map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

			-- Diagnostics
			map("gl", vim.diagnostic.open_float, "Diagnostics: line diagnostics")

			-- Toggle inlay hints: Enable by default if supported
			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Optimize diagnostics popup: only create if not already exists and only on CursorHold
			local diag_group = vim.api.nvim_create_augroup("LspDiagnosticsFloat", { clear = false })
			vim.api.nvim_clear_autocmds({ group = diag_group, buffer = bufnr })

			vim.api.nvim_create_autocmd("CursorHold", {
				group = diag_group,
				buffer = bufnr,
				callback = function()
					if vim.api.nvim_get_mode().mode ~= "n" or vim.fn.getcmdwintype() ~= "" then
						return
					end

					-- Check if any float is already open
					for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
						local conf = vim.api.nvim_win_get_config(win)
						if conf.relative ~= "" and conf.focusable then
							return
						end
					end

					vim.diagnostic.open_float(nil, {
						focus = false,
						scope = "cursor",
						border = "rounded",
						close_events = { "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter" },
					})
				end,
			})
		end,
	})

	setup_diagnostics()
end

function M.enable_server(name, s_spec, bufnr)
	local cmd = s_spec.cmd or {}

	-- Skip setup if the language server executable is missing
	if cmd[1] and vim.fn.executable(cmd[1]) ~= 1 then
		-- Only warn once
		if enabled_servers[name] ~= "missing" then
			enabled_servers[name] = "missing"
			vim.notify(string.format("LSP server '%s' not found: %s", name, cmd[1]), vim.log.levels.WARN)
		end
		return
	end

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local root_dir = nil

	-- Try project root markers first
	if s_spec.root_markers and #s_spec.root_markers > 0 then
		root_dir = vim.fs.root(bufnr, s_spec.root_markers)
	end

	-- Fallback to current file directory or CWD
	if not root_dir then
		root_dir = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
	end

	vim.lsp.start({
		name = name,
		cmd = s_spec.cmd,
		root_dir = root_dir,
		settings = s_spec.settings,
		capabilities = capabilities,
	}, { bufnr = bufnr })

	enabled_servers[name] = true
end

function M.start(ft, bufnr)
	-- Ensure global setup (diagnostics, commands, etc.) is done once
	init_global()

	-- Look up and enable servers matching the current filetype
	for name, s_spec in pairs(spec.lsp_servers) do
		if s_spec.filetypes and vim.tbl_contains(s_spec.filetypes, ft) then
			M.enable_server(name, s_spec, bufnr)
		end
	end
end

-- Compatibility with old setup() call if needed, but we prefer lazy M.start(ft)
function M.setup()
	-- Do nothing or just init_global?
	-- Let's just init_global so commands are available.
	init_global()
end

return M

