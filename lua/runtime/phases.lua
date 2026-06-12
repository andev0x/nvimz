local M = {}

local function normalize(spec)
	local source = type(spec) == "string" and spec or spec.source

	if not (source:find("http", 1, true) or source:find("git@", 1, true)) then
		source = "https://github.com/" .. source
	end

	local final = type(spec) == "table" and vim.tbl_extend("force", {}, spec) or {}

	final.src = source
	final.source = nil

	return final
end

function M.add(specs)
	vim.pack.add(vim.tbl_map(normalize, specs))
end

function M.setup()
	------------------------------------------------------------------
	-- Phase 1: UI + Core Editing
	------------------------------------------------------------------
	vim.schedule(function()
		local is_headless = #vim.api.nvim_list_uis() == 0
		local registry = require("infra.registry")
		local plugins = registry.plugins
		M.add(plugins.phase1)

		pcall(function()
			-- UI (Only if not headless)
			if not is_headless then
				require("features.interface.theme").setup()
				require("features.interface.icons").setup()
				require("features.interface.statusline").setup()
				require("features.interface.scope_line").setup()
			end

			-- Core editing
			require("infra.treesitter").setup()
			require("features.editing.files").setup()
			require("features.editing.pairs").setup()
			require("features.editing.completion").setup()

			-- Search / Git
			require("features.search.pick").setup()
			require("features.git").setup()
		end)

		local cache = require("infra.cache")
		local state = cache.get("plugin_state") or { phases = {} }
		if not state.phases[1] then
			state.phases[1] = true
			cache.set("plugin_state", state)
		end
	end)

	------------------------------------------------------------------
	-- Markdown only when actually opening markdown files
	------------------------------------------------------------------
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("NvimzMarkdown", { clear = true }),
		pattern = "markdown",
		once = true,
		callback = function()
			pcall(function()
				require("features.interface.markdown").setup()
			end)
		end,
	})

	------------------------------------------------------------------
	-- Phase 2: Core Editing Extensions
	------------------------------------------------------------------
	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		group = vim.api.nvim_create_augroup("PackPhase2", { clear = true }),
		once = true,
		callback = function()
			local registry = require("infra.registry")
			local plugins = registry.plugins
			M.add(plugins.phase2)

			pcall(function()
				require("features.format").setup()
				require("features.dap").setup()
			end)

			local cache = require("infra.cache")
			local state = cache.get("plugin_state") or { phases = {} }
			if not state.phases[2] then
				state.phases[2] = true
				cache.set("plugin_state", state)
			end
		end,
	})

	------------------------------------------------------------------
	-- Phase 3: AI / Extra Features
	------------------------------------------------------------------
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = vim.api.nvim_create_augroup("PackPhase3", { clear = true }),
		once = true,
		callback = function()
			local registry = require("infra.registry")
			local plugins = registry.plugins
			M.add(plugins.phase3)

			pcall(function()
				require("features.ai").setup()
			end)

			local cache = require("infra.cache")
			local state = cache.get("plugin_state") or { phases = {} }
			if not state.phases[3] then
				state.phases[3] = true
				cache.set("plugin_state", state)
			end
		end,
	})
end

return M
