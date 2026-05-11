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
	if vim.fn.argc() > 0 or vim.g.blueprints_loaded then
		return
	end

	-- Create a scratch buffer with minimalist interface settings
	local bufnr = vim.api.nvim_create_buf(false, true)
	local opts = { scope = "local" }
	vim.api.nvim_set_option_value("bufhidden", "wipe", opts)
	vim.api.nvim_set_option_value("buftype", "nofile", opts)
	vim.api.nvim_set_option_value("swapfile", false, opts)
	vim.api.nvim_set_option_value("filetype", "dashboard", opts)

	-- Loaded
	local startup_time = _G.nvimz_start_time and ((vim.uv.hrtime() - _G.nvimz_start_time) / 1e6) or 0

	-- Raw ASCII Art representation of 'nvimz'
	local logo = {
		[[      _  __     _           ]],
		[[     / |/ /_ __(_)_ _  ___  ]],
		[[    /    / \ \ / / ' \/_ /  ]],
		[[   /_/|_/ \___/_/_/_/_//__/_]],
		[[      designed by andev0x   ]],
		string.format("    ⚡ Loaded in %.2fms", startup_time),
	}

	-- Actionable single-key shortcut menu
	local menu = {
		"   [f]  Find Files                ",
		"   [g]  Live Grep                 ",
		"   [e]  File Explorer             ",
		"   [q]  Quit Neovim               ",
	}

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

	-- Calculate horizontal padding
	local pad_str = string.rep(" ", math.max(0, math.floor((win_width - max_len) / 2)))

	-- Calculate vertical padding
	local total_height = #logo + #menu + 1
	local top_padding = math.max(0, math.floor((win_height - total_height) / 2))

	-- Construct final layout
	local lines = {}
	for _ = 1, top_padding do
		table.insert(lines, "")
	end
	for _, line in ipairs(logo) do
		table.insert(lines, pad_str .. line)
	end
	table.insert(lines, "")
	for _, line in ipairs(menu) do
		table.insert(lines, pad_str .. line)
	end

	-- Write data to the buffer and lock editing
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

	-- Mount the configured dashboard buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Hide standard UI layout components
	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.statusline = ""

	-- Map single-key navigation triggers
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

	-- Apply syntax highlights
	local ns = vim.api.nvim_create_namespace("dashboard_colors")
	for row = top_padding, top_padding + #logo - 2 do
		vim.api.nvim_buf_add_highlight(bufnr, ns, "String", row, 0, -1)
	end
	vim.api.nvim_buf_add_highlight(bufnr, ns, "Comment", top_padding + #logo - 1, 0, -1)

	local menu_start = top_padding + #logo + 1
	for i = 0, #menu - 1 do
		vim.api.nvim_buf_add_highlight(bufnr, ns, "Special", menu_start + i, #pad_str + 3, #pad_str + 6)
	end
end

function M.open()
	M.setup()
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		M.setup()
	end,
})

return M
