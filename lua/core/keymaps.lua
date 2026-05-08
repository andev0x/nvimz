local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

map("n", "<leader>xx", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })
