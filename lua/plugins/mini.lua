local M = {}

function M.setup()
	-- =========================================================================
	-- 1. MINI.FILES (File Explorer with Custom File Creation Keymap)
	-- =========================================================================
	require("mini.files").setup({
		windows = {
			preview = true,
			width_preview = 80,
		},
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

	-- LSP Pickers (FIXED: Remapped to leader-prefixed keys to avoid conflicting with core LSP bindings)
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

	-- =========================================================================
	-- 5. MINI.STATUSLINE (Clean Minimal Style)
	-- =========================================================================
	local statusline = require("mini.statusline")
	statusline.setup({
		use_icons = true,
		set_vim_settings = false,
	})

	-- Helpers for statusline
	local function mode_hl()
		local mode = vim.fn.mode()
		local map = {
			n = "MiniStatuslineModeNormal",
			i = "MiniStatuslineModeInsert",
			v = "MiniStatuslineModeVisual",
			V = "MiniStatuslineModeVisual",
			[""] = "MiniStatuslineModeVisual",
			c = "MiniStatuslineModeCommand",
			R = "MiniStatuslineModeReplace",
			t = "MiniStatuslineModeTerminal",
		}
		return map[mode] or "MiniStatuslineModeNormal"
	end

	local function mode_name()
		local mode = vim.fn.mode()
		local map = {
			n = "NORMAL",
			i = "INSERT",
			v = "VISUAL",
			V = "VISUAL",
			[""] = "V-BLOCK",
			c = "COMMAND",
			R = "REPLACE",
			t = "TERMINAL",
		}
		return map[mode] or mode
	end

	local function brand()
		local hour = tonumber(vim.fn.strftime("%H"))
		if hour >= 6 and hour < 18 then
			return "󰖨 nvimz"
		end
		return "󰼱 nvimz"
	end

	local function lsp()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		if #clients == 0 then
			return ""
		end
		return "󰒋 " .. clients[1].name
	end

	local function diagnostics()
		local count = vim.diagnostic.count(0)
		local errors = count[vim.diagnostic.severity.ERROR] or 0
		local warns = count[vim.diagnostic.severity.WARN] or 0

		local parts = {}
		if errors > 0 then
			table.insert(parts, " " .. errors)
		end
		if warns > 0 then
			table.insert(parts, " " .. warns)
		end
		return table.concat(parts, " ")
	end

	statusline.section_location = function()
		return "%l:%c"
	end

	-- Active Statusline Content Configuration
	statusline.config.content.active = function()
		local filename = MiniStatusline.section_filename({ trunc_width = 140 })
		local git = MiniStatusline.section_git({ trunc_width = 40 })
		local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
		local location = MiniStatusline.section_location({ trunc_width = 75 })

		return MiniStatusline.combine_groups({
			-- Left Side
			{ hl = "MiniStatuslineInactive", strings = { " " .. brand() } },
			{ hl = mode_hl(), strings = { " " .. mode_name() .. " " } },
			{ hl = "MiniStatuslineDevinfo", strings = { git } },
			{ hl = "MiniStatuslineFilename", strings = { filename } },
			"%<",
			"%=",
			-- Right Side
			{ hl = "MiniStatuslineDiagnostics", strings = { diagnostics() } },
			{ hl = "MiniStatuslineDevinfo", strings = { lsp() } },
			{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
			{ hl = mode_hl(), strings = { " " .. location .. " " } },
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
