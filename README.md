# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

**nvimz** is a high-performance Neovim setup optimized for **Neovim 0.12+** that prioritizes speed, structural simplicity, and developer experience. With a strict startup target under **10ms** (measured ~7–9 ms to first render on an empty startup on the maintainer's machine), it replaces heavy plugin ecosystems with native APIs, the lightweight `mini.nvim` suite, and the built-in `vim.pack` package manager.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Neovim](https://img.shields.io/badge/Neovim-%3E=0.12.0-blueviolet?logo=neovim)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/andev0x/nvimz)

---

## At a Glance

| | |
| --- | --- |
| **Startup target** | `< 10ms` (warns above it) |
| **Plugins** | 12, pinned in `nvim-pack-lock.json` |
| **Plugin manager** | Built-in `vim.pack` |
| **Leader key** | `<Space>` |
| **LSP servers** | 10 pre-wired (binaries resolved from `$PATH`) |
| **Treesitter parsers** | 16 required, compiled ahead of time |
| **License** | MIT |

---

## Philosophy: Zero-Mason, Native-First

Unlike heavy configurations that rely on Mason for runtime isolation, **nvimz** expects language servers and formatters to be pre-installed in your system `$PATH`. This aligns with infrastructure-as-code and deterministic dotfile management:

- **Predictable & Reproducible:** Environment managed by your system package manager (`Homebrew`, `Nix`, `APT`) or `./scripts/setup`.
- **Zero Startup Overhead:** No third-party manager checks binaries at startup. Core init loads only `core` files and registers the deferred phase triggers.
- **Native-First Stability:** Uses Neovim 0.12+ built-ins (`vim.lsp`, `vim.pack`, `vim.treesitter`, `vim.diagnostic`) to reduce plugin surface to 12 pinned plugins.
- **Phase-Driven Loading:** 3-phase `vim.pack` loading keeps the initial path unblocked (`lua/runtime/phases.lua`):
    1. **Phase 1 — UI + Core (`VimEnter`, deferred):** Theme, icons, statusline, scope line, Treesitter, LSP, `oil.nvim`, `mini.*` editing, native picker, Git.
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

- **Ultra-Fast (~7–9 ms to first render on an empty startup):** `vim.loader` bytecode cache, deferred `VimEnter` phases, lazy `FileType`/`InsertEnter` triggers. Warns if startup exceeds 10ms. Verify with `:NvimzBenchmark`.
- **12 Pinned Plugins via `vim.pack`:** `tokyonight`, `mini.nvim`, `render-markdown`, `oil.nvim` + `oil-git-status`, `conform.nvim`, `nvim-dap` + `nvim-dap-ui` + `nvim-nio` + `nvim-dap-go`, `gp.nvim`, `copilot.lua`. Locked in `nvim-pack-lock.json`.
- **Power-user Workflows:** Native floating picker (files, hidden files, live grep, gitignored grep, buffers), `oil.nvim` directory explorer, floating/bottom terminals, `mini.git` status/blame + `mini.diff` overlay.
- **Native Code Intelligence:** `vim.lsp` with inlay hints, auto diagnostics on `CursorHold`, `mini.completion`, Treesitter parsers compiled AOT from source via `scripts/parsers` (decoupled `queries/`).
- **Advanced Features:** DAP debugging (Go-specialized), Copilot + local Ollama agents (`Scout`, `Judge`, `Editor`).

---

## Quick Start

### 1. Requirements

- **Neovim 0.12.0+**
- **Core tools (required):** `git`, `rg` (ripgrep), `fd`
- **Build toolchain:** C compiler for Treesitter (`build-essential` on Debian/Ubuntu, `base-devel` on Arch, Xcode Command Line Tools on macOS)
- **Language tooling (optional, must be in `$PATH`):**
  - **Go:** `gopls`, `dlv`
  - **Lua:** `lua-language-server`, `stylua`
  - **Python:** `pyright`, `black`
  - **JavaScript / TypeScript:** `typescript-language-server`
  - **Rust:** `rust-analyzer`
  - **Java:** `jdtls`, `google-java-format`
  - **Terraform / HCL:** `terraform-ls`, `terraform`
  - **YAML / JSON / Markdown:** `yaml-language-server`, `vscode-json-language-server`, `marksman`
  - **Shell:** `shfmt`

### 2. Installation & Setup

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone and launch nvimz
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
cd ~/.config/nvim

# Pick a mode:
./scripts/setup --minimal                 # interactive minimal install
./scripts/setup --full                    # full default environment (Go, Rust, Python, Node, Java)
./scripts/setup --langs=go,rust,python    # only selected languages
```

Provisioning scripts are available for `go`, `java`, `node`, `python`, and `rust`. The setup script handles OS detection (macOS, Arch, Debian/Ubuntu) and toolchain install via `scripts/lang/` + `scripts/lib/`.

### 3. Verify the Install

Launch Neovim and run:

```vim
:checkhealth nvimz      " tools, servers, formatters, parsers, plugins
:checkhealth vim.pack   " packaging and lockfile
:NvimzBenchmark         " startup timing
```

From a shell, `./scripts/doctor` checks required tools and Treesitter parsers.

### 4. Update & Maintain

```bash
./scripts/manage --sync    # sync system packages
./scripts/manage --update  # update plugins (native vim.pack) and rebuild parsers
./scripts/manage --all     # update plugins + sync system packages
./scripts/doctor           # environment health check
```

Or from inside Neovim: `:PackUpdate`, `:PackRollback`, `:PackStatus`, `:PackClean`, `:NvimzBenchmark`, `:ParsersUpdate`, `:License`. See the [Commands Reference](docs/commands.md).

---

## Keybindings

Leader is `<Space>`. The full reference lives in [docs/commands.md](docs/commands.md).

### Core & Navigation

| Key | Action |
| --- | --- |
| `<leader>w` | Write buffer |
| `<leader>qq` | Quit window |
| `<leader>h` | Clear search highlight |
| `<leader>ds` | Open dashboard |
| `<leader>bd` / `bn` / `bp` | Delete / next / previous buffer |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | Move between windows |
| `<C-d>` / `<C-u>` | Scroll and center |
| `<leader>z` | Toggle fold |
| `<leader>mj` / `<leader>mk` | Move line down / up |
| `J` / `K` (Visual) | Move selection down / up |

### Files, Search & Clipboard

| Key | Action |
| --- | --- |
| `<leader>e` | Toggle `oil.nvim` floating explorer |
| `<leader>ff` | Find files |
| `<leader>fe` | Find files (including hidden) |
| `<leader>fg` | Live grep |
| `<leader>fr` | Live grep (including gitignored) |
| `<leader>fb` | List buffers |
| `<leader>cp` / `cP` / `cn` / `cd` | Copy relative path / absolute path / filename / directory |

The dashboard uses single keys: `f` find files, `g` live grep, `e` file explorer, `q` quit.

### Splits & Terminals

| Key | Action |
| --- | --- |
| `<leader>sv` / `<leader>sh` | Vertical / horizontal split |
| `<leader>se` | Equalize splits |
| `<leader>rh` / `rl` / `rj` / `rk` | Resize windows |
| `<leader>tt` / `<leader>tb` | Toggle floating / bottom terminal |
| `<Esc><Esc>` (Terminal) | Exit terminal mode |

### LSP & Formatting

| Key | Action |
| --- | --- |
| `gd` / `gD` | Go to definition / declaration |
| `K` | Hover documentation |
| `gl` | Line diagnostics float |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>fm` | Format buffer |
| `<leader>uh` | Toggle inlay hints |

### Git, Debug & AI

| Key | Action |
| --- | --- |
| `<leader>gs` / `<leader>gb` | `mini.git` status / blame |
| `<leader>gd` | Toggle `mini.diff` overlay |
| `<leader>db` / `dc` | Toggle breakpoint / continue |
| `<leader>di` / `do` / `du` | Step into / over / out |
| `<leader>dr` / `<leader>dt` | DAP REPL / debug Go test |
| `<leader>aa` | Toggle AI chat (`gp.nvim`) |
| `<leader>a1` / `a2` / `a3` | Switch Ollama agent: Scout / Judge / Editor |
| `<leader>at` | Toggle Copilot |
| `<leader>ar` / `ap` / `ab` (Visual) | AI rewrite / append / prepend |
| `<A-CR>` | Send AI chat prompt |
| `<M-S-right>` / `<M-]>` / `<M-[>` / `<C-]>` | Copilot accept / next / previous / dismiss |

---

## Structure

```
init.lua                 # records start time -> require("runtime")
lua/
  runtime/               # bootstrap (0.12 check), vim.loader, phase triggers, startup warning
  core/                  # options, keymaps (<Space> leader), autocmds, commands, filetypes
  features/              # interface/ (theme, statusline, dashboard, scope line), lsp/, editing/,
                         # search/pick, git, format, dap, ai
  nvimz/
    config/              # plugins, languages, tools, parsers (static declarations)
    picker/              # native fuzzy picker implementation
    health.lua           # :checkhealth nvimz provider
    packages.lua         # status/clean helpers over vim.pack
    benchmark.lua        # :NvimzBenchmark
    treesitter.lua       # native Treesitter + folds
    ui.lua               # scratch report buffers
  machine/               # host-local overrides (copy example.lua -> local.lua, gitignored)
scripts/                 # setup, manage, doctor, parsers, lang/, lib/
queries/                 # decoupled Treesitter queries
ftplugin/                # per-filetype overrides (Java)
docs/                    # architecture, performance, commands, languages, audit/
nvim-pack-lock.json      # pinned plugin revisions
```

---

## Language Support

Pre-wired in `lua/nvimz/config/languages.lua` (binaries must be in `$PATH`). Format-on-save only runs for filetypes listed in `M.formatters_by_ft`:

| Language | LSP | Formatter |
| --- | --- | --- |
| Go | `gopls` | `gofmt` |
| Lua | `lua-language-server` | `stylua` |
| Python | `pyright` | `black` |
| Java | `jdtls` | `google-java-format` |
| JavaScript / TypeScript | `typescript-language-server` | — |
| Rust | `rust-analyzer` | — |
| Terraform / HCL | `terraform-ls` | `terraform fmt` |
| YAML | `yaml-language-server` | — |
| JSON / JSONC | `vscode-json-language-server` | — |
| Markdown | `marksman` | — |
| Shell (`sh`/`bash`/`zsh`) | — | `shfmt` |

Add a server in `M.lsp_servers`, or a formatter in `M.formatters_by_ft` / `M.formatter_binaries`, in that file. Full guide: [Language Support](docs/languages.md).

---

## Customization

Host-specific paths (such as the Python host) without polluting the repo:

```bash
cp lua/machine/example.lua lua/machine/local.lua
```

`local.lua` is gitignored.

Common extension points:

- `lua/core/keymaps.lua` — personal keybindings
- `lua/core/options.lua` — editor options
- `lua/nvimz/config/plugins.lua` — plugin list and load phases
- `lua/nvimz/config/languages.lua` — LSP servers, formatters, icons
- `lua/nvimz/config/parsers.lua` — Treesitter parser pins

---

## Health & Troubleshooting

nvimz does **not** install language servers or formatters at runtime. If a feature does not start, check that the binary exists on your `$PATH`. Inside Neovim:

```vim
:checkhealth nvimz      " core tools, servers, formatters, parsers, plugins
:checkhealth vim.pack   " lockfile and plugin directory
:PackStatus             " quick plugin and tool summary
:LspInfo                " attached clients and their status
:LspLog                 " open the LSP log
:LspStart / :LspStop / :LspRestart
```

From a shell, `./scripts/doctor` checks required tools and installed Treesitter parsers. Use `:ParsersUpdate` to rebuild parsers after upgrading Neovim or the parser pins.

Startup slower than expected? Run `:NvimzBenchmark`; it measures three consecutive starts and lists the slowest sourced modules. It never deletes the bytecode cache (`~/.cache/nvim/luac`).

---

## Documentation

- [Architecture & Design Details](docs/architecture.md)
- [Performance & Initialization Optimizations](docs/performance.md)
- [Native Commands & Keybindings Reference](docs/commands.md)
- [Language Support & LSP/Formatter Extensibility](docs/languages.md)

---

## License

MIT © [andev0x](https://github.com/andev0x)
