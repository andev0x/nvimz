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
	block = true, -- Crucial for Go syntax tree traversal
	method_spec = true, -- Handles interface methods in Go
	for_statement = true, -- Optional: tracks loop blocks
	if_statement = true, -- Optional: tracks conditional blocks
}

local function is_normal_buffer(bufnr)
	return vim.bo[bufnr].buftype == "" and vim.bo[bufnr].filetype ~= ""
end

local function get_scope_node(bufnr, winid)
local ft = vim.bo[bufnr].filetype
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
	if not ok or not parser then
		return nil
	end

	local cursor = vim.api.nvim_win_get_cursor(winid)
	local node = vim.treesitter.get_node({
		bufnr = bufnr,
		pos = { cursor[1] - 1, cursor[2] },
	})

	-- Traverse up the syntax tree to locate the enclosing code block or function
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

local function get_byte_col_from_visual_col(line_str, target_visual_col, tabstop)
	local current_visual_col = 0
	local current_byte_idx = 0
	local len = #line_str

	while current_byte_idx < len and current_visual_col < target_visual_col do
		local byte = string.byte(line_str, current_byte_idx + 1)
		if not byte then
			break
		end

		local char_len = 1
		if byte >= 0xc0 and byte <= 0xdf then
			char_len = 2
		elseif byte >= 0xe0 and byte <= 0xef then
			char_len = 3
		elseif byte >= 0xf0 and byte <= 0xf7 then
			char_len = 4
		end

		local char = string.sub(line_str, current_byte_idx + 1, current_byte_idx + char_len)
		if char == "\t" then
			current_visual_col = current_visual_col + tabstop - (current_visual_col % tabstop)
		else
			current_visual_col = current_visual_col + vim.fn.strdisplaywidth(char)
		end

		current_byte_idx = current_byte_idx + char_len
	end

	if current_visual_col == target_visual_col then
		return current_byte_idx
	end

	return -1
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
	local tabstop = vim.bo[bufnr].tabstop
	if not tabstop or tabstop <= 0 then
		tabstop = 8
	end

	-- Calculate exact visual indentation column based on the scope's start line
	local start_line_str = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
	local indent_str = start_line_str:match("^%s*") or ""
	local visual_col = 0
	local i = 1
	while i <= #indent_str do
		local byte = string.byte(indent_str, i)
		if byte == 9 then
			visual_col = visual_col + tabstop - (visual_col % tabstop)
			i = i + 1
		else
			local char_len = 1
			if byte >= 0xc0 and byte <= 0xdf then
				char_len = 2
			elseif byte >= 0xe0 and byte <= 0xef then
				char_len = 3
			elseif byte >= 0xf0 and byte <= 0xf7 then
				char_len = 4
			end
			local char = string.sub(indent_str, i, i + char_len - 1)
			visual_col = visual_col + vim.fn.strdisplaywidth(char)
			i = i + char_len
		end
	end

	clear(bufnr)

	-- Draw vertical line from the line below declaration up to the closing boundary row
	for row = start_row + 1, end_row do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local line_str = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

			-- Calculate visual display width of the line to compare with visual_col
			local line_display_width = 0
			local j = 1
			while j <= #line_str do
				local byte = string.byte(line_str, j)
				if not byte then
					break
				end
				if byte == 9 then
					line_display_width = line_display_width + tabstop - (line_display_width % tabstop)
					j = j + 1
				else
					local char_len = 1
					if byte >= 0xc0 and byte <= 0xdf then
						char_len = 2
					elseif byte >= 0xe0 and byte <= 0xef then
						char_len = 3
					elseif byte >= 0xf0 and byte <= 0xf7 then
						char_len = 4
					end
					local char = string.sub(line_str, j, j + char_len - 1)
					line_display_width = line_display_width + vim.fn.strdisplaywidth(char)
					j = j + char_len
				end
			end

			-- Only process non-empty lines
			if #line_str:gsub("%s", "") > 0 then
				if line_display_width < visual_col then
					-- Handle short lines (e.g., closing braces or short segments)
					-- Pad with spaces up to visual_col to keep the line vertically straight
					local padding = string.rep(" ", visual_col - line_display_width)
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, #line_str, {
						virt_text = { { padding .. "│", "ScopeLine" } },
						virt_text_pos = "eol",
						priority = 10,
					})
				else
					-- Fix: Safely convert visual column alignment into a precise byte index
					local safe_byte_col = get_byte_col_from_visual_col(line_str, visual_col, tabstop)

					-- Ensure byte calculation didn't overflow or hit text characters
					if safe_byte_col >= 0 and safe_byte_col < #line_str then
						local char = string.sub(line_str, safe_byte_col + 1, safe_byte_col + 1)
						if char == " " then
							vim.api.nvim_buf_set_extmark(bufnr, ns, row, safe_byte_col, {
								virt_text = { { "│", "ScopeLine" } },
								virt_text_pos = "overlay", -- Replaces exactly 1 whitespace character seamlessly
								priority = 10,
							})
						elseif char == "\t" then
							-- Replace the tab character with a guide line and padding spaces to prevent shifting
							local tab_width = tabstop - (visual_col % tabstop)
							vim.api.nvim_buf_set_extmark(bufnr, ns, row, safe_byte_col, {
								virt_text = { { "│" .. string.rep(" ", tab_width - 1), "ScopeLine" } },
								virt_text_pos = "overlay", -- Replaces the tab character seamlessly
								priority = 10,
							})
						end
					end
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
