local M = {}

-- ============================================================================
-- Auto Insert Mode
-- ============================================================================

vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
	pattern = "term://*",
	callback = function()
		vim.cmd.startinsert()
	end,
})

-- ============================================================================
-- Terminal State
-- ============================================================================

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

-- ============================================================================
-- Utility
-- ============================================================================

local function create_terminal_buffer()
	-- Terminal buffers should not be scratch buffers
	local buf = vim.api.nvim_create_buf(false, false)

	vim.api.nvim_set_option_value("buflisted", false, {
		buf = buf,
	})

	vim.api.nvim_set_option_value("bufhidden", "hide", {
		buf = buf,
	})

	return buf
end

local function ensure_terminal_buffer(buf)
	if vim.api.nvim_buf_is_valid(buf) then
		return buf
	end

	return create_terminal_buffer()
end

local function ensure_terminal_job(buf)
	-- Reuse existing terminal job if possible
	if vim.bo[buf].buftype == "terminal" then
		return
	end

	vim.api.nvim_set_current_buf(buf)

	---@diagnostic disable-next-line: deprecated
	vim.fn.termopen(vim.o.shell)
end

local function setup_terminal_window(win)
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.wo[win].winfixheight = true
end

-- ============================================================================
-- Floating Terminal
-- ============================================================================

function M.toggle()
	local entry = state.floating

	-- Close terminal if already open
	if vim.api.nvim_win_is_valid(entry.win) then
		vim.api.nvim_win_close(entry.win, true)
		return
	end

	entry.buf = ensure_terminal_buffer(entry.buf)

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

	setup_terminal_window(entry.win)

	ensure_terminal_job(entry.buf)

	vim.cmd.startinsert()
end

-- ============================================================================
-- Bottom Terminal
-- ============================================================================

function M.toggle_bottom()
	local entry = state.bottom

	-- Close terminal if already open
	if vim.api.nvim_win_is_valid(entry.win) then
		vim.api.nvim_win_close(entry.win, true)
		return
	end

	entry.buf = ensure_terminal_buffer(entry.buf)

	-- Open terminal split at bottom
	vim.cmd("botright split")

	entry.win = vim.api.nvim_get_current_win()

	vim.api.nvim_win_set_buf(entry.win, entry.buf)

	setup_terminal_window(entry.win)

	vim.api.nvim_win_set_height(entry.win, math.floor(vim.o.lines * 0.3))

	ensure_terminal_job(entry.buf)

	vim.cmd.startinsert()
end

return M
