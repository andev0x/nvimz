local M = {}

function M.generate()
	local plugins = vim.pack.get()
	local lock = { plugins = {} }

	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		lock.plugins[name] = {
			rev = rev,
			src = plugin.spec.src,
		}
	end

	local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(path, "w")
	if f then
		f:write(vim.json.encode(lock))
		f:close()
	end
end

return M
