local M = {}

local ui = require("infra.view")

local function render_version()
	return vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
end

local function render_tool_category(category_name, tool_list, check, lines)
	table.insert(lines, "### " .. category_name)
	for _, tool in ipairs(tool_list) do
		local info = check.inspect(tool)
		local status = info.installed and "✅ OK" or "❌ MISSING"
		local version_note = info.version and (" - `" .. info.version .. "`") or ""
		table.insert(lines, string.format("- **%s**: %s%s", info.name, status, version_note))
	end
end

function M.run()
	local lines = {
		"# PackDoctor: System Diagnostics & Health",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	table.insert(lines, "## 1. Neovim Version")
	table.insert(lines, "- Version: `" .. render_version() .. "`")
	table.insert(lines, "")

	table.insert(lines, "## 2. Runtime Health")
	local registry = require("infra.registry")
	local tools = registry.tools
	local check = require("infra.health.check")

	render_tool_category("Core Dependencies", tools.core, check, lines)
	render_tool_category("Language Servers", tools.lsp, check, lines)
	render_tool_category("Formatters", tools.formatters, check, lines)
	render_tool_category("Linters", tools.linters, check, lines)
	table.insert(lines, "")

	table.insert(lines, "## 3. Treesitter Parser Health")
	local parsers = registry.parsers.required
	for _, lang in ipairs(parsers) do
		local ok, _ = pcall(vim.treesitter.language.inspect, lang)
		local status = ok and "✅ Installed" or "❌ Missing/Invalid"
		table.insert(lines, string.format("- **%s**: %s", lang, status))
	end
	table.insert(lines, "")

	table.insert(lines, "## 4. Plugin Health")
	local installed_plugins = vim.pack.get()
	for _, plugin in ipairs(installed_plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local plugin_exists = vim.fn.isdirectory(plugin.path) == 1
		local status = plugin_exists and "✅ Healthy" or "❌ Missing"
		local revision = plugin.rev and plugin.rev:sub(1, 7) or "N/A"
		table.insert(
			lines,
			string.format("- **%s**: %s (Revision: `%s`, Active: `%s`)", name, status, revision, tostring(plugin.active))
		)
	end
	table.insert(lines, "")

	table.insert(lines, "## 5. Machine & Environment State")
	local os_info = vim.uv.os_uname()
	table.insert(lines, string.format("- OS: `%s %s` (`%s`)", os_info.sysname, os_info.release, os_info.machine))
	table.insert(lines, string.format("- Config Dir: `%s`", vim.fn.stdpath("config")))
	table.insert(lines, string.format("- Data Dir:   `%s`", vim.fn.stdpath("data")))
	table.insert(lines, string.format("- State Dir:  `%s`", vim.fn.stdpath("state")))
	table.insert(lines, string.format("- Cache Dir:  `%s`", vim.fn.stdpath("cache")))
	table.insert(lines, "")

	ui.show_in_buffer("PackDoctor", lines)
end

return M
