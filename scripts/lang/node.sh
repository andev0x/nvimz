#!/usr/bin/env bash

# Language provisioning for Node.js
# Mirrors lua/nvimz/config/languages.lua

install_node_deps() {
    log_info "Setting up Node.js environment..."
    if ! has node; then
        install_package "nodejs"
    fi
    if ! has npm; then
        install_package "npm"
    fi
    has typescript-language-server || npm install -g typescript typescript-language-server vscode-langservers-extracted prettier
}
