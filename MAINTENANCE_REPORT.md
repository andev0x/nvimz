# nvimz Maintenance Report
Date: 2026-05-28 09:30:49

## 1. Lockfile Validation
✅ Lockfile (`nvim-pack-lock.json`) is valid JSON.

## 2. Environment Health
```
────────────────────────────────────────────────────────────
 Core
────────────────────────────────────────────────────────────
 git                    OK         git version 2.54.0
 rg                     OK         ripgrep 15.1.0features:+pcre2simd(compile):+NEONsimd(runtime):+NEONPCRE2 10.45 is available (JIT is available)
 fd                     OK         fd 10.4.2
────────────────────────────────────────────────────────────
 LSP
────────────────────────────────────────────────────────────
 gopls                  OK         golang.org/x/tools/gopls v0.22.0
 lua_ls                 OK         3.18.2-dev
────────────────────────────────────────────────────────────
 Formatters
────────────────────────────────────────────────────────────
 stylua                 OK         stylua 2.5.2
 shfmt                  OK         3.13.1
────────────────────────────────────────────────────────────
 Linters
────────────────────────────────────────────────────────────
 golangci-lint          OK         golangci-lint has version 2.12.2 built with go1.26.2 from c0d3ddc on 2026-05-06T11:01:25Z
```

## 3. Startup Benchmark
Total startup time: **009.716ms** (Target: <20ms)

## 4. Parser Validation
```
--------------------------------------------------
 nvimz: Treesitter Parser Manager
--------------------------------------------------
✅ c: Already installed
✅ cpp: Already installed
✅ go: Already installed
✅ rust: Already installed
✅ python: Already installed
✅ typescript: Already installed
✅ tsx: Already installed
✅ lua: Already installed
✅ vim: Already installed
✅ vimdoc: Already installed
✅ gitcommit: Already installed
✅ git_rebase: Already installed
✅ diff: Already installed
✅ markdown: Already installed
--------------------------------------------------
```

