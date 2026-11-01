# Language Support

This document details the preconfigured language integrations and explains how to customize and extend LSP (Language Server Protocol) servers and code formatters in **nvimz**.

---

## Language Support Philosophy

**nvimz** implements a native-first, zero-overhead philosophy for development utilities:

* **System Path Resolution:** Instead of downloading language servers and formatters into Neovim's private runtime namespaces via heavy manager plugins (e.g., Mason), **nvimz** expects these binaries to be pre-installed on your system and resolvable via `$PATH`.
* **Formatter Integration:** On-save formatting runs asynchronously through `conform.nvim` using system binaries. Manual formatting with `<leader>fm` waits for a bounded result so failures are visible.
* **Non-Blocking LSP Setup:** Uses Neovim's native, super-lightweight `vim.lsp.start` client mapping rather than third-party initialization wrapper libraries, keeping memory usage clean and module resolution incredibly fast.

---

## Preconfigured Languages

**nvimz** includes native configurations and out-of-the-box wiring for the following languages:

| Language | Language Server (LSP) | Formatter(s) |
| --- | --- | --- |
| **Go** | `gopls` | `gofmt` |
| **Lua** | `lua-language-server` | `stylua` |
| **Python** | `pyright` | `black` |
| **Java** | `jdtls` | `google-java-format` |
| **JavaScript / TypeScript** | `typescript-language-server` | — |
| **Rust** | `rust-analyzer` | — |
| **Terraform / HCL** | `terraform-ls` | `terraform fmt` |
| **YAML** | `yaml-language-server` | — |
| **JSON / JSONC** | `vscode-json-language-server` | — |
| **Markdown** | `marksman` | — |
| **Shell (`sh`/`bash`/`zsh`)** | — | `shfmt` |

Only filetypes listed in `M.formatters_by_ft` are formatted on save. Add an entry there to wire up `prettier`, `rustfmt`, or any other system formatter.

---

## Extending LSP & Formatters

Adding a new language server or custom formatter is straightforward and managed directly within the central declaration file at `lua/nvimz/config/languages.lua`.

### 1. Registering a Language Server

To add a new LSP server, add an entry to the existing `M.lsp_servers` table. Make sure that the server binary (e.g., `gopls`, `pyright`, etc.) is installed in your system's `$PATH`.

Example addition in `lua/nvimz/config/languages.lua`:

```lua
M.lsp_servers.my_server = {
    cmd = { "my-server", "--stdio" },
    filetypes = { "myft" },
    root_markers = { ".git" },
}
```

### 2. Registering a Formatter

Formatters are managed in the `M.formatters_by_ft` table. Map your target filetype key to a table of preferred formatters.

Example addition in `lua/nvimz/config/languages.lua`:

```lua
M.formatters_by_ft.myft = { "my-formatter" }
```

If the formatter's executable name differs from the key used by `conform.nvim`, also map it in
`M.formatter_binaries` so `:checkhealth nvimz` checks the correct binary:

```lua
M.formatter_binaries["my-formatter"] = "my-formatter-bin"
```
