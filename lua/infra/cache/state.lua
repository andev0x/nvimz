local M = {}

M.cache_path = vim.fn.stdpath("state") .. "/nvimz_cache.json"
M.cache_data = nil

function M.load()
	if M.cache_data then
		return M.cache_data
	end

	if vim.fn.filereadable(M.cache_path) == 0 then
		M.cache_data = {}
		return M.cache_data
	end

	local f = io.open(M.cache_path, "r")
	if not f then
		M.cache_data = {}
		return M.cache_data
	end

	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		M.cache_data = {}
		return M.cache_data
	end

	M.cache_data = data
	return M.cache_data
end

function M.save()
	if not M.cache_data then
		return
	end

	local f = io.open(M.cache_path, "w")
	if not f then
		return
	end

	f:write(vim.json.encode(M.cache_data))
	f:close()
end

return M
