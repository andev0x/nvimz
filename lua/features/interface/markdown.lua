local M = {}

function M.setup()
	require("render-markdown").setup({
		-- Default configuration is usually sufficient, but we can be explicit
		-- based on user request: "markdown = rendered document, code block = syntax highlighted"
	})
end

return M
