# Progressive Loading Plan

**Phase:** 1 — Loading strategy and dependency classification (Gate A)
**Date:** 2026-11-02
**Status:** **Implemented in Gate B.** The approved decisions below are the ones that shipped.
Measured before/after evidence: `docs/audit/progressive-performance-final-report.md`.
**Inputs:** `docs/audit/progressive-performance-baseline.md` (measured), current runtime source,
`docs/architecture/runtime-decisions.md`, `docs/audit/runtime-final-report.md`.

> **Reading note:** sections 1–11 preserve the Gate A proposal as a record. The shipped decisions
> are in §12–13 and in `docs/audit/progressive-performance-final-report.md`; where they differ,
> those are authoritative.

The plan keeps the existing architecture: one bootstrap, one native `vim.pack` declaration file,
one phase runner, feature modules with `setup()` functions, and native lifecycle events. It does
not add a scheduler, registry, cache, or dependency framework.

The guiding rule is unchanged:

> Initialize what is necessary immediately. Load what is useful next without blocking interaction.
> Initialize specialized features only when needed. Perform optional background work only when the
> editor can afford it.

---

## 1. What the baseline says the plan must fix

| Baseline finding | Required outcome |
| --- | --- |
| F-1: phase 1 is a single 24 ms main-loop block | Split into a small first-render block plus bounded deferred chunks |
| F-2: phase 2 adds 10–21 ms, dominated by DAP | Stop configuring DAP until it is used |
| F-3: Markdown auto-loads in every session (5.3 ms, 21 modules) | Load the Markdown plugin only for Markdown buffers |
| F-4: dashboard is 36 ms after first themed paint | Create the dashboard before the first paint |
| F-5: startup warning interrupts the first file paint | Remove the interactive warning |
| F-6: first insert loads gp + Copilot (7–12 ms, ~300 MiB) | Trigger AI on AI intent, not on every insert |
| F-7: statusline first build can pull `vim.lsp`/`vim.diagnostic` | Guard optional modules; keep first paint cheap |
| F-8/F-9: LSP setup/config is timing-sensitive and loads `vim.lsp.protocol` eagerly | Make setup idempotent, ensure it precedes `start`, load capabilities per server |
| F-11: idle input handling is ~0.1 ms | Preserve it; the fix is chunking, not a new event system |
| F-12: unused features cost memory | Leave unused plugins and servers unloaded |

---

## 2. Tier definitions for nvimz

| Tier | Meaning | Execution point | Constraint |
| --- | --- | --- | --- |
| 0 | Immediate core | synchronous, before `VimEnter` | no plugin setup, no subprocess, no scans |
| 1 | First-render critical | synchronous `VimEnter`, before the first paint | only what the first screen needs |
| 2 | Deferred normal editing | after the first paint, in 2–3 bounded chunks | each chunk ≤ ~8 ms; no duplicate setup |
| 3 | On demand | first feature action (filetype, keymap, command) | first activation reliable, idempotent, errors named |
| 4 | Opportunistic background | **not used** | no warm-up, no idle queue |

**Tier 4 is intentionally empty.** The measured benefit of a background warm-up is zero: idle CPU
is already ~0, and the remaining costs (LSP indexing, Copilot server) are better paid only when
the feature is requested. Adding idle work would compete with typing and complicate shutdown.

---

## 3. Target boot sequence

```
init.lua
└─ runtime/init.lua
   ├─ version guard
   ├─ capture + blank 'shada'
   ├─ require("core")                         Tier 0, ~2.1 ms
   └─ runtime.phases.setup()                  registers triggers only

VimEnter (one consolidated, synchronous handler)
├─ Tier 1 (before first paint)
│  ├─ vim.pack.add({ tokyonight, mini.nvim })
│  ├─ theme → icons → statusline
│  ├─ nvimz.treesitter (first buffer highlighting/folds)
│  ├─ if argc() == 0: dashboard.setup()
│  └─ if a loaded buffer is Markdown: markdown.ensure()
├─ schedule chunk A: pairs, completion, picker, scope_line
├─ schedule chunk B: lsp.setup() (cheap; servers on first start)
├─ schedule chunk C: git, format, oil
└─ defer(0): restore 'shada' + rshada!

FileType=markdown (once)            → markdown.ensure()        Tier 3
First DAP key / :Dap* command       → dap.ensure()             Tier 3
First AI key / :Gp* / :Copilot      → ai.ensure_gp()/copilot() Tier 3
FileType with configured server     → lsp.start() → lsp.ensure() + servers.start()
```

No `InsertEnter` phase. No background queue. Each trigger is a named function with an
`initialized` guard.

---

## 4. Component classification

### 4.1 Tier 0 — Immediate core (unchanged)

| Component | Current | Proposed | Trigger | Dependencies | Cost | Benefit | Failure | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `core/globals` | sync | keep | `require("core")` | none | ~0.1 ms | leader/netrw/providers correct | error aborts startup | required for keymaps/behavior |
| `core/options` | sync | keep | same | none | ~0.2 ms | editor options, undofile, folds | error aborts startup | required for first buffer |
| `core/filetypes` | sync | keep | same | none | ~0.1 ms | `*.gotmpl` detection | broken detection only | native detection preserved |
| `core/keymaps` | sync | keep; add lazy DAP/AI stubs | same | feature entry points only | ~0.4 ms | keys exist from first keypress | stub reports error | keys must not disappear |
| `core/autocmds` | sync | keep; FileType→LSP stays | same | none | ~0.1 ms | yank, resize, large-file, LSP trigger | isolated per callback | native lifecycle |
| `core/commands` | sync | keep | same | none | ~0.1 ms | 7 commands exist | command error is visible | cheap and deterministic |
| `runtime/init.lua` | sync + VimEnter | simplify VimEnter; remove warning; keep shada | startup | core | ~2.1 ms total config | deterministic bootstrap | reports shada failure | existing design |
| `runtime/phases.lua` | 3 phases | restructure into Tier 1 + 3 chunks + on-demand ensures | `VimEnter`/events | plugin declarations | ~0.3 ms | bounded stalls | per-module `pcall` + name | one owner for loading |

No filesystem scans, subprocesses, or plugin setup are added to Tier 0.

### 4.2 Tier 1 — First-render critical

| Component | Current | Proposed | Trigger | Dependencies | Est. cost | Benefit | Failure | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `tokyonight` + `mini.nvim` | added in phase 1 | add in sync `VimEnter` | `VimEnter` | none | ~1.2–1.5 ms | theme/icons available before paint | report and continue with default colors | prevents theme flash |
| `features.interface.theme` | deferred ~30 ms | **sync before first paint** | `VimEnter` | tokyonight | 3.5–5.2 ms | correct colors at first paint | report; editor still starts | first-render correctness |
| `features.interface.icons` | deferred | **sync** | `VimEnter` | mini.icons | 1.6–2.3 ms | statusline/picker glyphs correct | report; fallback text | prevents icon flash |
| `features.interface.statusline` | deferred | **sync** | `VimEnter` | mini.statusline, theme colors, icons | setup 0.9–3.7 ms; first build ~1 ms after guards | no default statusline flash | report; default statusline remains | first-render correctness |
| `nvimz.treesitter` | phase 1 | **sync** | `VimEnter` | parsers (native) | 0.1–0.25 ms setup; first Go parser ~8 ms | correct syntax/folds at first content | skips unsupported parsers | no native-syntax → treesitter switch |
| `features.interface.dashboard` | `vim.schedule` after phases | **sync, only when `argc()==0`** | `VimEnter` | theme highlights | 3.1–3.5 ms | dashboard is the first screen; no intro flash | report; empty buffer remains | fixes F-4 |
| `features.interface.markdown` | added in phase 1 for everyone | **only if the first session has a Markdown buffer** | `VimEnter` condition | render-markdown plugin | 5.2–5.4 ms only in that case | rendered first paint for Markdown files | report; native Markdown remains | avoids 5.3 ms in every other session |

**Trade-off:** Tier 1 moves ~8–15 ms of work in front of the first paint. The first file content
may move from ~40–44 ms to roughly ~45–55 ms, while the dashboard moves from ~71 ms to a target of
~30–40 ms and the native intro disappears. This is the deliberate trade required by
"first-render correctness is more important than an artificially low startup number." The
init→VimEnter metric is still reported separately and must not be conflated with first paint.

**Statusline guards (small change, large effect):**

- `get_lsp()` returns `""` when `package.loaded["vim.lsp"] == nil` (no client can exist yet).
- `get_diagnostics()` returns `""` when `package.loaded["vim.diagnostic"] == nil`.
- Existing `LspAttach`/`DiagnosticChanged` redraw paths refresh the statusline when the modules
  do load.

Without these guards, the first statusline build pulls `vim.lsp` and `vim.diagnostic` and costs
6.5–9.1 ms. With them, the measured cost after icons is ~1.0–1.1 ms.

### 4.3 Tier 2 — Deferred normal editing (three bounded chunks)

| Component | Current | Proposed | Trigger | Dependencies | Est. cost | Benefit | Failure | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Chunk A: `features.editing.pairs` | phase 1 | chunk A | after first paint | mini.pairs | 1.0–1.2 ms | pairs ready before first insert | report; plain editing works | normal editing |
| Chunk A: `features.editing.completion` | phase 1 | chunk A | after first paint | mini.completion | 1.3–1.8 ms | completion ready before first insert | report; no completion | normal editing |
| Chunk A: `features.search.pick` | phase 1 | chunk A | after first paint | native picker | 0.5–0.6 ms | `<leader>f*` registered | report; keys may be absent | keeps keymaps deterministic |
| Chunk A: `features.interface.scope_line` | phase 1 | chunk A | after first paint | treesitter | ~0.2 ms | scope line on cursor move | report; no guide | not first render |
| Chunk B: `features.lsp` | phase 1 (5.3–6.4 ms) | chunk B, **cheap setup** | after first paint | vim.lsp, diagnostics, attach | ~1.5 ms after moving capabilities | LSP machinery ready before first code attach | report; LSP skipped | setup must precede `start` |
| Chunk C: `features.git` | phase 1 | chunk C | after first paint | mini.git, mini.diff | 2.4–2.8 ms | git keys/diff signs available | report; no git UI | normal editing |
| Chunk C: `features.format` | phase 2 | chunk C | after first paint | conform | 0.7–1.3 ms | format-on-save armed before first save | report; no formatting | normal editing |
| Chunk C: `features.editing.files` | phase 1 | chunk C | after first paint | oil, oil-git-status | 3.7–5.0 ms | `:Oil` and `<leader>e` exist | report; explorer unavailable | command availability |

**LSP split (F-9):** move `local capabilities = vim.lsp.protocol.make_client_capabilities()` out of
the top level of `features/lsp/servers.lua` and build it on first `enable_server`. Move
`require("features.lsp.servers")` out of `features/lsp/init.lua`'s top-level `setup_commands` path;
require it inside `LspStart` and `M.start`. This removes 4.0–4.4 ms from general LSP setup; the
first server start pays it once. `M.start(filetype, bufnr)` calls `M.setup()` first (idempotent) so
`LspAttach` hooks exist before any server can attach (F-8).

**Chunk size:** A ≈ 3–4 ms, B ≈ 1.5–2 ms, C ≈ 7–9 ms. Each chunk is a single function chained from
the previous with `vim.defer_fn(..., 0)`. This is not a scheduler: three explicit functions, one
order, one ownership boundary.

### 4.4 Tier 3 — On-demand

| Component | Current | Proposed | Trigger | Dependencies | Est. cost | Benefit | Failure | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `render-markdown.nvim` + `features.interface.markdown` | added in phase 1, auto-setup every session | add plugin + setup on first Markdown buffer; also in Tier 1 if the startup buffer is Markdown | `FileType=markdown` once | render-markdown | 5.2–5.4 ms once | no cost in non-Markdown sessions | report; native Markdown remains | F-3 |
| `features.dap` (dap, nio, dap-ui, dap-go) | plugins + full setup in phase 2 | add plugin specs in Tier 2 (cheap; keeps `:Dap*` commands); run `dap.ensure()` on first DAP key or `:Dap*` | first key / command | nvim-dap, dap-ui, dap-go | setup 9.9–16.3 ms once | no cost in non-debug sessions | report; basic `:Dap*` may still work; keymaps explain failure | F-2 |
| `features.ai` gp.nvim | loaded on first insert | `ai.ensure_gp()` on first AI key/command | `<leader>aa/a1/a2/a3/ar/ap/ab`, `<A-CR>`, `:Gp*` | gp.nvim, Ollama | 3.2–5.3 ms require + setup | no AI cost unless used | report; AI keys remain and report | F-6 |
| `features.ai` copilot.lua | loaded on first insert | **decision required** (see §7) | explicit `<leader>at`/`:Copilot`, or opt-in first insert | copilot.lua + language server | 4.8–8.4 ms + ~300 MiB server | avoids ~300 MiB for non-users | report; inline suggestions off until enabled | F-6/F-12 |
| Ollama reachability check | first insert | inside `ensure_gp` only | first AI chat action | curl/ollama | async, no block | removes subprocess from typing | warning if missing | AI intent only |
| `features.editing.terminal` | keymap require | keep | `<leader>tt/tb` | native terminal | ~0 | unchanged | report | already demand-driven |
| `nvimz.health` | `:checkhealth` | keep | command | none | on demand | unchanged | health output | already demand-driven |
| `nvimz.packages` | `:Pack*` | keep | command | vim.pack | on demand | unchanged | command error | already demand-driven |
| `nvimz.benchmark` | `:NvimzBenchmark` | keep | command | child nvim | on demand | unchanged | error message | already demand-driven |
| `nvimz.ui` | report buffer | keep | commands | none | on demand | unchanged | fallback stdout | already demand-driven |

**DAP command availability:** adding the DAP plugin specs in Tier 2 keeps `:Dap*` commands
registered. A lightweight `features.dap.ensure()` is called by:

1. each `<leader>d*` keymap stub (registered in Tier 2),
2. a `CmdlineLeave` autocmd that calls `ensure()` when the command line starts with `Dap`.

The autocmd is 4–6 lines, native, and only runs the check once (`ensure` is idempotent). If it
proves unreliable, the fallback is to keep the keymap trigger and document that `:Dap*` commands
work after the first DAP key. This is the only place where command-line interception is proposed.

**AI command availability:** the AI keymaps are registered by `core/keymaps.lua` (or a small
Tier 2 keys module) as functions that call `ensure_*()` and then execute the action. This preserves
the keys before the plugin is loaded. `:Gp*`/`:Copilot` commands do not exist until the plugin is
added; the same `CmdlineLeave` pattern can cover them if the review approves it. The documented
entry points are the keymaps.

### 4.5 Tier 4 — Opportunistic background

**Nothing is scheduled.** No idle timer, no warm-up, no precomputed metadata, no background
loading queue. The measured idle CPU is already ~0 and all optional costs are better paid on use.
If a future component proves a measured benefit from idle work, it must be proposed separately
with its own trigger, budget, and skip conditions.

### 4.6 File-level inventory (every current Lua module)

| File | Tier | Loaded by / trigger | Note |
| --- | --- | --- | --- |
| `lua/runtime/init.lua` | 0 | `init.lua` | bootstrap, shada, VimEnter |
| `lua/runtime/phases.lua` | 0 | `require("runtime")` | registers triggers only |
| `lua/core/init.lua` | 0 | `require("core")` | aggregator |
| `lua/core/globals.lua` | 0 | core | leader, netrw off |
| `lua/core/options.lua` | 0 | core | options, machine override |
| `lua/core/filetypes.lua` | 0 | core | `*.gotmpl` |
| `lua/core/keymaps.lua` | 0 | core | core keys + lazy feature hooks |
| `lua/core/autocmds.lua` | 0 | core | yank/resize/large-file/LSP trigger |
| `lua/core/commands.lua` | 0 | core | 7 commands |
| `lua/features/interface/theme.lua` | 1 | `VimEnter` | before first paint |
| `lua/features/interface/icons.lua` | 1 | `VimEnter` | before statusline |
| `lua/features/interface/statusline.lua` | 1 | `VimEnter` | before first paint |
| `lua/features/interface/dashboard.lua` | 1 | `VimEnter` when `argc()==0` | first screen |
| `lua/features/interface/scope_line.lua` | 2 | chunk A | runtime cursor work |
| `lua/features/interface/markdown.lua` | 3 (1 if first buffer) | `FileType=markdown` / Tier 1 conditional | plugin-owned auto-setup |
| `lua/features/editing/pairs.lua` | 2 | chunk A | before first insert |
| `lua/features/editing/completion.lua` | 2 | chunk A | before first insert |
| `lua/features/editing/files.lua` | 2 | chunk C | oil, `:Oil`, `<leader>e` |
| `lua/features/editing/terminal.lua` | 3 | `<leader>tt/tb` | already keymap-driven |
| `lua/features/search/pick.lua` | 2 | chunk A | registers picker keys |
| `lua/nvimz/picker/native.lua` | 3 | first `<leader>f*` | implementation behind wrapper |
| `lua/nvimz/treesitter.lua` | 1 | `VimEnter` | first-buffer syntax/folds |
| `lua/features/lsp/init.lua` | 2 | chunk B | cheap setup + commands |
| `lua/features/lsp/attach.lua` | 2 | `lsp.setup` | `LspAttach` hooks |
| `lua/features/lsp/diagnostics.lua` | 2 | `lsp.setup` | diagnostic config/annotations |
| `lua/features/lsp/inlay.lua` | 2 | `LspAttach` | per-client inlay |
| `lua/features/lsp/keymaps.lua` | 2 | `LspAttach` | per-buffer keys |
| `lua/features/lsp/servers.lua` | 3 | first server start | capabilities moved here |
| `lua/features/git/init.lua` | 2 | chunk C | mini.git + mini.diff |
| `lua/features/format/init.lua` | 2 | chunk C | conform, format-on-save |
| `lua/features/dap/init.lua` | 3 | first DAP key/command | setup guard |
| `lua/features/ai/init.lua` | 3 | first AI key/command | gp/copilot split; Ollama here |
| `lua/nvimz/config/plugins.lua` | 0 | `runtime.phases` | static declarations |
| `lua/nvimz/config/languages.lua` | 3 | LSP/format/health use | static data |
| `lua/nvimz/config/parsers.lua` | 3 | health/packages use | static data |
| `lua/nvimz/config/tools.lua` | 3 | health use | static data |
| `lua/nvimz/health.lua` | 3 | `:checkhealth nvimz` | read-only |
| `lua/nvimz/packages.lua` | 3 | `:Pack*` | native wrappers |
| `lua/nvimz/benchmark.lua` | 3 | `:NvimzBenchmark` | 3 child runs |
| `lua/nvimz/ui.lua` | 3 | report commands | scratch buffer |
| `lua/machine/example.lua` | — | not loaded | template only |

---

## 5. Plugin declaration changes

`lua/nvimz/config/plugins.lua` currently has three groups. The proposal regroups declarations
without changing the native `vim.pack` shape:

| New group | Members | Loaded by |
| --- | --- | --- |
| `plugins.tier1` | tokyonight, mini.nvim | Tier 1 sync |
| `plugins.deferred` | oil.nvim, oil-git-status.nvim, conform.nvim | Tier 2 chunk C |
| `plugins.dap` | nvim-dap, nvim-nio, nvim-dap-ui, nvim-dap-go | Tier 2 add; setup on demand |
| `plugins.markdown` | render-markdown.nvim | Tier 3 (or Tier 1 only for a Markdown first buffer) |
| `plugins.ai` | gp.nvim, copilot.lua | Tier 3 on demand |

The lockfile does not change: all 12 plugins remain declared and managed by `vim.pack`.
`:PackStatus`/`:checkhealth nvimz` continue to report managed vs active plugins; after this change
more plugins will correctly show as inactive until used.

---

## 6. Per-component decisions and rationale

### 6.1 Keep Tier 0 synchronous

The core costs 2.1 ms and keymaps/commands must exist before the first keypress. Deferring them
would reintroduce the old "keys appear later" defect (runtime decisions D12). Leave it alone.

### 6.2 Theme, icons, statusline, treesitter, dashboard in Tier 1

These are the only components whose absence or lateness is visible on the first screen:

- theme → no default-color flash,
- icons/statusline → no missing or plain statusline,
- treesitter → no native-syntax → treesitter color switch,
- dashboard → no native-intro → dashboard layout shift.

The measured cost is 8–15 ms before first paint. This is the deliberate cost of correctness.
The first *content* paint is expected to stay in the same 40–55 ms range; the dashboard improves
from ~71 ms to a target of ~30–40 ms. This must be re-measured, not assumed.

### 6.3 Treesitter stays synchronous even though it is "enhancement"

It is 0.1 ms for an empty session. For a Go/Rust/C first buffer it pays the parser/query cost once,
before the first paint, instead of switching highlighting later. That is a first-buffer correctness
requirement, not an optimization.

### 6.4 Markdown is conditional, not always deferred

`render-markdown.nvim` auto-runs setup when added. Therefore:

- non-Markdown session: do not add the plugin at all (saves 5.2–5.4 ms and 21 modules),
- Markdown first buffer: add + setup in Tier 1 before the first paint,
- Markdown opened later: add + setup on `FileType=markdown` (once).

The explicit `features.interface.markdown.setup()` call remains for configuration ownership; the
plugin's own auto-setup is acknowledged in a comment. If the review prefers to rely solely on the
auto-setup, the module can be deleted (remove before replace).

### 6.5 LSP is Tier 2 setup + per-server Tier 3 start

LSP is normal editing, not a first-render feature. Keep the `LspAttach`/diagnostics/keymap setup
after the first paint, but make it cheap:

- no `vim.lsp.protocol` at module load,
- no `servers` require until a server is actually started,
- `M.start` calls `M.setup` first (idempotent) so attach hooks always exist.

First code file pays ~4 ms for capabilities + server spawn; subsequent files reuse it. Empty and
dashboard-only sessions never load `vim.lsp`.

### 6.6 DAP plugins in Tier 2, setup in Tier 3

Plugin runtime paths are cheap (~1.4 ms for nvim-dap alone; plugin scripts only register commands).
Setup (10–16 ms) configures dap-ui listeners, dap-go configurations, signs, and keymaps. It is
useless until a debug action. Keep commands alive by adding the specs in Tier 2 and trigger setup
on first use.

### 6.7 AI on AI intent

`InsertEnter` is an editing signal, not an AI signal. The baseline shows it loads gp + Copilot,
spawns the Copilot server (~302 MiB), and adds 7–12 ms before the next key. The plan moves gp to
the AI keymaps/commands and the Ollama check into gp setup.

Copilot needs a product decision because inline suggestions are expected during insert:

- **Option A (recommended): explicit.** Load Copilot on `<leader>at`/`:Copilot` or a first
  `InsertEnter` only when `vim.g.copilot_auto_start == true` (new opt-in). Users who never use
  Copilot never pay 300 MiB. This changes current default behavior.
- **Option B (preserve behavior): first InsertEnter, but only after Tier 2 completes.** Keeps
  inline suggestions working by default; still loads ~300 MiB on every editing session and adds a
  one-time 7–12 ms stall. Not demand-driven.
- **Option C: split.** Keep Copilot on first insert if `:Copilot` auth/state exists (e.g., a paid
  seat check), otherwise leave it off. More logic; not recommended for this mission.

The plan cannot choose A or B without approval because it changes user-visible AI behavior.
Everything else in this document is independent of that choice.

### 6.8 Remove the startup warning

The 10 ms threshold measures empty init→VimEnter. File opens legitimately add 5–12 ms of native
work. The warning is not actionable and is painted over the first file line. Remove the
interactive notification; keep `_G.nvimz_start_time` for the dashboard banner and
`:NvimzBenchmark`, and keep `:checkhealth nvimz`'s "startup target" information.

### 6.9 Keep the shada deferral

It is measured at ~0.7 ms and is already safe. Do not expand it into a general deferred-work
mechanism.

### 6.10 Do not touch

- Native filetype detection, syntax, runtime plugin loading.
- `vim.pack` commands and the lockfile.
- Picker implementation, LSP server table, health provider, benchmark.
- `core/keymaps` non-lazy mappings, `core/options`, `core/autocmds` behavior.
- `ftplugin/java.lua` (known LSP/Java domain issue, deferred by D-12).

---

## 7. Reliability and failure behavior

| Case | Required behavior |
| --- | --- |
| Plugin missing / install fails on demand | `pcall(vim.pack.add)`; notify with feature name; editor continues; keymap remains and reports again only when used |
| Feature `setup()` fails | named error notification; `initialized` is not set, so a later attempt can retry; no half-registered duplicate listeners |
| Missing executable (gopls, ollama, formatter) | single actionable warning per server/feature; feature skipped; editor usable |
| Unsupported filetype | no LSP/treesitter/markdown load; native behavior |
| First activation fails | error names the feature; subsequent activation retries; no silent disappearance |
| Repeated activation | `initialized`/`ready` guards; no duplicate autocmds, listeners, or keymaps |
| Short-lived session | Tier 1 runs, phases may not; no error; no background state |
| File opened immediately after startup | FileType handler works before Tier 2; `lsp.start` ensures setup; Markdown trigger works |
| Deferred chunk fails | only that module is reported; the next chunk still runs; editor usable |
| No UI (headless) | Tier 1 UI modules skipped, as today; core and file behavior unaffected |
| `:PackStatus` after change | reports more plugins as inactive until their trigger; no orphan/undeclared change |

No retry loops. No catch-all `pcall` that hides phase-wide errors.

---

## 8. Verification plan (Phase 2/3)

Every item is measured with the same boundaries as the baseline.

### 8.1 Correctness

- Headless startup: no messages/errors, `ft` correct for file args.
- Real PTY startup: first paint is themed, has custom statusline, and is the dashboard for empty
  startup; no native intro; no startup notification.
- Lua/Go/Markdown first buffer: filetype, treesitter, theme, statusline correct at first content.
- Markdown first buffer: rendered layout at first paint; non-Markdown session has no
  `render-markdown` modules loaded.
- DAP: first `<leader>db` / `:DapContinue` initializes exactly once; second use does not re-run
  setup; `:Dap*` commands exist before setup.
- AI: first AI key loads gp; second use does not duplicate setup; Copilot behavior per approval.
- LSP: `M.start` before `M.setup` still gets keymaps/inlay/diagnostic float; missing server warning.
- Unused-session check: empty session has no `dap`, `conform`, `oil`, `render-markdown`, `gp`,
  `copilot`, or `vim.lsp` modules loaded unless their trigger ran.
- `:checkhealth nvimz`, `:PackStatus`, `:License`, `:ParsersUpdate` unchanged.

### 8.2 Performance

Re-run exactly:

- `NVIM STARTED` n=10 after 5 warm-ups,
- init→VimEnter n=10,
- PTY first paint n=5 for empty/Lua/Go/Markdown,
- phase chunk completion (1 ms probe),
- `vim.on_key` input latency at 10/40/400 ms,
- feature activation costs (isolated),
- process-tree RSS for clean/empty/Lua/Go and first-insert AI,
- idle CPU at 1 s and 3 s.

Success criteria (to be confirmed against measured results, not assumed):

| Metric | Baseline | Target |
| --- | --- | --- |
| init→VimEnter | 6.73 ms median | ≤ 8 ms (core only; Tier 1 measured separately) |
| Dashboard first paint | 70.7 ms | ≤ 45 ms |
| Native intro before dashboard | 36 ms | 0 |
| First file content | 41–52 ms | ≤ 60 ms |
| Max input stall during startup | 41 ms | ≤ 10 ms |
| First insert stall | 6.8–11.6 ms | 0 with AI Option A; one-time 7–12 ms with Option B |
| Phase 1 block | 24 ms | split into ≤ 8 ms chunks |
| Markdown cost in non-Markdown session | 5.3 ms / 21 modules | 0 |
| Empty session modules | 166 | lower by ≥ 25 |
| Empty session tree RSS | 30.1 MiB | ≤ 30 MiB (no regression) |
| AI-unused session | gp inactive, Copilot inactive until insert | both inactive until AI intent |
| Idle input processing | ~0.1 ms | ≤ 0.5 ms |
| Idle CPU | ~0 | no increase |

If a target is not met, report the measured regression and its cause; do not hide it behind a
different boundary.

### 8.3 Failure tests

- Remove `gopls` from `PATH`; open Go file; expect one warning, no LSP, editor usable.
- Remove `ollama` from `PATH`; first AI key; expect a named warning, no crash.
- Temporarily point one plugin spec at a missing source in an isolated copy; expect a named
  plugin-install error and other chunks still running.
- Force a module `setup()` error in an isolated copy; expect one named error, later retry possible.
- Run 5 short-lived headless sessions; all exit 0.

---

## 9. Estimated outcome (design expectation, not measured yet)

> **Gate B note:** the table below is the original design expectation. Measured Gate B results are
> in `docs/audit/progressive-performance-final-report.md`; where they differ (first-activation
> costs, Go/Markdown first paint), the report is authoritative.

These are expectations derived from the measured component costs. They are not claims.

| Area | Expected change |
| --- | --- |
| First screen | Dashboard at first paint; no native intro; theme/statusline correct |
| First buffer | Same or ~5–15 ms later than today for file opens; correct highlighting from first paint |
| Startup input stalls | From 41 ms max to ≤ ~10 ms, because phase 1 is split |
| First insert | No AI load; ~0 ms extra |
| Non-Markdown sessions | −5.3 ms, −21 modules |
| Non-debug sessions | −10–16 ms setup, DAP plugins still addressable |
| Non-AI sessions | no gp/Copilot; potentially −300 MiB if Copilot is opt-in |
| Empty session modules | ~166 → ~140 (estimate; must be measured) |
| Memory (empty) | no material change; fewer optional modules |
| Complexity | plugin declarations regrouped; `phases.lua` still one file; no new framework |

---

## 10. Risks and trade-offs

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Tier 1 before first paint adds 8–15 ms | first file content may be ~5–15 ms later | measure; if first content regresses beyond 60 ms, reduce Tier 1 (e.g. defer icons) or split theme/dashboard |
| DAP command setup timing | `:Dap*` before first key may lack dap-ui/go config | `CmdlineLeave` trigger; otherwise document keymap-first behavior |
| AI behavior change (Option A) | Copilot suggestions no longer automatic | approval required; provide opt-in flag |
| Markdown auto-setup is plugin-owned | explicit setup call may duplicate | keep setup idempotent; delete the Lua module if review prefers |
| LSP `CmdlineLeave`/lazy commands | command may not exist before plugin add | keymaps are primary; verify `:Gp*`/`:Copilot` at review |
| More inactive plugins in `:PackStatus` | user may think plugins are missing | docs/health explain "inactive until trigger" |
| PTY measurement overhead | first-paint numbers are upper bounds | keep the same harness for before/after; compare deltas |
| Single host | results may not generalize | document; verify Linux later |

---

## 11. Explicitly out of scope / not proposed

- No `infra/` return, no custom package manager, no registries, no dependency injection.
- No universal scheduler, priority queue, or task bus.
- No new startup cache or serialized state.
- No new plugin solely for lazy loading.
- No rewrite of the picker, LSP server table, health provider, or packaging commands.
- No change to native filetype detection, syntax, or runtime plugin loading.
- No scheduled idle warm-up.
- No commit, tag, or publish.

---

## 12. Resolved decisions (Gate B)

1. **Tier 1 timing trade-off:** approved. Theme, icons, statusline, first-buffer Treesitter, and the
   dashboard initialize synchronously in `VimEnter` before the first paint. The core boundary
   (`init.lua → start of VimEnter`) is unchanged; Tier 1 duration is reported separately.
2. **Copilot trigger:** approved as opt-in. No `InsertEnter` startup. `<leader>at` is the first
   explicit activation and enables Copilot; later presses toggle it. `:Copilot` is served by a
   lazy stub. `gp.nvim` and Copilot are independent.
3. **DAP command behavior:** approved as demand-driven without `CmdlineLeave`. `CmdUndefined`
   resolves no-argument `:Dap*` commands; argument/range commands have small lazy stubs that
   preserve their arguments before re-dispatching to the plugin command. DAP plugins are added
   only on first activation.
4. **Markdown module:** removed. `features/interface/markdown.lua` was a redundant wrapper;
   render-markdown's own plugin script owns setup. The plugin is added only for a Markdown
   startup buffer or the first `FileType=markdown` event.
5. **Startup warning:** removed. `_G.nvimz_start_time` remains for the dashboard and benchmark.
   Genuine failures still produce named notifications.

---

## 13. Implementation record (Gate B)

This section records what shipped, including the differences from the proposal. It is the
authoritative description of the current loading boundaries.

### 13.1 Files changed

| Change | Result |
| --- | --- |
| `runtime/phases.lua` | Tier 1 + event-driven Tier 2/3 triggers; no phase1/2/3 callbacks |
| `runtime/init.lua` | shada deferral only; dashboard and warning removed |
| `nvimz/config/plugins.lua` | groups: `tier1`, `markdown`, `oil`, `format`, `dap`, `gp`, `copilot` |
| `core/keymaps.lua` | owns all lazy feature entry points (picker, git, oil, format, DAP, AI) |
| `core/autocmds.lua` | FileType→LSP also skips unlisted buffers (plugin-owned documents) |
| `features/interface/markdown.lua` | deleted (redundant wrapper) |
| `features/search/pick.lua` | deleted (keys moved to core; picker loads on first use) |
| `nvimz/picker/native.lua` | keymap registration removed; core owns the entry points |
| `features/lsp/{init,servers}.lua` | setup on first server need; capabilities built per first start |
| `features/lsp/diagnostics.lua` | annotation autocommands use a named, clearable group |
| `features/interface/statusline.lua` | LSP/diagnostic guards + cache invalidation on attach/change |
| `features/dap/init.lua` | idempotent setup only; keymaps and tests moved to core |
| `features/ai/init.lua` | split `setup_gp` / `setup_copilot`; no keymaps; Ollama check only in gp |
| `features/{git,format,editing/files}.lua` | setup only; keys centralized in core |
| `nvimz/health.lua` | wording for on-demand plugins and core-startup target |

### 13.2 Actual loading boundaries

```
init.lua
└─ runtime/init.lua                         Tier 0
   ├─ version guard, shada deferral
   ├─ require("core")                       keymaps/commands exist synchronously
   └─ runtime.phases.setup()                registers triggers only

VimEnter (synchronous, once)
├─ plugins.tier1: tokyonight, mini.nvim
├─ theme → icons → statusline              only when a UI exists
├─ nvimz.treesitter                        first buffer + FileType autocmd
├─ markdown plugin if the first buffer is Markdown
├─ dashboard                               only when argc() == 0
└─ Oil setup only when the first buffer is a directory

InsertEnter              → pairs, completion          (idempotent, retryable)
CursorMoved              → scope_line, git signs       (real editing buffers only; idempotent)
BufWritePre              → conform setup + first format
FileType=markdown        → render-markdown plugin      (listed, normal buffers only)
FileType with a server   → LSP setup, then vim.lsp.start
<leader>e / :Oil / dir   → Oil setup
<leader>f*               → native picker
<leader>g* / :Git        → mini.git + mini.diff
<leader>fm               → conform
<leader>d* / :Dap*       → DAP plugins + setup
<leader>a* / :Gp*        → gp plugin + setup
<leader>at / :Copilot    → Copilot plugin + setup
:Lsp*                    → LSP setup (no server started by the command itself)
```

No `InsertEnter` phase, no post-`VimEnter` timer chain, no idle/warm-up queue, and no Tier 4.

### 13.3 Deviations from the proposal and why

| Proposal | Shipped | Reason |
| --- | --- | --- |
| Chunk A scheduled after `VimEnter` | pairs/completion on `InsertEnter`; scope line + git on `CursorMoved` | Removes startup work for the dashboard and ties the chunk to editing. A real file raises `CursorMoved` when it opens, so its 1.6–1.8 ms chunk is part of file first paint; deferring it would make diff signs/scope lines appear after the first movement. |
| Chunk C loads git, formatting, Oil together | git on first cursor move; format on first write; Oil on its key/command/directory | Avoids loading the file explorer for users who never open it |
| Markdown module retained for configuration | deleted; plugin auto-setup owns it | The wrapper passed no configuration |
| DAP `CmdlineLeave` trigger | `CmdUndefined` + argument-preserving stubs | Native, only fires when an undefined `:Dap*` command is used |
| LSP setup in a scheduled chunk | first FileType with a configured server, or `:Lsp*` | No LSP work in sessions that never edit code |
| First activation cost ≈ require + setup | measured cost includes native `vim.pack.add`/`packadd` | The plan's estimates excluded package activation; see final report |

One pre-existing defect surfaced while moving the key: `<leader>gs` ran `:Git` with no arguments, but
mini.git declares `:Git` with `nargs='+'`. The key now runs `:Git status`, matching its "Git status"
description. No other Git behavior changed.

### 13.4 Verified repeatedly

- Empty session: only `tokyonight`, `mini.nvim`, and Treesitter are loaded; no `vim.lsp`,
  `vim.diagnostic`, markdown, git, format, oil, DAP, gp, or Copilot modules. Gate C clarified that
  the 43-module figure is headless; a live UI also loads theme/icons/statusline/dashboard and
  settles at 65 modules (27.0 MiB) after the dashboard cursor guard.
- Lua/Go startup: LSP attaches and keymaps/inlay are present; no DAP/AI/format/Oil modules.
- Markdown startup: render-markdown is loaded at first paint; non-Markdown sessions never add it.
- Insert: pairs/completion load; gp and Copilot do not.
- `<leader>at`: Copilot setup runs once; no language server is spawned until insert.
- `<leader>db` and `:DapShowLog`: DAP setup runs once; repeat calls do not duplicate listeners.
- `:Oil`, `:Git`, and `:LspInfo` work before their feature has been used.
- Missing `gopls`/`ollama`: one named warning or skip; the editor remains usable.
- `:checkhealth nvimz` and `:PackStatus` report managed/active/inactive plugins correctly after
  startup.

### 13.5 Remaining limitations

- `vim.pack.add` and `packadd` dominate first activation (several milliseconds each); this is a
  native package cost, not a `require` cost.
- Go/Markdown Tier 1 is longer than 10 ms because Treesitter pickup and Markdown rendering are
  deliberately completed before the first paint. Empty/Lua Tier 1 stays within ~7–10 ms.
- `:Gp*` commands that take arguments and are typed before the first AI activation lose those
  arguments when resolved by `CmdUndefined`; the provided keymaps and the stubbed range commands
  remain the supported entry points.
- LSP skips unlisted buffers. This intentionally excludes plugin-owned documents such as the gp
  chat transcript; a user who deliberately opens an unlisted code buffer will not get a server.
- Only macOS/arm64 and Neovim 0.12.6 were measured.
- Delve could not launch a debuggee on the Gate C host (`dlv dap` answers `initialize`, never
  `launch`; `dlv exec` also hangs). DAP demand loading, breakpoints, and listeners are verified;
  a real stopped-state session is not.
- Scout (`qwen2.5:7b`) and Judge (`qwen3:8b`) are configured but not installed on the Gate C host.
  The Editor agent (`qwen2.5-coder:7b`) was validated with a real Ollama rewrite.

### 13.6 Gate C corrections (2026-11-02)

Gate C drove the code through real PTY sessions and found two activations that the headless
module probes could not see. Both fixes are in `runtime/phases.lua` and are intentionally small:

1. **Dashboard cursor placement.** `dashboard.setup()` calls `nvim_win_set_cursor`, which raised
   `CursorMoved` at ~32 ms and loaded `scope_line`, `features.git`, `mini.git`, and `mini.diff`
   during startup (69 modules). `cursor_chunk_relevant()` now requires a normal, listed editing
   buffer with a non-empty filetype other than `dashboard`. Empty dashboard: 69 → 65 modules, and
   no git/scope modules. A real file still triggers on open, keeping first-frame diff signs.
2. **LSP hover Markdown.** A `K` hover creates an unlisted `nofile` Markdown float; the
   `FileType=markdown` handler activated all 66 `render-markdown` modules (~20 ms first hover).
   `is_markdown_buffer()` now requires `buftype == ""` and `buflisted`. Real Markdown files and
   the listed gp chat still render; hover floats do not.

Gate C also confirmed: 30-second editing soak at 0% idle with stable 109 modules; Copilot one
server across repeated presses; Copilot server 342–425 MiB; DAP one listener and one breakpoint;
real gp Editor rewrite; one gopls warning when missing; lazy keys for git/Oil/format/picker/
terminal; empty dashboard first paint 40.7 ms and headless `NVIM STARTED` 10.44 ms. Full evidence:
`docs/audit/progressive-performance-gate-c-report.md`.

### 13.7 Cold startup target (2026-11-02)

The 10 ms target now applies to the cold core boundary: `init.lua` → `VimEnter`, empty session,
fresh `XDG_CACHE_HOME`. The only runtime change is that `runtime/init.lua` no longer calls
`vim.loader.enable()`.

On a fresh cache the loader compiled the startup modules before the first buffer. Measured cold
core init was **11.7 ms median** (10.8–16.1, n=10) with the loader and **8.3 ms median**
(7.8–9.0, n=10) without it; cold `NVIM STARTED` moved from **12.8 ms** (11.9–12.9) to **9.7 ms**
(9.2–11.0). Warm core init (8.2–8.6 ms), warm `NVIM STARTED` (~9.6 vs ~10.2 ms), and warm first
content (dashboard 40.6–43.6 ms) were unchanged or slightly better. The bytecode cache was not
paying for itself on this codebase; every start is now the no-cache path, so there is no first-run
compile spike. The first start with a cold OS page cache is outside this boundary.
`:checkhealth nvimz` and `:NvimzBenchmark` now name the cold core target, and the dashboard banner
displays the same value.
