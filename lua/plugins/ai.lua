local M = {}

function M.setup()
	-- Auto start Ollama if not running
	if vim.fn.executable("ollama") == 1 then
		local handle = vim.uv.spawn("nc", { args = { "-z", "127.0.0.1", "11434" } }, function(code)
			if code ~= 0 then
				vim.uv.spawn("ollama", { args = { "serve" }, detached = true }, function() end)
			end
		end)
	end

	require("gp").setup({
		providers = {
			openai = {
				endpoint = "http://127.0.0.1:11434/v1/chat/completions",
				secret = "ollama",
			},
		},
		agents = {
			{
				provider = "openai",
				name = "Ollama-3B",
				chat = true,
				command = true,
				model = { model = "qwen2.5-coder:3b" },
				system_prompt = "You are a fast and concise coding assistant. Prefer short and efficient responses.",
			},
			{
				provider = "openai",
				name = "Ollama-7B",
				chat = true,
				command = true,
				model = { model = "qwen2.5-coder:7b" },
				system_prompt = "You are an expert senior software engineer. Provide deep reasoning and production-grade implementations.",
			},
		},
		default_chat_agent = "Ollama-3B",
		default_command_agent = "Ollama-3B",
	})

	local map = function(lhs, rhs, desc)
		vim.keymap.set({ "n", "v" }, lhs, rhs, { desc = desc, silent = true })
	end

	map("<leader>aa", "<cmd>GpChatNew<cr>", "AI Chat")
	map("<leader>aq", "<cmd>GpChatToggle<cr>", "AI Toggle")
	map("<leader>a3", function()
		vim.cmd("GpAgent Ollama-3B")
		vim.notify("Switched to Ollama-3B")
	end, "AI 3B")
	map("<leader>a7", function()
		vim.cmd("GpAgent Ollama-7B")
		vim.notify("Switched to Ollama-7B")
	end, "AI 7B")
end

return M
