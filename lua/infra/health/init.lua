local M = {}

local registry = require("infra.registry")
local tools = registry.tools
local parsers = registry.parsers

local check = require("infra.health.check")
local render = require("infra.health.render")
local ui = require("infra.view")

local function iterate(category)
	for _, tool in ipairs(category) do
		render.tool(check.inspect(tool))
	end
end

local function read_startup_time(report_path)
	local startup_file = io.open(report_path, "r")
	if not startup_file then
		return nil
	end

	local startup_ms
	for line in startup_file:lines() do
		if line:find("NVIM STARTED") then
			startup_ms = line:match("^%s*(%d+%.%d+)")
			break
		end
	end

	startup_file:close()
	return startup_ms
end

function M.check()
	local health = require("vim.health")

	health.start("infra: Core Dependencies")
	for _, tool in ipairs(tools.core) do
		local info = check.inspect(tool)
		if info.installed then
			local version_note = info.version and (" (" .. info.version .. ")") or ""
			health.ok(string.format("%s: installed%s", info.name, version_note))
		else
			health.error(
				string.format("%s: missing executable '%s'", info.name, info.bin),
				{ "Please install " .. info.name .. " and make sure it is in your PATH." }
			)
		end
	end

	health.start("infra: Optional Dependencies")
	local optional_categories = {
		{ name = "LSP", items = tools.lsp },
		{ name = "Formatters", items = tools.formatters },
		{ name = "Linters", items = tools.linters },
	}
	for _, category in ipairs(optional_categories) do
		for _, tool in ipairs(category.items) do
			local info = check.inspect(tool)
			if info.installed then
				local version_note = info.version and (" (" .. info.version .. ")") or ""
				health.ok(string.format("%s: installed%s", info.name, version_note))
			else
				health.warn(
					string.format("%s: missing executable '%s'", info.name, info.bin),
					{ "Optional: install " .. info.name .. " to enable " .. category.name .. " features." }
				)
			end
		end
	end
end

function M.run_doctor()
	render.section("Core")
	iterate(tools.core)

	render.section("LSP")
	iterate(tools.lsp)

	render.section("Formatters")
	iterate(tools.formatters)

	render.section("Linters")
	iterate(tools.linters)
end

function M.run()
	local lines = {
		"# PackValidate: Runtime & Configuration Health",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	table.insert(lines, "## 1. Startup Errors")
	local result = vim.system({ "nvim", "--headless", "-c", "qa" }, { text = true }):wait()
	if result.stderr and result.stderr ~= "" then
		table.insert(lines, "❌ **Startup generated stderr output:**")
		table.insert(lines, "```")
		table.insert(lines, result.stderr)
		table.insert(lines, "```")
	else
		table.insert(lines, "✅ No startup errors/stderr detected.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 2. Missing Plugins")
	local missing_plugins = {}
	for _, plugin in ipairs(vim.pack.get()) do
		if vim.fn.isdirectory(plugin.path) == 0 then
			table.insert(missing_plugins, plugin.spec.name or plugin.spec.src)
		end
	end
	if #missing_plugins > 0 then
		table.insert(lines, "❌ **The following plugins are registered but missing from disk:**")
		for _, missing_plugin in ipairs(missing_plugins) do
			table.insert(lines, "- " .. missing_plugin)
		end
	else
		table.insert(lines, "✅ All registered plugins are installed on disk.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 3. Treesitter Parsers")
	local invalid_parser_diagnostics = {}
	for _, lang in ipairs(parsers.required) do
		local ok, err = pcall(vim.treesitter.language.inspect, lang)
		if not ok then
			table.insert(invalid_parser_diagnostics, { lang = lang, err = err })
		end
	end
	if #invalid_parser_diagnostics > 0 then
		table.insert(lines, "❌ **The following Tree-sitter parsers are missing or invalid:**")
		for _, parser_diagnostic in ipairs(invalid_parser_diagnostics) do
			table.insert(lines, string.format("- **%s**: %s", parser_diagnostic.lang, tostring(parser_diagnostic.err)))
		end
	else
		table.insert(lines, "✅ All required Tree-sitter parsers are installed and inspectable.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 4. Git Repository Integrity")
	local corrupted_repositories = {}
	for _, plugin in ipairs(vim.pack.get()) do
		if vim.fn.isdirectory(plugin.path) == 1 then
			local git_status = vim.system({ "git", "-C", plugin.path, "status" }):wait()
			if git_status.code ~= 0 then
				table.insert(corrupted_repositories, plugin.spec.name or plugin.spec.src)
			end
		end
	end
	if #corrupted_repositories > 0 then
		table.insert(lines, "❌ **The following plugin repositories returned non-zero git status:**")
		for _, repository in ipairs(corrupted_repositories) do
			table.insert(lines, "- " .. repository)
		end
	else
		table.insert(lines, "✅ All plugin git repositories are healthy and accessible.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 5. Configuration Syntax Errors")
	local syntax_diagnostics = {}
	local config_dir = vim.fn.stdpath("config")
	local lua_files = vim.fn.globpath(config_dir, "**/*.lua", true, true)
	for _, lua_file in ipairs(lua_files) do
		local chunk, err = loadfile(lua_file)
		if not chunk then
			table.insert(syntax_diagnostics, { file = lua_file, err = err })
		end
	end
	if #syntax_diagnostics > 0 then
		table.insert(lines, "❌ **The following configuration files contain syntax errors:**")
		for _, diagnostic in ipairs(syntax_diagnostics) do
			table.insert(lines, string.format("- **%s**:", vim.fn.fnamemodify(diagnostic.file, ":.")))
			table.insert(lines, "  ```\n  " .. diagnostic.err .. "\n  ```")
		end
	else
		table.insert(lines, "✅ All configuration Lua files compiled successfully.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 6. Startup Performance Benchmark")
	local startup_report = vim.fn.tempname()
	local startup_result = vim.system({ "nvim", "--startuptime", startup_report, "--headless", "-c", "qa" }):wait()
	local startup_ms = nil
	if startup_result.code == 0 then
		startup_ms = read_startup_time(startup_report)
	end
	vim.fn.delete(startup_report)
	if startup_ms then
		table.insert(lines, string.format("Benchmark startup time: **%s ms** (Target: < 20 ms)", startup_ms))
	else
		table.insert(lines, "❌ Benchmark startup failed or could not parse startup time.")
	end

	ui.show_in_buffer("PackValidate", lines)
end

return M
