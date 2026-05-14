local group = vim.api.nvim_create_augroup("nvim_zen", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Highlight yanked text",
	callback = function()
		vim.highlight.on_yank({ timeout = 120 })
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	desc = "Equalize splits on window resize",
	command = "tabdo wincmd =",
})
