local start_ns = vim.uv.hrtime()

if vim.fn.has("nvim-0.12") == 0 then
	error("nvim-zen requires Neovim 0.12+")
end

if vim.loader and vim.loader.enable then
	vim.loader.enable()
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local path_package = vim.fn.stdpath("data") .. "/site"
local mini_path = path_package .. "/pack/deps/start/mini.deps"

if not vim.uv.fs_stat(mini_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch",
		"v0.17.0",
		"https://github.com/echasnovski/mini.deps",
		mini_path,
	})
end

vim.cmd.packadd("mini.deps")
require("mini.deps").setup({ path = { package = path_package } })

require("core.health").check()
require("core.health").register_command()
require("core.options")
require("core.keymaps")
require("core.autocmds")
require("core.terminal")
require("infra.deps").setup()
require("core.startup").track(start_ns)
