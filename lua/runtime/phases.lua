local M = {}

local plugins = require("nvimz.config.plugins")

local UI_MODULES = {
	"features.interface.theme",
	"features.interface.icons",
	"features.interface.statusline",
	"features.interface.scope_line",
}

local CORE_MODULES = {
	"nvimz.treesitter",
	"features.lsp",
	"features.editing.files",
	"features.editing.pairs",
	"features.editing.completion",
	"features.search.pick",
	"features.git",
}

local FORMAT_DEBUG_MODULES = {
	"features.format",
	"features.dap",
}

local AI_MODULES = {
	"features.ai",
}

local function has_ui()
	return #vim.api.nvim_list_uis() > 0
end

local function report(scope, err)
	vim.notify(("[nvimz] %s failed:\n%s"):format(scope, tostring(err)), vim.log.levels.ERROR)
end

local function add_plugins(specs)
	local ok, err = pcall(vim.pack.add, specs)
	if not ok then
		report("plugin installation", err)
	end
end

local function setup_module(module)
	local ok, err = pcall(function()
		require(module).setup()
	end)
	if not ok then
		report(module, err)
	end
end

local function setup_modules(modules)
	for _, module in ipairs(modules) do
		setup_module(module)
	end
end

local function has_markdown_buffer()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "markdown" then
			return true
		end
	end
	return false
end

local markdown_ready = false

local function setup_markdown()
	if markdown_ready then
		return
	end
	markdown_ready = true
	setup_module("features.interface.markdown")
end

local function load_phase1()
	add_plugins(plugins.phase1)
	if has_ui() then
		setup_modules(UI_MODULES)
	end
	setup_modules(CORE_MODULES)

	-- The markdown plugin is only available after phase 1. Handle a Markdown
	-- file that was opened on the command line before registering the trigger.
	if has_markdown_buffer() then
		setup_markdown()
	end
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		once = true,
		callback = setup_markdown,
	})
end

local function load_phase2()
	add_plugins(plugins.phase2)
	setup_modules(FORMAT_DEBUG_MODULES)
end

local function load_phase3()
	add_plugins(plugins.phase3)
	setup_modules(AI_MODULES)
end

function M.setup()
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			vim.defer_fn(function()
				load_phase1()
				vim.defer_fn(load_phase2, 0)
			end, 0)
		end,
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		once = true,
		callback = load_phase3,
	})
end

return M
