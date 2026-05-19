local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",
		transparent = true, -- Enable transparency for the system blur effect
		terminal_colors = true,

		-- ---------------------------------------------------------------------
		-- Deep Forest Palette Overrides (Helix-Inspired Tuning)
		-- ---------------------------------------------------------------------
		on_colors = function(colors)
			-- Deep Emerald/Forest Backgrounds
			colors.bg = "#0b1210"
			colors.bg_dark = "#080d0b"
			colors.bg_float = "#0d1614"
			colors.bg_sidebar = "#080d0b"
			colors.bg_statusline = "#0d1614"
			colors.bg_visual = "#1a2b26"
			colors.bg_highlight = "#162420"

			-- Shift blues to precise Helix teals and vibrant functional blues
			colors.blue = "#72cce8" -- Vibrant Light Blue (Used for explicit Function Calls like stop/cancel)
			colors.blue1 = "#b4f9f8"
			colors.blue2 = "#00b4d8" -- Intense Teal for specialized methods
			colors.blue5 = "#89ddff"
			colors.blue6 = "#b4f9f8"
			colors.blue7 = "#394b70"

			-- Sharp green execution for structural control
			colors.magenta = "#a3e635" -- High-visibility Lime/Green for structural keywords
			colors.magenta2 = "#73daca"
			colors.purple = "#a3e635"

			-- Contrast accents
			colors.orange = "#ff9e64"
			colors.yellow = "#e0af68"
			colors.green = "#9ece6a" -- Core Emerald Green
			colors.teal = "#1abc9c"
		end,

		-- ---------------------------------------------------------------------
		-- Green-centric Syntax & UI
		-- ---------------------------------------------------------------------
		styles = {
			comments = { italic = true },
			keywords = { italic = true, bold = true },
			functions = { bold = true },
			variables = {},
			sidebars = "transparent",
			floats = "transparent",
		},

		on_highlights = function(highlights, colors)
			-- UI synchronization with green theme
			highlights.Visual = { bg = colors.bg_visual, bold = true }
			highlights.CursorLine = { bg = colors.bg_highlight }
			highlights.WinSeparator = { fg = colors.teal, bold = true }
			highlights.LineNr = { fg = "#3b423d" }
			highlights.CursorLineNr = { fg = colors.green, bold = true }

			-- High-contrast MatchParen
			highlights.MatchParen = { fg = colors.orange, bold = true, underline = true }

			-- LspInlayHint: Mossy/Subtle (Perfect contrast against dark forest)
			highlights.LspInlayHint = {
				fg = "#4e5e54",
				bg = "NONE",
				italic = true,
			}

			-- Dashboard/Startup synchronization (Emerald)
			highlights.NvimzLogo = { fg = colors.teal, bold = true }
			highlights.NvimzStats = { fg = colors.green, italic = true }

			-- -----------------------------------------------------------------
			-- Helix-Style Balanced Syntax Tuning
			-- -----------------------------------------------------------------
			-- Balancing the "Greens" to prevent flat text and maximize scan-speed
			highlights["@keyword"] = { fg = colors.green, italic = true, bold = true } -- Core keywords (package, import)
			highlights["@variable"] = { fg = "#78aec2" } -- Light Cyan/Silver for high-readability parameters (ctx, signals)
			highlights["@function"] = { fg = colors.blue, bold = true } -- Teal/Blue function architecture
			highlights["@string"] = { fg = "#86b38a" } -- Soft Sage Green for friendly, non-distracting strings
			highlights["@comment"] = { fg = "#5a6e68", italic = true } -- Perfect mossy tone for background documentation

			-- -----------------------------------------------------------------
			-- Neovim 0.12 Core Treesitter Extensions for Golang (Helix Match)
			-- -----------------------------------------------------------------
			-- Enforce strict color isolation for nested Go AST tokens
			local go_native_tokens = {
				["@function.call.go"] = { fg = colors.blue, bold = true }, -- e.g., stop(), cancel(), Println()
				["@function.method.go"] = { fg = colors.blue, bold = true }, -- Method architecture
				["@method.call.go"] = { fg = colors.blue, bold = true }, -- e.g., apiServer.Shutdown(), ctx.Done()
				["@keyword.function.go"] = { fg = colors.orange, bold = true }, -- 'func' gets a warm accent just like Helix!
				["@variable.member.go"] = { fg = "#b4f9f8" }, -- Struct properties get distinct light teal illumination
				["@type.go"] = { fg = "#2ac3de", bold = true }, -- Types like 'Context', 'CancelFunc' get structural blue
			}

			for token, style in pairs(go_native_tokens) do
				highlights[token] = style
			end
		end,
	})

	vim.cmd.colorscheme("tokyonight-moon")
end

return M
