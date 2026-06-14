local M = {}

local function ensure_ollama_running()
	if vim.fn.executable("ollama") ~= 1 then
		return
	end

	local health_check = vim.fn.executable("nc") == 1 and { "nc", "-z", "127.0.0.1", "11434" } or { "sh", "-c", "command -v nc >/dev/null && nc -z 127.0.0.1 11434" }

	vim.system(health_check, { text = true }, function(result)
		if result.code ~= 0 then
			vim.uv.spawn("ollama", { args = { "serve" }, detached = true }, function() end)
		end
	end)
end

local function map_ai_key(lhs, rhs, description)
	vim.keymap.set({ "n", "v" }, lhs, rhs, { desc = description, silent = true })
end

function M.setup()
	ensure_ollama_running()

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

	map_ai_key("<leader>aa", "<cmd>GpChatNew<cr>", "AI Chat")
	map_ai_key("<leader>aq", "<cmd>GpChatToggle<cr>", "AI Toggle")
	map_ai_key("<leader>at", "<cmd>Copilot toggle<cr>", "AI Copilot Toggle")
	map_ai_key("<leader>a3", function()
		vim.cmd("GpAgent Ollama-3B")
		vim.notify("Switched to Ollama-3B")
	end, "AI 3B")
	map_ai_key("<leader>a7", function()
		vim.cmd("GpAgent Ollama-7B")
		vim.notify("Switched to Ollama-7B")
	end, "AI 7B")
	map_ai_key("<A-CR>", ":GpChatRespond<CR>", "AI Respond")
end

return M
