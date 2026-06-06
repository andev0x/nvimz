# Language Support

This document details the preconfigured language integrations and explains how to customize and extend LSP (Language Server Protocol) servers and code formatters in **nvimz**.

---

## Language Support Philosophy

**nvimz** implements a native-first, zero-overhead philosophy for development utilities:

* **System Path Resolution:** Instead of downloading language servers and formatters into Neovim's private runtime namespaces via heavy manager plugins (e.g., Mason), **nvimz** expects these binaries to be pre-installed on your system and resolvable via `$PATH`.
* **Asynchronous Formatting:** Formatting is handled asynchronously via the highly optimized `conform.nvim` plugin using system binaries, preventing editor freezes or key lockups during file writes.
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
| **JavaScript / TypeScript** | `typescript-language-server` | (System configured) |
| **Rust** | `rust-analyzer` | `rustfmt` |
| **Terraform / HCL** | `terraform-ls` | `terraform fmt` |
| **YAML** | `yaml-language-server` | (System configured) |

---

## Extending LSP & Formatters

Adding a new language server or custom formatter is straightforward and managed directly within the centralized registry at `lua/infra/registry/languages.lua`.

### 1. Registering a Language Server

To add a new LSP server, add its configuration to the `M.lsp_servers` table. Make sure that the server binary (e.g., `gopls`, `pyright`, etc.) is installed in your system's `$PATH`.

Example block in `lua/infra/registry/languages.lua`:

```lua
M.lsp_servers = {
    -- Existing servers...
    
    -- Adding a new server configuration
    gopls = {
        cmd = { "gopls" },
        filetypes = { "go" },
        root_markers = { "go.mod", ".git" },
    },
}
```

### 2. Registering a Formatter

Formatters are managed in the `M.formatters_by_ft` table. Map your target filetype key to a table of preferred formatters.

Example block in `lua/infra/registry/languages.lua`:

```lua
M.formatters_by_ft = {
    -- Map filetype to the system binary name
    lua = { "stylua" },
    python = { "black" },
    go = { "gofmt" },
}
```
