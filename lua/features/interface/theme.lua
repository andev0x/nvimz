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
			-- Universal Treesitter Mappings (Fallback Strategy)
			-- -----------------------------------------------------------------
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

			-- -----------------------------------------------------------------
			-- Granular Global Mappings matching your Go highlights.scm perfectly
			-- This guarantees 100% color synchronization between Lua and Go
			-- -----------------------------------------------------------------
			local custom_scm_tokens = {
				-- Function Calls & Methods
				["@function.call"] = { fg = colors.blue, bold = true },
				["@function.method"] = { fg = colors.blue2 },
				["@function.method.call"] = { fg = colors.blue2 },
				["@constructor"] = { fg = colors.orange, bold = true }, -- Matches your custom New/Make query

				-- Fine-grained Keywords (Fixes all faded/monochrome tokens in main.go)
				["@keyword.function"] = { fg = colors.orange, bold = true }, -- Distinct orange 'func' anchor
				["@keyword.type"] = { fg = colors.green, italic = true }, -- type, struct, interface
				["@keyword.return"] = { fg = colors.green, italic = true }, -- return
				["@keyword.coroutine"] = { fg = colors.green, italic = true }, -- go
				["@keyword.repeat"] = { fg = colors.green, italic = true }, -- for
				["@keyword.import"] = { fg = colors.green, italic = true }, -- import, package
				["@keyword.conditional"] = { fg = colors.green, italic = true }, -- if, else, switch, case

				-- Identifiers, Structural Scopes & Modules
				["@type.definition"] = { fg = "#78c2d8", bold = true },
				["@type.builtin"] = { fg = colors.blue2 },
				["@variable.member"] = { fg = "#9cd4d0" }, -- Struct fields isolation
				["@variable.parameter"] = { fg = colors.yellow }, -- Parameters locked to yellow
				["@module"] = { fg = colors.blue1 },

				-- Builtins & Constants
				["@number.float"] = { fg = colors.magenta },
				["@constant.builtin"] = { fg = colors.magenta },
				["@function.builtin"] = { fg = colors.blue, bold = true }, -- append, len, make, etc.
			}

			for token, style in pairs(custom_scm_tokens) do
				highlights[token] = style
			end
		end,
	})

	-- Apply the configured palette variant
	vim.cmd.colorscheme("tokyonight-moon")
end

return M
