local M = {}

local cache_path = vim.fn.stdpath("state") .. "/nvimz_cache.json"
local cache_data = nil

local function load_cache()
	if cache_data then
		return cache_data
	end

	if vim.fn.filereadable(cache_path) == 0 then
		cache_data = {}
		return cache_data
	end

	local f = io.open(cache_path, "r")
	if not f then
		cache_data = {}
		return cache_data
	end

	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		cache_data = {}
		return cache_data
	end

	cache_data = data
	return cache_data
end

local function save_cache()
	if not cache_data then
		return
	end

	local f = io.open(cache_path, "w")
	if not f then
		return
	end

	f:write(vim.json.encode(cache_data))
	f:close()
end

function M.get(key)
	return load_cache()[key]
end

function M.set(key, value)
	load_cache()[key] = value
	save_cache()
end

return M
