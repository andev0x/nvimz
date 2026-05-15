local M = {}

-- ============================================================================
-- HIGHLIGHTS
-- Soft modern colors designed for long coding sessions
-- ============================================================================

local function setup_highlights()
	local set_hl = vim.api.nvim_set_hl

	-- Main mode colors
	set_hl(0, "MiniStatuslineModeNormal", {
		fg = "#0B1220",
		bg = "#7AA2F7",
		bold = true,
	})

	set_hl(0, "MiniStatuslineModeInsert", {
		fg = "#0B1220",
		bg = "#9ECE6A",
		bold = true,
	})

	set_hl(0, "MiniStatuslineModeVisual", {
		fg = "#0B1220",
		bg = "#BB9AF7",
		bold = true,
	})

	set_hl(0, "MiniStatuslineModeReplace", {
		fg = "#0B1220",
		bg = "#F7768E",
		bold = true,
	})

	set_hl(0, "MiniStatuslineModeCommand", {
		fg = "#0B1220",
		bg = "#E0AF68",
		bold = true,
	})

	-- Neutral sections
	set_hl(0, "MiniStatuslineFilename", {
		fg = "#D4D4D8",
		bg = "#24283B",
		bold = true,
	})

	set_hl(0, "MiniStatuslineDevinfo", {
		fg = "#A9B1D6",
		bg = "#24283B",
	})

	set_hl(0, "MiniStatuslineFileinfo", {
		fg = "#7DCFFF",
		bg = "#24283B",
	})

	set_hl(0, "MiniStatuslineDiagnostics", {
		fg = "#A9B1D6",
		bg = "#24283B",
	})

	set_hl(0, "MiniStatuslineError", {
		fg = "#F7768E",
		bg = "#24283B",
		bold = true,
	})

	set_hl(0, "MiniStatuslineWarning", {
		fg = "#E0AF68",
		bg = "#24283B",
		bold = true,
	})

	set_hl(0, "MiniStatuslineHint", {
		fg = "#7AA2F7",
		bg = "#24283B",
		bold = true,
	})

	set_hl(0, "MiniStatuslineInfo", {
		fg = "#7DCFFF",
		bg = "#24283B",
		bold = true,
	})

	set_hl(0, "MiniStatuslineTime", {
		fg = "#9ECE6A",
		bg = "#24283B",
	})

	set_hl(0, "MiniStatuslineInactive", {
		fg = "#6B7280",
		bg = "#1F2335",
	})

	set_hl(0, "MiniStatuslinePath", {
		fg = "#7C8397",
		bg = "#24283B",
		italic = true,
	})
end

-- ============================================================================
-- MODE
-- ============================================================================

local mode_map = {
	n = { label = "NORMAL", hl = "MiniStatuslineModeNormal" },
	i = { label = "INSERT", hl = "MiniStatuslineModeInsert" },
	v = { label = "VISUAL", hl = "MiniStatuslineModeVisual" },
	V = { label = "VISUAL", hl = "MiniStatuslineModeVisual" },
	[""] = { label = "V-BLOCK", hl = "MiniStatuslineModeVisual" },
	c = { label = "COMMAND", hl = "MiniStatuslineModeCommand" },
	R = { label = "REPLACE", hl = "MiniStatuslineModeReplace" },
	s = { label = "SELECT", hl = "MiniStatuslineModeVisual" },
	S = { label = "SELECT", hl = "MiniStatuslineModeVisual" },
	t = { label = "TERMINAL", hl = "MiniStatuslineInactive" },
}

local function get_mode()
	local mode = vim.fn.mode()
	return mode_map[mode] or mode_map.n
end

-- ============================================================================
-- TIME ICON
-- Ambient biological clock with caching for smoothness
-- ============================================================================

local cached_time_icon = ""
local last_time_update = 0

local function get_time_icon()
	local now = vim.uv.now()
	if now - last_time_update < 60000 then -- Update every 60 seconds
		return cached_time_icon
	end

	local hour = tonumber(os.date("%H"))

	-- Dawn
	if hour >= 5 and hour < 7 then
		cached_time_icon = "󰖚"
	-- Morning focus
	elseif hour >= 7 and hour < 9 then
		cached_time_icon = "󰖨"
	-- Productive work
	elseif hour >= 9 and hour < 12 then
		cached_time_icon = "󰄉"
	-- Lunch time
	elseif hour >= 12 and hour < 13 then
		cached_time_icon = "󰩰"
	-- Hydration / refresh
	elseif hour >= 13 and hour < 14 then
		cached_time_icon = ""
	-- Work
	elseif hour >= 14 and hour < 17 then
		cached_time_icon = "󱍄"
	-- Afternoon
	elseif hour >= 17 and hour < 18 then
		cached_time_icon = "󰖚"
	-- Dinner / relax
	elseif hour >= 18 and hour < 20 then
		cached_time_icon = "󰅶"
	-- Calm evening
	elseif hour >= 20 and hour < 23 then
		cached_time_icon = "󰖔"
	-- Sleep soon
	elseif hour >= 23 and hour < 24 then
		cached_time_icon = "󰒲"
	-- Deep night
	else
		cached_time_icon = "󰭎"
	end

	last_time_update = now
	return cached_time_icon
end

-- ============================================================================
-- FILE NAME
-- ============================================================================

local function get_filename()
	local filename = vim.fn.expand("%:t")

	if filename == "" then
		filename = "Hello, welcome back!"
	end

	if vim.bo.modified then
		filename = filename .. " [+]"
	end

	return filename
end

-- ============================================================================
-- FILE PATH
-- Current working path visualization
-- ============================================================================

local function get_filepath()
	local path = vim.fn.expand("%:~:.:h")

	if path == "." or path == "" then
		return ""
	end

	return "󰉋 " .. path
end

-- ============================================================================
-- FILE SIZE
-- Caching to avoid frequent syscalls during redraw
-- ============================================================================

local filesize_cache = {}

local function update_filesize_cache(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		filesize_cache[bufnr] = ""
		return
	end

	local size = vim.fn.getfsize(path)
	if size <= 0 then
		filesize_cache[bufnr] = ""
	elseif size < 1024 then
		filesize_cache[bufnr] = size .. "B"
	elseif size < 1024 * 1024 then
		filesize_cache[bufnr] = string.format("%.1fKB", size / 1024)
	else
		filesize_cache[bufnr] = string.format("%.1fMB", size / (1024 * 1024))
	end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("statusline_cache", { clear = true }),
	callback = function(args)
		update_filesize_cache(args.buf)
	end,
})

local function get_filesize()
	local bufnr = vim.api.nvim_get_current_buf()
	if not filesize_cache[bufnr] then
		update_filesize_cache(bufnr)
	end
	return filesize_cache[bufnr] or ""
end

-- ============================================================================
-- LSP
-- Caching to avoid querying clients on every redraw
-- ============================================================================

local lsp_icons = require("infra.spec").lsp_icons
local lsp_cache = {
	val = "",
	last_update = 0,
}

local function get_lsp()
	local now = vim.uv.now()
	if now - lsp_cache.last_update < 1000 then -- Update every second
		return lsp_cache.val
	end

	local clients = vim.lsp.get_clients({ bufnr = 0 })

	if #clients == 0 then
		lsp_cache.val = ""
	else
		local names = {}
		for _, client in ipairs(clients) do
			if client.name ~= "copilot" then
				local icon = lsp_icons[client.name] or "󰒋"
				table.insert(names, icon .. " " .. client.name)
			end
		end
		lsp_cache.val = table.concat(names, " ")
	end

	lsp_cache.last_update = now
	return lsp_cache.val
end

-- ============================================================================
-- DIAGNOSTICS
-- Caching to reduce pressure during rapid redraws
-- ============================================================================

local diag_cache = {
	val = "",
	last_update = 0,
}

local function get_diagnostics()
	local now = vim.uv.now()
	if now - diag_cache.last_update < 100 then -- Update max 10 times per second
		return diag_cache.val
	end

	local count = vim.diagnostic.count(0)
	local errors = count[vim.diagnostic.severity.ERROR] or 0
	local warns = count[vim.diagnostic.severity.WARN] or 0
	local hints = count[vim.diagnostic.severity.HINT] or 0
	local infos = count[vim.diagnostic.severity.INFO] or 0

	local parts = {}
	if errors > 0 then
		table.insert(parts, "%#MiniStatuslineError# " .. errors)
	end
	if warns > 0 then
		table.insert(parts, "%#MiniStatuslineWarning# " .. warns)
	end
	if hints > 0 then
		table.insert(parts, "%#MiniStatuslineHint#󰠠 " .. hints)
	end
	if infos > 0 then
		table.insert(parts, "%#MiniStatuslineInfo# " .. infos)
	end

	if #parts > 0 then
		diag_cache.val = " " .. table.concat(parts, " ") .. " "
	else
		diag_cache.val = ""
	end

	diag_cache.last_update = now
	return diag_cache.val
end

-- ============================================================================
-- FILE INFO
-- ============================================================================

local function get_fileinfo()
	local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
	return string.format("%s • %%p%%%%", ft)
end

-- ============================================================================
-- LOCATION
-- ============================================================================

-- Will be set in setup function

-- ============================================================================
-- ACTIVE STATUSLINE
-- ============================================================================

local function setup_active_statusline(statusline, MiniStatusline)
	statusline.section_location = function()
		return "%l:%c"
	end

	statusline.config.content.active = function()
		local mode = get_mode()

		local git = MiniStatusline.section_git({
			trunc_width = 40,
		})

		local location = MiniStatusline.section_location({
			trunc_width = 75,
		})

		return MiniStatusline.combine_groups({
			-- Left section
			{
				hl = mode.hl,
				strings = {
					" " .. mode.label .. " ",
				},
			},

			{
				hl = "MiniStatuslineFilename",
				strings = {
					" " .. get_filename() .. " ",
				},
			},

			{
				hl = "MiniStatuslinePath",
				strings = {
					" " .. get_filepath() .. " ",
				},
			},

			{
				hl = "MiniStatuslineDevinfo",
				strings = {
					git,
				},
			},

			"%<",

			"%=",

			-- Right section
			{
				hl = "MiniStatuslineDiagnostics",
				strings = {
					get_diagnostics(),
				},
			},

			{
				hl = "MiniStatuslineDevinfo",
				strings = {
					" " .. get_lsp() .. " ",
				},
			},

			{
				hl = "MiniStatuslineFileinfo",
				strings = {
					" " .. get_filesize() .. " ",
				},
			},

			{
				hl = "MiniStatuslineFileinfo",
				strings = {
					" " .. get_fileinfo() .. " ",
				},
			},

			{
				hl = "MiniStatuslineTime",
				strings = {
					" " .. get_time_icon() .. " ",
				},
			},

			{
				hl = "MiniStatuslineInactive",
				strings = {
					" " .. location .. " ",
				},
			},
		})
	end
end

-- ============================================================================
-- INACTIVE STATUSLINE
-- ============================================================================

local function setup_inactive_statusline(statusline, MiniStatusline)
	statusline.config.content.inactive = function()
		return MiniStatusline.combine_groups({
			{
				hl = "MiniStatuslineInactive",
				strings = {
					" " .. get_filename() .. " ",
				},
			},
		})
	end
end

-- ============================================================================
-- MAIN SETUP
-- ============================================================================

function M.setup()
	local statusline = require("mini.statusline")

	statusline.setup({
		use_icons = true,
		set_vim_settings = false,
	})

	local MiniStatusline = statusline

	setup_highlights()
	setup_active_statusline(statusline, MiniStatusline)
	setup_inactive_statusline(statusline, MiniStatusline)
end

return M
