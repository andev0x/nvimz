_G.nvimz_start_time = _G.nvimz_start_time or vim.uv.hrtime()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable netrw; oil.nvim is used as the file explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.g.loaded_perl_provider = 0

-- Skip automatic runtime plugin loading during startup; they are sourced
-- lazily in the background after VimEnter.
vim.o.loadplugins = false
-- Defer shada I/O out of the critical startup path.
vim.o.shada = ""

-- Skip automatic filetype detection during startup; re-enabled in the background.
vim.g.did_load_filetypes = 1