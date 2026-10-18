local M = {}

local state = nil
local ns = vim.api.nvim_create_namespace("nvimz_picker")
local hl_ns = vim.api.nvim_create_namespace("nvimz_picker_hl")

local file_cache = {
	normal = nil,
	hidden = nil,
}

local function close_picker()
	local s = state
	if not s then
		return
	end
	state = nil
	pcall(vim.cmd, "stopinsert")
	if s._job then
		pcall(function()
			s._job:kill(9)
		end)
	end
	if s._timer then
		pcall(function()
			s._timer:stop()
			s._timer:close()
		end)
	end
	if s._augroup then
		pcall(vim.api.nvim_del_augroup_by_id, s._augroup)
	end
	for _, win in ipairs({ s.input_win, s.results_win, s.preview_win }) do
		if win and vim.api.nvim_win_is_valid(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
	for _, buf in ipairs({ s.input_buf, s.results_buf, s.preview_buf }) do
		if buf and vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end
end

local function parse_location(item)
	local file, lnum, col = item:match("^(.-):(%d+):(%d+):")
	if not file then
		file, lnum = item:match("^(.-):(%d+):")
		col = "1"
	end
	return file, lnum, col
end

--- Strip ANSI escape sequences, control chars and normalize tabs.
--- Prevents "blue block" artifacts from colored/tabbed tool output.
local function sanitize_line(s)
	if not s or s == "" then
		return ""
	end
	-- strip ANSI CSI sequences: ESC [ ... letter
	s = s:gsub("\27%[[0-9;?]*[A-Za-z]", "")
	-- strip ANSI OSC sequences: ESC ] ... BEL / ESC \
	s = s:gsub("\27%][^\7\27]*(\7|\27\\)", "")
	-- strip any remaining ESC + single char
	s = s:gsub("\27.", "")
	s = s:gsub("\r", "")
	s = s:gsub("\t", "  ")
	-- strip other C0 controls (keep nothing unprintable here; lines are already split)
	s = s:gsub("[%z\1-\8\11\12\14-\31]", "")
	return s
end

local function truncate_str(str, max)
	if max <= 0 then
		return ""
	end
	if vim.fn.strdisplaywidth(str) <= max then
		return str
	end
	if max <= 3 then
		return vim.fn.strcharpart(str, 0, max)
	end
	return vim.fn.strcharpart(str, 0, max - 3) .. "..."
end

local function shorten_path(path, max)
	if vim.fn.strdisplaywidth(path) <= max then
		return path
	end
	local sep = "/"
	local parts = vim.split(path, sep, { plain = true })
	if #parts <= 2 then
		return truncate_str(path, max)
	end
	local first = parts[1]
	local last = parts[#parts]
	local mid = first .. sep .. "..." .. sep .. last
	if vim.fn.strdisplaywidth(mid) <= max then
		return mid
	end
	local avail = max - vim.fn.strdisplaywidth(first) - 5
	if avail < 4 then
		return truncate_str(path, max)
	end
	return first .. sep .. "..." .. sep .. truncate_str(last, avail)
end

local function fd_cmd(hidden)
	local cmd = { "fd", "--type", "f", "--exclude", ".git" }
	if hidden then
		table.insert(cmd, 2, "--hidden")
	end
	return cmd
end

local function rg_cmd(query, hidden)
	local cmd = { "rg", "--vimgrep", "--smart-case", "--color=never", "--no-heading" }
	if hidden then
		vim.list_extend(cmd, { "--hidden", "--no-ignore-vcs", "--glob", "!.git" })
	end
	vim.list_extend(cmd, { "--", query })
	return cmd
end

local function filter_files(files, query)
	if query == "" then
		return files
	end
	return vim.fn.matchfuzzy(files, query)
end

local function preview_for(item)
	if not item or item == "" then
		return { "No preview" }, nil
	end
	local file, lnum = parse_location(item)
	if not file then
		file = item
		lnum = 1
	end
	if vim.fn.filereadable(file) == 0 then
		return { "No preview available" }, nil
	end
	local lines = vim.fn.readfile(file)
	if #lines == 0 then
		lines = { "" }
	end
	local cursor = tonumber(lnum) or 1
	if cursor < 1 then
		cursor = 1
	end
	if cursor > #lines then
		cursor = #lines
	end
	-- Window large files around the matched line so the line-jump target
	-- is always loaded. Files mode (cursor == 1) shows the head; grep
	-- shows a centered slice. Cursor is remapped to the window.
	local MAX_PREVIEW = 200
	if #lines > MAX_PREVIEW then
		local start = cursor - math.floor(MAX_PREVIEW / 2)
		if start < 1 then
			start = 1
		end
		local finish = start + MAX_PREVIEW - 1
		if finish > #lines then
			finish = #lines
			start = finish - MAX_PREVIEW + 1
		end
		local window = {}
		for i = start, finish do
			window[#window + 1] = lines[i]
		end
		cursor = cursor - start + 1
		if cursor < 1 then
			cursor = 1
		end
		if cursor > #window then
			cursor = #window
		end
		lines = window
	end
	return lines, cursor, file
end

--- Format one raw rg vimgrep line as a concise `file:lnum` label for the
--- left pane (telescope-style). The matched snippet is intentionally
--- omitted here; it is shown only in the right preview pane. This keeps
--- rows short, legible and aligned. Returns the label truncated to the
--- window width and its byte length (for byte-accurate highlights).
--- Width is derived from the live results window width; no hardcoded offsets.
local function format_grep_line(item, width)
	local file, lnum = parse_location(item)
	file = file or ""
	lnum = lnum or ""
	if file == "" then
		local fallback = "  " .. truncate_str(item, math.max(8, width - 2))
		return fallback, #fallback
	end
	local suffix = ":" .. lnum
	-- Reserve room for the leading indent + `:lnum` suffix; shorten the
	-- path first so long paths collapse to `first/.../last` instead of
	-- raw truncation, always keeping the suffix visible.
	local avail = width - 2 - vim.fn.strdisplaywidth(suffix)
	if avail < 4 then
		avail = 4
	end
	local short = shorten_path(file, avail)
	local label = "  " .. short .. suffix
	if vim.fn.strdisplaywidth(label) > width then
		label = truncate_str(label, width)
	end
	return label, #label
end

local function render_results()
	if not state or state._rendering then
		return
	end
	-- Guard against reentrant renders: input-event callbacks and async
	-- job/timer completions all funnel through here via vim.schedule.
	-- Without this, overlapping renders can interleave and duplicate rows.
	state._rendering = true
	local width = vim.api.nvim_win_is_valid(state.results_win) and vim.api.nvim_win_get_width(state.results_win)
		or 40
	local lines = {}
	-- Rebuild the mapping from scratch every render so stale rows can
	-- never linger or mirror previous input states.
	state.display = {}
	for i, item in ipairs(state.candidates) do
		if state.mode == "grep" then
			local disp = format_grep_line(item, width)
			lines[#lines + 1] = disp
		else
			lines[#lines + 1] = "  " .. shorten_path(item, math.max(8, width - 2))
		end
		state.display[i] = item
	end
	if #lines == 0 then
		lines = { state.mode == "grep" and "  Type to search…" or "  No matches" }
	end

	local buf = state.results_buf
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	-- Full replace starting strictly at line 0: never append, so result
	-- rows can neither duplicate nor mirror a previous input state.
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)

	local selected = state.selected
	if selected and selected >= 1 and selected <= #state.candidates then
		-- Selection is indicated solely by the results window's cursorline,
		-- which spans the full window width uniformly. Never paint a Visual
		-- background over the row: it ends at EOL and leaves a two-tone
		-- rectangular block artifact in the middle of the text.
		if state.mode == "grep" then
			local item = state.candidates[selected]
			if item then
				-- Left pane shows only the `file:lnum` label; highlight it
				-- dimly. The snippet and query matches live in the preview.
				local label, _ = format_grep_line(item, width)
				-- Extmark columns are byte-indexed: use byte lengths, not
				-- display widths, so multibyte text stays aligned.
				pcall(vim.api.nvim_buf_set_extmark, buf, hl_ns, selected - 1, 0, {
					end_col = #label,
					hl_group = "LineNr",
				})
			end
		end
		pcall(vim.api.nvim_win_set_cursor, state.results_win, { selected, 0 })
	end
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	state._rendering = false
end

local function render_preview()
	if not state then
		return
	end
	local sel_item = state.candidates[state.selected]
	local preview_lines, preview_cursor, file = preview_for(sel_item)
	local pw = state.preview_win and vim.api.nvim_win_is_valid(state.preview_win)
			and vim.api.nvim_win_get_width(state.preview_win)
		or 40
	local truncated = {}
	for _, l in ipairs(preview_lines) do
		truncated[#truncated + 1] = truncate_str(sanitize_line(l), pw)
	end
	preview_lines = truncated
	if state.preview_buf and vim.api.nvim_buf_is_valid(state.preview_buf) then
		vim.api.nvim_buf_set_option(state.preview_buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, preview_lines)
		vim.api.nvim_buf_set_option(state.preview_buf, "modifiable", false)
		if file then
			-- Detach the previous Treesitter highlighter so filetype
			-- switches don't stack parsers on the reused buffer.
			pcall(vim.treesitter.stop, state.preview_buf)
			local ft = nil
			if vim.filetype and vim.filetype.match then
				-- Native detection: explicit filename wins; buffer content
				-- is used as fallback for ambiguous extensions.
				local ok_match, matched =
					pcall(vim.filetype.match, { filename = file, buf = state.preview_buf })
				if ok_match then
					ft = matched
				end
				-- Fallback for very old shims that expose detect().
				if (not ft or ft == "") and vim.filetype.detect then
					local ok_det, detected = pcall(vim.filetype.detect, file)
					if ok_det then
						ft = detected
					end
				end
			end
			if ft and ft ~= "" then
				-- Explicit filetype assignment triggers FileType autocmds
				-- (indent, ftplugin) on the preview buffer.
				pcall(function()
					vim.bo[state.preview_buf].filetype = ft
				end)
				-- Attach Treesitter when a parser exists; otherwise fall
				-- back to standard syntax highlighting.
				local lang = ft
				if vim.treesitter.language and vim.treesitter.language.get_lang then
					local ok_lang, resolved = pcall(vim.treesitter.language.get_lang, ft)
					if ok_lang and resolved and resolved ~= "" then
						lang = resolved
					end
				end
				local ts_ok = pcall(vim.treesitter.start, state.preview_buf, lang)
				if not ts_ok then
					pcall(function()
						vim.bo[state.preview_buf].syntax = ft
					end)
				end
			end
		end
	end
	if preview_cursor and state.preview_win and vim.api.nvim_win_is_valid(state.preview_win) then
		-- Parse target line (e.g. `styles.css:12` -> 12) and jump the
		-- preview cursor to that exact row, then center it.
		if preview_cursor < 1 then
			preview_cursor = 1
		end
		if preview_cursor > #preview_lines then
			preview_cursor = #preview_lines
		end
		if preview_cursor >= 1 then
			pcall(vim.api.nvim_win_set_cursor, state.preview_win, { preview_cursor, 0 })
			pcall(vim.api.nvim_win_call, state.preview_win, function()
				vim.cmd("normal! zz")
			end)
		end
	end
	-- Highlight the matched line/range in the preview. The left pane shows
	-- only `file:lnum`, so the preview owns the content highlight: whole
	-- target line gets a line highlight, and every query occurrence on that
	-- line gets a Search highlight (grep mode only).
	if state.preview_buf and vim.api.nvim_buf_is_valid(state.preview_buf) then
		pcall(vim.api.nvim_buf_clear_namespace, state.preview_buf, hl_ns, 0, -1)
		if preview_cursor and preview_cursor >= 1 and preview_cursor <= #preview_lines then
			pcall(vim.api.nvim_buf_set_extmark, state.preview_buf, hl_ns, preview_cursor - 1, 0, {
				line_hl_group = "Visual",
				priority = 200,
			})
			if state.mode == "grep" and state.query and state.query ~= "" then
				local target = preview_lines[preview_cursor] or ""
				if target ~= "" then
					local lower_text = target:lower()
					local lower_q = state.query:lower()
					local s = 1
					while s <= #lower_text do
						local ms, me = string.find(lower_text, lower_q, s, true)
						if not ms then
							break
						end
						-- plain-find indices are byte-based, matching the
						-- byte-indexed extmark columns.
						pcall(vim.api.nvim_buf_set_extmark, state.preview_buf, hl_ns, preview_cursor - 1, ms - 1, {
							end_col = me,
							hl_group = "Search",
							priority = 201,
						})
						s = me + 1
					end
				end
			end
		end
	end
end

local function render()
	if not state then
		return
	end
	render_results()
	render_preview()
end

local function refresh()
	if not state then
		return
	end
	-- Monotonic generation: every keystroke bumps the sequence and async
	-- fd/rg callbacks only apply when their generation is still current.
	-- This drops stale results that would otherwise overwrite (and appear
	-- to duplicate/conflict with) newer input states.
	state._seq = (state._seq or 0) + 1
	local seq = state._seq
	local query = state.query
	if state._job then
		pcall(function()
			state._job:kill(9)
		end)
		state._job = nil
	end
	if state._timer then
		pcall(function()
			state._timer:stop()
		end)
	end

	local function apply(candidates)
		if not state or state._seq ~= seq or state.query ~= query then
			return
		end
		state.candidates = candidates or {}
		if #state.candidates == 0 then
			state.selected = 0
		elseif state.selected < 1 or state.selected > #state.candidates then
			state.selected = 1
		end
		render()
	end

	if state.mode == "files" then
		local key = state.hidden and "hidden" or "normal"
		local cached = file_cache[key]
		if cached then
			apply(filter_files(cached, query))
		else
			local job = vim.system(fd_cmd(state.hidden), { text = true }, function(res)
				vim.schedule(function()
					if not state or state._seq ~= seq or state.query ~= query then
						return
					end
					local files = {}
					for line in (res.stdout or ""):gmatch("[^\r\n]+") do
						local cleaned = sanitize_line(line)
						if cleaned ~= "" then
							table.insert(files, cleaned)
						end
					end
					file_cache[key] = files
					apply(filter_files(files, query))
				end)
			end)
			state._job = job
		end
	elseif state.mode == "buffers" then
		local items = {}
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
				local name = vim.api.nvim_buf_get_name(bufnr)
				if name == "" then
					name = "[No Name] (" .. bufnr .. ")"
				end
				table.insert(items, sanitize_line(name))
			end
		end
		apply(filter_files(items, query))
	else
		-- grep with debounce
		if state._timer then
			pcall(function()
				state._timer:close()
			end)
		end
		local timer = vim.uv.new_timer()
		state._timer = timer
		timer:start(90, 0, function()
			timer:stop()
			vim.schedule(function()
				if not state or state._seq ~= seq or state.query ~= query then
					return
				end
				if #query < 2 then
					apply({})
					return
				end
				local job = vim.system(rg_cmd(query, state.hidden), { text = true }, function(res)
					vim.schedule(function()
						if not state or state._seq ~= seq or state.query ~= query then
							return
						end
						local items = {}
						for line in (res.stdout or ""):gmatch("[^\r\n]+") do
							local cleaned = sanitize_line(line)
							if cleaned ~= "" then
								table.insert(items, cleaned)
							end
						end
						apply(items)
					end)
				end)
				state._job = job
			end)
		end)
	end
end

--- Create three independent floating windows:
--- input (top, height 1) / results (bottom) / preview (right, full height).
function M.open(title, mode, hidden, on_select)
	close_picker()

	local results_h = math.min(vim.o.lines - 8, math.floor(vim.o.lines * 0.5))
	if results_h < 5 then
		results_h = 5
	end
	local input_h = 1
	local total_width = math.min(vim.o.columns - 4, math.floor(vim.o.columns * 0.86))
	local left_width = math.floor(total_width * 0.50)
	local right_width = total_width - left_width - 1
	-- outer heights: each float adds 2 for the border
	local combined_h = (input_h + 2) + (results_h + 2)
	local start_row = math.floor((vim.o.lines - combined_h) / 2)
	if start_row < 0 then
		start_row = 0
	end
	local left_col = math.floor((vim.o.columns - total_width) / 2)
	local right_col = left_col + left_width + 1
	local input_row = start_row
	local results_row = start_row + input_h + 2
	-- preview spans input + results outer height
	local preview_h = combined_h - 2
	if preview_h < 1 then
		preview_h = 1
	end

	local input_buf = vim.api.nvim_create_buf(false, true)
	local input_win = vim.api.nvim_open_win(input_buf, true, {
		relative = "editor",
		width = left_width,
		height = input_h,
		row = input_row,
		col = left_col,
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	})

	local results_buf = vim.api.nvim_create_buf(false, true)
	local results_win = vim.api.nvim_open_win(results_buf, false, {
		relative = "editor",
		width = left_width,
		height = results_h,
		row = results_row,
		col = left_col,
		style = "minimal",
		border = "rounded",
	})

	local preview_buf = vim.api.nvim_create_buf(false, true)
	local preview_win = vim.api.nvim_open_win(preview_buf, false, {
		relative = "editor",
		width = right_width,
		height = preview_h,
		row = start_row,
		col = right_col,
		style = "minimal",
		border = "rounded",
		title = " Preview ",
		title_pos = "center",
	})

	for _, buf in ipairs({ input_buf, results_buf, preview_buf }) do
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buf, "swapfile", false)
	end
	-- Disable every completion source on the picker buffers so no popup
	-- menu ever renders over the picker. mini.completion uses
	-- completefunc with auto_setup, so both funcs must be cleared, the
	-- keyword scan list emptied, and mini.completion opted out per buffer.
	for _, buf in ipairs({ input_buf, results_buf, preview_buf }) do
		vim.bo[buf].omnifunc = ""
		vim.bo[buf].completefunc = ""
		vim.bo[buf].complete = ""
		vim.b[buf].minicompletion_disable = true
	end
	vim.api.nvim_buf_set_option(results_buf, "modifiable", false)
	vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)

	vim.api.nvim_win_set_option(input_win, "wrap", false)
	vim.api.nvim_win_set_option(input_win, "cursorline", false)
	vim.api.nvim_win_set_option(results_win, "cursorline", true)
	vim.api.nvim_win_set_option(results_win, "wrap", false)
	vim.api.nvim_win_set_option(preview_win, "wrap", false)
	vim.api.nvim_win_set_option(preview_win, "cursorline", true)

	state = {
		input_buf = input_buf,
		input_win = input_win,
		results_buf = results_buf,
		results_win = results_win,
		preview_buf = preview_buf,
		preview_win = preview_win,
		title = title,
		mode = mode,
		hidden = hidden,
		query = "",
		candidates = {},
		selected = 0,
		on_select = on_select,
		_job = nil,
		_timer = nil,
		_seq = 0,
		_rendering = false,
		display = {},
	}

	-- `> ` prompt marker as virtual text so the buffer holds only the query.
	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })
	pcall(vim.api.nvim_buf_set_extmark, input_buf, ns, 0, 0, {
		virt_text = { { "> ", "Special" } },
		virt_text_pos = "inline",
		right_gravity = false,
	})

	local augroup = vim.api.nvim_create_augroup("nvimz_picker", { clear = true })
	state._augroup = augroup

	local function move_selection(delta)
		if not state then
			return
		end
		local n = #state.candidates
		if n == 0 then
			return
		end
		local next_sel = (state.selected or 0) + delta
		if next_sel < 1 then
			next_sel = 1
		elseif next_sel > n then
			next_sel = n
		end
		if next_sel ~= state.selected then
			state.selected = next_sel
			render()
		end
	end

	local function confirm()
		if not state then
			return
		end
		local item = state.candidates[state.selected]
		local cb = state.on_select
		close_picker()
		if item and cb then
			cb(item)
		end
	end

	local function map_input(lhs, fn)
		vim.keymap.set({ "i", "n" }, lhs, fn, { buffer = input_buf, nowait = true, silent = true })
	end

	map_input("<Esc>", close_picker)
	map_input("<C-c>", close_picker)
	map_input("<CR>", confirm)
	map_input("<Down>", function()
		move_selection(1)
	end)
	map_input("<Up>", function()
		move_selection(-1)
	end)
	map_input("<C-n>", function()
		move_selection(1)
	end)
	map_input("<C-p>", function()
		move_selection(-1)
	end)
	map_input("<C-j>", function()
		move_selection(1)
	end)
	map_input("<C-k>", function()
		move_selection(-1)
	end)

	vim.api.nvim_create_autocmd("TextChangedI", {
		group = augroup,
		buffer = input_buf,
		callback = function()
			if not state or state._rendering then
				return
			end
			-- input buffer holds the raw query only; the `> ` marker is virtual.
			local line = (vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or "")
			state.query = line
			refresh()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWipeout", "WinClosed" }, {
		group = augroup,
		buffer = input_buf,
		once = true,
		callback = function()
			close_picker()
		end,
	})

	-- Sync preview scroll & line jump when navigating the left list.
	-- Covers direct cursor moves in the results window (mouse, j/k after
	-- focusing it); programmatic moves via move_selection() already call
	-- render(), and the row == selected guard below makes that a no-op.
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		buffer = results_buf,
		callback = function()
			if not state or state._rendering then
				return
			end
			if not vim.api.nvim_win_is_valid(state.results_win) then
				return
			end
			local ok, pos = pcall(vim.api.nvim_win_get_cursor, state.results_win)
			if not ok or not pos then
				return
			end
			local row = pos[1]
			if row < 1 or row > #state.candidates then
				return
			end
			if row ~= state.selected then
				state.selected = row
				render()
			end
		end,
	})

	refresh()
	render()
	vim.api.nvim_set_current_win(input_win)
	vim.cmd("startinsert")
end

local function open_file(item)
	vim.cmd("edit " .. vim.fn.fnameescape(item))
end

local function open_grep(item)
	local file, lnum, col = parse_location(item)
	if file then
		vim.cmd("edit " .. vim.fn.fnameescape(file))
		local l = tonumber(lnum) or 1
		local c = tonumber(col) or 1
		pcall(vim.api.nvim_win_set_cursor, 0, { l, math.max(0, c - 1) })
	end
end

local function open_buffer(item)
	vim.cmd("edit " .. vim.fn.fnameescape(item))
end

function M.files()
	M.open("Files", "files", false, open_file)
end

function M.files_hidden()
	M.open("Files (hidden)", "files", true, open_file)
end

function M.grep()
	M.open("Live Grep", "grep", false, open_grep)
end

function M.grep_hidden()
	M.open("Grep hidden (gitignored)", "grep", true, open_grep)
end

function M.buffers()
	M.open("Buffers", "buffers", false, open_buffer)
end

M.close_picker = close_picker

function M.setup()
	vim.keymap.set("n", "<leader>ff", M.files, { desc = "Find files" })
	vim.keymap.set("n", "<leader>fe", M.files_hidden, { desc = "Find files (hidden)" })
	vim.keymap.set("n", "<leader>fg", M.grep, { desc = "Live grep" })
	vim.keymap.set("n", "<leader>fr", M.grep_hidden, { desc = "Grep hidden (gitignored)" })
	vim.keymap.set("n", "<leader>fb", M.buffers, { desc = "Buffers" })
end

return M
