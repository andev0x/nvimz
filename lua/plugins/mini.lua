local M = {}

function M.setup()
	-- =========================================================================
	-- 0. MINI.ICONS (Setup this FIRST so other mini modules can inherit it)
	-- =========================================================================
	-- We load and register mini.icons first. This automatically provides icons
	-- to mini.files, mini.pick, and mini.statusline.
	require("mini.icons").setup({
		-- Style: 'glyph' (standard) or 'ascii'
		style = "glyph",
		-- Customizing specific icons to fit Catppuccin Mocha palette or your preference
		custom = {
			-- Custom file extension icons
			extension = {
				lua = { glyph = "", hl = "MiniIconsAzure" },
				md = { glyph = "", hl = "MiniIconsGreen" },
			},
			-- Custom system/filetype icons
			file = {
				[".gitignore"] = { glyph = "", hl = "MiniIconsOrange" },
			},
			-- Custom directory icon (if you want to override the default folder icon)
			directory = {
				folder = { glyph = "󰉋", hl = "MiniIconsBlue" },
			},
		},
	})
	-- Mock mini.icons as 'nvim-web-devicons' so non-mini plugins can also use it
	MiniIcons.mock_nvim_web_devicons()

	-- =========================================================================
	-- 1. MINI.FILES (File Explorer with Custom File Creation Keymap)
	-- =========================================================================
	require("mini.files").setup({
		windows = {
			preview = true,
			width_preview = 80,
		},
		-- Ensure mini.files uses the icons we setup above
		use_icons = true,
	})

	vim.keymap.set("n", "<leader>e", function()
		if not MiniFiles.close() then
			MiniFiles.open(vim.api.nvim_buf_get_name(0))
		end
	end, { desc = "Toggle Mini Files" })

	-- Create an autocommand to map 'a' inside mini.files buffer for quick creation
	vim.api.nvim_create_autocmd("User", {
		pattern = "MiniFilesBufferCreate",
		callback = function(args)
			local buf_id = args.data.buf_id

			-- Pressing 'a' inserts a new line below and automatically enters insert mode
			vim.keymap.set("n", "a", function()
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o", true, true, true), "n", true)
			end, { buffer = buf_id, desc = "Create new File/Folder" })
		end,
	})

	-- =========================================================================
	-- 2. MINI.PAIRS (Smart & Minimalist Auto-Pairs)
	-- =========================================================================
	require("mini.pairs").setup({
		modes = { insert = true, command = false, terminal = false },
		mappings = {
			["("] = { action = "open", close = ")", register = { cr = true } },
			["["] = { action = "open", close = "]", register = { cr = true } },
			["{"] = { action = "open", close = "}", register = { cr = true } },

			[")"] = { action = "close", close = ")", register = { cr = true } },
			["]"] = { action = "close", close = "]", register = { cr = true } },
			["}"] = { action = "close", close = "}", register = { cr = true } },

			-- Auto-close double quotes (Strings)
			['"'] = { action = "closeopen", close = '"', register = { cr = true } },

			-- Avoid auto-closing single quotes on Rust lifetimes (e.g., 'a)
			["'"] = {
				action = "closeopen",
				close = "'",
				register = { cr = true },
				neigh_pattern = "[^%a].",
			},

			-- Template literals for JS/TS/Go backticks
			["`"] = { action = "closeopen", close = "`", register = { cr = true } },
		},
	})

	-- =========================================================================
	-- 3. MINI.PICK (Fuzzy Finder) & MINI.EXTRA
	-- =========================================================================
	require("mini.pick").setup({
		window = {
			config = function()
				local height = math.floor(0.618 * vim.o.lines)
				local width = math.floor(0.618 * vim.o.columns)
				return {
					anchor = "NW",
					height = height,
					width = width,
					row = math.floor(0.5 * (vim.o.lines - height)),
					col = math.floor(0.5 * (vim.o.columns - width)),
				}
			end,
		},
		options = {
			content_from_bottom = true,
		},
	})

	-- General Finders
	vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
	vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
	vim.keymap.set("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Help tags" })

	require("mini.extra").setup()
	vim.keymap.set("n", "<leader>gc", "<cmd>lua MiniExtra.pickers.git_commits()<cr>", { desc = "Git commits" })
	vim.keymap.set("n", "<leader>gh", "<cmd>lua MiniExtra.pickers.git_hunks()<cr>", { desc = "Git hunks" })

	-- LSP Pickers
	vim.keymap.set("n", "<leader>lr", "<cmd>Pick lsp scope='references'<cr>", { desc = "LSP References (Picker)" })
	vim.keymap.set("n", "<leader>ld", "<cmd>Pick lsp scope='definition'<cr>", { desc = "LSP Definition (Picker)" })
	vim.keymap.set(
		"n",
		"<leader>ly",
		"<cmd>Pick lsp scope='type_definition'<cr>",
		{ desc = "LSP Type Definition (Picker)" }
	)
	vim.keymap.set(
		"n",
		"<leader>li",
		"<cmd>Pick lsp scope='implementation'<cr>",
		{ desc = "LSP Implementation (Picker)" }
	)
	vim.keymap.set(
		"n",
		"<leader>cs",
		"<cmd>Pick lsp scope='document_symbol'<cr>",
		{ desc = "LSP Document Symbols (Outline)" }
	)
	vim.keymap.set("n", "<leader>cS", "<cmd>Pick lsp scope='workspace_symbol'<cr>", { desc = "LSP Workspace Symbols" })

	-- =========================================================================
	-- 4. MINI.GIT & MINI.DIFF
	-- =========================================================================
	require("mini.git").setup()
	vim.keymap.set({ "n", "x" }, "<leader>gs", "<cmd>Git<cr>", { desc = "Git status" })
	vim.keymap.set({ "n", "x" }, "<leader>gb", "<cmd>lua MiniGit.show_at_cursor()<cr>", { desc = "Git blame" })

	require("mini.diff").setup()
	vim.keymap.set("n", "<leader>gd", function()
		if MiniDiff.get_buf_data() == nil then
			MiniDiff.enable()
		end
		MiniDiff.toggle_overlay()
	end, { desc = "Toggle diff overlay" })

	-- ============================================================================
	-- 5. MINI.STATUSLINE
	-- ============================================================================

	local statusline = require("mini.statusline")

	statusline.setup({
		use_icons = true,
		set_vim_settings = false,
	})

	local MiniStatusline = statusline

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
			fg = "#E0AF68",
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

	setup_highlights()

	-- ============================================================================
	-- MODE
	-- ============================================================================

	local mode_map = {
		n = { label = "NORMAL", hl = "MiniStatuslineModeNormal" },
		i = { label = "INSERT", hl = "MiniStatuslineModeInsert" },
		v = { label = "VISUAL", hl = "MiniStatuslineModeVisual" },
		V = { label = "VISUAL", hl = "MiniStatuslineModeVisual" },
		[""] = { label = "V-BLOCK", hl = "MiniStatuslineModeVisual" },
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
	-- Ambient biological clock
	-- ============================================================================

	local function get_time_icon()
		local hour = tonumber(vim.fn.strftime("%H"))

		-- Dawn
		if hour >= 5 and hour < 7 then
			return "󰖚"

		-- Morning focus
		elseif hour >= 7 and hour < 9 then
			return ""

		-- Productive work
		elseif hour >= 9 and hour < 12 then
			return "󱎫"

		-- Lunch time
		elseif hour >= 12 and hour < 13 then
			return "󰩰"

		-- Hydration / refresh
		elseif hour >= 13 and hour < 14 then
			return ""

		-- Work
		elseif hour >= 14 and hour < 17 then
			return "󱍄"

		-- Afternoon
		elseif hour >= 17 and hour < 18 then
			return "󰖚"

		-- Dinner / relax
		elseif hour >= 18 and hour < 20 then
			return "󰅶"

		-- Calm evening
		elseif hour >= 20 and hour < 23 then
			return "󰖔"

		-- Sleep soon
		elseif hour >= 23 and hour < 24 then
			return "󰒲"

		-- Deep night
		else
			return ""
		end
	end

	-- ============================================================================
	-- FILE NAME
	-- ============================================================================

	local function get_filename()
		local filename = vim.fn.expand("%:t")

		if filename == "" then
			filename = "[No Name]"
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
	-- ============================================================================

	local function get_filesize()
		local size = vim.fn.getfsize(vim.fn.expand("%:p"))

		if size <= 0 then
			return ""
		end

		if size < 1024 then
			return size .. "B"
		elseif size < 1024 * 1024 then
			return string.format("%.1fKB", size / 1024)
		else
			return string.format("%.1fMB", size / (1024 * 1024))
		end
	end

	-- ============================================================================
	-- LSP
	-- ============================================================================

	local lsp_icons = require("infra.spec").lsp_icons

	local function get_lsp()
		local clients = vim.lsp.get_clients({ bufnr = 0 })

		if #clients == 0 then
			return ""
		end

		local names = {}

		for _, client in ipairs(clients) do
			if client.name ~= "copilot" then
				local icon = lsp_icons[client.name] or "󰒋"
				table.insert(names, icon .. " " .. client.name)
			end
		end

		return table.concat(names, " ")
	end

	-- ============================================================================
	-- DIAGNOSTICS
	-- ============================================================================

	local function get_diagnostics()
		local count = vim.diagnostic.count(0)

		local errors = count[vim.diagnostic.severity.ERROR] or 0
		local warns = count[vim.diagnostic.severity.WARN] or 0
		local hints = count[vim.diagnostic.severity.HINT] or 0

		local parts = {}

		if errors > 0 then
			table.insert(parts, " " .. errors)
		end

		if warns > 0 then
			table.insert(parts, " " .. warns)
		end

		if hints > 0 then
			table.insert(parts, "󰌵 " .. hints)
		end

		return table.concat(parts, " ")
	end

	-- ============================================================================
	-- FILE INFO
	-- ============================================================================

	local function get_fileinfo()
		local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"

		local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding

		local format = vim.bo.fileformat

		return string.format("%s • %s • %s", ft, encoding, format)
	end

	-- ============================================================================
	-- LOCATION
	-- ============================================================================

	statusline.section_location = function()
		return "%l:%c"
	end

	-- ============================================================================
	-- ACTIVE STATUSLINE
	-- ============================================================================

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
				hl = "MiniStatuslineInactive",
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

	-- ============================================================================
	-- INACTIVE STATUSLINE
	-- ============================================================================

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

	-- =========================================================================
	-- 6. MINI.COMPLETION & TAB NAVIGATION
	-- =========================================================================
	require("mini.completion").setup({
		lsp_completion = {
			source_func = "completefunc",
			auto_setup = true,
		},
		window = {
			info = { border = "rounded" },
			signature = { border = "rounded" },
		},
	})

	-- Set up Tab/S-Tab for smooth command-line/insert completion navigation
	local imap = function(lhs, rhs)
		vim.keymap.set("i", lhs, rhs, { expr = true, replace_keycodes = false })
	end

	imap("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
	imap("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])
end

return M
