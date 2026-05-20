local M = {}

local ns = vim.api.nvim_create_namespace("scope_line")
local group = vim.api.nvim_create_augroup("scope_line", { clear = true })

-- Supported Treesitter node types for code scopes
local scope_nodes = {
	function_declaration = true,
	function_definition = true,
	["function"] = true,
	method_declaration = true,
	method_definition = true,
	arrow_function = true,
	lambda_expression = true,
}

local function is_normal_buffer(bufnr)
	return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype ~= ""
end

local function get_scope_node(bufnr, winid)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return nil
	end

	local cursor = vim.api.nvim_win_get_cursor(winid)
	local node = vim.treesitter.get_node({
		bufnr = bufnr,
		pos = { cursor[1] - 1, cursor[2] },
	})

	-- Traverse up the syntax tree to locate the enclosing function block
	while node do
		if scope_nodes[node:type()] then
			return node
		end
		node = node:parent()
	end

	return nil
end

local function clear(bufnr)
	if vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

local function draw_scope_line(bufnr, winid)
	if not is_normal_buffer(bufnr) then
		clear(bufnr)
		return
	end

	local node = get_scope_node(bufnr, winid)
	if not node then
		clear(bufnr)
		return
	end

	local start_row, _, end_row, _ = node:range()

	-- Calculate exact visual indentation column based on the function's start line
	local start_line_str = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
	local _, indent_bytes = start_line_str:find("^%s*")
	local visual_col = indent_bytes or 0

	clear(bufnr)

	-- Draw vertical line from the line below declaration up to the closing brace row
	for row = start_row + 1, end_row do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local line_str = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

			-- Only process non-empty lines
			if #line_str:gsub("%s", "") > 0 then
				if #line_str < visual_col then
					-- Handle short lines (e.g., closing braces or short segments)
					-- Pad with spaces up to visual_col to keep the line vertically straight
					local padding = string.rep(" ", visual_col - #line_str)
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, #line_str, {
						virt_text = { { padding .. "│", "ScopeLine" } },
						virt_text_pos = "eol",
						priority = 10,
					})
				else
					-- Handle regular lines: use "inline" to push text rightwards instead of overlaying
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, visual_col, {
						virt_text = { { "│", "ScopeLine" } },
						virt_text_pos = "inline",
						priority = 10,
					})
				end
			end
		end
	end
end

function M.setup()
	-- Integrates seamlessly with your Deep Forest / NonText subdued tones
	vim.api.nvim_set_hl(0, "ScopeLine", { link = "NonText" })

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter", "BufEnter" }, {
		group = group,
		desc = "Render Treesitter scope line dynamically",
		callback = function(args)
			local winid = vim.api.nvim_get_current_win()
			draw_scope_line(args.buf, winid)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = group,
		desc = "Clear active Treesitter scope line on context exit",
		callback = function(args)
			clear(args.buf)
		end,
	})
end

return M
