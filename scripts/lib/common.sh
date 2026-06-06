#!/usr/bin/env bash

# UI Helpers
info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$1"; }
ok() { printf "\033[1;32m[OK]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }
