local M = {}

local spec = require("infra.spec")

function M.setup()
	local conform = require("conform")

	conform.setup({
		formatters_by_ft = spec.formatters_by_ft,
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
