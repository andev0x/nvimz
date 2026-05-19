local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
map("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

map("n", "<leader>ds", function()
	require("core.startup").open()
end, { desc = "Open dashboard", silent = true })

map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })

map("n", "<leader>cp", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied relative path: " .. path)
end, { desc = "Copy relative path", silent = true })

map("n", "<leader>cP", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Copied absolute path: " .. path)
end, { desc = "Copy absolute path", silent = true })

map("n", "<leader>cn", function()
	local name = vim.fn.expand("%:t")
	vim.fn.setreg("+", name)
	vim.notify("Copied filename: " .. name)
end, { desc = "Copy filename", silent = true })

map("n", "<leader>cd", function()
	local dir = vim.fn.expand("%:h")
	vim.fn.setreg("+", dir)
	vim.notify("Copied directory path: " .. dir)
end, { desc = "Copy directory path", silent = true })

-- Split management
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical", silent = true })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal", silent = true })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize splits", silent = true })

-- Resize splits
vim.keymap.set("n", "<leader>rh", "<cmd>vertical resize -2<CR>", { desc = "Resize left" })
vim.keymap.set("n", "<leader>rl", "<cmd>vertical resize +2<CR>", { desc = "Resize right" })
vim.keymap.set("n", "<leader>rj", "<cmd>resize -2<CR>", { desc = "Resize down" })
vim.keymap.set("n", "<leader>rk", "<cmd>resize +2<CR>", { desc = "Resize up" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

-- Fast navigation (Smooth-like scrolling)
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center", silent = true })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center", silent = true })

-- Folding
map("n", "<leader>z", "za", { desc = "Toggle fold", silent = true })

-- Font size
-- Note: Terminal-level shortcuts (Cmd/Ctrl + and Cmd/Ctrl -) usually handle zooming
-- in/out as Neovim inherits the font size from the terminal emulator.

-- Terminal
map("n", "<leader>tt", function()
	require("core.terminal").toggle()
end, { desc = "Toggle floating terminal", silent = true })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- UI Toggles
map("n", "<leader>uh", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "LSP: toggle inlay hints", silent = true })
