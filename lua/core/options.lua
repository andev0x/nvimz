vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.scrolloff = 4
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "
vim.opt.listchars = {
	tab = "│ ",
	trail = "•",
	extends = "→",
	precedes = "←",
	nbsp = "◌",
}

vim.opt.lazyredraw = true
vim.opt.synmaxcol = 240
vim.opt.redrawtime = 1500

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildchar = string.byte("\t")

vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99

-- Host-local overrides are optional and loaded directly; there is no cache to
-- invalidate when machine/local.lua changes.
local local_config = vim.fn.stdpath("config") .. "/lua/machine/local.lua"
if vim.fn.filereadable(local_config) == 1 then
	local ok, machine = pcall(require, "machine.local")
	if not ok then
		vim.schedule(function()
			vim.notify("[nvimz] machine/local.lua failed to load:\n" .. tostring(machine), vim.log.levels.ERROR)
		end)
	elseif type(machine) == "table" and type(machine.python_path) == "string" then
		vim.g.python3_host_prog = machine.python_path
	end
end
