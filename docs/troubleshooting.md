# Troubleshooting

**nvimz** does not install language servers or formatters at runtime. If a feature does not start, first check that its binary exists on your `$PATH`.

## In Neovim

```vim
:checkhealth nvimz      " core tools, servers, formatters, parsers, plugins
:checkhealth vim.pack   " lockfile and plugin directory
:PackStatus             " quick plugin and tool summary
:LspInfo                " attached clients and their status
:LspLog                 " open the LSP log
:LspStart / :LspStop / :LspRestart
```

## From a Shell

```bash
./scripts/doctor
```

This checks required tools and installed Treesitter parsers. Use `:ParsersUpdate` to rebuild parsers after upgrading Neovim or changing the parser pins.

## Slow Startup

Run `:NvimzBenchmark`. It measures three consecutive starts and lists the slowest sourced modules. For the expected numbers and measurement boundaries, see [Performance](performance.md).
