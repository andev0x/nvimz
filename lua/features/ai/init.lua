local M = {}

-- Ensure Ollama is running before gp.nvim initializes.
local ollama_started = false
local function ensure_ollama_running()
	if ollama_started or vim.fn.executable("ollama") ~= 1 then
		return
	end

	vim.system({
		"sh",
		"-c",
		"curl -fs http://127.0.0.1:11434/api/tags >/dev/null",
	}, { text = true }, function(result)
		if result.code == 0 then
			return
		end

		ollama_started = true
		local ok, err = pcall(vim.uv.spawn, "ollama", {
			args = { "serve" },
			detached = true,
			stdio = { nil, nil, nil },
		}, function() end)

		if not ok then
			vim.schedule(function()
				vim.notify("[AI] Failed to start Ollama: " .. tostring(err), vim.log.levels.ERROR)
			end)
		end
	end)
end

-- Helper to create keymaps.
local function map(lhs, rhs, desc, mode)
	vim.keymap.set(mode or "n", lhs, rhs, { desc = desc, silent = true })
end

function M.setup()
	ensure_ollama_running()

	require("gp").setup({
		providers = {
			ollama = {
				endpoint = "http://127.0.0.1:11434/api/chat",
				disable_stream = true,
			},
		},
		agents = {
			{
				provider = "ollama",
				name = "Scout",
				chat = true,
				command = false,
				model = { model = "qwen2.5:7b" },
				system_prompt = [[
You are a fast technical thinking partner.

Core behavior:
1. Validate the user's premise BEFORE answering.
2. If the question contains flawed assumptions, correct them immediately.
3. Never compare two technologies as equivalents if they solve different problems.
4. Distinguish category, role, and abstraction level first.
5. Prefer correctness over pleasing agreement.

Response style:
- Keep answers short
- Prefer simple solutions
- Optimize for clarity
- Challenge wrong framing early
- ALWAYS respond in the SAME language as the user
- NEVER respond in Chinese
]],
			},
			{
				provider = "ollama",
				name = "Judge",
				chat = true,
				command = false,
				model = { model = "qwen3:8b" },
				system_prompt = [[
You are a senior technical decision-maker.

Core behavior:
1. Detect hidden assumptions.
2. Reject false equivalences.
3. Separate tools by primary purpose before comparing.
4. Analyze tradeoffs only after validating the framing.
5. Prioritize production reality over theoretical possibility.

Decision style:
- Challenge assumptions
- Analyze deeply
- Consider scale, failure modes, maintenance
- Be decisive
]],
			},
			{
				provider = "ollama",
				name = "Editor",
				chat = true,
				command = true,
				model = { model = "qwen2.5-coder:7b" },
				system_prompt = [[
You are a senior code editor.
- Make minimal, surgical changes
- Preserve APIs and behavior
- Avoid unrelated refactors
- Keep changes production‑safe
- Output only final code or diff
]],
			},
		},
		default_chat_agent = "Scout",
		default_command_agent = "Editor",
	})

	-- Copilot configuration
	require("copilot").setup({
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 120,
			keymap = {
				accept = "<M-S-right>",
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
		},
		panel = { enabled = false },
	})

	-- AI keymaps
	map("<leader>aa", "<cmd>GpChatToggle<cr>", "AI Toggle Chat")
	map("<leader>a1", function()
		vim.cmd("GpAgent Scout")
		vim.notify("AI → Scout")
	end, "AI Scout")
	map("<leader>a2", function()
		vim.cmd("GpAgent Judge")
		vim.notify("AI → Judge")
	end, "AI Judge")
	map("<leader>a3", function()
		vim.cmd("GpAgent Editor")
		vim.notify("AI → Editor")
	end, "AI Editor")
	map("<leader>at", "<cmd>Copilot toggle<cr>", "Copilot Toggle")
	map("<A-CR>", "<cmd>GpChatRespond<cr>", "AI Respond")
	map("<leader>ar", ":GpRewrite<space>", "AI Rewrite", "v")
	map("<leader>ap", ":GpAppend<space>", "AI Append", "v")
	map("<leader>ab", ":GpPrepend<space>", "AI Prepend", "v")
end

return M
