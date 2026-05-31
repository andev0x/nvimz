local M = {}

function M.setup(bufnr)
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

return M
