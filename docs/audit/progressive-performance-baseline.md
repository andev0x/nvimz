# Progressive Performance Baseline

**Phase:** 0 — Reproducible baseline (Gate A)
**Date:** 2026-11-02
**Status:** Measured. No runtime code was changed for this document.
**Repository:** `/Users/anvndev/.config/nvim` @ `main` (`e24e24f`), working tree had only the pre-existing
`.gitignore` edit when measured.
**Purpose:** Record the actual startup and interactive behavior of the current nvimz runtime so the
loading plan and every later before/after claim use identical boundaries.

All values below were measured on this host, not inferred. Where a value could not be measured
reliably it is marked as such. Timings are milliseconds unless stated otherwise.

---

## 1. Environment

| Item | Value | Source |
| --- | --- | --- |
| Neovim | 0.12.6 | `nvim --version` |
| Lua runtime | LuaJIT 2.1.1793383622 | `nvim --version` |
| OS | macOS 27.0.1 (build 26A434), Darwin 27.0.0 | `sw_vers`, `uname -a` |
| CPU / memory | Apple M1 Pro (8 cores), 16 GB | `system_profiler` |
| Config root | `/Users/anvndev/.config/nvim` | `pwd` |
| Runtime files (`lua/`) | 41 files, 3,934 lines | `find`, `wc -l` |
| Plugins declared / installed | 12 / 12 | `nvim-pack-lock.json`, `vim.pack.get()` |
| Treesitter parsers | 16/16 required available | `vim.treesitter.language.inspect` sweep |
| Bytecode cache | `~/.cache/nvim/luac`, 6.6 MB, warm | `du`, `stat` |
| Shell PATH | git, rg, fd, gopls, lua-language-server, ollama, all formatters present | `command -v` |
| Other load | Background `go test` processes were running during part of the batch | `ps` |

The host was not idle during every batch. Two startup batches are reported separately in §4.1 so
the effect is visible instead of hidden.

---

## 2. Measurement boundaries

These boundaries are used in this and every later report.

| Metric | Boundary | Instrument |
| --- | --- | --- |
| Process startup | OS process start → `NVIM STARTED` in `--startuptime` | `nvim --startuptime <file> --headless -c qa` |
| Core init → VimEnter | `_G.nvimz_start_time` (first line of `init.lua`) → `VimEnter` autocmd | headless probe registered with `-c` |
| First terminal output | process start → first byte written to a PTY | PTY capture (§2.1) |
| First themed paint | process start → first truecolor SGR sequence | PTY capture |
| First buffer content | process start → first file-content token drawn | PTY capture |
| First dashboard paint | process start → dashboard text drawn | PTY capture |
| Phase 1 complete | all UI/core phase modules present in `package.loaded` | 1 ms polling probe from `VimEnter` |
| Phase 2 complete | `features.format` and `features.dap` present | same probe |
| Input processing | PTY key write → `vim.on_key` callback (`gettimeofday` epoch) | `vim.on_key` probe + PTY |
| Feature activation | cold `require` + `setup()` in an isolated `nvim --headless -u <minimal>` | Lua `uv.hrtime()` |
| Session memory | sum of RSS for the Neovim process tree (`nvim` + `nvim --embed` + children) | `ps -axo pid,ppid,rss` |

**Note on `--headless`:** the UI phase is deliberately skipped when no UI exists
(`runtime/phases.lua:31-33`, `82-84`). Headless numbers therefore cover core startup only.
Theme, statusline, dashboard, and scope-line costs are measured with a real PTY UI.

### 2.1 PTY capture

A Python PTY harness starts `nvim` with `TERM=xterm-256color`, `COLORTERM=truecolor`, a 120×40
window, and answers the terminal queries Neovim waits for (background color, DSR, DA1/DA2,
kitty-keyboard and DECRQM probes). It timestamps every output chunk. Without these answers Neovim
waits ~125 ms for the background-color response, which would invalidate every number. The harness
is measurement-only and lives outside the repository.

---

## 3. Scenarios measured

| ID | Scenario | Command shape |
| --- | --- | --- |
| S1 | Empty startup, interactive dashboard | `nvim` in the config root |
| S2 | Empty startup, headless | `nvim --headless -c qa` |
| S3 | Lua file | `nvim .../sample.lua` |
| S4 | Go file | `nvim .../sample.go` |
| S5 | Markdown file | `nvim .../sample.md` |
| S6 | Project only (cwd = repo, no file) | same as S1 |
| S7 | Optional tools unavailable | `PATH=/usr/bin:/bin nvim .../sample.go` |
| S8 | Session that never inserts / never uses AI | headless + delayed `qa!`, and PTY with no keys |

Representative files are 2–6 lines and contain one Lua statement, one Go `main`, and one Markdown
heading/code fence. They isolate editor startup from project-indexing cost.

---

## 4. Results

### 4.1 Process startup (`NVIM STARTED`)

**Batch A (15 runs, no concurrent test load; first 5 discarded as warm-up):**

`10.10 ms` median for the last 10 (range `9.76–15.46`; one 15.46 outlier). All 15: median `10.23`,
range `9.57–15.46`.

**Batch B (10 runs, concurrent `go test` load):**

| n | Median | Min | Max |
| --- | --- | --- | --- |
| 10 | **11.50 ms** | 10.92 ms | 12.31 ms |

The established acceptance reference is `9.87 ms` median on a quieter host. The difference is
environmental, not a code change. `NVIM STARTED` includes native Neovim runtime plugins,
filetype detection, and the config; it is not the same boundary as `init.lua → VimEnter`.

`--startuptime` composition from a representative run:

| Component | self+sourced (ms) |
| --- | --- |
| `sourcing init.lua` | 2.11 |
| `require('runtime')` | 2.07 |
| `require('core')` | 1.26 |
| `core.keymaps` | 0.42 |
| `runtime.phases` | 0.28 |
| `vim.loader` | 0.23 |
| `core.options` | 0.18 |
| `core.autocmds` | 0.13 |
| `nvimz.config.plugins` | 0.12 |
| native `loading rtp plugins` | 1.79 |
| native `matchit.vim` | 0.58 |
| `NVIM STARTED` | ~10.1 |

The config path is already small. Most of the process time is native Neovim startup, not nvimz.

### 4.2 Core init → VimEnter (headless, n=10)

| n | Median | Min | Max |
| --- | --- | --- | --- |
| 10 | **6.73 ms** | 6.11 ms | 7.98 ms |

This is the project's established 10 ms metric. It remains below target. Opening a file adds native
filetype detection, ftplugin, and syntax work before `VimEnter`:

| Scenario | VimEnter (ms, 3 runs) |
| --- | --- |
| Empty | 6.23 / 6.44 / 8.18 |
| Lua file | 13.12 / 13.58 / 14.57 |
| Go file | 11.64 / 12.02 / 12.57 |
| Markdown file | 17.26 / 17.41 / 18.32 |

That is native work, not config work.

### 4.3 First render with a real UI (n=5 per scenario)

| Scenario | First byte | First themed paint | First content | Native intro | Dashboard |
| --- | --- | --- | --- | --- | --- |
| Empty (S1) | 15.0 (13.5–17.3) | **34.4 (31.9–37.4)** | — | 34.6 (32.1–37.6) | **70.7 (68.0–72.8)** |
| Lua (S3) | 14.8 (14.3–19.0) | 43.8 (40.4–72.9¹) | 43.8 (40.4–72.9¹) | — | — |
| Go (S4) | 16.5 (14.8–17.6) | 41.4 (40.6–45.2) | 41.4 (40.6–45.2) | — | — |
| Markdown (S5) | 15.3 (14.7–17.6) | 52.3 (51.1–53.0) | 52.3 (51.1–53.1) | — | — |

¹ One Lua run was 72.9 ms; it was the same run that produced a 72.9 ms first content. The other four
were 40.4–44.9 ms.

Observed visual sequence for an empty interactive session:

1. **~15 ms** — terminal enters the alternate screen, no content.
2. **~25 ms** — a blank screen is painted (all spaces).
3. **~34 ms** — tokyonight colors, custom statusline, and the **native Neovim intro screen**
   (`NVIM v0.12.6`, help hints) are painted.
4. **~70 ms** — the nvimz dashboard replaces the native intro.

So theme and statusline are correct at the first *content* paint. The visible defect is the
36 ms native-intro interval before the dashboard, i.e. a real layout shift.

For file scenarios, the first content paint already includes theme, custom statusline, and the
file content. There is no default-theme flash on a normal file open.

### 4.4 First-buffer readiness

| Check | Lua | Go | Markdown |
| --- | --- | --- | --- |
| Native filetype at `VimEnter` | `lua` | `go` | `markdown` |
| Content painted (median) | 43.8 ms | 41.4 ms | 52.3 ms |
| Treesitter active at first content | yes (native ftplugin) | yes (phase 1) | yes (native ftplugin) |
| LSP client attached | lua_ls ~63 ms | gopls ~68 ms | marksman (not separately timed) |
| LSP keymaps / inlay / diagnostic float present | ~20 ms after attach | same mechanism | same mechanism |
| Render-markdown decoration | — | — | first paint in this batch; earlier runs showed ~105 ms |

`features.lsp.setup` registers `LspAttach` at phase 1; the actual attach callback runs later and
the final state is correct. The order is not guaranteed for a server that attaches very quickly,
which is a reliability item in the plan (§5, F-8).

### 4.5 Input responsiveness (`send → vim.on_key`, n=3 per delay)

Keys were sent one byte at a time with a 20 ms interval. `send` is the PTY write epoch; `on_key`
is the epoch inside Neovim's key handler. Delays are `on_key − send`.

| Key start | Typed | Per-key delays (ms) | Interpretation |
| --- | --- | --- | --- |
| 10 ms | `ihello` | **22.8–41.0**, 30–41, 10–14, 2–14, 0.7–9.4, 0.1–0.2 | Startup phases block input for up to ~41 ms |
| 40 ms | `ihello` | 3.1–6.9, 4.8–8.5, 4.0–10.7, 1.9–9.7, 0.1, 0.1 | Still blocked while phase 1/2 run |
| 400 ms | `ihello` | 0.1, **6.8–11.6**, 0.1, 0.1, 0.1, 0.1 | Idle processing is ~0.1 ms; the second key waits for phase 3 (AI) |

This is the most important interactive result in the baseline: the editor event loop is responsive
when idle (~0.1 ms to consume a key), but deferred phase work is **synchronous on the main loop**
and produces visible stalls up to ~41 ms during startup and ~7–12 ms on the first insert.

Visual echo measured through the PTY was 20–30 ms at idle. That number includes PTY/render batching
and is an upper bound; the `on_key` measurement is the reliable input-processing figure.

### 4.6 Deferred phase completion and module counts

Probe: 1 ms timer from `VimEnter`, recording when each watched module first appears in
`package.loaded`. The probe itself adds ~1 ms of scheduling overhead; values are rounded to 0.1 ms.

| Scenario | VimEnter | Phase 1 complete | Phase 2 complete | Modules after phase 2 |
| --- | --- | --- | --- | --- |
| Empty | 6.23–8.18 | **28.8–32.7** | **39.9–43.2** | 166 |
| Lua | 13.12–14.57 | **39.6–40.9** | **51.9–53.3** | 192 |
| Go | 11.64–12.57 | **39.9–45.8** | **55.7–64.1** | 191 |
| Markdown | 17.26–18.32 | **53.3–55.7** | **75.0–77.2** | 231 |

Phase 1 includes theme, icons, statusline, scope line, treesitter, LSP setup, oil, pairs,
completion, picker, and mini.git/mini.diff. Phase 2 includes conform plus the four DAP plugins.

The Markdown case is ~13 ms later than Lua/Go because phase 1 also adds `render-markdown.nvim`,
whose plugin script auto-runs `require('render-markdown').setup(...)`.

The earlier acceptance report recorded ~22 ms for a phase-1 checkpoint and ~33 ms for phase 1+2.
This batch measures 28.8–32.7 ms and 39.9–43.2 ms for the empty case. The earlier probe used a
different timer boundary and a quieter host; the values in this table are the ones to reuse for
before/after comparison, with the same probe and the same host load.

### 4.7 Plugin and module activation

| Boundary | Active plugins | Notes |
| --- | --- | --- |
| `VimEnter` | **none** | `package.loaded` = 38 in headless |
| Phase 1 (~30–56 ms) | tokyonight, mini.nvim, render-markdown.nvim, oil.nvim, oil-git-status.nvim | 5 plugins |
| Phase 2 (~40–77 ms) | + conform.nvim, nvim-dap, nvim-nio, nvim-dap-ui, nvim-dap-go | 10 plugins |
| First `InsertEnter` | + gp.nvim, copilot.lua | 12 plugins |

Important: `render-markdown.nvim` is **not lazy today**. `vim.pack.add(phase1)` activates its
runtime path, its `plugin/render-markdown.lua` runs `require('render-markdown').setup()` and loads
21 modules. Measured in isolation: **5.2–5.4 ms and 21 modules** on every session, including
sessions that never open Markdown. The later `FileType=markdown` setup call is a duplicate setup,
not the first load.

In a session with no `InsertEnter`, `gp.nvim` and `copilot.lua` remain inactive. In any normal
editing session the first `i` loads both.

### 4.8 Feature activation cost (cold, isolated)

Measured with `nvim --headless -u <minimal>` that puts the plugin paths on `runtimepath`, then
times `require(...)` + `setup()` per module. These are cold upper bounds; in the real phase the
Lua and OS caches are warmer, so the phase totals are lower than the sum. They are useful for
ranking, not for adding up as an exact budget.

| Feature | Measured cost | Notes |
| --- | --- | --- |
| Theme (`tokyonight.setup` + colorscheme) | 3.5–5.2 ms | must precede first themed paint |
| Icons (`mini.icons`) | 1.6–2.3 ms | needed by statusline/picker |
| Statusline setup | 0.9–3.7 ms | |
| Statusline first build | **6.5–9.1 ms** cold; **1.0–1.1 ms** after icons + LSP | loads `vim.lsp`, `vim.diagnostic`, `mini.icons` on first call |
| Dashboard setup | 3.1–3.5 ms | buffer, lines, keymaps, highlights |
| Scope line setup | ~0.2 ms | runtime autocmds |
| Treesitter setup | 0.1–0.25 ms | plus per-buffer `treesitter.start`: **8.2 ms** for a cold Go buffer |
| LSP setup | **5.3–6.4 ms** | 4.0–4.4 ms is `require('features.lsp.servers')`, which loads `vim.lsp.protocol`; diagnostics 1.2–1.4; attach 0.12 |
| Oil setup | 3.7–5.0 ms | plugin require + config |
| Pairs | 1.0–1.2 ms | |
| Completion | 1.3–1.8 ms | |
| Picker setup | 0.5–0.6 ms | open 1.5 ms; `fd` 9.9–20.3 ms |
| Git (`mini.git` + `mini.diff`) | 2.4–2.8 ms | `mini.git` 0.9–1.5, `mini.diff` 1.2–1.7 |
| Format (`conform`) | 0.7–1.3 ms | |
| Markdown (`vim.pack.add` + auto setup) | **5.2–5.4 ms, 21 modules** | plus duplicate `setup()` 0.1 ms |
| DAP setup (`dap` + `dapui` + `dap-go`) | **9.9–16.3 ms** | largest unconditional deferred cost |
| gp require | 3.2–5.3 ms | |
| copilot require | 4.8–8.4 ms | |
| Phase 3 on first insert | **6.8–11.6 ms stall** before the next key | measured via `on_key` |
| `fd` for picker | 9.9–20.3 ms | 108 files in the repo |
| `rg` for grep | 16.4–31.9 ms | 154 matches |

### 4.9 CPU and memory

**Headless max RSS (`/usr/bin/time -l`, wait 50/200/1000/3000 ms):**

| Wait | nvimz | vanilla `nvim --clean` |
| --- | --- | --- |
| 50 ms | 20.9 MB | 12.1 MB |
| 200 ms | 20.9 MB | 12.2 MB |
| 1000 ms | 21.0 MB | 12.1 MB |
| 3000 ms | 21.2 MB | 12.2 MB |

CPU time (user+sys) was ~0.05–0.07 s for nvimz in the first 50–100 ms and ~0.02 s for vanilla;
after 3 s the difference did not grow, i.e. no ongoing background CPU from the config.

**Interactive process tree (RSS sum, 1.2 s after start, 3 runs):**

| Session | Total |
| --- | --- |
| `nvim --clean`, empty | 21.5 MiB |
| `nvim --clean`, Lua file | 24.0–24.2 MiB |
| **nvimz, empty** | **30.1–30.3 MiB** |
| **nvimz, Lua file (lua_ls)** | **108.6–109.7 MiB** |
| **nvimz, Go file (gopls)** | **156.7–251.6 MiB** (gopls spawns a telemetry child in some runs) |

The Neovim 0.12 TUI itself is two processes (`nvim` + `nvim --embed`); the table sums the tree.
Single-process headless numbers above are the `nvim --embed` server only. Do not compare the two
directly.

**AI memory:** the first `InsertEnter` starts the Copilot language server. One probe measured
`copilot-language-server` at **301.9 MiB RSS** at idle, with the total Neovim tree rising from
~35 MiB to ~370 MiB including the Lua LSP. This is the single largest optional memory cost in the
configuration and it is paid by every editing session today.

### 4.10 Background overhead

- There is no background worker, timer queue, or idle warm-up in the current runtime. All deferred
  work runs synchronously on the main loop.
- Phase 1 and phase 2 therefore compete with typing: the §4.5 table shows up to 41 ms key latency.
- During phase loading, child processes (`gopls`, `lua-language-server`) may start; they are
  asynchronous and do not block the editor, but they consume CPU while indexing.
- After phases complete, idle Neovim CPU is ~0% and input processing is ~0.1 ms.

### 4.11 Failure and edge probes

| Probe | Result |
| --- | --- |
| Missing `gopls` (`PATH=/usr/bin:/bin`, Go file) | `ft=go`, Treesitter active, one warning `LSP server 'gopls' not found: gopls`, editor stays usable |
| Unknown filetype (`.xyz`) | `ft=""`, no errors, editor starts |
| Short-lived `nvim --headless -c qa` | exit 0, no messages |
| Five consecutive headless starts | 5/5 exit 0 |
| Startup messages | empty |
| `:checkhealth nvimz` | all sections present (tools, servers, formatters, parsers, plugins, machine) |
| Command inventory | core + LSP + native commands; no duplicate/error |
| `:NvimzBenchmark` | 3 samples, ~2.07 s total command time; median 12.05 ms under load |

---

## 5. Current loading map

```
init.lua
└─ runtime/init.lua
   ├─ version guard
   ├─ capture + blank 'shada'
   ├─ vim.loader.enable()
   ├─ require("core")                       ~1.3 ms
   │  ├─ globals, options, filetypes
   │  ├─ keymaps
   │  ├─ autocmds (yank, resize, large-file, LspAttach, FileType→LSP)
   │  └─ commands
   └─ require("runtime.phases").setup()     ~0.3 ms

VimEnter (two autocmds, deferred)
├─ restore shada + rshada!                  defer(0)
├─ dashboard.setup()                        vim.schedule
└─ phase 1                                  defer(0)
   ├─ vim.pack.add(phase1): tokyonight, mini, render-markdown, oil, oil-git
   ├─ theme → icons → statusline → scope line
   ├─ treesitter → lsp → oil → pairs → completion → picker → git
   ├─ markdown setup if a Markdown buffer is already open
   ├─ FileType=markdown autocmd for later
   └─ defer(0) → phase 2
      ├─ vim.pack.add(phase2): conform, dap, nio, dap-ui, dap-go
      └─ format → dap

InsertEnter (once)
└─ phase 3
   ├─ vim.pack.add(phase3): gp, copilot
   └─ features.ai.setup() (Ollama check, gp setup, Copilot setup, AI keymaps)
```

The intent is already phased. The problem is **when and how much**, not the existence of phases:

1. Phase 1 is a single ~24 ms synchronous block executed after `VimEnter`.
2. Phase 2 is a second ~10–20 ms block executed immediately after phase 1.
3. Phase 3 is triggered by *any* first `InsertEnter`, not by AI intent, and is executed inline in
   the key handler.
4. `render-markdown.nvim` is added in phase 1 and auto-loads on every start.
5. DAP is fully configured in phase 2 even in sessions that never debug.
6. The dashboard is created after phase 2 because `vim.schedule(dashboard)` loses to the phase
   timers.
7. A startup-timing warning is shown in the middle of the first file paint.

---

## 6. Findings

### F-1 — Phase 1 is a single 24 ms main-loop block

Observed from `VimEnter` to phase-1 completion: 22–24 ms for empty/Lua/Go, ~38 ms for Markdown.
Keys sent during this window are delayed by 10–41 ms. This is the largest startup responsiveness
defect.

### F-2 — Phase 2 adds another 10–21 ms, dominated by DAP

`features.format` is ~1 ms; `features.dap` is 9.9–16.3 ms. Phase 2 runs unconditionally and
immediately after phase 1, so the two blocks combine. In sessions that never debug, 10–16 ms of
synchronous work and four plugin runtime paths are pure overhead.

### F-3 — Markdown is not actually lazy

`render-markdown.nvim` is added in phase 1. Its plugin script auto-calls
`require('render-markdown').setup()`, loading 21 modules in 5.2–5.4 ms on every session. The
`FileType=markdown` path is a second setup, not the first load. This is both wasted startup cost
and a misleading architecture claim.

### F-4 — The dashboard appears ~36 ms after the first themed paint

At ~34 ms the user sees the native Neovim intro screen; the dashboard replaces it at ~70 ms.
This is a visible layout shift in the default empty-startup experience.

### F-5 — The startup warning is a user-visible interruption

When any file is opened, `init.lua → VimEnter` is 11.6–19.4 ms because of native file work. The
current rule `elapsed > 10` therefore notifies `nvimz startup N ms exceeded the 10ms target` in
normal use. In PTY captures the notification is painted over the first line of the file at
~68–105 ms, after the file content. The threshold is meaningful for empty startup, not for
file-open startup, and the notification is not actionable.

### F-6 — AI is loaded on the first insert, not on AI intent

The first `i` loads gp.nvim *and* copilot.lua inline (6.8–11.6 ms before the next key), starts the
Copilot language server (~302 MiB at idle), and runs the Ollama reachability check. A user who
never uses AI still pays this on every editing session. A session that never inserts leaves both
plugins inactive.

### F-7 — Statusline's first build can cost 6.5–9 ms

The first call to `build_active()` loads `vim.lsp`, `vim.diagnostic`, and `mini.icons` if they are
not already loaded. In the current phase order LSP is loaded before the first redraw, so the real
cost is ~1 ms. If LSP is deferred without a guard in `get_lsp`/`get_diagnostics`, the statusline
will pull those modules back in on the first paint and erase the intended saving.

### F-8 — LSP is set up before servers attach, but only by timing

`features.lsp.setup()` runs in phase 1 and registers `LspAttach`; `vim.lsp.start` is called from
the FileType handler. In the measured Lua and Go runs attach happened at ~63–68 ms, after setup, so
keymaps/inlay/diagnostic-float were present. A faster server could attach before phase 1 and miss
them. First-use correctness should not depend on a 30 ms race.

### F-9 — `features.lsp.servers` costs 4.0–4.4 ms at require time

`vim.lsp.protocol.make_client_capabilities()` is evaluated at module load (`servers.lua:5`). That
single line pulls `vim.lsp.protocol` into every session that sets up LSP, even if no server is
ever started. Moving it to first server start removes most of the LSP setup cost from the general
path.

### F-10 — Native startup is already efficient

Config load is 2.1 ms; core is 1.3 ms; native runtime plugins account for ~1.8 ms plus filetype
work. There is no evidence for touching Tier 0 beyond removing the warning and keeping the
existing synchronous keymaps/commands.

### F-11 — Input handling itself is fast

`vim.on_key` receives idle keys in ~0.1 ms. The perceived lag is entirely phase work. This means
chunking phases is a valid fix; replacing the event loop or adding a scheduler is not needed.

### F-12 — Memory is reasonable until optional features start

Empty nvimz is 30.1–30.3 MiB (tree) vs 21.5 MiB vanilla. Lua/Go LSP adds 79–221 MiB depending on
the server. Copilot adds ~300 MiB. The config should not pay for servers or AI that are not used.

---

## 7. What is already good (preserve)

- Core/Tier 0 is ~2 ms and contains no plugin setup or subprocesses.
- Native filetype detection, syntax, and runtime plugin loading are intact.
- Per-module failure isolation (`pcall` + named notification) is present.
- The shada deferral works and is measured (~0.7 ms) without breaking persistence.
- The native picker is demand-driven at the keymap level (module loaded in phase 1 but no
  subprocess until used).
- `:checkhealth nvimz` is read-only and complete.
- No startup cache or state file is read/written.
- Idle CPU after phases is ~0 and input handling is ~0.1 ms.

---

## 8. Limitations of this baseline

1. **Single host.** macOS 27 / arm64, Neovim 0.12.6 only. Linux is unverified.
2. **Host load.** Batch B and parts of the feature probes ran with concurrent Go test processes.
   Startup medians differ by ~1.4 ms between batches; both are reported.
3. **PTY approximation.** A PTY is closer to a real terminal than `--headless`, but it is not the
   user's terminal emulator. First-paint timings include PTY scheduling and Neovim's terminal
   query/response path.
4. **Cold feature costs are upper bounds.** They were measured in a minimal process with plugin
   paths added; the real phase benefits from warmer Lua/OS caches. They rank costs reliably but
   are not additive.
5. **LSP attach times vary by server and project.** Lua and Go values are from tiny sample files;
   a real project can index for seconds after attach.
6. **Memory is whole-tree RSS.** No per-module attribution. gopls telemetry children caused a
   156–252 MiB spread for the same Go scenario.
7. **No visual recording.** The PTY stream proves ordering and timing, not perceived smoothness.
   Interactive confirmation is still required in Phase 3.

---

## 9. Reproduction

Run from the repository root. All commands are read-only.

```bash
# Warm startup (discard 5, measure 10)
D=$(mktemp -d)
for i in $(seq 1 5); do nvim --startuptime "$D/w$i.log" --headless -c qa; done
for i in $(seq 1 10); do
  nvim --startuptime "$D/$i.log" --headless -c qa
  grep 'NVIM STARTED' "$D/$i.log" | tail -1 | awk '{print $1}'
done

# Core init -> VimEnter
nvim --headless -c 'lua vim.api.nvim_create_autocmd("VimEnter",{once=true,callback=function()
  io.write(("%.4f\n"):format((vim.uv.hrtime()-_G.nvimz_start_time)/1e6)); vim.cmd("qa!") end})'

# Phase completion and module count (1 ms probe)
nvim --headless -c 'lua local s=_G.nvimz_start_time
  local w={"features.interface.theme","features.lsp","features.editing.files","features.git","features.format","features.dap"}
  vim.api.nvim_create_autocmd("VimEnter",{once=true,callback=function()
    local t=vim.uv.new_timer()
    t:start(1,1,function() vim.schedule(function()
      for _,m in ipairs(w) do if package.loaded[m] then io.write(m.." ") end end
      io.write(string.format("%.1f\n",(vim.uv.hrtime()-s)/1e6))
      vim.cmd("qa!") end) end) end})'

# Plugin/module state after startup
nvim --headless -c 'lua vim.defer_fn(function()
  local ac={} for _,p in ipairs(vim.pack.get(nil,{info=false})) do if p.active then ac[#ac+1]=p.spec.name end end
  io.write("active="..table.concat(ac,",").."\n")
  io.write("markdown="..tostring(package.loaded["render-markdown"]~=nil).."\n")
  io.write("ai="..tostring(package.loaded["features.ai"]~=nil).."\n")
  vim.cmd("qa!") end,500)'

# Memory (headless, single process)
/usr/bin/time -l nvim --headless -c 'lua vim.defer_fn(function() vim.cmd("qa!") end,1000)'
```

The PTY harness and the isolated feature-cost probes are measurement scripts kept outside the
repository; their exact behavior is described in §2.1 and §4.8. The final report will include the
same commands and the identical boundaries.

---

## 10. Source inventory reviewed

- `init.lua`, `lua/runtime/init.lua`, `lua/runtime/phases.lua`
- `lua/core/{init,globals,options,filetypes,keymaps,autocmds,commands}.lua`
- `lua/features/interface/{theme,icons,statusline,dashboard,scope_line,markdown}.lua`
- `lua/features/editing/{files,pairs,completion,terminal}.lua`
- `lua/features/lsp/{init,servers,attach,diagnostics,inlay,keymaps}.lua`
- `lua/features/{format,git,dap,ai}/init.lua`
- `lua/features/search/pick.lua`, `lua/nvimz/picker/native.lua`
- `lua/nvimz/{treesitter,benchmark,health,packages,ui}.lua`
- `lua/nvimz/config/{plugins,languages,parsers,tools}.lua`
- `nvim-pack-lock.json`, `ftplugin/java.lua`, `docs/performance.md`,
  `docs/architecture/runtime-decisions.md`, `docs/audit/runtime-final-report.md`
