vim.opt.number = true
vim.opt.relativenumber = false
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
vim.opt.mouse = "a" -- Enable mouse support
vim.opt.scrolloff = 4
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.timeoutlen = 300
vim.opt.updatetime = 200 -- Faster completion and diagnostics

-- Line wrapping and special characters
vim.opt.wrap = true
vim.opt.linebreak = true -- Proper word wrap: don't break words
vim.opt.breakindent = true -- Smart break indent: wrapped lines match indentation
vim.opt.showbreak = "↳ "
vim.opt.list = true
vim.opt.listchars = {
	tab = "│ ", -- Slender vertical line for tabs
	trail = "·", -- Small dot for trailing spaces
	extends = "»", -- Slender indicator for lines extending off-screen
	precedes = "«",
	nbsp = "␣",
}

vim.opt.lazyredraw = true -- Reduce redraw jitter
vim.opt.shada = "!,'100,<50,s10,h" -- Limit ShaDa file size
vim.opt.synmaxcol = 240 -- Don't highlight long lines
vim.opt.redrawtime = 1500 -- Limit time for redrawing

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildchar = 9 -- <Tab>

vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

-- Folding
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99

local ok, machine = pcall(require, "machine.local")
if ok and type(machine) == "table" and type(machine.python_path) == "string" then
	vim.g.python3_host_prog = machine.python_path
end
