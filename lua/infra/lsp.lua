local M = {}

local spec = require("infra.spec")

local function root_pattern(markers)
	if not markers or #markers == 0 then
		return nil
	end
	return require("lspconfig.util").root_pattern((table.unpack or unpack)(markers))
end

local function on_attach(_, bufnr)
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map("gd", vim.lsp.buf.definition, "LSP: go to definition")
	map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
	map("gr", vim.lsp.buf.references, "LSP: references")
	map("gi", vim.lsp.buf.implementation, "LSP: implementation")
	map("K", vim.lsp.buf.hover, "LSP: hover")
	map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
	map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
	map("<leader>e", vim.diagnostic.open_float, "Diagnostics: float")
	map("[d", vim.diagnostic.goto_prev, "Diagnostics: previous")
	map("]d", vim.diagnostic.goto_next, "Diagnostics: next")
end

function M.setup()
	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = { "gopls", "pyright", "ts_ls", "rust_analyzer" },
	})

	local servers = { "gopls", "pyright", "ts_ls", "rust_analyzer" }

	for _, server in ipairs(servers) do
		local config = {
			on_attach = on_attach,
		}

		-- Merge custom settings from spec if they exist
		for _, s in ipairs(spec.lsp_servers) do
			if s.name == server then
				config.cmd = s.cmd
				config.filetypes = s.filetypes
				config.root_dir = root_pattern(s.root_markers)
				config.settings = s.settings
				break
			end
		end

		vim.lsp.config(server, config)
		vim.lsp.enable(server)
	end

	vim.diagnostic.config({
		virtual_text = false,
		severity_sort = true,
		underline = true,
		update_in_insert = false,
		float = { border = "rounded", source = "if_many" },
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
