local M = {}

local initialized = false

local function go_root()
	local file = vim.api.nvim_buf_get_name(0)
	local root = vim.fs.find({ "go.work", "go.mod" }, { path = file, upward = true })[1]
	if root then
		return vim.fs.dirname(root)
	end
	return vim.fn.getcwd()
end

local function has_go_parser(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
	return ok and parser ~= nil
end

function M.setup()
	if initialized then
		return
	end

	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup()

	require("dap-go").setup({
		dap_configurations = {
			{
				type = "go",
				name = "Debug",
				request = "launch",
				program = "${file}",
				cwd = go_root,
			},
			{
				type = "go",
				name = "Debug test (file)",
				request = "launch",
				mode = "test",
				program = "${file}",
				cwd = go_root,
			},
			{
				type = "go",
				name = "Debug test (package)",
				request = "launch",
				mode = "test",
				program = "${fileDirname}",
				cwd = go_root,
			},
		},
	})

	vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
	vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
	vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })

	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end

	initialized = true
end

-- Invoked by the <leader>dt mapping after setup. Debugging a Go test is the
-- only action that needs the Treesitter parser check.
function M.debug_test()
	local dap = require("dap")
	local bufnr = vim.api.nvim_get_current_buf()

	if vim.bo[bufnr].filetype ~= "go" then
		vim.notify("Debug test (Go): current buffer is not Go", vim.log.levels.WARN)
		return
	end

	if has_go_parser(bufnr) then
		require("dap-go").debug_test()
		return
	end

	vim.notify(
		"Go Tree-sitter parser not found. Run :ParsersUpdate for better test selection. Falling back to package tests.",
		vim.log.levels.WARN
	)

	local config
	for _, candidate in ipairs(dap.configurations.go or {}) do
		if candidate.name == "Debug test (package)" then
			config = candidate
			break
		end
	end

	dap.run(vim.deepcopy(config or {
		type = "go",
		name = "Debug test (package)",
		request = "launch",
		mode = "test",
		program = "${fileDirname}",
		cwd = go_root,
	}))
end

return M
