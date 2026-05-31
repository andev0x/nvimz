local M = {}

function M.run()
	local inactive = vim.iter(vim.pack.get())
		:filter(function(plugin) return not plugin.active end)
		:map(function(plugin) return plugin.spec.name or plugin.spec.src end)
		:totable()

	if #inactive > 0 then
		print("Removing inactive plugins:\n" .. table.concat(inactive, "\n"))
		vim.pack.del(inactive)
	else
		print("No inactive plugins found.")
	end

	local cache_path = vim.fn.stdpath("state") .. "/nvimz_cache.json"
	if vim.fn.filereadable(cache_path) == 1 then
		vim.fn.delete(cache_path)
		print("Cleared state cache file.")
	end

	local parser_dir = vim.fn.expand("~/.local/share/nvim/site/parser")
	local valid_parsers = {
		c = true, cpp = true, go = true, rust = true, python = true,
		typescript = true, tsx = true, lua = true, vim = true, vimdoc = true,
		gitcommit = true, markdown = true,
	}
	if vim.fn.isdirectory(parser_dir) == 1 then
		local files = vim.fn.globpath(parser_dir, "*.so", true, true)
		for _, file in ipairs(files) do
			local lang = vim.fn.fnamemodify(file, ":t:r")
			local ok, _ = pcall(vim.treesitter.language.inspect, lang)
			if not valid_parsers[lang] or not ok then
				vim.fn.delete(file)
				print("Removed invalid/orphaned parser binary: " .. file)
			end
		end
	end

	local snapshot_dir = vim.fn.stdpath("config") .. "/snapshots"
	if vim.fn.isdirectory(snapshot_dir) == 1 then
		local snapshots = vim.fn.globpath(snapshot_dir, "snapshot_*.json", true, true)
		table.sort(snapshots)
		if #snapshots > 5 then
			for i = 1, #snapshots - 5 do
				vim.fn.delete(snapshots[i])
				print("Removed old snapshot: " .. snapshots[i])
			end
		end
	end
	print("󰄬 PackClean complete.")
end

return M
