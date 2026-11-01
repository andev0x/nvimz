# Performance

This document details the optimizations and performance-focused design of **nvimz**, targeting a sub-10ms empty-startup time and ultra-low runtime latency.

## Key Performance Vectors

### 1. Zero-Mason Native-First Architecture
Unlike traditional Neovim setups that rely on the Mason plugin for runtime tool management, **nvimz** expects all external language servers, formatters, and compilers to be pre-installed in the system `$PATH`.
* **Zero Boot Overhead:** Completely removes runtime shell executions and system calls that third-party managers run during Neovim initialization to check for missing binaries.
* **Deterministic Native Resolution:** Resolves tools using highly optimized OS native lookup routines (the system path cache).

### 2. Phase-Driven Event Loading (Sub-10ms Empty-Startup Target)
By delaying the loading of resource-heavy features (like LSP, Tree-sitter, theme renderers, and debugging scopes) to specific post-boot stages, the editor's initial view renders almost instantaneously:
* **Deferred UI and Core:** After `VimEnter`, `vim.defer_fn(..., 0)` loads Phase 1 (theme, icons, statusline, scope line, Tree-sitter, LSP setup, editing, picker, Git).
* **Deferred Tooling:** Phase 2 loads formatting and DAP on the same deferred `VimEnter` path.
* **Lazy AI:** Phase 3 (AI chat and Copilot) is not loaded until the first `InsertEnter`.
* **FileType-Triggered Rendering:** Markdown rendering is loaded only for `FileType=markdown`.

### 3. No Telemetry Cache
nvimz does not serialize session state. Startup timing is measured on demand, machine overrides are read directly from `lua/machine/local.lua`, and no file is written during startup. This removes a per-session JSON read/write and a second source of truth for configuration.

### 4. Ahead-of-Time Tree-sitter Compilation
Instead of relying on the CPU-intensive and unpredictable runtime compilations of downstream plugins, **nvimz** handles syntax parsing at the infrastructure layer:
* **Local Ahead-of-Time (AOT) Compiling:** The 16 required parsers are compiled directly on the local system toolchain via `scripts/parsers`. Revisions are pinned where upstream provides a stable tag; a few track an upstream branch.
* **Decoupled Performance-Tuned Queries:** Parsers use a static query mapping from the project root `queries/` directory. This decouples parsing performance from Neovim's core runtime paths and avoids breaking modifications from upstream plugin updates.

### 5. Unified Ecosystem & Zero Bloat
Replacing a fragmented ecosystem of individual plugins with the integrated, highly optimized `mini.nvim` library leads to significant savings:
* **Single-Engine Execution:** Reduces the Lua namespace footprint, meaning fewer module cache lookups, lower garbage collection overhead, and unified key bindings.
* **Native LSP Attachments:** Rather than calling complex, multi-layered wrapper libraries, the LSP architecture uses Neovim's native, highly optimized `vim.lsp.start` APIs for asynchronous non-blocking server attachments.
* **Native Packaging:** Plugin install, update, review, rollback, deletion, and lockfile handling are `vim.pack` operations. nvimz only supplies the declarations and two small command helpers.

---

## Measuring & Auditing Performance

Performance in **nvimz** is not assumed; it is measured and audited deterministically.

### Recorded Measurements
Measured on the maintainer's machine (Neovim 0.12.6, macOS 27 / arm64). Acceptance re-measurement on 2026-11-01:

| Metric | Value |
| --- | --- |
| First render (`init.lua` → `VimEnter`, headless, n=10) | median 6.64 ms (range 6.26 – 6.97) |
| `--startuptime` `NVIM STARTED` (warm, n=10) | median 9.87 ms (range 8.98 – 13.29; first run 13.29) |
| Cold bytecode cache `NVIM STARTED` (isolated, n=5) | median 10.99 ms (range 10.00 – 15.13; first run 15.13) |
| Phase 1 complete (deferred UI + core, n=5) | median 22.2 ms (range 21.2 – 23.9) |
| Phase 1 + phase 2 complete (format/DAP loaded, polled, n=5) | median 33.2 ms (range 30.9 – 34.5) |
| Config load (`require("runtime")`) | ~1.7 ms |

The two phase figures are different boundaries: the ~22 ms checkpoint is after phase 1 but before `features.format`/`features.dap` finish loading; ~33 ms is when both phase-2 modules are loaded. The deferred-timer probe that produced the old ~23 ms figure measured the phase-1 checkpoint, not phase 1 + phase 2 (verified: DAP is not yet loaded at that point). Do not compare any of these with the `NVIM STARTED` figure.

These figures are for an empty startup. Opening a file adds native filetype detection, ftplugin, and syntax work before `VimEnter`: measured headless first-buffer times were ~13 ms for Lua and ~18 ms for Markdown. That is native editor work retained deliberately (see D11 in `docs/architecture/runtime-decisions.md`), not config loading.

The `NVIM STARTED` figure includes Neovim's native runtime plugin loading (matchit, editorconfig, `:Man`, OSC52), filetype detection, and its plugin script set. An earlier build reported ~5.4 ms by skipping those native steps; that number is not comparable. Full methodology and limitations: `docs/audit/runtime-baseline.md`.

### Native Benchmark Command
Run **`:NvimzBenchmark`** to measure three consecutive starts and list the ten slowest sourced modules. It does not delete the bytecode cache (`~/.cache/nvim/luac`) and does not keep history.

### Health Checks
* `:checkhealth nvimz` — tools, servers, formatters, parsers, plugins, machine config.
* `:checkhealth vim.pack` — native packaging and lockfile diagnostics.
* `./scripts/doctor` — shell-only tool and parser check.
