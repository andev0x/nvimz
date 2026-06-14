local M = {}

local ui = require("infra.view")

local function read_startuptime(report_path)
	local startup_file = io.open(report_path, "r")
	if not startup_file then
		return nil
	end

	local startup_ms
	for line in startup_file:lines() do
		if line:find("NVIM STARTED") then
			startup_ms = tonumber(line:match("^%s*(%d+%.%d+)"))
			break
		end
	end

	startup_file:close()
	return startup_ms
end

local function read_sourced_modules(report_path)
	local profiler_file = io.open(report_path, "r")
	local sourced_modules = {}

	if profiler_file then
		for line in profiler_file:lines() do
			local self_sourced, self_only, script = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s+(%d+%.%d+)%s*:%s*(.*)")
			if not self_sourced then
				local combined_time, script_name = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s*:%s*(.*)")
				if combined_time and script_name then
					self_sourced = combined_time
					self_only = combined_time
					script = script_name
				end
			end

			if self_sourced and self_only and script then
				table.insert(sourced_modules, {
					script = script,
					self_sourced = tonumber(self_sourced),
					self_only = tonumber(self_only),
				})
			end
		end
		profiler_file:close()
	end

	return sourced_modules
end

local function average(values)
	local total = 0
	for _, value in ipairs(values) do
		total = total + value
	end
	return #values > 0 and (total / #values) or 0
end

local function average_startup_stats(startup_stats)
	local total = 0
	for _, entry in ipairs(startup_stats) do
		total = total + entry.elapsed_ms
	end
	return #startup_stats > 0 and (total / #startup_stats) or 0
end

function M.run()
	local lines = {
		"# PackBenchmark: Startup & Module Profiling",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	print("󰚰 Measuring cold startup (cache cleared)...")
	local cache_dir = vim.fn.stdpath("cache") .. "/luac"
	vim.fn.delete(cache_dir, "rf")

	local cold_report = vim.fn.tempname()
	vim.system({ "nvim", "--startuptime", cold_report, "--headless", "-c", "qa" }):wait()
	local cold_startup_ms = read_startuptime(cold_report) or 0
	vim.fn.delete(cold_report)

	print("󰚰 Measuring warm startup (multiple trials)...")
	local warm_startup_times = {}
	for _ = 1, 4 do
		local warm_report = vim.fn.tempname()
		vim.system({ "nvim", "--startuptime", warm_report, "--headless", "-c", "qa" }):wait()
		local warm_startup_ms = read_startuptime(warm_report)
		if warm_startup_ms then
			table.insert(warm_startup_times, warm_startup_ms)
		end
		vim.fn.delete(warm_report)
	end

	local warm_startup_average = average(warm_startup_times)

	table.insert(lines, "## 1. Startup Timings")
	table.insert(lines, string.format("- **Cold Startup (first run):** %.2f ms", cold_startup_ms))
	table.insert(lines, string.format("- **Warm Startup (average of %d runs):** %.2f ms", #warm_startup_times, warm_startup_average))
	table.insert(lines, "")

	table.insert(lines, "## 2. Slowest Sourced Modules")
	table.insert(lines, "| Sourced Script / Module | Self+Sourced Time (ms) | Self Time (ms) |")
	table.insert(lines, "| --- | --- | --- |")

	local profiler_report = vim.fn.tempname()
	vim.system({ "nvim", "--startuptime", profiler_report, "--headless", "-c", "qa" }):wait()
	local sourced_modules = read_sourced_modules(profiler_report)
	vim.fn.delete(profiler_report)

	table.sort(sourced_modules, function(left, right)
		return left.self_sourced > right.self_sourced
	end)

	for i = 1, math.min(10, #sourced_modules) do
		local module_stats = sourced_modules[i]
		table.insert(lines, string.format("| `%s` | %.3f ms | %.3f ms |", vim.fn.fnamemodify(module_stats.script, ":t"), module_stats.self_sourced, module_stats.self_only))
	end
	table.insert(lines, "")

	table.insert(lines, "## 3. Historical Comparison")
	local cache = require("infra.cache")
	local startup_stats = cache.get("startup_stats") or {}
	if #startup_stats > 0 then
		local cached_startup_average = average_startup_stats(startup_stats)
		table.insert(lines, string.format("- Current Warm Average: **%.2f ms**", warm_startup_average))
		table.insert(lines, string.format("- Cached Historical Average (last %d runs): **%.2f ms**", #startup_stats, cached_startup_average))

		local startup_delta = warm_startup_average - cached_startup_average
		if startup_delta > 0 then
			table.insert(lines, string.format("- Status: ⚠️ Slower than historical average by **+%.2f ms**", startup_delta))
		else
			table.insert(lines, string.format("- Status: ✅ Faster than historical average by **%.2f ms**", -startup_delta))
		end
	else
		table.insert(lines, "- No historical startup stats found in cache.")
	end
	table.insert(lines, "")

	ui.show_in_buffer("PackBenchmark", lines)
end

return M
