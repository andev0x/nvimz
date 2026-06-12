local M = {}

-- ============================================================================
-- Startup Performance Tracking
-- ============================================================================

function M.track(start_ns)
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6

			-- Cache startup stats
			vim.schedule(function()
				local ok, cache = pcall(require, "infra.cache")
				if ok then
					local stats = cache.get("startup_stats") or {}
					table.insert(stats, {
						time = os.date("%Y-%m-%d %H:%M:%S"),
						elapsed_ms = elapsed_ms,
					})
					-- Keep only last 10 entries
					while #stats > 10 do
						table.remove(stats, 1)
					end
					cache.set("startup_stats", stats)
				end
			end)

			if elapsed_ms > 20 then
				vim.schedule(function()
					vim.notify(("nvimz startup %.2fms exceeded 20ms target"):format(elapsed_ms), vim.log.levels.WARN)
				end)
			end
		end,
	})
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

local function center_text(text, width)
	local text_width = vim.fn.strdisplaywidth(text)
	local padding = math.max(0, math.floor((width - text_width) / 2))

	return string.rep(" ", padding) .. text
end

local function set_line_highlight(bufnr, ns, row, hl_group)
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
		end_col = #line,
		hl_group = hl_group,
	})
end

local function set_range_highlight(bufnr, ns, row, start_col, end_col, hl_group)
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	if end_col == -1 then
		end_col = #line
	end

	vim.api.nvim_buf_set_extmark(bufnr, ns, row, start_col, {
		end_col = end_col,
		hl_group = hl_group,
	})
end

-- Create a single persistent namespace for the dashboard
local dashboard_ns = vim.api.nvim_create_namespace("nvimz_dashboard")

-- Define highlights with the new cyber-green and cyan color palette
local function define_highlights()
	vim.api.nvim_set_hl(0, "DashboardNormal", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "DashboardEndOfBuffer", { fg = "NONE", bg = "NONE", ctermfg = "NONE", ctermbg = "NONE" })

	-- Bright neon green for the main ASCII logo
	vim.api.nvim_set_hl(0, "NvimzLogo", { fg = "#b8e673", bold = true })

	-- Medium green for the username
	vim.api.nvim_set_hl(0, "NvimzUser", { fg = "#8cb359", bold = true })

	-- Muted gray/green for the startup stats
	vim.api.nvim_set_hl(0, "NvimzStats", { fg = "#5c7365", italic = true })

	-- Vibrant cyan/blue for the shortcut brackets and keys: [f], [g], etc.
	vim.api.nvim_set_hl(0, "NvimzKey", { fg = "#3399cc", bold = true })

	-- Clean crisp white/gray for the descriptions
	vim.api.nvim_set_hl(0, "NvimzMenu", { fg = "#ccd9d2" })
end

-- Initialize highlights immediately on load
define_highlights()

-- Re-apply highlights when the colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = define_highlights,
})

-- ============================================================================
-- Dashboard Core
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

	-- =========================================================================
	-- Minimal Logo
	-- =========================================================================

	local logo = {
		[[ █▄░█ █░█ █ █▀▄▀█ ▀█░ ]],
		[[ █░▀█ ▀▄▀ █ █░▀░█ █▄▀ ]],
		"",
		[[andev0x]],
		string.format("󱐋 %.2fms", startup_time),
	}

	-- =========================================================================
	-- Minimal Action Menu
	-- =========================================================================

	local menu = {
		string.format("[f]  %-14s", "Find Files"),
		string.format("[g]  %-14s", "Live Grep"),
		string.format("[e]  %-14s", "File Explorer"),
		string.format("[q]  %-14s", "Quit Neovim"),
	}

	-- Get current window dimensions
	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)

	-- Calculate vertical centering
	local content_height = #logo + #menu + 1
	local top_padding = math.max(0, math.floor((win_height - content_height) / 2))

	-- =========================================================================
	-- Build Dashboard Layout
	-- =========================================================================

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

	-- Write dashboard content into buffer
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	-- Prevent buffer editing
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

	-- Mount dashboard buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Move cursor away from top-left corner
	vim.api.nvim_win_set_cursor(0, { top_padding + 8, 0 })

	-- =========================================================================
	-- Local Window UI Options
	-- =========================================================================

	vim.opt_local.number = false
	vim.opt_local.relativenumber = false
	vim.opt_local.signcolumn = "no"
	vim.opt_local.statusline = ""
	vim.opt_local.winbar = ""
	vim.opt_local.cursorline = false
	vim.opt_local.cursorcolumn = false
	vim.opt_local.wrap = false
	vim.opt_local.list = false
	vim.opt_local.fillchars = "eob: "

	-- Apply local window highlights
	vim.wo.winhighlight = "Normal:DashboardNormal,EndOfBuffer:DashboardEndOfBuffer"

	-- =========================================================================
	-- Keymaps
	-- =========================================================================

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
		require("oil").open()
	end, map_opts)

	vim.keymap.set("n", "q", "<cmd>qa<cr>", map_opts)

	-- =========================================================================
	-- Apply Highlights
	-- =========================================================================

	-- Clear old extmarks to ensure a pristine state when re-opening
	vim.api.nvim_buf_clear_namespace(bufnr, dashboard_ns, 0, -1)

	-- Highlight ASCII logo
	for row = top_padding, top_padding + 1 do
		set_line_highlight(bufnr, dashboard_ns, row, "NvimzLogo")
	end

	-- Highlight username
	set_line_highlight(bufnr, dashboard_ns, top_padding + 3, "NvimzUser")

	-- Highlight startup stats
	set_line_highlight(bufnr, dashboard_ns, top_padding + 4, "NvimzStats")

	-- Highlight action menu items
	local menu_start = top_padding + #logo + 1

	for i, line in ipairs(menu) do
		local row = menu_start + i - 1
		local col_start = math.floor((win_width - vim.fn.strdisplaywidth(line)) / 2)

		-- Highlight shortcut key component: e.g., "[f]"
		set_range_highlight(bufnr, dashboard_ns, row, col_start, col_start + 3, "NvimzKey")

		-- Highlight menu description label
		set_range_highlight(bufnr, dashboard_ns, row, col_start + 5, -1, "NvimzMenu")
	end
end

function M.open()
	M.setup()
end



return M
