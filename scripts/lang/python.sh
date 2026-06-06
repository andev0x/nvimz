#!/usr/bin/env bash

# Language provisioning for Python
# Data derived from lua/infra/registry/languages.lua

install_python_deps() {
    log_info "Setting up Python environment..."
    case "$OS" in
        macos) install_package "python" && install_package "pipx" ;;
        ubuntu) install_package "python3" && install_package "python3-pip" && install_package "python3-venv" && install_package "pipx" ;;
        arch) install_package "python" && install_package "python-pip" && install_package "python-pipx" ;;
    esac
    has basedpyright || pipx install basedpyright
    has ruff || pipx install ruff
}
