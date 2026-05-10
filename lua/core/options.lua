vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = false

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
vim.opt.scrolloff = 4
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildchar = 9 -- <Tab>

vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

local ok, machine = pcall(require, "machine.local")
if ok and type(machine) == "table" and type(machine.python_path) == "string" then
	vim.g.python3_host_prog = machine.python_path
end
