#!/usr/bin/env bash

# Language provisioning for Go
# Data derived from lua/infra/registry/languages.lua

install_go_deps() {
    log_info "Installing Go ecosystem dependencies..."
    # Using registry-defined binaries: lsp = gopls, formatter = gofmt, debugger = dlv
    # Package name for brew/apt/pacman is go
    install_package "go"
    # Additional logic for gopls, dlv
    go install golang.org/x/tools/gopls@latest
    go install github.com/go-delve/delve/cmd/dlv@latest
}
