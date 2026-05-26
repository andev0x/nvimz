local M = {}

local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")

function M.setup()
	MiniPick.setup({
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
	local function grep_gitignored_hidden()
		local rg_config_path = vim.fs.joinpath(vim.fn.stdpath("config"), "rg-hidden.conf")
		local previous_rg_config = vim.env.RIPGREP_CONFIG_PATH

		vim.env.RIPGREP_CONFIG_PATH = rg_config_path

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniPickStop",
			once = true,

			callback = function()
				vim.env.RIPGREP_CONFIG_PATH = previous_rg_config
			end,
		})

		MiniPick.builtin.grep_live({ tool = "rg" }, { source = { name = "Grep hidden (gitignored)" } })
	end

	local function files_hidden()
		local rg_config_path = vim.fs.joinpath(vim.fn.stdpath("config"), "rg-hidden-files.conf")
		local previous_rg_config = vim.env.RIPGREP_CONFIG_PATH

		vim.env.RIPGREP_CONFIG_PATH = rg_config_path

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniPickStop",
			once = true,

			callback = function()
				vim.env.RIPGREP_CONFIG_PATH = previous_rg_config
			end,
		})

		MiniPick.builtin.files({ tool = "rg" }, { source = { name = "Files (hidden)" } })
	end

	vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", { desc = "Find files" })
	vim.keymap.set("n", "<leader>fe", files_hidden, { desc = "Find files (hidden)" })
	vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
	vim.keymap.set("n", "<leader>fr", grep_gitignored_hidden, { desc = "Grep hidden (gitignored)" })
	vim.keymap.set("n", "<leader>fb", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
	vim.keymap.set("n", "<leader>fh", "<cmd>Pick help<cr>", { desc = "Help tags" })
	vim.keymap.set("n", "<leader>fd", "<cmd>Pick diagnostic<cr>", { desc = "Find diagnostics" })

	MiniExtra.setup()

	vim.keymap.set("n", "<leader>gc", function()
		MiniExtra.pickers.git_commits()
	end, { desc = "Git commits" })

	vim.keymap.set("n", "<leader>gh", function()
		MiniExtra.pickers.git_hunks()
	end, { desc = "Git hunks" })

	-- LSP Pickers
	vim.keymap.set("n", "<leader>lr", "<cmd>Pick lsp scope='references'<cr>", { desc = "LSP References" })
	vim.keymap.set("n", "<leader>ld", "<cmd>Pick lsp scope='definition'<cr>", { desc = "LSP Definition" })

	vim.keymap.set("n", "<leader>ly", "<cmd>Pick lsp scope='type_definition'<cr>", { desc = "LSP Type Definition" })

	vim.keymap.set("n", "<leader>li", "<cmd>Pick lsp scope='implementation'<cr>", { desc = "LSP Implementation" })

	vim.keymap.set("n", "<leader>cs", "<cmd>Pick lsp scope='document_symbol'<cr>", { desc = "Document Symbols" })

	vim.keymap.set("n", "<leader>cS", "<cmd>Pick lsp scope='workspace_symbol'<cr>", { desc = "Workspace Symbols" })
end

return M
