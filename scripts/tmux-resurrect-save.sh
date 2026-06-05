#!/usr/bin/env bash
set -euo pipefail

original_save_script="${TMUX_RESURRECT_ORIGINAL_SAVE_SCRIPT:-$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh}"
empty_title_panes=()

while IFS='|' read -r pane_id pane_title pane_current_command; do
  if [[ -z "$pane_title" ]]; then
    empty_title_panes+=("$pane_id")
    tmux select-pane -t "$pane_id" -T "${pane_current_command:-pane}"
  fi
done < <(tmux list-panes -a -F '#{pane_id}|#{pane_title}|#{pane_current_command}')

restore_empty_titles() {
  local pane_id

  for pane_id in "${empty_title_panes[@]}"; do
    tmux select-pane -t "$pane_id" -T '' 2>/dev/null || true
  done
}

trap restore_empty_titles EXIT

"$original_save_script" "$@"
