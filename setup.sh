#!/usr/bin/env bash

set -ex
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

#
# Install homebrew if missing
#

if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

#
# Change origin to read/write and sync submodules
#

git remote set-url origin git@github.com:aymericbeaumet/dotfiles.git
git submodule update --init --recursive
git submodule update --remote --merge

#
# Symlink dotfiles
#

symlink() {
	target="$HOME/$1"
	rm -rf "$target"
	mkdir -p "$(dirname "$target")"
	ln -svf "$PWD/$1" "$target"
}

/usr/bin/find . -mindepth 1 -maxdepth 1 \( -type file -o -type link \) \( -name '.*' -o -name 'Brewfile' \) \! -name '.gitmodules' | while read -r file; do
	symlink "${file#./}"
done

/usr/bin/find . -mindepth 1 -maxdepth 1 -type dir -name '.*' \! -name '.config' \! -name '.git' | while read -r dir; do
	symlink "${dir#./}"
done

/usr/bin/find .config -mindepth 1 -maxdepth 1 -type dir | while read -r dir; do
	symlink "$dir"
done

#
# Configure system
#

defaults write com.apple.dock "expose-group-apps" -bool "true" && killall Dock
defaults write com.apple.spaces "spans-displays" -bool "true" && killall SystemUIServer
defaults write -g NSAutomaticWindowAnimationsEnabled -bool false

#
# Update submodules, brew, and nvim plugins
#

brew bundle --cleanup --file ./Brewfile
nvim --headless '+Lazy! sync' +qa
