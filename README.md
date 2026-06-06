# nvimz

> A blazing-fast, minimalist Neovim configuration for DevOps engineers and backend developers.

**nvimz** is a high-performance Neovim setup optimized for **Neovim 0.12+** that prioritizes speed, structural simplicity, and developer experience. With a strict startup target under **20ms**, it replaces heavy plugin ecosystems with native APIs, the lightweight `mini.nvim` suite, and the built-in `vim.pack` package manager.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Neovim](https://img.shields.io/badge/Neovim-%3E=0.12.0-blueviolet?logo=neovim)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://github.com/andev0x/nvimz)

---

## Philosophy: Zero-Mason, Native-First

Unlike heavy configurations that rely on Mason for runtime isolation, **nvimz** expects language servers and formatters to be pre-installed in your system `$PATH`. This aligns perfectly with modern infrastructure-as-code and deterministic dotfile management:

- **Predictable & Reproducible:** Your development environment is managed deterministically by your system's package manager (`Homebrew`, `Nix`, `APT`).
- **Zero Startup Overhead:** Eliminates execution delays caused by third-party managers checking binaries at startup.
- **Native-First Stability:** Leverages Neovim 0.12+ built-in features to drastically reduce plugin surface area and minimize breaking changes.
- **Phase-Driven Loading:** Strategic 3-phase loading ensures the core initialization path remains completely unblocked:
    1. **UI Phase:** Deferred to the first idle period (Theme, Icons, Statusline).
    2. **Editing Phase:** Triggered by file access (LSP, Formatting).
    3. **Extra Phase:** Triggered by user interaction (DAP, AI, Git).

---

## Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz1.png" width="350" alt="nvimz workspace display" />
  <img src="https://raw.githubusercontent.com/andev0x/description-image-archive/refs/heads/main/nvimz/nvimz2.png" width="350" alt="nvimz file explorer display" />
</p>

---

## Highlights

- **Ultra-Fast Performance:** Achieves <20ms startup times via dynamic event caching and a deferred, 3-phase lazy loading pipeline.
- **Unified Ecosystem:** Eliminates plugin bloat by substituting heavy external dependency chains with the lightweight, unified `mini.nvim` suite.
- **Power-user Workflows:** Out-of-the-box support for a fuzzy finder (`mini.pick`), fluid directory explorer (`mini.files`), floating/split terminals, and built-in Git staging/blaming.
- **Native Code Intelligence:** Clean diagnostic hovers, LSP inlay hints, and smart completions, powered natively without third-party abstraction layers.
- **Advanced Features:** Interactive DAP-driven debugging, Copilot integration, and deep Local AI/Ollama chat windows.

---

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

---

## Documentation

For deep-dives into the internals, performance optimizations, custom tooling commands, and language support, refer to the dedicated guide files:

* [Architecture & Design Details](docs/architecture.md)
* [Performance & Initialization Optimizations](docs/performance.md)
* [Native Commands & Keybindings Reference](docs/commands.md)
* [Language Support & LSP/Formatter Extensibility](docs/languages.md)

---

## License

MIT © [andev0x](https://github.com/andev0x)
