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

	-- Custom highlight overrides
	local colors = {
		bg_dark = "#181825", -- Mantle
		surface0 = "#313244", -- Surface0
		teal = "#70bfa3", -- Teal (Soft Blue)
	}

	-- Block Background for Inlay Hints
	vim.api.nvim_set_hl(0, "LspInlayHint", { fg = colors.teal, bg = colors.bg_dark, italic = true })

	-- Blur hidden characters
	vim.api.nvim_set_hl(0, "NonText", { fg = colors.surface0 })
	vim.api.nvim_set_hl(0, "SpecialKey", { fg = colors.surface0 })
end

return M
