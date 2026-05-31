local M = {}

local languages = require("infra.registry").languages

local capabilities = vim.lsp.protocol.make_client_capabilities()
local enabled_servers = {}

function M.enable_server(name, s_spec, bufnr)
	local cmd = s_spec.cmd or {}

	-- Skip setup if executable does not exist
	if cmd[1] and vim.fn.executable(cmd[1]) ~= 1 then
		if enabled_servers[name] ~= "missing" then
			enabled_servers[name] = "missing"

			vim.notify(string.format("LSP server '%s' not found: %s", name, cmd[1]), vim.log.levels.WARN)
		end

		return
	end

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local root_dir = nil

	-- Try project root markers first
	if s_spec.root_markers and #s_spec.root_markers > 0 then
		root_dir = vim.fs.root(bufnr, s_spec.root_markers)
	end

	-- Fallback to file directory or current working directory
	if not root_dir then
		root_dir = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
	end

	vim.lsp.start({
		name = name,
		cmd = s_spec.cmd,
		root_dir = root_dir,
		settings = s_spec.settings,
		capabilities = capabilities,
	}, {
		bufnr = bufnr,
	})

	enabled_servers[name] = true
end

function M.start(filetype, bufnr)
	-- Ensure global LSP state is initialized (commands, diagnostics, etc.)
	require("features.lsp").setup()

	for name, s_spec in pairs(languages.lsp_servers) do
		if s_spec.filetypes and vim.tbl_contains(s_spec.filetypes, filetype) then
			M.enable_server(name, s_spec, bufnr)
		end
	end
end

return M
