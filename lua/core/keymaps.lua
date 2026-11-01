local set = vim.keymap.set

-- Core operations
set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
set("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
set("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

set("n", "<leader>ds", function()
	require("features.interface.dashboard").open()
end, { desc = "Open dashboard", silent = true })

-- Buffer management
set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
set("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
set("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })

-- Clipboard path extraction
set("n", "<leader>cp", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied relative path: " .. path)
end, { desc = "Copy relative path", silent = true })

set("n", "<leader>cP", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Copied absolute path: " .. path)
end, { desc = "Copy absolute path", silent = true })

set("n", "<leader>cn", function()
	local name = vim.fn.expand("%:t")
	vim.fn.setreg("+", name)
	vim.notify("Copied filename: " .. name)
end, { desc = "Copy filename", silent = true })

set("n", "<leader>cd", function()
	local dir = vim.fn.expand("%:h")
	vim.fn.setreg("+", dir)
	vim.notify("Copied directory path: " .. dir)
end, { desc = "Copy directory path", silent = true })

-- Window management
set("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical", silent = true })
set("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal", silent = true })
set("n", "<leader>se", "<C-w>=", { desc = "Equalize splits", silent = true })

set("n", "<leader>rh", "<cmd>vertical resize -2<CR>", { desc = "Resize left" })
set("n", "<leader>rl", "<cmd>vertical resize +2<CR>", { desc = "Resize right" })
set("n", "<leader>rj", "<cmd>resize -2<CR>", { desc = "Resize down" })
set("n", "<leader>rk", "<cmd>resize +2<CR>", { desc = "Resize up" })

set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center", silent = true })
set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center", silent = true })

-- Line movement
set("n", "<leader>mj", "<cmd>m .+1<cr>==", { desc = "Move line down", silent = true })
set("n", "<leader>mk", "<cmd>m .-2<cr>==", { desc = "Move line up", silent = true })
set("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down", silent = true })
set("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up", silent = true })

set({ "n", "v" }, "<leader>z", "za", { desc = "Toggle fold", silent = true })

-- Terminals
set("n", "<leader>tt", function()
	require("features.editing.terminal").toggle()
end, { desc = "Toggle floating terminal", silent = true })
set("n", "<leader>tb", function()
	require("features.editing.terminal").toggle_bottom()
end, { desc = "Toggle bottom terminal", silent = true })
set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

set("n", "<leader>uh", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "LSP: toggle inlay hints", silent = true })
