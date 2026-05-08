local M = {}

function M.setup()
	local configs = require("nvim-treesitter.configs")

	configs.setup({
		-- A list of parser names, or "all"
		ensure_installed = {
			"lua",
			"vim",
			"vimdoc",
			"query",
			"go",
			"python",
			"rust",
			"terraform",
			"yaml",
			"bash",
			"json",
			"typescript",
			"javascript",
			"markdown",
			"markdown_inline",
		},

		-- Install parsers synchronously (only applied to `ensure_installed`)
		sync_install = false,

		-- Automatically install missing parsers when entering buffer
		auto_install = true,

		highlight = {
			enable = true,
			-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
			-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
			-- Using this option may slow down your editor, and you may see some duplicate highlights.
			-- Instead of true it can also be a list of languages
			additional_vim_regex_highlighting = false,
		},

		indent = {
			enable = true,
		},

		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<c-space>",
				node_incremental = "<c-space>",
				scope_incremental = "<c-s>",
				node_decremental = "<M-space>",
			},
		},
	})
end

return M
