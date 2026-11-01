# Progressive Performance — Final Report

**Phase:** Gate B implementation + before/after measurement
**Date:** 2026-11-02
**Repository:** `/Users/anvndev/.config/nvim` @ `main`
**Status:** Implemented and measured. No commit, tag, or publish was made.
**Baseline:** `docs/audit/progressive-performance-baseline.md` (Gate A)
**Plan:** `docs/architecture/progressive-loading-plan.md` (Gate B implementation record)

All numbers in §4 are measured on this host. Design expectations are separated in §3 and §7.
Where a value could not be measured reliably it is marked as such.

---

## 1. Result in one paragraph

The editor now renders the dashboard at the first paint instead of showing the native intro screen
for ~36 ms. An empty session loads only `tokyonight`, `mini.nvim`, and native Treesitter: no LSP,
diagnostics, Markdown renderer, git, formatter, Oil, DAP, gp, or Copilot. Insert no longer starts
AI. Copilot is explicit opt-in and never spawns its language server in a session that does not
invoke it. DAP setup runs on first debug action. Markdown is loaded only for Markdown buffers. The
maximum startup key delay dropped from ~41 ms to ~33 ms, and the post-startup blocks are
1.3–2.6 ms for the editing chunk and 1.6–1.8 ms for the cursor chunk; the old first-insert AI
stall (6.8–11.6 ms) is gone. Empty-session memory dropped from ~30.2 MiB to ~26.5 MiB. The trade
is a later first paint for Go (+8.8 ms) and Markdown (+10.9 ms), because first-buffer Treesitter
and Markdown rendering are completed before the first paint instead of switching visually later.

---

## 2. What changed

| Area | Before | After |
| --- | --- | --- |
| Bootstrap | phase 1 deferred after `VimEnter`, phase 2 chained immediately | Tier 1 synchronous before first paint; Tier 2 on native events |
| Dashboard | `vim.schedule` after phases | created synchronously at `VimEnter` when `argc() == 0` |
| Startup warning | notified on normal file opens | removed |
| AI | gp + Copilot on first `InsertEnter` | gp on first AI key/`:Gp*`; Copilot on `<leader>at`/`:Copilot` |
| DAP | full setup in phase 2, every session | plugins added and setup run on first `<leader>d*`/`:Dap*` |
| Markdown | plugin added in phase 1, auto-setup every session | plugin added on Markdown first buffer / `FileType=markdown` only |
| Editing | pairs, completion, picker, scope line in phase 1 | pairs/completion on `InsertEnter`; scope line + git signs on `CursorMoved`; picker on key |
| LSP | setup in phase 1; `vim.lsp.protocol` at module load | setup on first code `FileType`/`:Lsp*`; capabilities built on first server start |
| Statusline | first build could pull `vim.lsp`/`vim.diagnostic` | guarded getters; caches invalidated on attach/diagnostic change |
| Plugin groups | phase1/phase2/phase3 | `tier1`, `markdown`, `oil`, `format`, `dap`, `gp`, `copilot` |
| `features.interface.markdown` | redundant wrapper | deleted; plugin auto-setup owns it |
| `features/search/pick` | wrapper + setup | deleted; keys live in core and load the picker on use |
| `<leader>gs` | ran `:Git` with no args, which mini.git rejects (`nargs='+'`) | now runs `:Git status`, matching the existing description |

No scheduler, registry, cache, or package manager was added. `vim.pack` declarations and the
lockfile remain the packaging boundary.

---

## 3. Boundaries and design intent

The measurement boundaries are the same as Gate A:

| Metric | Boundary |
| --- | --- |
| Process startup | OS process start → `NVIM STARTED` (`--startuptime`) |
| Core init | `_G.nvimz_start_time` → start of the `VimEnter` callback, **before** Tier 1 |
| `VimEnter` complete | start of `init.lua` → end of the synchronous Tier 1 callback |
| First render / first themed paint / first buffer content | PTY stream (§4.3) |
| First dashboard paint | PTY stream |
| Input processing | PTY key write epoch → `vim.on_key` epoch |
| Tier 1 / chunk block | `uv.hrtime()` around the synchronous callback (temporary probe) |
| Feature activation | `uv.hrtime()` around a real `ensure_*` call in a live session |
| Memory | sum of RSS for the Neovim process tree |

**Boundary note.** Tier 1 now runs inside `VimEnter`, so a `VimEnter` probe includes it. The
comparable Gate A boundary is reported separately as **core init → start of `VimEnter`**. Do not
compare the two `VimEnter` figures as if they measured the same work.

Environment:

| Item | Value |
| --- | --- |
| Neovim / Lua | 0.12.6 / LuaJIT 2.1.1793383622 |
| OS | macOS 27.0.1 (Darwin 27.0.0), arm64 |
| CPU / memory | Apple M1 Pro (8 cores) / 16 GB |
| Config | `/Users/anvndev/.config/nvim` @ `main`, 22 runtime files changed |
| Plugins | 12 declared, 12 installed (`vim.pack` lockfile present) |
| Tools on PATH | git, rg, fd, gopls, lua-language-server, marksman, ollama, stylua, formatters |
| Treesitter | 16/16 required parsers available |

---

## 4. Measured results

### 4.1 Process startup (`NVIM STARTED`)

Warm, 5 discarded, n=10:

| n | Median | Min | Max |
| --- | --- | --- | --- |
| 10 | **10.25 ms** | 10.06 ms | 11.17 ms |

Gate A batch A: 10.10 ms median; batch B under load: 11.50 ms. Process startup is unchanged within
host noise. `NVIM STARTED` is dominated by native Neovim runtime work, not nvimz.

### 4.2 Core init and Tier 1

Measured with a temporary probe, n=3 per scenario. The probe was removed before the final run.

| Scenario | Core init → start of `VimEnter` | Tier 1 duration | `VimEnter` complete |
| --- | --- | --- | --- |
| Empty | 6.67–8.15 ms | **9.03–9.59 ms** | 16.11–17.76 ms |
| Lua | 12.92–13.51 ms | **6.88–6.96 ms** | 19.88–20.42 ms |
| Go | 11.01–11.56 ms | **10.31–11.01 ms** | 21.87–22.44 ms |
| Markdown | 16.78–18.07 ms | **16.08–17.70 ms** | 33.74–34.49 ms |

Gate A core init: empty 6.23–8.18, Lua 13.12–14.57, Go 11.64–12.57, Markdown 17.26–18.32. The core
boundary is unchanged. The 10 ms objective is met for empty and Lua. Go is ~10.3–11.0 ms and
Markdown ~16.1–17.7 ms because first-buffer Treesitter and Markdown rendering are deliberately
finished before the first paint; deferring them would produce a visible highlight/layout switch.

Headless `VimEnter` complete, n=10: **7.75 ms median** (7.39–8.99). This includes the headless
Tier 1 (plugin add + Treesitter registration) and is still below the 8 ms plan target.

### 4.3 First render (real PTY, n=5)

| Scenario | First byte | First themed paint | First content | Native intro | Dashboard |
| --- | --- | --- | --- | --- | --- |
| Empty | 14.2 (13.8–15.7) | **44.2 (42.6–45.3)** | — | **none** | **44.2** |
| Lua | 13.3 (12.6–15.9) | 44.6 (43.5–48.9) | 44.6 | — | — |
| Go | 15.9 (13.1–16.6) | 50.2 (46.1–51.1) | 50.2 | — | — |
| Markdown | 15.4 (13.3–17.1) | 63.2 (60.7–67.3) | 63.2 | — | — |

Gate A: empty dashboard 70.7 ms with the native intro at 34.6 ms; Lua 43.8; Go 41.4; Markdown 52.3.
The empty dashboard is ~26.5 ms earlier and the intro/layout shift is gone. Go and Markdown are
later by the amounts described in §4.2; theme, statusline, and file content are correct at the
first content paint, with no unthemed flash.

An outlier batch during development measured 60.9 ms dashboard / 101 ms Markdown; the n=5 batch
above is the reported result, and the host variance is documented in §8.

### 4.4 First-buffer readiness

| Check | Lua | Go | Markdown |
| --- | --- | --- | --- |
| Filetype at first content | `lua` | `go` | `markdown` |
| Treesitter highlighter active | yes | yes | yes |
| LSP client | `lua_ls` | `gopls` | `marksman` |
| LSP keymaps (`gd`, `K`) present | yes | yes | yes |
| Inlay hints enabled | yes | yes | n/a (server does not support) |
| Render-markdown decoration | — | — | yes (loaded before first paint) |

LSP setup starts at ~27.4–28.1 ms (Lua) and ~29.1–31.1 ms (Go) in the state probe. Actual
`LspAttach` times were 62.1–91.0 ms for `lua_ls` and 56.2–253.2 ms for `gopls` (gopls indexing
dominates the spread), comparable to Gate A's ~63–68 ms. Markdown's `marksman` client was present
in the 400 ms readiness probe, but the 600 ms attach-event probe did not reliably capture its
event; treat its attach time as not separately measured. Setup still precedes `vim.lsp.start`, so
keymaps/inlay are present when the client attaches.

### 4.5 Input responsiveness (`send → vim.on_key`, n=3 per delay)

Keys were sent one byte at a time at 20 ms intervals, starting at the stated delay.

| Key start | After: per-key delays (ms) | Gate A |
| --- | --- | --- |
| 10 ms | **32.6–33.2**, 16.5–17.3, 0.2–0.3, 0.1, 0.1, 0.1 | 22.8–41.0, 10–14, 2–14, 0.7–9.4, 0.1–0.2 |
| 40 ms | **3.8–5.1**, 0.1, 0.1, 0.1, 0.1, 0.1 | 3.1–6.9, 4.8–8.5, 4.0–10.7, 1.9–9.7, 0.1, 0.1 |
| 400 ms | **0.1**, 0.1, 0.1, 0.1, 0.1, 0.1 | 0.1, **6.8–11.6**, 0.1, 0.1, 0.1, 0.1 |

The 10 ms row is queued startup: the key arrives before the first paint and waits for native
startup + Tier 1. The config-owned block is Tier 1 itself (9.0–9.6 ms empty, 6.9 ms Lua), not the
whole 33 ms. At 40 ms and 400 ms the editor is immediately responsive; the first-insert AI stall
is gone.

Measured block durations in live sessions (temporary probe, n=5):

| Block | Measured |
| --- | --- |
| Insert chunk (pairs + completion) | **1.3–2.6 ms** (n=5) |
| Cursor chunk (scope line + git signs) | **1.6–1.8 ms** |
| First save | conform packadd 7.5 ms + setup 0.3 ms + external formatter time |

### 4.6 Module and plugin loading

Modules after each scenario (state probe; idle empty measured separately at 600 ms):

| Scenario | Gate A modules | Gate B modules |
| --- | --- | --- |
| Empty, idle | 166 after phase 2 | **43** |
| Empty, after probe-induced cursor activity | 166 | 62 |
| Lua | 192 | **101** |
| Go | 191 | **100** |
| Markdown | 231 | **160** |

Plugin runtime state:

| Boundary | Active plugins |
| --- | --- |
| Empty, after `VimEnter` | `tokyonight`, `mini.nvim` |
| Lua/Go file | + none (LSP is native, not a plugin) |
| Markdown file | + `render-markdown.nvim` |
| First insert | no new plugins |
| `<leader>d*` / `:Dap*` | + `nvim-dap`, `nvim-nio`, `nvim-dap-ui`, `nvim-dap-go` |
| `<leader>a*` / `:Gp*` | + `gp.nvim` |
| `<leader>at` / `:Copilot` | + `copilot.lua` |
| `<leader>e` / `:Oil` / directory startup | + `oil.nvim`, `oil-git-status.nvim` |
| First write / `<leader>fm` | + `conform.nvim` |

Verified absent in a normal Lua/Go editing session: `features.dap`, `dap`, `dapui`, `dap-go`,
`features.ai`, `gp`, `copilot`, `render-markdown`, `oil`, `conform`. Verified absent in an empty
session: `vim.lsp`, `vim.diagnostic`, all of the above.

### 4.7 Feature first-activation latency (live session, 300 ms after start)

First activation includes native `vim.pack.add`/`packadd`, which the Gate A isolated estimates did
not. Values are end-to-end `ensure_*` calls, n=3 unless noted.

| Feature | Measured first activation | Decomposition |
| --- | --- | --- |
| LSP setup (`:Lsp*`, no server start) | 5.0–18.0 ms (n=8, noisy) | `vim.diagnostic` 1.5 ms + LSP setup 3.6 ms |
| Git (`<leader>g*`, `:Git`) | 2.2–9.5 ms (n=6) | mini.git + mini.diff setup |
| Format (`<leader>fm`, first write) | 9.6–12.7 ms | conform packadd 7.5 ms + setup 0.3 ms |
| Oil (`<leader>e`, `:Oil`, directory) | 5.0–21.4 ms (n=6) | oil packadd 1.7 ms + setup 3.1 ms + oil-git |
| Markdown (first later Markdown buffer) | 19.6–21.5 ms | render-markdown packadd + auto setup (17.5 ms add) |
| DAP (`<leader>d*`, `:Dap*`) | 18.9–36.0 ms | DAP packadd 11.6 ms + setup 6.9 ms |
| gp (`<leader>a*`, `:Gp*`) | 35.8–50.0 ms | gp packadd 2.7 ms + `gp.setup` 28.7 ms |
| Copilot (`<leader>at`, `:Copilot`) | 5.6–30.8 ms | copilot packadd 3.8 ms + setup 18.9 ms |

These are one-time costs paid only when the feature is invoked. They are larger than the plan's
estimates because the plan measured `require` + `setup` with plugin paths already on
`runtimepath`; the real path also pays native package activation. The explicit-Copilot path was
also checked: no Copilot language server is spawned until insert after activation, and no
`copilot-language-server` process exists in sessions that never invoke it.

### 4.8 Memory (process-tree RSS, 1.2 s after start)

| Session | Gate B | Gate A |
| --- | --- | --- |
| Empty | **26.4–26.7 MiB** | 30.1–30.3 MiB |
| Lua file (lua_ls) | 105.2–110.4 MiB | 108.6–109.7 MiB |
| Go file (gopls) | 153.9–154.1 MiB | 156.7–251.6 MiB |
| Markdown file (marksman) | 139.0–139.2 MiB | not measured |
| Lua editing, first insert, no AI | **110.6–113.2 MiB** | ~370 MiB (gp + Copilot + Lua LSP) |
| Copilot explicitly activated, then insert | 408.1–415.8 MiB | ~370 MiB (automatic every session) |
| DAP activated, no debug session | 27.4 MiB | — |
| gp chat open | **33.8–34.3 MiB** | ~140 MiB during development before the listed-buffer LSP boundary |

The last row is a measured benefit of the LSP boundary: gp chat transcripts are unlisted
plugin-owned buffers, so they no longer start `marksman`. Normal Markdown files still do.

### 4.9 CPU and background overhead

- No background worker, timer queue, or idle warm-up exists. The only deferred calls are existing
  one-shot deferrals with concrete triggers: the viminfo restore, the per-file LSP start, and
  oil-git-status setup after Oil. There is no queue and nothing repeats.
- Idle process-tree CPU at 1 s: 0.0–0.5%; at 3 s: 0.0%. No growth.
- Child processes appear only when a feature starts them: `lua_ls`/`gopls`/`marksman` for a
  relevant code buffer, Copilot's server only after explicit Copilot activation and insert, no
  Ollama process unless gp is activated and the reachability check fails.
- No new cache or state file is read or written. `vim.pack` remains the only package state.

---

## 5. Required verification scenarios

| # | Scenario | Result |
| --- | --- | --- |
| 1 | Empty startup + dashboard | Dashboard is the first content; native intro absent; theme/statusline correct; no LSP/markdown/AI/DAP modules |
| 2 | Direct Lua file | `ft=lua`; Treesitter active; `lua_ls` attaches; no DAP/AI/format/Oil modules |
| 3 | Direct Go project | `ft=go`; Treesitter active; `gopls` attaches; no DAP/AI modules |
| 4 | Direct Markdown file | `ft=markdown`; render-markdown loaded before first paint; marksman attaches |
| 5 | Normal editing without AI | Insert loads pairs/completion only; no gp/Copilot; no Copilot server; tree RSS ~111 MiB |
| 6 | Explicit Copilot activation | `<leader>at` loads Copilot once; no server until insert; no gp; repeat press toggles without re-setup |
| 7 | Normal session without DAP | No `dap`/`dapui`/`dap-go` modules; no DAP plugins active |
| 8 | Explicit DAP activation | `<leader>db` loads DAP and sets a breakpoint; `:DapShowLog` resolves via `CmdUndefined`; second call does not duplicate setup |
| 9 | Session without Markdown | `render-markdown` plugin and module absent; gp chat no longer starts marksman |
| 10 | Markdown activation + repeated buffers | First later Markdown buffer adds the plugin; second buffer does not duplicate setup; `vim.g.loaded_render_markdown` remains true |
| 11 | Missing optional dependencies | Missing `gopls`: one warning, no client, Treesitter still active, exit 0. Missing `ollama`: gp still loads, no crash |
| 12 | Input responsiveness | Post-startup keys 0.1 ms; first-insert chunk 1.3–2.6 ms; first-cursor chunk 1.6–1.8 ms |

Command/UX checks:

- `:Oil` works before Oil is loaded (lazy stub).
- `:Git status` works before mini.git is loaded (lazy stub); `<leader>gs` now issues
  `:Git status` (the previous no-argument `:Git` was rejected by mini.git's `nargs='+'`).
- `:LspInfo` works in an empty session and initializes LSP setup without starting a server.
- `:DapShowLog` works before DAP setup (native `CmdUndefined`).
- `:GpChatToggle` works before gp setup (native `CmdUndefined`).
- `:checkhealth nvimz` completes; `:PackStatus` reports 12 managed plugins, with only the
  triggered ones active after startup.
- `:messages` is empty after normal empty/Lua/Go startup.
- Five consecutive headless starts exit 0.

---

## 6. Failure behavior and probes

| Probe | Result |
| --- | --- |
| `gopls` missing (`PATH=/usr/bin:/bin`, Go file) | one warning `LSP server 'gopls' not found: gopls`; `ft=go`; Treesitter active; no client; exit 0 |
| `ollama` missing, `<leader>aa` | gp loads; no crash; no Ollama process; optional warning path preserved |
| Plugin add fails | `pcall` reports a named `[nvimz] plugin installation failed`; other features continue |
| Module setup fails | named `[nvimz] <module> failed`; the ensure guard is reset where the feature is retryable |
| Repeat DAP activation | `initialized` guard; no duplicate listeners/keymaps |
| Repeat Copilot activation | phases guard; setup runs once; later presses only toggle |
| Repeat Markdown buffer | plugin script's `loaded_render_markdown` guard + `ensure_markdown` guard |
| Short-lived headless session | Tier 1 runs, deferred triggers do not; exit 0 |
| No UI (headless) | Tier 1 skips theme/icons/statusline/dashboard; core, filetype, and LSP still work |

---

## 7. Expected benefits vs measured outcome

| Design expectation | Measured outcome |
| --- | --- |
| Dashboard before first paint, no intro | **Met**: 44.2 ms first paint, no native intro |
| Empty session does not load optional features | **Met**: 43 modules, 26.5 MiB, no LSP/diagnostics/markdown/AI/DAP |
| Insert never starts AI | **Met**: no gp/Copilot, no server, 0.1 ms idle input |
| Copilot opt-in | **Met**: no server until explicit activation + insert |
| DAP demand-driven | **Met**: no DAP modules/plugins in normal sessions |
| Markdown only for Markdown buffers | **Met**: absent in empty/session; present at first Markdown paint |
| No post-startup phase stalls | **Met**: editing chunk 1.3–2.6 ms; cursor chunk 1.6–1.8 ms |
| Tier 1 ≤ 10 ms | **Met for empty/Lua**; Go 10.3–11.0 ms and Markdown 16.1–17.7 ms are deliberate first-buffer correctness costs |
| First file paint not worse | **Lua flat (44.6 vs 43.8)**; Go +8.8 ms; Markdown +10.9 ms |
| Memory not worse | **Empty −3.7 MiB**; Lua/Go unchanged within range; normal editing −~260 MiB without AI |

The plan's numeric targets for first activation were optimistic because they excluded native
package activation; the measured values are in §4.7 and are reported as the real cost.

---

## 8. Remaining limitations

1. **Single host.** macOS 27 / arm64, Neovim 0.12.6. Linux and other terminals are unverified.
2. **Host variance.** Development runs produced a 60.9 ms dashboard and a 101 ms Markdown outlier
   on a loaded host; one later dashboard run hit 101 ms while `go build` and `xprotectd` were
   active. The n=5 final batches are 44.2 ms (dashboard) and 63.2 ms (Markdown). First-activation
   values (especially gp/Copilot and LSP setup) vary with GC and scheduling; ranges are reported
   instead of a single number.
3. **Tier 1 is intentionally over 10 ms for Go/Markdown.** Deferring it would trade a visible
   highlight/layout switch for a lower number, which the mission explicitly forbids.
4. **Native package activation dominates first use.** `vim.pack.add`/`packadd` costs several
   milliseconds before the plugin's own `require`/`setup`; this is native behavior, not a new
   framework.
5. **`:Gp*` argument edge.** No-argument `:Gp*` commands typed before activation resolve through
   `CmdUndefined`; commands that require a range/arguments rely on the provided keymaps or the
   small argument-preserving stubs. This is a deliberate limit of the native `CmdUndefined` event.
6. **LSP skips unlisted buffers.** This avoids starting servers for plugin-owned documents (gp
   chat). A user who deliberately opens a code file with `buflisted=false` will not get a server.
7. **No visual recording.** The PTY proves ordering and timing, not perceived smoothness. Final
   interactive confirmation is Gate C.
8. **Markdown first paint depends on project size.** `render-markdown` setup is constant, but
   parser/query work and terminal response time vary; the 60.7–67.3 ms range is for a 6-line file.

---

## 9. Reproduction

Run from `/Users/anvndev/.config/nvim`. The PTY/measurement scripts live outside the repository at
`/private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/`
(`pty_capture.py`, `probe_state_v2.lua`, `probe_input_v2.lua`, `mem_after.py`, `final_after.py`).

```bash
# Process startup (5 warm-up, 10 measured)
D=$(mktemp -d)
for i in $(seq 1 5); do nvim --startuptime "$D/w$i.log" --headless -c qa; done
for i in $(seq 1 10); do
  nvim --startuptime "$D/$i.log" --headless -c qa
  grep 'NVIM STARTED' "$D/$i.log" | tail -1 | awk '{print $1}'
done

# Core init -> VimEnter (headless)
nvim --headless -c 'lua vim.api.nvim_create_autocmd("VimEnter",{once=true,callback=function()
  io.write(("%.4f\n"):format((vim.uv.hrtime()-_G.nvimz_start_time)/1e6)); vim.cmd("qa!") end})'

# State after startup: modules, plugins, filetype, Treesitter, LSP
PROBE_OUT=/tmp/state.json nvim --headless -c 'luafile /private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/probe_modules_v2.lua'

# First paint (real PTY, n=5 per scenario)
python3 /private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/pty_capture.py \
  --out /tmp/empty.json --duration 0.7

# Memory tree
python3 /private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/mem_after.py
```

The exact final batch is reproducible with:

```bash
python3 /private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/final_after.py
```

It writes `final-after/all.json` (startup, VimEnter, paint, state, input, memory). The temporary
Tier 1/block instrumentation used for §4.2 and §4.5 was removed before the final batch; its
method is a single `uv.hrtime()` pair around the synchronous callback, recorded in a global and
read by an external probe.

---

## 10. Conclusion

The approved loading boundaries are implemented and measured. The first screen is correct,
the first buffer keeps its highlighting, normal editing is responsive, and specialized features
are paid only when invoked. The only deliberate regressions are the later Go/Markdown first
paint, which buys stable highlighting and Markdown layout, and the one-time native package cost
on first feature activation. Gate C should validate these results interactively on the real
terminal and, if available, on a second host.

---

## 11. Gate C handoff

Recommended real-world checks, in this order:

1. **Visual first screen** in the user's terminal: empty startup shows only the dashboard, no
   native intro, and no statusline/menu flash; Lua/Go/Markdown files show theme, statusline,
   Treesitter highlighting, and (Markdown) rendered layout at first paint.
2. **Normal editing session:** type for several minutes without invoking AI or DAP; confirm no
   `copilot-language-server`, `dap`, `gp`, `render-markdown`, `oil`, or `conform` process/module
   appears, and idle CPU stays at ~0%.
3. **Copilot:** press `<leader>at`, confirm the "Copilot enabled" notice, then insert and confirm
   one language-server process, suggestions, and no duplicate server on repeated presses.
4. **DAP:** use `<leader>db` and a real Go debug session; confirm adapters/configurations are
   available, dap-ui opens, and a second session does not duplicate listeners.
5. **AI chat/rewrite:** `<leader>aa` and a visual `<leader>ar`; confirm gp commands, Ollama
   reachability, and that a failed Ollama start is reported once.
6. **Markdown:** open a Markdown file from an empty session; confirm the first render is already
   decorated and opening a second Markdown buffer does not re-run setup.
7. **LSP:** open a real Lua/Go project; confirm diagnostics, `gd`/`K`, inlay hints, and the
   statusline update after attach.
8. **Missing tools:** run with `gopls` and `ollama` absent; confirm one named warning each, no
   crash, and unrelated features still work.
9. **Memory:** sample the process tree before and after Copilot activation; confirm non-AI
   sessions stay near the measured ~110 MiB for Lua and ~154 MiB for Go.
10. **Second host:** repeat `--startuptime`, PTY first paint, and memory on Linux if available;
    do not assume the macOS ranges transfer.
