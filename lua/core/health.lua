local M = {}

local tools = require("infra.tools")

local check = require("infra.health.check")
local render = require("infra.health.render")

local function iterate(category)
	for _, tool in ipairs(category) do
		render.tool(check.inspect(tool))
	end
end

function M.check()
	local missing = {}

	for _, tool in ipairs(tools.core) do
		if tool.required and not check.executable(tool.bin) then
			table.insert(missing, tool.bin)
		end
	end

	if #missing == 0 then
		return
	end

	error(table.concat({
		"Missing critical dependencies:",
		"  - " .. table.concat(missing, "\n  - "),
	}, "\n"))
end

function M.register_command()
	vim.api.nvim_create_user_command("ToolDoctor", function()
		render.section("Core")
		iterate(tools.core)

		render.section("LSP")
		iterate(tools.lsp)

		render.section("Formatters")
		iterate(tools.formatters)

		render.section("Linters")
		iterate(tools.linters)
	end, {
		desc = "Show environment tooling health",
	})
end

return M
