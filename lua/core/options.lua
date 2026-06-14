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

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)
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
vim.opt.shada = "!,'100,<50,s10,h"
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

vim.schedule(function()
	local cache = require("infra.cache")
	local machine_state = cache.get("machine_state")

	if not machine_state then
		local ok, local_machine = pcall(require, "machine.local")
		if ok and type(local_machine) == "table" then
			machine_state = local_machine
			cache.set("machine_state", machine_state)
		end
	end

	if machine_state and type(machine_state.python_path) == "string" then
		vim.g.python3_host_prog = machine_state.python_path
	end
end)
