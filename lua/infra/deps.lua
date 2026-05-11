local M = {}

-- Normalize plugin specifications for vim.pack
local function normalize(spec)
	local source = type(spec) == "string" and spec or spec.source

	-- Expand GitHub shorthand into full URL
	if not (source:find("http", 1, true) or source:find("git@", 1, true)) then
		source = "https://github.com/" .. source
	end

	local final = type(spec) == "table" and vim.tbl_extend("force", {}, spec) or {}

	final.src = source
	final.source = nil

	return final
end

-- Batch plugin registration
local function add(specs)
	vim.pack.add(vim.tbl_map(normalize, specs))
end

-- Create helper commands only once
local function create_commands()
	if vim.g.pack_commands_created then
		return
	end

	vim.g.pack_commands_created = true

	vim.api.nvim_create_user_command("PackUpdate", function()
		vim.pack.update()
	end, {
		desc = "Update plugins",
	})

	vim.api.nvim_create_user_command("PackClean", function()
		local inactive = vim.iter(vim.pack.get())
			:filter(function(plugin)
				return not plugin.active
			end)
			:map(function(plugin)
				return plugin.spec.name or plugin.spec.src
			end)
			:totable()

		if #inactive > 0 then
			vim.notify("Removing:\n" .. table.concat(inactive, "\n"), vim.log.levels.INFO)

			vim.pack.del(inactive)
		else
			vim.notify("No inactive plugins found", vim.log.levels.INFO)
		end
	end, {
		desc = "Remove inactive plugins",
	})
end

function M.setup()
	-- Register user commands immediately
	create_commands()

	-- Defer plugin loading to keep startup extremely fast.
	-- This prioritizes perceived responsiveness over eager initialization.
	vim.schedule(function()
		add({
			{ source = "neovim/nvim-lspconfig" },

			{ source = "catppuccin/nvim", name = "catppuccin" },

			{ source = "echasnovski/mini.nvim" },

			{ source = "mfussenegger/nvim-dap" },
			{ source = "nvim-neotest/nvim-nio" },
			{ source = "rcarriga/nvim-dap-ui" },
			{ source = "leoluz/nvim-dap-go" },

			{ source = "Robitx/gp.nvim" },

			{ source = "stevearc/conform.nvim" },
		})

		require("infra.lsp").setup()
		require("plugins.theme").setup()
		require("plugins.mini").setup()
		require("plugins.dap").setup()
		require("plugins.ai").setup()
		require("plugins.format").setup()
	end)
end

return M
