local M = {}

function M.setup()
	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup()
	require("dap-go").setup()

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
	vim.keymap.set("n", "<leader>dt", function()
		require("dap-go").debug_test()
	end, { desc = "DAP: Debug test (Go)" })
end

return M
