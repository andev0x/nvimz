local M = {}

local ns = vim.api.nvim_create_namespace("comment_annotations")

-- ============================================================================
-- LSP Diagnostics
-- ============================================================================

function M.setup_diagnostics()
	vim.diagnostic.config({
		virtual_text = false,
		severity_sort = true,
		underline = true,
		update_in_insert = false,

		float = {
			border = "rounded",
			source = "if_many",
			header = "",
			prefix = "",
			focusable = true,
		},

		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "󰅚 ",
				[vim.diagnostic.severity.WARN] = "󰀪 ",
				[vim.diagnostic.severity.INFO] = "󰋽 ",
				[vim.diagnostic.severity.HINT] = "󰌶 ",
			},
		},
	})
end

-- ============================================================================
-- Comment Annotations (FIX, TODO, NOTE...)
-- ============================================================================

local annotations = {
	FIX = { icon = "󰁨 ", hl = "DiagnosticError" },
	BUG = { icon = "󰨰 ", hl = "DiagnosticError" },

	WARN = { icon = " ", hl = "DiagnosticWarn" },
	HACK = { icon = "󰡶 ", hl = "DiagnosticWarn" },

	NOTE = { icon = " ", hl = "DiagnosticInfo" },
	TEST = { icon = "󰙨 ", hl = "DiagnosticInfo" },

	TODO = { icon = "󰗡 ", hl = "DiagnosticHint" },
	PERF = { icon = "󰓅 ", hl = "DiagnosticHint" },
}

local function define_signs()
	for name, cfg in pairs(annotations) do
		vim.fn.sign_define("Comment" .. name, {
			text = cfg.icon,
			texthl = cfg.hl,
		})
	end
end

local function clear_annotations(bufnr)
	vim.fn.sign_unplace("comment_annotations", { buffer = bufnr })
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

local function scan_annotations(bufnr)
	bufnr = bufnr or 0
	clear_annotations(bufnr)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for lnum, line in ipairs(lines) do
		for keyword, cfg in pairs(annotations) do
			local start_col = line:find("%f[%w]" .. keyword .. "%f[%W]")

			if start_col then
				-- Sign column icon
				vim.fn.sign_place(0, "comment_annotations", "Comment" .. keyword, bufnr, { lnum = lnum })

				-- Highlight keyword via extmark
				vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, start_col - 1, {
					end_col = start_col - 1 + #keyword,
					hl_group = cfg.hl,
					priority = 200,
				})
			end
		end
	end
end

-- ============================================================================
-- Setup
-- ============================================================================

function M.setup()
	M.setup_diagnostics()
	define_signs()

	vim.api.nvim_create_autocmd({
		"BufEnter",
		"BufWritePost",
		"TextChanged",
		"InsertLeave",
	}, {
		callback = function(args)
			scan_annotations(args.buf)
		end,
	})
end

return M
