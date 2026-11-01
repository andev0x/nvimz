if vim.fn.has("nvim-0.12") == 0 then
	error("nvimz requires Neovim 0.12 or newer")
end

-- Reading viminfo is deferred past the first render; restore the original value
-- and load it once at VimEnter.
local shada = vim.o.shada
vim.o.shada = ""

vim.loader.enable()

require("core")
require("runtime.phases").setup()

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.defer_fn(function()
			vim.o.shada = shada
			local ok, err = pcall(vim.cmd, "rshada!")
			if not ok then
				-- A missing shada file is normal on the first run; report only
				-- failures that leave an existing file unreadable.
				local message = tostring(err)
				local missing = message:match("E886") and message:lower():match("no such file")
				if not missing then
					vim.notify("[nvimz] failed to read viminfo:\n" .. message, vim.log.levels.WARN)
				end
			end
		end, 0)
	end,
})
