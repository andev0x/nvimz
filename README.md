# nvimz

A minimalist, high-performance Neovim configuration optimized for **Neovim 0.12+**. Built for Backend/Cloud DevOps engineers who value speed, security, and a "Zen" developer experience.

##  Features

- **Blazing Fast:** Startup time < 15ms thanks to `mini.deps` and asynchronous loading.
- **Pure Minimalism:** Replaces heavy plugins with native APIs and the `mini.nvim` suite.
- **Native Treesitter:** Uses Neovim 0.12's native Treesitter triggering (no `nvim-treesitter` plugin needed).
- **Integrated Git:** Full Git integration with status, diff, blame, and commit browsing via `mini.git` and `mini.diff`.
- **Floating Terminal:** Quick-access floating terminal for workflow efficiency.
- **Clipboard Sync:** Seamless synchronization with the operating system clipboard.
- **Self-Bootstrapping:** Automatically installs the package manager and configures itself on first run.
- **Secure Local AI:** Integrated with **Ollama** (`qwen2.5-coder:7b`) via `gen.nvim` for private, local code intelligence.
- **Full Debugger Suite:** Pre-configured `nvim-dap` with UI and Go support.

##  Tech Stack

| Component | Technology |
| :--- | :--- |
| **Package Manager** | `mini.deps` |
| **LSP Management** | `mason.nvim` + `vim.lsp.config` (Native) |
| **Git & Diff** | `mini.git` + `mini.diff` |
| **Fuzzy Finder** | `mini.pick` + `mini.extra` |
| **File Explorer** | `mini.files` |
| **Completion** | `mini.completion` (Native LSP source) |
| **Statusline** | `mini.statusline` |
| **Formatter** | `conform.nvim` |
| **Debugger** | `nvim-dap` + `nvim-dap-ui` |
| **AI** | `gen.nvim` + Ollama |

##  Installation

1. **Backup your existing config:**
   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. **Clone this repository:**
   ```bash
   git clone <your-repo-url> ~/.config/nvim
   ```

3. **Launch Neovim:**
   The configuration will automatically clone `mini.deps` and install all required plugins on the first start.

##  Keymaps

### Navigation & UI
- `<leader>e`: Toggle File Explorer (`mini.files`)
- `<leader>ff`: Find Files
- `<leader>fg`: Live Grep
- `<leader>fb`: List Buffers
- `<leader>fh`: Help Tags
- `<leader>w`: Save Buffer
- `<leader>q`: Quit Window
- `<C-h/j/k/l>`: Navigate between windows/splits

### Git & Development
- `<leader>gs`: Git Status
- `<leader>gd`: Toggle Diff Overlay
- `<leader>gb`: Git Blame (at cursor)
- `<leader>gc`: Pick Git Commits
- `<leader>gh`: Pick Git Hunks
- `gd`: Go to definition
- `K`: Hover documentation
- `<leader>rn`: Rename symbol
- `<leader>ca`: Code action
- `<leader>fm`: Format buffer
- `<leader>a`: Local AI (Gen)

### Terminal
- `<leader>t`: Toggle Floating Terminal
- `<Esc><Esc>`: Exit Terminal Mode

### Debugger (DAP)
- `<leader>db`: Toggle Breakpoint
- `<leader>dc`: Continue
- `<leader>di`: Step Into
- `<leader>do`: Step Over

##  Requirements
- Neovim 0.12.0+
- `git`, `rg` (ripgrep), `fd`
- [Ollama](https://ollama.com/) (optional, for AI features)
- Language Servers (automatically managed via Mason)
