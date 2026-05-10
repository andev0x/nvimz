local M = {}

function M.setup()
	-- Enable native treesitter highlighting
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("native_treesitter", { clear = true }),
		desc = "Enable native Treesitter highlighting",
		callback = function(args)
			local bufnr = args.buf
			-- Avoid running on non-normal buffers or empty filetypes
			if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" then
				return
			end

			-- Check if a parser is available for the current buffer's filetype
			local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
			if ok and parser then
				vim.treesitter.start(bufnr)
			end
		end,
	})

	-- Native folding support via Treesitter
	vim.opt.foldmethod = "expr"
	vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	-- Ensure folds are open by default
	vim.opt.foldlevel = 99

	-- Handle potential filetype aliases
	vim.treesitter.language.add("javascript", { filetype = "js" })
	vim.treesitter.language.add("typescript", { filetype = "typescripts" })

	-- The user specifically requested support for:
	-- go, rust, python, typescript, markdown, cpp, java, javascript
	-- Note: Neovim 0.12 includes some parsers by default.
	-- Others must be installed to the runtime path (e.g., via OS package manager).
end

return M
