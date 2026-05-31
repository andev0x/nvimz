local M = {}

local ui = require("infra.view")

function M.run()
	local lines = {
		"# PackDoctor: System Diagnostics & Health",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	-- 1. Neovim Version
	table.insert(lines, "## 1. Neovim Version")
	local nvim_version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
	table.insert(lines, "- Version: `" .. nvim_version .. "`")
	table.insert(lines, "")

	-- 2. Runtime Health
	table.insert(lines, "## 2. Runtime Health")
	local registry = require("infra.registry")
	local tools = registry.tools
	local check = require("infra.health.check")

	local function check_and_add_tools(cat_name, cat)
		table.insert(lines, "### " .. cat_name)
		for _, tool in ipairs(cat) do
			local info = check.inspect(tool)
			local status = info.installed and "✅ OK" or "❌ MISSING"
			local version_str = info.version and (" - `" .. info.version .. "`") or ""
			table.insert(lines, string.format("- **%s**: %s%s", info.name, status, version_str))
		end
	end
	check_and_add_tools("Core Dependencies", tools.core)
	check_and_add_tools("Language Servers", tools.lsp)
	check_and_add_tools("Formatters", tools.formatters)
	check_and_add_tools("Linters", tools.linters)
	table.insert(lines, "")

	-- 3. Parser Health
	table.insert(lines, "## 3. Treesitter Parser Health")
	local parsers = registry.parsers.required
	for _, lang in ipairs(parsers) do
		local ok, _ = pcall(vim.treesitter.language.inspect, lang)
		local status = ok and "✅ Installed" or "❌ Missing/Invalid"
		table.insert(lines, string.format("- **%s**: %s", lang, status))
	end
	table.insert(lines, "")

	-- 4. Plugin Health
	table.insert(lines, "## 4. Plugin Health")
	local plugins = vim.pack.get()
	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local exists = vim.fn.isdirectory(plugin.path) == 1
		local status = exists and "✅ Healthy" or "❌ Missing"
		local rev = plugin.rev and plugin.rev:sub(1, 7) or "N/A"
		table.insert(
			lines,
			string.format("- **%s**: %s (Revision: `%s`, Active: `%s`)", name, status, rev, tostring(plugin.active))
		)
	end
	table.insert(lines, "")

	-- 5. Machine State
	table.insert(lines, "## 5. Machine & Environment State")
	local uname = vim.uv.os_uname()
	table.insert(lines, string.format("- OS: `%s %s` (`%s`)", uname.sysname, uname.release, uname.machine))
	table.insert(lines, string.format("- Config Dir: `%s`", vim.fn.stdpath("config")))
	table.insert(lines, string.format("- Data Dir:   `%s`", vim.fn.stdpath("data")))
	table.insert(lines, string.format("- State Dir:  `%s`", vim.fn.stdpath("state")))
	table.insert(lines, string.format("- Cache Dir:  `%s`", vim.fn.stdpath("cache")))
	table.insert(lines, "")

	ui.show_in_buffer("PackDoctor", lines)
end

return M
