require("runtime.bootstrap")
require("runtime.loader")

-- Load core modules
require("core")

-- Setup plugin phases
require("runtime.phases").setup()

-- Startup profiler / tracker & dashboard setup
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local is_headless = #vim.api.nvim_list_uis() == 0
		local elapsed_ms = (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6

		-- Cache startup stats (run asynchronously to avoid blocking first render/input)
		vim.schedule(function()
			local ok, cache = pcall(require, "infra.cache")
			if ok then
				local stats = cache.get("startup_stats") or {}
				table.insert(stats, {
					time = os.date("%Y-%m-%d %H:%M:%S"),
					elapsed_ms = elapsed_ms,
				})
				-- Keep only last 10 entries
				while #stats > 10 do
					table.remove(stats, 1)
				end
				cache.set("startup_stats", stats)
			end
		end)

		if elapsed_ms > 20 then
			vim.schedule(function()
				vim.notify(("nvimz startup %.2fms exceeded 20ms target"):format(elapsed_ms), vim.log.levels.WARN)
			end)
		end

		-- Setup dashboard (Only if not headless)
		if not is_headless then
			pcall(function()
				require("features.interface.dashboard").setup()
			end)
		end
	end,
})
