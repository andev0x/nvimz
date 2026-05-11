-- 1. Record the absolute start time in nanoseconds at the very first microsecond
_G.nvimz_start_time = vim.uv.hrtime()

-- 2. Enable bytecode compiler loader immediately to accelerate all subsequent loads
if vim.loader and vim.loader.enable then
	vim.loader.enable()
end

-- 3. Enforce minimum system requirements
if vim.fn.has("nvim-0.12") == 0 then
	error("nvim-zen requires Neovim 0.12+")
end

-- 4. Define global map leaders
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 5. Manage package manager infrastructure (builtin vim.pack)
-- No bootstrap needed for vim.pack as it is built-in to Neovim 0.12+

-- 6. Load Core Configurations (Sorted by resource load priority)
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.terminal")
require("core.treesitter").setup()

-- Register health check commands without executing them synchronously at startup
require("core.health").check()
require("core.health").register_command()

-- 7. Initialize Infrastructure & Plugins
require("infra.deps").setup()

-- 8. Track and warn if total actual startup time exceeds the 20ms target
require("core.startup").track(_G.nvimz_start_time)
