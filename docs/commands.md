# Commands & Keybindings

This document serves as a comprehensive reference manual for all custom native commands and keybindings preconfigured in **nvimz**.

---

## Native Commands

**nvimz** exposes a small command surface over native Neovim mechanisms:

| Command | Description |
| --- | --- |
| `:PackUpdate` | Download plugin updates and open the native `vim.pack` review buffer. |
| `:PackRollback` | Open the native review buffer to revert plugins to the revisions in `nvim-pack-lock.json` (`:write` applies, `:quit` discards). |
| `:PackStatus` | Quick summary of managed/active plugins, lockfile, and core tools. |
| `:PackClean` | Remove undeclared plugins and broken parser binaries. |
| `:NvimzBenchmark` | Measure startup over three runs and list the slowest sourced modules. |
| `:ParsersUpdate` | Rebuild Treesitter parsers and sync queries. |
| `:License` | Open the project `LICENSE`. |

### Health

| Command | Description |
| --- | --- |
| `:checkhealth nvimz` | Core tools, language servers, formatters, parsers, plugins, machine config. |
| `:checkhealth vim.pack` | Native packaging and lockfile diagnostics. |

### LSP Commands

| Command | Description |
| --- | --- |
| `:LspInfo` | List active LSP clients and attached buffers. |
| `:LspLog` | Open the LSP log file. |
| `:LspStart <server>` | Start a server configured in `lua/nvimz/config/languages.lua`. |
| `:LspStop [server]` | Stop the current buffer's server, or a named server. |
| `:LspRestart` | Restart LSP clients for the current buffer. |

---

## Keybindings

The leader key in **nvimz** is configured to **`<Space>`**.

### Core Navigation

| Key | Action |
| --- | --- |
| `<leader>ds` | Open startup dashboard |
| `<leader>w` | Write current buffer |
| `<leader>qq` | Quit active window |
| `<leader>h` | Clear search highlights |
| `<leader>bd` | Close current buffer |
| `<leader>bn` / `bp` | Next / Previous buffer |
| `<C-h/j/k/l>` | Navigate window splits |
| `<C-d/u>` | Scroll down / up and center |
| `<leader>z` | Toggle code fold |
| `<leader>mj` / `<leader>mk` | Move current line down / up |
| `J` / `K` (Visual) | Move selected lines down / up |
| `<leader>tt` | Toggle floating scratch terminal |
| `<leader>tb` | Toggle bottom terminal |
| `<Esc><Esc>` | Exit terminal mode (Terminal only) |

### Splits & Layouts

| Key | Action |
| --- | --- |
| `<leader>sv` | Split window vertically |
| `<leader>sh` | Split window horizontally |
| `<leader>se` | Equalize all active splits |
| `<leader>rh` / `rl` | Resize window width (Left / Right) |
| `<leader>rj` / `rk` | Resize window height (Down / Up) |

### Files & Searching (`native` & `oil.nvim`)

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle file explorer (`oil.nvim`) |
| `o` / `O` | Add new line to create new file/folder (save with `:w` inside `oil.nvim`) |
| `<leader>ff` | Search files by name |
| `<leader>fe` | Search files including hidden |
| `<leader>fg` | Live project grep search |
| `<leader>fr` | Live grep including gitignored |
| `<leader>fb` | List active buffers |
| `<leader>cp` | Copy relative path to clipboard |
| `<leader>cP` | Copy absolute path to clipboard |
| `<leader>cn` | Copy filename to clipboard |
| `<leader>cd` | Copy parent directory path to clipboard |

### LSP & Code Intelligence

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `K` | Trigger hover documentation |
| `<leader>rn` | Rename active symbol |
| `<leader>ca` | Open code actions |
| `<leader>fm` | Format buffer manually |
| `<leader>uh` | Toggle global inlay hints |
| `gl` | Show line diagnostics float |

### Git & AI

| Key | Action |
| --- | --- |
| `<leader>gs` | Open interactive Git status |
| `<leader>gb` | Trigger inline Git blame |
| `<leader>gd` | Toggle `mini.diff` overlay |
| `<leader>aa` | Toggle AI chat window (Ollama via `gp.nvim`) |
| `<leader>a1` | Switch to the `Scout` agent (`qwen2.5:7b`) |
| `<leader>a2` | Switch to the `Judge` agent (`qwen3:8b`) |
| `<leader>a3` | Switch to the `Editor` agent (`qwen2.5-coder:7b`) |
| `<leader>at` | Toggle GitHub Copilot |
| `<leader>ar` (Visual) | AI rewrite selection |
| `<leader>ap` (Visual) | AI append to selection |
| `<leader>ab` (Visual) | AI prepend to selection |
| `<A-CR>` | Send the AI chat prompt |
| `<M-S-right>` | Accept Copilot suggestion |
| `<M-]>` / `<M-[>` | Next / previous Copilot suggestion |
| `<C-]>` | Dismiss Copilot suggestion |

### Dashboard

| Key | Action |
| --- | --- |
| `f` | Find files |
| `g` | Live grep |
| `e` | Open file explorer |
| `q` | Quit Neovim |

### Debugging (DAP)

| Key | Action |
| --- | --- |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue execution |
| `<leader>di` | Step Into |
| `<leader>do` | Step Over |
| `<leader>du` | Step Out |
| `<leader>dr` | Open DAP REPL console |
| `<leader>dt` | Debug test (Go specialized) |
