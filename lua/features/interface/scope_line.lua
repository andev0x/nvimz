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

-- Walk a string accumulating its display width. When `target_col` is given the
-- scan stops as soon as that visual column is reached, which is what the guide
-- placement needs; pass `nil` to measure the whole string (used for indents).
--
-- Returns `width` and, when `target_col` is reachable, the 0-based byte index
-- whose visual column equals it (-1 otherwise, e.g. a tab overshoots the
-- column). ASCII and tabs are handled inline so the common case avoids a
-- `vim.fn.strdisplaywidth` FFI call per character, which made this O(chars)
-- hot path the slowest part of cursor movement.
local function scan_line(line_str, target_col, tabstop)
	local width = 0
	local i = 1
	local len = #line_str

	while i <= len and (target_col == nil or width < target_col) do
		local byte = string.byte(line_str, i)

		if byte == 9 then
			width = width + tabstop - (width % tabstop)
			i = i + 1
		elseif byte < 0x80 then
			width = width + 1
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
			width = width + vim.fn.strdisplaywidth(string.sub(line_str, i, i + char_len - 1))
			i = i + char_len
		end
	end

	if target_col ~= nil and width == target_col then
		return width, i - 1
	end

	return width, -1
end

local function draw_scope_line(bufnr, start_row, end_row, visual_col, tabstop)
	clear(bufnr)

	-- Draw vertical line from the line below declaration up to the closing boundary row
	for row = start_row + 1, end_row do
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local line_str = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

		-- Only process non-empty lines
		if #line_str:gsub("%s", "") > 0 then
			-- `width` equals the full line width when the line is shorter than
			-- the guide column, otherwise it is capped at `visual_col`:
			-- either way it is only used for the short-line test below.
			local width, byte = scan_line(line_str, visual_col, tabstop)

			if width < visual_col then
				-- Handle short lines (e.g., closing braces) by padding up to
				-- visual_col so the guide stays vertically straight.
				local padding = string.rep(" ", visual_col - width)
				vim.api.nvim_buf_set_extmark(bufnr, ns, row, #line_str, {
					virt_text = { { padding .. "│", "ScopeLine" } },
					virt_text_pos = "eol",
					priority = 10,
				})
			elseif byte >= 0 and byte < #line_str then
				-- Safely convert visual column alignment into a byte index
				local char = string.sub(line_str, byte + 1, byte + 1)
				if char == " " then
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, byte, {
						virt_text = { { "│", "ScopeLine" } },
						virt_text_pos = "overlay", -- Replaces exactly 1 whitespace character seamlessly
						priority = 10,
					})
				elseif char == "\t" then
					-- Replace the tab character with a guide line and padding spaces to prevent shifting
					local tab_width = tabstop - (visual_col % tabstop)
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, byte, {
						virt_text = { { "│" .. string.rep(" ", tab_width - 1), "ScopeLine" } },
						virt_text_pos = "overlay", -- Replaces the tab character seamlessly
						priority = 10,
					})
				end
			end
		end
	end
end

-- The last rendered scope. Re-rendering is skipped while this signature is
-- unchanged, so moving the cursor *within* a scope costs a single treesitter
-- node lookup instead of a full buffer-block rescan.
local last_render = nil
local redraw_pending = false

local function invalidate()
	last_render = nil
end

local function render(bufnr, winid)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
		invalidate()
		return
	end

	if not is_normal_buffer(bufnr) then
		if last_render and last_render.bufnr == bufnr then
			clear(bufnr)
			invalidate()
		end
		return
	end

	local node = get_scope_node(bufnr, winid)
	if not node then
		if last_render and last_render.bufnr == bufnr then
			clear(bufnr)
			invalidate()
		end
		return
	end

	local start_row, _, end_row, _ = node:range()

	local tabstop = vim.bo[bufnr].tabstop
	if not tabstop or tabstop <= 0 then
		tabstop = 8
	end

	local signature =
		string.format("%d:%d:%d:%d:%d", winid, start_row, end_row, tabstop, vim.api.nvim_buf_get_changedtick(bufnr))

	if last_render and last_render.bufnr == bufnr and last_render.signature == signature then
		return
	end

	-- Calculate exact visual indentation column based on the scope's start line
	local start_line_str = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
	local indent_str = start_line_str:match("^%s*") or ""
	local visual_col = scan_line(indent_str, nil, tabstop)

	draw_scope_line(bufnr, start_row, end_row, visual_col, tabstop)
	last_render = { bufnr = bufnr, signature = signature }
end

-- Coalesce the frequent CursorMoved/CursorMovedI bursts into one redraw per
-- event-loop tick so keystrokes are never blocked by scope rendering.
local function schedule_render()
	if redraw_pending then
		return
	end
	redraw_pending = true
	vim.schedule(function()
		redraw_pending = false
		local winid = vim.api.nvim_get_current_win()
		render(vim.api.nvim_win_get_buf(winid), winid)
	end)
end

function M.setup()
	-- Integrates seamlessly with your Deep Forest / NonText subdued tones
	vim.api.nvim_set_hl(0, "ScopeLine", { link = "NonText" })

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter", "BufEnter" }, {
		group = group,
		desc = "Render Treesitter scope line dynamically",
		callback = schedule_render,
	})

	vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
		group = group,
		desc = "Clear active Treesitter scope line on context exit",
		callback = function(args)
			clear(args.buf)
			invalidate()
		end,
	})
end

return M
