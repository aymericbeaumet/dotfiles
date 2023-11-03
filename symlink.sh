#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

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
