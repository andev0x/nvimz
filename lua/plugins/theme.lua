local M = {}

function M.setup()
	require("tokyonight").setup({
		style = "moon",
		transparent = true,
		terminal_colors = true,

		-- ---------------------------------------------------------------------
		-- Global syntax styling
		-- Philosophy:
		-- - Reduce visual noise
		-- - Emphasize reading flow over syntax taxonomy
		-- - Avoid excessive bold/saturation
		-- - Keep the editor calm during long coding sessions
		-- ---------------------------------------------------------------------
		styles = {
			comments = { italic = true },
			keywords = { italic = true },
			functions = {},
			variables = {},
			sidebars = "transparent",
			floats = "transparent",
		},

		on_highlights = function(highlights, colors)
			-- -----------------------------------------------------------------
			-- Palette tuning
			-- -----------------------------------------------------------------

			-- Neutral identifier color inspired by Helix/editor-style themes
			local identifier = "#9aa5ce"

			-- Dimmed syntax noise
			local noise = colors.comment

			-- Softer semantic accents
			local soft_blue = "#7aa2f7"
			local soft_purple = "#b4a1ff"
			local soft_yellow = "#d9b27c"
			local soft_orange = "#dca561"

			-- -----------------------------------------------------------------
			-- Core philosophy:
			-- Flatten most identifiers to reduce rainbow noise
			-- -----------------------------------------------------------------

			highlights["@variable"] = { fg = identifier }
			highlights["@variable.parameter"] = { fg = identifier }
			highlights["@variable.member"] = { fg = identifier }

			highlights["@property"] = { fg = identifier }
			highlights["@module"] = { fg = identifier }

			highlights["@lsp.type.variable"] = { fg = identifier }
			highlights["@lsp.type.parameter"] = { fg = identifier }
			highlights["@lsp.type.namespace"] = { fg = identifier }

			-- -----------------------------------------------------------------
			-- Reduce punctuation/operator attention
			-- -----------------------------------------------------------------

			highlights["@operator"] = { fg = noise }
			highlights["@punctuation.bracket"] = { fg = noise }
			highlights["@punctuation.delimiter"] = { fg = noise }

			highlights["@lsp.type.operator"] = { fg = noise }
			highlights["@lsp.type.punctuation"] = { fg = noise }

			-- -----------------------------------------------------------------
			-- Keywords:
			-- Keep structure readable without screaming for attention
			-- -----------------------------------------------------------------

			highlights["@keyword"] = {
				fg = soft_purple,
				italic = true,
			}

			-- -----------------------------------------------------------------
			-- Functions:
			-- Slight emphasis without bold
			-- -----------------------------------------------------------------

			highlights["@function"] = { fg = soft_blue }
			highlights["@function.call"] = { fg = soft_blue }

			highlights["@method"] = { fg = soft_blue }
			highlights["@method.call"] = { fg = soft_blue }

			-- -----------------------------------------------------------------
			-- Types:
			-- Warm but subtle to avoid overpowering the editor
			-- -----------------------------------------------------------------

			highlights["@type"] = { fg = soft_yellow }
			highlights["@type.builtin"] = { fg = soft_yellow }

			-- -----------------------------------------------------------------
			-- Builtins/constants:
			-- Slightly warmer for quick scanning
			-- -----------------------------------------------------------------

			highlights["@constant.builtin"] = {
				fg = soft_orange,
			}

			-- -----------------------------------------------------------------
			-- Comments:
			-- Atmospheric and low distraction
			-- -----------------------------------------------------------------

			highlights.Comment = {
				fg = "#66708a",
				italic = true,
			}

			-- -----------------------------------------------------------------
			-- Inlay hints:
			-- Minimal and soft instead of sticker-like blocks
			-- -----------------------------------------------------------------

			highlights.LspInlayHint = {
				fg = "#6a8f89",
				bg = "NONE",
				italic = true,
			}

			-- -----------------------------------------------------------------
			-- UI polish
			-- -----------------------------------------------------------------

			highlights.NonText = { fg = colors.dark3 }
			highlights.SpecialKey = { fg = colors.dark3 }

			-- Softer cursor line
			highlights.CursorLine = {
				bg = "#1a1d2a",
			}

			-- Cleaner split separator
			highlights.WinSeparator = {
				fg = "#24283b",
			}

			-- More subtle line numbers
			highlights.LineNr = {
				fg = "#414868",
			}

			highlights.CursorLineNr = {
				fg = "#7aa2f7",
			}

			-- Floating windows
			highlights.FloatBorder = {
				fg = "#3b4261",
				bg = "NONE",
			}

			-- Visual selection
			highlights.Visual = {
				bg = "#283457",
			}

			-- Matching parentheses
			highlights.MatchParen = {
				fg = colors.fg,
				bg = "#2b3254",
			}
		end,
	})

	vim.cmd.colorscheme("tokyonight-moon")
end

return M
