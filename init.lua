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
vim.g.loaded_matchparen = 1

-- Minimum supported Neovim version
if vim.fn.has("nvim-0.12") == 0 then
	error("nvim-zen requires Neovim 0.12+")
end

-- Global leaders
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Core modules
require("core.filetype")
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.terminal")
require("core.treesitter").setup()

-- Plugin/dependency infrastructure
require("infra.deps").setup()

-- Register health commands only
require("core.health").register_command()

-- Startup profiler / tracker
require("core.startup").track(_G.nvimz_start_time)
