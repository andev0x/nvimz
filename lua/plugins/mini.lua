local M = {}

function M.setup()
	-- mini.files: File management
	require("mini.files").setup({
		windows = {
			preview = true,
			width_preview = 80,
		},
	})
	vim.keymap.set("n", "<leader>e", function()
		if not MiniFiles.close() then
			MiniFiles.open(vim.api.nvim_buf_get_name(0))
		end
	end, { desc = "Toggle Mini Files" })

	-- mini.pick: Fuzzy finder
	require("mini.pick").setup()
	vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
	vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
	vim.keymap.set("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Help tags" })
	vim.keymap.set("n", "<leader>gc", "<cmd>Pick git_commits<cr>", { desc = "Git commits" })
	vim.keymap.set("n", "<leader>gh", "<cmd>Pick git_hunks<cr>", { desc = "Git hunks" })

	-- mini.extra: Extra pickers and more
	require("mini.extra").setup()

	-- mini.git: Git integration
	require("mini.git").setup()
	vim.keymap.set({ "n", "x" }, "<leader>gs", "<cmd>Git<cr>", { desc = "Git status" })
	vim.keymap.set({ "n", "x" }, "<leader>gb", "<cmd>lua MiniGit.show_at_cursor()<cr>", { desc = "Git blame" })

	-- mini.diff: Diff integration
	require("mini.diff").setup()
	vim.keymap.set("n", "<leader>gd", "<cmd>lua MiniDiff.toggle_overlay()<cr>", { desc = "Toggle diff overlay" })

	-- mini.statusline: Minimalist status bar
	require("mini.statusline").setup({ set_vim_settings = false })

	-- mini.completion: Native LSP completion
	require("mini.completion").setup({
		lsp_completion = {
			source_func = "completefunc",
			auto_setup = true,
		},
		window = {
			info = { border = "rounded" },
			signature = { border = "rounded" },
		},
	})

	-- Tab completion
	local imap = function(lhs, rhs)
		vim.keymap.set("i", lhs, rhs, { expr = true, replace_keycodes = false })
	end

	imap("<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
	imap("<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])
end

return M
