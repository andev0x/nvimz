local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

map("n", "<leader>ds", function()
	require("core.startup").open()
end, { desc = "Open dashboard", silent = true })

map("n", "<leader>xx", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

-- Terminal
map("n", "<leader>t", function()
	require("core.terminal").toggle()
end, { desc = "Toggle floating terminal", silent = true })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
