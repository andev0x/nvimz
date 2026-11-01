-- Plugin declarations grouped by loading boundary.
-- Specs use the native `vim.pack` shape (`src`, optional `name`/`version`).
-- Groups are added by `runtime/phases.lua`; none is added while init.lua is sourced.

local function gh(repo)
	return "https://github.com/" .. repo
end

local M = {}

-- First render: the two plugins whose state is visible on the first screen.
M.tier1 = {
	{ src = gh("folke/tokyonight.nvim"), name = "tokyonight" },
	{ src = gh("echasnovski/mini.nvim") },
}

-- Markdown is added only when a Markdown buffer exists. Its plugin script
-- calls setup() itself, so adding it is the whole activation.
M.markdown = {
	{ src = gh("MeanderingProgrammer/render-markdown.nvim") },
}

-- File explorer: added only when the explorer is opened or a directory starts.
M.oil = {
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("refractalize/oil-git-status.nvim") },
}

-- Formatting: added on the first write or explicit format action.
M.format = {
	{ src = gh("stevearc/conform.nvim") },
}

-- Debugging: plugins are added on the first debug action, and setup follows
-- immediately. Before that, `:Dap*` commands are provided by lazy stubs.
M.dap = {
	{ src = gh("mfussenegger/nvim-dap") },
	{ src = gh("nvim-neotest/nvim-nio") },
	{ src = gh("rcarriga/nvim-dap-ui") },
	{ src = gh("leoluz/nvim-dap-go") },
}

-- AI: each side is activated independently. gp has no plugin/ scripts; copilot
-- has one that only registers `:Copilot`.
M.gp = {
	{ src = gh("Robitx/gp.nvim") },
}

M.copilot = {
	{ src = gh("zbirenbaum/copilot.lua") },
}

return M
