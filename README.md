# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

**nvimz** is a high-performance Neovim setup optimized for **Neovim 0.12+** that prioritizes speed, structural simplicity, and developer experience. With a strict startup target under **20ms**, it replaces heavy plugin ecosystems with native APIs, the lightweight `mini.nvim` suite, and the built-in `vim.pack` package manager.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Neovim](https://img.shields.io/badge/Neovim-%3E=0.12.0-blueviolet?logo=neovim)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/andev0x/nvimz)

## Philosophy: Zero-Mason, Native-First

Unlike heavy configurations that rely on Mason for runtime isolation, **nvimz** expects language servers and formatters to be pre-installed in your system `$PATH`. This aligns perfectly with modern infrastructure-as-code and deterministic dotfile management:

- **Predictable & Reproducible:** Your development environment is managed deterministically by your system's package manager (`Homebrew`, `Nix`, `APT`).
- **Zero Startup Overhead:** Eliminates execution delays caused by third-party managers checking binaries at startup.
- **Native-First Stability:** Leverages Neovim 0.12+ built-in features to drastically reduce plugin surface area and minimize breaking changes.
- **Phase-Driven Loading:** Strategic 3-phase loading ensures the core initialization path remains completely unblocked:
    1. **UI Phase:** Deferred to the first idle period (Theme, Icons, Statusline).
    2. **Editing Phase:** Triggered by file access (LSP, Formatting).
    3. **Extra Phase:** Triggered by user interaction (DAP, AI, Git).

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz1.png" width="350" alt="nvimz workspace display" />
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz2.png" width="350" alt="nvimz file explorer display" />
</p>

## Quick Start

### 1. Requirements

- **Neovim 0.12.0+**
- **System tools:** `git`, `rg` (ripgrep), `fd`, `build-essential` (or `base-devel`)
- **Optional language tooling:** (Automatically handled by the setup script)

### 2. Installation & Setup

```bash
# Backup your existing configuration
mv ~/.config/nvim ~/.config/nvim.bak

# Clone and launch nvimz
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
cd ~/.config/nvim

# Run the universal setup script
# This handles OS detection, toolchain installation (Go, Rust, Python, Java, Node),
# and shell configuration for macOS, Arch, and Ubuntu.
./scripts/setup
```

### 3. Verification & Maintenance

**nvimz** features a centralized management layer in `scripts/manage` and `lua/infra/deps.lua`.

```bash
# Update plugins only
./scripts/manage --update

# Sync system packages (brew, pacman, apt)
./scripts/manage --sync

# Generate a comprehensive health and benchmark report
./scripts/manage --report

# Run the full maintenance pipeline (Update -> Sync -> Report)
./scripts/manage --all

# Check system tooling health (CLI)
./scripts/doctor

# Build/verify pinned Tree-sitter parsers and sync queries
./scripts/parsers
```

**Key Orchestration Features:**

* **Deterministic Updates:** Plugins are updated via `git reset --hard` to their remote default branch.
* **Source-Built Treesitter:** `scripts/parsers` compiles parsers from source with pinned revisions and bundles optimized queries in the root `queries/` directory.
* **Universal Setup:** `scripts/setup` provides a zero-config path for bootstrapping a complete development environment across multiple Linux distributions and macOS.
* **Maintenance Report:** Every `--report` run generates `MAINTENANCE_REPORT.md`, providing a transparent audit of your setup's health and performance.

**Native Commands:**

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

## Features

### Performance & Minimalism

* **<20ms Startup Target:** Achieved via bytecode caching and a 3-phase event-driven lazy loading system.
* **Persistent State Caching:** Centralized caching in `lua/infra/cache.lua` persists startup metrics.
* **Pinned Treesitter:** Uses specific parser revisions compiled locally for maximum stability and performance. Optimized queries are decoupled from Neovim's runtime and managed in the project root.
* **Zero Ecosystem Bloat:** Replaces heavy third-party dependency chains with the unified `mini.nvim` suite.
* **High-Throughput LSP:** Non-blocking attach logic using native `vim.lsp.start`.

### Development Workflow

* **Fluid File Explorer:** Rapid navigation using `mini.files`. Press `a` to create new files/folders.
* **Fuzzy Finding:** Instant search for files, grep patterns, and buffers powered by `mini.pick`.
* **Git Operations:** Version control tracking directly from the buffer with `mini.git` and `mini.diff`.
* **Scratch Terminal:** Instant floating shell access (`<leader>tt`) and bottom terminal (`<leader>tb`).
* **Asynchronous Formatting:** Managed via `conform.nvim` leveraging system-wide binaries.
* **Smart Diagnostics:** Clean diagnostic hover popups triggered gracefully on cursor-hold events.

### Advanced Capabilities

* **Interactive Debugging:** Pre-configured `nvim-dap` with UI overlays and specialized Go workflows.
* **Local AI Context:** Deep integration with Ollama via `gp.nvim`.
* **GitHub Copilot:** Native integration with `copilot.lua` for contextual inline suggestions.
* **Inlay Hints:** Native LSP inlay hints support, toggleable via `<leader>uh`.

### Preconfigured Language Support

The default spec in `lua/infra/registry/languages.lua` includes LSP and formatter wiring for:

* **Go** (`gopls`, `gofmt`)
* **Lua** (`lua-language-server`, `stylua`)
* **Python** (`pyright`, `black`)
* **Java** (`jdtls`, `google-java-format`)
* **JavaScript/TypeScript** (`typescript-language-server`)
* **Rust** (`rust-analyzer`)
* **Terraform/HCL** (`terraform-ls`, `terraform fmt`)
* **YAML** (`yaml-language-server`)

## Keybindings

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

### Files & Searching (`mini.pick` & `mini.files`)

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle file explorer (`mini.files`) |
| `a` | Create new file/folder (inside `mini.files`) |
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

## Customization

### Local Machine Overrides

Environment-specific variables can be declared in `lua/machine/local.lua` (ignored by git).
The universal setup script (`./scripts/setup`) creates this automatically from the example.
To create it manually:

```bash
cp lua/machine/example.lua lua/machine/local.lua
```

```lua
return {
    python_path = "/usr/bin/python3",
}
```

### Extending LSP & Formatters

Add new language servers or formatters in `lua/infra/registry/languages.lua`. Ensure the binary is in your `$PATH`.

```lua
M.lsp_servers = {
    gopls = {
        cmd = { "gopls" },
        filetypes = { "go" },
        root_markers = { "go.mod", ".git" },
    },
}

M.formatters_by_ft = {
    lua = { "stylua" },
}
```

## License

MIT © [andev0x](https://github.com/andev0x)
