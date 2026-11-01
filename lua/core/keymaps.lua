local set = vim.keymap.set

-- Core operations
set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer", silent = true })
set("n", "<leader>qq", "<cmd>quit<cr>", { desc = "Quit window", silent = true })
set("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight", silent = true })

set("n", "<leader>ds", function()
	require("features.interface.dashboard").open()
end, { desc = "Open dashboard", silent = true })

-- Buffer management
set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer", silent = true })
set("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer", silent = true })
set("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Previous buffer", silent = true })

-- Clipboard path extraction
set("n", "<leader>cp", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify("Copied relative path: " .. path)
end, { desc = "Copy relative path", silent = true })

set("n", "<leader>cP", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Copied absolute path: " .. path)
end, { desc = "Copy absolute path", silent = true })

set("n", "<leader>cn", function()
	local name = vim.fn.expand("%:t")
	vim.fn.setreg("+", name)
	vim.notify("Copied filename: " .. name)
end, { desc = "Copy filename", silent = true })

set("n", "<leader>cd", function()
	local dir = vim.fn.expand("%:h")
	vim.fn.setreg("+", dir)
	vim.notify("Copied directory path: " .. dir)
end, { desc = "Copy directory path", silent = true })

-- Window management
set("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical", silent = true })
set("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal", silent = true })
set("n", "<leader>se", "<C-w>=", { desc = "Equalize splits", silent = true })

set("n", "<leader>rh", "<cmd>vertical resize -2<CR>", { desc = "Resize left" })
set("n", "<leader>rl", "<cmd>vertical resize +2<CR>", { desc = "Resize right" })
set("n", "<leader>rj", "<cmd>resize -2<CR>", { desc = "Resize down" })
set("n", "<leader>rk", "<cmd>resize +2<CR>", { desc = "Resize up" })

set("n", "<C-h>", "<C-w>h", { desc = "Go to left window", silent = true })
set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", silent = true })
set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", silent = true })
set("n", "<C-l>", "<C-w>l", { desc = "Go to right window", silent = true })

set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center", silent = true })
set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center", silent = true })

-- Line movement
set("n", "<leader>mj", "<cmd>m .+1<cr>==", { desc = "Move line down", silent = true })
set("n", "<leader>mk", "<cmd>m .-2<cr>==", { desc = "Move line up", silent = true })
set("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down", silent = true })
set("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up", silent = true })

set({ "n", "v" }, "<leader>z", "za", { desc = "Toggle fold", silent = true })

-- Terminals
set("n", "<leader>tt", function()
	require("features.editing.terminal").toggle()
end, { desc = "Toggle floating terminal", silent = true })
set("n", "<leader>tb", function()
	require("features.editing.terminal").toggle_bottom()
end, { desc = "Toggle bottom terminal", silent = true })
set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

set("n", "<leader>uh", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "LSP: toggle inlay hints", silent = true })

-- ---------------------------------------------------------------------------
-- Lazy feature entry points
--
-- These mappings exist from the first keypress. Each first invocation loads
-- its feature through runtime/phases.lua and then performs the action; later
-- invocations are a guard check plus the action.
-- ---------------------------------------------------------------------------

local function phases()
	return require("runtime.phases")
end

local function picker()
	return require("nvimz.picker.native")
end

-- Picker
set("n", "<leader>ff", function()
	picker().files()
end, { desc = "Find files" })
set("n", "<leader>fe", function()
	picker().files_hidden()
end, { desc = "Find files (hidden)" })
set("n", "<leader>fg", function()
	picker().grep()
end, { desc = "Live grep" })
set("n", "<leader>fr", function()
	picker().grep_hidden()
end, { desc = "Grep hidden (gitignored)" })
set("n", "<leader>fb", function()
	picker().buffers()
end, { desc = "Buffers" })

-- Git
set({ "n", "x" }, "<leader>gs", function()
	if not phases().ensure_git() then
		return
	end
	vim.cmd("Git status")
end, { desc = "Git status" })

set({ "n", "x" }, "<leader>gb", function()
	if not phases().ensure_git() then
		return
	end
	MiniGit.show_at_cursor()
end, { desc = "Git blame" })

set("n", "<leader>gd", function()
	if not phases().ensure_git() then
		return
	end
	if MiniDiff.get_buf_data() == nil then
		MiniDiff.enable()
	end
	MiniDiff.toggle_overlay()
end, { desc = "Toggle diff overlay" })

-- File explorer
set("n", "<leader>e", function()
	if not phases().ensure_files() then
		return
	end
	if vim.bo.filetype == "oil" then
		require("oil").close()
	else
		require("oil").open_float()
	end
end, { desc = "Toggle Oil (rounded left float)" })

-- Formatting
set("n", "<leader>fm", function()
	if not phases().ensure_format() then
		return
	end
	local conform = package.loaded["conform"]
	if conform then
		conform.format({ async = false, lsp_format = "never", timeout_ms = 400 })
	end
end, { desc = "Format buffer", silent = true })

-- Debugging
local function with_dap(action)
	if not phases().ensure_dap() then
		return
	end
	action()
end

set("n", "<leader>db", function()
	with_dap(function()
		require("dap").toggle_breakpoint()
	end)
end, { desc = "DAP: Toggle breakpoint" })

set("n", "<leader>dc", function()
	with_dap(function()
		require("dap").continue()
	end)
end, { desc = "DAP: Continue" })

set("n", "<leader>di", function()
	with_dap(function()
		require("dap").step_into()
	end)
end, { desc = "DAP: Step into" })

set("n", "<leader>do", function()
	with_dap(function()
		require("dap").step_over()
	end)
end, { desc = "DAP: Step over" })

set("n", "<leader>du", function()
	with_dap(function()
		require("dap").step_out()
	end)
end, { desc = "DAP: Step out" })

set("n", "<leader>dr", function()
	with_dap(function()
		require("dap").repl.open()
	end)
end, { desc = "DAP: Open REPL" })

set("n", "<leader>dt", function()
	with_dap(function()
		require("features.dap").debug_test()
	end)
end, { desc = "DAP: Debug test (Go)" })

-- AI
local function with_gp(action)
	if not phases().ensure_gp() then
		return
	end
	action()
end

set("n", "<leader>aa", function()
	with_gp(function()
		vim.cmd("GpChatToggle")
	end)
end, { desc = "AI Toggle Chat" })

set("n", "<leader>a1", function()
	with_gp(function()
		vim.cmd("GpAgent Scout")
		vim.notify("AI → Scout")
	end)
end, { desc = "AI Scout" })

set("n", "<leader>a2", function()
	with_gp(function()
		vim.cmd("GpAgent Judge")
		vim.notify("AI → Judge")
	end)
end, { desc = "AI Judge" })

set("n", "<leader>a3", function()
	with_gp(function()
		vim.cmd("GpAgent Editor")
		vim.notify("AI → Editor")
	end)
end, { desc = "AI Editor" })

set("n", "<leader>at", function()
	local ok, newly_initialized = phases().ensure_copilot()
	if not ok then
		return
	end
	if newly_initialized then
		vim.notify("Copilot enabled")
		return
	end
	vim.cmd("Copilot toggle")
end, { desc = "Copilot Toggle" })

set("n", "<A-CR>", function()
	with_gp(function()
		vim.cmd("GpChatRespond")
	end)
end, { desc = "AI Respond" })

-- Visual AI commands keep the command line open for additional arguments.
local function gp_command(command)
	return function()
		if not phases().ensure_gp() then
			return ""
		end
		return ":" .. command .. " "
	end
end

set("v", "<leader>ar", gp_command("GpRewrite"), { expr = true, desc = "AI Rewrite" })
set("v", "<leader>ap", gp_command("GpAppend"), { expr = true, desc = "AI Append" })
set("v", "<leader>ab", gp_command("GpPrepend"), { expr = true, desc = "AI Prepend" })
