#!/usr/bin/env bash

set -e
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

function readlink {
  if command -v greadlink &> /dev/null ; then
    command greadlink "$@"
  else
    command readlink "$@"
  fi
}

function __bootstrap {
  git submodule update --init --recursive
  brew bundle cleanup --force
  brew bundle check || brew bundle
  n latest
  yarn global upgrade np
}

# Symlink the dotfiles to the $HOME directory
function __symlink {
  from_directories=(
    "src"
  )
  for from_directory in "${from_directories[@]}" ; do
    resolved_from_directory="$(readlink -f "$(pwd)/$from_directory")"
    find "$resolved_from_directory" -type file -o -type link | while read -r from ; do
      to="$HOME/${from##"$resolved_from_directory/"}"
      to_directory="$(dirname "$to")"
      rm -rf "$to"
      mkdir -p "$to_directory"
      ln -svf "$from" "$to"
    done
  done
}

for command in "$@" ; do
  if [[ "$(type "__$command" 2>/dev/null)" == *function* ]] ; then
    printf '\e[94m%s...\e[0m\n' "$command"
    "__$command"
    printf '\e[92mok\e[0m\n'
  else
    printf '\e[91m-> skipping unknown command "%s"\e[0m\n' "$command" >&2
  fi
done
