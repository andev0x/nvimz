# Runtime & Infrastructure Architecture Audit

**Phase:** 1 — Architectural Audit & Design Baseline
**Date:** 2026-11-01
**Subject:** nvimz Runtime & Infrastructure Core
**Repository:** `/Users/anvndev/.config/nvim`
**Branch:** `perf/optimize-logic`
**Neovim:** 0.12.6 (LuaJIT 2.1.1793383622), macOS 27.0.1, arm64 (Apple M1 Pro)

---

## 1. Scope and Method

Inspected (source is the source of truth, not the docs):

- `init.lua`, `lua/runtime/**`, `lua/core/**`, `lua/infra/**`, `lua/machine/**`
- Feature entry points only where they define infrastructure contracts:
  `features/lsp/*`, `features/format/init.lua`, `features/interface/*`
- `scripts/{setup,manage,doctor,parsers}`, `scripts/lib/*`, `scripts/lang/*`
- `nvim-pack-lock.json`, `docs/*.md`, `README.md`, `.gitignore`, `.luarc.json`

Method:

1. Static call/require graph (`grep` over all Lua sources), cross-checked by loading modules in a
   headless Neovim and inspecting `package.loaded`.
2. Runtime probes: `--startuptime`, isolated `XDG_CACHE_HOME`, deferred-timer timestamps,
   `vim.pack.get()`, `:checkhealth`, `:command` inventory.
3. Verification of native API availability in the shipped runtime docs
   (`/opt/homebrew/share/nvim/runtime/doc/pack.txt`, `lsp.txt`, `runtime/lua/vim/pack.lua`).
4. Measurements were taken on the maintainer's machine only. Numbers are in
   `docs/audit/runtime-baseline.md`; estimates are labelled as such.

**Repository state at audit time:** branch `perf/optimize-logic`, clean except user edits to
`README.md` and four files under `docs/` (252 insertions). Those edits were read but **not
modified or reverted**.

---

## 2. Executive Summary

nvimz is **fast**: warm startup is 5.37 ms mean (n=10). That is not the problem.

The problem is that the *maintenance and runtime infrastructure* grew into a small package
manager, a telemetry cache, three diagnostic renderers, and a static-data "registry" — roughly
**1,609 lines of `infra/` for functionality that Neovim 0.12 already provides**. Measured costs:

| Finding | Evidence |
| --- | --- |
| 25 of the 60 Lua files (1,609 lines) are infrastructure; most of it duplicates `vim.pack`/`:checkhealth` | `lua/infra/**` |
| `infra/deps/` reimplements `vim.pack.update()`, the native lockfile, and native rollback | `lua/infra/deps/{lockfile,update,rollback,sync,git}.lua` |
| The persistence cache is written on **every startup**, but one of its three keys is never read | `lua/runtime/init.lua:27`, `lua/runtime/phases.lua:26-40`, `lua/core/options.lua:58-64` |
| Three separate tool/health renderers plus a dead `vim.health` provider | `lua/infra/health/init.lua:35`, `lua/infra/report/{doctor,maintenance}.lua` |
| All deferred feature setup errors are silently discarded | `lua/runtime/phases.lua:70` |
| A declared plugin (`nvim-lspconfig`) is never `require`d or used | `lua/infra/registry/plugins.lua:12` |
| `lua/infra/registry/languages.lua` defines `M.lsp_servers` twice (155 dead lines) | `:15` and `:170` |
| A diagnostic command deletes the user's bytecode cache and spawns 6 Neovim children | `lua/infra/report/benchmark.lua:78,87` |
| `:PackStatus` reports session uptime as "startup time" | `lua/infra/deps/status.lua:23-25` |
| Tool health covers 2 of 10 LSP servers and 3 of 9 configured formatters | `lua/infra/registry/tools.lua` vs `languages.lua` |

The correct architectural response is **subtraction**, not a new framework. The target
architecture (see `docs/architecture/runtime-target-architecture.md`) keeps the current,
already-good loading model and replaces the duplicated infrastructure with native Neovim
mechanisms plus a handful of small, single-purpose modules.

---

## 3. Actual Initialization Path

### 3.1 Immediate path (measured 5.37 ms mean to `NVIM STARTED`, n=10)

| Step | Module | Effect | Cost |
| --- | --- | --- | --- |
| 1 | `init.lua` | Sets `_G.nvimz_start_time`, `require("runtime")` | 0.03 ms self |
| 2 | `runtime/bootstrap.lua` | `vim.fn.has("nvim-0.12")` guard | 0.10 ms incl. require |
| 3 | `runtime/loader.lua` | `vim.loader.enable()` (pulls `vim.loader`, `vim.fs`, `vim.uri`) | 0.29 ms incl. require |
| 4 | `core/globals.lua` | leader, netrw off, **`loadplugins=false`**, **`shada=""`**, **`did_load_filetypes=1`** | 0.10 ms |
| 5 | `core/options.lua` | editor options; schedules clipboard + machine config | 0.17 ms |
| 6 | `core/filetypes.lua` | `*.gotmpl` BufRead/BufNewFile autocmd | 0.10 ms |
| 7 | `core/keymaps.lua` | **all** keymaps inside `vim.schedule` | 0.10 ms |
| 8 | `core/autocmds.lua` | yank, resize, large-file guard, LSP attach guard, FileType→LSP | 0.10 ms |
| 9 | `core/commands.lua` | **12** commands inside `vim.schedule`, global guard | 0.10 ms |
| 10 | `runtime/phases.lua` | registers 2×`VimEnter`, `FileType=markdown`, `InsertEnter` | 0.12 ms |
| 11 | `runtime/events.lua` | registers `:License` only | 0.10 ms |

Total `require("runtime")`: **1.82 ms self+sourced** (startuptime, n=1 run; stable across runs).

Then Neovim finishes its own work. Because of the globals above, startup also sources:

- `$VIMRUNTIME/filetype.lua` late (0.05 ms), `syntax/synload.vim` (0.06 ms), `syntax/syntax.vim` (0.12 ms)
- first `BufEnter` with **no filetype detected yet** (see §5, defect D-4)

### 3.2 `VimEnter` (deferred) path

`runtime/init.lua:10-52` and `runtime/phases.lua:82-126` register timers with `vim.defer_fn(..., 0)`:

| Work | Trigger | Modules initialized |
| --- | --- | --- |
| Startup telemetry | `VimEnter` → `vim.schedule` | `infra.cache` (reads, appends, **writes JSON**) |
| Filetype re-enable, `runtime! plugin/**/*.vim`, shada + `rshada!` | `VimEnter` → defer 0 | Vim runtime plugins |
| Dashboard | `VimEnter` → `vim.schedule`, UI only | `features.interface.dashboard` |
| Phase 1 | `VimEnter` → defer 0 | 5 plugins; theme, icons, statusline, scope line, treesitter, **LSP setup**, oil, mini.pairs, mini.completion, picker, mini.git, mini.diff |
| Phase 2 | `VimEnter` → defer 0 | 6 plugins; conform, nvim-dap, dap-ui, dap-go |
| Markdown | `FileType=markdown` once | `render-markdown` |
| Phase 3 | `InsertEnter` once | 2 plugins; gp.nvim, copilot.lua |

**Measured:** from process start to *phase 1 + phase 2 complete* is **31.9–36.1 ms** (n=5,
median 32.7 ms). The first screen is therefore rendered at ~5.4 ms, but the editor is only fully
initialized ~27 ms later. This is a deliberate, working trade-off — the audit preserves it.

### 3.3 Independent paths

- `core/autocmds.lua:96-112` starts LSP on **every** `FileType` via `vim.defer_fn`, independently
  of phase 1. If a buffer gets a filetype before phase 1 completes, `features.lsp.start` loads
  `features.lsp.servers` early. This ordering is implicit, not guaranteed.
- Keymaps and commands do not exist until the first scheduled tick (after the first event-loop
  iteration). Anything that runs during startup cannot invoke them.

### 3.4 Lazy / on-demand work

| Path | Trigger | Notes |
| --- | --- | --- |
| `:Pack*`, `:ToolDoctor`, `:ParsersUpdate`, `:License` | user command | all infrastructure is loaded lazily today |
| `scripts/manage`, `scripts/setup`, `scripts/doctor` | shell | independent of the editor |
| LSP server start | `FileType` | one `vim.lsp.start` per matching server |
| DAP, AI, terminals | keymap after phase 2/3 | phase 3 spawns `curl` and possibly `ollama serve` |
| Treesitter | `FileType` | native `vim.treesitter.start` |

---

## 4. Layer-by-Layer Audit

Line counts are `wc -l` over the actual files.

| Layer | Files / LOC | Actual responsibility | Consumers | Verdict |
| --- | --- | --- | --- | --- |
| `init.lua` | 1 / 4 | entry + start clock | Neovim | **KEEP** |
| `runtime/` | 5 / 207 | version guard, loader, phase loading, telemetry, `:License`, filetype/shada re-enable | `init.lua` | **SIMPLIFY + MERGE** |
| `core/` | 7 / 368 | options, keymaps, autocmds, filetypes, commands, globals | `runtime` | **KEEP, trim hacks** |
| `infra/registry/` | 5 / 445 | static data (plugins, languages, parsers, tools) + eager aggregator | phases, LSP, format, health, deps | **MERGE / de-framework** |
| `infra/cache/` | 2 / 62 | JSON persistence: startup history, phase flags, machine config | runtime, options, benchmark, snapshot | **REMOVE** |
| `infra/deps/` | 9 / 408 | git-based sync/update/rollback/status/clean/snapshot/lockfile | commands only | **REMOVE most → native `vim.pack`** |
| `infra/health/` | 3 / 259 | tool inspection, 3 renderers, unreachable `vim.health` provider, nested-nvim validator | commands, deps, reports | **MERGE → `:checkhealth nvimz`** |
| `infra/report/` | 3 / 322 | doctor, maintenance report, benchmark | commands | **MERGE / REMOVE** |
| `infra/treesitter/` | 1 / 49 | native treesitter enablement + folds | phases | **KEEP, simplify** |
| `infra/view/` | 1 / 23 | scratch buffer renderer | deps, health, report | **KEEP** (move under `nvimz`) |
| `infra/license.lua` | 1 / 41 | embedded copy of `LICENSE` | `:License` | **REMOVE** (open the real file) |
| `features/` | 21 / 1945 | feature domains | phases, keymaps | **DEFER** (only require-path edits) |
| `nvimz/picker/` | 1 / 815 | native picker | `features.search.pick` | **DEFER** |
| `machine/` | 1 / 6 | host-local overrides | `core/options.lua` | **KEEP, remove caching** |

### 4.1 `runtime/` — four modules for a version check, an API call, one command, and the phase loader

- `bootstrap.lua` — one `vim.fn.has()` check, but costs a module load (0.10 ms).
- `loader.lua` — two lines around `vim.loader.enable()`.
- `events.lua` — registers one command (`:License`) and nothing else; 0.10 ms of `require`
  on the critical path.
- `phases.lua` — the only substantive module, but it contains dead state:
  `cached_phase_state`, `remember_phase`, `phase_has_loaded` (lines 26-40) are written every
  startup and **never used to gate anything**; `M.add` (line 77) has no callers.
- `runtime/init.lua` mixes six unrelated concerns: version bootstrap, cache telemetry,
  `:License`, filetype/shada/plugin re-enable, dashboard launch, startup warning.

### 4.2 `infra/registry/` — not a registry

There is no registration, no mutation, no lookup by key. It is four static data tables plus an
aggregator (`registry/init.lua`) that eagerly loads **all four** whenever any consumer needs one.
Evidence: `features/lsp/servers.lua:3`, `features/format/init.lua:3`, `infra/health/init.lua:3`
only need `languages`, but load `plugins`, `tools`, and `parsers` as well.

Correctness defects in this layer:

- `languages.lua` assigns `M.lsp_servers` twice (line 15 and line 170). The first 155-line table
  is dead; only the second (with `jsonls`, `marksman`) is used. Any edit made to the first block
  silently has no effect.
- `tools.lua` is a second, hand-maintained inventory: 2 LSP servers and 3 formatters, while
  `languages.lua` declares 10 servers and 9 formatter filetypes. Health output therefore
  under-reports tooling that nvimz actually uses.
- `plugins.lua` declares `nvim-lspconfig`, which no code requires (verified by grep over
  `lua/`, `ftplugin/`, `scripts/`). It is installed and locked but provides no value.

### 4.3 `infra/cache/` — persistent state without an owner

`state.lua` loads/serializes one JSON file at `stdpath("state")/nvimz_cache.json`. Keys:

| Key | Written by | Read by | Verdict |
| --- | --- | --- | --- |
| `startup_stats` | `runtime/init.lua:27` (every startup) | `report/benchmark.lua:125`, `deps/snapshot.lua:12` | low value (history is not used to make decisions) |
| `plugin_state.phases` | `phases.lua:35` | **nothing** (`phase_has_loaded` only guards its own write) | dead |
| `machine_state` | `core/options.lua:64` | `core/options.lua:58` | **stale-cache bug** |

`machine_state` is a correctness problem: if `lua/machine/local.lua` changes (new
`python3_host_prog`), the cached copy in `stdpath("state")` wins forever — the new value is never
applied. `:PackClean` deletes the cache file, which happens to "fix" it, but that coupling is
undocumented.

Cost: one JSON read + one JSON write **per startup** (measured read 0.009 ms; the write happens
after the first render, so it does not affect the startup number, but it is still I/O every
session and a second source of truth for configuration).

### 4.4 `infra/deps/` — a package manager built on top of a package manager

`vim.pack` (0.12) natively provides everything this layer implements:

| Custom module | Native replacement (verified in `runtime/lua/vim/pack.lua` + `doc/pack.txt`) |
| --- | --- |
| `lockfile.lua` `git rev-parse` per plugin, writes `nvim-pack-lock.json` | `vim.pack` writes and reads the same lockfile itself (`lock_write`, `lock_read`) |
| `update.lua` fetch + checkout `origin/<branch>` + relock | `vim.pack.update()` with confirmation buffer, changelog, and log |
| `rollback.lua` manual `git checkout <rev>` | `vim.pack.update(nil, { offline = true, target = "lockfile" })` |
| `sync.lua` fetch + compare revisions per plugin | `vim.pack.update(nil, { offline = true })` (review-only buffer) |
| `status.lua` per-plugin `rev-parse` + branch detection | `vim.pack.get()` returns `{spec, path, rev, active}`; `:checkhealth vim.pack` exists |
| `git.lua` default-branch discovery via `git remote show` | not needed for update/target |
| `snapshot.lua` JSON of plugin revs + uname | lockfile already records every revision; artifact is gitignored |

Operational defects:

- **No confirmation.** `deps/update.lua` checks out `origin/<branch>` immediately. Native
  `vim.pack.update()` shows the diff and requires `:write` to apply.
- **Redundant process fan-out.** `sync` and `status` each spawn 4–5 `git` processes *per plugin*
  (13 plugins → ~50–65 processes) synchronously; `update` spawns 4–5 per plugin.
- **Wrong metric.** `status.lua:23-25` reports `(hrtime() - startup_time)` at command execution —
  that is session uptime, not startup time. After an hour, `:PackStatus` prints
  `startup=3600200.00ms`.
- **Misleading API.** `deps/init.lua` is a pass-through facade whose only job is
  `require(...).run()` for six modules.

### 4.5 `infra/health/` + `infra/report/` — five overlapping diagnostic surfaces

| Surface | Command | Output | Duplication |
| --- | --- | --- | --- |
| `health.run_doctor` | `:ToolDoctor` | stdout table | tool rendering #1 |
| `health.run` | `:PackValidate` | markdown buffer | startup parser #1, syntax scan, nested `nvim` |
| `report.doctor.run` | `:PackDoctor` | markdown buffer | tool rendering #2, parser list |
| `report.maintenance.run` | `:PackReport` | writes `MAINTENANCE_REPORT.md` in repo | tool rendering #3, startup parser #2 |
| `report.benchmark.run` | `:PackBenchmark` | markdown buffer | startup parser #3 |

Specific defects:

- `health.check()` (line 35) is a `vim.health` provider **but is never called** and there is no
  `lua/*/health.lua` provider file, so `:checkhealth nvimz` does nothing (verified: prints
  `checking nvimz... checks done` with zero sections).
- `health.run()` spawns `nvim --headless -c qa` **from inside Neovim** (line 96). That child runs
  the full config, including plugin phases, cache writes, and potentially plugin installation.
  A read-only "validate" command therefore mutates state and can touch the network.
- `health.run()` globs and `loadfile`s every `**/*.lua` in the config dir (line 165). This checks
  syntax only; it cannot detect missing modules, circular requires, or runtime errors.
- Startup parsers are copy-pasted three times (`health:25`, `maintenance:60`, `benchmark:13`).
- `health.run` says `Target: < 20 ms` (line 192) while the project target is `< 10 ms`.
- `:PackBenchmark` deletes `stdpath("cache")/luac` (line 78) — the user's bytecode cache — then
  spawns 6 child Neovim processes (1 cold + 4 warm + 1 profile) with `:wait()`, blocking the UI
  for seconds.
- `report/maintenance.lua` writes a generated file into the repository root that duplicates
  `:PackDoctor` output; it is committed (last generated 2026-10-19) and therefore stale by design.

### 4.6 `core/` — small, but three startup hacks and one scheduling anti-pattern

- `globals.lua` disables `loadplugins`, `shada`, and filetype detection to shave the startup
  path, then `runtime/init.lua` re-enables each one in a deferred callback:
  `source $VIMRUNTIME/filetype.lua`, `doautocmd filetypedetect BufRead`, `runtime! plugin/**/*.vim`,
  `rshada!`. This is clever but fragile: filetype detection for a file opened on the command line
  is delayed until after `VimEnter` (measured: `ft=""` before the deferred callback, `ft="lua"`
  after ~300 ms). Any startup autocmd that depends on `filetype` runs blind.
- `keymaps.lua` wraps **every** mapping in one `vim.schedule`, and `commands.lua` wraps all 12
  commands in another. Mappings do not exist during startup; the benefit is not measurable
  (registration is ~0.1 ms total).
- `commands.lua` protects creation with `vim.g.pack_commands_created` — a global used exactly
  once, in one call site.
- `options.lua` loads machine config inside `vim.schedule` through the cache (see §4.3).
  `python3_host_prog` should be set synchronously and directly from `machine.local`.

### 4.7 God modules / framework-like abstractions

| Component | Symptom |
| --- | --- |
| `runtime/init.lua` | 6 responsibilities in 55 lines |
| `infra/deps/` | an internal package-manager framework with a facade layer |
| `infra/health/` + `infra/report/` | a diagnostics/reporting framework (5 commands, 3 renderers) |
| `infra/registry/init.lua` | an eager service-locator for static tables |
| `infra/cache/` | a persistence framework for three keys, one of which is dead |

There is **no** DI container, event bus, or lifecycle manager — that is a genuine strength and must
be preserved. The over-engineering is concentrated in `deps/`, `report/`, `health/`, and `cache/`.

---

## 5. Correctness and Operational Defects

Ordered by severity. Each is reproducible from the repository.

| ID | Severity | Defect | Evidence |
| --- | --- | --- | --- |
| D-1 | **High** | All phase setup errors are swallowed (`pcall(setup)` with no report). A broken theme/LSP/DAP leaves a silently half-initialized editor. | `runtime/phases.lua:70` |
| D-2 | **High** | A single plugin install failure aborts the whole phase. `vim.pack.add` raises (verified `pack.lua:1062`); `load_phase` calls it outside `pcall`. Offline first run ⇒ no pairs/completion/theme/git/LSP setup at all. | `runtime/phases.lua:68-74` |
| D-3 | **High** | `:PackStatus` reports session uptime as startup time. | `infra/deps/status.lua:23-25` |
| D-4 | Medium | Filetype detection is disabled at startup and replayed after `VimEnter`. Startup autocmds see `filetype=""`; behavior differs for the first buffer vs later buffers. | `core/globals.lua:19`, `runtime/init.lua:33-35` |
| D-5 | Medium | Machine overrides are cached persistently; editing `machine/local.lua` has no effect until the cache is deleted. | `core/options.lua:56-70`, `infra/cache/state.lua` |
| D-6 | Medium | `:PackValidate` is not read-only: it spawns a full Neovim, which runs plugin phases and writes the state cache. | `infra/health/init.lua:96` |
| D-7 | Medium | `:PackBenchmark` deletes the bytecode cache and blocks the UI on 6 child processes. | `infra/report/benchmark.lua:78,87,110` |
| D-8 | Medium | `:PackUpdate` moves plugins without review; it also diverges from the native lockfile workflow. | `infra/deps/update.lua:46-53` |
| D-9 | Medium | `:checkhealth nvimz` does not exist (no provider file); the only `vim.health` call is unreachable. | `infra/health/init.lua:35` |
| D-10 | Medium | Tool health under-reports: 2/10 LSP servers, 3/9 formatters. | `infra/registry/tools.lua` |
| D-11 | Low | `nvim-lspconfig` is installed, locked, and never used. | `infra/registry/plugins.lua:12` |
| D-12 | Low | `ftplugin/java.lua` requires `nvim-jdtls`, which is not declared in `plugins.lua`; if installed manually, it starts `jdtls` a second time next to the native registry entry. | `ftplugin/java.lua:1,30` |
| D-13 | Low | Two full `M.lsp_servers` tables; the first is dead. | `languages.lua:15,170` |
| D-14 | Low | Dead code: `runtime/phases.lua` phase cache + `M.add`; `dashboard.track`; `license.get`; `health.check`. | grep results |
| D-15 | Low | Docs drift: startup target mismatch (20 vs 10 ms); README claims one measured 6.9 ms value without conditions; `docs/architecture.md` describes `lua/infra/deps.lua` (a file that does not exist). | `health/init.lua:192`, `README.md:5`, `docs/architecture.md:66` |
| D-16 | Low | `scripts/doctor` parser list (11) diverges from `registry/parsers.lua` (16); `scripts/setup --minimal` offers `lua`, `terraform`, `markdown`, `typescript`, but only `go/java/node/python/rust` provisioning scripts exist. | `scripts/doctor:20-31`, `scripts/setup:127`, `scripts/lang/` |
| D-17 | Low | `scripts/manage --all` runs update + sync but not `--report`, although help says "Run all tasks" and README says report is included. | `scripts/manage:62-82` |

---

## 6. Constraints to Preserve

These interfaces are consumed outside the runtime core and must keep working:

1. `require("features.*")` module names and `.setup()` contracts (`runtime/phases.lua`).
2. `require("infra.registry.languages").lsp_servers` / `.formatters_by_ft` shape
   (`features/lsp/*`, `features/format`).
3. `vim.pack` phase composition: phase 1 must remain sufficient for editing (pairs, completion,
   picker, oil, git) and must run within one deferred `VimEnter` tick.
4. Commands documented in `docs/commands.md` (names may change only with doc updates and an
   explicit decision; see `runtime-decisions.md`).
5. `nvim-pack-lock.json` stays the single lockfile, in place, native schema.
6. `lua/machine/local.lua` remains gitignored and the only host-specific surface.
7. Startup target `< 10 ms` and no new startup work on the immediate path.

---

## 7. Phase 1 Acceptance Gate

| Criterion | Status |
| --- | --- |
| Actual initialization path understood | PASS — §3, reproduced with startuptime and deferred probes |
| Important dependencies mapped | PASS — `runtime-dependency-map.md` |
| Existing complexity documented | PASS — §4 |
| Keep/Simplify/Merge/Remove/Defer justified | PASS — §4 and `runtime-decisions.md` |
| Target architecture defined | PASS — `runtime-target-architecture.md` |
| Compatibility constraints identified | PASS — §6 |
| Baseline measurements recorded | PASS — `runtime-baseline.md` (single-machine limitation stated) |

**Gate status: PASS WITH LIMITATIONS**

Limitations: no GUI session measurement, single platform (macOS arm64), and no Linux host was
available for runtime verification. Startup numbers are headless; UI-only work (theme, icons,
statusline) is excluded from the startup figure and included in the "phase completion" figure.

**Stop condition:** Phase 2 must not start until this audit and the target architecture are
reviewed and approved. No implementation changes were made in Phase 1.
