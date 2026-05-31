local M = {}

function M.setup()
	-- Auto start Ollama if not running
	if vim.fn.executable("ollama") == 1 then
		local check_cmd = { "nc", "-z", "127.0.0.1", "11434" }
		if vim.fn.executable("nc") ~= 1 then
			check_cmd = { "sh", "-c", "command -v nc >/dev/null && nc -z 127.0.0.1 11434" }
		end

		vim.system(check_cmd, { text = true }, function(result)
			if result.code ~= 0 then
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

	require("copilot").setup({
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 75,
			keymap = {
				accept = "<M-S-right>",
				accept_word = false,
				accept_line = false,
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
		},
		panel = { enabled = false },
	})

	local map = function(lhs, rhs, desc)
		vim.keymap.set({ "n", "v" }, lhs, rhs, { desc = desc, silent = true })
	end

	map("<leader>aa", "<cmd>GpChatNew<cr>", "AI Chat")
	map("<leader>aq", "<cmd>GpChatToggle<cr>", "AI Toggle")
	map("<leader>at", "<cmd>Copilot toggle<cr>", "AI Copilot Toggle")
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
