local M = {}

-- Track startup metrics cleanly
function M.track(start_ns)
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6
			if elapsed_ms > 20 then
				vim.schedule(function()
					vim.notify(("nvim-zen startup %.2fms exceeded 20ms target"):format(elapsed_ms), vim.log.levels.WARN)
				end)
			end
		end,
	})
end

function M.setup()
	-- Only trigger the dashboard if Neovim is launched empty (no file/directory arguments)
	if vim.fn.argc() > 0 or vim.blueprints_loaded then
		return
	end

	-- Create a scratch buffer with minimalist interface settings
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
	vim.api.nvim_buf_set_option(bufnr, "filetype", "dashboard")

	-- Loaded
	local startup_time = 0

	if _G.nvimz_start_time then
		startup_time = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6
	else
		-- Fallback

		startup_time = 0.00
	end

	-- Raw ASCII Art representation of 'nvimz'
	local logo = {
		[[      _  __     _           ]],
		[[     / |/ /_ __(_)_ _  ___  ]],
		[[    /    / \ \ / / ' \/_ /  ]],
		[[   /_/|_/ \___/_/_/_/_//__/_]],
		[[      designed by andev0x   ]],
	}

	-- Actionable single-key shortcut menu
	local menu = {
		"   [f]  Find Files (mini.pick)    ",
		"   [g]  Live Grep (mini.pick)     ",
		"   [e]  File Explorer (mini.files)",
		"   [q]  Quit Neovim               ",
	}

	-- Stats line
	local stats = string.format("    ⚡ Loaded in %.2fms", startup_time)
	table.insert(logo, stats)

	-- Get current window dimensions
	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)

	-- Find the longest line in the layout to determine the content width
	local max_len = 0
	for _, line in ipairs(logo) do
		max_len = math.max(max_len, vim.fn.strdisplaywidth(line))
	end
	for _, line in ipairs(menu) do
		max_len = math.max(max_len, vim.fn.strdisplaywidth(line))
	end

	-- Calculate horizontal padding (left margin offset)
	local left_padding = math.max(0, math.floor((win_width - max_len) / 2))
	local pad_str = string.rep(" ", left_padding)

	-- Generate horizontally-centered content payload
	local centered_logo = {}
	for _, line in ipairs(logo) do
		table.insert(centered_logo, pad_str .. line)
	end

	local centered_menu = {}
	for _, line in ipairs(menu) do
		table.insert(centered_menu, pad_str .. line)
	end

	-- Calculate vertical padding (top margin offset)
	local total_content_height = #logo + #menu + 1 -- Plus 1 for spacing line
	local top_padding_size = math.max(0, math.floor((win_height - total_content_height) / 2))

	-- Construct final layout with top vertical spacing
	local lines = {}
	for _ = 1, top_padding_size do
		table.insert(lines, "")
	end
	for _, line in ipairs(centered_logo) do
		table.insert(lines, line)
	end
	table.insert(lines, "") -- Spacer line between logo and menu
	for _, line in ipairs(centered_menu) do
		table.insert(lines, line)
	end

	-- Write data to the buffer and lock editing
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Mount the configured dashboard buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Hide standard UI layout components to achieve a pristine "Zen" look
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.statusline = ""

	-- Map single-key navigation triggers (instant execution without Leader key)
	local map_opts = { buffer = bufnr, nowait = true, silent = true }
	vim.keymap.set("n", "f", function()
		require("mini.pick").builtin.files()
	end, map_opts)
	vim.keymap.set("n", "g", function()
		require("mini.pick").builtin.grep_live()
	end, map_opts)
	vim.keymap.set("n", "e", function()
		require("mini.files").open()
	end, map_opts)
	vim.keymap.set("n", "q", ":qa<CR>", map_opts)

	-- Apply syntax highlights dynamically targeting colored segments
	local ns = vim.api.nvim_create_namespace("dashboard_colors")

	-- Style the logo lines (calculated after the top padding offset)
	local logo_start_row = top_padding_size
	local logo_end_row = logo_start_row + #logo

	for row = logo_start_row, logo_end_row - 2 do
		vim.api.nvim_buf_add_highlight(bufnr, ns, "String", row, 0, -1)
	end

	-- Style the author subtitle line (last line of the logo block)
	vim.api.nvim_buf_add_highlight(bufnr, ns, "Comment", logo_end_row - 1, 0, -1)

	-- Highlight the single-key action brackets [f], [g], [e], [q] (positioned after logo + spacer)
	local menu_start_row = logo_end_row + 1
	for i = 0, #menu - 1 do
		local row = menu_start_row + i
		-- Dynamic slice offset to match the padded bracket index position [x]
		local start_col = left_padding + 3
		local end_col = left_padding + 6
		vim.api.nvim_buf_add_highlight(bufnr, ns, "Special", row, start_col, end_col)
	end
end

function M.open()
	M.setup()
end

-- FIX: Only run setup ONCE during the VimEnter lifecycle event
-- This ensures window dimensions (width/height) are fully settled before layout math runs.
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		M.setup()
	end,
})

return M
