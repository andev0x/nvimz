local M = {}

-- Cache for gitignored files to keep navigation performant
local git_ignored_cache = setmetatable({}, { __mode = "v" })

local function is_ignored(path)
	if git_ignored_cache[path] ~= nil then
		return git_ignored_cache[path]
	end

	-- Check if the path is ignored by git
	-- Use 'git check-ignore' which is reliable but requires a process call
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
		-- Let oil take over directory buffers
		default_file_explorer = true,
		columns = {
			"icon",
		},
		win_options = {
			signcolumn = "yes:2",
		},
		view_options = {
			show_hidden = true,
			highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
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
	})

	require("oil-git-status").setup()

	vim.api.nvim_set_hl(0, "OilGitIgnored", { link = "Comment" })

	vim.keymap.set("n", "<leader>e", function()
		if vim.bo.filetype == "oil" then
			require("oil").close()
		else
			require("oil").open()
		end
	end, { desc = "Toggle Oil" })
end

return M
