local M = {}

local git = require("infra.deps.git")

function M.run()
	local plugins = vim.pack.get()
	local plugin_count = #plugins

	local outdated = 0
	for _, plugin in ipairs(plugins) do
		local branch = git.get_default_branch(plugin.path)
		local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local remote_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "origin/" .. branch }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		if local_rev ~= remote_rev then
			outdated = outdated + 1
		end
	end

	local startup_time = 0
	if _G.nvimz_start_time then
		startup_time = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6
	end

	local health_ok = true
	local tools = require("infra.registry.tools")
	local check = require("infra.health.check")
	for _, tool in ipairs(tools.core) do
		if tool.required and not check.executable(tool.bin) then
			health_ok = false
		end
	end

	local lock_ok = true
	local lock_path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(lock_path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local ok, lock = pcall(vim.json.decode, content)
		if ok and lock.plugins then
			for _, plugin in ipairs(plugins) do
				local name = plugin.spec.name or plugin.spec.src
				local entry = lock.plugins[name]
				local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
					:wait().stdout
					:gsub("\n", "")
				if not entry or entry.rev ~= local_rev then
					lock_ok = false
					break
				end
			end
		else
			lock_ok = false
		end
	else
		lock_ok = false
	end

	print(
		string.format(
			"nvimz Status: plugins=%d, outdated=%d, startup=%.2fms, health=%s, lockfile=%s",
			plugin_count,
			outdated,
			startup_time,
			health_ok and "OK" or "WARNING",
			lock_ok and "In Sync" or "Out of Sync"
		)
	)
end

return M
