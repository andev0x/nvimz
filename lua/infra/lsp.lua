local M = {}

local spec = require("infra.spec")

local function on_attach(_, bufnr)
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, {
			buffer = bufnr,
			silent = true,
			desc = desc,
		})
	end

	-- Navigation
	map("gd", vim.lsp.buf.definition, "LSP: go to definition")
	map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
	map("gr", vim.lsp.buf.references, "LSP: references")
	map("gi", vim.lsp.buf.implementation, "LSP: implementation")
	map("K", vim.lsp.buf.hover, "LSP: hover")

	-- Actions
	map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
	map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

	-- Diagnostics
	map("gl", vim.diagnostic.open_float, "Diagnostics: line diagnostics")
	map("[d", vim.diagnostic.goto_prev, "Diagnostics: previous")
	map("]d", vim.diagnostic.goto_next, "Diagnostics: next")

	-- Toggle inlay hints
	if vim.lsp.inlay_hint then
		map("<leader>uh", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
		end, "LSP: toggle inlay hints")
	end

	-- Auto diagnostics popup on cursor hold
	local group = vim.api.nvim_create_augroup("LspDiagnosticsFloat", { clear = false })

	vim.api.nvim_clear_autocmds({
		group = group,
		buffer = bufnr,
	})

	vim.api.nvim_create_autocmd("CursorHold", {
		group = group,
		buffer = bufnr,
		callback = function()
			local diagnostics = vim.diagnostic.get(0, {
				lnum = vim.api.nvim_win_get_cursor(0)[1] - 1,
			})

			if #diagnostics == 0 then
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

function M.setup()
	-- Better CursorHold responsiveness without being too aggressive
	vim.opt.updatetime = 1000

	-- LSP capabilities
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	-- Uncomment if using blink.cmp
	-- capabilities = require("blink.cmp").get_lsp_capabilities()

	-- Uncomment if using nvim-cmp
	-- capabilities = require("cmp_nvim_lsp").default_capabilities()

	-- Global defaults for all LSP servers
	vim.lsp.config("*", {
		capabilities = capabilities,
		on_attach = on_attach,
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
				local util = require("lspconfig.util")
				local bufname = vim.api.nvim_buf_get_name(bufnr)

				-- Try project root markers first
				if s_spec.root_markers and #s_spec.root_markers > 0 then
					local root = util.root_pattern((table.unpack or unpack)(s_spec.root_markers))(bufname)

					if root then
						on_dir(root)
						return
					end
				end

				-- Fallback to current file directory
				local fallback = bufname ~= "" and util.path.dirname(bufname) or vim.fn.getcwd()

				on_dir(fallback)
			end,
		})

		vim.lsp.enable(name)

		::continue::
	end

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

return M
