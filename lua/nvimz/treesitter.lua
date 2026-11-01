local M = {}

local function can_enable(bufnr)
	return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype ~= "" and not vim.b[bufnr].large_file
end

local function parser_available(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	return ok and parser ~= nil
end

local function enable(bufnr)
	if not can_enable(bufnr) or not parser_available(bufnr) then
		return
	end

	vim.treesitter.start(bufnr)
	vim.wo.foldmethod = "expr"
	vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	vim.wo.foldlevel = 99
end

function M.setup()
	local group = vim.api.nvim_create_augroup("nvimz_treesitter", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		desc = "Enable native Treesitter highlighting",
		callback = function(args)
			enable(args.buf)
		end,
	})

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			enable(bufnr)
		end
	end
end

return M
