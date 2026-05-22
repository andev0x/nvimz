-- Record startup timestamp as early as possible
_G.nvimz_start_time = vim.uv.hrtime()

-- Enable Lua bytecode cache loader
if vim.loader and vim.loader.enable then
	vim.loader.enable()
end

-- Disable unused builtin runtime plugins early
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1

-- Minimum supported Neovim version
if vim.fn.has("nvim-0.12") == 0 then
	error("nvim-zen requires Neovim 0.12+")
end

-- Global leaders
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Core modules: Options are essential for early UI state
pcall(require, "core.options")

-- Defer remaining core modules to the next event loop tick
vim.schedule(function()
	local core_deferred = {
		"core.filetype",
		"core.keymaps",
		"core.autocmds",
		"core.terminal",
	}

	for _, module in ipairs(core_deferred) do
		pcall(require, module)
	end

	-- Setup deferred UI components
	pcall(function()
		require("core.treesitter").setup()
		require("core.scope_line").setup()
	end)

	-- Plugin/dependency infrastructure
	pcall(function()
		require("infra.deps").setup()
	end)

	-- Register health commands
	pcall(function()
		require("core.health").register_command()
	end)
end)

-- Startup profiler / tracker
require("core.startup").track(_G.nvimz_start_time)
