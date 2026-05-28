local M = {}

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup()

	local function go_root()
		local file = vim.api.nvim_buf_get_name(0)
		local root = vim.fs.find({ "go.work", "go.mod" }, { path = file, upward = true })[1]
		if root then
			return vim.fs.dirname(root)
		end
		return vim.fn.getcwd()
	end

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

	local function has_go_parser(bufnr)
		local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
		return ok and parser ~= nil
	end

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

	vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
	vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: Continue" })
	vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP: Step into" })
	vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP: Step over" })
	vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "DAP: Step out" })
	vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP: Open REPL" })

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "go",
		group = vim.api.nvim_create_augroup("DapGoKeymaps", { clear = true }),
		callback = function(event)
			vim.keymap.set("n", "<leader>dt", function()
				if has_go_parser(event.buf) then
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
			end, { desc = "DAP: Debug test (Go)", buffer = event.buf })
		end,
	})
end

return M
