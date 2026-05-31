local M = {}

local function has_focusable_float()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" and config.focusable then
			return true
		end
	end
	return false
end

local function setup_diagnostic_float(bufnr)
	local group = vim.api.nvim_create_augroup("LspDiagnosticFloat_" .. bufnr, { clear = true })
	vim.api.nvim_create_autocmd("CursorHold", {
		group = group,
		buffer = bufnr,
		callback = function()
			if vim.api.nvim_get_mode().mode ~= "n" then return end
			if vim.fn.getcmdwintype() ~= "" then return end
			if has_focusable_float() then return end

			vim.diagnostic.open_float(nil, {
				focus = false,
				scope = "cursor",
				border = "rounded",
				close_events = {
					"CursorMoved",
					"CursorMovedI",
					"BufLeave",
					"InsertEnter",
				},
			})
		end,
	})
end

function M.setup()
	local lsp_group = vim.api.nvim_create_augroup("LspSetup", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", {
		group = lsp_group,
		callback = function(args)
			local bufnr = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if not client then return end

			require("features.lsp.keymaps").setup(bufnr)
			require("features.lsp.inlay").setup(client, bufnr)
			setup_diagnostic_float(bufnr)
		end,
	})
end

return M
