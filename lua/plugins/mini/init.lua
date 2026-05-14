local M = {}

function M.setup()
	-- Setup all mini modules in the correct order
	-- (mini.icons must be first so other modules can inherit it)

	require("plugins.mini.icons").setup()
	require("plugins.mini.files").setup()
	require("plugins.mini.pairs").setup()
	require("plugins.mini.pick").setup()
	require("plugins.mini.git").setup()
	require("plugins.mini.statusline").setup()
	require("plugins.mini.completion").setup()
end

return M
