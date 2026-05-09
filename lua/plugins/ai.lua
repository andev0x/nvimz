local M = {}

function M.setup()
	local MiniDeps = require("mini.deps")

	MiniDeps.add({
		source = "Robitx/gp.nvim",
	})

	-- Auto start Ollama
	local handle = io.popen("nc -z 127.0.0.1 11434 >/dev/null 2>&1; echo $?")

	if handle then
		local result = handle:read("*a")
		handle:close()

		local exit_code = result:match("^%s*(%d+)")

		if exit_code ~= "0" then
			pcall(io.popen, "ollama serve >/dev/null 2>&1 &")
		end
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

				model = {
					model = "qwen2.5-coder:3b",
				},

				system_prompt = [[
You are a fast and concise coding assistant.
Prefer short and efficient responses.
]],
			},

			{
				provider = "openai",
				name = "Ollama-7B",

				chat = true,
				command = true,

				model = {
					model = "qwen2.5-coder:7b",
				},

				system_prompt = [[
You are an expert senior software engineer.
Provide deep reasoning, architecture guidance,
and production-grade implementations.
]],
			},
		},

		-- Default lightweight model
		default_chat_agent = "Ollama-3B",
		default_command_agent = "Ollama-3B",
	})

	-- Chat
	vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>GpChatNew<cr>", {
		desc = "AI Chat",
		silent = true,
	})

	vim.keymap.set({ "n", "v" }, "<leader>aq", "<cmd>GpChatToggle<cr>", {
		desc = "AI Toggle",
		silent = true,
	})

	-- Switch to 3B
	vim.keymap.set("n", "<leader>a3", function()
		vim.cmd("GpAgent Ollama-3B")
		print("Switched to Ollama-3B")
	end, {
		desc = "AI 3B",
		silent = true,
	})

	-- Switch to 7B
	vim.keymap.set("n", "<leader>a7", function()
		vim.cmd("GpAgent Ollama-7B")
		print("Switched to Ollama-7B")
	end, {
		desc = "AI 7B",
		silent = true,
	})
end

return M
