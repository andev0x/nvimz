local M = {}

local git = require("infra.deps.git")

function M.run()
	local snapshot_dir = vim.fn.stdpath("config") .. "/snapshots"
	if vim.fn.isdirectory(snapshot_dir) == 0 then
		vim.fn.mkdir(snapshot_dir, "p")
	end

	local cache = require("infra.cache")
	local startup_stats = cache.get("startup_stats") or {}

	local plugins = {}
	for _, plugin in ipairs(vim.pack.get()) do
		local name = plugin.spec.name or plugin.spec.src
		local rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local branch = git.get_default_branch(plugin.path)
		plugins[name] = {
			rev = rev,
			branch = branch,
			src = plugin.spec.src,
		}
	end

	local uname = vim.uv.os_uname()
	local machine = {
		os = uname.sysname,
		release = uname.release,
		version = uname.version,
		arch = uname.machine,
		nvim_version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
	}

	local snapshot = {
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		startup = startup_stats,
		plugins = plugins,
		machine = machine,
	}

	local filename = snapshot_dir .. "/snapshot_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
	local f = io.open(filename, "w")
	if f then
		f:write(vim.json.encode(snapshot))
		f:close()
		print("󰄬 Snapshot generated: " .. filename)
	else
		print("❌ Failed to write snapshot file!")
	end
end

return M
