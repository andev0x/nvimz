local M = {}

M.lsp_icons = {
	gopls = " ",
	pyright = " ",
	ts_ls = " ",
	rust_analyzer = " ",
	terraformls = "󱁢 ",
	yamlls = " ",
	lua_ls = " ",
	copilot = " ",
}

M.lsp_servers = {
	gopls = {
		cmd = { "gopls" },
		filetypes = { "go", "gomod", "gowork", "gotmpl" },
		root_markers = { "go.work", "go.mod", ".git" },
		settings = {
			gopls = {
				semanticTokens = true,
				hints = {
					assignVariableTypes = true,
					compositeLiteralFields = true,
					compositeLiteralTypes = true,
					constantValues = true,
					functionTypeParameters = true,
					parameterNames = true,
					rangeVariableTypes = true,
				},
			},
		},
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
		settings = {
			javascript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
				},
			},
			typescript = {
				inlayHints = {
					includeInlayEnumMemberValueHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayVariableTypeHints = true,
				},
			},
		},
	},
	rust_analyzer = {
		cmd = { "rust-analyzer" },
		filetypes = { "rust" },
		root_markers = { "Cargo.toml", "rust-toolchain", "rust-toolchain.toml", ".git" },
		settings = {
			["rust-analyzer"] = {
				inlayHints = {
					bindingModeHints = { enable = false },
					chainingHints = { enable = true },
					closingBraceHints = { enable = true, minLines = 25 },
					closureReturnTypeHints = { enable = "never" },
					lifetimeElisionHints = { enable = "never", useParameterNames = false },
					maxLength = 25,
					parameterHints = { enable = true },
					reborrowHints = { enable = "never" },
					renderColons = true,
					typeHints = { enable = true, hideClosureInitialization = false, hideNamedTempTypes = false },
				},
			},
		},
	},
	lua_ls = {
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
		settings = {
			Lua = {
				hint = {
					enable = true,
					arrayIndex = "Disable",
					await = true,
					paramName = "All",
					paramType = true,
					semicolon = "Disable",
					setType = true,
				},
				workspace = {
					checkThirdParty = false,
					library = {
						vim.env.VIMRUNTIME,
					},
				},
				telemetry = { enable = false },
			},
		},
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
