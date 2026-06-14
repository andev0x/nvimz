-- lua/infra/license.lua
local M = {}

-- Full license text (preserve line‑breaks exactly as in the LICENSE file)
M.text = [[
MIT License

Copyright (c) 2026 nvimz (@andev0x)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--- Return the license text.
function M.get()
    return M.text
end

--- Open the license in a temporary scratch buffer (useful for a `:License` command).
function M.show()
    local buf = vim.api.nvim_create_buf(false, true)   -- unlisted, scratch
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(M.text, "\n"))
    vim.api.nvim_set_current_buf(buf)
end

return M
