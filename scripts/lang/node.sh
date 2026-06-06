#!/usr/bin/env bash

# Language provisioning for Node.js
# Data derived from lua/infra/registry/languages.lua

install_node_deps() {
    log_info "Setting up Node.js environment..."
    has node || install_package "nodejs" && install_package "npm"
    has typescript-language-server || npm install -g typescript typescript-language-server vscode-langservers-extracted prettier
}
