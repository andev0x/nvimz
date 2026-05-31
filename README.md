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
- **System tools:** `git`, `rg` (ripgrep), `fd`
- **Optional language tooling (install what you use):**
  - **LSP servers:** `gopls`, `lua-language-server`, `pyright`, `typescript-language-server`, `jdtls`, `rust-analyzer`, `terraform-ls`, `yaml-language-server`
  - **Formatters:** `stylua`, `black`, `shfmt`, `gofmt`, `google-java-format`, `terraform` (for `terraform fmt`)
  - **AI:** [Ollama](https://ollama.com/) (local models), GitHub Copilot (requires login)

### 2. Installation

```bash
# Backup your existing configuration
mv ~/.config/nvim ~/.config/nvim.bak

# Clone and launch nvimz
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
nvim
```

On first launch, plugins will be automatically initialized and installed via the built-in `vim.pack` system.

For Arch Linux or Ubuntu users, dedicated installation scripts are available:

```bash
# Arch Linux
./scripts/arch-install

# Ubuntu / Debian
./scripts/ubuntu-install
```

To auto-detect your package manager and install common tooling:

```bash
./scripts/bootstrap
```

### 3. Verification & Maintenance

**nvimz** features a centralized orchestration layer in `lua/infra/deps.lua` that manages the entire package lifecycle. It uses a deterministic update strategy:

```bash
# Update plugins via CLI wrapper
# This invokes the nvim orchestration layer in headless mode
./scripts/update-plugins

# Run the full validation pipeline
# Updates plugins -> Regenerates lockfile -> Validates environment -> Benchmarks
./scripts/validate

# Check system tooling health (CLI)
./scripts/doctor

# Install/verify Tree-sitter parsers and queries
./scripts/parsers
```

**Key Orchestration Features:**

* **Deterministic Updates:** Plugins are updated via `git reset --hard` to their remote default branch, ensuring a clean and predictable state.
* **Source of Truth:** The on-disk git state is the absolute source of truth.
* **Generated Lockfile:** `nvim-pack-lock.json` is a generated snapshot of your exact environment, not cached metadata.
* **Maintenance Report:** Every validation run generates `MAINTENANCE_REPORT.md`, providing a transparent audit of your setup's health and performance.

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
| `:ParsersUpdate`| Update and compile Tree-sitter parsers directly. |
| `:ToolDoctor` | Show environment tooling health (LSP, formatters, etc.). |

## Features

### Performance & Minimalism

* **<20ms Startup Target:** Achieved via bytecode caching and a 3-phase event-driven lazy loading system.
* **Persistent State Caching:** Centralized caching in `lua/infra/cache.lua` persists startup metrics and plugin states.
* **Lifecycle Orchestration:** `lua/infra/deps.lua` acts as the primary package lifecycle manager, handling everything from on-disk git state validation to automated maintenance reporting.
* **Bare-Metal Tree-sitter:** Direct interaction with Neovim 0.12's native syntax highlighting and folding.
* **Zero Ecosystem Bloat:** Replaces heavy third-party dependency chains with the unified `mini.nvim` suite.
* **High-Throughput LSP:** Non-blocking attach logic using native `vim.lsp.start` for instantaneous response.

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
| `<leader>a3` | Hot-swap to Ollama 3B model |
| `<leader>a7` | Hot-swap to Ollama 7B model |
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
Create it quickly with:

```bash
./scripts/setup-machine
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
