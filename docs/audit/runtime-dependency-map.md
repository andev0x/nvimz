# Runtime Dependency Map

**Phase:** 1 — Architectural Audit & Design Baseline
**Date:** 2026-11-01
**Scope:** runtime bootstrap, core, infrastructure, and the feature interfaces they own.

This map was built from the actual `require` calls and verified at runtime with
`package.loaded`. It is not derived from directory names.

---

## 1. Boot Call Graph (actual)

```
Neovim
└─ init.lua
   ├─ _G.nvimz_start_time = vim.uv.hrtime()
   └─ require("runtime")                      [lua/runtime/init.lua]
      ├─ require("runtime.bootstrap")          version guard (nvim-0.12)
      ├─ require("runtime.loader")             vim.loader.enable()
      ├─ require("core")                       [lua/core/init.lua]
      │  ├─ core.globals                       leader / netrw / loadplugins / shada / filetypes
      │  ├─ core.options                       options; vim.schedule(clipboard, machine)
      │  ├─ core.filetypes                     *.gotmpl BufRead/BufNewFile
      │  ├─ core.keymaps                       vim.schedule(all mappings)
      │  ├─ core.autocmds                      yank / resize / large-file / LspAttach / FileType→LSP
      │  └─ core.commands.setup()              vim.schedule(12 commands)
      ├─ require("runtime.phases").setup()     registers all phase triggers
      ├─ require("runtime.events").setup()     registers :License
      └─ nvim_create_autocmd("VimEnter", once) telemetry, filetype/plugin/shada replay,
                                               dashboard, >10ms warning
```

Nothing in the immediate path touches `infra.*` except `core.options` (scheduled, later) and
`core.commands` (command bodies are closures; nothing is required until invoked).

---

## 2. Immediate vs Deferred Edges

| Edge | When resolved |
| --- | --- |
| `core.options → infra.cache` | `vim.schedule` after startup |
| `core.options → machine.local` | `vim.schedule` after startup (via cache) |
| `core.autocmds → features.lsp.start` | per `FileType`, `vim.defer_fn(0)` |
| `core.keymaps → features.editing.terminal` | keypress |
| `core.keymaps → features.interface.dashboard` | keypress |
| `runtime.phases → infra.registry` (plugins) | deferred `VimEnter` / `InsertEnter` |
| `runtime.phases → infra.cache` | deferred `VimEnter` |
| `runtime.phases → features.*` | deferred `VimEnter` / `InsertEnter` / `FileType=markdown` |
| `runtime.init → infra.cache` | `vim.schedule` at `VimEnter` |
| `runtime.events → infra.license` | `:License` |
| `core.commands → infra.{deps,health,report}` | user command |
| `core.commands → scripts/parsers` | `:ParsersUpdate` (jobstart) |

---

## 3. Module Dependency Table

| Module | Requires | Relationship |
| --- | --- | --- |
| `runtime/init` | `runtime.bootstrap`, `runtime.loader`, `core`, `runtime.phases`, `runtime.events`, `features.interface.dashboard` (lazy), `infra.cache` (lazy) | orchestrator |
| `runtime/phases` | `infra.registry` (all 4 tables), `infra.cache`, `features.interface.{theme,icons,statusline,scope_line,markdown}`, `infra.treesitter`, `features.lsp`, `features.editing.{files,pairs,completion}`, `features.search.pick`, `features.git`, `features.format`, `features.dap`, `features.ai` | **highest fan-out** |
| `runtime/events` | `infra.license` | 1 consumer |
| `core/options` | `infra.cache`, `machine.local` (optional) | **immediate config depends on persistence layer** |
| `core/autocmds` | `features.lsp` | LSP trigger |
| `core/commands` | `infra.deps`, `infra.health`, `infra.report.{doctor,benchmark,maintenance}` | command surface |
| `infra/registry/init` | `infra.registry.{languages,plugins,tools,parsers}` | **eager aggregation** |
| `features/lsp/servers` | `infra.registry.languages` | data |
| `features/lsp/init` | `infra.registry.languages`, `features.lsp.{servers,diagnostics,attach,keymaps,inlay}` | domain |
| `features/format` | `infra.registry.languages` | data |
| `infra/health/init` | `infra.registry` (all), `infra.health.{check,render}`, `infra.view`, `vim.health` | diagnostics |
| `infra/report/doctor` | `infra.registry` (all), `infra.health.check`, `infra.view` | diagnostics |
| `infra/report/maintenance` | `infra.registry` (all), `infra.health.check`, `vim.system` | diagnostics + repo write |
| `infra/report/benchmark` | `infra.cache`, `infra.view`, `vim.system`, `vim.fn.delete` | diagnostics |
| `infra/deps/init` | all `infra.deps.*` (lazy) | facade |
| `infra/deps/update` | `git`, `lockfile`, `infra.health`, `infra.report.maintenance`, shell `scripts/parsers` | **health → report → fs write chain** |
| `infra/deps/status` | `git`, `infra.health.check`, `infra.registry.tools` | diagnostics |
| `infra/deps/sync` | `git`, `infra.view` | diagnostics |
| `infra/deps/snapshot` | `git`, `infra.cache` | persistence |
| `infra/deps/clean` | `infra.registry.parsers` | cleanup |
| `infra/deps/lockfile` | `vim.pack.get`, `git` | **duplicates native lockfile** |
| `infra/treesitter` | — (treesitter API) | infra |

**Cycles:** none detected. The graph is a tree rooted at `runtime`. There is one awkward
direction: `runtime/runtime init → infra.cache → JSON file → machine config`, which makes startup
configuration depend on mutable disk state.

---

## 4. Data Ownership

| Data | Current owner | Consumers | Duplication |
| --- | --- | --- | --- |
| Plugin sources per phase | `infra/registry/plugins.lua` | `runtime/phases.lua` | none |
| Plugin revisions | `nvim-pack-lock.json` (native) **and** `infra/deps/lockfile.lua` writes it | `vim.pack`, `deps/rollback` | native file is authoritative; custom writer risks divergence |
| LSP server specs | `infra/registry/languages.lua::M.lsp_servers` (defined twice) | LSP feature, `:LspStart` | duplicated inside one file |
| LSP tool inventory | `infra/registry/tools.lua` | health/doctor/status | **duplicates `languages.lua`** |
| Formatter map | `languages.lua::formatters_by_ft` | conform | none |
| Formatter binaries | `languages.lua::formatter_binaries` | *nobody* (dead data) | partially duplicated in `tools.lua` |
| Parser pins (Lua) | `infra/registry/parsers.lua` | clean, health, doctor, maintenance | duplicated with `scripts/parsers` (shell) and `scripts/doctor` |
| Core tool list | `infra/registry/tools.lua` | health, status, doctor, maintenance | duplicated in `scripts/doctor` |
| Startup history | state JSON | benchmark, snapshot | — |
| Machine overrides | `machine/local.lua` **and** state JSON cache | options | **two sources of truth** |
| Phase completion flags | state JSON | nothing | dead |

---

## 5. Subprocess Inventory

| Source | Triggers | Process count | Blocking |
| --- | --- | --- | --- |
| `vim.pack.add` | plugin missing on disk | `git clone` per missing plugin, parallel | yes (documented) |
| `infra/deps/status` | `:PackStatus` | 4–5 git calls per plugin (~50–65) | yes (`:wait()`) |
| `infra/deps/sync` | `:PackSync` | `fetch` + branch probe + 2 `rev-parse` per plugin (~50–65) | yes |
| `infra/deps/update` | `:PackUpdate`, `scripts/manage --update` | 4–5 git per plugin, then `scripts/parsers` (git ×15 + `cc`) | yes |
| `infra/deps/lockfile` | after update | 1 `rev-parse` per plugin | yes |
| `infra/deps/snapshot` | `:PackSnapshot` | 2–3 git per plugin | yes |
| `infra/health/check.version` | `:ToolDoctor`, `:PackDoctor`, reports | 1 process per tool (7 today) | yes |
| `infra/health/run` | `:PackValidate` | **nested `nvim --headless`** + `git status` per plugin | yes |
| `infra/report/benchmark` | `:PackBenchmark` | 6 nested `nvim` | yes |
| `infra/report/maintenance` | `:PackReport`, update | 1 nested `nvim` + tool versions | yes |
| `features/ai` | first `InsertEnter` | `curl` + possibly `ollama serve` | async |
| LSP servers | `FileType` | 1 per matching server | async |

No subprocess runs on the immediate startup path. This is a real strength.

---

## 6. Filesystem and Persistent State

| Path | Written by | Read by | Lifecycle |
| --- | --- | --- | --- |
| `nvim-pack-lock.json` (repo) | `vim.pack` **and** `deps/lockfile.lua` | `vim.pack`, `deps/rollback`, `deps/status` | version-controlled |
| `stdpath("state")/nvimz_cache.json` | startup telemetry, phase flags, machine config | options, benchmark, snapshot | every session |
| `stdpath("state")/nvim-pack.log` | `vim.pack` | humans | append |
| `stdpath("cache")/luac` | `vim.loader` | `vim.loader`; **deleted by `:PackBenchmark`** | rebuild |
| `<config>/snapshots/snapshot_*.json` | `:PackSnapshot` | humans | gitignored, pruned to 5 |
| `<config>/MAINTENANCE_REPORT.md` | `:PackReport`, `:PackUpdate`, `scripts/manage` | humans | **committed and stale** |
| `~/.local/share/nvim/site/parser/*.so` | `scripts/parsers`, pruned by `:PackClean` | treesitter | AOT |
| `~/.local/share/nvim/site/pack/core/opt/*` | `vim.pack` | `vim.pack` | managed |
| `stdpath("state")/lsp.log` | Neovim LSP | `:LspLog` | Neovim-managed |

---

## 7. Failure Isolation Matrix

| Failure | Current behavior | Isolation |
| --- | --- | --- |
| Missing LSP binary | `features/lsp/servers.lua:8-17` notifies once, skips server | good |
| Missing formatter | conform reports on use; startup unaffected | good |
| Missing treesitter parser | `infra/treesitter` skips (`parser_available`) | good |
| Missing plugin on disk, network available | `vim.pack.add` installs during the phase | acceptable |
| Missing plugin on disk, network unavailable | `vim.pack.add` **raises**; `load_phase` does not `pcall` it ⇒ the entire phase (theme, LSP, editing) never initializes | **poor** |
| Error in any `setup()` | `pcall(setup)` discards it; no notification, no log | **poor** |
| Invalid `machine/local.lua` | `pcall(require)` falls back silently; stale cache may mask the change | poor |
| Missing `ollama` | `ensure_ollama_running` returns; gp.nvim still configures | acceptable |
| Missing `nvim-jdtls` | `packadd` silently no-ops; `pcall(require)` returns ⇒ Java ftplugin is dead code | acceptable but dead |
| Invalid state JSON | `state.load` falls back to `{}` | good |
| Corrupt lockfile | native `vim.pack` repairs per its docs | good |
| Missing `git` | `vim.pack` errors on install/update; core editor still starts | acceptable |

---

## 8. External Boundary (Editors ↔ Shell)

```
scripts/setup   → system package managers (brew/pacman/apt), rustup, go install
scripts/parsers → git clone + cc → ~/.local/share/nvim/site/parser/*.so + queries/
scripts/manage  → nvim --headless → infra.deps.update → git, scripts/parsers
scripts/doctor  → static tool/parser list (independent of Lua registry)
```

The shell side duplicates Lua-side lists (tools, parsers). Every list addition currently requires
editing 2–3 places. This is a maintenance cost, not a runtime cost.

---

## 9. What the Map Implies

1. `runtime` is a clean single root; keep that shape.
2. `infra/registry/init.lua` is an eager service locator over static data; consumers should
   require the data module they need.
3. `infra/cache` introduces a second configuration source (machine state) and dead state
   (phase flags); it is not load-bearing for correct startup.
4. `infra/deps` is a parallel package-manager implementation; `vim.pack` already owns the
   lockfile, update, rollback, and review workflow.
5. Diagnostics are the most duplicated subsystem (4 surfaces, 3 renderers, 3 copies of the
   startup-log parser).
6. Failure isolation needs exactly two fixes in the runtime: `pcall` around `vim.pack.add`
   reporting the error, and explicit reporting for phase `setup` failures.

These implications drive the target architecture and the decisions register.
