-- Register extra filetype detection without eagerly loading `vim.filetype`.
-- `vim.filetype.add()` is loaded lazily by Neovim itself, so calling it here
-- only to map a single extension pulls the whole module into the startup path
-- (~1.3ms). A plain BufRead/BufNewFile autocmd keeps detection identical while
-- leaving `vim.filetype` lazy for buffers that actually need it.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = vim.api.nvim_create_augroup("nvimz_filetypes", { clear = true }),
	pattern = "*.gotmpl",
	callback = function()
		vim.bo.filetype = "gotmpl"
	end,
})
