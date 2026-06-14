local M = {}

-- Define highlight groups for the statusline using Tokyonight colors.
local function setup_highlights()
	local set_hl = vim.api.nvim_set_hl
	local colors = require("tokyonight.colors").setup({ style = "moon" })

	-- Base background for the statusline.
	local base_bg = colors.bg_statusline
	-- Background for the rightmost anchor pill.
	local right_pill_bg = colors.bg_highlight

	-- Mode indicators.
	set_hl(0, "MiniStatuslineModeNormal", { fg = colors.bg_dark, bg = colors.blue, bold = true })
	set_hl(0, "MiniStatuslineModeInsert", { fg = colors.bg_dark, bg = colors.green, bold = true })
	set_hl(0, "MiniStatuslineModeVisual", { fg = colors.bg_dark, bg = "#9d7cd8", bold = true })
	set_hl(0, "MiniStatuslineModeReplace", { fg = colors.bg_dark, bg = colors.red1, bold = true })
	set_hl(0, "MiniStatuslineModeCommand", { fg = colors.bg_dark, bg = colors.orange, bold = true })
	set_hl(0, "MiniStatuslineModeTerminal", { fg = colors.bg_dark, bg = colors.teal, bold = true })

	-- Primary content.
	set_hl(0, "MiniStatuslineFilename", { fg = colors.fg, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslineFilenameModified", { fg = colors.yellow, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslinePath", { fg = colors.dark3, bg = base_bg })
	set_hl(0, "MiniStatuslineWelcome", { fg = colors.blue, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslineGit", { fg = colors.dark5, bg = base_bg })

	-- Diagnostics.
	set_hl(0, "MiniStatuslineError", { fg = colors.error, bg = base_bg, bold = true })
	set_hl(0, "MiniStatuslineWarning", { fg = colors.warning, bg = base_bg, bold = true })

	-- Metadata.
	set_hl(0, "MiniStatuslineLSP", { fg = colors.fg_dark, bg = base_bg })
	set_hl(0, "MiniStatuslineFileinfo", { fg = colors.dark5, bg = base_bg })

	-- Right anchor pill.
	set_hl(0, "MiniStatuslineRightPill", { fg = colors.purple, bg = right_pill_bg, bold = true })
	set_hl(0, "MiniStatuslineLocation", { fg = colors.fg, bg = right_pill_bg, bold = true })
	set_hl(0, "MiniStatuslineProgress", { fg = colors.dark5, bg = right_pill_bg })

	-- Spacers.
	set_hl(0, "MiniStatuslineSecondary", { fg = base_bg, bg = base_bg })
	set_hl(0, "MiniStatuslineInactive", { fg = colors.dark3, bg = base_bg })
end

-- Map Vim modes to label and highlight group.
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

-- Cache time icon for one minute to avoid repeated computation.
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

-- Determine filename, greeting, and modification state.
local function get_filename()
	local name = vim.fn.expand("%:t")
	local ft = vim.bo.filetype
	local modified = vim.bo.modified

	if name == "" or ft == "dashboard" or ft == "alpha" or ft == "starter" then
		if not modified then
			local username = vim.env.USER or vim.env.USERNAME or "User"
			local h = tonumber(os.date("%H"))
			local greeting, icon = "", ""

			if h >= 5 and h < 12 then
				greeting, icon = "Good morning", "󰖨"
			elseif h >= 12 and h < 18 then
				greeting, icon = "Good afternoon", "󰖚"
			elseif h >= 18 and h < 22 then
				greeting, icon = "Good evening", "󰅶"
			else
				greeting, icon = "Good night", "󰖔"
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

-- Shorten long paths for display.
local function get_filepath()
	local path = vim.fn.expand("%:~:.:h")
	if path == "." or path == "" then
		return ""
	end

	local parts = vim.split(path, "/", { plain = true })
	if #parts > 2 then
		path = parts[1] .. "/…/" .. parts[#parts - 1] .. "/" .. parts[#parts]
	elseif #parts > 1 then
		path = parts[1] .. "/" .. parts[#parts]
	end

	return path
end

-- Cache file sizes per buffer; updated on read/write/enter events.
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

-- Cache LSP client list for 1.5 s to reduce UI latency.
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
		if #parts > 0 then
			local server_names = table.concat(parts, ",")
			local ft = vim.bo.filetype
			local has_mini_icons, MiniIcons = pcall(require, "mini.icons")
			if has_mini_icons then
				local icon, hl = MiniIcons.get("filetype", ft)
				_lsp.val = string.format("%%#%s#%s %%#MiniStatuslineLSP#%s", hl, icon, server_names)
			else
				_lsp.val = "%#MiniStatuslineLSP#󰒋 " .. server_names
			end
		else
			_lsp.val = ""
		end
	end
	_lsp.ts = now
	return _lsp.val
end

-- Cache diagnostic counts for 150 ms to avoid excessive redraws.
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

-- Cache git status for 2 s; uses MiniStatusline's built‑in git section.
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

-- Assemble active statusline.
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

	-- Left side: mode indicator and file information.
	s = s .. "%#" .. mode.hl .. "#" .. mode.label
	s = s .. "%#MiniStatuslineSecondary# "

	if is_welcome then
		s = s .. "%#MiniStatuslineWelcome#" .. fname
	else
		local fname_hl = modified and "MiniStatuslineFilenameModified" or "MiniStatuslineFilename"
		s = s .. "%#" .. fname_hl .. "#" .. fname .. (fsuffix or "")
		if fpath ~= "" then
			s = s .. " %#MiniStatuslinePath# " .. fpath
		end
		if git ~= "" then
			s = s .. " %#MiniStatuslineGit# " .. git
		end
	end

	-- Center spacer.
	s = s .. "%#MiniStatuslineSecondary#%<%="

	-- Right side: diagnostics, LSP, filesize, and anchor pill.
	if not is_welcome then
		if diag ~= "" then
			s = s .. diag .. "  "
		end
		if lsp ~= "" then
			s = s .. lsp .. "  "
		end
		if fsize ~= "" then
			s = s .. "%#MiniStatuslineFileinfo#󰈐 " .. fsize .. "  "
		end
	end

	s = s .. "%#MiniStatuslineRightPill# " .. time_icon .. "  "
	s = s .. "%#MiniStatuslineLocation#%l:%c  "
	s = s .. "%#MiniStatuslineProgress#%p%% "

	return s
end

-- Assemble inactive statusline.
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

	-- Redraw statusline when LSP clients attach/detach.
	vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
		group = vim.api.nvim_create_augroup("slc_lsp_icon", { clear = true }),
		callback = function()
			vim.cmd("redrawstatus")
		end,
	})

	-- Reapply highlights on colorscheme change.
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
	-- Ensure location section matches the anchor pill layout.
	statusline.section_location = function()
		return "%l:%c"
	end
end

return M
