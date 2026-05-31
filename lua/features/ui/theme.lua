local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",

		-- Enable transparency for macOS blur/vibrancy compatibility
		transparent = true,
		terminal_colors = true,

		-- ---------------------------------------------------------------------
		-- Deep Forest Palette - Fully Rewritten for Max Readability
		-- Refined for:
		-- - Premium visual hierarchy & strict semantic separation
		-- - Helix-inspired minimalist balance with attenuated saturation
		-- - Explicit separation of function calls from parameters
		-- ---------------------------------------------------------------------
		on_colors = function(colors)
			-- Base solid backgrounds
			colors.bg = "#0b1210"
			colors.bg_dark = "#080d0b"
			colors.bg_float = "#0d1614"
			colors.bg_sidebar = "#080d0b"
			colors.bg_statusline = "#0d1614"

			-- Subdued UI accents
			colors.bg_visual = "#253b34"
			colors.bg_highlight = "#101a17"

			-- Primary syntax base tones - Muted and Calm
			colors.green = "#9ad179"
			colors.teal = "#73daca"

			-- -----------------------------------------------------------------
			-- Rewritten Blue Tones for Clear Actions & Structural Isolation
			-- -----------------------------------------------------------------
			-- Standard function blue: Clearer, more vibrant for fast scanning
			colors.blue = "#61afef"
			-- Typographic blue: Lighter for inline types
			colors.blue1 = "#b4f9f8"
			-- Structural blue: Slightly more aqua for methods and calls
			colors.blue2 = "#2ac3de"
			-- Highlight blue: Lighter for brackets/operators
			colors.blue5 = "#89ddff"
			-- Active border blue
			colors.blue6 = "#b4f9f8"
			-- Passive blue
			colors.blue7 = "#394b70"

			-- Structural accents
			colors.orange = "#e6b366"

			-- Muted yellow for standardized parameters & variables
			colors.yellow = "#d9b36c"

			-- Attenuated spectrum mapping for deep forest context
			colors.magenta = "#a7c080"
			colors.magenta2 = "#73daca"
			colors.purple = "#a7c080"
		end,

		-- ---------------------------------------------------------------------
		-- Global Typography & Styling
		-- ---------------------------------------------------------------------
		styles = {
			comments = { italic = true },
			-- Italics applied to keywords for a clean structure
			keywords = { italic = true },
			-- Functions bold for fast structural eye-scanning
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

			-- Soft selections and unobtrusive cursorlines
			highlights.Visual = { bg = colors.bg_visual }
			highlights.CursorLine = { bg = colors.bg_highlight }
			highlights.WinSeparator = { fg = "#1f312b" }

			-- Low-contrast inactive line numbers
			highlights.LineNr = { fg = "#2f3d37" }

			-- High-readability active line number
			highlights.CursorLineNr = { fg = "#d7e3dc", bold = true }

			-- Elegant parenthesis matching
			highlights.MatchParen = {
				fg = colors.orange,
				bg = colors.bg_highlight,
				bold = true,
			}

			-- -----------------------------------------------------------------
			-- Diagnostics & Inlay Hints
			-- -----------------------------------------------------------------
			-- Background set to NONE to prevent transparency bugs
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
			-- Custom Dashboard UI Elements
			-- -----------------------------------------------------------------
			highlights.NvimzLogo = { fg = colors.blue, bold = true }
			highlights.NvimzStats = { fg = colors.green, italic = true }

			-- -----------------------------------------------------------------
			-- Standard Treesitter Syntax (Neovim 0.12+ Optimized)
			-- -----------------------------------------------------------------
			highlights["@keyword"] = { fg = colors.green, italic = true }

			-- -----------------------------------------------------------------
			-- Critical Refinement: Isolation of Functions vs Variables
			-- -----------------------------------------------------------------
			-- Functions: Re-vibrated blue definition for actions
			highlights["@function"] = { fg = colors.blue, bold = true }
			highlights["@function.call"] = { fg = colors.blue, bold = true }
			highlights["@method"] = { fg = colors.blue2 }
			highlights["@method.call"] = { fg = colors.blue2 }

			-- Variables and Parameters: Clear separation via muted yellow
			highlights["@variable"] = { fg = colors.yellow }
			highlights["@parameter"] = { fg = colors.yellow }
			highlights["@variable.parameter"] = { fg = colors.yellow }

			-- Typographic elements and literals
			highlights["@type"] = { fg = colors.blue2 } -- Distinct blue for types
			highlights["@string"] = { fg = "#8fbf8f" } -- Standard forest string green
			highlights["@constant"] = { fg = colors.magenta } -- Muted green for constants
			highlights["@operator"] = { fg = colors.teal } -- Muted teal for operators

			-- Comments: Kept subdued
			highlights["@comment"] = { fg = "#688077", italic = true }

			-- Punctuation
			highlights["@punctuation.bracket"] = { fg = "#5a6e68" }
			highlights["@punctuation.delimiter"] = { fg = "#89b482" }

			-- -----------------------------------------------------------------
			-- Go-specific Semantic Tuning (Synchronized with Blue Function Call)
			-- -----------------------------------------------------------------
			local go_native_tokens = {
				-- Apply new blue action call standard
				["@function.call.go"] = { fg = colors.blue, bold = true },
				["@method.call.go"] = { fg = colors.blue2 },
				["@function.method.go"] = { fg = colors.blue2 },

				-- Bold 'func' statement stands as a structural anchor
				["@keyword.function.go"] = { fg = colors.orange, bold = true },

				-- Isolated struct member colors vs local variables
				["@variable.member.go"] = { fg = "#9cd4d0" },

				-- Typographic declarations
				["@type.go"] = { fg = "#78c2d8", bold = true },
				["@constant.builtin.go"] = { fg = colors.magenta },
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
