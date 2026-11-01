local M = {}

local plugins_config = require("nvimz.config.plugins")
local parsers = require("nvimz.config.parsers")
local tools = require("nvimz.config.tools")
local ui = require("nvimz.ui")

local function default_name(src)
	local name = src:match("([^/\\]+)$") or src
	return (name:gsub("%.git$", ""))
end

local function declared_names()
	local names = {}
	for _, phase in ipairs({ plugins_config.phase1, plugins_config.phase2, plugins_config.phase3 }) do
		for _, spec in ipairs(phase) do
			names[spec.name or default_name(spec.src)] = true
		end
	end
	return names
end

local function sorted(list)
	table.sort(list)
	return table.concat(list, ", ")
end

function M.status()
	local declared = declared_names()
	local active, lazy, orphan = {}, {}, {}

	for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
		local name = plugin.spec.name
		if plugin.active then
			active[#active + 1] = name
		elseif declared[name] then
			lazy[#lazy + 1] = name
		else
			orphan[#orphan + 1] = name
		end
	end

	local missing_tools = {}
	for _, tool in ipairs(tools.core) do
		if vim.fn.executable(tool.bin) ~= 1 then
			missing_tools[#missing_tools + 1] = tool.name
		end
	end

	local lockfile = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local lines = {
		"# PackStatus",
		"",
		"- Neovim: " .. tostring(vim.version()),
		"- Managed plugins: " .. (#active + #lazy + #orphan),
		"- Active in this session: " .. (#active > 0 and sorted(active) or "none"),
		"- Not active (lazy phase): " .. (#lazy > 0 and sorted(lazy) or "none"),
		"- Undeclared: " .. (#orphan > 0 and sorted(orphan) or "none"),
		"- Lockfile: " .. (vim.fn.filereadable(lockfile) == 1 and "present" or "MISSING"),
		"- Core tools missing: " .. (#missing_tools > 0 and sorted(missing_tools) or "none"),
		"",
		"Use `:checkhealth nvimz` for full diagnostics and `:checkhealth vim.pack` for packaging.",
	}

	ui.show("PackStatus", lines)
end

local function prune_parsers()
	local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
	if vim.fn.isdirectory(parser_dir) == 0 then
		return {}
	end

	local removed = {}
	for _, file in ipairs(vim.fn.globpath(parser_dir, "*.so", true, true)) do
		local lang = vim.fn.fnamemodify(file, ":t:r")
		-- Only delete parsers that are not required and cannot be loaded;
		-- valid extra parsers installed by the user are left alone.
		if not parsers.required_set[lang] and not pcall(vim.treesitter.language.inspect, lang) then
			vim.fn.delete(file)
			removed[#removed + 1] = lang
		end
	end
	return removed
end

function M.clean()
	local declared = declared_names()
	local orphan = {}

	for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
		if not plugin.active and not declared[plugin.spec.name] then
			orphan[#orphan + 1] = plugin.spec.name
		end
	end

	if #orphan > 0 then
		table.sort(orphan)
		vim.pack.del(orphan)
		vim.notify("Removed undeclared plugins: " .. table.concat(orphan, ", "), vim.log.levels.INFO)
	else
		vim.notify("No undeclared plugins found.", vim.log.levels.INFO)
	end

	local removed = prune_parsers()
	if #removed > 0 then
		vim.notify("Removed broken parser binaries: " .. table.concat(removed, ", "), vim.log.levels.INFO)
	else
		vim.notify("No broken parser binaries found.", vim.log.levels.INFO)
	end
end

return M
