# Runtime & Infrastructure Final Report

**Mission:** Reconstruct the Runtime & Infrastructure Core of nvimz
**Phases:** 1 (audit) → 2 (reconstruction) → 3 (hardening and validation)
**Date:** 2026-11-01
**Branch:** `perf/optimize-logic` (no commits made)
**Reference host:** Neovim 0.12.6, LuaJIT 2.1.1793383622, macOS 27.0.1, Apple M1 Pro

**Overall status: `PASS WITH LIMITATIONS`**

---

## 1. Objective

Replace nvimz's accumulated infrastructure — a custom package manager, a telemetry cache, five
diagnostic surfaces, and a static-data "registry" — with the smallest native-first runtime that
preserves every essential workflow and has a measurable, honest performance profile.

Design documents:

- `docs/audit/runtime-architecture-audit.md` — findings and defect register (D-1…D-17)
- `docs/audit/runtime-dependency-map.md` — actual call/subprocess/persistence graph
- `docs/audit/runtime-baseline.md` — pre-change measurements
- `docs/architecture/runtime-target-architecture.md` — approved target
- `docs/architecture/runtime-decisions.md` — 17 decisions with rationale

---

## 2. Work Completed

### Runtime

- `init.lua` → `runtime/init.lua` is now a 40-line bootstrap: version guard, `vim.loader`,
  `core`, phase triggers, deferred viminfo restore, dashboard launch, 10 ms warning.
- Deleted `runtime/{bootstrap,loader,events}.lua`.
- `runtime/phases.lua` is the only plugin loader: declarations come from
  `nvimz/config/plugins.lua`; phase 2 starts after phase 1; phase 3 on `InsertEnter`;
  markdown on `FileType`.
- Failure isolation: `vim.pack.add` and every feature `setup()` are wrapped individually and
  reported with the failing module name. No phase-wide silent `pcall`.

### Core

- Removed the `loadplugins`, filetype-replay, and command/keymap scheduling hacks.
- Filetype detection, syntax loading, and runtime plugin loading are native again.
- Only the viminfo read is deferred past `VimEnter` (measured 0.73 ms; restored before the
  event loop processes input; verified to persist registers across sessions).
- Keymaps and 7 commands are registered synchronously; the one-shot global guard is gone.
- `machine/local.lua` is read directly (no cache). A malformed file is reported, and the
  editor still starts.

### Infrastructure

| Before | After |
| --- | --- |
| `infra/registry` (5 files, 445 lines) | `nvimz/config` (4 files, 249 lines), one `lsp_servers` table |
| `infra/deps` (9 files, 408 lines) | native `vim.pack` + `nvimz/packages.lua` (113 lines) |
| `infra/health` + `infra/report` (6 files, 581 lines) | `nvimz/health.lua` (144) + `nvimz/benchmark.lua` (111) |
| `infra/cache` (2 files, 62 lines) | removed |
| `infra/license.lua`, `infra/view`, `infra/treesitter` | `:License` opens `LICENSE`; `nvimz/ui.lua`; `nvimz/treesitter.lua` |

### Commands

13 runtime commands → 7: `:PackUpdate`, `:PackRollback`, `:PackStatus`, `:PackClean`,
`:NvimzBenchmark`, `:ParsersUpdate`, `:License`. Five LSP commands remain (out of scope).
`:checkhealth nvimz` replaces `:PackValidate`, `:PackDoctor`, and `:ToolDoctor`.
Removed with no shim: `:PackSync` (use `:PackUpdate`'s review buffer), `:PackReport`,
`:PackSnapshot`.

### Scripts

- `scripts/manage --update` now calls `vim.pack.update(nil, { force = true })`, then rebuilds
  parsers; `--report` and the generated `MAINTENANCE_REPORT.md` are gone.
- `scripts/doctor` lists match the Lua declarations (3 core tools, 10 servers, 6 formatter
  binaries, 16 parsers).
- `scripts/setup --minimal` only offers languages that have provisioning scripts
  (`go`, `python`, `rust`, `java`, `node`); the node script's package-install precedence was fixed.

---

## 3. Before / After

All values measured on the reference host. "Before" values are from
`docs/audit/runtime-baseline.md`; "After" values were captured with the same commands.

| Category | Before | After | Evidence |
| --- | --- | --- | --- |
| Architectural layers (runtime + core + infra) | 37 files / 2,184 lines | 18 files / 1,141 lines | repository inventory (`find`, `wc -l`) |
| Runtime modules | 5 files / 207 lines | 2 files / 143 lines | `lua/runtime` |
| Lua source files (total) | 60 | 41 | `find lua -name '*.lua'` |
| Lua source lines (total) | 4,949 | 3,906 | `wc -l` |
| Plugins | 13 | 12 | `nvim-pack-lock.json`, `vim.pack.get()` |
| Dependencies | git, rg, fd + nvim-lspconfig | git, rg, fd (no plugin deps added) | declarations + lockfile |
| Warm startup (`NVIM STARTED`, mean/median) | 5.366 / 5.340 ms (n=10) | 9.844 / 9.896 ms (n=12) | `--startuptime` |
| First render (`VimEnter`) | not captured | 7.24–8.92 ms (median ~8.4 ms) | deferred-timer probe (n=8) |
| Cold bytecode cache (`NVIM STARTED`) | 5.995 / 5.629 ms (n=5) | 12.083 / 11.176 ms (n=5) | isolated `XDG_CACHE_HOME` |
| Phase 1 + 2 complete (median) | 32.69 ms (n=5) | 23.36 ms (n=5) | deferred-timer probe |
| Config load (`require("runtime")`) | 1.821 ms | 1.908 ms | `--startuptime` |
| Modules loaded after startup | 12 | 10 | `package.loaded` |
| Modules loaded after phases | 157 | 148 | `package.loaded` |
| Startup state writes | 1 JSON read + 1 write | none | state file absent after startup |
| Maintenance commands | 13 runtime + 5 LSP | 7 runtime + 5 LSP | `nvim_get_commands` |
| `:PackStatus` subprocesses | ~50 git calls | 0 | command implementation |
| Benchmark child processes | 6 (and cache deletion) | 3 (no deletion) | `nvimz/benchmark.lua` |
| RSS after phase 1+2 | 20.0 MiB | 20.3 MiB | `/usr/bin/time -l` |

### Interpreting the startup change

`NVIM STARTED` is **4.5 ms higher**, and this is intentional. The previous figure was obtained by
disabling native plugin loading, filetype detection, and viminfo loading, then replaying a subset
after `VimEnter`:

- the old replay loaded only `plugin/**/*.vim`, silently disabling the Lua runtime plugins
  (`editorconfig`, `:Man`, `:Open`, OSC52 clipboard, shada, spellfile);
- the first buffer had no filetype until the replay (measured `ft=""` before, `ft="lua"` after);
- matchit and the other native plugin scripts were skipped at startup.

The new build loads all of them natively. The project's own first-render metric (init start →
`VimEnter`) is **7.2–8.9 ms**, still under the 10 ms target, and deferred phase work is **~9 ms
faster** than before (23.4 ms vs 32.7 ms to a fully initialized editor). Viminfo is the only
deferral retained.

---

## 4. Verification Performed

### Syntax and load

- `loadfile()` over all 41 Lua files: 0 syntax errors.
- Headless startup and repeated startup: no messages/errors.
- Require-graph scan: 0 cycles, 0 unresolved internal requires.
- `grep` audit: no references to `infra.*`, removed commands, removed modules, `MAINTENANCE_REPORT`,
  `nvimz_cache`, or `nvim-lspconfig`.

### Runtime behavior

| Check | Result |
| --- | --- |
| File opened on command line | `filetype=lua` at `-c` time (native detection) |
| Go buffer | `filetype=go`, 1 `gopls` client, Treesitter active |
| Missing server (`gopls` removed from PATH) | one actionable warning; editor starts; `:checkhealth nvimz` warns |
| Invalid `machine/local.lua` | startup succeeds; explicit error notification |
| Machine override change | applied live without deleting any cache (tested with a temp file) |
| Shada persistence | register written in session 1 present in session 2 (isolated state dir) |
| State file | not created during startup |
| `:checkhealth nvimz` | all sections; 10 active + 2 lazy plugins after startup |
| `:checkhealth nvimz` without tooling | warnings for missing servers/formatters, no false errors for optional tools |
| `:PackStatus` | managed/active/lazy/undeclared, lockfile, core tools; no subprocesses |
| `:PackClean` | removed the undeclared `nvim-lspconfig`; preserved lazy phase-3 plugins |
| `:PackRollback` | native review buffer; no changes when already at lockfile revisions |
| `:PackUpdate` | native `vim.pack` flow (offline/force path validated; no revisions moved) |
| `:NvimzBenchmark` | 3 samples, module table, cache untouched |
| `:License` | opens the real `LICENSE` file |
| `:ParsersUpdate` | command present; uses `scripts/parsers` |
| Shell scripts | `bash -n` clean; `scripts/doctor` runs |

### Fresh installation

A full copy of the config was run with isolated `XDG_{CONFIG,DATA,STATE,CACHE}_HOME` directories
and an empty plugin directory:

- `vim.pack.add(..., { confirm = false })` installed **12/12** plugins;
- the copied lockfile remained valid with 12 entries;
- a subsequent normal start reported `filetype=go`, 1 LSP client, 12 managed plugins;
- startup in that fresh environment: 9.10 / 9.70 / 10.79 ms.

### Failure isolation (code-level)

`vim.pack.add` is wrapped in `pcall` and a failure is reported; feature setups are individually
wrapped in `runtime/phases.lua` and reported by module name. This was verified by inspection of the
runner and by the native `vim.pack` error contract (`pack.lua:1062`); no destructive injection test
was performed on the user's plugin directory.

---

## 5. Defect Resolution

| Audit defect | Status |
| --- | --- |
| D-1 silent phase failures | **Fixed** — per-module `pcall` + named error notification |
| D-2 plugin failure aborts phase | **Fixed** — `vim.pack.add` isolated; setup continues for on-disk plugins |
| D-3 bogus startup metric | **Fixed** — startup metric removed from `:PackStatus` |
| D-4 deferred filetype | **Fixed** — native filetype detection |
| D-5 stale machine cache | **Fixed** — direct load, explicit error on malformed file |
| D-6 mutating validate command | **Fixed** — `:checkhealth nvimz` is read-only, no child Neovim |
| D-7 destructive benchmark | **Fixed** — 3 runs, cache never deleted |
| D-8 unreviewed plugin checkout | **Fixed** — native review buffer + lockfile rollback |
| D-9 unreachable health provider | **Fixed** — `lua/nvimz/health.lua` |
| D-10 under-reported tool health | **Fixed** — servers/formatters derived from one source |
| D-11 unused `nvim-lspconfig` | **Fixed** — removed from declarations, lockfile, and disk |
| D-12 Java `nvim-jdtls` / duplicate client | **Deferred** — LSP/Java domain |
| D-13 duplicate `lsp_servers` | **Fixed** — one table |
| D-14 dead code | **Fixed** — cache/phase state, `M.add`, `license.get`, `health.check` removed |
| D-15 documentation drift | **Fixed** — README and all four docs updated to real commands/paths/measurements |
| D-16 script list drift / phantom languages | **Fixed** — doctor aligned, setup offers only real scripts |
| D-17 `manage --all` mismatch | **Fixed** — report task removed and help matches behavior |

---

## 6. Files

**Deleted (28 Lua files + 1 generated report):** `lua/runtime/{bootstrap,loader,events}.lua`
and all of `lua/infra/**` (25 files: cache 2, deps 9, health 3, report 3, registry 5, license 1,
view 1, treesitter 1), plus `MAINTENANCE_REPORT.md`.

**Added (9):** `lua/nvimz/config/{plugins,languages,parsers,tools}.lua`,
`lua/nvimz/{health,packages,benchmark,ui,treesitter}.lua`.

**Modified:** `lua/runtime/init.lua`, `lua/runtime/phases.lua`,
`lua/core/{init,globals,options,keymaps,commands}.lua`,
`lua/features/{lsp/init,lsp/servers,format/init}.lua`, `scripts/{manage,doctor,setup}`,
`scripts/lang/*.sh` (comment/path + node fix), `README.md`, `docs/{architecture,commands,languages,
performance}.md`, `nvim-pack-lock.json` (native rewrite; `nvim-lspconfig` removed; revisions
unchanged).

Net tracked diff: **+621 / −2,169 lines** (plus the new audit/architecture documents).

The user's pre-existing edits to `README.md` and `docs/*.md` were preserved and extended, not
reverted. Nothing was committed.

---

## 7. Remaining Limitations

1. **Single platform.** Verified on macOS 27 / arm64 only. Linux behavior is unverified at runtime.
2. **No GUI session measurement.** Theme, icons, statusline, scope line, and markdown setup were
   smoke-tested in headless mode; the dashboard was not visually verified.
3. **`NVIM STARTED` regression is real** (+4.5 ms) and is the cost of restoring native plugin and
   filetype loading. The first-render metric is 7.2–8.9 ms; the `--startuptime` metric includes
   native runtime plugin scripts. Do not compare the two as if they were the same number.
4. **Viminfo restore after `VimEnter`.** If Neovim exits before the first deferred callback (for
   example `-c qa` scripts), viminfo is neither read nor written. Interactive sessions are
   unaffected; persistence was verified in isolated state directories.
5. **Deferred feature items.** `ftplugin/java.lua` still expects `nvim-jdtls` (undeclared) and
   `:LspInfo/:LspStart/:LspStop/:LspRestart` overlap native `:lsp` commands. Both belong to the
   planned LSP/Java redesign.
6. **`vim.pack` is documented as experimental** in Neovim 0.12. nvimz now depends on it directly;
   this is a deliberate trade (it was already the package manager, without a custom wrapper).
7. **Fresh-install test** used a copied config with isolated XDG directories on a networked host,
   not a clean operating-system image.
8. **Stale ignored artifact.** `snapshots/snapshot_20260526_105957.json` remains from the removed
   snapshot feature. It is gitignored and safe to delete; it was left untouched to avoid removing
   user files.
9. **No per-module memory attribution.** RSS values are whole-process maxima.

---

## 8. Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| `vim.pack` API changes across Neovim releases | packaging commands break | pinned to Neovim 0.12+; `:checkhealth vim.pack` and `:PackStatus` surface problems |
| Startup warning fires on slower hosts (>10 ms to `VimEnter`) | noisy warning | warning is informational; `:NvimzBenchmark` gives the number and slowest modules |
| Users scripted against removed commands | breakage | documented mapping: diagnostics → `:checkhealth nvimz`, sync → `:PackUpdate` review buffer |
| Deferred viminfo on unusual exit paths | lost session marks for that run | documented; only affects processes that never reach `VimEnter` |
| Java double-client if `nvim-jdtls` is installed manually | duplicate LSP | documented; fix belongs to the LSP redesign |

---

## 9. Acceptance Gate

| Phase 3 criterion | Status |
| --- | --- |
| Critical runtime checks pass | PASS |
| Essential workflows work (LSP, treesitter, format, DAP, picker, git, AI phases) | PASS — phase load and LSP verified; feature setup errors are now visible |
| No known critical regression | PASS WITH LIMITATIONS — startup metric change is explained and accepted |
| Performance results reproducible | PASS — commands in `runtime-baseline.md` |
| Documentation matches implementation | PASS |
| Cross-platform limitations explicit | PASS (macOS only) |
| Architecture simpler in operational terms | PASS — 19 fewer infra files, 1,043 fewer lines, 6 fewer commands, 1 fewer plugin |
| Remaining complexity justified | PASS — see decisions register |

**Gate status: `PASS WITH LIMITATIONS`.**

---

## 10. Recommendation

The runtime and infrastructure core is now small enough to read in one sitting:
2 runtime files, 7 core files, 9 infrastructure modules, and native `vim.pack`/`:checkhealth` for
the rest. No new framework was introduced.

Recommended next steps, outside this mission:

1. Review the diff and commit on `perf/optimize-logic` when satisfied (nothing was committed).
2. Run one interactive session to confirm the theme/statusline/dashboard visually.
3. Schedule the LSP/Java domain review to resolve audit D-12 and the LSP command overlap.
4. Verify on a Linux host before advertising cross-platform metrics.
5. Do not reintroduce the removed startup hacks to chase the old 5.4 ms number; measure first
   render and phase completion separately.
