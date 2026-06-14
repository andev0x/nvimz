local M = {}

function M.setup()
	require("mini.icons").setup({
		style = "glyph",
		custom = {
			extension = {
				lua = { glyph = "󰢱", hl = "MiniIconsAzure" },
				md = { glyph = "󰍔", hl = "MiniIconsGreen" },
			},
			file = {
				[".gitignore"] = { glyph = "", hl = "MiniIconsOrange" },
			},
			directory = {
				folder = { glyph = "󰉋", hl = "MiniIconsBlue" },
			},
		},
	})

	-- Provide devicons API for plugins that expect nvim-web-devicons
	MiniIcons.mock_nvim_web_devicons()
end

return M
