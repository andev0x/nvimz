## System Design Guidelines (Architecture Blueprint)

* **Core Philosophy:** Pure minimalism (Zen), maximum performance (startup time < 15ms), self-contained operation, and absolute security for large Backend/Cloud DevOps codebases.

* **Target Environment:** Deep optimization for **Neovim 0.12+** and full utilization of the latest native APIs of the core.

* **Configuration Source Code Management:** Decomposing the system structure according to a standard layered model including `core` (basic behavior), `infra` (package management and LSP infrastructure), and `plugins` (detailed configuration for each task).

* **Bootstrap Mechanism:** Automatically installs the package management infrastructure and loads the entire configuration from A-Z when bringing the `init.lua` file to any new device without manual interaction.

---

## Modern Tech Stack Spec

* **Package Manager:** Uses **`vim.pack` (the `mini.deps` kernel)** to completely replace `lazy.nvim` / `packer.nvim`, loading packages asynchronously (`later`) to eliminate startup latency.

* **Syntax Highlighter:** Uses the built-in **Native Treesitter** of the Neovim 0.12+ core via an automatic triggering mechanism using `vim.treesitter.start()` based on file type, completely eliminating the cumbersome `nvim-treesitter` plugin.

* **Workspace Navigation & UI:** Utilizes the lightweight **`mini.nvim`** module trio, including:
* `mini.files` (Direct file management using Vim's text editing keys).

* `mini.pick` (Super-fast file/text finder, replacing Telescope).

* `mini.statusline` (Minimalist, elegant status bar).

* **Autocomplete Engine:** Uses **`mini.completion`** to connect directly to the native LSP data source, eliminating the complex plugin system of the `nvim-cmp` suite.

* * **Backend Code Intelligence:** Uses **`nvim-lspconfig` + `mason.nvim**` to automatically manage versions and establish stable connections with the main Language Servers: `gopls` (Go), `rust_analyzer` (Rust), `pyright` (Python), and `ts_ls` (TypeScript).

* **Debugger System:** Uses **`nvim-dap` + `nvim-dap-ui` + `nvim-dap-go**` configured to load dynamically (lazy-load) only when the actual debugging process is first triggered.

* **Local AI Integration:** Uses **`gen.nvim` to connect asynchronously with Ollama running locally (`qwen2.5-coder:7b`)** via a floating window, ensuring 100% security of the enterprise project's source code and preventing UI blocking.
