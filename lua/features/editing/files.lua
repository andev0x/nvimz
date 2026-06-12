local M = {}

-- Safe require helper to safely check for module availability
local function safe_require(module)
	local ok, result = pcall(require, module)
	if ok then
		return result
	end
	return nil
end

-- Static O(1) lookup table for immediately dimming/ignoring build folders
local static_ignored_patterns = {
	["node_modules"] = true,
	[".git"] = true,
	[".cache"] = true,
	["dist"] = true,
	["build"] = true,
	[".next"] = true,
	[".astro"] = true,
}

-- Apply highlight groups (called once at startup + re-applied on ColorScheme change)
local function apply_highlights()
	vim.api.nvim_set_hl(0, "OilGitIgnored", { link = "Comment" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedModified", { link = "MiniDiffSignChange" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedModified", { link = "MiniDiffSignChange" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedAdded", { link = "MiniDiffSignAdd" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedAdded", { link = "MiniDiffSignAdd" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedDeleted", { link = "MiniDiffSignDelete" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedDeleted", { link = "MiniDiffSignDelete" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUntracked", { link = "Comment" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexRenamed", { fg = "#cba6f7" })
end

-- FIXED: Cleaned up the duplicates by leaving 'index' empty and using 'working_tree'
-- This prevents two identical icons from rendering side-by-side in the signcolumn
local git_symbols = {
	index = {
		["M"] = " ",
		["A"] = " ",
		["D"] = " ",
		["R"] = " ",
		["C"] = " ",
		["U"] = " ",
		["?"] = " ",
		["!"] = " ",
		[" "] = " ",
	},
	working_tree = {
		["M"] = "●", -- Modified
		["A"] = "✚", -- Added
		["D"] = "✖", -- Deleted
		["R"] = "»", -- Renamed
		["C"] = "©", -- Copied
		["U"] = "!", -- Conflict
		["?"] = "?", -- Untracked
		["!"] = "◌", -- Ignored
		[" "] = " ",
	},
}

-- Safe wrapper to fully initialize the oil-git-status core setup
local function setup_oil_git(oil_git)
	if not oil_git or type(oil_git.setup) ~= "function" then
		return
	end
	oil_git.setup({
		show_ignored = true,
		symbols = git_symbols,
	})
end

function M.setup()
	require("oil").setup({
		default_file_explorer = true,
		columns = { "icon" },
		win_options = {
			signcolumn = "yes:2",
		},
		view_options = {
			show_hidden = true,
			-- Performant filename highlighting using ultra-fast static O(1) checks
			highlight_filename = function(entry, _, _, _)
				if static_ignored_patterns[entry.name] then
					return "OilGitIgnored"
				end
				if entry.name:sub(1, 1) == "." and entry.name ~= ".." then
					return "OilGitIgnored"
				end
				return nil
			end,
		},
		float = {
			padding = 0,
			border = "rounded",
			-- Evaluated dynamically at window-open time for fluid resizing
			override = function(conf)
				conf.anchor = "NW"
				conf.col = 0
				conf.row = 1
				conf.width = math.floor(vim.o.columns * 0.30)
				conf.height = math.floor(vim.o.lines * 0.85)
				return conf
			end,
		},
	})

	------------------------------------------------------------------------
	-- FIXED: Defer oil-git-status setup to AFTER all plugins are loaded.
	------------------------------------------------------------------------
	vim.schedule(function()
		local oil_git = safe_require("oil-git-status")
		setup_oil_git(oil_git)

		-- Only register the refresh autocmd once we KNOW the module is live
		if oil_git and type(oil_git.refresh_buffer) == "function" then
			vim.api.nvim_create_autocmd("BufReadPost", {
				pattern = "oil://*",
				callback = function(args)
					vim.schedule(function()
						if vim.api.nvim_buf_is_valid(args.buf) then
							oil_git.refresh_buffer(args.buf)
						end
					end)
				end,
			})
		end
	end)

	-- Initialize color configurations and bind to theme-switch hooks
	apply_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_highlights })

	------------------------------------------------------------------------
	-- Toggle floating Oil window helper
	------------------------------------------------------------------------
	local function toggle_oil_float()
		if vim.bo.filetype == "oil" then
			require("oil").close()
			return
		end
		require("oil").open_float()
	end

	vim.keymap.set("n", "<leader>e", toggle_oil_float, { desc = "Toggle Oil (rounded left float)" })
end

return M
