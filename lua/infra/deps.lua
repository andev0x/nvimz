local M = {}

function M.setup()
	local add = function(spec)
		local s = type(spec) == "string" and spec or spec.source
		if not (s:find("http") or s:find("git@")) then
			s = "https://github.com/" .. s
		end

		local final_spec = type(spec) == "table" and vim.deepcopy(spec) or { src = s }
		final_spec.src = s
		final_spec.source = nil

		vim.pack.add({ final_spec })
	end

	-- Use vim.schedule to defer plugin loading and setup,
	-- keeping the initial startup time below the 20ms target.
	vim.schedule(function()
		add({ source = "neovim/nvim-lspconfig" })
		require("infra.lsp").setup()

		add({ source = "catppuccin/nvim", name = "catppuccin" })
		require("plugins.theme").setup()

		add({ source = "echasnovski/mini.nvim" })
		require("plugins.mini").setup()

		add({ source = "mfussenegger/nvim-dap" })
		add({ source = "nvim-neotest/nvim-nio" })
		add({ source = "rcarriga/nvim-dap-ui" })
		add({ source = "leoluz/nvim-dap-go" })
		require("plugins.dap").setup()

		add({ source = "Robitx/gp.nvim" })
		require("plugins.ai").setup()

		add({ source = "stevearc/conform.nvim" })
		require("plugins.format").setup()

		-- Register helper commands for plugin management
		vim.api.nvim_create_user_command("PackUpdate", function()
			vim.pack.update()
		end, { desc = "Update plugins" })

		vim.api.nvim_create_user_command("PackClean", function()
			local plugins = vim.iter(vim.pack.get())
				:filter(function(x) return not x.active end)
				:map(function(x) return x.spec.name end)
				:totable()
			if #plugins > 0 then
				print("Removing: " .. table.concat(plugins, ", "))
				vim.pack.del(plugins)
			else
				print("No inactive plugins to remove")
			end
		end, { desc = "Remove inactive plugins" })
	end)
end

return M
