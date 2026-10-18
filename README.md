# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

**nvimz** is a high-performance Neovim setup optimized for **Neovim 0.12+** that prioritizes speed, structural simplicity, and developer experience. With a strict startup target under **10ms** (measured ~6.9ms), it replaces heavy plugin ecosystems with native APIs, the lightweight `mini.nvim` suite, and the built-in `vim.pack` package manager.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Neovim](https://img.shields.io/badge/Neovim-%3E=0.12.0-blueviolet?logo=neovim)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/andev0x/nvimz)

---

## Philosophy: Zero-Mason, Native-First

Unlike heavy configurations that rely on Mason for runtime isolation, **nvimz** expects language servers and formatters to be pre-installed in your system `$PATH`. This aligns with infrastructure-as-code and deterministic dotfile management:

- **Predictable & Reproducible:** Environment managed by your system package manager (`Homebrew`, `Nix`, `APT`) or `./scripts/setup`.
- **Zero Startup Overhead:** No third-party manager checks binaries at startup. Core init only loads `core` + `vim.loader` cache; everything else is deferred.
- **Native-First Stability:** Uses Neovim 0.12+ built-ins (`vim.lsp`, `vim.pack`, `vim.treesitter`) to reduce plugin surface to 13 pinned plugins.
- **Phase-Driven Loading:** 3-phase `vim.pack` loading keeps the initial path unblocked (`lua/runtime/phases.lua`):
    1. **Phase 1 — UI + Core (`VimEnter`, deferred):** Theme, Icons, Statusline, Treesitter, LSP, `oil.nvim`, `mini.*` editing, native picker, Git.
    2. **Phase 2 — Format + Debug (`VimEnter`, deferred):** `conform.nvim`, `nvim-dap` + UI + `nvim-dap-go`.
    3. **Phase 3 — AI (`InsertEnter`, once):** `gp.nvim` (Ollama) + `copilot.lua`. Markdown rendering loads on `FileType=markdown` only.

---

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz1.png" width="350" alt="nvimz workspace display" />
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz2.png" width="350" alt="nvimz file explorer display" />
</p>

---

## Highlights

- **Ultra-Fast (~6.9ms):** `vim.loader` bytecode cache, deferred `VimEnter` phases, lazy `FileType`/`InsertEnter` triggers. Warns if startup exceeds 10ms. Verify with `:PackBenchmark`.
- **13 Pinned Plugins via `vim.pack`:** `tokyonight`, `mini.nvim`, `render-markdown`, `oil.nvim` + `oil-git-status`, `nvim-lspconfig`, `conform.nvim`, `nvim-dap` + `nvim-dap-ui` + `nvim-nio` + `nvim-dap-go`, `gp.nvim`, `copilot.lua`. Locked in `nvim-pack-lock.json`.
- **Power-user Workflows:** Native floating picker (files, live grep, buffers), `oil.nvim` directory explorer, floating/bottom terminals, `mini.git` status/blame + `mini.diff` overlay.
- **Native Code Intelligence:** `vim.lsp` with inlay hints, `mini.completion`, Treesitter parsers compiled AOT from source via `scripts/parsers` (decoupled `queries/`).
- **Advanced Features:** DAP debugging (Go-specialized), Copilot + local Ollama agents (Scout/Judge/Editor on `qwen2.5`/`qwen3`).

---

## Quick Start

### 1. Requirements

- **Neovim 0.12.0+**
- **Core tools (required):** `git`, `rg` (ripgrep), `fd`
- **Build toolchain:** `build-essential` (or `base-devel`), C compiler for Treesitter
- **Language tooling (optional, `$PATH`):** `gopls`, `lua-language-server`, `pyright`, `typescript-language-server`, `rust-analyzer`, `jdtls`, `terraform-ls`, `yaml-language-server`, `stylua`, `black`, `shfmt`, `prettier`

### 2. Installation & Setup

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone and launch nvimz
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
cd ~/.config/nvim

# Pick a mode:
./scripts/setup --minimal        # interactive minimal install
./scripts/setup --full           # full default environment (Go, Rust, Python, Java, Node)
./scripts/setup --langs=go,lua,rust  # only selected languages
```

The setup script handles OS detection (macOS, Arch, Ubuntu), toolchain install via `scripts/lang/` + `scripts/lib/`, and shell configuration.

### 3. Update & Maintain

```bash
./scripts/manage --sync    # sync system packages
./scripts/manage --update  # update plugins (relock + validate)
./scripts/manage --report  # regenerate MAINTENANCE_REPORT.md
./scripts/manage --all     # all tasks
./scripts/doctor           # environment health check
```

Or from inside Neovim: `:PackSync`, `:PackUpdate`, `:PackStatus`, `:PackDoctor`, `:ToolDoctor`, `:PackBenchmark`, `:PackRollback`, `:PackClean`, `:PackSnapshot`, `:PackReport`, `:ParsersUpdate`. See [Commands Reference](docs/commands.md).

---

## Structure

```
init.lua                 # records start time -> require("runtime")
lua/
  runtime/               # bootstrap (0.12 check), loader (vim.loader), phases, events (:License)
  core/                  # options, keymaps (<Space> leader), autocmds, commands, filetypes
  features/              # interface/ (theme, statusline, dashboard), lsp/, editing/, search/pick, git, format, dap, ai
  infra/                 # registry/ (plugins, languages, tools), deps/ (sync/update/rollback), health/, cache/, report/, treesitter/
  machine/               # host-local overrides (copy example.lua -> local.lua, gitignored)
scripts/                 # setup, manage, doctor, parsers, lang/, lib/
queries/                 # decoupled Treesitter queries
docs/                    # architecture, performance, commands, languages
snapshots/               # :PackSnapshot output
nvim-pack-lock.json      # pinned plugin revisions
```

---

## Language Support

Pre-wired in `lua/infra/registry/languages.lua` (binaries must be in `$PATH`):

| Language | LSP | Formatter |
| --- | --- | --- |
| Go | `gopls` | `gofmt` |
| Lua | `lua-language-server` | `stylua` |
| Python | `pyright` | `black` |
| Java | `jdtls` | `google-java-format` |
| JavaScript / TypeScript | `typescript-language-server` | `prettier` (system) |
| Rust | `rust-analyzer` | `rustfmt` |
| Terraform / HCL | `terraform-ls` | `terraform fmt` |
| YAML | `yaml-language-server` | system |
| JSON | `vscode-json-language-server` | system |
| Markdown | `marksman` | system |

Add a server/formatter by extending `M.lsp_servers` / `M.formatters_by_ft` in that file. Full guide: [Language Support](docs/languages.md).

---

## Customization

Host-specific paths (Python/Node, etc.) without polluting the repo:

```bash
cp lua/machine/example.lua lua/machine/local.lua
```

`local.lua` is gitignored.

---

## Documentation

* [Architecture & Design Details](docs/architecture.md)
* [Performance & Initialization Optimizations](docs/performance.md)
* [Native Commands & Keybindings Reference](docs/commands.md)
* [Language Support & LSP/Formatter Extensibility](docs/languages.md)

---

## License

MIT © [andev0x](https://github.com/andev0x)
