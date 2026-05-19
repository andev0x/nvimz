local group = vim.api.nvim_create_augroup("nvim_zen", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank({ timeout = 120 })
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	desc = "Equalize splits on window resize",
	command = "tabdo wincmd =",
})

-- ============================================================================
-- Neovim 0.12 FileType-Based Lazy-Start
-- ============================================================================

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Lazy-start language tools (LSP, formatters, etc.)",
	callback = function(args)
		local ft = args.match

		-- Skip special buffers
		if vim.bo[args.buf].buftype ~= "" or ft == "" then
			return
		end

		-- Silently call the startup command for the language
		-- This runs asynchronously in the background
		pcall(function()
			require("infra.lsp").start(ft, args.buf)
		end)
	end,
})
