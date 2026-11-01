# Runtime Target Architecture

**Phase:** 1 — Proposed design, awaiting review
**Date:** 2026-11-01
**Status:** Implemented in Phase 2. Measured outcomes and deviations are recorded in `docs/audit/runtime-final-report.md`.

This document defines the minimal runtime that satisfies the requirements found in
`docs/audit/runtime-architecture-audit.md`. It deliberately keeps the parts that already work
(the phased loader, native LSP, native treesitter, native picker) and removes the layers that
duplicate Neovim, the standard library, or each other.

---

## 1. Design Rules Applied

1. **Native first.** `vim.pack`, `:checkhealth`, `vim.pack.update`, `vim.pack.get`, and
   `vim.uv` replace the custom package manager, health framework, and telemetry cache.
2. **Remove before replace.** Deleting `:PackSync`, `:PackReport`, `:PackSnapshot`, and the
   cache removes requirements; it does not create new Lua to maintain.
3. **One owner per concern.** Static declarations live in `nvimz/config/`, runtime mechanics in
   `runtime/` + `nvimz/`, editor behavior in `core/`, feature domains in `features/`.
4. **Explicit failure.** No phase-wide `pcall` that hides errors; each module's setup is isolated
   and reported with its module name.
5. **No framework.** No registry object, no lifecycle manager, no event bus, no DI, no plugin
   abstraction above `vim.pack`.
6. **Features are frozen.** `lua/features/**` changes only where a `require` path moved.

---

## 2. Target Tree

```
init.lua                         # 5 lines: start clock + require("runtime")

lua/
  runtime/
    init.lua                     # version guard, vim.loader, require core, phase triggers,
                                 # VimEnter dashboard + startup warning  (~45 lines)
    phases.lua                   # plugin declarations + ordered phase runner (~90 lines)

  core/                          # editor behavior, unchanged ownership
    globals.lua                  # leader, netrw off, provider flags
    options.lua                  # editor options + direct machine.local load
    keymaps.lua                  # keymaps (no blanket vim.schedule)
    autocmds.lua                 # yank, resize, large-file, LSP attach, FileType→LSP
    filetypes.lua                # *.gotmpl detection
    commands.lua                 # 7 commands, created synchronously

  nvimz/                         # nvimz-owned runtime + infrastructure
    config/
      plugins.lua                # phase → vim.pack specs (static)
      languages.lua              # LSP specs, formatters, icons (single table, deduped)
      parsers.lua                # required treesitter parsers (static)
      tools.lua                  # core CLI tools only; LSP/formatters derived
    health.lua                   # `:checkhealth nvimz` provider (read-only, no children)
    packages.lua                 # status / rollback / clean wrappers over vim.pack (~60 lines)
    benchmark.lua                # startup measurement, non-destructive (~50 lines)
    ui.lua                       # scratch buffer rendering (was infra/view)
    treesitter.lua               # native treesitter + folds (was infra/treesitter)
    picker/native.lua            # unchanged

  machine/
    example.lua                  # unchanged

  features/                      # unchanged (21 files); only require paths updated
    interface/ lsp/ editing/ search/ git/ format/ dap/ ai/
```

**Deleted paths (28):** `runtime/{bootstrap,loader,events}.lua`,
`infra/cache/*` (2), `infra/deps/*` (9), `infra/health/*` (3), `infra/report/*` (3),
`infra/registry/*` (5), `infra/license.lua`, `infra/view/init.lua`, `infra/treesitter/init.lua`.

**New paths under `nvimz/` (9):** 6 moved (`config/{plugins,languages,parsers,tools}.lua`, `ui.lua`,
`treesitter.lua`) and 3 genuinely new (`health.lua`, `packages.lua`, `benchmark.lua`).
Net file count: **60 → 41**; infrastructure lines: **1,609 → 683** (`nvimz/config` + `nvimz/*`).

Why move `infra/*` under `nvimz/` instead of leaving it? Because the audit shows `infra/` is a
grab-bag of unrelated concerns (static config, caching, package management, diagnostics,
reporting, rendering, parser setup, licensing).
A single `nvimz` namespace makes ownership obvious and collides with nothing. This is the only
directory restructure in the mission; it is justified by ownership, not aesthetics.

---

## 3. Boot Sequence (explicit and ordered)

```
init.lua
│  _G.nvimz_start = vim.uv.hrtime()
└─ require("runtime")                       lua/runtime/init.lua
   ├─ assert: vim.fn.has("nvim-0.12") == 1
   ├─ vim.loader.enable()
   ├─ require("core")                       ← the only synchronous feature-free work
   │   ├─ globals → options → filetypes → keymaps → autocmds → commands
   └─ require("runtime.phases")
       ├─ phases VimEnter:    defer(0) → phase 1 → defer(0) → phase 2
       ├─ phases InsertEnter: once     → phase 3
       └─ phases FileType:    once/pattern=markdown → render-markdown setup
                          (registered after phase 1; an already-loaded
                           Markdown first buffer is handled there too)

   └─ VimEnter (once):
        ├─ defer(0): restore 'shada' and `rshada!`
        ├─ if UI: dashboard.setup()
        └─ if elapsed > 10 ms: notify(warn)
```

Properties:

- Deterministic order: phase 2 starts only after phase 1 finishes. No two independent timers
  with the same deadline.
- Startup remains free of plugin setup and subprocesses.
- Native runtime plugin loading and filetype detection stay on. Only the viminfo read is deferred
  past the first render; the `shada` value is captured at startup and restored before `rshada!`.
- No state file is read or written at startup.
- Runtime plugin loading, filetype detection, and syntax loading stay native; only the viminfo read is deferred (measured in Phase 2).
- `core` remains independent of `nvimz` and `features` (one exception: keymaps reference feature
  entry points lazily, as today).

---

## 4. Module Contracts

| Module | Public API | Owns | Must not |
| --- | --- | --- | --- |
| `runtime` | side-effect bootstrap (no exported API) | process start order, startup warning, dashboard launch | plugin declarations, config data, diagnostics |
| `runtime.phases` | `setup()` | phase order, `vim.pack.add` calls, per-module setup isolation | feature internals, caching |
| `core.*` | options/autocmds/mappings/commands | editor behavior | plugin/package logic |
| `nvimz.config.languages` | `M.lsp_servers`, `M.formatters_by_ft`, `M.lsp_icons` | static language wiring | executable checks, UI |
| `nvimz.config.tools` | `M.core`, `M.lsp`, `M.formatters` (derived) | tool inventory | version probing |
| `nvimz.health` | `M.check()` (`:checkhealth nvimz`) | read-only environment report | writes, network, child Neovim |
| `nvimz.packages` | `M.status()`, `M.rollback()`, `M.clean()` | thin `vim.pack` UX | lockfile format, git plumbing |
| `nvimz.benchmark` | `M.run()` | startup measurement | deleting caches, mutating config |
| `nvimz.ui` | `M.show(title, lines)` | scratch buffer output | feature state |
| `nvimz.treesitter` | `M.setup()` | treesitter enablement + folds | buffer policy beyond large-file guard |

### Phase runner contract

```lua
local function run(module)
  local ok, err = pcall(function()
    require(module).setup()
  end)
  if not ok then
    vim.notify(("[nvimz] %s failed to initialize:\n%s"):format(module, err), vim.log.levels.ERROR)
  end
end
```

- Plugin acquisition is wrapped separately: if `vim.pack.add` fails (offline, missing `git`),
  nvimz reports the error and still runs the phase's feature setup for the plugins that are
  already on disk. A network failure must never disable pairs/completion/picker.
- One failing feature does not abort the others.
- No silent `pcall` anywhere else in the runtime.

---

## 5. Data Ownership (final)

| Data | Single owner |
| --- | --- |
| Plugin sources + phases | `nvimz/config/plugins.lua` |
| Plugin revisions | `nvim-pack-lock.json` (native `vim.pack` only) |
| LSP servers + formatters + icons | `nvimz/config/languages.lua` (deduplicated) |
| Required parsers | `nvimz/config/parsers.lua` |
| Core CLI tools | `nvimz/config/tools.lua` |
| LSP/formatter tool status | **derived** from `languages.lua` at check time |
| Host overrides | `machine/local.lua` only (no cache) |
| Startup history | none (benchmark measures on demand) |

---

## 6. Command Surface

| Today | Target | Rationale |
| --- | --- | --- |
| `:PackSync` | **removed** | `:PackUpdate` already shows a review buffer natively; quitting it applies nothing |
| `:PackUpdate` | `:PackUpdate` → `vim.pack.update()` | native confirm buffer, changelog, log, lockfile |
| `:PackRollback` | `:PackRollback` → `vim.pack.update(nil, { offline = true, target = "lockfile" })` | native rollback; 3 lines |
| `:PackStatus` | `:PackStatus` → `vim.pack.get()` summary (no subprocess) | keeps nvimz phase context; fixes D-3 |
| `:PackClean` | `:PackClean` → `vim.pack.del(inactive)` + orphan parser prune | drops cache/snapshot deletion |
| `:PackValidate` | **removed** | `:checkhealth nvimz` + `:checkhealth vim.pack` |
| `:PackDoctor` | **removed** | `:checkhealth nvimz` |
| `:ToolDoctor` | **removed** | `:checkhealth nvimz` |
| `:PackReport` | **removed** | generated artifact duplicated health output |
| `:PackSnapshot` | **removed** | lockfile + `git` already record the same state |
| `:PackBenchmark` | `:NvimzBenchmark` | name reflects ownership; non-destructive |
| `:ParsersUpdate` | `:ParsersUpdate` | unchanged |
| `:License` | `:License` | opens `LICENSE`; no embedded copy |
| `:LspInfo/Log/Start/Stop/Restart` | **deferred** (LSP domain) | overlaps native `:lsp stop/restart`; decision belongs to the LSP redesign |

Command count: **13 runtime commands → 7** (PackUpdate, PackRollback, PackStatus, PackClean,
ParsersUpdate, NvimzBenchmark, License). Five LSP commands remain unchanged and explicitly
out of scope.

---

## 7. Diagnostics

`:checkhealth nvimz` is the single environment report. It is read-only and spawn-free:

1. **Neovim / nvimz** — version, `vim.pack` availability, startup target.
2. **Core tools** — `git`, `rg`, `fd` (required ⇒ `health.error`; optional ⇒ `health.warn`).
3. **Language servers** — one entry per `languages.lsp_servers` entry, executable check only.
   Missing ⇒ `warn` (nvimz is zero-Mason; absence is valid).
4. **Formatters** — derived from `formatters_by_ft` → `formatter_binaries`.
5. **Treesitter** — required parsers via `vim.treesitter.language.inspect` (in-process).
6. **Plugins** — `vim.pack.get()` active state, lockfile presence, phase-3 plugins not yet active
   (reported as expected, not as an error).
7. **Machine** — `machine/local.lua` presence, effective `python3_host_prog`.

Native `:checkhealth vim.pack` remains available for packaging internals; nvimz does not wrap it.

` :NvimzBenchmark` runs 3 child `nvim --startuptime` processes (explicit user action), prints
min/median/max and the 10 slowest sourced modules, and never deletes `~/.cache/nvim/luac`.

---

## 8. Package Management Mapping

Everything below is native; nvimz only supplies command entry points and the plugin declarations.

| Operation | Mechanism |
| --- | --- |
| Install missing plugins | `vim.pack.add(specs)` (phase 1/2/3) |
| Update with review | `vim.pack.update()` |
| Revert to locked revisions | `vim.pack.update(nil, { offline = true, target = "lockfile" })` |
| Read revisions | `vim.pack.get()` |
| Remove inactive | `vim.pack.del(names)` |
| Lockfile | written/read by `vim.pack` |
| Packaging health | `:checkhealth vim.pack` |
| Update log | `stdpath("state")/nvim-pack.log` |

---

## 9. What Does Not Change

- Phase composition and timing (5 / 6 / 2 plugins; `VimEnter` deferred, `InsertEnter`, markdown).
- Feature modules and their setup functions.
- Native LSP (`vim.lsp.start`), completion, treesitter, picker, oil, mini.*, DAP, AI behavior.
- `nvim-pack-lock.json` location and schema.
- `machine/local.lua` contract (only loading becomes direct).
- Startup target `< 10 ms` and the "zero-Mason / `$PATH`" policy.

---

## 10. Migration Plan (Phase 2, ordered, each step verified)

| Step | Change | Verification |
| --- | --- | --- |
| 1 | Flatten `runtime/`: merge bootstrap + loader + `:License` into `runtime/init.lua`, delete 3 files | `nvim --headless -c qa`, startuptime, `:License` exists |
| 2 | Remove startup hacks from `core/globals.lua` / `runtime/init.lua` (loadplugins, shada, filetype replay) | filetype probe for file argument; cold/warm benchmark; `:messages` clean |
| 3 | Make keymaps/commands synchronous; remove `pack_commands_created` | command inventory; `:map` check; startuptime |
| 4 | Move static data to `nvimz/config/`, delete `infra/registry/init.lua`, dedupe `languages.lua`, derive tool lists | `require` all consumers headless; `:checkhealth nvimz` |
| 5 | Remove `infra/cache` + telemetry; load `machine.local` directly | edit a temp `machine/local.lua`, verify effect without restarting cache; no state file write |
| 6 | Replace `infra/deps` with `nvimz/packages`; remove 8 files | `:PackStatus`, `:PackRollback` dry run, `:PackClean` on a scratch plugin set |
| 7 | Replace health/report/deps diagnostics with `nvimz/health` + `nvimz/benchmark`; trim commands | `:checkhealth nvimz`, `:NvimzBenchmark`, command inventory |
| 8 | Update docs (`README`, `docs/{architecture,commands,performance,languages}.md`) and scripts (`manage`, `doctor`, `setup` messages) | link/command audit; no references to deleted modules |

Each step must pass: `luac`/`loadfile` syntax check, headless startup, command smoke test, and a
warm-startup measurement. A regression above +0.5 ms stops the step for review.

All eight steps are complete. Native runtime plugin loading and filetype detection were kept even
though they cost more than the previous deferral hacks; see D11 in `runtime-decisions.md`.

---

## 11. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Native `vim.pack.update()` confirmation buffer changes UX | high | medium | documented; review buffer is safer than silent checkout |
| Removing `loadplugins=false` adds startup cost | medium | low | measure; revert only that line with evidence |
| Removing `shada`/filetype deferral slows startup | medium | low | measure; keep the filetype replay only if >0.5 ms gain and correctness holds |
| `:PackRollback` semantics differ from old `git checkout` | medium | medium | document "revert to lockfile revs"; verify on a scratch plugin |
| Feature modules break on moved require paths | medium | high | 3 known call sites; full headless load test of every feature module |
| Users scripted against removed commands | low | medium | document mapping table; removed commands had no auto-completion |
| `nvimz/config` collides with a plugin namespace | very low | low | `nvimz` prefix already owns picker |
| `vim.pack` is marked experimental | accepted | medium | it is already the only package manager in use; no change in exposure |

---

## 12. Rejected Alternatives

| Alternative | Why rejected |
| --- | --- |
| Keep `infra/deps` and harden it | Reimplements a native subsystem; permanent maintenance and divergence risk |
| Build one "nvimz framework" module with registries and lifecycle hooks | Explicitly out of bounds; increases abstraction over a config |
| Move all `features/` under `nvimz/` | Cosmetic churn; feature domain is out of mission scope |
| Replace mini.nvim with hand-written Lua | Expensive, fragile, worse UX; mini provides real value |
| Keep the custom cache for "fast" machine config | The cache is the defect; direct `require` is cheaper and correct |
| Add a compatibility shim for removed commands | Would preserve dead functionality; docs mapping is enough |

---

## 13. Success Criteria for Phase 2

Mechanically checkable:

- `lua/infra/` no longer exists; 41 Lua files at most.
- `require("infra.*")` appears nowhere.
- `runtime/` is two files.
- Startup commands = 7 runtime commands + 5 LSP commands.
- Per-module `pcall` isolation with named error notifications; no phase-wide `pcall`.
- No state file written during startup (`strace`-free check: no `nvimz_cache.json` created).
- `:checkhealth nvimz` returns sections and each entry is truthful on this host.
- Warm startup ≤ baseline + 0.5 ms (target: equal or better).
- All feature modules load headless; `:PackStatus`, `:PackUpdate` (review buffer), `:PackRollback`,
  `:PackClean`, `:NvimzBenchmark`, `:License`, `:ParsersUpdate` exist and are documented.
