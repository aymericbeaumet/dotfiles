#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tool=github:fcsonline/tmux-thumbs
mise -C "$repo_root" install --yes "$tool"
install_dir=$(mise -C "$repo_root" where "$tool")

# The upstream driver looks for <dir>/target/release/thumbs. Keep that layout
# outside mise's install so upgrades cannot strand a copied executable.
runtime_dir="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-thumbs"
mkdir -p "$runtime_dir/target/release"
ln -sf "$install_dir/thumbs" "$runtime_dir/target/release/thumbs"

args=(--dir "$runtime_dir")
for option in command upcase-command multi-command; do
  value=$(tmux show-option -gqv "@thumbs-$option")
  [[ -z "$value" ]] || args+=("--$option=$value")
done
[[ $(tmux show-option -gqv @thumbs-osc52) != 1 ]] || args+=(--osc52)

exec "$install_dir/tmux-thumbs" "${args[@]}"
