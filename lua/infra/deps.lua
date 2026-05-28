local M = {}

-- Normalize plugin specifications for vim.pack
local function normalize(spec)
	local source = type(spec) == "string" and spec or spec.source

	-- Expand GitHub shorthand into full URL
	if not (source:find("http", 1, true) or source:find("git@", 1, true)) then
		source = "https://github.com/" .. source
	end

	local final = type(spec) == "table" and vim.tbl_extend("force", {}, spec) or {}

	final.src = source
	final.source = nil

	return final
end

-- Batch plugin registration
local function add(specs)
	vim.pack.add(vim.tbl_map(normalize, specs))
end

-- Create helper commands only once
local function create_commands()
	if vim.g.pack_commands_created then
		return
	end

	vim.g.pack_commands_created = true

	vim.api.nvim_create_user_command("PackSync", function()
		M.pack_sync()
	end, { desc = "Fetch and check plugin updates" })

	vim.api.nvim_create_user_command("PackUpdate", function()
		M.pack_update()
	end, { desc = "Apply plugin updates, relock, validate, and report" })

	vim.api.nvim_create_user_command("PackValidate", function()
		M.pack_validate()
	end, { desc = "Validate runtime integrity and config health" })

	vim.api.nvim_create_user_command("PackDoctor", function()
		M.pack_doctor()
	end, { desc = "Run health diagnostics" })

	vim.api.nvim_create_user_command("PackBenchmark", function()
		M.pack_benchmark()
	end, { desc = "Measure startup and module performance" })

	vim.api.nvim_create_user_command("PackRollback", function()
		M.pack_rollback()
	end, { desc = "Restore plugins from lockfile state" })

	vim.api.nvim_create_user_command("PackStatus", function()
		M.pack_status()
	end, { desc = "Quick overview of package status" })

	vim.api.nvim_create_user_command("PackClean", function()
		M.pack_clean()
	end, { desc = "Remove inactive plugins, stale cache, and old snapshots" })

	vim.api.nvim_create_user_command("PackSnapshot", function()
		M.pack_snapshot()
	end, { desc = "Generate system and state snapshot" })

	vim.api.nvim_create_user_command("PackReport", function()
		M.pack_report()
	end, { desc = "Regenerate maintenance report" })

	vim.api.nvim_create_user_command("ParsersUpdate", function()
		local script = vim.fn.stdpath("config") .. "/scripts/parsers"
		vim.fn.jobstart({ script }, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				if data then
					for _, line in ipairs(data) do
						if line ~= "" then
							print(line)
						end
					end
				end
			end,
			on_exit = function(_, code)
				if code == 0 then
					vim.notify("Treesitter parsers updated successfully!", vim.log.levels.INFO)
				else
					vim.notify("Treesitter parser update failed!", vim.log.levels.ERROR)
				end
			end,
		})
	end, {
		desc = "Update Treesitter parsers",
	})
end

function M.setup()
	-- Register user commands immediately (cheap)
	create_commands()

	local cache = require("infra.cache")
	local state = cache.get("plugin_state") or { phases = {} }

	-- Phase 1: UI (Now deferred until the first idle period)
	vim.schedule(function()
		add({
			{ source = "folke/tokyonight.nvim", name = "tokyonight" },
			{ source = "echasnovski/mini.nvim" },
		})

		pcall(function()
			require("plugins.theme").setup()
			require("plugins.mini").setup()
		end)

		state.phases[1] = true
		cache.set("plugin_state", state)
	end)

	-- Phase 2: Core Editing (Triggered by file access)

	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		group = vim.api.nvim_create_augroup("PackPhase2", { clear = true }),
		once = true,
		callback = function()
			add({
				{ source = "neovim/nvim-lspconfig" },
				{ source = "stevearc/conform.nvim" },
				{ source = "mfussenegger/nvim-dap" },
				{ source = "nvim-neotest/nvim-nio" },
				{ source = "rcarriga/nvim-dap-ui" },
				{ source = "leoluz/nvim-dap-go" },
			})

			pcall(function()
				-- require("infra.lsp").setup() -- Handled lazily by FileType autocmd
				require("plugins.format").setup()
				require("plugins.dap").setup()
			end)

			state.phases[2] = true
			cache.set("plugin_state", state)
		end,
	})

	-- Phase 3: Extra Features & Tools (Triggered by typing or deferred)
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = vim.api.nvim_create_augroup("PackPhase3", { clear = true }),
		once = true,
		callback = function()
			add({
				{ source = "Robitx/gp.nvim" },
				{ source = "zbirenbaum/copilot.lua" },
			})

			pcall(function()
				require("plugins.ai").setup()
			end)

			state.phases[3] = true
			cache.set("plugin_state", state)
		end,
	})
end

local function get_default_branch(path)
	local obj = vim.system({ "git", "-C", path, "remote", "show", "origin" }, { text = true }):wait()
	if obj.code ~= 0 then
		return "main"
	end
	for line in vim.gsplit(obj.stdout, "\n") do
		local branch = line:match("HEAD branch: (.+)")
		if branch then
			return branch
		end
	end
	return "main"
end

function M.check_updates()
	local plugins = vim.pack.get()
	local results = {}

	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		io.write(string.format(" 󰆓 %-20s", name))
		io.flush()

		vim.system({ "git", "-C", plugin.path, "fetch", "origin", "--quiet" }):wait()

		local branch = get_default_branch(plugin.path)
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

function M.apply_updates(updates)
	if #updates == 0 then
		return
	end

	for _, update in ipairs(updates) do
		vim.system({ "git", "-C", update.plugin.path, "reset", "--hard", "origin/" .. update.branch }):wait()
	end
end

function M.generate_lockfile()
	local plugins = vim.pack.get()
	local lock = { plugins = {} }

	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		lock.plugins[name] = {
			rev = rev,
			src = plugin.spec.src,
		}
	end

	local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(path, "w")
	if f then
		f:write(vim.json.encode(lock))
		f:close()
	end
end

function M.validate()
	local script = vim.fn.stdpath("config") .. "/scripts/validate"
	vim.system({ script }):wait()
end

-- Helper to show text in a buffer
local function show_in_buffer(title, lines)
	if #vim.api.nvim_list_uis() == 0 then
		print(table.concat(lines, "\n"))
		return
	end

	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })

	vim.cmd("vsplit")
	vim.api.nvim_set_current_buf(bufnr)
	vim.wo.wrap = false
	vim.wo.number = true
	vim.wo.relativenumber = false
	pcall(vim.api.nvim_buf_set_name, bufnr, title)
end

function M.pack_sync()
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

		local branch = get_default_branch(plugin.path)
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

	show_in_buffer("PackSync", lines)
end

function M.pack_validate()
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
		for _, m in ipairs(missing) do
			table.insert(lines, "- " .. m)
		end
	else
		table.insert(lines, "✅ All registered plugins are installed on disk.")
	end
	table.insert(lines, "")

	-- 3. Check Invalid Treesitter Parsers
	table.insert(lines, "## 3. Treesitter Parsers")
	local parsers =
		{ "c", "cpp", "go", "rust", "python", "typescript", "tsx", "lua", "vim", "vimdoc", "gitcommit", "git_rebase", "diff", "markdown" }
	local invalid_parsers = {}
	for _, lang in ipairs(parsers) do
		local ok, err = pcall(vim.treesitter.language.inspect, lang)
		if not ok then
			table.insert(invalid_parsers, { lang = lang, err = err })
		end
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

	-- 4. Check Detached / Corrupted Git Repos
	table.insert(lines, "## 4. Git Repository Integrity")
	local corrupted = {}
	for _, p in ipairs(vim.pack.get()) do
		if vim.fn.isdirectory(p.path) == 1 then
			local res = vim.system({ "git", "-C", p.path, "status" }):wait()
			if res.code ~= 0 then
				table.insert(corrupted, p.spec.name or p.spec.src)
			end
		end
	end
	if #corrupted > 0 then
		table.insert(lines, "❌ **The following plugin repositories returned non-zero git status:**")
		for _, c in ipairs(corrupted) do
			table.insert(lines, "- " .. c)
		end
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
		if not f then
			table.insert(syntax_errors, { file = filepath, err = err })
		end
	end
	if #syntax_errors > 0 then
		table.insert(lines, "❌ **The following configuration files contain syntax errors:**")
		for _, se in ipairs(syntax_errors) do
			table.insert(lines, string.format("- **%s**:", vim.fn.fnamemodify(se.file, ":.")))
			table.insert(lines, "  ```")
			table.insert(lines, "  " .. se.err)
			table.insert(lines, "  ```")
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

	show_in_buffer("PackValidate", lines)
end

function M.pack_doctor()
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
	local tools = require("infra.tools")
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
	local parsers =
		{ "c", "cpp", "go", "rust", "python", "typescript", "tsx", "lua", "vim", "vimdoc", "gitcommit", "git_rebase", "diff", "markdown" }
	for _, lang in ipairs(parsers) do
		local ok, err = pcall(vim.treesitter.language.inspect, lang)
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

	show_in_buffer("PackDoctor", lines)
end

function M.pack_benchmark()
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
					if t then
						table.insert(warm_times, t)
					end
					break
				end
			end
			f_warm:close()
		end
		vim.fn.delete(tempfile_warm)
	end

	local warm_sum = 0
	for _, t in ipairs(warm_times) do
		warm_sum = warm_sum + t
	end
	local warm_avg = #warm_times > 0 and (warm_sum / #warm_times) or 0

	table.insert(lines, "## 1. Startup Timings")
	table.insert(lines, string.format("- **Cold Startup (first run):** %.2f ms", cold_time))
	table.insert(lines, string.format("- **Warm Startup (average of %d runs):** %.2f ms", #warm_times, warm_avg))
	table.insert(lines, "")

	-- 3. Sourced Module Profiling (from warm startuptime log)
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
				if val1 and val2 then
					self_sourced = val1
					self_only = val1
					script = val2
				end
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

	table.sort(prof_modules, function(a, b)
		return a.self_sourced > b.self_sourced
	end)

	local count = 0
	for _, mod in ipairs(prof_modules) do
		if count >= 10 then
			break
		end
		table.insert(
			lines,
			string.format(
				"| `%s` | %.3f ms | %.3f ms |",
				vim.fn.fnamemodify(mod.script, ":t"),
				mod.self_sourced,
				mod.self_only
			)
		)
		count = count + 1
	end
	table.insert(lines, "")

	-- 4. Compare with Cached History
	table.insert(lines, "## 3. Historical Comparison")
	local cache = require("infra.cache")
	local stats = cache.get("startup_stats") or {}
	if #stats > 0 then
		local history_sum = 0
		for _, entry in ipairs(stats) do
			history_sum = history_sum + entry.elapsed_ms
		end
		local history_avg = history_sum / #stats
		table.insert(lines, string.format("- Current Warm Average: **%.2f ms**", warm_avg))
		table.insert(
			lines,
			string.format("- Cached Historical Average (last %d runs): **%.2f ms**", #stats, history_avg)
		)
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

	show_in_buffer("PackBenchmark", lines)
end

function M.pack_rollback()
	local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(path, "r")
	if not f then
		print("❌ Lockfile missing!")
		return
	end
	local content = f:read("*a")
	f:close()

	local lock = vim.json.decode(content)
	local plugins = vim.pack.get()

	print("󰚰 Rolling back plugins to lockfile state...")
	for _, plugin in ipairs(plugins) do
		local name = plugin.spec.name or plugin.spec.src
		local entry = lock.plugins[name]
		if entry and entry.rev then
			print("  Resetting " .. name .. " to " .. entry.rev:sub(1, 7) .. "...")
			vim.system({ "git", "-C", plugin.path, "reset", "--hard", entry.rev }):wait()
		else
			print("  ⚠️ No lockfile entry for " .. name)
		end
	end
	print("󰄬 Rollback complete.")
end

function M.pack_status()
	local plugins = vim.pack.get()
	local plugin_count = #plugins

	local outdated = 0
	for _, plugin in ipairs(plugins) do
		local branch = get_default_branch(plugin.path)
		local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local remote_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "origin/" .. branch }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		if local_rev ~= remote_rev then
			outdated = outdated + 1
		end
	end

	local startup_time = 0
	if _G.nvimz_start_time then
		startup_time = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6
	end

	local health_ok = true
	local tools = require("infra.tools")
	local check = require("infra.health.check")
	for _, tool in ipairs(tools.core) do
		if tool.required and not check.executable(tool.bin) then
			health_ok = false
		end
	end

	local lock_ok = true
	local lock_path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local f = io.open(lock_path, "r")
	if f then
		local content = f:read("*a")
		f:close()
		local ok, lock = pcall(vim.json.decode, content)
		if ok and lock.plugins then
			for _, plugin in ipairs(plugins) do
				local name = plugin.spec.name or plugin.spec.src
				local entry = lock.plugins[name]
				local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
					:wait().stdout
					:gsub("\n", "")
				if not entry or entry.rev ~= local_rev then
					lock_ok = false
					break
				end
			end
		else
			lock_ok = false
		end
	else
		lock_ok = false
	end

	print(
		string.format(
			"nvimz Status: plugins=%d, outdated=%d, startup=%.2fms, health=%s, lockfile=%s",
			plugin_count,
			outdated,
			startup_time,
			health_ok and "OK" or "WARNING",
			lock_ok and "In Sync" or "Out of Sync"
		)
	)
end

function M.pack_clean()
	local inactive = vim.iter(vim.pack.get())
		:filter(function(plugin)
			return not plugin.active
		end)
		:map(function(plugin)
			return plugin.spec.name or plugin.spec.src
		end)
		:totable()

	if #inactive > 0 then
		print("Removing inactive plugins:\n" .. table.concat(inactive, "\n"))
		vim.pack.del(inactive)
	else
		print("No inactive plugins found.")
	end

	local cache_path = vim.fn.stdpath("state") .. "/nvimz_cache.json"
	if vim.fn.filereadable(cache_path) == 1 then
		vim.fn.delete(cache_path)
		print("Cleared state cache file.")
	end

	local parser_dir = vim.fn.expand("~/.local/share/nvim/site/parser")
	local valid_parsers = {
		c = true,
		cpp = true,
		go = true,
		rust = true,
		python = true,
		typescript = true,
		tsx = true,
		lua = true,
		vim = true,
		vimdoc = true,
		gitcommit = true,
		markdown = true,
	}
	if vim.fn.isdirectory(parser_dir) == 1 then
		local files = vim.fn.globpath(parser_dir, "*.so", true, true)
		for _, file in ipairs(files) do
			local lang = vim.fn.fnamemodify(file, ":t:r")
			local ok, err = pcall(vim.treesitter.language.inspect, lang)
			if not valid_parsers[lang] or not ok then
				vim.fn.delete(file)
				print("Removed invalid/orphaned parser binary: " .. file)
			end
		end
	end

	local snapshot_dir = vim.fn.stdpath("config") .. "/snapshots"
	if vim.fn.isdirectory(snapshot_dir) == 1 then
		local snapshots = vim.fn.globpath(snapshot_dir, "snapshot_*.json", true, true)
		table.sort(snapshots)
		if #snapshots > 5 then
			for i = 1, #snapshots - 5 do
				vim.fn.delete(snapshots[i])
				print("Removed old snapshot: " .. snapshots[i])
			end
		end
	end
	print("󰄬 PackClean complete.")
end

function M.pack_snapshot()
	local snapshot_dir = vim.fn.stdpath("config") .. "/snapshots"
	if vim.fn.isdirectory(snapshot_dir) == 0 then
		vim.fn.mkdir(snapshot_dir, "p")
	end

	local cache = require("infra.cache")
	local startup_stats = cache.get("startup_stats") or {}

	local plugins = {}
	for _, plugin in ipairs(vim.pack.get()) do
		local name = plugin.spec.name or plugin.spec.src
		local rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true })
			:wait().stdout
			:gsub("\n", "")
		local branch = get_default_branch(plugin.path)
		plugins[name] = {
			rev = rev,
			branch = branch,
			src = plugin.spec.src,
		}
	end

	local uname = vim.uv.os_uname()
	local machine = {
		os = uname.sysname,
		release = uname.release,
		version = uname.version,
		arch = uname.machine,
		nvim_version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
	}

	local snapshot = {
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		startup = startup_stats,
		plugins = plugins,
		machine = machine,
	}

	local filename = snapshot_dir .. "/snapshot_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
	local f = io.open(filename, "w")
	if f then
		f:write(vim.json.encode(snapshot))
		f:close()
		print("󰄬 Snapshot generated: " .. filename)
	else
		print("❌ Failed to write snapshot file!")
	end
end

function M.pack_report()
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
	local tools = require("infra.tools")
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
	local parsers =
		{ "c", "cpp", "go", "rust", "python", "typescript", "tsx", "lua", "vim", "vimdoc", "gitcommit", "git_rebase", "diff", "markdown" }
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

function M.pack_update()
	print("󰚰 Checking updates...")
	local updates = M.check_updates()

	if #updates > 0 then
		print(string.format("󰚰 Applying %d updates...", #updates))
		M.apply_updates(updates)
	else
		print("󰄬 Plugins already up to date.")
	end

	M.generate_lockfile()
	M.pack_report()

	-- Treesitter parsers update
	print("󰚰 Updating Treesitter parsers...")
	local parsers_script = vim.fn.stdpath("config") .. "/scripts/parsers"
	vim.system({ parsers_script }):wait()

	print("󰄬 Done. Maintenance report updated.")
end

return M
