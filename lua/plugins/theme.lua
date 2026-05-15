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
			-- Required for Helix-like intelligent coloring
			native_lsp = {
				enabled = true,
				semantic_tokens = true,
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
		-- Using custom_highlights to override default theme behaviors
		custom_highlights = function(colors)
			return {
				-- 1. Helix-like "Flat" Variables: Removes excessive colors from identifiers
				-- This targets both Treesitter and LSP Semantic Tokens
				["@variable"] = { fg = colors.text },
				["@variable.parameter"] = { fg = colors.text },
				["@variable.member"] = { fg = colors.text },
				["@property"] = { fg = colors.text },
				["@lsp.type.variable"] = { fg = colors.text },
				["@lsp.type.parameter"] = { fg = colors.text },
				["@lsp.type.property"] = { fg = colors.text },
				["@lsp.type.variable.lua"] = { fg = colors.text },

				-- 2. Inlay Hints: Styled with a subtle background and Teal foreground
				-- Mimics the "Block" look from Helix for type/parameter hints
				LspInlayHint = {
					fg = "#70bfa3", -- Your preferred Teal
					bg = "#1e1e2e", -- Slightly darker than Mocha base for contrast
					italic = true,
				},

				-- 3. UI Elements & Invisible Characters
				NonText = { fg = colors.surface0 },
				SpecialKey = { fg = colors.surface0 },

				-- 4. Refined Function Calls: Subtle Blue instead of bright highlights
				["@function.call"] = { fg = colors.blue },
				["@method.call"] = { fg = colors.blue },
				["@lsp.type.function"] = { fg = colors.blue },

				-- 5. Constants & Types: Keeping them distinct but not overwhelming
				["@constant"] = { fg = colors.peach },
				["@type"] = { fg = colors.yellow },
				["@lsp.type.type"] = { fg = colors.yellow },
			}
		end,
	})

	-- Apply the colorscheme
	vim.cmd.colorscheme("catppuccin")
end

return M
