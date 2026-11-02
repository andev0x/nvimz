# Installation & Setup

**nvimz** targets Neovim 0.12.0+ and treats language tooling as a system dependency. No language servers or formatters are installed into Neovim at runtime; every binary must be available on your `$PATH`.

## Requirements

- **Neovim 0.12.0+**
- **Core tools (required):** `git`, `rg` (ripgrep), `fd`
- **Build toolchain:** a C compiler for Treesitter (`build-essential` on Debian/Ubuntu, `base-devel` on Arch, Xcode Command Line Tools on macOS)

Language tooling is optional and only needed for the languages you use:

| Language | Tools |
| --- | --- |
| Go | `gopls`, `dlv` |
| Lua | `lua-language-server`, `stylua` |
| Python | `pyright`, `black` |
| JavaScript / TypeScript | `typescript-language-server` |
| Rust | `rust-analyzer` |
| Java | `jdtls`, `google-java-format` |
| Terraform / HCL | `terraform-ls`, `terraform` |
| YAML / JSON / Markdown | `yaml-language-server`, `vscode-json-language-server`, `marksman` |
| Shell | `shfmt` |

## Setup

Back up an existing configuration, clone the repository, and pick a provisioning mode:

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone and launch nvimz
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
cd ~/.config/nvim

# Pick a mode
./scripts/setup --minimal                 # interactive minimal install
./scripts/setup --full                    # full environment (Go, Rust, Python, Node, Java)
./scripts/setup --langs=go,rust,python    # only selected languages
```

Provisioning scripts are available for `go`, `java`, `node`, `python`, and `rust`. The setup script detects macOS, Arch, and Debian/Ubuntu, then installs the toolchain through `scripts/lang/` and `scripts/lib/`.

## Verification

Launch Neovim and run:

```vim
:checkhealth nvimz      " tools, servers, formatters, parsers, plugins
:checkhealth vim.pack   " packaging and lockfile
:NvimzBenchmark         " startup timing
```

From a shell, `./scripts/doctor` checks required tools and Treesitter parsers.

## Maintenance

```bash
./scripts/manage --sync    # sync system packages
./scripts/manage --update  # update plugins (native vim.pack) and rebuild parsers
./scripts/manage --all     # update plugins + sync system packages
./scripts/doctor           # environment health check
```

Inside Neovim, use `:PackUpdate`, `:PackRollback`, `:PackStatus`, `:PackClean`, `:NvimzBenchmark`, `:ParsersUpdate`, and `:License`. See [Commands & Keybindings](commands.md) for the full command reference.
