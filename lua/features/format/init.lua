local M = {}

local initialized = false

local languages = require("nvimz.config.languages")

function M.setup()
	if initialized then
		return
	end

	local conform = require("conform")

	conform.setup({
		formatters_by_ft = languages.formatters_by_ft,
		format_on_save = function(bufnr)
			if vim.b[bufnr].large_file then
				return
			end
			return { timeout_ms = 400, lsp_format = "never" }
		end,
	})

	initialized = true
end

return M
