local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("native_treesitter", { clear = true })

	local function enable_treesitter(bufnr)
		-- Skip special buffers, invalid filetypes, or large files
		if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" or vim.b[bufnr].large_file then
			return
		end

		-- Skip large files for performance
		local path = vim.api.nvim_buf_get_name(bufnr)
		local ok, stats = pcall(vim.uv.fs_stat, path)

		if ok and stats and stats.size > 500 * 1024 then
			return
		end

		-- Enable Treesitter only if parser exists
		local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)

		if not ok_parser or not parser then
			return
		end

		vim.treesitter.start(bufnr)

		-- Treesitter folding
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo.foldlevel = 99
	end

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		desc = "Enable native Treesitter highlighting",
		callback = function(args)
			enable_treesitter(args.buf)
		end,
	})

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			enable_treesitter(bufnr)
		end
	end
end

return M
