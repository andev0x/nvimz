#!/usr/bin/env bash

# Language provisioning for Rust
# Data derived from lua/infra/registry/languages.lua

install_rust_deps() {
    log_info "Setting up Rust environment..."
    if ! has rustc; then
        curl https://sh.rustup.rs -sSf | sh -s -- -y
    fi
    source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"
    rustup component add rust-analyzer rustfmt clippy || true
}
