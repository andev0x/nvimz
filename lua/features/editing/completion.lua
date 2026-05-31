local M = {}

function M.setup()
	require("mini.completion").setup({
		lsp_completion = {
			source_func = "completefunc",
			auto_setup = true,
		},
		window = {
			info = { border = "rounded" },
			signature = { border = "rounded" },
		},
	})

	-- Set up Tab/S-Tab for smooth command-line/insert completion navigation
	-- Note: Neovim 0.12+ handles Tab/S-Tab for snippets by default.
	-- We only need custom logic if we want to integrate it with pumvisible()
	-- but Neovim 0.12's default is already quite smart.
end

return M
