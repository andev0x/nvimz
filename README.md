# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

A high-performance Neovim setup optimized for **Neovim 0.12+** that prioritizes speed, simplicity, and developer experience. With a startup time under 15ms, nvimz replaces heavy plugin ecosystems with native APIs and the lightweight `mini.nvim` suite.

## Quick Start

### Installation

1. **Backup existing config** (if you have one):
   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. **Clone and launch**:
   ```bash
   git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
   nvim
   ```

That's it! The config self-bootstraps on first launch, automatically installing the package manager and all plugins.

## Features

### Performance & Minimalism
- **Startup time < 15ms** via lazy loading and `mini.deps`
- **Zero bloat:** Native Neovim APIs + `mini.nvim` suite
- **Treesitter built-in:** Neovim 0.12's native highlighting (no plugins needed)

### Development Workflow
- **File Explorer:** Quick file navigation with `mini.files`
- **Fuzzy Finding:** Fast file/buffer/grep search with `mini.pick`
- **Git Integration:** Full Git support (status, blame, diff, commits)
- **Floating Terminal:** Quick shell access without leaving Neovim
- **Formatting & LSP:** Native LSP + Mason for language server management

### Advanced Features
- **Debugging:** Pre-configured DAP (Debugger Adapter Protocol) with UI
- **Local AI:** Integrated Ollama support for offline code intelligence
- **Clipboard Sync:** Automatic OS clipboard integration
- **Self-Contained:** Auto-installs dependencies on first run

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Package Manager** | `mini.deps` |
| **LSP** | Native `vim.lsp` + `mason.nvim` |
| **Git** | `mini.git` + `mini.diff` |
| **Finder** | `mini.pick` + `mini.extra` |
| **Explorer** | `mini.files` |
| **Completion** | `mini.completion` (LSP-powered) |
| **Formatting** | `conform.nvim` |
| **Debugging** | `nvim-dap` + `nvim-dap-ui` |
| **AI** | `gen.nvim` + Ollama |

## Requirements

- **Neovim 0.12.0+**
- **System tools:** `git`, `rg` (ripgrep), `fd`
- **Optional:** [Ollama](https://ollama.com/) for AI features

Language servers are installed automatically via Mason.

## Keybindings

### Core & Buffer Management
| Key | Action |
|-----|--------|
| `<leader>w` | Write buffer |
| `<leader>q` | Quit window |
| `<leader>h` | Clear search highlight |
| `<leader>ds` | Open dashboard |
| `<leader>xx` | Close buffer |
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |

### Window Navigation
| Key | Action |
|-----|--------|
| `<C-h>` | Go to left window |
| `<C-j>` | Go to lower window |
| `<C-k>` | Go to upper window |
| `<C-l>` | Go to right window |

### File & Finding
| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | List buffers |
| `<leader>fh` | Help tags |

### LSP Navigation & Actions
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | References |
| `gi` | Implementation |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions |
| `<leader>lr` | LSP references (picker) |
| `<leader>ld` | LSP definition (picker) |
| `<leader>ly` | LSP dynamic symbols |
| `<leader>li` | LSP incoming calls |
| `<leader>cs` | LSP document symbols |
| `<leader>cS` | LSP workspace symbols |

### Diagnostics
| Key | Action |
|-----|--------|
| `gl` | Show diagnostics float |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

### Git Integration
| Key | Action |
|-----|--------|
| `<leader>gs` | Git status |
| `<leader>gb` | Git blame |
| `<leader>gd` | Toggle git diff |
| `<leader>gc` | Git commits (picker) |
| `<leader>gh` | Git hunks (picker) |

### Terminal & Debugging
| Key | Action |
|-----|--------|
| `<leader>t` | Toggle floating terminal |
| `<Esc><Esc>` | Exit terminal mode |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue execution |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>du` | Step out |
| `<leader>dr` | Open REPL |
| `<leader>dt` | Toggle DAP UI |

### Formatting & AI
| Key | Action |
|-----|--------|
| `<leader>fm` | Format buffer |
| `<leader>a` | AI assistant (Gen) |

## Customization

### Adding Language Servers

Language servers are managed through Mason. Use `:Mason` to open the interface and install servers for your languages.

### Configuring AI

Edit the Ollama setup to use different models:
```lua
-- Change the model in your config
model = "qwen2.5-coder:7b"  -- or your preferred model
```

Ensure Ollama is running:
```bash
ollama serve
```

### Modifying Keybindings

Edit the keymap configuration files in `lua/config/keymaps.lua` to customize shortcuts.

## Troubleshooting

### Slow startup?
- Verify Neovim version: `nvim --version` (should be 0.12+)
- Check for plugin conflicts in `lua/plugins/`

### LSP not working?
- Run `:Mason` and ensure language servers are installed
- Check `:LspInfo` for connection status

### Git integration issues?
- Verify `git` is installed and the repository is initialized
- Check git config with `git config --list`

### AI features not available?
- Ensure Ollama is installed and running: `ollama serve`
- Verify model is downloaded: `ollama pull qwen2.5-coder:7b`

## Project Structure

```
~/.config/nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/          # Core settings
│   ├── plugins/         # Plugin specifications
│   └── utils/           # Helper functions
└── README.md            # This file
```

## License

This configuration is provided as-is. Modify freely for your workflow.

## Contributing

Found improvements? Submit a PR or open an issue on GitHub.
