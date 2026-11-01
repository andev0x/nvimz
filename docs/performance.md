# Performance

This document details the optimizations and performance-focused design of **nvimz**, targeting a sub-10ms empty-startup time and ultra-low runtime latency.

## Key Performance Vectors

### 1. Zero-Mason Native-First Architecture
Unlike traditional Neovim setups that rely on the Mason plugin for runtime tool management, **nvimz** expects all external language servers, formatters, and compilers to be pre-installed in the system `$PATH`.
* **Zero Boot Overhead:** Completely removes runtime shell executions and system calls that third-party managers run during Neovim initialization to check for missing binaries.
* **Deterministic Native Resolution:** Resolves tools using highly optimized OS native lookup routines (the system path cache).

### 2. Progressive Loading (Tiered, Event-Driven)
Initialization is split by what the first screen actually needs. There is no timer chain and no
background scheduler:

* **Tier 0 — core (synchronous):** options, keymaps, commands, and the event handlers. No plugin
  setup or subprocess.
* **Tier 1 — first render (synchronous at `VimEnter`):** tokyonight, mini.nvim, theme, icons,
  statusline, first-buffer Treesitter, the dashboard when no file was given, and Markdown
  rendering when the first buffer is Markdown. The native intro screen is never shown.
* **Tier 2 — normal editing (event-driven):** pairs/completion on the first `InsertEnter`, scope
  line and git signs on the first cursor movement, conform on the first write, LSP on the first
  code `FileType` (or `:Lsp*`), and Oil from its key, `:Oil`, or a directory startup.
* **Tier 3 — on demand:** DAP on the first `<leader>d*`/`:Dap*`, gp on the first AI key/`:Gp*`,
  Copilot only on `<leader>at`/`:Copilot`, Markdown for later buffers, and the picker on its key.
* **No Tier 4:** no idle queue, warm-up, periodic timer, or speculative preload.

The former `InsertEnter` AI phase is gone: gp and Copilot are never loaded by inserting text.


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
Measured on the maintainer's machine (Neovim 0.12.6, macOS 27 / arm64). Gate B re-measurement
(2026-11-02) uses the same boundaries as `docs/audit/progressive-performance-baseline.md`:

| Metric | Before (Gate A) | After (Gate B) |
| --- | --- | --- |
| Core init → start of `VimEnter` (n=3) | 6.23–8.18 ms | 6.67–8.15 ms |
| Headless `VimEnter` complete (n=10) | 6.73 ms median | 7.75 ms median (includes headless Tier 1) |
| `--startuptime` `NVIM STARTED` (warm, n=10) | 10.10 ms median (batch A) | 10.25 ms median |
| Empty dashboard first paint (n=5) | 70.7 ms | **44.2 ms** |
| Native intro shown before dashboard | 34.6 → 70.7 ms | **never** |
| Lua file first content (n=5) | 43.8 ms | 44.6 ms |
| Go file first content (n=5) | 41.4 ms | 50.2 ms |
| Markdown first content (n=5) | 52.3 ms | 63.2 ms |
| Empty session modules (idle, 600 ms) | 38 at `VimEnter`; 166 after phase 2 | **43** |
| Lua session modules | 192 after phase 2 | **101** |
| Go session modules | 191 after phase 2 | **100** |
| Markdown session modules | 231 after phase 2 | **160** |
| Empty process-tree RSS (1.2 s) | 30.1–30.3 MiB | **26.4–26.7 MiB** |
| Lua session tree RSS | 108.6–109.7 MiB | 105.2–110.4 MiB |
| Go session tree RSS | 156.7–251.6 MiB | 153.9–154.1 MiB |
| Normal Lua editing (insert, no AI) | ~370 MiB (auto gp+Copilot + lua_ls) | **110.6–113.2 MiB** |
| Explicit Copilot activation + insert | ~370 MiB tree | 408.1–415.8 MiB (opt-in only) |

The Go and Markdown first-content numbers are later by design: Treesitter must pick up the first
Go buffer and render-markdown must render the first Markdown buffer before the first paint,
otherwise the user would see a visible highlight/layout switch. Empty and Lua first paint improved
or stayed flat. Tier 1 itself measures 9.0–9.6 ms (empty), 6.9 ms (Lua), 10.3–11.0 ms (Go), and
16.1–17.7 ms (Markdown); the 10 ms objective is met for empty/Lua and intentionally exceeded for
the two first-buffer correctness cases.

`NVIM STARTED` includes Neovim's native runtime plugin loading, filetype detection, and its own
plugin scripts; it is not the same boundary as the config timings above. Do not compare it with a
Lua-only measurement.

Full evidence, feature-activation costs, input-latency tables, and limitations:
`docs/audit/progressive-performance-final-report.md`.

### Native Benchmark Command
Run **`:NvimzBenchmark`** to measure three consecutive starts and list the ten slowest sourced modules. It does not delete the bytecode cache (`~/.cache/nvim/luac`) and does not keep history.

### Health Checks
* `:checkhealth nvimz` — tools, servers, formatters, parsers, plugins, machine config.
* `:checkhealth vim.pack` — native packaging and lockfile diagnostics.
* `./scripts/doctor` — shell-only tool and parser check.
