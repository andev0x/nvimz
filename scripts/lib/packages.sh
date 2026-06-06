#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/platform.sh"
detect_os

install_package() {
    local package=$1
    case "$OS" in
        macos) brew install "$package" ;;
        arch) sudo pacman -S --noconfirm "$package" ;;
        ubuntu) sudo apt install -y "$package" ;;
        *) log_error "Unsupported OS: $OS" ;;
    esac
}
