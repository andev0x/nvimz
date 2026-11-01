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
		local interactive = #vim.api.nvim_list_uis() > 0
		local elapsed_ms = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6

		-- Load viminfo after the first render (deferred above).
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

		if interactive and elapsed_ms > 10 then
			vim.schedule(function()
				vim.notify(("nvimz startup %.2fms exceeded the 10ms target"):format(elapsed_ms), vim.log.levels.WARN)
			end)
		end

		if interactive then
			vim.schedule(function()
				local ok, err = pcall(function()
					require("features.interface.dashboard").setup()
				end)
				if not ok then
					vim.notify("[nvimz] dashboard failed:\n" .. tostring(err), vim.log.levels.ERROR)
				end
			end)
		end
	end,
})
