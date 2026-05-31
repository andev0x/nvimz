local M = {}

function M.setup()
	local cache = require("infra.cache")
	local state = cache.get("plugin_state") or { phases = {} }
	local plugins = require("infra.registry.plugins")
	local phases = require("runtime.phases")

	-- Phase 2: Core Editing (Triggered by file access)
	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		group = vim.api.nvim_create_augroup("PackPhase2", { clear = true }),
		once = true,
		callback = function()
			phases.add(plugins.phase2)

			pcall(function()
				require("features.format").setup()
				require("features.dap").setup()
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
			phases.add(plugins.phase3)

			pcall(function()
				require("features.ai").setup()
			end)

			state.phases[3] = true
			cache.set("plugin_state", state)
		end,
	})
end

return M
