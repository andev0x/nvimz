local M = {}

local git_root_cache = {}
local git_ignore_cache = {}

local function get_git_root(path)
	local dir = vim.fs.dirname(path)
	if git_root_cache[dir] ~= nil then
		return git_root_cache[dir]
	end

	local git_dir = vim.fs.find(".git", { path = dir, upward = true })[1]
	local root = git_dir and vim.fs.dirname(git_dir) or nil
	git_root_cache[dir] = root
	return root
end

local function is_git_ignored(path)
	local root = get_git_root(path)
	if not root then
		return false
	end

	local rel = vim.fs.normalize(path):sub(#vim.fs.normalize(root) + 2)
	local cache_key = root .. "::" .. rel
	if git_ignore_cache[cache_key] ~= nil then
		return git_ignore_cache[cache_key]
	end

	vim.fn.system({ "git", "-C", root, "check-ignore", "-q", "--", rel })
	local ignored = vim.v.shell_error == 0
	git_ignore_cache[cache_key] = ignored
	return ignored
end

function M.setup()
	require("mini.files").setup({
		content = {
			highlight = function(fs_entry)
				if is_git_ignored(fs_entry.path) then
					return "MiniFilesGitIgnored"
				end

				return MiniFiles.default_highlight(fs_entry)
			end,
		},
		windows = {
			preview = true,
			width_preview = 80,
		},
		-- Ensure mini.files uses the icons we setup above
		use_icons = true,
	})

	vim.api.nvim_set_hl(0, "MiniFilesGitIgnored", { link = "Comment" })

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
end

return M
