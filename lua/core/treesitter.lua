local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("native_treesitter", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		desc = "Enable native Treesitter highlighting",
		callback = function(args)
			local bufnr = args.buf

			-- Skip special buffers and invalid filetypes
			if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" then
				return
			end

			-- Skip large files for performance
			local path = vim.api.nvim_buf_get_name(bufnr)
			local ok, stats = pcall(vim.uv.fs_stat, path)

			if ok and stats and stats.size > 500 * 1024 then
				return
			end

			-- Enable Treesitter only if parser exists
			local ok, parser = pcall(vim.treesitter.get_parser, bufnr)

			if not ok or not parser then
				return
			end

			vim.treesitter.start(bufnr)

			-- Treesitter folding
			vim.bo[bufnr].foldmethod = "expr"
			vim.bo[bufnr].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.bo[bufnr].foldlevel = 99
		end,
	})
end

return M
