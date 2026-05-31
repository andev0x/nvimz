local M = {}

function M.run()
	local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(path, "r")
	if not f then
		print("❌ Lockfile missing!")
		return
	end
	local content = f:read("*a")
	f:close()

	local lock = vim.json.decode(content)
	local plugins = vim.pack.get()

	print("󰚰 Rolling back plugins to lockfile state...")
	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local entry = lock.plugins[name]
		if entry and entry.rev then
			print("  Resetting " .. name .. " to " .. entry.rev:sub(1, 7) .. "...")
			vim.system({ "git", "-C", plugin.path, "reset", "--hard", entry.rev }):wait()
		else
			print("  ⚠️ No lockfile entry for " .. name)
		end
	end
	print("󰄬 Rollback complete.")
end

return M
