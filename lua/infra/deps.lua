local M = {}

function M.setup()
	local add = MiniDeps.add
	local later = MiniDeps.later

	later(function()
		add({ source = "neovim/nvim-lspconfig" })
		require("infra.lsp").setup()
	end)

	later(function()
		add({ source = "catppuccin/nvim", name = "catppuccin" })
		require("plugins.theme").setup()
	end)

	later(function()
		add({ source = "echasnovski/mini.nvim" })
		require("plugins.mini").setup()
	end)

	later(function()
		add({ source = "mfussenegger/nvim-dap" })
		add({ source = "nvim-neotest/nvim-nio" })
		add({ source = "rcarriga/nvim-dap-ui" })
		add({ source = "leoluz/nvim-dap-go" })
		require("plugins.dap").setup()
	end)

	later(function()
		add({ source = "Robitx/gp.nvim" })
		require("plugins.ai").setup()
	end)

	later(function()
		add({ source = "stevearc/conform.nvim" })
		require("plugins.format").setup()
	end)
end

return M
