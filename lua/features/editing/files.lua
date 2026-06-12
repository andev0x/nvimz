local M = {}

-- Safe require helper
local function safe_require(module)
	local ok, result = pcall(require, module)
	if ok then
		return result
	end
	return nil
end

-- Static list of common build/generated folders to dim immediately (Zero Lag)
local static_ignored_patterns = {
	["node_modules"] = true,
	[".git"] = true,
	[".cache"] = true,
	["dist"] = true,
	["build"] = true,
	[".next"] = true,
	[".astro"] = true,
}

function M.setup()
	require("oil").setup({
		default_file_explorer = true,
		columns = {
			"icon",
		},
		win_options = {
			-- yes:2 gives enough space for the git status signs on the left margin
			signcolumn = "yes:2",
		},
		view_options = {
			show_hidden = true,
			-- Performant filename highlighting using static O(1) lookups
			highlight_filename = function(entry, _, _, _)
				if static_ignored_patterns[entry.name] then
					return "OilGitIgnored"
				end

				-- Dim files/folders starting with a dot
				if string.sub(entry.name, 1, 1) == "." and entry.name ~= ".." then
					return "OilGitIgnored"
				end

				return nil
			end,
		},

		-- Floating‑window configuration for the "rounded‑left" layout
		float = {
			padding = 0,
			border = "rounded",
			max_width = math.floor(vim.o.columns * 0.30),
			max_height = math.floor(vim.o.lines * 0.85),

			override = function(conf)
				conf.anchor = "NW"
				conf.col = 0
				conf.row = 1
				return conf
			end,
		},
	})

	-- Initialize oil-git-status after Oil is set up
	local oil_git = safe_require("oil-git-status")
	if oil_git and type(oil_git.setup) == "function" then
		oil_git.setup()
	end

	------------------------------------------------------------------------
	-- FIXED: Force oil-git-status to update manually when Oil buffer loads
	------------------------------------------------------------------------
	vim.api.nvim_create_autocmd("BufWinEnter", {
		pattern = "oil",
		callback = function()
			-- Give a tiny 10ms delay for the floating window layout to settle down,
			-- then force oil-git-status to run its internal update logic
			vim.defer_fn(function()
				local status_module = safe_require("oil-git-status")
				if status_module and type(status_module.update) == "function" then
					status_module.update()
				end
			end, 10)
		end,
	})

	------------------------------------------------------------------------
	-- Highlight Color Customization (Links to Catppuccin Mocha colors)
	------------------------------------------------------------------------
	-- Dimmed out gray color for ignored/hidden files
	vim.api.nvim_set_hl(0, "OilGitIgnored", { link = "Comment" })

	-- Map oil-git-status highlights to the current theme colors smoothly
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedModified", { link = "MiniDiffSignChange" }) -- Yellow
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedModified", { link = "MiniDiffSignChange" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedAdded", { link = "MiniDiffSignAdd" }) -- Green
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedAdded", { link = "MiniDiffSignAdd" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUnstagedDeleted", { link = "MiniDiffSignDelete" }) -- Red
	vim.api.nvim_set_hl(0, "OilGitStatusIndexStagedDeleted", { link = "MiniDiffSignDelete" })
	vim.api.nvim_set_hl(0, "OilGitStatusIndexUntracked", { link = "Comment" }) -- Gray/Dimmed
	vim.api.nvim_set_hl(0, "OilGitStatusIndexRenamed", { fg = "#cba6f7" }) -- Catppuccin Mauve

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

	vim.keymap.set("n", "<leader>e", toggle_oil_float, { desc = "Toggle Oil (rounded left float)" })
end

return M
