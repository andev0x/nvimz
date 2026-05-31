local M = {}

function M.setup(client, bufnr)
	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, {
			bufnr = bufnr,
		})
	end
end

return M
