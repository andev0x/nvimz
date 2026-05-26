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

	vim.api.nvim_create_user_command("PackUpdate", function()
		M.pack_update()
	end, {
		desc = "Update plugins",
	})

	vim.api.nvim_create_user_command("PackClean", function()
		local inactive = vim.iter(vim.pack.get())
			:filter(function(plugin)
				return not plugin.active
			end)
			:map(function(plugin)
				return plugin.spec.name or plugin.spec.src
			end)
			:totable()

		if #inactive > 0 then
			vim.notify("Removing:\n" .. table.concat(inactive, "\n"), vim.log.levels.INFO)

			vim.pack.del(inactive)
		else
			vim.notify("No inactive plugins found", vim.log.levels.INFO)
		end
	end, {
		desc = "Remove inactive plugins",
	})

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
			})

			pcall(function()
				-- require("infra.lsp").setup() -- Handled lazily by FileType autocmd
				require("plugins.format").setup()
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
				{ source = "mfussenegger/nvim-dap" },
				{ source = "nvim-neotest/nvim-nio" },
				{ source = "rcarriga/nvim-dap-ui" },
				{ source = "leoluz/nvim-dap-go" },
				{ source = "Robitx/gp.nvim" },
				{ source = "zbirenbaum/copilot.lua" },
			})

			pcall(function()
				require("plugins.dap").setup()
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
		io.write(string.format("󰆓 %-20s", name))
		io.flush()

		vim.system({ "git", "-C", plugin.path, "fetch", "origin", "--quiet" }):wait()

		local branch = get_default_branch(plugin.path)
		local local_rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true }):wait().stdout:gsub("\n", "")
		local remote_rev =
			vim.system({ "git", "-C", plugin.path, "rev-parse", "origin/" .. branch }, { text = true }):wait().stdout:gsub(
				"\n",
				""
			)

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
		local rev = vim.system({ "git", "-C", plugin.path, "rev-parse", "HEAD" }, { text = true }):wait().stdout:gsub(
			"\n",
			""
		)
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
	M.validate()

	-- Treesitter parsers update
	print("󰚰 Updating Treesitter parsers...")
	local parsers_script = vim.fn.stdpath("config") .. "/scripts/parsers"
	vim.system({ parsers_script }):wait()

	print("󰄬 Done. Maintenance report updated.")
end

return M
