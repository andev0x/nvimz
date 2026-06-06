# Performance

This document details the optimizations and performance-focused design of **nvimz**, targeting a sub-20ms startup time and ultra-low runtime latency.

## Key Performance Vectors

### 1. Zero-Mason Native-First Architecture
Unlike traditional Neovim setups that rely on the Mason plugin for runtime tool management, **nvimz** expects all external language servers, formatters, and compilers to be pre-installed in the system `$PATH`.
* **Zero Boot Overhead:** Completely removes runtime shell executions and system calls that third-party managers run during Neovim initialization to check for missing binaries.
* **Deterministic Native Resolution:** Resolves tools using highly optimized OS native lookup routines (the system path cache).

### 2. Phase-Driven Event Loading (Sub-20ms Boot Target)
By delaying the loading of resource-heavy features (like LSP, tree-sitter, theme renderers, and debugging scopes) to specific post-boot stages, the editor initial view renders almost instantaneously:
* **UI Deferred:** The visual chrome (themes, custom highlights, custom statuslines) is rendered on the first idle callback (`User` event).
* **Buffer-Triggered Editing:** Highlighting engine and LSP servers are only spun up when a relevant text buffer is explicitly focused or created.
* **On-Demand Extra Features:** Highly complex plugin chains (AI integration, debugger engines, terminal managers) remain entirely un-imported and uninitialized until their mapped key bindings are actively pressed.

### 3. Persistent State Caching (`lua/infra/cache.lua`)
A centralized state cache records and manages key execution metrics and internal telemetry:
* **Cached Telemetry:** Telemetry metrics are preserved in-memory and persistently serialized to state files.
* **Execution Profiling:** Allows you to identify performance regressions instantly on any file-load or buffer change event without running verbose profiling flags.

### 4. Pinned Tree-sitter Compilation
Instead of relying on the CPU-intensive and unpredictable runtime compilations of downstream plugins, **nvimz** handles syntax parsing at the infrastructure layer:
* **Local Ahead-of-Time (AOT) Compiling:** Pinned parser revisions are compiled directly on the local system toolchain via `scripts/parsers`.
* **Decoupled Performance-Tuned Queries:** Parsers use a static query mapping from the project root `queries/` directory. This decouples parsing performance from Neovim's core runtime paths and avoids breaking modifications from upstream plugin updates.

### 5. Unified Ecosystem & Zero Bloat
Replacing a fragmented ecosystem of individual plugins with the integrated, highly optimized `mini.nvim` library leads to significant savings:
* **Single-Engine Execution:** Reduces the Lua namespace footprint, meaning fewer module cache lookups, lower garbage collection overhead, and unified key bindings.
* **Native LSP Attachments:** Rather than calling complex, multi-layered wrapper libraries, the LSP architecture uses Neovim's native, highly optimized `vim.lsp.start` APIs for asynchronous non-blocking server attachments.

---

## Measuring & Auditing Performance

Performance in **nvimz** is not assumed; it is measured and audited deterministically.

### Automatic Maintenance Report
Whenever you run `./scripts/manage --report` or `./scripts/manage --all`, a clean `MAINTENANCE_REPORT.md` is generated in the root of your config. This report contains:
- Exact startup performance metrics (e.g., millisecond-precise timing charts).
- System-wide environment diagnostics.
- Active plugin status validations.

### Native Benchmark Command
Inspect startup benchmarks and telemetry logs directly within Neovim:
* Run **`:PackBenchmark`** to view startup history, module load times, and execution details.
