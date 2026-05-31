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

function M.check()
	local missing = {}

	for _, tool in ipairs(tools.core) do
		if tool.required and not check.executable(tool.bin) then
			table.insert(missing, tool.bin)
		end
	end

	if #missing == 0 then
		return
	end

	error(table.concat({
		"Missing critical dependencies:",
		"  - " .. table.concat(missing, "\n  - "),
	}, "\n"))
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

function M.register_command()
	vim.api.nvim_create_user_command("ToolDoctor", function()
		M.run_doctor()
	end, {
		desc = "Show environment tooling health",
	})
end

function M.run()
	local lines = {
		"# PackValidate: Runtime & Configuration Health",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	-- 1. Check Startup Errors
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

	-- 2. Check Missing Plugins
	table.insert(lines, "## 2. Missing Plugins")
	local missing = {}
	for _, p in ipairs(vim.pack.get()) do
		if vim.fn.isdirectory(p.path) == 0 then
			table.insert(missing, p.spec.name or p.spec.src)
		end
	end
	if #missing > 0 then
		table.insert(lines, "❌ **The following plugins are registered but missing from disk:**")
		for _, m in ipairs(missing) do table.insert(lines, "- " .. m) end
	else
		table.insert(lines, "✅ All registered plugins are installed on disk.")
	end
	table.insert(lines, "")

	-- 3. Check Invalid Treesitter Parsers
	table.insert(lines, "## 3. Treesitter Parsers")
	local invalid_parsers = {}
	for _, lang in ipairs(parsers.required) do
		local ok, err = pcall(vim.treesitter.language.inspect, lang)
		if not ok then table.insert(invalid_parsers, { lang = lang, err = err }) end
	end
	if #invalid_parsers > 0 then
		table.insert(lines, "❌ **The following Tree-sitter parsers are missing or invalid:**")
		for _, ip in ipairs(invalid_parsers) do
			table.insert(lines, string.format("- **%s**: %s", ip.lang, tostring(ip.err)))
		end
	else
		table.insert(lines, "✅ All required Tree-sitter parsers are installed and inspectable.")
	end
	table.insert(lines, "")

	-- 4. Check Corrupted Git Repos
	table.insert(lines, "## 4. Git Repository Integrity")
	local corrupted = {}
	for _, p in ipairs(vim.pack.get()) do
		if vim.fn.isdirectory(p.path) == 1 then
			local res = vim.system({ "git", "-C", p.path, "status" }):wait()
			if res.code ~= 0 then table.insert(corrupted, p.spec.name or p.spec.src) end
		end
	end
	if #corrupted > 0 then
		table.insert(lines, "❌ **The following plugin repositories returned non-zero git status:**")
		for _, c in ipairs(corrupted) do table.insert(lines, "- " .. c) end
	else
		table.insert(lines, "✅ All plugin git repositories are healthy and accessible.")
	end
	table.insert(lines, "")

	-- 5. Check Configuration Syntax Errors
	table.insert(lines, "## 5. Configuration Syntax Errors")
	local syntax_errors = {}
	local config_path = vim.fn.stdpath("config")
	local files = vim.fn.globpath(config_path, "**/*.lua", true, true)
	for _, filepath in ipairs(files) do
		local f, err = loadfile(filepath)
		if not f then table.insert(syntax_errors, { file = filepath, err = err }) end
	end
	if #syntax_errors > 0 then
		table.insert(lines, "❌ **The following configuration files contain syntax errors:**")
		for _, se in ipairs(syntax_errors) do
			table.insert(lines, string.format("- **%s**:", vim.fn.fnamemodify(se.file, ":.")))
			table.insert(lines, "  ```\n  " .. se.err .. "\n  ```")
		end
	else
		table.insert(lines, "✅ All configuration Lua files compiled successfully.")
	end
	table.insert(lines, "")

	-- 6. Benchmark Startup Performance
	table.insert(lines, "## 6. Startup Performance Benchmark")
	local tempfile = vim.fn.tempname()
	local res_bench = vim.system({ "nvim", "--startuptime", tempfile, "--headless", "-c", "qa" }):wait()
	local startup_time = nil
	if res_bench.code == 0 then
		local f = io.open(tempfile, "r")
		if f then
			for line in f:lines() do
				if line:find("NVIM STARTED") then
					startup_time = line:match("^%s*(%d+%.%d+)")
					break
				end
			end
			f:close()
		end
	end
	vim.fn.delete(tempfile)
	if startup_time then
		table.insert(lines, string.format("Benchmark startup time: **%s ms** (Target: < 20 ms)", startup_time))
	else
		table.insert(lines, "❌ Benchmark startup failed or could not parse startup time.")
	end

	ui.show_in_buffer("PackValidate", lines)
end

return M
