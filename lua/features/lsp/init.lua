local M = {}

local initialized = false

local function setup_commands()
	local languages = require("infra.registry").languages
	local servers = require("features.lsp.servers")

	vim.api.nvim_create_user_command("LspInfo", function()
		local clients = vim.lsp.get_clients()
		if #clients == 0 then
			vim.notify("No active LSP clients", vim.log.levels.WARN)
			return
		end

		local lines = { "Active LSP Clients:" }
		for _, client in ipairs(clients) do
			table.insert(lines, string.format("- %s (id: %d, root: %s)", client.name, client.id, client.config.root_dir or "nil"))
			local attached_buffers = {}
			for bufnr, _ in pairs(client.attached_buffers) do table.insert(attached_buffers, bufnr) end
			table.insert(lines, string.format("  Attached buffers: %s", table.concat(attached_buffers, ", ")))
		end
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	end, { desc = "Show active LSP clients" })

	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd("tabnew | edit " .. vim.lsp.log.get_filename())
	end, { desc = "Open LSP log" })

	vim.api.nvim_create_user_command("LspStart", function(opts)
		local name = opts.args
		if name == "" then
			vim.notify("Usage: LspStart <server_name>", vim.log.levels.ERROR)
			return
		end
		if languages.lsp_servers[name] then
			servers.enable_server(name, languages.lsp_servers[name], 0)
		else
			vim.notify(string.format("LSP server '%s' not found in spec", name), vim.log.levels.ERROR)
		end
	end, {
		nargs = 1,
		desc = "Start LSP server",
		complete = function() return vim.tbl_keys(languages.lsp_servers) end,
	})

	vim.api.nvim_create_user_command("LspStop", function(opts)
		local name = opts.args
		if name == "" then
			vim.lsp.stop({ bufnr = 0, force = true })
			return
		end
		vim.lsp.stop({ name = name, force = true })
	end, {
		nargs = "?",
		desc = "Stop LSP server",
		complete = function()
			return vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients())
		end,
	})

	vim.api.nvim_create_user_command("LspRestart", function()
		vim.lsp.stop({ bufnr = 0, force = true })
		vim.defer_fn(function()
			local bufnr = vim.api.nvim_get_current_buf()
			local filetype = vim.bo[bufnr].filetype
			servers.start(filetype, bufnr)
		end, 500)
	end, { desc = "Restart LSP clients for current buffer" })
end

local function setup_ui_overrides()
	local orig_open_floating_preview = vim.lsp.util.open_floating_preview
	---@diagnostic disable-next-line: duplicate-set-field
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig_open_floating_preview(contents, syntax, opts, ...)
	end
end

function M.setup()
	if initialized then return end
	initialized = true

	setup_commands()
	setup_ui_overrides()
	require("features.lsp.diagnostics").setup()
	require("features.lsp.attach").setup()
end

function M.start(filetype, bufnr)
	require("features.lsp.servers").start(filetype, bufnr)
end

return M
