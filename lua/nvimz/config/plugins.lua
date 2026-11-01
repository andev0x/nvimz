-- Plugin declarations grouped by loading phase.
-- Specs use the native `vim.pack` shape (`src`, optional `name`/`version`).

local function gh(repo)
	return "https://github.com/" .. repo
end

local M = {}

M.phase1 = {
	{ src = gh("folke/tokyonight.nvim"), name = "tokyonight" },
	{ src = gh("echasnovski/mini.nvim") },
	{ src = gh("MeanderingProgrammer/render-markdown.nvim") },
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("refractalize/oil-git-status.nvim") },
}

M.phase2 = {
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("mfussenegger/nvim-dap") },
	{ src = gh("nvim-neotest/nvim-nio") },
	{ src = gh("rcarriga/nvim-dap-ui") },
	{ src = gh("leoluz/nvim-dap-go") },
}

M.phase3 = {
	{ src = gh("Robitx/gp.nvim") },
	{ src = gh("zbirenbaum/copilot.lua") },
}

return M
