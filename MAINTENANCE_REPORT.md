# nvimz Maintenance Report
Date: 2026-10-19 01:17:35

## 1. Lockfile Validation
✅ Lockfile (`nvim-pack-lock.json`) is valid JSON.

## 2. Environment Health
```
────────────────────────────────────────────────────────────
 Core
────────────────────────────────────────────────────────────
 git                    OK         git version 2.55.0
 rg                     OK         ripgrep 15.2.0features:+pcre2simd(compile):+NEONsimd(runtime):+NEONPCRE2 10.45 is available (JIT is available)
 fd                     OK         fd 10.5.0
────────────────────────────────────────────────────────────
 LSP
────────────────────────────────────────────────────────────
 gopls                  OK         golang.org/x/tools/gopls v0.23.0
 lua_ls                 OK         3.19.1
────────────────────────────────────────────────────────────
 Formatters
────────────────────────────────────────────────────────────
 stylua                 OK         stylua 2.5.2
 shfmt                  OK         3.14.1
 prettier               OK         3.9.9
────────────────────────────────────────────────────────────
 Linters
────────────────────────────────────────────────────────────
 golangci-lint          OK         golangci-lint has version 2.14.0 built with go1.27.1 from 114493f on 2026-09-24T10:54:53Z
```

## 3. Startup Benchmark
Total startup time: **006.919ms** (Target: <10ms)

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
✅ markdown_inline: Already installed
✅ json: Already installed
--------------------------------------------------
```

