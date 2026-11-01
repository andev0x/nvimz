local M = {}

local initialized = false

function M.setup()
	if initialized then
		return
	end

	require("mini.git").setup()

	require("mini.diff").setup({
		view = {
			style = "sign",
			signs = { add = "┃", change = "┊", delete = "-" },
		},
	})

	initialized = true
end

return M
