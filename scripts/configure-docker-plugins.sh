#!/usr/bin/env bash
set -euo pipefail

script_dir=$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
plugin_dir="${DOCKER_CONFIG:-$HOME/.docker}/cli-plugins"
mkdir -p "$plugin_dir"

for plugin in buildx compose; do
  target="$plugin_dir/docker-$plugin"
  if [[ -e "$target" && ! -L "$target" ]]; then
    printf 'Preserving existing Docker plugin: %s\n' "$target" >&2
    continue
  fi
  ln -sfn "$script_dir/docker-$plugin.sh" "$target"
done
