-- Record startup timestamp as early as possible
_G.nvimz_start_time = _G.nvimz_start_time or vim.uv.hrtime()

-- Global leaders
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable unused builtin runtime plugins early
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
