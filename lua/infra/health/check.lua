local M = {}

function M.executable(bin)
	return vim.fn.executable(bin) == 1
end

function M.version(cmd)
	if not cmd then
		return nil
	end

	local result = vim.system(cmd, {
		text = true,
	}):wait()

	if result.code ~= 0 then
		return nil
	end

	local output = result.stdout:gsub("\n", "")

	return output ~= "" and output or nil
end

function M.inspect(tool)
	local installed = M.executable(tool.bin)

	return {
		name = tool.name,
		bin = tool.bin,
		required = tool.required,
		installed = installed,
		version = installed and M.version(tool.version) or nil,
	}
end

return M
