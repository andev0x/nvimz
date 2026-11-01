-- Core CLI prerequisites. Language servers and formatters are derived from
-- nvimz/config/languages.lua so there is only one source of truth.
local M = {}

M.core = {
	{ name = "git", bin = "git" },
	{ name = "rg", bin = "rg" },
	{ name = "fd", bin = "fd" },
}

return M
