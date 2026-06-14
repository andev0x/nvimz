vim.schedule(function()
	local set_keymap = vim.keymap.set

	set_keymap("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
	set_keymap("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
	set_keymap("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

	set_keymap("n", "<leader>ds", function()
		require("features.interface.dashboard").open()
	end, { desc = "Open dashboard", silent = true })

	set_keymap("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
	set_keymap("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
	set_keymap("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })

	set_keymap("n", "<leader>cp", function()
		local path = vim.fn.expand("%:.")
		vim.fn.setreg("+", path)
		vim.notify("Copied relative path: " .. path)
	end, { desc = "Copy relative path", silent = true })

	set_keymap("n", "<leader>cP", function()
		local path = vim.fn.expand("%:p")
		vim.fn.setreg("+", path)
		vim.notify("Copied absolute path: " .. path)
	end, { desc = "Copy absolute path", silent = true })

	set_keymap("n", "<leader>cn", function()
		local name = vim.fn.expand("%:t")
		vim.fn.setreg("+", name)
		vim.notify("Copied filename: " .. name)
	end, { desc = "Copy filename", silent = true })

	set_keymap("n", "<leader>cd", function()
		local dir = vim.fn.expand("%:h")
		vim.fn.setreg("+", dir)
		vim.notify("Copied directory path: " .. dir)
	end, { desc = "Copy directory path", silent = true })

	set_keymap("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical", silent = true })
	set_keymap("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal", silent = true })
	set_keymap("n", "<leader>se", "<C-w>=", { desc = "Equalize splits", silent = true })

	vim.keymap.set("n", "<leader>rh", "<cmd>vertical resize -2<CR>", { desc = "Resize left" })
	vim.keymap.set("n", "<leader>rl", "<cmd>vertical resize +2<CR>", { desc = "Resize right" })
	vim.keymap.set("n", "<leader>rj", "<cmd>resize -2<CR>", { desc = "Resize down" })
	vim.keymap.set("n", "<leader>rk", "<cmd>resize +2<CR>", { desc = "Resize up" })

	set_keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
	set_keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
	set_keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
	set_keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

	set_keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center", silent = true })
	set_keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center", silent = true })

	set_keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down", silent = true })
	set_keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up", silent = true })

	set_keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down", silent = true })
	set_keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up", silent = true })

	set_keymap({ "n", "v" }, "<leader>z", "za", { desc = "Toggle fold", silent = true })

	set_keymap("n", "<leader>tt", function()
		require("features.editing.terminal").toggle()
	end, { desc = "Toggle floating terminal", silent = true })
	set_keymap("n", "<leader>tb", function()
		require("features.editing.terminal").toggle_bottom()
	end, { desc = "Toggle bottom terminal", silent = true })
	set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

	set_keymap("n", "<leader>uh", function()
		vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
	end, { desc = "LSP: toggle inlay hints", silent = true })
end)
