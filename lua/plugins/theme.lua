local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",
		transparent = true,
		terminal_colors = true,
		styles = {
			comments = { italic = true },
			keywords = { italic = true, bold = true }, -- Bold keywords for structural clarity
			functions = { bold = true }, -- Bold functions to make logic "pop"
			variables = {},
			sidebars = "transparent",
			floats = "transparent",
		},
		on_highlights = function(highlights, colors)
			-- 1. Helix-style Flat Identifiers: Removes the "rainbow" effect
			-- Using fg_dark or a custom hex makes it even more subtle than colors.fg
			local variable_color = "#92a2d5"
			highlights["@variable"] = { fg = variable_color }
			highlights["@variable.parameter"] = { fg = variable_color }
			highlights["@variable.member"] = { fg = variable_color }
			highlights["@property"] = { fg = variable_color }
			highlights["@lsp.type.variable"] = { fg = variable_color }
			highlights["@lsp.type.parameter"] = { fg = variable_color }

			-- 2. Neutralize Noise: Dims operators and punctuation (The Helix secret)
			local noise_color = colors.comment
			highlights["@operator"] = { fg = noise_color }
			highlights["@punctuation.bracket"] = { fg = noise_color }
			highlights["@punctuation.delimiter"] = { fg = noise_color }
			highlights["@lsp.type.operator"] = { fg = noise_color }
			highlights["@lsp.type.punctuation"] = { fg = noise_color }

			-- 3. Inlay Hints: Teal foreground with a subtle block background
			highlights.LspInlayHint = {
				fg = "#70bfa3",
				bg = "#1e2030", -- Darker contrast for the "tag" look
				italic = true,
			}

			-- 4. Logic Highlights: High-contrast Blue and Yellow
			highlights["@function.call"] = { fg = colors.blue, bold = true }
			highlights["@method.call"] = { fg = colors.blue, bold = true }
			highlights["@type"] = { fg = colors.yellow, bold = true }
			highlights["@keyword"] = { fg = colors.magenta, bold = true }

			-- 5. Go Specifics: Keep package names neutral
			highlights["@module"] = { fg = variable_color }
			highlights["@lsp.type.namespace"] = { fg = variable_color }
			highlights["@constant.builtin"] = { fg = colors.orange, bold = true } -- nil, true, false

			-- 6. UI Polish
			highlights.NonText = { fg = colors.dark3 }
			highlights.SpecialKey = { fg = colors.dark3 }
		end,
	})

	vim.cmd.colorscheme("tokyonight-moon")
end

return M
