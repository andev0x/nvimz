# Performance

This document details the optimizations and performance-focused design of **nvimz**, targeting a sub-10 ms cold core start (`init.lua` → `VimEnter`, empty session) and ultra-low runtime latency.

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
  line and git signs on the first cursor movement in a real editing buffer (the dashboard's
  programmatic cursor placement is ignored), conform on the first write, LSP on the first code
  `FileType` (or `:Lsp*`), and Oil from its key, `:Oil`, or a directory startup.
* **Tier 3 — on demand:** DAP on the first `<leader>d*`/`:Dap*`, gp on the first AI key/`:Gp*`,
  Copilot only on `<leader>at`/`:Copilot`, Markdown for listed Markdown files (plugin-owned
  `nofile` floats such as an LSP hover are excluded), and the picker on its key.
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
| Empty session modules (idle, 600 ms) | 38 at `VimEnter`; 166 after phase 2 | **43 headless / 65 live UI** |
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

The dashboard banner (`󱐋`) shows the same cold core boundary. `runtime/phases.lua` records
`_G.nvimz_core_ms` when `VimEnter` fires, before Tier 1, and the value is frozen for the rest of
the session. Native startup before `init.lua` is outside Lua's visibility, so the banner is lower
than the PTY first-content figures above. Reopening the dashboard shows the frozen startup value,
not session uptime.

Gate C (2026-11-02) validated the result in real terminal sessions and found two startup
activations that headless probes missed: the dashboard's cursor placement loaded the git/scope
chunk, and an LSP hover loaded the whole Markdown renderer. Both are fixed. Spot checks after the
fixes: empty dashboard **40.7 ms**, Lua **45.2 ms**, Go **47.8 ms**, Markdown **61.4 ms** first
content (n=5), `NVIM STARTED` **10.44 ms**, and headless `VimEnter` **7.59 ms**. A live empty
dashboard settles at **65 modules / 27.0 MiB** (the 43-module figure is headless). A 30-second
editing soak stayed at 0% idle with no AI/DAP/Markdown/Oil/conform modules.

The cold target uses the same core boundary with a fresh bytecode cache:
`XDG_CACHE_HOME=$(mktemp -d) nvim --headless` with a `VimEnter` probe (n=10). The config does not
enable `vim.loader`: a fresh cache made it compile the startup modules before the first buffer,
costing **~3 ms**, and removing it made warm startup equal or slightly faster. Measured cold core
init is **8.3 ms median** (7.8–9.0 ms) and cold `NVIM STARTED` is **9.7 ms median** (9.2–11.0 ms);
with `vim.loader` enabled the same cold runs were **11.7 ms** (10.8–16.1 ms) for core init and
**12.8 ms** (11.9–12.9 ms) for `NVIM STARTED`. Warm core init and warm first content are unchanged
within noise. The first start on a machine with a cold OS page cache is outside this boundary.

Full evidence, feature-activation costs, input-latency tables, and limitations:
`docs/audit/progressive-performance-final-report.md`. Gate C details:
`docs/audit/progressive-performance-gate-c-report.md`.

### Native Benchmark Command
Run **`:NvimzBenchmark`** to measure three consecutive warm `NVIM STARTED` samples and list the
ten slowest sourced modules. It does not keep history. The cold core target is verified with an
isolated `XDG_CACHE_HOME` and a `VimEnter` probe, as above.

### Health Checks
* `:checkhealth nvimz` — tools, servers, formatters, parsers, plugins, machine config.
* `:checkhealth vim.pack` — native packaging and lockfile diagnostics.
* `./scripts/doctor` — shell-only tool and parser check.
