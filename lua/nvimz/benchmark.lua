local M = {}

local SAMPLES = 3
local ui = require("nvimz.ui")

local function parse_report(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local total
	local modules = {}

	for line in file:lines() do
		if line:find("NVIM STARTED", 1, true) then
			total = tonumber(line:match("^%s*(%d+%.%d+)"))
		else
			local self_sourced, self_only, script = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s+(%d+%.%d+)%s*:%s*(.*)")
			if not self_sourced then
				local combined, name = line:match("^%s*%d+%.%d+%s+(%d+%.%d+)%s*:%s*(.*)")
				self_sourced, self_only, script = combined, combined, name
			end

			if self_sourced and script and script ~= "" then
				modules[#modules + 1] = {
					script = script,
					total = tonumber(self_sourced),
					self = tonumber(self_only),
				}
			end
		end
	end

	file:close()
	return total, modules
end

local function measure()
	local report = vim.fn.tempname()
	local ok, result = pcall(function()
		return vim.system({ "nvim", "--startuptime", report, "--headless", "-c", "qa" }):wait()
	end)

	local total, modules
	if ok and result.code == 0 then
		total, modules = parse_report(report)
	end
	vim.fn.delete(report)
	return total, modules
end

function M.run()
	vim.notify(("Measuring startup (%d runs)..."):format(SAMPLES), vim.log.levels.INFO)

	local samples = {}
	local modules = {}

	for _ = 1, SAMPLES do
		local total, measured = measure()
		if total then
			samples[#samples + 1] = total
			modules = measured or modules
		end
	end

	if #samples == 0 then
		vim.notify("Startup measurement failed: could not run or parse `nvim --startuptime`.", vim.log.levels.ERROR)
		return
	end

	table.sort(samples)
	local minimum = samples[1]
	local maximum = samples[#samples]
	local median = samples[math.ceil(#samples / 2)]

	table.sort(modules, function(a, b)
		return a.total > b.total
	end)

	local lines = {
		"# NvimzBenchmark",
		"",
		"Generated " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"## Startup",
		"",
		("- Samples: %s ms"):format(table.concat(samples, ", ")),
		("- Median: **%.2f ms**"):format(median),
		("- Min / max: %.2f / %.2f ms"):format(minimum, maximum),
		"- Metric: process start → `NVIM STARTED` (includes native runtime plugins)",
		"- Project target: < 10.00 ms cold core init.lua → VimEnter (different boundary)",
		"",
		"## Slowest sourced modules (last run)",
		"",
		"| Module | Self+sourced (ms) | Self (ms) |",
		"| --- | --- | --- |",
	}

	for i = 1, math.min(10, #modules) do
		local module = modules[i]
		lines[#lines + 1] = ("| `%s` | %.3f | %.3f |"):format(
			vim.fn.fnamemodify(module.script, ":t"),
			module.total,
			module.self
		)
	end

	ui.show("NvimzBenchmark", lines)
end

return M
