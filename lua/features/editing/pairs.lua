local M = {}

function M.setup()
	require("mini.pairs").setup({
		modes = { insert = true, command = false, terminal = false },
		mappings = {
			["("] = { action = "open", close = ")", register = { cr = true } },
			["["] = { action = "open", close = "]", register = { cr = true } },
			["{"] = { action = "open", close = "}", register = { cr = true } },

			[")"] = { action = "close", close = ")", register = { cr = true } },
			["]"] = { action = "close", close = "]", register = { cr = true } },
			["}"] = { action = "close", close = "}", register = { cr = true } },

			['"'] = { action = "closeopen", close = '"', register = { cr = true } },
			["'"] = {
				action = "closeopen",
				close = "'",
				register = { cr = true },
				neigh_pattern = "[^%a].",
			},
			["`"] = { action = "closeopen", close = "`", register = { cr = true } },
		},
	})
end

return M
