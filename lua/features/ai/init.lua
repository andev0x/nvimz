local M = {}

local gp_initialized = false
local copilot_initialized = false

-- Ensure Ollama is running before gp.nvim initializes. This runs only when AI
-- is explicitly activated, never during startup or a plain insert.
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

function M.setup_gp()
	if gp_initialized then
		return
	end

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

	gp_initialized = true
end

function M.setup_copilot()
	if copilot_initialized then
		return
	end

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

	copilot_initialized = true
end

return M
