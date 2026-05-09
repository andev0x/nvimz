local M = {}

function M.setup()
	require("catppuccin").setup({
		flavour = "mocha", -- latte, frappe, macchiato, mocha
		transparent_background = true,
		term_colors = true,
		integrations = {
			mini = {
				enabled = true,
				indentscope_color = "subtext0",
			},
			treesitter = true,
			native_lsp = {
				enabled = true,
				virtual_text = {
					errors = { "italic" },
					hints = { "italic" },
					warnings = { "italic" },
					information = { "italic" },
				},
				underlines = {
					errors = { "underline" },
					hints = { "underline" },
					warnings = { "underline" },
					information = { "underline" },
				},
			},
		},
	})

	vim.cmd.colorscheme("catppuccin")
end

return M
