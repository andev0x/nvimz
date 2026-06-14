local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",
		transparent = true,
		terminal_colors = true,

		on_colors = function(colors)
			colors.bg = "#0b1210"
			colors.bg_dark = "#080d0b"
			colors.bg_float = "#0d1614"
			colors.bg_sidebar = "#080d0b"
			colors.bg_statusline = "#0d1614"

			colors.bg_visual = "#253b34"
			colors.bg_highlight = "#101a17"

			colors.green = "#9ad179"
			colors.teal = "#73daca"

			-- Blue tones: function calls, types, structure, borders, in order of brightness
			colors.blue = "#61afef"
			colors.blue1 = "#b4f9f8"
			colors.blue2 = "#2ac3de"
			colors.blue5 = "#89ddff"
			colors.blue6 = "#b4f9f8"
			colors.blue7 = "#394b70"

			colors.orange = "#e6b366"
			colors.yellow = "#d9b36c"

			colors.magenta = "#a7c080"
			colors.magenta2 = "#73daca"
			colors.purple = "#a7c080"
		end,

		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			functions = { bold = true },
			variables = {},
			sidebars = "transparent",
			floats = "transparent",
		},

		on_highlights = function(highlights, colors)
			highlights.Normal = { bg = "NONE" }
			highlights.NormalFloat = { bg = "NONE" }
			highlights.SignColumn = { bg = colors.bg }
			highlights.EndOfBuffer = { fg = colors.bg_dark }

			highlights.Visual = { bg = colors.bg_visual }
			highlights.CursorLine = { bg = colors.bg_highlight }
			highlights.WinSeparator = { fg = "#1f312b" }

			highlights.LineNr = { fg = "#2f3d37" }
			highlights.CursorLineNr = { fg = "#d7e3dc", bold = true }

			highlights.MatchParen = {
				fg = colors.orange,
				bg = colors.bg_highlight,
				bold = true,
			}

			highlights.MiniDiffSignAdd = { fg = colors.green }
			highlights.MiniDiffSignChange = { fg = colors.blue }
			highlights.MiniDiffSignDelete = { fg = colors.red }

			highlights.DiagnosticVirtualTextHint = {
				fg = "#5a6e68",
				bg = "NONE",
				italic = true,
			}
			highlights.LspInlayHint = {
				fg = "#4c5c55",
				bg = "NONE",
				italic = true,
			}

			highlights.NvimzLogo = { fg = colors.blue, bold = true }
			highlights.NvimzStats = { fg = colors.green, italic = true }

			highlights["@keyword"] = { fg = colors.green, italic = true }
			highlights["@function"] = { fg = colors.blue, bold = true }
			highlights["@variable"] = { fg = colors.yellow }
			highlights["@parameter"] = { fg = colors.yellow }
			highlights["@type"] = { fg = colors.blue2 }
			highlights["@string"] = { fg = "#8fbf8f" }
			highlights["@constant"] = { fg = colors.magenta }
			highlights["@operator"] = { fg = colors.teal }
			highlights["@comment"] = { fg = "#688077", italic = true }
			highlights["@punctuation.bracket"] = { fg = "#5a6e68" }
			highlights["@punctuation.delimiter"] = { fg = "#89b482" }

			-- Neutralize markdown highlights -- render-markdown.nvim handles these
			highlights["@markdown.heading"] = { fg = "#d7e3dc", bold = true }
			highlights["@markdown.quote"] = { fg = "#688077" }
			highlights["@markdown.punctuation"] = { fg = "#5a6e68" }
			highlights["@markdown.fence"] = { fg = "#5a6e68" }

			-- Matches the Go highlights.scm for synchronized color between Lua and Go
			local custom_scm_tokens = {
				["@function.call"] = { fg = colors.blue, bold = true },
				["@function.method"] = { fg = colors.blue2 },
				["@function.method.call"] = { fg = colors.blue2 },
				["@constructor"] = { fg = colors.orange, bold = true },

				["@keyword.function"] = { fg = colors.orange, bold = true },
				["@keyword.type"] = { fg = colors.green, italic = true },
				["@keyword.return"] = { fg = colors.green, italic = true },
				["@keyword.coroutine"] = { fg = colors.green, italic = true },
				["@keyword.repeat"] = { fg = colors.green, italic = true },
				["@keyword.import"] = { fg = colors.green, italic = true },
				["@keyword.conditional"] = { fg = colors.green, italic = true },

				["@type.definition"] = { fg = "#78c2d8", bold = true },
				["@type.builtin"] = { fg = colors.blue2 },
				["@variable.member"] = { fg = "#9cd4d0" },
				["@variable.parameter"] = { fg = colors.yellow },
				["@module"] = { fg = colors.blue1 },

				["@number.float"] = { fg = colors.magenta },
				["@constant.builtin"] = { fg = colors.magenta },
				["@function.builtin"] = { fg = colors.blue, bold = true },
			}

			for token, style in pairs(custom_scm_tokens) do
				highlights[token] = style
			end
		end,
	})

	vim.cmd.colorscheme("tokyonight-moon")
end

return M
