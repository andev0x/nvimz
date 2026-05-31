local M = {}

local git = require("infra.deps.git")
local ui = require("infra.ui")

function M.run()
	local plugins = vim.pack.get()
	local lines = {
		"# PackSync: Plugin Update Status",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	print("󰚰 Checking remote plugin states...")
	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		print("  Fetching " .. name .. "...")
		vim.system({ "git", "-C", plugin.path, "fetch", "origin", "--quiet" }):wait()

		local branch = git.get_default_branch(plugin.path)
		local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local remote_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "origin/" .. branch }, { text = true })
			:wait().stdout
			:gsub("\n", "")

		table.insert(lines, "## " .. name)
		table.insert(lines, "Branch: `" .. branch .. "`")
		if local_rev ~= remote_rev then
			table.insert(lines, "Status: ⚠️ **Pending Update**")
			table.insert(lines, "Current revision: `" .. local_rev .. "`")
			table.insert(lines, "Remote revision:  `" .. remote_rev .. "`")
		else
			table.insert(lines, "Status: ✅ **Up to date**")
			table.insert(lines, "Revision: `" .. local_rev .. "`")
		end
		table.insert(lines, "")
	end

	ui.show_in_buffer("PackSync", lines)
end

return M
