local M = {}

local spec = require("infra.spec")

local function verify_formatter_binaries()
	local missing = {}
	for formatter, bin in pairs(spec.formatter_binaries) do
		if vim.fn.executable(bin) == 0 then
			table.insert(missing, formatter .. "(" .. bin .. ")")
		end
	end

	if #missing > 0 then
		error("Missing formatter binaries in PATH: " .. table.concat(missing, ", "))
	end
end

function M.setup()
	verify_formatter_binaries()

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
