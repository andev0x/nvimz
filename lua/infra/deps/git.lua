local M = {}

function M.get_default_branch(path)
	local obj = vim.system({ "git", "-C", path, "remote", "show", "origin" }, { text = true }):wait()
	if obj.code ~= 0 then
		return "main"
	end
	for line in vim.gsplit(obj.stdout, "\n") do
		local branch = line:match("HEAD branch: (.+)")
		if branch then
			return branch
		end
	end
	return "main"
end

return M
