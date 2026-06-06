# Architecture

This document describes the design principles, loading pipeline, and internal file and module structure of **nvimz**.

## Core Design Principles

**nvimz** is designed as a native-first, zero-bloat Neovim configuration. It optimizes performance and maintainability by adhering to the following rules:

1. **System-Managed Dependencies:** Language servers, formatters, and compilers are expected to be available on your system `$PATH` rather than isolated inside Neovim via third-party managers like Mason.
2. **Ecosystem Unification:** Prefers the cohesive, lightweight `mini.nvim` suite over numerous single-purpose plugins to reduce API fragmentation.
3. **Local Compilation:** Tree-sitter parsers are pinned and compiled locally from source to guarantee syntax stability.

---

## Phase-Driven Loading Pipeline

To achieve a sub-20ms startup time, **nvimz** employs a strategic 3-phase loading mechanism. This ensures that the core initialization path (processing keymaps, basic options, and the first render) is never blocked by plugin setup.

```
[Startup] -> Load Core Config -> First Screen Render
                                      │
          ┌───────────────────────────┴───────────────────────────┐
          ▼                                                       ▼
    (Idle Event)                                            (File Access)
    [Phase 1: UI]                                        [Phase 2: Editing]
    Theme, Icons, Statusline                             LSP, Formatting, Treesitter
                                                                  │
                                                                  ▼
                                                          (User Interaction)
                                                          [Phase 3: Extra]
                                                          DAP, AI, Git, Terminal
```

### 1. UI Phase
Deferred to the first idle period (`User` event after startup).
* **Modules:** Theme (`mini.colors`/`theme`), Icons (`mini.icons`), Statusline (`statusline.lua`), Dashboard (`dashboard.lua`).
* **Goal:** Deliver an immediate visual response without blocking editor responsiveness.

### 2. Editing Phase
Triggered dynamically by file access (`BufReadPost`, `BufNewFile`).
* **Modules:** LSP client (`vim.lsp`), Tree-sitter highlighting, auto-completion (`completion.lua`), formatting (`conform.nvim`).
* **Goal:** Prepare the editor for writing and navigating code as soon as a buffer is loaded.

### 3. Extra Phase
Triggered lazily by explicit user interaction or command execution.
* **Modules:** Interactive debugging (`nvim-dap`), AI utilities (`gp.nvim`, GitHub Copilot), Git integration (`mini.git`, `mini.diff`), terminal scratchpads (`terminal.lua`).
* **Goal:** Keep advanced development tools completely unloaded until needed.

---

## Centralized Package Management

**nvimz** bypasses standard plugin managers in favor of Neovim's built-in package system (`packpath`), orchestrated via custom scripts in `scripts/` and configuration in `lua/infra/deps/`.

### Orchestration Layer

The package management logic is split into a robust command-line interface and a Lua configuration layer:

* **`scripts/manage`:** The entrypoint for all updates, synchronization, and diagnostic actions. It supports updating plugins, syncing system packages, and gathering benchmark audits.
* **`lua/infra/deps.lua`:** The declaration file for external packages. This module handles runtime loading, validation, and snapshotting of plugins.
* **`scripts/parsers`:** Compiles pinned Tree-sitter parsers directly from source and syncs optimized queries to the root `queries/` directory.
* **`scripts/setup`:** A universal bootstrapping script that detects the host operating system, configures required toolchains, and installs runtime dependencies.

### Key Orchestration Features

* **Deterministic Updates:** Plugins are updated via `git reset --hard` to their pinned remote default branches or specific lockfile revisions.
* **Decoupled Queries:** Tree-sitter queries are maintained directly in the root `queries/` directory, preventing upstream plugin updates from breaking custom syntax highlights.
* **System Auditing:** After any update or maintenance pipeline run, a comprehensive report is generated in `MAINTENANCE_REPORT.md` detailing start-up telemetry, plugin integrity, and system tools health.

---

## Customization & Local Overrides

**nvimz** provides a clean extension interface designed to separate shared configuration from host-specific environments.

### Local Machine Overrides

Host-specific overrides (such as localized Python/Node executable paths) are declared in `lua/machine/local.lua`. This file is ignored by Git, allowing you to tailor settings on individual work or personal machines without polluting the shared repository.

An example configuration file is provided in `lua/machine/example.lua`:

```lua
return {
    -- Override executable paths
    python_path = "/usr/bin/python3",
}
```

To create your local configuration manually:

```bash
cp lua/machine/example.lua lua/machine/local.lua
```
