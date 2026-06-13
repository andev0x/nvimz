local M = {}

-- ============================================================================
-- Startup Performance Tracking
-- ============================================================================

function M.track(start_ns)
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6

			-- Cache startup stats — deferred entirely, no hot-path work
			vim.schedule(function()
				-- Lazy require: only load infra.cache if it's already in package.loaded
				-- to avoid a cold require on every startup
				local cache = package.loaded["infra.cache"]
				if not cache then
					local ok
					ok, cache = pcall(require, "infra.cache")
					if not ok then
						return
					end
				end

				local stats = cache.get("startup_stats") or {}
				stats[#stats + 1] = {
					time = os.date("%Y-%m-%d %H:%M:%S"),
					elapsed_ms = elapsed_ms,
				}
				-- Keep only last 10 entries — remove from front in bulk
				local overflow = #stats - 10
				if overflow > 0 then
					for i = 1, #stats - overflow do
						stats[i] = stats[i + overflow]
					end
					for i = #stats - overflow + 1, #stats do
						stats[i] = nil
					end
				end
				cache.set("startup_stats", stats)
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
-- Highlight Definitions (defined once, never redundantly re-set)
-- ============================================================================

-- Create a single persistent namespace for the dashboard
local dashboard_ns = vim.api.nvim_create_namespace("nvimz_dashboard")

-- Track whether highlights have been defined for the current colorscheme
local _hl_defined = false

local function define_highlights()
	if _hl_defined then
		return
	end
	_hl_defined = true

	-- Use the batch-friendly table form to avoid repeated API calls
	local hls = {
		DashboardNormal = { bg = "NONE" },
		DashboardEndOfBuffer = { fg = "NONE", bg = "NONE", ctermfg = "NONE", ctermbg = "NONE" },
		NvimzLogo = { fg = "#b8e673", bold = true },
		NvimzUser = { fg = "#8cb359", bold = true },
		NvimzStats = { fg = "#5c7365", italic = true },
		NvimzKey = { fg = "#3399cc", bold = true },
		NvimzMenu = { fg = "#ccd9d2" },
	}
	for name, opts in pairs(hls) do
		vim.api.nvim_set_hl(0, name, opts)
	end
end

-- Re-apply highlights when the colorscheme changes; reset guard first
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		_hl_defined = false
		define_highlights()
	end,
})

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Returns leading-space padding count for centering — avoids recomputing strdisplaywidth
-- when the caller already has both values.
local function padding_for(text_width, win_width)
	return math.max(0, math.floor((win_width - text_width) / 2))
end

-- ============================================================================
-- Dashboard Core
-- ============================================================================

function M.setup()
	-- Only show dashboard when no file or directory is passed
	if vim.fn.argc() > 0 or vim.g.blueprints_loaded then
		return
	end

	-- Ensure highlights are ready before we touch any buffers
	define_highlights()

	-- Create scratch buffer
	local bufnr = vim.api.nvim_create_buf(false, true)

	-- Set all buffer options in one block (avoids repeated option-lookup overhead)
	local buf_opts = { buf = bufnr }
	vim.api.nvim_set_option_value("bufhidden", "wipe", buf_opts)
	vim.api.nvim_set_option_value("buftype", "nofile", buf_opts)
	vim.api.nvim_set_option_value("swapfile", false, buf_opts)
	vim.api.nvim_set_option_value("filetype", "dashboard", buf_opts)

	-- =========================================================================
	-- Compute startup time
	-- =========================================================================

	local startup_time = _G.nvimz_start_time and ((vim.uv.hrtime() - _G.nvimz_start_time) / 1e6) or 0

	-- =========================================================================
	-- Content
	-- =========================================================================

	local logo = {
		[[ █▄░█ █░█ █ █▀▄▀█ ▀█░ ]],
		[[ █░▀█ ▀▄▀ █ █░▀░█ █▄▀ ]],
		"",
		[[andev0x]],
		string.format("󱐋 %.2fms", startup_time),
	}

	local menu = {
		string.format("[f]  %-14s", "Find Files"),
		string.format("[g]  %-14s", "Live Grep"),
		string.format("[e]  %-14s", "File Explorer"),
		string.format("[q]  %-14s", "Quit Neovim"),
	}

	-- =========================================================================
	-- Layout — snapshot window dimensions once
	-- =========================================================================

	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)

	local content_height = #logo + #menu + 1
	local top_padding = math.max(0, math.floor((win_height - content_height) / 2))

	-- =========================================================================
	-- Build lines + precompute per-line display widths in one pass
	-- =========================================================================

	-- We need display widths for centering and later for highlight column math.
	-- Call strdisplaywidth once per unique string, not once per insertion.

	local lines = {}

	-- top padding
	for _ = 1, top_padding do
		lines[#lines + 1] = ""
	end

	-- logo lines — center once per logo string
	local logo_paddings = {}
	for i, text in ipairs(logo) do
		local w = vim.fn.strdisplaywidth(text)
		local pad = padding_for(w, win_width)
		logo_paddings[i] = pad
		lines[#lines + 1] = string.rep(" ", pad) .. text
	end

	-- separator
	lines[#lines + 1] = ""

	-- menu lines — center once per menu string, record col_start for highlight pass
	local menu_col_starts = {}
	for i, text in ipairs(menu) do
		local w = vim.fn.strdisplaywidth(text)
		local pad = padding_for(w, win_width)
		menu_col_starts[i] = pad
		lines[#lines + 1] = string.rep(" ", pad) .. text
	end

	-- =========================================================================
	-- Write content — single API call
	-- =========================================================================

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

	-- Mount dashboard buffer
	vim.api.nvim_set_current_buf(bufnr)

	-- Move cursor to a sensible row (below stats line)
	vim.api.nvim_win_set_cursor(0, { top_padding + 8, 0 })

	-- =========================================================================
	-- Window UI Options
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

	vim.wo.winhighlight = "Normal:DashboardNormal,EndOfBuffer:DashboardEndOfBuffer"

	-- =========================================================================
	-- Keymaps
	-- =========================================================================

	local map_opts = { buffer = bufnr, nowait = true, silent = true }

	vim.keymap.set("n", "f", function()
		require("mini.pick").builtin.files()
	end, map_opts)

	vim.keymap.set("n", "g", function()
		require("mini.pick").builtin.grep_live()
	end, map_opts)

	vim.keymap.set("n", "e", function()
		-- packadd makes the runtime files available; package.loaded is the only
		-- stable public signal that oil has already been initialised — avoids
		-- relying on internal implementation details like oil.config internals.
		vim.cmd("packadd oil.nvim")
		if not package.loaded["oil"] then
			require("oil").setup()
		end
		require("oil").open()
	end, map_opts)

	vim.keymap.set("n", "q", "<cmd>qa<cr>", map_opts)

	-- =========================================================================
	-- Apply Extmark Highlights — batch via a single clear + sequential set_extmark
	-- =========================================================================

	-- Clear any stale extmarks from a previous open
	vim.api.nvim_buf_clear_namespace(bufnr, dashboard_ns, 0, -1)

	-- Helper: highlight a full logical line by its row in the buffer.
	-- Avoids get_lines round-trip by using the known line content lengths from
	-- the lines table we already built.
	local function hl_full_row(row, hl)
		local col_end = #lines[row + 1] -- lines is 1-indexed, extmarks are 0-indexed
		if col_end == 0 then
			return
		end
		vim.api.nvim_buf_set_extmark(bufnr, dashboard_ns, row, 0, {
			end_col = col_end,
			hl_group = hl,
		})
	end

	local function hl_range(row, c0, c1, hl)
		local col_end = (c1 == -1) and #lines[row + 1] or c1
		vim.api.nvim_buf_set_extmark(bufnr, dashboard_ns, row, c0, {
			end_col = col_end,
			hl_group = hl,
		})
	end

	-- Logo rows (rows 0..top_padding-1 are blank, logo starts at top_padding)
	hl_full_row(top_padding, "NvimzLogo")
	hl_full_row(top_padding + 1, "NvimzLogo")

	-- Username and stats (logo[3] and logo[4], 0-indexed = top_padding+2 / top_padding+3 / +4)
	-- logo[3] = "" (blank), logo[4] = username, logo[5] = stats (1-indexed)
	hl_full_row(top_padding + 3, "NvimzUser")
	hl_full_row(top_padding + 4, "NvimzStats")

	-- Menu highlights — use precomputed col_starts, avoid any get_lines calls
	local menu_start = top_padding + #logo + 1 -- +1 for the separator ""

	for i = 1, #menu do
		local row = menu_start + i - 1
		local col0 = menu_col_starts[i]

		-- Key bracket "[x]" — 3 chars
		hl_range(row, col0, col0 + 3, "NvimzKey")
		-- Description — from col+5 to end
		hl_range(row, col0 + 5, -1, "NvimzMenu")
	end
end

function M.open()
	M.setup()
end

return M
