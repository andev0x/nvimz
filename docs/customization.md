# Customization

Keep host-specific settings out of the repository, and extend shared behavior through the declarative config files.

## Machine Overrides

Host-specific paths (such as the Python host) live in `lua/machine/local.lua`, which is gitignored:

```bash
cp lua/machine/example.lua lua/machine/local.lua
```

The example file documents the available overrides:

```lua
return {
    -- Override executable paths
    python_path = "/usr/bin/python3",
}
```

## Extension Points

| File | Purpose |
| --- | --- |
| `lua/core/keymaps.lua` | Personal keybindings |
| `lua/core/options.lua` | Editor options |
| `lua/nvimz/config/plugins.lua` | Plugin list and load tiers |
| `lua/nvimz/config/languages.lua` | LSP servers, formatters, icons |
| `lua/nvimz/config/parsers.lua` | Treesitter parser pins |

For adding language servers and formatters, see [Language Support](languages.md).
