local M = {}

function M.get_default_branch(path)
	-- Try to get from remote HEAD reference first (fast, no network)
	local obj = vim.system({ "git", "-C", path, "symbolic-ref", "refs/remotes/origin/HEAD" }, { text = true }):wait()
	if obj.code == 0 then
		local branch = obj.stdout:match("refs/remotes/origin/(.+)")
		if branch then
			return branch:gsub("\n", "")
		end
	end

	-- Fallback to remote show (slow, network)
	obj = vim.system({ "git", "-C", path, "remote", "show", "origin" }, { text = true }):wait()
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
