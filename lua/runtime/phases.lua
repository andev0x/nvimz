local M = {}

local plugins = require("nvimz.config.plugins")

local function has_ui()
	return #vim.api.nvim_list_uis() > 0
end

local function report(scope, err)
	vim.notify(("[nvimz] %s failed:\n%s"):format(scope, tostring(err)), vim.log.levels.ERROR)
end

local function add_plugins(specs)
	local ok, err = pcall(vim.pack.add, specs)
	if not ok then
		report("plugin installation", err)
		return false
	end
	return true
end

local function setup_module(module)
	local ok, err = pcall(function()
		require(module).setup()
	end)
	if not ok then
		report(module, err)
		return false
	end
	return true
end

-- Markdown rendering is for documents the user edits or opens, not for
-- plugin-owned Markdown floats (for example an LSP hover preview).
local function is_markdown_buffer(bufnr)
	return vim.bo[bufnr].filetype == "markdown" and vim.bo[bufnr].buftype == "" and vim.bo[bufnr].buflisted
end

local function has_markdown_buffer()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and is_markdown_buffer(bufnr) then
			return true
		end
	end
	return false
end

local function startup_is_directory()
	local name = vim.api.nvim_buf_get_name(0)
	if name ~= "" and vim.fn.isdirectory(name) == 1 then
		return true
	end

	local arg = vim.fn.argv(0, -1)
	return arg ~= "" and vim.fn.isdirectory(vim.fn.fnamemodify(arg, ":p")) == 1
end

local markdown_ready = false
local editing_ready = false
local scope_ready = false
local git_ready = false
local format_ready = false
local files_ready = false
local lsp_ready = false
local dap_ready = false
local gp_ready = false
local copilot_ready = false

-- Tier 3 activations. Each returns `ok, newly_initialized` and leaves the
-- feature retryable when setup fails.

function M.ensure_markdown()
	if markdown_ready then
		return true, false
	end
	markdown_ready = true

	-- Adding the plugin sources its plugin/ script, which calls setup() itself.
	if not add_plugins(plugins.markdown) then
		markdown_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_git()
	if git_ready then
		return true, false
	end
	git_ready = true

	if not setup_module("features.git") then
		git_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_format()
	if format_ready then
		return true, false
	end
	format_ready = true

	if not add_plugins(plugins.format) then
		format_ready = false
		return false, false
	end
	if not setup_module("features.format") then
		format_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_files()
	if files_ready then
		return true, false
	end
	files_ready = true

	if not add_plugins(plugins.oil) then
		files_ready = false
		return false, false
	end
	if not setup_module("features.editing.files") then
		files_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_lsp()
	if lsp_ready then
		return true, false
	end
	lsp_ready = true

	if not setup_module("features.lsp") then
		lsp_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_dap()
	if dap_ready then
		return true, false
	end
	dap_ready = true

	if not add_plugins(plugins.dap) then
		dap_ready = false
		return false, false
	end
	if not setup_module("features.dap") then
		dap_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_gp()
	if gp_ready then
		return true, false
	end
	gp_ready = true

	if not add_plugins(plugins.gp) then
		gp_ready = false
		return false, false
	end
	local ok, err = pcall(function()
		require("features.ai").setup_gp()
	end)
	if not ok then
		report("features.ai (gp)", err)
		gp_ready = false
		return false, false
	end
	return true, true
end

function M.ensure_copilot()
	if copilot_ready then
		return true, false
	end
	copilot_ready = true

	if not add_plugins(plugins.copilot) then
		copilot_ready = false
		return false, false
	end
	local ok, err = pcall(function()
		require("features.ai").setup_copilot()
	end)
	if not ok then
		report("features.ai (copilot)", err)
		copilot_ready = false
		return false, false
	end
	return true, true
end

local function ensure_editing()
	if editing_ready then
		return
	end
	editing_ready = true

	-- These are independent: a completion failure must not remove pairs.
	local pairs_ok = setup_module("features.editing.pairs")
	local completion_ok = setup_module("features.editing.completion")
	if not pairs_ok or not completion_ok then
		-- Keep the trigger active so the failed side can be retried on the next
		-- insert. Both modules are idempotent.
		editing_ready = false
	end
end

local function ensure_scope_line()
	if scope_ready then
		return
	end
	scope_ready = true
	if not setup_module("features.interface.scope_line") then
		scope_ready = false
	end
end

local function ensure_normal_editing()
	-- Git diff signs are the only normal-mode feature that should follow the
	-- first cursor movement. Formatting arms itself on the first write and Oil
	-- loads from its key, command, or a directory startup.
	M.ensure_git()
end

-- The dashboard places the cursor when it builds its buffer, which raises
-- CursorMoved during startup. Scope lines and diff signs are only meaningful in
-- a real editing buffer, so ignore special buffers and let the first movement
-- in an actual file trigger the chunk.
local function cursor_chunk_relevant()
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].buflisted and filetype ~= "" and filetype ~= "dashboard"
end

local function load_first_render()
	add_plugins(plugins.tier1)

	if has_ui() then
		setup_module("features.interface.theme")
		setup_module("features.interface.icons")
		setup_module("features.interface.statusline")
	end

	-- Treesitter is the only feature that must start on the first buffer to
	-- avoid a visible switch from native syntax to parsed highlighting.
	setup_module("nvimz.treesitter")

	if has_markdown_buffer() then
		M.ensure_markdown()
	end

	if has_ui() and vim.fn.argc() == 0 then
		setup_module("features.interface.dashboard")
	end

	if startup_is_directory() then
		M.ensure_files()
	end
end

local function replay(name, opts, percent_range)
	local prefix = ""
	if percent_range then
		prefix = opts.line1 .. "," .. opts.line2
	elseif opts.range and opts.range > 0 then
		prefix = opts.range == 1 and tostring(opts.line1) or (opts.line1 .. "," .. opts.line2)
	elseif opts.count and opts.count >= 0 then
		prefix = tostring(opts.count)
	end

	local bang = opts.bang and "!" or ""
	local args = opts.args ~= "" and (" " .. opts.args) or ""
	vim.cmd(prefix .. name .. bang .. args)
end

local function lazy_command(name, ensure, opts, percent_range)
	vim.api.nvim_create_user_command(name, function(args)
		local ok = ensure()
		if not ok then
			return
		end
		-- The real command was registered by the plugin during ensure(), so
		-- this re-dispatch runs the plugin implementation with its arguments.
		replay(name, args, percent_range)
	end, opts)
end

local function register_lazy_commands()
	lazy_command("Git", M.ensure_git, { bang = true, nargs = "+", desc = "Git status" })
	lazy_command("Oil", M.ensure_files, { nargs = "*", complete = "dir", count = true, desc = "Open Oil" })
	lazy_command("Copilot", M.ensure_copilot, { bang = true, nargs = "?", desc = "Copilot" })

	lazy_command("LspStart", M.ensure_lsp, { nargs = 1, desc = "Start LSP server" })
	lazy_command("LspStop", M.ensure_lsp, { nargs = "?", desc = "Stop LSP server" })

	lazy_command("DapSetLogLevel", M.ensure_dap, { nargs = 1, desc = "DAP: set log level" })
	lazy_command("DapNew", M.ensure_dap, { nargs = "*", desc = "DAP: start a new session" })
	lazy_command(
		"DapEval",
		M.ensure_dap,
		{ nargs = 0, range = "%", bang = true, bar = true, desc = "DAP: evaluate expression" },
		true
	)

	lazy_command("GpAgent", M.ensure_gp, { nargs = "*", range = true, desc = "AI: select agent" })
	lazy_command("GpRewrite", M.ensure_gp, { nargs = "*", range = true, desc = "AI: rewrite" })
	lazy_command("GpAppend", M.ensure_gp, { nargs = "*", range = true, desc = "AI: append" })
	lazy_command("GpPrepend", M.ensure_gp, { nargs = "*", range = true, desc = "AI: prepend" })
	lazy_command("GpImplement", M.ensure_gp, { nargs = "*", range = true, desc = "AI: implement" })

	-- Commands without arguments or ranges are resolved by CmdUndefined.
	vim.api.nvim_create_autocmd("CmdUndefined", {
		pattern = { "Dap*", "Gp*", "Lsp*" },
		callback = function(args)
			local ensure
			if args.match:match("^Dap") then
				ensure = M.ensure_dap
			elseif args.match:match("^Gp") then
				ensure = M.ensure_gp
			else
				ensure = M.ensure_lsp
			end
			if not ensure() then
				return
			end
			vim.cmd(args.match)
		end,
	})
end

local function arm_deferred_triggers()
	-- Editing essentials, at the moment they are first needed. The handlers
	-- stay registered: each ensure function is a cheap idempotent guard, and
	-- keeping it active lets a failed setup retry on the next event.
	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = ensure_editing,
	})

	-- Normal editing features become useful once the cursor has moved.
	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function()
			if scope_ready and git_ready then
				return
			end
			if not cursor_chunk_relevant() then
				return
			end
			ensure_scope_line()
			ensure_normal_editing()
		end,
	})

	-- Format-on-save must be armed before the first write. The setup registers
	-- its own BufWritePre handler, which will not run for this same event, so
	-- the first write is formatted explicitly. Later writes are left to
	-- conform's own handler.
	vim.api.nvim_create_autocmd("BufWritePre", {
		callback = function(args)
			local newly_armed = not format_ready
			local ok = M.ensure_format()
			if not ok or not newly_armed or vim.b[args.buf].large_file then
				return
			end
			local conform = package.loaded["conform"]
			if conform then
				pcall(conform.format, { bufnr = args.buf, timeout_ms = 400, lsp_format = "never" })
			end
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		callback = function(args)
			if is_markdown_buffer(args.buf) then
				M.ensure_markdown()
			end
		end,
	})
end

function M.setup()
	register_lazy_commands()

	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			-- Official cold core metric: init.lua -> VimEnter, before Tier 1.
			_G.nvimz_core_ms = _G.nvimz_start_time and ((vim.uv.hrtime() - _G.nvimz_start_time) / 1e6)
			load_first_render()
			arm_deferred_triggers()
		end,
	})
end

return M
