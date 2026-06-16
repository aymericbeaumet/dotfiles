#!/usr/bin/env bash
set -euo pipefail

# Cross-session window picker. Invoked from tmux via display-popup so it does
# not block the tmux server (unlike run-shell + fzf-tmux).

sel=$(tmux list-windows -a -F '#S:#I	[#S] #W (#{pane_current_command})' |
  fzf --reverse --info=hidden --header='Switch window' \
    --with-nth=2.. --delimiter=$'\t') || exit 0

[[ -n "$sel" ]] || exit 0
target=${sel%%$'\t'*}
tmux switch-client -t "$target"
