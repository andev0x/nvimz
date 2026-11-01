# Runtime & Infrastructure Decisions

**Phase:** 1 — Decision register
**Date:** 2026-11-01
**Status:** Accepted and implemented in Phase 2. One entry per architectural decision, following the project protocol:
Problem → Evidence → Native capability → Removal → External boundary → Cost → Decision → Verification.

Legend for **Decision**: KEEP · SIMPLIFY · MERGE · REMOVE · DEFER.

---

## Summary

| ID | Subject | Decision |
| --- | --- | --- |
| D1 | `infra/deps` custom package manager | **REMOVE** → native `vim.pack` |
| D2 | `infra/cache` persistence layer | **REMOVE** |
| D3 | Machine-specific configuration loading | **SIMPLIFY** (direct require) |
| D4 | `runtime/` module split | **MERGE** into two files |
| D5 | `infra/registry` aggregator | **MERGE** into `nvimz/config` |
| D6 | Duplicate tool inventory | **MERGE** (derive from languages) |
| D7 | Health/reporting framework | **MERGE** → `:checkhealth nvimz` |
| D8 | Benchmark implementation | **SIMPLIFY** (non-destructive) |
| D9 | Maintenance report + snapshots | **REMOVE** |
| D10 | Error isolation in phase loading | **SIMPLIFY** (explicit reporting) |
| D11 | Startup hacks (`loadplugins`/`shada`/filetype) | **REMOVE** (pending measurement) |
| D12 | Scheduled keymaps/commands | **SIMPLIFY** (synchronous) |
| D13 | Command surface and naming | **SIMPLIFY** (13 → 7) |
| D14 | `nvim-lspconfig` plugin | **REMOVE** |
| D15 | Embedded license copy | **REMOVE** |
| D16 | Java `ftplugin` / duplicate LSP commands | **DEFER** (feature domains) |
| D17 | Shell script list drift (`manage`, `doctor`, `setup`) | **SIMPLIFY** (documentation/consistency only) |

---

## D1 — Replace the custom dependency layer with `vim.pack`

**Problem.** nvimz maintains a parallel package manager: 9 modules, 408 lines, ~50 git calls for a
status check and ~80 per update, its own lockfile writer, its own rollback, and its own update path
with no review step.

**Evidence.** `lua/infra/deps/{lockfile,git,update,sync,status,rollback,clean,snapshot,init}.lua`.
`vim.pack` already writes `nvim-pack-lock.json` (`pack.lua:695`, `lock_write`), supports update
with a confirmation buffer (`update()` docs, `pack.lua:1263`), lockfile-targeted rollback
(`opts.target == 'lockfile'`, `pack.lua:1298`), deletion (`del`), and inspection (`get`).
Verified on this host: `vim.pack.get()` returns `{spec, path, rev, active}` for all 13 plugins.

**Native capability.** Yes — complete. `:checkhealth vim.pack` also exists and reports lockfile
and plugin directory state.

**Removal.** `:PackSync` becomes redundant (`:PackUpdate` shows a review buffer; quitting applies
nothing). `:PackSnapshot` becomes redundant (lockfile records revisions). `:PackReport` is
unrelated output. `deps/git.lua` default-branch discovery is not needed by any native operation.

**External boundary.** Git remains the transport; nvimz does not wrap it.

**Cost.** Four conversational UX differences: update now opens a review buffer; rollback is
`target = "lockfile"`; "sync" no longer exists as a separate verb; status no longer runs git.
Cost of keeping: maintenance of 408 lines + divergence from the native lockfile writer +
blocking subprocess fan-out.

**Decision: REMOVE.** Keep only `nvimz/packages.lua` (~60 lines): `status`, `rollback`, `clean`.

**Verification.** `:PackStatus` on this host; `:PackUpdate` opens the native buffer and `:quit`
changes nothing; `:PackRollback` with a scratch plugin returns it to the lockfile revision;
`:PackClean` removes an intentionally deactivated plugin. Compare command output with
`vim.pack.get()`.

---

## D2 — Remove the persistent cache

**Problem.** One JSON state file is read and written every session, holds three keys, and one of
them is a second source of truth for configuration.

**Evidence.** `lua/infra/cache/state.lua`, `lua/infra/cache/init.lua`.
Writers: `runtime/init.lua:27`, `runtime/phases.lua:35`, `core/options.lua:64`.
Readers: `core/options.lua:58`, `report/benchmark.lua:125`, `deps/snapshot.lua:12`.
`plugin_state.phases` is written but never gates behavior (`phases.lua:38-40` only reads it inside
the same write path).

**Native capability.** Neovim persists shada/undo; no native equivalent is needed because the
data is not load-bearing. Benchmark history can be measured on demand.

**Removal.** Delete the module, the startup write, the phase flags, and the machine cache.
Benchmark loses the "historical comparison" section — it was never used to make a decision and
was polluted by outliers.

**External boundary.** None.

**Cost.** Losing 10 startup-history samples. Value gained: one less file, one less write per
session, and correct machine-config semantics.

**Decision: REMOVE.**

**Verification.** Start Neovim twice; assert `stdpath("state")/nvimz_cache.json` is not created.
Change a test `machine/local.lua` value and confirm it applies on the next start.

---

## D3 — Load machine configuration directly

**Problem.** `machine/local.lua` is read only on a cache miss. Changing it has no effect until
the cache file is deleted (`:PackClean` happens to delete it).

**Evidence.** `core/options.lua:56-70`; cache key `machine_state`.

**Native capability.** `pcall(require, "machine.local")` is the native mechanism. It costs one
`require` on a tiny file.

**Removal.** Remove the cache read/write and the `vim.schedule` wrapper. Set
`vim.g.python3_host_prog` synchronously when the file exists.

**External boundary.** Machine-specific paths stay in the gitignored file; nothing moves into
shell environment scripts.

**Cost.** Negligible (one optional module load). Keeping the cache risks silently wrong tooling.

**Decision: SIMPLIFY.**

**Verification.** Create `machine/local.lua` with a fake path, start headless, print
`vim.g.python3_host_prog`; change the value; confirm the new value without deleting any file.

---

## D4 — Collapse `runtime/` into two files

**Problem.** Four modules implement one version check, one API call, one user command, and the
phase loader. `runtime/events.lua` exists solely for `:License`, which is a command, not a
runtime event.

**Evidence.** `runtime/bootstrap.lua` (3 lines), `runtime/loader.lua` (4 lines),
`runtime/events.lua` (17 lines), measured `require` cost 0.10 ms each on the startup path
(`--startuptime`). `:License` is registered by a module whose name suggests an event bus.

**Native capability.** `vim.fn.has`, `vim.loader.enable`, `nvim_create_user_command`.

**Removal.** Delete the three files; inline the guard and loader; move `:License` to
`core/commands.lua`.

**External boundary.** None.

**Cost.** One more responsibility in `runtime/init.lua` (bootstrap + startup hooks). Mitigated by
keeping it ~45 lines with one concern per block. This is not a "god module"; it is the process
entry point.

**Decision: MERGE.**

**Verification.** Startup log shows `require('runtime')` only; `:License` opens the real LICENSE
file; `:messages` is clean.

---

## D5 — Replace the eager "registry" with config data modules

**Problem.** `infra/registry/init.lua` eagerly loads four unrelated tables whenever one is
needed. The name implies dynamic registration that does not exist.

**Evidence.** `infra/registry/init.lua:3-6`; consumers that need only languages:
`features/lsp/servers.lua:3`, `features/format/init.lua:3`, `infra/health/init.lua:3`.
`languages.lua` defines `M.lsp_servers` twice (lines 15 and 170); the first 155-line block is dead.

**Native capability.** Direct `require` of a data module.

**Removal.** Delete the aggregator. Move the four tables to `nvimz/config/{plugins,languages,
parsers,tools}.lua`. Dedupe `languages.lua` to one `lsp_servers` table.

**External boundary.** None; these are Lua declarations, not package lists.

**Cost.** Three require-line changes in features, plus docs paths. Benefit: no accidental
loading of plugins/tools/parsers when only language data is needed; one authoritative LSP table.

**Decision: MERGE.**

**Verification.** Each consumer loads headless; `nvim --headless -c 'lua for _,m in ipairs({...}) do require(m) end'`
passes; LSP attach works for a Lua file; `#vim.tbl_keys(require("nvimz.config.languages").lsp_servers) == 10`.

---

## D6 — One tool inventory, derived

**Problem.** `tools.lua` hand-maintains a second tool list, already out of sync: 2/10 LSP servers,
3/9 formatter filetypes. Health output therefore under-reports what nvimz configures.

**Evidence.** `infra/registry/tools.lua` vs `infra/registry/languages.lua`; reproduced at runtime:
`lsp_servers=10 tools.lsp=2`, `formatters_by_ft=9 tools.formatters=3`.

**Native capability.** `vim.fn.executable`; iteration over the existing language tables.

**Removal.** Delete `tools.lsp` / `tools.formatters`. Keep only `tools.core` (git, rg, fd) because
those are prerequisites with no other declaration site. Derive server and formatter checks from
`languages.lua`.

**External boundary.** `scripts/doctor` keeps its own list until D17; after D17 it can invoke
`:checkhealth` or mirror the same table. Duplication is documented in the meantime.

**Cost.** One derive function (~15 lines) in `nvimz/health.lua`. Replaces 72 lines of drifting data.

**Decision: MERGE.**

**Verification.** `:checkhealth nvimz` lists all 10 servers and all distinct formatter binaries on
this host; remove one formatter from PATH and confirm it is reported missing.

---

## D7 — Replace the diagnostics framework with `:checkhealth nvimz`

**Problem.** Four commands produce overlapping reports through three renderers, three copies of
the startup-log parser, and one nested Neovim. The one native health provider is unreachable.

**Evidence.** `infra/health/{init,check,render}.lua`, `infra/report/{doctor,maintenance}.lua`.
`M.check()` at `health/init.lua:35` is never called and no `lua/*/health.lua` provider exists;
`:checkhealth nvimz` prints "checks done" with no sections. `health.run()` spawns
`nvim --headless` (line 96), which executes the full config and can write state.

**Native capability.** `:checkhealth` + `vim.health.{start,ok,warn,error}`; `:checkhealth vim.pack`
for packaging. All read-only.

**Removal.** Delete `infra/health/*`, `infra/report/doctor.lua`, `infra/report/maintenance.lua`,
and the corresponding commands. One provider file `lua/nvimz/health.lua` (~90 lines) covers
core tools, servers, formatters, parsers, plugins, machine state.

**External boundary.** Keep `scripts/doctor` for shell-only environments, aligned to the same
lists (D17).

**Cost.** Users lose the Markdown-buffer reports; they gain a standard `:checkhealth` interface
with no side effects. This is a net reduction: 259 + 76 + 101 lines → ~90.

**Decision: MERGE.**

**Verification.** `:checkhealth nvimz` shows each section; entries match reality on this host
(e.g. 10 servers); no child Neovim, no network, no file writes (verify mtime of the state dir).

---

## D8 — Simplify the benchmark

**Problem.** `:PackBenchmark` deletes `~/.cache/nvim/luac`, spawns 6 child Neovim processes
synchronously, and compares against a cache polluted by outliers.

**Evidence.** `infra/report/benchmark.lua:78` (`delete(cache_dir, "rf")`), `:87` (4 warm loops),
`:110` (extra profiling child); three copies of startup parsing (6 children total).

**Native capability.** `nvim --startuptime` and `vim.uv.hrtime`; no cache mutation required.

**Removal.** Drop cache deletion, history comparison, and the redundant profiling run. Measure
3 child runs; report min/median/max plus the 10 slowest sourced modules from the last log.

**External boundary.** Startup measurement remains a shell-friendly operation (`--startuptime`).

**Cost.** Loses "cold after deleting cache" (destructive) and history. Retains the information a
maintainer needs: current warm latency and the slowest modules.

**Decision: SIMPLIFY.**

**Verification.** `:NvimzBenchmark` completes without touching `~/.cache/nvim/luac` (compare
mtimes), reports 3 samples, and its median matches `docs/audit/runtime-baseline.md` methodology.

---

## D9 — Remove the maintenance report and snapshots

**Problem.** Generated artifacts duplicate health output and the lockfile, are committed, and go
stale immediately.

**Evidence.** `MAINTENANCE_REPORT.md` committed with date 2026-10-19; `:PackReport` and
`scripts/manage --report` regenerate it. `snapshots/` is gitignored; `:PackSnapshot` writes plugin
revisions + `uname` that `nvim-pack-lock.json` already contains.

**Native capability.** `nvim-pack-lock.json`, `git`, `:checkhealth`.

**Removal.** Delete `infra/report/maintenance.lua`, `infra/deps/snapshot.lua`, the commands, the
`--report` task, and the committed report file. Keep `snapshots/` in `.gitignore` (harmless) or
remove the directory.

**External boundary.** A maintainer can run `:checkhealth nvimz` + `git log` directly.

**Cost.** Losing a single Markdown artifact. No workflow depends on it (the file was last
generated during a previous maintenance pass).

**Decision: REMOVE.**

**Verification.** `grep -r "MAINTENANCE_REPORT"` returns only git history; `:PackReport` and
`:PackSnapshot` are gone from the command inventory; `scripts/manage --help` matches behavior.

---

## D10 — Explicit failure isolation

**Problem.** Feature setup errors are discarded. Plugin acquisition errors abort a whole phase.

**Evidence.** `runtime/phases.lua:70` (`pcall(setup)` with no report), `:68-74` (`add_plugins`
outside any `pcall`); native `vim.pack.add` raises when any plugin fails (`pack.lua:1062`).

**Native capability.** `pcall` + `vim.notify` (error level). No logging framework needed.

**Removal.** No new subsystem: a 6-line `run(module)` helper that names the failing module, and a
`pcall` around `vim.pack.add` that reports and continues with on-disk plugins.

**External boundary.** None; errors also reach `:messages` and `nvim -V1` logs.

**Cost.** ~10 lines; eliminates silent half-initialization. One failing feature no longer takes
down unrelated features.

**Decision: SIMPLIFY (mandatory correctness fix).**

**Verification.** Temporarily inject `error("boom")` in a feature setup and in one plugin source
(offline); confirm one error notification per failure, other features still loaded, editor usable.

---

## D11 — Remove the startup hacks

**Problem.** `loadplugins=false`, `shada=""`, and `did_load_filetypes=1` are replayed after
`VimEnter` by sourcing runtime files and re-triggering filetype detection. The first buffer has no
filetype until the replay; startup autocmds see an empty filetype.

**Evidence.** `core/globals.lua:14-19`, `runtime/init.lua:32-40`. Measured probe: file argument
`ft=""` at `-c` time and after the first deferred tick; `ft="lua"` only after the replay (~300 ms
in the probe). Deferred replay also sources `syntax.vim` on the measured startup path.

**Native capability.** Neovim's default startup: plugin loading is already deferred internally,
shada is loaded natively, filetype detection is incremental.

**Removal.** Delete the three settings and the replay block.

**External boundary.** None.

**Cost.** Unknown startup delta until measured. Expected small: all 13 plugins are `opt`, so
native plugin loading has nothing to source; matchit/netrw are the only runtime plugins (netrw is
disabled). Shada load is bounded by the native defaults. **If the measured regression exceeds
0.5 ms, keep only the shada deferral and document it** — but do not reintroduce the filetype hack.

**Decision: REMOVE, conditional on measurement (Phase 2/3 gate).**

**Outcome.** The filetype and `loadplugins` hacks were removed; native plugin loading and filetype
detection are kept. Only the viminfo read remains deferred (0.73 ms) because restoring it is safe
and it keeps the first render under the 10 ms target. Removing all three hacks measured ~11.3 ms
on `NVIM STARTED`; keeping native plugin loading measured ~9.9 ms after the viminfo deferral.

**Verification.** Compare warm/cold startup before/after (n=10) and the filetype probe; require
`ft="lua"` at `-c` time; confirm `:messages` is clean and undo/history still work.

---

## D12 — Create keymaps and commands synchronously

**Problem.** All mappings and all commands are wrapped in `vim.schedule` with a global one-shot
guard. They do not exist during startup, and the guard is a global used once.

**Evidence.** `core/keymaps.lua:1`, `core/commands.lua:4-10`.

**Native capability.** `vim.keymap.set` / `nvim_create_user_command` are already fast; measured
config load is 1.8 ms total.

**Removal.** Remove the wrappers and the `vim.g.pack_commands_created` guard.

**External boundary.** None.

**Cost.** Negligible; the APIs are synchronous by design. Benefit: deterministic availability and
less hidden state.

**Decision: SIMPLIFY.**

**Verification.** `nvim --headless file.lua -c 'lua print(vim.fn.maparg("<leader>w"))'` is non-empty
at `-c` time; `:PackStatus` resolves at `-c` time; startuptime unchanged within noise.

---

## D13 — Reduce and rename the command surface

**Problem.** 13 runtime commands for 4 real operations; names (`PackValidate`, `PackDoctor`,
`ToolDoctor`, `PackReport`) imply distinctions that do not exist. Diagnostics are commands, not
health checks.

**Evidence.** `core/commands.lua` (12) + `runtime/events.lua` (1); `docs/commands.md` table.

**Native capability.** `:checkhealth`, `vim.pack.update/del/get`.

**Removal.** Target: `:PackUpdate`, `:PackRollback`, `:PackStatus`, `:PackClean`,
`:ParsersUpdate`, `:NvimzBenchmark`, `:License` (7). Removed: `:PackSync`, `:PackValidate`,
`:PackDoctor`, `:ToolDoctor`, `:PackReport`, `:PackSnapshot`.

**External boundary.** `scripts/manage` keeps `--update` (plugins) and `--sync` (system packages);
its `--report` task is removed.

**Cost.** Muscle-memory change for the maintainer; mitigated by `docs/commands.md` mapping and
one release of documentation. Keeping them means keeping four implementations of the same report.

**Decision: SIMPLIFY.**

**Verification.** `:command` inventory exactly matches docs; every listed command runs headless
without error on this host.

---

## D14 — Remove the unused `nvim-lspconfig` plugin

**Problem.** A plugin is installed, locked, and loaded by `vim.pack` but never used.

**Evidence.** Declared at `infra/registry/plugins.lua:12`; `grep -rn lspconfig lua ftplugin scripts`
returns only that line. LSP is configured directly with `vim.lsp.start`
(`features/lsp/servers.lua:35`).

**Native capability.** Already in use.

**Removal.** Delete the declaration; `:PackClean` (or `vim.pack.del`) removes the directory.

**External boundary.** None.

**Cost.** Saves one plugin clone/update and its `runtimepath` entry; removes a false signal in the
README plugin list.

**Decision: REMOVE.**

**Verification.** `:PackStatus` shows 12 plugins; LSP still attaches for Go/Lua; no `lspconfig`
module in `package.loaded`.

---

## D15 — Open the real license file

**Problem.** The MIT text is duplicated inside Lua; the two copies can diverge.

**Evidence.** `lua/infra/license.lua:6` vs `LICENSE:1`.

**Native capability.** `:edit <config>/LICENSE`; `vim.fn.stdpath("config")`.

**Removal.** Delete `infra/license.lua`; implement `:License` as a two-line command.

**External boundary.** None.

**Cost.** None. `LICENSE` remains the single source.

**Decision: REMOVE.**

**Verification.** `:License` opens `LICENSE`; content matches `git show HEAD:LICENSE`.

---

## D16 — Defer Java ftplugin and the LSP command overlap

**Problem.** `ftplugin/java.lua` requires `nvim-jdtls`, which is not declared as a plugin, so it is
dead on a clean install. If a user installs it manually, `jdtls` starts twice: once from
`features/lsp/servers.lua` (`jdtls` in `languages.lua`) and once from
`jdtls.start_or_attach`. Separately, `:LspStart/:LspStop/:LspRestart` overlap the native
`:lsp stop/restart/enable/disable` (verified in `doc/lsp.txt:149-162`).

**Evidence.** `ftplugin/java.lua:1,30`; `languages.lua` jdtls entry; `features/lsp/init.lua`
defines 5 commands; `:lsp` exists natively.

**Native capability.** `:lsp`, `vim.lsp.start`, `:checkhealth lsp`.

**Removal.** Both duplicates could be removed, but this is the **LSP/Java feature domain**, which
this mission must not reconstruct.

**External boundary.** n/a.

**Cost.** Documented as a known defect; no runtime/infra change.

**Decision: DEFER** to the LSP redesign. Recorded here so it is not lost.

**Verification.** Future LSP mission: open a Java buffer with `nvim-jdtls` installed and assert
exactly one `jdtls` client; map the 5 commands to native equivalents.

---

## D17 — Align shell scripts with the runtime

**Problem.** Shell lists drift from Lua lists and user-facing help overstates behavior.

**Evidence.** `scripts/doctor` checks 11 parsers vs 16 in `parsers.lua` and lists toolchain
binaries as "core"; `scripts/setup --minimal` offers `lua`, `terraform`, `markdown`, `typescript`
but `scripts/lang/` has only `go`, `java`, `node`, `python`, `rust`; `scripts/manage --all` omits
`--report` although help says "Run all tasks" (the report is removed by D9, so the help must
change, not the behavior).

**Native capability.** Shell is the correct boundary for system package management. No Lua
changes required.

**Removal.** Remove the `--report` task and the phantom language options; make `doctor` read the
same parser/tools lists (either hard-code a mirrored list with a comment pointing at the Lua
source, or call `nvim --headless -c 'checkhealth nvimz'`).

**External boundary.** Yes — this is exactly where external tooling belongs.

**Cost.** Small documentation/help edits; no runtime impact.

**Decision: SIMPLIFY** (help text + list parity; do not grow the scripts).

**Verification.** `./scripts/doctor` output count matches `parsers.required`; `./scripts/setup
--help` lists only existing provisioning scripts; `./scripts/manage --all` behavior matches help.

---

## Review Outcome

All open questions were resolved before Phase 2:

1. **Command naming:** `:Pack*` is kept for package operations; `:NvimzBenchmark` is the only new
   name. 13 runtime commands became 7.
2. **`:PackStatus`:** kept as a 113-line module that reports managed/active/lazy/undeclared plugins,
   lockfile presence, and core tool status without spawning subprocesses.
3. **D11 threshold:** accepted. The resulting startup change is larger than 0.5 ms and is documented
   as the cost of restoring native plugin loading and filetype detection; only the viminfo deferral
   remains.
4. **Startup warning:** kept at 10 ms, measured from `init.lua` to `VimEnter`; telemetry writes were
   removed. Measured first-render time is 7.2–8.9 ms on the reference machine.

No decision in this register depends on a hypothetical future feature. Every REMOVE has a native
or external owner for the removed responsibility.
