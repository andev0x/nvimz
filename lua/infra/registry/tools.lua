return {
	core = {
		{
			name = "git",
			bin = "git",
			version = { "git", "--version" },
			required = true,
		},

		{
			name = "rg",
			bin = "rg",
			version = { "rg", "--version" },
			required = true,
		},

		{
			name = "fd",
			bin = "fd",
			version = { "fd", "--version" },
			required = true,
		},
	},

	lsp = {
		{
			name = "gopls",
			bin = "gopls",
			version = { "gopls", "version" },
			required = false,
		},

		{
			name = "lua_ls",
			bin = "lua-language-server",
			version = { "lua-language-server", "--version" },
			required = false,
		},
	},

	formatters = {
		{
			name = "stylua",
			bin = "stylua",
			version = { "stylua", "--version" },
			required = false,
		},

		{
			name = "shfmt",
			bin = "shfmt",
			version = { "shfmt", "--version" },
			required = false,
		},
	},

	linters = {
		{
			name = "golangci-lint",
			bin = "golangci-lint",
			version = { "golangci-lint", "--version" },
			required = false,
		},
	},
}
