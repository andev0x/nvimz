# Runtime & Infrastructure Acceptance Report

**Mission:** Final interactive acceptance, stabilization, and closure of the nvimz Runtime & Infrastructure Core
**Phase:** Final acceptance (after Phases 1–3)
**Date:** 2026-11-01
**Branch:** `perf/optimize-logic` (nothing staged, committed, tagged, or published)
**Reference host:** Neovim 0.12.6, LuaJIT 2.1.1793383622, macOS 27.0.1 (build 26A434), Apple M1 Pro (arm64)

**Final status: `ACCEPTED WITH DOCUMENTED LIMITATIONS — READY FOR USER REVIEW`**

---

## A. Executive Summary

The reconstructed runtime was exercised in a real interactive Neovim session, in fresh isolated
environments, and through headless/package/health probes. The approved architecture is intact:
two runtime files, native `vim.pack`, native filetype/plugin loading, one `:checkhealth nvimz`
provider, seven runtime commands, and no reintroduced infrastructure.

**Three confirmed in-scope defects were found and fixed:**

1. **Silent viminfo read failure.** A corrupt ShaDa file was ignored with no diagnostic, violating
   the target contract ("no silent pcall in the runtime"). It now warns; a missing file (normal
   first run) stays silent.
2. **Markdown first-buffer ordering.** Opening a Markdown file from the command line fired the
   `FileType` hook before phase 1 added `render-markdown`, producing `module 'render-markdown' not
   found`. The setup now runs after phase 1 and also handles a Markdown buffer already loaded at
   startup.
3. **Misleading benchmark label.** `:NvimzBenchmark` placed the `< 10 ms` init→`VimEnter` target
   next to `NVIM STARTED` samples (~11 ms), conflating two boundaries. The output now labels both.

Documentation was corrected for the `:PackRollback` review-buffer semantics and for the measured
performance boundaries. No feature, plugin, package manager, or architecture was added.

All applicable acceptance checks passed. The remaining limitations are the previously documented
ones (macOS-only runtime verification, GUI-only properties, deferred LSP/Java work, upstream
experimental `vim.pack`, intentional viminfo deferral, ignored historical snapshot).

---

## B. Repository Integrity

| Item | State |
| --- | --- |
| Branch | `perf/optimize-logic` |
| Staged changes | none (`git diff --cached --stat` empty) |
| Commits / tags / releases | none created |
| User-owned changes | preserved; prior README/docs edits were extended, never reverted |
| Destructive Git commands | none |
| User plugin directory | 12/12 revisions still match `nvim-pack-lock.json` |
| Tests with side effects | run only in isolated `XDG_{CONFIG,DATA,STATE,CACHE}_HOME` copies |

Files changed **during this final phase**:

| File | Change |
| --- | --- |
| `lua/runtime/init.lua` | report real viminfo read failures; keep missing-file first run silent |
| `lua/runtime/phases.lua` | set up Markdown after phase 1; cover an already-loaded Markdown buffer |
| `lua/nvimz/benchmark.lua` | separate `NVIM STARTED` from the init→`VimEnter` target |
| `.gitignore` | ignore the host-local `lua/machine/local.lua` |
| `scripts/parsers` | build the required `json` parser (16/16 parity) |
| `docs/commands.md` | `:PackRollback` review-buffer semantics |
| `docs/languages.md` | accurate extension examples and formatter/health guidance |
| `docs/architecture.md` | rollback clarification; Python-only host override; AOT wording |
| `docs/performance.md` | corrected measurement boundaries and acceptance numbers |
| `docs/architecture/runtime-target-architecture.md` | documented the post-phase-1 Markdown trigger |
| `README.md` | empty-startup wording; removed unsupported Node/shell-config claims |
| `docs/audit/runtime-acceptance-report.md` | this report |

The rest of the working tree is the Phase 2/3 implementation already present before this phase.
`MAINTENANCE_REPORT.md` was deleted by the earlier phase; this phase deleted nothing.

---

## C. Interactive Acceptance Results

A real interactive session was run in tmux with a UI attached and an isolated state directory.

### Startup and first buffer

| Case | Result |
| --- | --- |
| `nvim` without a file | Dashboard rendered; no startup errors; self-reported 9.03 ms and 9.14 ms |
| Lua file | `filetype=lua` at `-c` time; Treesitter active; one `lua_ls` client |
| Go file in a project (`go.mod`) | `filetype=go`; Treesitter active; one `gopls` client; correct root |
| Markdown on the command line | `filetype=markdown`; marksman + Treesitter + render-markdown after the fix |
| Normal command-line invocation | works; no delayed filetype replay |
| `:messages` after startup | empty |

Native plugin loading and native filetype detection remain enabled. The first buffer is correctly
typed without any replay.

### Visual / UI

| Check | Result |
| --- | --- |
| Colorscheme | `tokyonight-moon` |
| Transparency | `Normal` has no background (`bg=nil`); `termguicolors=true` |
| Statusline | `MiniStatusline` active; filetype, Git branch, diagnostics, LSP, position shown |
| Dashboard | logo, user, startup time, and four menu entries rendered |
| Icons | `mini.icons` loaded; icons visible in statusline/dashboard |
| Treesitter | highlighter active on Lua, Go, Markdown buffers |
| Diagnostics | 1 diagnostic rendered with sign/underline; `open_float()` succeeds |
| Splits | 3 windows created by `:vsplit`/`:split`; `splitbelow`/`splitright` honored |
| Lazy UI | UI modules and plugins initialize after `VimEnter` without visible errors |

No flicker or missing component was observed in captured frames. Precise compositor transparency
and font rasterization are terminal/GUI properties and cannot be asserted from tmux; the highlight
values and layout were verified instead.

### Plugin lifecycle

| Check | Result |
| --- | --- |
| Phase 1 | 5 plugins active after `VimEnter`; UI + core modules loaded |
| Phase 2 | 5 more plugins active; format and DAP loaded |
| Phase 3 | `InsertEnter` activates `gp.nvim` + `copilot.lua`; 12/12 active |
| Failure isolation (feature) | injected error reported as `features.format failed`; phase 1, DAP, commands still work |
| Failure isolation (acquisition) | blocked Git transport produced named errors; editor alive, filetype/commands available |
| Missing optional tooling | warnings only; required `rg`/`fd` absence is an error |
| `:PackStatus` | 12 managed, 10 active, 2 lazy, no undeclared, lockfile present, missing tools reported |
| `:PackClean` | removed an undeclared plugin and a broken parser; preserved declared lazy plugins |

### Persistence

| Step | Result |
| --- | --- |
| Register `a` set in session 1, normal exit | ShaDa file written |
| Session 2 | register restored (`nvimz-persist-…`) |
| Corrupt existing ShaDa | actionable `E576` warning after the fix |
| Fresh state dir with no ShaDa | no warning; file written on exit |
| `nvim --headless -c qa` before `VimEnter` | documented limitation reproduced: no read/write, no ShaDa file |

The deferred viminfo read remains a deliberate lifecycle decision, not an accidental regression.

---

## D. Operational Verification

All commands below were run from the repository root on the reference host. The repository has no automated test harness, so each fix was reproduced and re-verified with the focused commands recorded here.

### Runtime and static checks

| Check | Command | Result |
| --- | --- | --- |
| Lua syntax | `luac -p` over all 41 files | 0 failures |
| Shell syntax | `bash -n` over `scripts/*` and `scripts/lang/*.sh` | 0 failures |
| Stale infrastructure | `rg "infra\.|infra/|PackSync|PackValidate|PackDoctor|ToolDoctor|PackReport|PackSnapshot|MAINTENANCE_REPORT|nvimz_cache|nvim-lspconfig"` over `lua/`, `scripts/`, `README.md`, and current user docs | no matches (historical audit/design docs and this report excluded) |
| Require cycles | static require graph over 41 modules | 0 cycles, 0 unresolved internal requires |
| Startup messages | two consecutive headless starts | no errors or warnings |
| State cache | check `stdpath("state")/nvimz_cache.json` | not created |
| Machine override | temp `machine/local.lua` values | new value applied without deleting any cache; malformed file reported, editor started |
| `:License` | isolated session | opens the real `LICENSE` file |
| Filetype at `-c` time | Lua / Go / no file | `lua` / `go` / empty |

### Package management

| Check | Environment | Result |
| --- | --- | --- |
| `:PackStatus` | isolated + degraded PATH | matches `vim.pack.get`; no subprocesses; no invented metric |
| `:PackUpdate` review | isolated copy | fetch + native review buffer; `:quit` left lockfile and revisions unchanged |
| Forced update | isolated copy | `vim.pack.update(nil, { force = true })` updated 2 plugins and the lockfile |
| `:PackRollback` | isolated copy after restoring the original lockfile | review buffer showed lockfile targets; `:write` restored all 12 revisions |
| Offline update | isolated copy with proxy blocked | `offline=true` completed from local refs without network errors |
| `:PackClean` | isolated copy with an undeclared plugin + bogus parser | both removed; 12 declared plugins preserved |
| Lockfile consistency | declared specs vs lockfile | 12 declared / 12 locked, 0 missing, 0 extra, 0 source mismatches |
| Fresh install | copied config, empty XDG dirs | 12/12 installed at exact lockfile revisions; lockfile byte-identical |
| Fresh start | same isolated environment | `filetype=go`, 1 `gopls` client, 10 active + 2 lazy, no errors |

The user's real plugin directory was never updated, rolled back, or cleaned.

### Health and diagnostics

| Check | Result |
| --- | --- |
| `:checkhealth nvimz` | all sections present: 3 core tools, 10 servers, 6 formatter binaries, 16 parsers, 12 managed plugins, machine state |
| `:checkhealth vim.pack` | reachable; lockfile and plugin directory reported |
| Degraded PATH | required tools error, optional servers/formatters warn; editor starts |
| Missing parser / corrupt state | reported, not silently ignored |
| `scripts/doctor` | 3 core / 10 servers / 6 formatters / 16 parsers, matching the Lua declarations |
| `scripts/parsers --check` | 16/16 parser binaries present; list matches `nvimz/config/parsers.lua` and `scripts/doctor` |
| `scripts/manage` | `--update`, `--sync`, `--all` only; no `--report`; help matches behavior |
| `scripts/setup` | `--minimal` offers only the five existing language scripts |

### Reproduction commands

```bash
# syntax and shell
find lua -name '*.lua' -exec luac -p {} \;
for s in scripts/doctor scripts/manage scripts/setup scripts/parsers scripts/lang/*.sh scripts/lib/*.sh; do bash -n "$s"; done

# headless startup and first-buffer filetype
nvim --headless -c 'qa!'
nvim --headless lua/runtime/init.lua -c 'lua print(vim.bo.filetype)' -c 'qa!'
nvim --headless README.md -c 'lua print(vim.bo.filetype)' -c 'qa!'

# health and package status (inside Neovim)
:checkhealth nvimz
:checkhealth vim.pack
:PackStatus

# warm startup, one process at a time
for i in $(seq 1 10); do
  XDG_STATE_HOME=$(mktemp -d) nvim --startuptime /tmp/w-$i.log --headless -c qa
  grep 'NVIM STARTED' /tmp/w-$i.log
done
```

`init.lua → VimEnter` and phase probes use a temp Lua file that records
`(vim.uv.hrtime() - _G.nvimz_start_time) / 1e6` from a `VimEnter` autocmd (and, for phase 1 + 2,
polls until `features.format` and `features.dap` are loaded). Interactive checks were run in tmux;
package tests used copied configs with isolated `XDG_{CONFIG,DATA,STATE,CACHE}_HOME`.

### In-scope defect evidence (before → after)

**1. Silent viminfo failure**

```vim
" before: corrupt main.shada
:lua vim.wait(300); vim.cmd("messages")   " empty
" after
[nvimz] failed to read viminfo:
... Vim(rshada):E576: Error while reading ShaDa file ...
```

A fresh state directory (no ShaDa file) produces no warning and writes the file on exit.

**2. Markdown first buffer**

```text
before: nvim README.md
[nvimz] features.interface.markdown failed: module 'render-markdown' not found

after:
ft=markdown
render_markdown=true
messages=            " empty
```

**3. Benchmark boundary**

```text
before: Samples: 10.961, 11.541, 11.558 ms ... Target: < 10.00 ms
after:  Metric: process start → NVIM STARTED
        Project target: < 10.00 ms from init.lua → VimEnter (different boundary)
```

---

## E. Performance

### Environment and methodology

- Neovim 0.12.6 / LuaJIT 2.1.1793383622 / macOS 27.0.1 / Apple M1 Pro (arm64).
- Warm runs: bytecode cache warm, one `nvim --startuptime … --headless -c qa` process at a time.
- `init.lua → VimEnter`: `_G.nvimz_start_time` recorded in `init.lua`; measured in a `VimEnter`
  autocmd; headless (no UI).
- Phase 1: the previously used `vim.defer_fn(..., 1)` checkpoint. **Verified at that point:
  `active=5`, `features.dap=false`, `features.format=false` — it is phase 1, not phase 1 + 2.**
- Phase 1 + 2: polled from `VimEnter` until `features.format` and `features.dap` are loaded.
- First-buffer: same `init.lua → VimEnter` probe with a file argument.
- Isolated `XDG_STATE_HOME`; no other Neovim process was running during the final sequential runs.

### Results (final sequential run)

| Metric | n | Median | Range |
| --- | --- | --- | --- |
| Warm `NVIM STARTED` | 10 | **9.87 ms** | 8.98 – 13.29 ms (first run 13.29) |
| Cold bytecode cache `NVIM STARTED` (isolated) | 5 | **10.99 ms** | 10.00 – 15.13 ms (first run 15.13) |
| `init.lua → VimEnter` (empty) | 10 | **6.64 ms** | 6.26 – 6.97 ms |
| Phase 1 checkpoint | 5 | **22.21 ms** | 21.22 – 23.93 ms |
| Phase 1 + 2 complete (DAP/format loaded) | 5 | **33.18 ms** | 30.95 – 34.53 ms |
| First buffer, Lua file | 5 | 13.39 ms | 12.57 – 14.81 ms |
| First buffer, Markdown file | 5 | 17.94 ms | 16.78 – 18.55 ms |
| Interactive dashboard (self-reported) | 2 | 9.09 ms | 9.03 – 9.14 ms |
| Config load (`require("runtime")`) | 1 log | 1.71 ms | — |

### Comparison and interpretation

- The project target (`init.lua → VimEnter`, empty startup, ~10 ms) is met: median **6.64 ms**.
- `NVIM STARTED` is ~9.9 ms warm, versus the old 5.37 ms baseline. As documented in D11, the old
  figure was produced by disabling native plugin/filetype loading and replaying a subset later.
  The new figure includes native runtime plugins (`matchit`, editorconfig, `:Man`, OSC52) and
  native filetype detection. This is a deliberate trade, not an unexplained regression.
- The previous report's "Phase 1 + phase 2 complete = 23.36 ms" is a boundary error: the timer
  used for that number fires with DAP and format still unloaded. The comparable phase-1 number is
  ~22 ms; fully initialized phase 1 + 2 is ~33 ms. The old figure should not be compared with a
  fully initialized measurement.
- Opening a file raises the `VimEnter` number because native ftplugin/syntax work runs before
  `VimEnter` (Lua ~13 ms, Markdown ~18 ms, dominated by native `ftplugin/markdown.lua`). This is
  native editor work retained deliberately; it is not config load and was not optimized away.

No metric was extrapolated, and no measurement boundary was reused for a different phase.

---

## F. Architecture Closure

The final implementation satisfies the six principles:

1. **Native before plugin.** Package operations are `vim.pack`; health is `:checkhealth`; LSP,
   Treesitter, diagnostics, picker, and filetype handling use native APIs. `nvimz/*` only supplies
   thin command entry points and static declarations.
2. **Simplicity before abstraction.** `runtime/` is two files. There is no registry object,
   lifecycle manager, event bus, DI container, plugin abstraction, or reporting framework.
3. **Performance before features.** The empty-startup target is met without disabling native
   functionality; deferred phases remain ordered and observable.
4. **Value before dependency.** 12 plugins remain, each with a documented role; `nvim-lspconfig`
   and the custom package manager are gone.
5. **Explicit before magic.** Commands and keymaps are synchronous; phase failures and feature
   failures are reported by name; the viminfo failure is now explicit.
6. **Remove before replace.** The cache, custom deps, health/report framework, maintenance report,
   snapshot/report commands, and embedded license copy were removed rather than wrapped.

The decision register (D1–D17) is preserved: native `vim.pack`, no cache, direct `machine.local`
load, collapsed runtime, config data modules, derived tool inventory, `:checkhealth nvimz`,
non-destructive benchmark, explicit failure isolation, native filetype/plugin loading, synchronous
commands, seven runtime commands, no `nvim-lspconfig`, real `LICENSE`, and deferred Java/LSP work.
The only retained startup deferral is the viminfo read, with its limitation documented and tested.

---

## G. Remaining Limitations

### Verified limitations

1. **Startup with a file argument exceeds the 10 ms empty-startup target** (~13 ms Lua, ~18 ms
   Markdown) because native ftplugin/syntax loading happens before `VimEnter`. The interactive
   warning may therefore fire when opening a heavy file. This is native behavior, not a config
   regression; do not suppress it by disabling native detection.
2. **Viminfo is skipped if Neovim exits before `VimEnter`** (for example `-c qa` scripts). This is
   the documented lifecycle trade; interactive persistence works.
3. **`vim.pack` is upstream experimental** in Neovim 0.12. nvimz depends on it directly and pins
   Neovim 0.12+.
4. **GUI-only properties** (font rasterization, terminal compositor transparency) cannot be
   verified from tmux. Highlight values (`Normal` background absent, `termguicolors=true`) and all
   layout components were verified.
5. **The ignored snapshot** `snapshots/snapshot_20260526_105957.json` remains. Its producing
   feature is gone and it is redundant with the lockfile, but it was left untouched because it is
   user-owned historical data and no workflow required its removal.
6. **Single platform.** Runtime verification is macOS/arm64 only.

### Unverified platform behavior

- Linux runtime behavior (shell provisioning, XDG paths, `vim.system`, parser compilation) is
  statically reviewed but **not runtime-tested**.
- `scripts/doctor` assumes `$HOME/.local/share/nvim/site/parser`; a non-default `XDG_DATA_HOME`
  would need verification/adjustment on Linux.

### Deferred domain work

- `ftplugin/java.lua` still expects the undeclared `nvim-jdtls`, and `:LspStart/:LspStop/:LspRestart`
  overlap native `:lsp` commands. Both belong to the planned LSP/Java redesign (D16).
- `core/autocmds.lua` wraps `features.lsp.start` in a best-effort `pcall`; this is pre-existing LSP
  feature behavior, not runtime infrastructure, and was left unchanged to respect scope.

### Non-blocking observations

- `features/interface/dashboard.lua` still contains an unused `M.track()` helper with a 20 ms
  warning that nothing calls; it is in the frozen feature domain.
- The benchmark still measures only `NVIM STARTED`; it now labels the boundary correctly rather
  than adding a second measurement path.
- `rg-hidden.conf` and `rg-hidden-files.conf` are not referenced by the runtime or scripts; they
  were left untouched in case external tooling uses them.
- The ignored snapshot and the `.luarc.json` global list were left unchanged; neither affects
  runtime behavior.

---

## H. Final Recommendation

The current working tree is stable, operationally verified on macOS/arm64, and consistent with the
approved target architecture. The three defects fixed in this phase are minimal, reproduced before
the fix, and re-verified after it.

**You can safely review and commit the working tree on `perf/optimize-logic`.** Before advertising
cross-platform support, run the Linux verification described above and complete the deferred
LSP/Java review. Nothing was staged, committed, tagged, or published.

---

## Appendix: Post-Acceptance Documentation & Configuration Audit

After the acceptance run, the user-facing documentation was checked line by line against the Lua
declarations and shell scripts. The following mismatches were fixed:

| Finding | Fix | Verification |
| --- | --- | --- |
| `.gitignore` did not ignore `lua/machine/local.lua`, although README and architecture docs promised it | added the path to `.gitignore` | `git check-ignore -v lua/machine/local.lua` matches |
| `nvimz/config/parsers.lua` required 16 parsers, but `scripts/parsers` built only 15 (`json` missing) | added `json` at `tree-sitter/tree-sitter-json` `v0.24.8` | built and loaded in a temp dir; `scripts/parsers --check` reports 16/16; config/doctor/script parity is 16/16/16 |
| Docs described a Node executable override, but `machine/local.lua` only reads `python_path` | corrected README and architecture wording to the Python host | source inspection of `core/options.lua` |
| README claimed `scripts/setup` performs shell configuration | removed the unsupported claim | inspected `scripts/lang/*` and `scripts/lib/*` |
| Architecture/performance docs called every parser revision "pinned", but several track upstream branches | reworded to "pinned or upstream-tracked" and named the 16-parser scope | `scripts/parsers` `LANGS` list |
| Language-extension examples replaced `M.lsp_servers` / `M.formatters_by_ft` instead of adding entries; `formatter_binaries` was undocumented | examples now append entries and document `formatter_binaries` | matches `nvimz/health.lua` behavior |
| Docs implied all formatting is asynchronous; manual `<leader>fm` is bounded-synchronous | clarified on-save vs manual behavior | `features/format/init.lua` |
| Startup claims did not always say "empty startup" | qualified README/performance wording | matches the measured boundary in §E |

No runtime architecture, plugin declaration, package-management path, or feature behavior was
changed by this audit. The only executable changes are the `.gitignore` entry and the missing
`json` parser pin.

