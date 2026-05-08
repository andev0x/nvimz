local M = {}

function M.setup()
	require("gen").setup({
		model = "qwen2.5-coder:7b",
		display_mode = "float",
		show_prompt = true,
		show_model = true,
		no_auto_close = false,
		init = function()
			pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
		end,
		command = "curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body",
	})

	vim.keymap.set({ "n", "v" }, "<leader>a", ":Gen<cr>", { desc = "AI (Gen)", silent = true })
end

return M
