local M = {}

M.lsp_icons = {
	gopls = " ",
	pyright = " ",
	ts_ls = " ",
	rust_analyzer = " ",
	terraformls = "󱁢 ",
	yamlls = " ",
	lua_ls = " ",
}

M.lsp_servers = {
	gopls = {
		cmd = { "gopls" },
		filetypes = { "go", "gomod", "gowork", "gotmpl" },
		root_markers = { "go.work", "go.mod", ".git" },
	},
	pyright = {
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
		root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
	},
	ts_ls = {
		cmd = { "typescript-language-server", "--stdio" },
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	},
	rust_analyzer = {
		cmd = { "rust-analyzer" },
		filetypes = { "rust" },
		root_markers = { "Cargo.toml", "rust-toolchain", "rust-toolchain.toml", ".git" },
	},
	terraformls = {
		cmd = { "terraform-ls", "serve" },
		filetypes = { "terraform", "terraform-vars", "hcl" },
		root_markers = { ".terraform", ".git" },
	},
	yamlls = {
		cmd = { "yaml-language-server", "--stdio" },
		filetypes = { "yaml" },
		root_markers = { ".git" },
		settings = {
			yaml = {
				keyOrdering = false,
			},
		},
	},
}

M.formatters_by_ft = {
	lua = { "stylua" },
	python = { "black" },
	sh = { "shfmt" },
	bash = { "shfmt" },
	zsh = { "shfmt" },
	go = { "gofmt" },
	terraform = { "terraform_fmt" },
	["terraform-vars"] = { "terraform_fmt" },
}

M.formatter_binaries = {
	stylua = "stylua",
	black = "black",
	shfmt = "shfmt",
	gofmt = "gofmt",
	terraform_fmt = "terraform",
}

local function uniq(list)
	local out = {}
	local seen = {}
	for _, item in ipairs(list) do
		if not seen[item] then
			seen[item] = true
			table.insert(out, item)
		end
	end
	return out
end

function M.required_binaries()
	local bins = { "git", "rg", "fd" }

	for name, server in pairs(M.lsp_servers) do
		table.insert(bins, server.cmd[1])
	end

	for _, bin in pairs(M.formatter_binaries) do
		table.insert(bins, bin)
	end

	local out = uniq(bins)
	table.sort(out)
	return out
end

return M
