-- lua/runtime/init.lua
require("runtime.bootstrap")
require("runtime.loader")
require("core")
require("runtime.phases").setup()

-- Register custom commands (e.g., :License)
require("runtime.events").setup()

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local interactive_session = #vim.api.nvim_list_uis() > 0
		local elapsed_ms = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6

		vim.schedule(function()
			local ok, cache = pcall(require, "infra.cache")
			if ok then
				local startup_stats = cache.get("startup_stats") or {}
				table.insert(startup_stats, {
					time = os.date("%Y-%m-%d %H:%M:%S"),
					elapsed_ms = elapsed_ms,
				})
				while #startup_stats > 10 do
					table.remove(startup_stats, 1)
				end
				cache.set("startup_stats", startup_stats)
			end
		end)

		vim.defer_fn(function()
			-- Re-enable filetype detection now that startup is complete.
			vim.g.did_load_filetypes = nil
			pcall(vim.cmd, "source $VIMRUNTIME/filetype.lua")
			pcall(vim.cmd, "doautocmd filetypedetect BufRead")
			-- Defer non-essential runtime plugins and shada I/O to the background.
			pcall(vim.cmd, "runtime! plugin/**/*.vim")
			vim.o.shada = "!,'100,<50,s10,h"
			pcall(vim.cmd, "rshada!")
		end, 0)

		if elapsed_ms > 10 then
			vim.schedule(function()
				vim.notify(("nvimz startup %.2fms exceeded 10ms target"):format(elapsed_ms), vim.log.levels.WARN)
			end)
		end

		if interactive_session then
			vim.schedule(function()
				pcall(function()
					require("features.interface.dashboard").setup()
				end)
			end)
		end
	end,
})