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
  python3 -m pip install --force-reinstall --upgrade pynvim
  if ! [[ "$SHELL" =~ /zsh$ ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
}

# Install dev tools
__devtools() {
  # Cloud
  brew reinstall ansible awscli helm kubectl packer terraform vault
  # Golang
  brew reinstall go
  GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint@latest
  GO111MODULE=on go get github.com/mgechev/revive@latest
  GO111MODULE=on go get golang.org/x/tools/cmd/goimports@latest
  GO111MODULE=on go get golang.org/x/tools/gopls@latest
  # Node
  brew reinstall node
  npm install -g npm svelte-language-server typescript
  # Rust
  brew reinstall rustup-init rust-analyzer
  rustup-init -y --default-toolchain=stable --no-modify-path
  # Shell
  brew reinstall shellcheck
}

# Configure the OS
__configure() {
  # Disable key repeat delay
  defaults write -g InitialKeyRepeat -int 50
  defaults write -g KeyRepeat -int 10
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
