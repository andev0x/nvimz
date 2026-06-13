local M = {}

-- ============================================================================
-- HIGHLIGHTS
-- Minimalist, focus-driven design. High contrast reserved for Modes & Errors.
-- ============================================================================

local function setup_highlights()
	local set_hl = vim.api.nvim_set_hl
	local colors = require("tokyonight.colors").setup({ style = "moon" })

	-- We use a slightly darker, muted background for the statusline
	-- to separate it from the code buffer without needing a harsh border.
	local base_bg = colors.bg_statusline

	-- ── Mode pills (High focus, actionable) ─────────────────────────────────
	set_hl(0, "MiniStatuslineModeNormal", { fg = colors.bg_dark, bg = colors.blue, bold = true })
	set_hl(0, "MiniStatuslineModeInsert", { fg = colors.bg_dark, bg = colors.green, bold = true })
	set_hl(0, "MiniStatuslineModeVisual", { fg = colors.bg_dark, bg = colors.magenta, bold = true })
	set_hl(0, "MiniStatuslineModeReplace", { fg = colors.bg_dark, bg = colors.red, bold = true })
	set_hl(0, "MiniStatuslineModeCommand", { fg = colors.bg_dark, bg = colors.yellow, bold = true })
	set_hl(0, "MiniStatuslineModeTerminal", { fg = colors.bg_dark, bg = colors.teal, bold = true })

	-- ── Primary Content (Filename takes center stage) ───────────────────────
	set_hl(0, "MiniStatuslineFilename", { fg = colors.fg, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslineFilenameModified", { fg = colors.yellow, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslinePath", { fg = colors.dark3, bg = base_bg })

	-- ── Greeting Message (Gentle, inviting) ─────────────────────────────────
	set_hl(0, "MiniStatuslineWelcome", { fg = colors.blue, bg = base_bg, bold = true })

	-- ── Diagnostics (Flat, clean semantics) ─────────────────────────────────
	set_hl(0, "MiniStatuslineError", { fg = colors.error, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslineWarning", { fg = colors.warning, bg = base_bg, bold = true })

	-- ── Telemetry Metadata (Recessed, low cognitive load) ───────────────────
	set_hl(0, "MiniStatuslineGit", { fg = colors.dark5, bg = base_bg })
	set_hl(0, "MiniStatuslineLSP", { fg = colors.dark5, bg = base_bg })
	set_hl(0, "MiniStatuslineFileinfo", { fg = colors.dark5, bg = base_bg })

	-- ── Premium Right Pill (Matches Tmux capsule look perfectly) ────────────
	set_hl(0, "MiniStatuslineRightPill", { fg = colors.purple, bg = colors.bg_highlight, bold = true })
	set_hl(0, "MiniStatuslineLocation", { fg = colors.fg, bg = colors.bg_highlight, bold = true })
	set_hl(0, "MiniStatuslineProgress", { fg = colors.dark5, bg = colors.bg_highlight })

	-- ── Spacers ─────────────────────────────────────────────────────────────
	set_hl(0, "MiniStatuslineSecondary", { fg = base_bg, bg = base_bg })
	set_hl(0, "MiniStatuslineInactive", { fg = colors.dark3, bg = base_bg })
end

-- ============================================================================
-- MODES CONFIGURATION
-- Typography-focused indicator map
-- ============================================================================

local mode_map = {
	n = { label = " ● ", hl = "MiniStatuslineModeNormal" },
	no = { label = " ● ", hl = "MiniStatuslineModeNormal" },
	i = { label = " ✎ ", hl = "MiniStatuslineModeInsert" },
	ic = { label = " ✎ ", hl = "MiniStatuslineModeInsert" },
	v = { label = " ◈ ", hl = "MiniStatuslineModeVisual" },
	V = { label = " ◆ ", hl = "MiniStatuslineModeVisual" },
	["\22"] = { label = " ■ ", hl = "MiniStatuslineModeVisual" },
	c = { label = " ⌘ ", hl = "MiniStatuslineModeCommand" },
	R = { label = " ↺ ", hl = "MiniStatuslineModeReplace" },
	Rv = { label = " ↺ ", hl = "MiniStatuslineModeReplace" },
	s = { label = " ◇ ", hl = "MiniStatuslineModeVisual" },
	S = { label = " ◆ ", hl = "MiniStatuslineModeVisual" },
	t = { label = " ▸ ", hl = "MiniStatuslineModeTerminal" },
}

local function get_mode()
	local raw = vim.fn.mode(1)
	return mode_map[raw] or mode_map[vim.fn.mode()] or mode_map.n
end

-- ============================================================================
-- BIOLOGICAL CLOCK ENGINE
-- ============================================================================

local _time = { icon = "󰭎", ts = 0 }
local TIME_SLOTS = {
	{ from = 5, to = 7, icon = "󰖚 " },
	{ from = 7, to = 11, icon = "󰖨 " },
	{ from = 11, to = 13, icon = "󰩰 " },
	{ from = 13, to = 17, icon = "󱍄 " },
	{ from = 17, to = 19, icon = "󰖚 " },
	{ from = 19, to = 22, icon = "󰅶 " },
	{ from = 22, to = 24, icon = "󰖔 " },
	{ from = 0, to = 5, icon = "󰒲 " },
}

local function get_time_icon()
	local now = vim.uv.now()
	if now - _time.ts < 60000 then
		return _time.icon
	end
	local h = tonumber(os.date("%H"))
	_time.icon = "󰭎 "
	for _, s in ipairs(TIME_SLOTS) do
		if h >= s.from and h < s.to then
			_time.icon = s.icon
			break
		end
	end
	_time.ts = now
	return _time.icon
end

-- ============================================================================
-- CORE COMPONENTS
-- ============================================================================

local function get_filename()
	local name = vim.fn.expand("%:t")
	local ft = vim.bo.filetype
	local modified = vim.bo.modified

	-- Intercept if empty name buffer, or explicitly on a dashboard screen
	if name == "" or ft == "dashboard" or ft == "alpha" or ft == "starter" then
		if not modified then
			local username = vim.env.USER or vim.env.USERNAME or "User"
			local h = tonumber(os.date("%H"))
			local greeting = ""
			local icon = ""

			-- Dynamic Time-Based Greeting
			if h >= 5 and h < 12 then
				greeting = "Good morning"
				icon = "󰖨"
			elseif h >= 12 and h < 18 then
				greeting = "Good afternoon"
				icon = "󰖚"
			elseif h >= 18 and h < 22 then
				greeting = "Good evening"
				icon = "󰅶"
			else
				greeting = "Good night"
				icon = "󰖔"
			end

			return icon .. " " .. greeting .. ", @" .. username, "", false, true
		end
		return "scratch", "", false, false
	end

	local suffix = modified and " ●" or ""
	if vim.bo.readonly then
		suffix = suffix .. " 󰌾"
	end
	return name, suffix, modified, false
end

local function get_filepath()
	local path = vim.fn.expand("%:~:.:h")
	if path == "." or path == "" then
		return ""
	end

	-- Gracefully truncate deep absolute paths while preserving root context
	local parts = vim.split(path, "/", { plain = true })
	if #parts > 2 then
		path = parts[1] .. "/…/" .. parts[#parts - 1] .. "/" .. parts[#parts]
	elseif #parts > 1 then
		path = parts[1] .. "/" .. parts[#parts]
	end

	return path
end

local _sizes = {}
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("slc_filesize", { clear = true }),
	callback = function(ev)
		local p = vim.api.nvim_buf_get_name(ev.buf)
		if p == "" then
			_sizes[ev.buf] = ""
			return
		end
		local sz = vim.fn.getfsize(p)
		if sz <= 0 then
			_sizes[ev.buf] = ""
		elseif sz < 1024 then
			_sizes[ev.buf] = sz .. "B"
		elseif sz < 1048576 then
			_sizes[ev.buf] = string.format("%.1fKB", sz / 1024)
		else
			_sizes[ev.buf] = string.format("%.1fMB", sz / 1048576)
		end
	end,
})

local function get_filesize()
	local b = vim.api.nvim_get_current_buf()
	return _sizes[b] or ""
end

local _lsp = { val = "", ts = 0 }
local function get_lsp()
	local now = vim.uv.now()
	if now - _lsp.ts < 1500 then
		return _lsp.val
	end
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		_lsp.val = ""
	else
		local parts = {}
		for _, c in ipairs(clients) do
			if c.name ~= "copilot" then
				table.insert(parts, c.name)
			end
		end
		_lsp.val = #parts > 0 and "󰒋 " .. table.concat(parts, ",") or ""
	end
	_lsp.ts = now
	return _lsp.val
end

local _diag = { val = "", ts = 0 }
local function get_diagnostics()
	local now = vim.uv.now()
	if now - _diag.ts < 150 then
		return _diag.val
	end
	local c = vim.diagnostic.count(0)
	local E = c[vim.diagnostic.severity.ERROR] or 0
	local W = c[vim.diagnostic.severity.WARN] or 0
	local parts = {}
	if E > 0 then
		table.insert(parts, "%#MiniStatuslineError# " .. E)
	end
	if W > 0 then
		table.insert(parts, "%#MiniStatuslineWarning# " .. W)
	end
	_diag.val = #parts > 0 and table.concat(parts, " ") or ""
	_diag.ts = now
	return _diag.val
end

local _git = { val = "", ts = 0 }
local function get_git(MiniStatusline)
	local now = vim.uv.now()
	if now - _git.ts < 2000 then
		return _git.val
	end
	local raw = MiniStatusline.section_git({ trunc_width = 60 })
	_git.val = raw ~= "" and raw or ""
	_git.ts = now
	return _git.val
end

-- ============================================================================
-- RENDER CONTROL
-- ============================================================================

local function build_active(MiniStatusline)
	local mode = get_mode()
	local fname, fsuffix, modified, is_welcome = get_filename()
	local fpath = get_filepath()
	local git = get_git(MiniStatusline)
	local diag = get_diagnostics()
	local lsp = get_lsp()
	local fsize = get_filesize()
	local time_icon = get_time_icon()

	local s = ""

	-- ── LEFT SIDE: Core Identity Focus ───────────────────────────────────────
	s = s .. "%#" .. mode.hl .. "#" .. mode.label
	s = s .. "%#MiniStatuslineSecondary# "

	if is_welcome then
		-- Clean, time-sensitive greeting string displayed on the left
		s = s .. "%#MiniStatuslineWelcome#" .. fname
	else
		-- Standard editing view
		local fname_hl = modified and "MiniStatuslineFilenameModified" or "MiniStatuslineFilename"
		s = s .. "%#" .. fname_hl .. "#" .. fname .. (fsuffix or "")

		if fpath ~= "" then
			s = s .. " %#MiniStatuslinePath# " .. fpath
		end

		if git ~= "" then
			s = s .. " %#MiniStatuslineGit# " .. git
		end
	end

	-- ── SPRING CENTER SPACER ────────────────────────────────────────────────
	s = s .. "%#MiniStatuslineSecondary#%<%="

	-- ── RIGHT SIDE: Micro Telemetry ─────────────────────────────────────────
	if not is_welcome then
		if diag ~= "" then
			s = s .. diag .. "  "
		end
		if lsp ~= "" then
			s = s .. "%#MiniStatuslineLSP#" .. lsp .. "  "
		end
		if fsize ~= "" then
			s = s .. "%#MiniStatuslineFileinfo#󰈐 " .. fsize .. "  "
		end
	end

	-- ── BENTO PILL BRACKET (Always visible) ─────────────────────────────────
	s = s .. "%#MiniStatuslineRightPill# " .. time_icon .. " "
	s = s .. "%#MiniStatuslineLocation# %l:%c "
	s = s .. "%#MiniStatuslineProgress#%p%% "

	return s
end

local function build_inactive()
	local fname, fsuffix, _, is_welcome = get_filename()
	if is_welcome then
		return "%#MiniStatuslineInactive# %="
	end

	local suffix_str = (type(fsuffix) == "string") and fsuffix or ""
	return "%#MiniStatuslineInactive#  " .. fname .. suffix_str .. " %="
end

function M.setup()
	local statusline = require("mini.statusline")

	statusline.setup({
		use_icons = true,
		set_vim_settings = false,
	})

	setup_highlights()

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("slc_recolor", { clear = true }),
		callback = setup_highlights,
	})

	statusline.config.content.active = function()
		return build_active(statusline)
	end
	statusline.config.content.inactive = function()
		return build_inactive()
	end
	statusline.section_location = function()
		return "%l:%c"
	end
end

return M
