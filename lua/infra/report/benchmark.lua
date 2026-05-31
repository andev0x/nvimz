local M = {}

local ui = require("infra.ui")

function M.run()
	local lines = {
		"# PackBenchmark: Startup & Module Profiling",
		"Date: " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
	}

	-- 1. Cold Startup Measurement
	print("󰚰 Measuring cold startup (cache cleared)...")
	local cache_dir = vim.fn.stdpath("cache") .. "/luac"
	vim.fn.delete(cache_dir, "rf")

	local tempfile_cold = vim.fn.tempname()
	vim.system({ "nvim", "--startuptime", tempfile_cold, "--headless", "-c", "qa" }):wait()
	local cold_time = 0
	local f_cold = io.open(tempfile_cold, "r")
	if f_cold then
		for line in f_cold:lines() do
			if line:find("NVIM STARTED") then
				cold_time = tonumber(line:match("^%s*(%d+%.%d+)"))
				break
			end
		end
		f_cold:close()
	end
	vim.fn.delete(tempfile_cold)

	-- 2. Warm Startup Measurement
	print("󰚰 Measuring warm startup (multiple trials)...")
	local warm_times = {}
	for i = 1, 4 do
		local tempfile_warm = vim.fn.tempname()
		vim.system({ "nvim", "--startuptime", tempfile_warm, "--headless", "-c", "qa" }):wait()
		local f_warm = io.open(tempfile_warm, "r")
		if f_warm then
			for line in f_warm:lines() do
				if line:find("NVIM STARTED") then
					local t = tonumber(line:match("^%s*(%d+%.%d+)"))
					if t then table.insert(warm_times, t) end
					break
				end
			end
			f_warm:close()
		end
		vim.fn.delete(tempfile_warm)
	end

	local warm_sum = 0
	for _, t in ipairs(warm_times) do warm_sum = warm_sum + t end
	local warm_avg = #warm_times > 0 and (warm_sum / #warm_times) or 0

	table.insert(lines, "## 1. Startup Timings")
	table.insert(lines, string.format("- **Cold Startup (first run):** %.2f ms", cold_time))
	table.insert(lines, string.format("- **Warm Startup (average of %d runs):** %.2f ms", #warm_times, warm_avg))
	table.insert(lines, "")

	-- 3. Sourced Module Profiling
	table.insert(lines, "## 2. Slowest Sourced Modules")
	table.insert(lines, "| Sourced Script / Module | Self+Sourced Time (ms) | Self Time (ms) |")
	table.insert(lines, "| --- | --- | --- |")

	local tempfile_prof = vim.fn.tempname()
	vim.system({ "nvim", "--startuptime", tempfile_prof, "--headless", "-c", "qa" }):wait()
	local prof_modules = {}
	local f_prof = io.open(tempfile_prof, "r")
	if f_prof then
		for line in f_prof:lines() do
			local self_sourced, self_only, script = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s+(%d+%.%d+)%s*:%s*(.*)")
			if not self_sourced then
				local val1, val2 = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s*:%s*(.*)")
				if val1 and val2 then self_sourced = val1; self_only = val1; script = val2 end
			end
			if self_sourced and self_only and script then
				table.insert(prof_modules, {
					script = script,
					self_sourced = tonumber(self_sourced),
					self_only = tonumber(self_only),
				})
			end
		end
		f_prof:close()
	end
	vim.fn.delete(tempfile_prof)

	table.sort(prof_modules, function(a, b) return a.self_sourced > b.self_sourced end)

	for i = 1, math.min(10, #prof_modules) do
		local mod = prof_modules[i]
		table.insert(lines, string.format("| `%s` | %.3f ms | %.3f ms |", vim.fn.fnamemodify(mod.script, ":t"), mod.self_sourced, mod.self_only))
	end
	table.insert(lines, "")

	-- 4. Historical Comparison
	table.insert(lines, "## 3. Historical Comparison")
	local cache = require("infra.cache")
	local stats = cache.get("startup_stats") or {}
	if #stats > 0 then
		local history_sum = 0
		for _, entry in ipairs(stats) do history_sum = history_sum + entry.elapsed_ms end
		local history_avg = history_sum / #stats
		table.insert(lines, string.format("- Current Warm Average: **%.2f ms**", warm_avg))
		table.insert(lines, string.format("- Cached Historical Average (last %d runs): **%.2f ms**", #stats, history_avg))
		local diff = warm_avg - history_avg
		if diff > 0 then
			table.insert(lines, string.format("- Status: ⚠️ Slower than historical average by **+%.2f ms**", diff))
		else
			table.insert(lines, string.format("- Status: ✅ Faster than historical average by **%.2f ms**", -diff))
		end
	else
		table.insert(lines, "- No historical startup stats found in cache.")
	end
	table.insert(lines, "")

	ui.show_in_buffer("PackBenchmark", lines)
end

return M
