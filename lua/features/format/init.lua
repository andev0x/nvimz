local M = {}

local languages = require("infra.registry").languages

function M.setup()
	local conform = require("conform")

	conform.setup({
		formatters_by_ft = languages.formatters_by_ft,
		format_on_save = {
			timeout_ms = 400,
			lsp_format = "never",
		},
	})

	vim.keymap.set("n", "<leader>fm", function()
		conform.format({ async = false, lsp_format = "never", timeout_ms = 400 })
	end, { desc = "Format buffer", silent = true })
end

return M
