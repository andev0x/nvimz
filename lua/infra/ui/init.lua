local M = {}

function M.show_in_buffer(title, lines)
	if #vim.api.nvim_list_uis() == 0 then
		print(table.concat(lines, "\n"))
		return
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(bufnr)
	vim.wo.wrap = false
	vim.wo.number = true
	vim.wo.relativenumber = false
	pcall(vim.api.nvim_buf_set_name, bufnr, title)
end

return M
