local M = {}

local languages = require("nvimz.config.languages")
local parsers = require("nvimz.config.parsers")
local tools = require("nvimz.config.tools")

local function installed(bin)
	return vim.fn.executable(bin) == 1
end

local function config_path()
	return vim.fn.stdpath("config")
end

local function check_core(h)
	h.start("nvimz: core tools")
	for _, tool in ipairs(tools.core) do
		if installed(tool.bin) then
			h.ok(("%s: %s"):format(tool.name, tool.bin))
		else
			h.error(("%s: executable '%s' not found"):format(tool.name, tool.bin), {
				"Install " .. tool.name .. " and add it to your PATH.",
			})
		end
	end
end

local function check_servers(h)
	h.start("nvimz: language servers (optional)")
	local names = vim.tbl_keys(languages.lsp_servers)
	table.sort(names)

	for _, name in ipairs(names) do
		local spec = languages.lsp_servers[name]
		local bin = spec.cmd and spec.cmd[1]
		if bin and installed(bin) then
			h.ok(("%s: %s"):format(name, bin))
		else
			h.warn(("%s: '%s' not found"):format(name, bin or "?"), {
				"nvimz does not install servers. Install it, or remove the entry from lua/nvimz/config/languages.lua.",
			})
		end
	end
end

local function check_formatters(h)
	h.start("nvimz: formatters (optional)")
	local seen = {}

	for _, names in vim.spairs(languages.formatters_by_ft) do
		for _, formatter in ipairs(names) do
			if not seen[formatter] then
				seen[formatter] = true
				local bin = languages.formatter_binaries[formatter] or formatter
				if installed(bin) then
					h.ok(("%s: %s"):format(formatter, bin))
				else
					h.warn(("%s: executable '%s' not found"):format(formatter, bin), {
						"Install it, or remove the filetype entry from lua/nvimz/config/languages.lua.",
					})
				end
			end
		end
	end
end

local function check_parsers(h)
	h.start("nvimz: Treesitter parsers")
	local missing = {}
	for _, lang in ipairs(parsers.required) do
		if not pcall(vim.treesitter.language.inspect, lang) then
			missing[#missing + 1] = lang
		end
	end

	if #missing == 0 then
		h.ok(("%d required parsers available"):format(#parsers.required))
	else
		h.error(("missing or invalid parsers: %s"):format(table.concat(missing, ", ")), {
			"Run :ParsersUpdate (requires a C compiler and git).",
		})
	end
end

local function check_plugins(h)
	h.start("nvimz: plugins")
	local plugins = vim.pack.get(nil, { info = false })
	local active, pending = 0, {}

	for _, plugin in ipairs(plugins) do
		if plugin.active then
			active = active + 1
		else
			pending[#pending + 1] = plugin.spec.name
		end
	end

	local lockfile = config_path() .. "/nvim-pack-lock.json"
	if vim.fn.filereadable(lockfile) == 1 then
		h.ok("lockfile: " .. lockfile)
	else
		h.error("lockfile missing: " .. lockfile, { "Start Neovim once so vim.pack can write it." })
	end

	h.info(("%d managed, %d active in this session"):format(#plugins, active))
	if #pending > 0 then
		table.sort(pending)
		h.info("not active (lazy phase or undeclared): " .. table.concat(pending, ", "))
	end
end

local function check_machine(h)
	h.start("nvimz: machine configuration")
	local local_config = config_path() .. "/lua/machine/local.lua"
	if vim.fn.filereadable(local_config) == 1 then
		h.info("machine/local.lua: present")
	else
		h.info("machine/local.lua: not present (optional)")
	end

	local prog = vim.g.python3_host_prog
	if type(prog) == "string" and prog ~= "" then
		h.info("python3_host_prog: " .. prog)
	else
		h.info("python3_host_prog: default (managed by Neovim)")
	end
end

function M.check()
	local h = vim.health

	h.start("nvimz")
	h.ok("Neovim " .. tostring(vim.version()))
	h.info("startup target: < 10 ms")

	check_core(h)
	check_servers(h)
	check_formatters(h)
	check_parsers(h)
	check_plugins(h)
	check_machine(h)
end

return M
