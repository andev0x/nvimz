#!/usr/bin/env bash

# Prompt utilities
prompt_yes_no() {
    read -p "$1 (y/n): " yn
    case $yn in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        * ) echo "Please answer yes or no."; prompt_yes_no "$1";;
    esac
}
