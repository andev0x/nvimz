# Progressive Performance — Gate C Report

**Phase:** Gate C real-world validation
**Date:** 2026-11-02
**Repository:** `/Users/anvndev/.config/nvim` @ `main` (`abf4704` + two uncommitted guard fixes)
**Baseline:** `docs/audit/progressive-performance-baseline.md` (Gate A)
**Gate B:** `docs/audit/progressive-performance-final-report.md`
**Status:** Conditional pass. Interactive behavior and performance are validated. Two activation
defects were found and fixed. A real Delve session could not complete on this host, and two
configured Ollama models are not installed.

---

## 1. Result in one paragraph

Gate C drove the committed Gate B code through real terminal sessions: dashboard and file startup,
a 30-second mixed editing soak, Copilot activation, DAP activation, gp chat plus a real Ollama
rewrite, repeated Markdown buffers, real `lua_ls` and `gopls` projects, missing tools, lazy
keymaps, and process-tree memory. The first screen is correct, normal editing stays quiet, and
specialized features are paid only when invoked. Two defects were found that Gate B's headless
measurements could not see. The dashboard's programmatic cursor placement raised `CursorMoved`
during startup, loading the git/scope chunk in every real UI session; it now ignores non-editing
buffers. An LSP hover creates an unlisted `nofile` Markdown buffer, which was activating all 66
`render-markdown` modules on the first `K`; Markdown now activates only for listed, normal buffers.
After the fixes, empty dashboard first paint is **40.7 ms** (n=5; Gate B 44.2 ms), headless
`NVIM STARTED` is **10.44 ms** (Gate B 10.25 ms), and headless `VimEnter` is **7.59 ms** (Gate B
7.75 ms). Normal editing remains at 0% idle CPU with no AI/DAP/Markdown/Oil/conform activation.
The remaining blockers are environmental: Delve hangs at process launch, `qwen2.5:7b` and
`qwen3:8b` are not installed, and no Linux host is available.

---

## 2. Method and evidence

Every scenario used a fresh Neovim process attached to a real 120×40 PTY with emulated terminal
queries (background color, DSR, DA1/DA2, kitty keyboard, DECRQM), so the startup path matches a
normal terminal rather than a 125 ms query timeout. A small read-only helper (`gatec_api.lua`) was
loaded before `init.lua` to expose snapshots, screens, module/plugin lists, event timestamps, and
keystroke injection over `--listen`/`--remote-expr`. No feature was stubbed or skipped.

- Host: macOS 27.0.1 / arm64, Apple M1 Pro, 16 GB, Neovim 0.12.6 / LuaJIT 2.1.
- Sessions: one process per scenario; all closed with `qa!`; child processes checked.
- Host load during the final batches: 2.6–4.4 (1-minute average), so paint numbers are spot checks,
  not a replacement for Gate B's controlled batches.
- Raw evidence: `gatec-results/*.json` and `paint.json` under
  `/private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/`.
- Harness: `gatec_api.lua`, `gatec_session.py`, `gatec_run.py`, `pty_capture.py`.

The PTY proves ordering, screen contents, process state, and timing. It does not prove perceived
smoothness; the 30-second soak and key-by-key sessions are the closest automated substitute for
sitting at the terminal.

---

## 3. Defects found and fixed

Both fixes are confined to `lua/runtime/phases.lua`. Neither adds a scheduler, registry, cache, or
new dependency.

### 3.1 Dashboard cursor movement loaded the Tier 2 cursor chunk at startup

**Observed:** Empty dashboard, event trace:

| Event | Time |
| --- | --- |
| `VimEnter` | 17.4 ms |
| `FileType=dashboard` | 28.6 ms |
| `CursorMoved` (from dashboard `nvim_win_set_cursor`) | 31.8 ms |

The `CursorMoved` handler therefore ran `features.interface.scope_line` and `features.git` during
startup. Modules were 69 instead of the expected 43, and `mini.git`/`mini.diff` were active in a
session with no file.

**Fix:** `cursor_chunk_relevant()` returns true only for a normal, listed editing buffer with a
non-empty filetype other than `dashboard`. Dashboard and other special buffers no longer trigger
the chunk; the first movement in a real file still does.

**After:** Empty dashboard modules **69 → 65**; `features.git`, `features.interface.scope_line`,
`mini.git`, and `mini.diff` are absent. Pressing `j` on the dashboard also leaves them absent. A
real file still triggers the chunk (the file-open `CursorMoved` at ~26 ms), so diff signs and the
scope line are present in the first editing frame rather than appearing after a later movement.

**Why not defer file startup too:** opening a file already counts as the first editing interaction,
and deferring the 1.6–1.8 ms chunk would make diff signs/scope lines appear after the first cursor
movement — the visible switch the mission forbids. The dashboard has no such trade-off.

### 3.2 An LSP hover activated the entire Markdown renderer

**Observed:** In a Go file, pressing `K` on `main.Bad` opened a `nofile`, unlisted Markdown hover
buffer. The `FileType=markdown` handler activated `render-markdown.nvim`: plugin active, **66**
`render-markdown.*` modules loaded, first-hover cost ~20 ms.

**Fix:** `is_markdown_buffer()` requires `filetype == "markdown"`, `buftype == ""`, and
`buflisted`. Both the startup check and the `FileType` handler use it. Real Markdown files and the
listed gp chat transcript still activate the renderer; plugin-owned floats do not.

**After:** `K` on the same Go symbol opens the hover with the plugin set still
`mini.nvim`, `tokyonight` and no `render-markdown` modules. Opening `one.md` or a gp chat still
loads the renderer and produces decorations (4 extmarks on `one.md`).

---

## 4. Scenario results

`checks` counts are assertions from the automated harness. A failing model-availability check is
reported as a configuration finding, not a code failure.

| Scenario | Result | Key evidence |
| --- | --- | --- |
| Visual first screen (empty/Lua/Go/Markdown) | **29/29** | Dashboard only, no native intro, theme/statusline/Treesitter at first content, Markdown decorated (4 extmarks) |
| 30-second mixed editing soak | **4/4** | 132 actions, module count stable at 109, plugin set stable, idle CPU **0.0%**, RSS 133.8 MiB |
| Editing + first write | **13/13** | Feed median 16.8 ms / max 43.5 ms (includes RPC overhead), 0% idle, conform only after write, no AI/DAP/Markdown/Oil |
| Copilot activation | **7/7** | One `copilot-language-server`, one client, repeat presses keep one server, RSS 600–712 MiB tree (server 342–425 MiB) |
| DAP activation | **10/10** | No DAP before use; stubs + `CmdUndefined`; first breakpoint loads 4 plugins; one `dapui_config` listener; no dapui before a session |
| DAP real session | **blocked** | Adapter starts and answers `initialize`; `launch` never answers (90 s); `dlv exec` also hangs on this host |
| AI chat + rewrite | **7/9** | Chat opens, gp loads, real Editor rewrite produced a comment; Scout/Judge models missing |
| Markdown repeated buffers | **9/9** | First buffer loads/decorates; second buffer keeps one plugin and decorations; no duplicate setup |
| LSP Lua/Go projects | **9/9** | gopls diagnostics, `K` hover, `gd` jump, inlay hints, statusline updates for gopls and lua_ls; hover no longer loads Markdown |
| Missing gopls/ollama | **5/5** | One `LSP server 'gopls' not found: gopls`; no crash; gp still opens without ollama |
| Lazy keymap smoke test | **7/7** | `gs`, `gb`, `gd`, `e`, `fm`, `ff`, `fg`, `tt`, and `ds` (empty session) all work |

### 4.1 Startup and first paint

Final headless batches (load average 2.6–2.8):

| Metric | Gate B | Gate C |
| --- | --- | --- |
| `--startuptime` `NVIM STARTED` (n=10) | 10.25 ms | **10.44 ms** (10.2–11.4) |
| Headless `VimEnter` (n=10 / n=5) | 7.75 ms | **7.59 ms** (7.4–7.9) |
| Empty dashboard first content (n=5) | 44.2 ms | **40.7 ms** (39.2–43.8) |
| Lua first content (n=5) | 44.6 ms | **45.2 ms** (44.3–49.1) |
| Go first content (n=5) | 50.2 ms | **47.8 ms** (44.8–51.7) |
| Markdown first content (n=5) | 63.2 ms | **61.4 ms** (59.6–67.8) |

The dashboard improved by ~3.5 ms, consistent with removing the startup cursor chunk. Lua is flat;
Go and Markdown are within their Gate B ranges on this host. No native intro was captured in any
scenario. These are spot checks under a loaded host, not a new benchmark of record.

### 4.2 Empty-session module count: live UI vs headless

Gate B's **43** module figure is a headless/no-UI measurement. A live UI must also load theme,
icons, statusline, and dashboard (and their `mini`/`tokyonight` submodules). After the 3.1 fix, a
live empty dashboard settles at **65 modules** and **27.0 MiB**; the headless equivalent remains
43. The previously reported "62 after probe-induced cursor activity" was the live UI with the
cursor chunk loaded. The acceptance claim is unchanged in substance: no LSP, diagnostics, Markdown,
AI, DAP, Oil, conform, or git/scope modules are loaded on an idle dashboard.

### 4.3 Long editing session

The soak typed, inserted, moved, yanked, pasted, undid, and searched for 30 seconds (132 actions).
Snapshots every ~4.6 seconds were identical: 109 modules, plugins `mini.nvim` + `tokyonight`,
no AI/DAP/Markdown/Oil/conform. Idle CPU over 3 seconds was **0.0%**. No delayed timer or hidden
warm-up appeared. First write loaded conform and formatted through `stylua`, as designed.

### 4.4 Copilot

`<leader>at` loaded `copilot.lua` and printed `Copilot enabled`; no Copilot language server existed
before insert. After insert, exactly one `copilot-language-server` process and one `copilot` LSP
client were attached. Two further `<leader>at` presses kept exactly one server. The `:Copilot status`
lazy command also loads the plugin through its stub without crashing; because it queries status it
does start the server (expected for that command). Memory:

| State | Tree RSS | Breakdown |
| --- | --- | --- |
| Normal Lua session before Copilot | 89.8–97.9 MiB | nvim ~31 MiB, lua_ls ~58 MiB |
| After activation + insert | 599.7–711.7 MiB | nvim ~33 MiB, lua_ls 231–254 MiB, Copilot 342–425 MiB |

The Copilot server dominates and varies with its Node heap. The absolute total is higher than Gate
B's 408–416 MiB because that measurement did not include a fully indexed `lua_ls`; the Copilot
server itself is in the same range. The opt-in behavior and the one-server invariant are unchanged.

### 4.5 DAP and the Delve blocker

Demand loading works: before use there are no DAP modules/plugins, only `DapNew`, `DapEval`, and
`DapSetLogLevel` argument stubs and the `CmdUndefined` patterns `Dap*`/`Gp*`/`Lsp*`.
`:DapToggleBreakpoint` resolved through `CmdUndefined`, loaded DAP, and did not crash. `<leader>db`
loaded all four plugins, set line 8, and installed one `dapui_config` listener; a repeated
`ensure_dap()` kept one listener and did not open dapui.

A real Go session could not reach a stopped state on this host. The evidence:

- `dlv dap` starts, answers `initialize` successfully, receives `launch`, logs
  `launching process with args`, and never answers — 30 s with nvim-dap, 90 s with a minimal
  Python DAP client.
- `dlv exec /tmp/gatec-main --headless` also hangs at process launch.
- A stale `debugserver`/`__debug_bin` pair from the first attempt was killed and removed.
- nvim-dap's own log shows a correct `launch` request; the adapter, not the config, is stuck.

This is a tooling/environment issue (Delve 1.27.2 + Go 1.27.3 + macOS 27), not a regression from
tiered loading. The dap-ui/adapters/listener path is verified; the stopped-state UI is not.

### 4.6 AI

`<leader>aa` opened a gp chat buffer (`markdown`, listed) and loaded `gp.nvim`; the chat also loads
`render-markdown`, which is expected for a listed Markdown transcript. A visual `<leader>ar` with
the configured Editor agent produced a real Ollama result. gp inserted the model's fenced output
verbatim, including the opening fence and a truncated assignment:

````text
```lua
-- Initialize value to 1
local value = 
return value
```
````

That is model output, not a loading/configuration failure: the rewrite path, Ollama request, and
buffer replacement all completed.

Configured models on this host:

| Agent | Model | Installed |
| --- | --- | --- |
| Scout (default chat) | `qwen2.5:7b` | **no** |
| Judge | `qwen3:8b` | **no** |
| Editor (default command) | `qwen2.5-coder:7b` | yes |

Ollama is reachable and the Editor rewrite works. A Scout/Judge chat will fail at the model lookup
until those models are pulled or the agent config is changed. Gate C did not change the models.
`render-markdown` loading for the chat is deliberate; the hover guard only excludes unlisted
plugin floats.

### 4.7 Markdown, LSP, and missing tools

- Markdown: opening `one.md` from an empty session loaded one renderer and 4 extmarks; opening
  `two.md` kept one renderer and decorated it. Direct Markdown startup also decorated at first
  content.
- LSP: gopls reported one error on `var Bad int = "not an int"`, `K` opened a hover float, `gd`
  jumped to `add` in `main.go`, inlay hints were enabled, and the statusline showed `gopls`.
  `lua_ls` attached in a real Lua project and the statusline updated. `K` no longer loads the
  Markdown renderer.
- Missing tools: with `gopls` and `ollama` removed from `PATH`, one named gopls warning appeared
  and did not repeat on a second Go buffer; the editor stayed alive; gp still opened without
  Ollama. Missing Ollama is a silent skip by design (the final report calls this the optional
  warning path).

### 4.8 Lazy entry points

`<leader>gs` ran `:Git status` (buffer `minigit://…/git status`), `<leader>gb` opened blame,
`<leader>gd` toggled the diff overlay, `<leader>e` opened and closed Oil, `<leader>fm` loaded
conform, `<leader>ff`/`<leader>fg` opened the native picker, and `<leader>tt` opened a terminal.
`<leader>ds` opened the dashboard in an argument-free session. In a session started with a file,
`<leader>ds` is a no-op because `dashboard.setup()` guards on `argc() > 0`; this is pre-existing
behavior, not a tiered-loading regression, and the key was validated in the empty session.

---

## 5. Remaining limitations

1. **Delve cannot launch a debuggee on this host.** Real stopped-state UI is unverified. Retry after
   a Delve/Go/macOS update; the config side is ready.
2. **Two AI models are missing.** Pull `qwen2.5:7b` and `qwen3:8b` or change the agent config
   before relying on Scout/Judge.
3. **Single host.** macOS 27 / arm64 only. No Linux VM is available: `colima status` reports not
   running, `limactl list` is empty, and the Docker socket does not exist. The second-host check
   was not performed.
4. **Host variance.** Sessions ran at load 2.6–4.4. Paint medians moved by a few milliseconds
   between batches; Gate B's controlled n=5 values remain the benchmark of record.
5. **Live UI vs headless module counts.** Use 65 for a live empty dashboard and 43 for headless.
   Do not compare them as if they measure the same thing.
6. **`<leader>ds` with file arguments.** The dashboard guard intentionally returns when `argc() > 0`,
   so the manual key only opens the dashboard in an argument-free session.
7. **`:DapContinue` before a session** opens the native configuration picker when several Go
   configs exist. That is normal interactive behavior, but it blocks automated key injection until
   a choice is made; Gate C used `:DapToggleBreakpoint` to validate `CmdUndefined`.
8. **PTY, not human eyes.** The harness proves screen contents and timing, not perceived smoothness.

---

## 6. Verification matrix

| Gate C handoff item | Result |
| --- | --- |
| Visual first screen | Pass: dashboard/file content, theme, statusline, Treesitter, Markdown decoration; no native intro |
| Normal editing, no AI/DAP | Pass: 30 s soak, 0% idle, no optional modules/processes |
| Copilot | Pass: opt-in, one server, no duplicate on repeated presses |
| DAP | Partial: demand loading, breakpoints, listeners pass; real session blocked by Delve |
| AI chat/rewrite | Partial: chat and Editor rewrite pass; Scout/Judge models missing |
| Markdown repeated buffers | Pass: first decorated, second decorated, one renderer |
| LSP | Pass: diagnostics, hover, definition, inlay hints, statusline for gopls and lua_ls |
| Missing tools | Pass: one gopls warning, no crash, gp opens without Ollama |
| Memory | Pass with breakdown: empty 27 MiB; Copilot server 342–425 MiB; non-AI sessions stay low |
| Second host | Not performed: no Linux host/VM available |

---

## 7. Reproduction

The harness lives outside the repository at
`/private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf/`:

```bash
cd /private/var/folders/0z/x6n_jq_s0qv68_1ldw38p2b00000gn/T/opencode/nvimz-perf
python3 gatec_run.py visual     # first screen, file startup, Markdown decorations
python3 gatec_run.py editing    # mixed editing + first write
python3 gatec_run.py soak       # 30-second session
python3 gatec_run.py copilot    # opt-in + one server + toggles
python3 gatec_run.py dap        # lazy loading + breakpoint + listeners
python3 gatec_run.py ai         # chat + real Editor rewrite + model check
python3 gatec_run.py markdown   # repeated buffers
python3 gatec_run.py lsp        # gopls/lua_ls + hover + definition + inlay
python3 gatec_run.py missing    # PATH without gopls/ollama
python3 gatec_run.py keys       # lazy keymaps
python3 gatec_run.py memory     # process-tree samples
python3 gatec_run.py startup    # headless startup / VimEnter
```

Delve check used `probe_dap.lua` and `probe_dap_exec.lua`; the minimal Python DAP client is in the
Gate C transcript. The two fixes are in `lua/runtime/phases.lua` and are not committed.

---

## 8. Conclusion

Gate C confirms the Gate B architecture in real terminal use: the first screen is correct, editing
is quiet and responsive, and Copilot, DAP, gp, Oil, conform, and Markdown remain paid-for-on-use.
The two startup activations that headless probes missed are fixed. The only unresolved items are
external: Delve cannot launch on this macOS/Go combination, two Ollama models are absent, and no
Linux host was available. No commit, tag, or publish was made.
