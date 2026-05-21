local M = {}

local spec = require("infra.spec")

-- ============================================================================
-- Internal State
-- ============================================================================

local initialized = false
local enabled_servers = {}

-- ============================================================================
-- Floating Window Border Override
-- ============================================================================

local orig_open_floating_preview = vim.lsp.util.open_floating_preview

---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"

	return orig_open_floating_preview(contents, syntax, opts, ...)
end

-- ============================================================================
-- LSP Capabilities
-- ============================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()

-- ============================================================================
-- Diagnostics
-- ============================================================================

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

-- ============================================================================
-- Utility
-- ============================================================================

local function has_focusable_float()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local config = vim.api.nvim_win_get_config(win)

		if config.relative ~= "" and config.focusable then
			return true
		end
	end

	return false
end

local function setup_lsp_keymaps(bufnr)
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
end

local function setup_inlay_hints(client, bufnr)
	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, {
			bufnr = bufnr,
		})
	end
end

local function setup_diagnostic_float(bufnr)
	local group = vim.api.nvim_create_augroup("LspDiagnosticFloat_" .. bufnr, { clear = true })

	vim.api.nvim_create_autocmd("CursorHold", {
		group = group,
		buffer = bufnr,

		callback = function()
			if vim.api.nvim_get_mode().mode ~= "n" then
				return
			end

			if vim.fn.getcmdwintype() ~= "" then
				return
			end

			if has_focusable_float() then
				return
			end

			vim.diagnostic.open_float(nil, {
				focus = false,
				scope = "cursor",
				border = "rounded",

				close_events = {
					"CursorMoved",
					"CursorMovedI",
					"BufLeave",
					"InsertEnter",
				},
			})
		end,
	})
end

-- ============================================================================
-- Global Initialization
-- ============================================================================

local function init_global()
	if initialized then
		return
	end

	initialized = true

	-- ------------------------------------------------------------------------
	-- :LspInfo
	-- ------------------------------------------------------------------------

	vim.api.nvim_create_user_command("LspInfo", function()
		local clients = vim.lsp.get_clients()

		if #clients == 0 then
			vim.notify("No active LSP clients", vim.log.levels.WARN)
			return
		end

		local lines = {
			"Active LSP Clients:",
		}

		for _, client in ipairs(clients) do
			table.insert(
				lines,
				string.format("- %s (id: %d, root: %s)", client.name, client.id, client.config.root_dir or "nil")
			)

			local attached_buffers = {}

			for bufnr, _ in pairs(client.attached_buffers) do
				table.insert(attached_buffers, bufnr)
			end

			table.insert(lines, string.format("  Attached buffers: %s", table.concat(attached_buffers, ", ")))
		end

		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, {
		desc = "Show active LSP clients",
	})

	-- ------------------------------------------------------------------------
	-- :LspLog
	-- ------------------------------------------------------------------------

	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd({
			cmd = "tabnew",
		})

		vim.cmd({
			cmd = "edit",
			args = { vim.lsp.log.get_filename() },
		})
	end, {
		desc = "Open LSP log",
	})

	-- ------------------------------------------------------------------------
	-- :LspStart
	-- ------------------------------------------------------------------------

	vim.api.nvim_create_user_command("LspStart", function(opts)
		local name = opts.args

		if name == "" then
			vim.notify("Usage: LspStart <server_name>", vim.log.levels.ERROR)

			return
		end

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

	-- ------------------------------------------------------------------------
	-- :LspStop
	-- ------------------------------------------------------------------------

	vim.api.nvim_create_user_command("LspStop", function(opts)
		local name = opts.args

		-- Stop all LSP clients attached to current buffer
		if name == "" then
			vim.lsp.stop({
				bufnr = 0,
				force = true,
			})

			return
		end

		-- Stop specific LSP server by name
		vim.lsp.stop({
			name = name,
			force = true,
		})
	end, {
		nargs = "?",

		desc = "Stop LSP server",

		complete = function()
			return vim.tbl_map(function(client)
				return client.name
			end, vim.lsp.get_clients())
		end,
	})

	-- ------------------------------------------------------------------------
	-- :LspRestart
	-- ------------------------------------------------------------------------

	vim.api.nvim_create_user_command("LspRestart", function()
		vim.lsp.stop({
			bufnr = 0,
			force = true,
		})

		vim.defer_fn(function()
			local bufnr = vim.api.nvim_get_current_buf()
			local filetype = vim.bo[bufnr].filetype

			M.start(filetype, bufnr)
		end, 500)
	end, {
		desc = "Restart LSP clients for current buffer",
	})

	-- ------------------------------------------------------------------------
	-- LspAttach
	-- ------------------------------------------------------------------------

	local lsp_group = vim.api.nvim_create_augroup("LspSetup", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_group,

		callback = function(args)
			local bufnr = args.buf

			local client = vim.lsp.get_client_by_id(args.data.client_id)

			if not client then
				return
			end

			setup_lsp_keymaps(bufnr)

			setup_inlay_hints(client, bufnr)

			setup_diagnostic_float(bufnr)
		end,
	})

	setup_diagnostics()
end

-- ============================================================================
-- Enable LSP Server
-- ============================================================================

function M.enable_server(name, s_spec, bufnr)
	local cmd = s_spec.cmd or {}

	-- Skip setup if executable does not exist
	if cmd[1] and vim.fn.executable(cmd[1]) ~= 1 then
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

	-- Fallback to file directory or current working directory
	if not root_dir then
		root_dir = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
	end

	vim.lsp.start({
		name = name,
		cmd = s_spec.cmd,
		root_dir = root_dir,
		settings = s_spec.settings,
		capabilities = capabilities,
	}, {
		bufnr = bufnr,
	})

	enabled_servers[name] = true
end

-- ============================================================================
-- Start Matching Servers For Filetype
-- ============================================================================

function M.start(filetype, bufnr)
	init_global()

	for name, s_spec in pairs(spec.lsp_servers) do
		if s_spec.filetypes and vim.tbl_contains(s_spec.filetypes, filetype) then
			M.enable_server(name, s_spec, bufnr)
		end
	end
end

-- ============================================================================
-- Compatibility Setup
-- ============================================================================

function M.setup()
	init_global()
end

return M
