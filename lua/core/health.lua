local M = {}

local spec = require("infra.spec")

local function missing_binaries()
	local missing = {}
	for _, bin in ipairs(spec.required_binaries()) do
		if vim.fn.executable(bin) == 0 then
			table.insert(missing, bin)
		end
	end
	return missing
end

function M.check()
	local missing = missing_binaries()
	if #missing == 0 then
		return
	end

	error(table.concat({
		"Missing required system dependencies in PATH:",
		"  - " .. table.concat(missing, "\n  - "),
		"Install them with your OS package manager before starting Neovim.",
	}, "\n"))
end

function M.register_command()
	vim.api.nvim_create_user_command("ZenHealth", function()
		local missing = missing_binaries()
		if #missing == 0 then
			vim.notify("nvim-zen: all required dependencies are available", vim.log.levels.INFO)
			return
		end

		vim.notify("nvim-zen missing dependencies: " .. table.concat(missing, ", "), vim.log.levels.ERROR)
	end, { desc = "Show nvim-zen dependency health" })
end

return M
