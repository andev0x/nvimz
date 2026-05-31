local M = {}

M.required = {
	"c",
	"cpp",
	"go",
	"rust",
	"python",
	"typescript",
	"tsx",
	"lua",
	"vim",
	"vimdoc",
	"gitcommit",
	"git_rebase",
	"diff",
	"markdown",
}

M.required_set = {}
for _, lang in ipairs(M.required) do
	M.required_set[lang] = true
end

return M
