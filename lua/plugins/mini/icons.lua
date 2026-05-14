local M = {}

function M.setup()
	-- We load and register mini.icons first. This automatically provides icons
	-- to mini.files, mini.pick, and mini.statusline.
	require("mini.icons").setup({
		-- Style: 'glyph' (standard) or 'ascii'
		style = "glyph",
		-- Customizing specific icons to fit Catppuccin Mocha palette or your preference
		custom = {
			-- Custom file extension icons
			extension = {
				lua = { glyph = "", hl = "MiniIconsAzure" },
				md = { glyph = "", hl = "MiniIconsGreen" },
			},
			-- Custom system/filetype icons
			file = {
				[".gitignore"] = { glyph = "", hl = "MiniIconsOrange" },
			},
			-- Custom directory icon (if you want to override the default folder icon)
			directory = {
				folder = { glyph = "󰉋", hl = "MiniIconsBlue" },
			},
		},
	})
	-- Mock mini.icons as 'nvim-web-devicons' so non-mini plugins can also use it
	MiniIcons.mock_nvim_web_devicons()
end

return M
