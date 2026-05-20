local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",

		-- Enable transparency for macOS blur/vibrancy compatibility
		transparent = true,
		terminal_colors = true,

		-- ---------------------------------------------------------------------
		-- Deep Forest Palette
		-- Refined for:
		-- - Better visual hierarchy & semantic separation
		-- - Reduced eye fatigue during long development sessions
		-- - Premium Helix-inspired minimalist balance
		-- ---------------------------------------------------------------------
		on_colors = function(colors)
			-- Base solid backgrounds
			colors.bg = "#0b1210"
			colors.bg_dark = "#080d0b"
			colors.bg_float = "#0d1614"
			colors.bg_sidebar = "#080d0b"
			colors.bg_statusline = "#0d1614"

			-- Subdued UI accents
			colors.bg_visual = "#16231f"
			colors.bg_highlight = "#101a17"

			-- Primary syntax base tones
			colors.green = "#9ad179"
			colors.teal = "#73daca"

			-- Function and structural blues
			colors.blue = "#7dcfff"
			colors.blue1 = "#b4f9f8"
			colors.blue2 = "#2ac3de"
			colors.blue5 = "#89ddff"
			colors.blue6 = "#b4f9f8"
			colors.blue7 = "#394b70"

			-- Structural accents
			colors.orange = "#e6b366"
			colors.yellow = "#d9b36c"

			-- Attenuated neon spectrum to prevent eye strain
			colors.magenta = "#a7c080"
			colors.magenta2 = "#73daca"
			colors.purple = "#a7c080"
		end,

		-- ---------------------------------------------------------------------
		-- Global Typography & Styling
		-- ---------------------------------------------------------------------
		styles = {
			comments = { italic = true },
			-- Italics only for clean keywords; removes bold noise
			keywords = { italic = true },
			-- Keeps functions bold for lightning-fast code scanning
			functions = { bold = true },
			variables = {},
			sidebars = "transparent",
			floats = "transparent",
		},

		on_highlights = function(highlights, colors)
			-- -----------------------------------------------------------------
			-- Core Editor UI
			-- -----------------------------------------------------------------
			highlights.Normal = { bg = "NONE" }
			highlights.NormalFloat = { bg = "NONE" }
			highlights.SignColumn = { bg = "NONE" }
			highlights.EndOfBuffer = { fg = colors.bg_dark }

			-- Muted visual selections and cursorlines
			highlights.Visual = { bg = colors.bg_visual }
			highlights.CursorLine = { bg = colors.bg_highlight }
			highlights.WinSeparator = { fg = "#1f312b" }

			-- Low-contrast non-active line numbers to reduce distractions
			highlights.LineNr = { fg = "#2f3d37" }
			highlights.CursorLineNr = { fg = colors.green, bold = true }

			-- Elegant, non-intrusive parenthesis matching
			highlights.MatchParen = {
				fg = colors.orange,
				bg = "NONE",
				bold = true,
			}

			-- -----------------------------------------------------------------
			-- Diagnostics & Inlay Hints
			-- -----------------------------------------------------------------
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

			-- -----------------------------------------------------------------
			-- Dashboard / Custom UI Elements
			-- -----------------------------------------------------------------
			highlights.NvimzLogo = { fg = colors.teal, bold = true }
			highlights.NvimzStats = { fg = colors.green, italic = true }

			-- -----------------------------------------------------------------
			-- Standard Treesitter Cú Pháp (Neovim 0.12 Compatible)
			-- -----------------------------------------------------------------
			highlights["@keyword"] = { fg = colors.green, italic = true }
			highlights["@variable"] = { fg = "#7aa2b8" }

			-- Modern parameter specs linking for fallback safety
			highlights["@parameter"] = { fg = "#86a9b7" }
			highlights["@variable.parameter"] = { fg = "#86a9b7" }

			highlights["@function"] = { fg = colors.blue, bold = true }
			highlights["@function.call"] = { fg = colors.blue }
			highlights["@method"] = { fg = colors.blue2 }
			highlights["@method.call"] = { fg = colors.blue2 }

			highlights["@type"] = { fg = "#78c2d8" }
			highlights["@string"] = { fg = "#8fbf8f" }
			highlights["@comment"] = { fg = "#5a6e68", italic = true }
			highlights["@constant"] = { fg = "#d7ba7d" }
			highlights["@operator"] = { fg = "#89b482" }

			-- Calmed delimiters to maintain forest continuity
			highlights["@punctuation.bracket"] = { fg = "#5a6e68" }
			highlights["@punctuation.delimiter"] = { fg = "#89b482" }

			-- -----------------------------------------------------------------
			-- Go-specific Semantic Tuning
			-- -----------------------------------------------------------------
			local go_native_tokens = {
				-- Function and Method Routing
				["@function.call.go"] = { fg = colors.blue, bold = true },
				["@method.call.go"] = { fg = colors.blue2 },
				["@function.method.go"] = { fg = colors.blue2 },

				-- Bold 'func' keyword acts as a structural anchor
				["@keyword.function.go"] = { fg = colors.orange, bold = true },

				-- Distinct coloring for struct members vs local vars
				["@variable.member.go"] = { fg = "#9cd4d0" },

				-- Clean type declaration formatting
				["@type.go"] = { fg = "#78c2d8", bold = true },
				["@constant.builtin.go"] = { fg = "#d7ba7d" },
			}

			for token, style in pairs(go_native_tokens) do
				highlights[token] = style
			end
		end,
	})

	-- Apply the configured palette variant
	vim.cmd.colorscheme("tokyonight-moon")
end

return M
