# Runtime Baseline Measurements

**Phase:** 1 — Architectural Audit & Design Baseline
**Date:** 2026-11-01
**Purpose:** Record reproducible pre-reconstruction numbers. Phase 3 compares against this file.

All numbers below were **measured**, not estimated, unless the paragraph explicitly says
"estimate". Measurements are from one machine and one Neovim build; limitations are listed in §7.

---

## 1. Environment

| Item | Value | Source |
| --- | --- | --- |
| Neovim | 0.12.6 | `nvim --version` |
| Lua runtime | LuaJIT 2.1.1793383622 | `nvim --version` |
| OS | macOS 27.0.1 (build 26A434), Darwin 27.0.0 | `sw_vers`, `uname -a` |
| CPU | Apple M1 Pro (arm64) | `sysctl machdep.cpu.brand_string` |
| Config root | `/Users/anvndev/.config/nvim` | `pwd` |
| Branch | `perf/optimize-logic` | `git branch --show-current` |
| Working tree | modified: `README.md`, `docs/{architecture,commands,languages,performance}.md` (user work, preserved) | `git status --short` |
| Plugins declared | 13 across 3 phases | `lua/infra/registry/plugins.lua` |
| Lua source files | 60 (`lua/`) — 4,949 lines | `find` + `wc -l` |
| Treesitter parsers installed | 16/16 required | runtime `language.inspect` sweep |
| `vim.pack` lockfile | present, 13 entries | `nvim-pack-lock.json` |

### Source inventory

| Area | Files | Lines |
| --- | --- | --- |
| `lua/runtime` | 5 | 207 |
| `lua/core` | 7 | 368 |
| `lua/infra` | 25 | 1,609 |
| `lua/features` | 21 | 1,945 |
| `lua/nvimz/picker` | 1 | 815 |
| `lua/machine` | 1 | 6 |

`lua/infra` breakdown: registry 445, deps 408, report 322, health 259, cache 62,
treesitter 49, license 41, view 23.

---

## 2. Startup — Warm Cache (primary metric)

Method: `nvim --startuptime <log> --headless -c qa`, bytecode cache present and warm,
10 consecutive runs, value = `NVIM STARTED` clock (ms).

| Run | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ms | 5.375 | 5.253 | 5.305 | 5.499 | 6.033 | 5.114 | 4.978 | 5.229 | 5.393 | 5.478 |

| Statistic | Value |
| --- | --- |
| n | 10 |
| Mean | **5.366 ms** |
| Median | **5.340 ms** |
| Min / Max | 4.978 / 6.033 ms |

**Reference only:** an earlier 5-run batch on the same host included a 12.157 ms first run
(bytecode cache warming). Treat the table above as the representative warm state.

## 3. Startup — Cold Bytecode Cache (isolated)

Method: `XDG_CACHE_HOME=$(mktemp -d) nvim --startuptime <log> --headless -c qa`, 5 runs.
This isolates the cold cache without deleting the user's real cache.

| Run | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- |
| ms | 7.331 | 5.574 | 5.436 | 5.629 | 6.003 |

Mean **5.995 ms**, median **5.629 ms**, range 5.436–7.331 ms. The first run pays the
compile/serialize cost; subsequent runs in the same isolated cache are warm.

## 4. Startup — Vanilla Neovim Reference

Method: `nvim --clean --headless -c qa`, 3 runs: 10.056, 6.635, 6.180 ms (mean 7.62 ms).
`--clean` has no bytecode cache and includes first-run effects; this is **not** a controlled
comparison, only context that nvimz's immediate path is not slower than stock startup on this
host.

## 5. Post-Startup Initialization (deferred phases)

Method: launch, then measure from `_G.nvimz_start_time` to a `vim.defer_fn(..., 1)` callback that
runs after the `VimEnter` phase timers. Confirms `infra.treesitter` and `dap` are loaded.

| Run | 1 | 2 | 3 | 4 | 5 |
| --- | --- | --- | --- | --- | --- |
| ms from process start | 36.09 | 35.34 | 32.69 | 32.34 | 31.91 |

Median **32.69 ms**. With startup at ~5.4 ms, deferred phase 1 + phase 2 work costs
**~26–30 ms after the first screen**. Phase 3 (AI) is not included (requires `InsertEnter`).

## 6. Startup Composition (`--startuptime`, representative warm run)

| Component | self+sourced (ms) |
| --- | --- |
| sourcing vimrc / `init.lua` | 1.853 |
| `require('runtime')` | 1.821 |
| `require('core')` | 0.885 |
| `require('runtime.loader')` (incl. `vim.loader`, `vim.fs`, `vim.uri`) | 0.286 |
| `require('core.options')` | 0.171 |
| `require('runtime.phases')` | 0.120 |
| `require('runtime.events')` | 0.105 |
| `require('core.commands')` | 0.104 |
| `require('core.globals')` | 0.101 |
| `require('core.keymaps')` | 0.100 |
| `require('core.filetypes')` | 0.099 |
| `require('core.autocmds')` | 0.099 |
| `require('runtime.bootstrap')` | 0.100 |
| Neovim `syntax/syntax.vim` (startup replay path) | 0.170 |
| `syntax/synload.vim` | 0.055 |
| `$VIMRUNTIME/filetype.lua` (sourced late by the hack) | 0.050 |
| **NVIM STARTED** | **5.801** |

Caveat: `--startuptime` quantizes self times to ~0.1 ms, so per-module values are coarse.
The aggregate (1.82 ms for the whole config) is reliable.

Runtime module counts:

| Point in time | Count |
| --- | --- |
| Nvimz modules loaded during startup | 12 (`runtime`, `runtime.*` ×4, `core` + 6) |
| Nvimz modules after phase 1+2 | +19 (8 `infra.*`, 11 `features.*`) |
| Total `package.loaded` entries after phase 1+2 (idle session) | **157** |

## 7. Operational and Runtime Probes

| Probe | Result | Method |
| --- | --- | --- |
| State cache read | 0.009 ms | `cache.get("startup_stats")` timed with `uv.hrtime()` |
| State cache write | once per session | `runtime/init.lua:27` → `state.save()` |
| Open a Lua file | 1.66 ms | `:edit lua/runtime/init.lua` timed |
| Filetype at `-c` time (file argument) | `""` | `nvim --headless /tmp/probe.lua -c 'lua print(vim.bo.filetype)'` |
| Filetype after deferred replay (~300 ms) | `"lua"` | same, inside `defer_fn(300)` |
| `:checkhealth nvimz` | no sections ("checks done") | `nvim --headless -c 'checkhealth nvimz'` |
| Commands after startup | 18 custom (12 pack/report + 1 License + 5 LSP) | `nvim_get_commands` |
| RSS after phase 1+2 | 21,004,288 B (~20.0 MiB) | `/usr/bin/time -l`, 400 ms wait |
| RSS immediate (`-c qa`) | 11,911,168 B (~11.4 MiB) | `/usr/bin/time -l` |
| RSS vanilla after 400 ms | 12,238,848 B (~11.7 MiB) | `nvim --clean` + 400 ms wait |
| `vim.pack.get()` | 13 entries; `gp.nvim`/`copilot.lua` inactive until phase 3 | headless dump |

RSS delta (~8.7 MiB) is the measured memory added by the phase-1/2 plugin set. It is a
whole-process maximum, not per-module attribution.

## 8. Limitations

1. **Single platform.** macOS 27 / arm64 only. No Linux host was available; Linux behavior is
   unverified beyond code inspection.
2. **Headless measurements.** `--headless` skips UI rendering. Theme, icons, statusline, and
   dashboard setup still execute when a UI exists; their cost is included only in the
   "phase completion" number, not in the 5.37 ms startup figure.
3. **Timer resolution.** Phase completion uses libuv timers; values are stable (±2 ms) but not
   microsecond-precise.
4. **Filesystem cache state.** Warm/cold depend on OS page cache; cold isolation controls the
   Lua bytecode cache only, not the OS cache.
5. **No per-module memory attribution.** Node/GC measurement was not attempted.
6. **Startup is already fast.** There is no obvious latency defect; the reconstruction targets
   maintenance cost, duplication, and failure behavior, not a vanity benchmark.

## 9. Reproduction

Run from the repository root. None of these commands modify tracked files.

```bash
# Warm startup (10 runs, summary)
W=""; for i in $(seq 1 10); do
  nvim --startuptime /tmp/warm-$i.log --headless -c qa >/dev/null 2>&1
  W="$W $(grep 'NVIM STARTED' /tmp/warm-$i.log | awk '{print $1}')"
done
echo $W

# Cold bytecode cache, isolated (does not touch ~/.cache/nvim/luac)
T=$(mktemp -d)
for i in 1 2 3 4 5; do
  XDG_CACHE_HOME=$T nvim --startuptime $T/c-$i.log --headless -c qa >/dev/null 2>&1
  grep 'NVIM STARTED' $T/c-$i.log
done

# Time until deferred phases finish
nvim --headless -c 'lua vim.defer_fn(function()
  io.write(string.format("%.2f\n", (vim.uv.hrtime() - _G.nvimz_start_time) / 1e6))
  vim.cmd("qa!") end, 1)'

# Loaded module count
nvim --headless -c 'lua vim.defer_fn(function()
  local n = 0; for _ in pairs(package.loaded) do n = n + 1 end
  print(n); vim.cmd("qa!") end, 500)'

# Diagnostics inventory
nvim --headless -c 'checkhealth nvimz' -c 'qa!'

# RSS
/usr/bin/time -l nvim --headless -c 'lua vim.defer_fn(function() vim.cmd("qa!") end, 400)'
```

The Phase 3 report must re-run these exact commands under the same conditions and record the
same statistics (mean, median, min/max, n).
