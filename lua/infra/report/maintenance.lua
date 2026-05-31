local M = {}

function M.run()
	local lines = {
		"# nvimz Maintenance Report",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	table.insert(lines, "## 1. Lockfile Validation")
	local lock_path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local lf = io.open(lock_path, "r")
	if lf then
		local content = lf:read("*a")
		lf:close()
		local ok = pcall(vim.json.decode, content)
		if ok then
			table.insert(lines, "✅ Lockfile (`nvim-pack-lock.json`) is valid JSON.")
		else
			table.insert(lines, "❌ Lockfile (`nvim-pack-lock.json`) contains INVALID JSON.")
		end
	else
		table.insert(lines, "❌ Lockfile (`nvim-pack-lock.json`) is MISSING.")
	end
	table.insert(lines, "")

	table.insert(lines, "## 2. Environment Health")
	table.insert(lines, "```")
	local registry = require("infra.registry")
	local tools = registry.tools
	local check = require("infra.health.check")

	local function append_category(name, cat)
		table.insert(lines, string.rep("─", 60))
		table.insert(lines, " " .. name)
		table.insert(lines, string.rep("─", 60))
		for _, tool in ipairs(cat) do
			local info = check.inspect(tool)
			local status = info.installed and "OK" or "MISSING"
			local version = info.version or ""
			table.insert(lines, string.format(" %-22s %-10s %s", info.name, status, version))
		end
	end

	append_category("Core", tools.core)
	append_category("LSP", tools.lsp)
	append_category("Formatters", tools.formatters)
	append_category("Linters", tools.linters)
	table.insert(lines, "```")
	table.insert(lines, "")

	table.insert(lines, "## 3. Startup Benchmark")
	local tempfile = vim.fn.tempname()
	local res = vim.system({ "nvim", "--startuptime", tempfile, "--headless", "-c", "qa" }):wait()
	local startup_time = "N/A"
	if res.code == 0 then
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
	table.insert(lines, "Total startup time: **" .. (startup_time or "unknown") .. "ms** (Target: <20ms)")
	table.insert(lines, "")

	table.insert(lines, "## 4. Parser Validation")
	table.insert(lines, "```")
	table.insert(lines, "--------------------------------------------------")
	table.insert(lines, " nvimz: Treesitter Parser Manager")
	table.insert(lines, "--------------------------------------------------")
	local parsers = registry.parsers.required
	for _, lang in ipairs(parsers) do
		local ok = pcall(vim.treesitter.language.inspect, lang)
		if ok then
			table.insert(lines, "✅ " .. lang .. ": Already installed")
		else
			table.insert(lines, "❌ " .. lang .. ": MISSING or INVALID")
		end
	end
	table.insert(lines, "--------------------------------------------------")
	table.insert(lines, "```")
	table.insert(lines, "")

	local report_path = vim.fn.stdpath("config") .. "/MAINTENANCE_REPORT.md"
	local rf = io.open(report_path, "w")
	if rf then
		rf:write(table.concat(lines, "\n") .. "\n")
		rf:close()
		print("󰄬 Maintenance report generated: " .. report_path)
	else
		print("❌ Failed to write maintenance report!")
	end
end

return M
