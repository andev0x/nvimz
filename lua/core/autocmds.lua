local group = vim.api.nvim_create_augroup("nvim_zen", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank({ timeout = 120 })
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	desc = "Equalize splits on window resize",
	command = "tabdo wincmd =",
})

-- ============================================================================
-- Large File Optimizer (Performance Boost for > 1.5MB files)
-- ============================================================================

local MAX_FILESIZE = 1.5 * 1024 * 1024 -- 1.5 MB threshold

vim.api.nvim_create_autocmd("BufReadPre", {
	group = group,
	desc = "Detect large files and disable buffer-local heavy features",
	callback = function(args)
		local path = vim.api.nvim_buf_get_name(args.buf)
		if path == "" then
			return
		end

		local ok, stats = pcall(vim.uv.fs_stat, path)
		if ok and stats and stats.size > MAX_FILESIZE then
			vim.b[args.buf].large_file = true

			-- Disable swap and undo file creation to prevent write lag
			vim.opt_local.swapfile = false
			vim.opt_local.undofile = false

			-- Disable regex syntax highlighting
			vim.opt_local.syntax = "off"

			-- Only notify if the file is the current active buffer (prevents mini.files preview spam)
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_get_current_buf() == args.buf then
					local size_mb = stats.size / (1024 * 1024)
					vim.notify(
						string.format("Large file detected (%.2f MB). Disabling Treesitter, LSP, Line numbers, and syntax highlighting.", size_mb),
						vim.log.levels.WARN,
						{ title = "Performance Guard" }
					)
				end
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = group,
	desc = "Disable UI features for large files when displayed in a window",
	callback = function(args)
		if vim.b[args.buf].large_file then
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.cursorline = false
			vim.opt_local.signcolumn = "no"
			vim.opt_local.foldmethod = "manual"
			pcall(vim.treesitter.stop, args.buf)
		end
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	desc = "Prevent LSP from attaching to large files",
	callback = function(args)
		if vim.b[args.buf].large_file then
			vim.schedule(function()
				pcall(vim.lsp.buf_detach_client, args.buf, args.data.client_id)
			end)
		end
	end,
})

-- ============================================================================
-- Neovim 0.12 FileType-Based Lazy-Start
-- ============================================================================

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Lazy-start language tools (LSP, formatters, etc.)",
	callback = function(args)
		local ft = args.match

		-- Skip special buffers, invalid filetypes, or large files
		if vim.bo[args.buf].buftype ~= "" or ft == "" or vim.b[args.buf].large_file then
			return
		end

		-- Silently call the startup command for the language
		-- This runs asynchronously in the background
		pcall(function()
			require("features.lsp").start(ft, args.buf)
		end)
	end,
})

