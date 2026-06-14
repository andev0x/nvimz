local group = vim.api.nvim_create_augroup("nvim_zen", { clear = true })
local LARGE_FILE_BYTES = 1.5 * 1024 * 1024

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

-- Disable expensive buffer features for large files.
vim.api.nvim_create_autocmd("BufReadPre", {
	group = group,
	desc = "Detect large files and disable buffer-local heavy features",
	callback = function(args)
		local filepath = vim.api.nvim_buf_get_name(args.buf)
		if filepath == "" then
			return
		end

		local ok, file_stats = pcall(vim.uv.fs_stat, filepath)
		if ok and file_stats and file_stats.size > LARGE_FILE_BYTES then
			vim.b[args.buf].large_file = true

			vim.opt_local.swapfile = false
			vim.opt_local.undofile = false
			vim.opt_local.syntax = "off"

			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(args.buf) and vim.api.nvim_get_current_buf() == args.buf then
					local size_mb = file_stats.size / (1024 * 1024)
					vim.notify(
						string.format("Large file detected (%.2f MB). Disabling Treesitter, LSP, line numbers, and syntax highlighting.", size_mb),
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

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Lazy-start language tools (LSP, formatters, etc.)",
	callback = function(args)
		local filetype = args.match

		if vim.bo[args.buf].buftype ~= "" or filetype == "" or vim.b[args.buf].large_file then
			return
		end

		pcall(function()
			require("features.lsp").start(filetype, args.buf)
		end)
	end,
})
