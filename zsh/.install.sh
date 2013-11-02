#!/bin/bash
# This script will be sourced during installation

# Find Zsh path
zsh_path="$(which zsh | head -1)"

# Require sudo if not a standard shell
grep "$zsh_path" /etc/shells &>/dev/null || sudo='sudo'

# Change default shell
echo "$USER, please type your password to change your default shell to Zsh:"
$sudo chsh -s "$zsh_path" $USER
