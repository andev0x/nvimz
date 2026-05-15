local M = {}

local spec = require("infra.spec")

-- Global override for floating windows to ensure rounded borders
local orig_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	return orig_open_floating_preview(contents, syntax, opts, ...)
end

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

function M.setup()
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

	-- LSP capabilities
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	-- Uncomment if using blink.cmp
	-- capabilities = require("blink.cmp").get_lsp_capabilities()

	-- Uncomment if using nvim-cmp
	-- capabilities = require("cmp_nvim_lsp").default_capabilities()

	-- Use LspAttach for buffer-local setup (keymaps, inlay hints)
	vim.api.nvim_create_autocmd("LspAttach", {
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

			-- Synchronize Native Semantic Tokens from LSPs (gopls)
			if client.name == "gopls" then
				if not client.server_capabilities.semanticTokensProvider then
					local semantic = client.config.capabilities.textDocument.semanticTokens
					if semantic then
						client.server_capabilities.semanticTokensProvider = {
							full = true,
							legend = {
								tokenTypes = semantic.tokenTypes,
								tokenModifiers = semantic.tokenModifiers,
							},
							range = true,
						}
					end
				end
			end

			-- Diagnostics
			map("gl", vim.diagnostic.open_float, "Diagnostics: line diagnostics")

			-- Toggle inlay hints: Enable by default if supported
			if client:supports_method("textDocument/inlayHint") then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				map("<leader>uh", function()
					vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
				end, "LSP: toggle inlay hints")
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

					-- Check if any float is already open (simplified but efficient)
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

	-- Global defaults for all LSP servers
	vim.lsp.config("*", {
		capabilities = capabilities,
	})

	for name, s_spec in pairs(spec.lsp_servers) do
		local cmd = s_spec.cmd or {}

		-- Skip setup if the language server executable is missing
		if cmd[1] and vim.fn.executable(cmd[1]) ~= 1 then
			vim.notify(string.format("LSP server '%s' not found: %s", name, cmd[1]), vim.log.levels.WARN)

			goto continue
		end

		vim.lsp.config(name, {
			cmd = s_spec.cmd,
			filetypes = s_spec.filetypes,
			settings = s_spec.settings,

			root_dir = function(bufnr, on_dir)
				local bufname = vim.api.nvim_buf_get_name(bufnr)

				-- Try project root markers first
				if s_spec.root_markers and #s_spec.root_markers > 0 then
					local root = vim.fs.root(bufnr, s_spec.root_markers)

					if root then
						on_dir(root)
						return
					end
				end

				-- Fallback to current file directory or CWD
				local fallback = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()

				on_dir(fallback)
			end,
		})

		vim.lsp.enable(name)

		::continue::
	end

	setup_diagnostics()
end

return M
