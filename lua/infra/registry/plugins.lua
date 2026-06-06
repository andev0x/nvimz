local M = {}

M.phase1 = {
	{ source = "folke/tokyonight.nvim", name = "tokyonight" },
	{ source = "echasnovski/mini.nvim" },
	{ source = "MeanderingProgrammer/render-markdown.nvim" },
}

M.phase2 = {
	{ source = "neovim/nvim-lspconfig" },
	{ source = "stevearc/conform.nvim" },
	{ source = "mfussenegger/nvim-dap" },
	{ source = "nvim-neotest/nvim-nio" },
	{ source = "rcarriga/nvim-dap-ui" },
	{ source = "leoluz/nvim-dap-go" },
}

M.phase3 = {
	{ source = "Robitx/gp.nvim" },
	{ source = "zbirenbaum/copilot.lua" },
}

return M
