#!/usr/bin/env bash
set -euo pipefail

original_save_script="${TMUX_RESURRECT_ORIGINAL_SAVE_SCRIPT:-$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh}"
empty_title_panes=()
sanitizer_temp_dir=""
sanitizer_temp_archive=""

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

cleanup() {
  restore_empty_titles
  [[ -z "$sanitizer_temp_dir" ]] || rm -rf "$sanitizer_temp_dir"
  [[ -z "$sanitizer_temp_archive" ]] || rm -f "$sanitizer_temp_archive"
}

sanitize_pane_contents_archive() {
  local resurrect_dir archive file

  resurrect_dir="$(tmux show-option -gqv @resurrect-dir)"
  resurrect_dir="${resurrect_dir:-$HOME/.tmux/resurrect}"
  resurrect_dir="${resurrect_dir/#\$HOME/$HOME}"
  resurrect_dir="${resurrect_dir/#\~/$HOME}"
  archive="$resurrect_dir/pane_contents.tar.gz"
  [[ -f "$archive" ]] || return 0

  sanitizer_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/tmux-resurrect-pane-contents.XXXXXX")"
  sanitizer_temp_archive="${archive}.tmp.$$"
  tar xzf "$archive" -C "$sanitizer_temp_dir"

  while IFS= read -r -d '' file; do
    printf '\033[0m' >> "$file"
  done < <(find "$sanitizer_temp_dir/pane_contents" -type f -print0)

  tar cf - -C "$sanitizer_temp_dir" ./pane_contents | gzip > "$sanitizer_temp_archive"
  mv "$sanitizer_temp_archive" "$archive"
  sanitizer_temp_archive=""
  rm -rf "$sanitizer_temp_dir"
  sanitizer_temp_dir=""
}

trap cleanup EXIT

"$original_save_script" "$@"
sanitize_pane_contents_archive
