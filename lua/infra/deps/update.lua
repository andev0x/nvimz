local M = {}

local git = require("infra.deps.git")

function M.check()
	local plugins = vim.pack.get()
	local results = {}

	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		io.write(string.format(" 󰆓 %-20s", name))
		io.flush()

		vim.system({ "git", "-C", plugin.path, "fetch", "origin", "--quiet" }):wait()

		local branch = git.get_default_branch(plugin.path)
		local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local remote_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "origin/" .. branch }, { text = true })
			:wait().stdout
			:gsub("\n", "")

		if local_rev ~= remote_rev then
			print(string.format(" → pending update (%s)", branch))
			table.insert(results, {
				plugin = plugin,
				branch = branch,
				local_rev = local_rev,
				remote_rev = remote_rev,
			})
		else
			print(" → up to date")
		end
	end

	return results
end

function M.apply(updates)
	if #updates == 0 then return end
	for _, update in ipairs(updates) do
		vim.system({ "git", "-C", update.plugin.path, "checkout", "--quiet", "origin/" .. update.branch }):wait()
	end
end

function M.run()
	print("󰚰 Checking updates...")
	local updates = M.check()

	if #updates > 0 then
		print(string.format("󰚰 Applying %d updates...", #updates))
		M.apply(updates)
	else
		print("󰄬 Plugins already up to date.")
	end

	-- Treesitter parsers update
	print("󰚰 Updating Treesitter parsers...")
	local parsers_script = vim.fn.stdpath("config") .. "/scripts/parsers"
	vim.system({ parsers_script }):wait()

	require("infra.deps.lockfile").generate()
	require("infra.health").run()
	require("infra.report.maintenance").run()

	print("󰄬 Done. Maintenance report updated.")
end

return M
