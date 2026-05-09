local M = {}

local spec = require("infra.spec")

-- Clean root pattern lookup with robust fallback to the file's current directory
local function get_root_dir(server_name, s_spec)
	local util = require("lspconfig.util")

	-- 1. Try to find root directory using defined markers (e.g., go.mod, .git)
	if s_spec and s_spec.root_markers and #s_spec.root_markers > 0 then
		local detected_root =
			util.root_pattern((table.unpack or unpack)(s_spec.root_markers))(vim.api.nvim_buf_get_name(0))
		if detected_root then
			return detected_root
		end
	end

	-- 2. Fallback to current buffer's directory so LSP ALWAYS activates, even for single files
	return util.path.dirname(vim.api.nvim_buf_get_name(0))
end

local function on_attach(_, bufnr)
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	-- Core Navigation & Actions (Safe from mini.pick conflicts)
	map("gd", vim.lsp.buf.definition, "LSP: go to definition")
	map("gD", vim.lsp.buf.declaration, "LSP: go to declaration")
	map("gr", vim.lsp.buf.references, "LSP: references")
	map("gi", vim.lsp.buf.implementation, "LSP: implementation")
	map("K", vim.lsp.buf.hover, "LSP: hover")
	map("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
	map("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")

	-- Diagnostics (FIXED: Remapped <leader>e to gl to completely resolve conflict with mini.files)
	map("gl", vim.diagnostic.open_float, "Diagnostics: float status")
	map("[d", vim.diagnostic.goto_prev, "Diagnostics: previous")
	map("]d", vim.diagnostic.goto_next, "Diagnostics: next")

	-- Optional: Auto-open diagnostics popup when holding cursor still
	local group = vim.api.nvim_create_augroup("LspDiagnosticsFloat", { clear = false })
	vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
	vim.api.nvim_create_autocmd("CursorHold", {
		group = group,
		buffer = bufnr,
		callback = function()
			vim.diagnostic.open_float({
				focus = false,
				scope = "cursor",
				close_events = { "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter" },
			})
		end,
	})
end

function M.setup()
	require("mason").setup()
	require("mason-lspconfig").setup({
		ensure_installed = { "gopls", "pyright", "ts_ls", "rust_analyzer" },
	})

	-- Improve cursor hold reaction time (Default is 4000ms which makes popups feel broken)
	vim.opt.updatetime = 300

	local servers = { "gopls", "pyright", "ts_ls", "rust_analyzer" }

	for _, server in ipairs(servers) do
		local config = {
			on_attach = on_attach,
		}

		-- Find matching spec settings
		local s_spec = nil
		for _, s in ipairs(spec.lsp_servers) do
			if s.name == server then
				s_spec = s
				break
			end
		end

		-- Apply configs if spec exists
		if s_spec then
			config.cmd = s_spec.cmd
			config.filetypes = s_spec.filetypes
			config.settings = s_spec.settings
		end

		-- FIX: Ensure root_dir is never nil so the server is forced to launch successfully
		config.root_dir = get_root_dir(server, s_spec)

		vim.lsp.config(server, config)
		vim.lsp.enable(server)
	end

	vim.diagnostic.config({
		virtual_text = false,
		severity_sort = true,
		underline = true,
		update_in_insert = false,
		float = { border = "rounded", source = "if_many" },
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = " ",
				[vim.diagnostic.severity.WARN] = " ",
				[vim.diagnostic.severity.HINT] = "󰠠 ",
				[vim.diagnostic.severity.INFO] = " ",
			},
		},
	})
end

return M
