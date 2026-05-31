local M = {}
local state = require("infra.cache.state")

function M.get(key)
	return state.load()[key]
end

function M.set(key, value)
	state.load()[key] = value
	state.save()
end

return M
