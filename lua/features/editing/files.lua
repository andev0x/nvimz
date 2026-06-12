local M = {}

-- Cache for gitignored files to keep navigation performant
local git_ignored_cache = setmetatable({}, { __mode = "v" })

local function is_ignored(path)
	if git_ignored_cache[path] ~= nil then
		return git_ignored_cache[path]
	end

	-- Check if the path is ignored by git
	local handle = io.popen("git check-ignore " .. vim.fn.shellescape(path) .. " 2>/dev/null")
	if not handle then
		return false
	end

	local result = handle:read("*a")
	handle:close()

	local ignored = result ~= ""
	git_ignored_cache[path] = ignored
	return ignored
end

function M.setup()
	require("oil").setup({
		default_file_explorer = true,
		columns = {
			"icon",
		},
		win_options = {
			signcolumn = "yes:2",
		},
		view_options = {
			show_hidden = true,
			highlight_filename = function(entry, _, _, _)
				local dir = require("oil").get_current_dir()
				if dir then
					local path = dir .. entry.name
					if is_ignored(path) then
						return "OilGitIgnored"
					end
				end
				return nil
			end,
		},

		-- ★ FIXED: Correct structure for the floating window API in oil.nvim
		float = {
			padding = 0,
			border = "rounded",
			-- Fix width to 30% of screen, height to 85% to look balanced
			max_width = math.floor(vim.o.columns * 0.30),
			max_height = math.floor(vim.o.lines * 0.85),

			-- Override to force the window to attach directly to the top-left corner
			override = function(conf)
				conf.anchor = "NW"
				conf.col = 0
				conf.row = 1 -- Leaves 1 line from top so it doesn't clip the tabline/header
				return conf
			end,
		},
	})

	-- Initialize git status integration
	require("oil-git-status").setup()

	-- Link the highlight group to the theme's Comment color
	vim.api.nvim_set_hl(0, "OilGitIgnored", { link = "Comment" })

	------------------------------------------------------------------------
	-- Helper that toggles the *floating* Oil window
	------------------------------------------------------------------------
	local function toggle_oil_float()
		if vim.bo.filetype == "oil" then
			require("oil").close()
			return
		end

		require("oil").open_float()
	end

	-- Toggle shortcut
	vim.keymap.set("n", "<leader>e", toggle_oil_float, { desc = "Toggle Oil (rounded left float)" })
end

return M
