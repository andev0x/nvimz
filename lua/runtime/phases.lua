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

local function add_plugins(plugin_specs)
	vim.pack.add(vim.tbl_map(normalize, plugin_specs))
end

local function has_ui()
	return #vim.api.nvim_list_uis() > 0
end

local function cached_phase_state()
	local cache = require("infra.cache")
	return cache.get("plugin_state") or { phases = {} }
end

local function remember_phase(phase_number)
	local state = cached_phase_state()
	state.phases[phase_number] = true
	local cache = require("infra.cache")
	cache.set("plugin_state", state)
end

local function phase_has_loaded(phase_number)
	return cached_phase_state().phases[phase_number]
end

local function setup_phase_1()
	if has_ui() then
		require("features.interface.theme").setup()
		require("features.interface.icons").setup()
		require("features.interface.statusline").setup()
		require("features.interface.scope_line").setup()
	end

	require("infra.treesitter").setup()
	require("features.lsp").setup()
	require("features.editing.files").setup()
	require("features.editing.pairs").setup()
	require("features.editing.completion").setup()
	require("features.search.pick").setup()
	require("features.git").setup()
end

local function setup_phase_2()
	require("features.format").setup()
	require("features.dap").setup()
end

local function setup_phase_3()
	require("features.ai").setup()
end

local function load_phase(phase_number, plugin_specs, setup)
	add_plugins(plugin_specs)
	pcall(setup)

	if not phase_has_loaded(phase_number) then
		remember_phase(phase_number)
	end
end

function M.add(specs)
	add_plugins(specs)
end

function M.setup()
	vim.schedule(function()
		local registry = require("infra.registry")
		load_phase(1, registry.plugins.phase1, setup_phase_1)
	end)

	-- Load markdown UI only when needed.
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

	vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
		group = vim.api.nvim_create_augroup("PackPhase2", { clear = true }),
		once = true,
		callback = function()
			local registry = require("infra.registry")
			load_phase(2, registry.plugins.phase2, setup_phase_2)
		end,
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = vim.api.nvim_create_augroup("PackPhase3", { clear = true }),
		once = true,
		callback = function()
			local registry = require("infra.registry")
			load_phase(3, registry.plugins.phase3, setup_phase_3)
		end,
	})
end

return M
