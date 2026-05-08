local M = {}

function M.track(start_ns)
	vim.api.nvim_create_autocmd("VimEnter", {
		once = true,
		callback = function()
			local elapsed_ms = (vim.uv.hrtime() - start_ns) / 1e6
			if elapsed_ms > 20 then
				vim.schedule(function()
					vim.notify(
						("nvim-zen startup %.2fms exceeded 20ms target"):format(elapsed_ms),
						vim.log.levels.WARN
					)
				end)
			end
		end,
	})
end

return M
