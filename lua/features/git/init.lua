local M = {}

function M.setup()
	require("mini.git").setup()
	vim.keymap.set({ "n", "x" }, "<leader>gs", "<cmd>Git<cr>", { desc = "Git status" })
	vim.keymap.set({ "n", "x" }, "<leader>gb", "<cmd>lua MiniGit.show_at_cursor()<cr>", { desc = "Git blame" })

	require("mini.diff").setup()
	vim.keymap.set("n", "<leader>gd", function()
		if MiniDiff.get_buf_data() == nil then
			MiniDiff.enable()
		end
		MiniDiff.toggle_overlay()
	end, { desc = "Toggle diff overlay" })
end

return M
