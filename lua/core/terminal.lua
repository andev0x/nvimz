local M = {}

-- Auto-insert mode when entering terminal
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
	pattern = "term://*",
	callback = function()
		vim.cmd("startinsert")
	end,
})

local state = {
	floating = {
		buf = -1,
		win = -1,
	},
	bottom = {
		buf = -1,
		win = -1,
	},
}

local function get_terminal_buf(buf)
	if vim.api.nvim_buf_is_valid(buf) then
		return buf
	end
	local new_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(new_buf, "buflisted", false)
	vim.api.nvim_buf_set_option(new_buf, "bufhidden", "hide")
	return new_buf
end

function M.toggle()
	local entry = state.floating
	if vim.api.nvim_win_is_valid(entry.win) then
		vim.api.nvim_win_close(entry.win, true)
		return
	end

	entry.buf = get_terminal_buf(entry.buf)

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	entry.win = vim.api.nvim_open_win(entry.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	if vim.bo[entry.buf].buftype ~= "terminal" then
		vim.cmd.term()
	end
	vim.cmd.startinsert()
end

function M.toggle_bottom()
	local entry = state.bottom
	if vim.api.nvim_win_is_valid(entry.win) then
		vim.api.nvim_win_close(entry.win, true)
		return
	end

	entry.buf = get_terminal_buf(entry.buf)

	-- Open a split at the very bottom
	vim.cmd("botright split")
	entry.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(entry.win, entry.buf)

	-- Professional UI: No numbers, no signcolumn, fixed height
	vim.wo[entry.win].number = false
	vim.wo[entry.win].relativenumber = false
	vim.wo[entry.win].signcolumn = "no"
	vim.wo[entry.win].winfixheight = true
	vim.api.nvim_win_set_height(entry.win, math.floor(vim.o.lines * 0.3))

	if vim.bo[entry.buf].buftype ~= "terminal" then
		vim.cmd.term()
	end
	vim.cmd.startinsert()
end

return M
