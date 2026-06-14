local M = {}

local function safe_require(module)
	local ok, result = pcall(require, module)
	if ok then
		return result
	end
	return nil
end

local static_ignored_patterns = {
	["node_modules"] = true,
	[".git"] = true,
	[".cache"] = true,
	["dist"] = true,
	["build"] = true,
	[".next"] = true,
	[".astro"] = true,
}

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

-- Leave index empty, use working_tree only — prevents duplicate icons in signcolumn
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
		["M"] = "●",
		["A"] = "✚",
		["D"] = "✖",
		["R"] = "»",
		["C"] = "©",
		["U"] = "!",
		["?"] = "?",
		["!"] = "◌",
		[" "] = " ",
	},
}

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

	vim.schedule(function()
		local oil_git = safe_require("oil-git-status")
		setup_oil_git(oil_git)

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

	apply_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_highlights })

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
