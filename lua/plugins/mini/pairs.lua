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

			-- Auto-close double quotes (Strings)
			['"'] = { action = "closeopen", close = '"', register = { cr = true } },

			-- Avoid auto-closing single quotes on Rust lifetimes (e.g., 'a)
			["'"] = {
				action = "closeopen",
				close = "'",
				register = { cr = true },
				neigh_pattern = "[^%a].",
			},

			-- Template literals for JS/TS/Go backticks
			["`"] = { action = "closeopen", close = "`", register = { cr = true } },
		},
	})
end

return M
