# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

**nvimz** is a native-first Neovim 0.12+ setup built on `vim.pack`, `vim.lsp`, and `mini.nvim`. It targets a sub-10 ms cold core start, keeps language tooling in your system `$PATH`, and ships 12 pinned plugins — no Mason, no runtime installs.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Neovim](https://img.shields.io/badge/Neovim-%3E=0.12.0-blueviolet?logo=neovim)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/andev0x/nvimz)

<p align="center">
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz1.png" width="350" alt="nvimz workspace display" />
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz2.png" width="350" alt="nvimz file explorer display" />
</p>

## Quick Start

```bash
git clone https://github.com/andev0x/nvimz.git ~/.config/nvim
cd ~/.config/nvim
./scripts/setup --minimal   # or --full, or --langs=go,rust,python
```

Open Neovim, then verify the install with `:checkhealth nvimz` and `:NvimzBenchmark`. Requirements, backup steps, and provisioning details are in [Installation & Setup](docs/install.md).

## Features

- **Fast:** ~7–9 ms cold core start on an empty session, with tiered, event-driven loading. Profile with `:NvimzBenchmark`.
- **Native:** `vim.pack`, `vim.lsp`, `vim.treesitter`, a native fuzzy picker, and the `mini.nvim` suite.
- **Focused:** 12 pinned plugins for theme, files, Git, formatting, debugging, and AI (Copilot + local Ollama).
- **Predictable:** no runtime tool installs; servers and formatters resolve from `$PATH`.
- **Extensible:** declarative plugin, language, and parser config, plus gitignored machine overrides.

## Documentation

| Title | Contents |
| --- | --- |
| [Installation & Setup](docs/install.md) | Requirements, provisioning, verification, maintenance |
| [Architecture](docs/architecture.md) | Design principles, loading pipeline, repository layout |
| [Commands & Keybindings](docs/commands.md) | Native commands and the complete keymap |
| [Language Support](docs/languages.md) | LSP servers, formatters, and extension |
| [Performance](docs/performance.md) | Startup targets and measured results |
| [Customization](docs/customization.md) | Machine overrides and extension points |
| [Troubleshooting](docs/troubleshooting.md) | Health checks and common fixes |

## License

MIT © [andev0x](https://github.com/andev0x)
