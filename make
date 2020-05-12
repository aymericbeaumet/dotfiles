#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Symlink the dotfiles to the $HOME directory
__symlink() {
  from_directory="$(greadlink -f "$(pwd)/src")"
  find "$from_directory" -type file -o -type link | while read -r from ; do
    to="$HOME/${from##"$from_directory/"}"
    to_directory="$(dirname "$to")"
    rm -rf "$to"
    mkdir -p "$to_directory"
    ln -svf "$from" "$to"
  done
}

# Install the dependencies
__install() {
  source ./src/.zprofile
  if ! command -v brew &> /dev/null ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  mkdir -p "$HOME/Workspace" "$GOPATH"
  git submodule update --init --recursive
  brew bundle
  if ! [[ "$SHELL" =~ /zsh$ ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
}

# Install editor tools
__tools() {
  # Terraform
  brew install tflint || brew upgrade tflint
  # Rust
  rustup update
  rustup component add rustfmt rls rust-analysis rust-src
  # Go
  go get golang.org/x/tools/cmd/goimports golang.org/x/tools/gopls
  brew install golangci/tap/golangci-lint || brew upgrade golangci/tap/golangci-lint
  # Vim
  pip3 install vim-vint
  # Shell
  brew install shellcheck
}

# Configure the OS
__configure() {
  # Disable key repeat delay
  defaults write NSGlobalDomain KeyRepeat -int 1
}

for command in "$@"; do
  if [[ "$(type "__$command" 2>/dev/null)" == *function* ]]; then
    printf '\e[94m%s...\e[0m\n' "$command"
    "__$command"
    printf '\e[92mok\e[0m\n'
  else
    printf '\e[91m-> skipping unknown command "%s"\e[0m\n' "$command" >&2
  fi
done
