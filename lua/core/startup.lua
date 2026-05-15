local M = {}

-- ============================================================================
-- Startup Performance Tracking
-- ============================================================================

function M.track(start_ns)
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6

			if elapsed_ms > 20 then
				vim.schedule(function()
					vim.notify(("nvimz startup %.2fms exceeded 20ms target"):format(elapsed_ms), vim.log.levels.WARN)
				end)
			end
		end,
	})
end

-- ============================================================================
-- Utility
-- ============================================================================

local function center_text(text, width)
	local text_width = vim.fn.strdisplaywidth(text)
	local padding = math.max(0, math.floor((width - text_width) / 2))

	return string.rep(" ", padding) .. text
end

-- ============================================================================
-- Dashboard
-- ============================================================================

function M.setup()
	-- Only show dashboard when no file or directory is passed
	if vim.fn.argc() > 0 or vim.g.blueprints_loaded then
		return
	end

	-- Create scratch buffer
	local bufnr = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "dashboard", { buf = bufnr })

	-- Calculate startup time
	local startup_time = 0

	if _G.nvimz_start_time then
		startup_time = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6
	end

	-- Minimal modern "nvimz" logo
	local logo = {
		[[ █▄░█ █░█ █ █▀▄▀█ ▀█░ ]],
		[[ █░▀█ ▀▄▀ █ █░▀░█ █▄▀ ]],
		"",
		[[andev0x]],
		string.format("󱐋 %.2fms", startup_time),
	}

	-- Minimal action menu
	local menu = {
		string.format("[f]  %-14s", "Find Files"),
		string.format("[g]  %-14s", "Live Grep"),
		string.format("[e]  %-14s", "File Explorer"),
		string.format("[q]  %-14s", "Quit Neovim"),
	}

	-- Window dimensions
	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)

	-- Calculate vertical centering
	local content_height = #logo + #menu + 1
	local top_padding = math.max(0, math.floor((win_height - content_height) / 2))

	-- Build final layout
	local lines = {}

	for _ = 1, top_padding do
		table.insert(lines, "")
	end

	for _, line in ipairs(logo) do
		table.insert(lines, center_text(line, win_width))
	end

	table.insert(lines, "")

	for _, line in ipairs(menu) do
		table.insert(lines, center_text(line, win_width))
	end

	-- Write content into buffer
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- Lock buffer editing
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

	-- Mount dashboard buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Minimal local UI
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.statusline = ""
	vim.opt_local.winbar = ""
	vim.opt_local.cursorline = false
	vim.opt_local.cursorcolumn = false
	vim.opt_local.wrap = false
	vim.opt_local.list = false

	-- Keymaps
	local map_opts = {
		buffer = bufnr,
		nowait = true,
		silent = true,
	}

	vim.keymap.set("n", "f", function()
		require("mini.pick").builtin.files()
	end, map_opts)

	vim.keymap.set("n", "g", function()
		require("mini.pick").builtin.grep_live()
	end, map_opts)

	vim.keymap.set("n", "e", function()
		require("mini.files").open()
	end, map_opts)

	vim.keymap.set("n", "q", "<cmd>qa<cr>", map_opts)

	-- Highlight groups
	local ns = vim.api.nvim_create_namespace("nvimz_dashboard")

	-- Logo highlight
	for row = top_padding, top_padding + #logo - 2 do
		vim.api.nvim_buf_add_highlight(bufnr, ns, "String", row, 0, -1)
	end

	-- Startup time highlight
	vim.api.nvim_buf_add_highlight(bufnr, ns, "Comment", top_padding + #logo - 1, 0, -1)

	-- Menu key highlights
	local menu_start = top_padding + #logo + 1

	for i, line in ipairs(menu) do
		local row = menu_start + i - 1
		local col_start = math.floor((win_width - vim.fn.strdisplaywidth(line)) / 2)

		vim.api.nvim_buf_add_highlight(bufnr, ns, "Special", row, col_start, col_start + 3)
	end
end

function M.open()
	M.setup()
end

-- Auto-open dashboard on startup
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		M.setup()
	end,
})

return M
