local group = vim.api.nvim_create_augroup("nvim_zen", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Highlight yanked text",
	callback = function()
		vim.highlight.on_yank({ timeout = 120 })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Start native treesitter",
	callback = function(args)
		local ok, _ = pcall(vim.treesitter.start, args.buf)
		if not ok then
			-- Optional: silent failure if no parser is available
		end
	end,
})
