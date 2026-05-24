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
	require("mini.files").setup({
		content = {
			highlight = function(fs_entry)
				if is_ignored(fs_entry.path) then
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
