# Commands & Keybindings

This document serves as a comprehensive reference manual for all custom native commands and keybindings preconfigured in **nvimz**.

---

## Native Commands

**nvimz** provides a centralized package management and health diagnostics layer with the following user commands:

| Command | Description |
| --- | --- |
| `:PackSync` | Fetch and check plugin updates without applying them. |
| `:PackUpdate` | Apply updates, relock, validate, and regenerate reports. |
| `:PackValidate` | Comprehensive runtime integrity and config health check. |
| `:PackDoctor` | Run system-wide health diagnostics. |
| `:PackBenchmark`| Measure startup and module performance history. |
| `:PackRollback` | Restore plugins from `nvim-pack-lock.json` state. |
| `:PackStatus` | Quick overview of package and environment health. |
| `:PackClean` | Remove unused plugins and stale cache files. |
| `:PackSnapshot` | Generate a system and state snapshot in `snapshots/`. |
| `:PackReport` | Manually regenerate the `MAINTENANCE_REPORT.md`. |
| `:ParsersUpdate`| Update, compile, and sync Tree-sitter parsers/queries. |
| `:ToolDoctor` | Show environment tooling health (LSP, formatters, etc.). |

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

### Files & Searching (`mini.pick` & `oil.nvim`)

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle file explorer (`oil.nvim`) |
| `o` / `O` | Add new line to create new file/folder (save with `:w` inside `oil.nvim`) |
| `<leader>ff` | Search files by name |
| `<leader>fe` | Search files including hidden |
| `<leader>fg` | Live project grep search |
| `<leader>fr` | Live grep including gitignored |
| `<leader>fb` | List active buffers |
| `<leader>fh` | Query documentation help tags |
| `<leader>fd` | Search buffer diagnostics |
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
| `<leader>lr` | Locate references (Picker) |
| `<leader>ld` | Locate definition (Picker) |
| `<leader>ly` | Locate type definition (Picker) |
| `<leader>li` | Locate interface implementation (Picker) |
| `<leader>cs` | Document symbols outline |
| `<leader>cS` | Workspace symbols search |

### Git & AI

| Key | Action |
| --- | --- |
| `<leader>gs` | Open interactive Git status |
| `<leader>gb` | Trigger inline Git blame |
| `<leader>gd` | Toggle side-by-side diff overlay |
| `<leader>gc` | Browse commits history (Picker) |
| `<leader>gh` | Browse changed Git hunks (Picker) |
| `<leader>aa` | Open AI chat window (Ollama) |
| `<leader>aq` | Toggle AI chat visibility |
| `<leader>at` | Toggle GitHub Copilot engine |
| `<leader>a3` | Hot-swap to Qwen 2.5 Coder 3B |
| `<leader>a7` | Hot-swap to Qwen 2.5 Coder 7B |
| `<M-S-right>`| Accept Copilot suggestion |
| `<M-]>` / `<M-[>` | Next / Previous Copilot suggestion |

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
