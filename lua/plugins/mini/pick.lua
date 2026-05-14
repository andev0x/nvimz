local M = {}

function M.setup()
	require("mini.pick").setup({
		window = {
			config = function()
				local height = math.floor(0.618 * vim.o.lines)
				local width = math.floor(0.618 * vim.o.columns)
				return {
					anchor = "NW",
					height = height,
					width = width,
					row = math.floor(0.5 * (vim.o.lines - height)),
					col = math.floor(0.5 * (vim.o.columns - width)),
				}
			end,
		},
		options = {
			content_from_bottom = true,
		},
	})

	-- General Finders
	vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
	vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
	vim.keymap.set("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Help tags" })
	vim.keymap.set("n", "<leader>fd", "<cmd>Pick diagnostic<cr>", { desc = "Find diagnostics" })

	require("mini.extra").setup()
	vim.keymap.set("n", "<leader>gc", "<cmd>lua MiniExtra.pickers.git_commits()<cr>", { desc = "Git commits" })
	vim.keymap.set("n", "<leader>gh", "<cmd>lua MiniExtra.pickers.git_hunks()<cr>", { desc = "Git hunks" })

	-- LSP Pickers
	vim.keymap.set("n", "<leader>lr", "<cmd>Pick lsp scope='references'<cr>", { desc = "LSP References (Picker)" })
	vim.keymap.set("n", "<leader>ld", "<cmd>Pick lsp scope='definition'<cr>", { desc = "LSP Definition (Picker)" })
	vim.keymap.set(
		"n",
		"<leader>ly",
		"<cmd>Pick lsp scope='type_definition'<cr>",
		{ desc = "LSP Type Definition (Picker)" }
	)
	vim.keymap.set(
		"n",
		"<leader>li",
		"<cmd>Pick lsp scope='implementation'<cr>",
		{ desc = "LSP Implementation (Picker)" }
	)
	vim.keymap.set(
		"n",
		"<leader>cs",
		"<cmd>Pick lsp scope='document_symbol'<cr>",
		{ desc = "LSP Document Symbols (Outline)" }
	)
	vim.keymap.set("n", "<leader>cS", "<cmd>Pick lsp scope='workspace_symbol'<cr>", { desc = "LSP Workspace Symbols" })
end

return M
