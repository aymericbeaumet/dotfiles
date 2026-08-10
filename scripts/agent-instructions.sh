#!/usr/bin/env bash

set -euo pipefail

payload=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
[[ -n "$cwd" && -d "$cwd" ]] || exit 0
cwd=$(CDPATH='' cd "$cwd" && pwd -P)

instruction_files=()

append_instruction_file() {
  local candidate="$1"
  local existing

  [[ -f "$candidate" ]] || return 0
  for existing in "${instruction_files[@]-}"; do
    [[ "$existing" == "$candidate" ]] && return 0
  done
  instruction_files+=("$candidate")
}

append_instruction_file "$HOME/.agents/AGENTS.md"

project_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
if [[ -n "$project_root" && -d "$project_root" ]]; then
  project_root=$(CDPATH='' cd "$project_root" && pwd -P)

  if [[ "$cwd" == "$project_root" || "$cwd" == "$project_root/"* ]]; then
    current_dir="$project_root"
    while :; do
      if [[ -f "$current_dir/AGENTS.override.md" ]]; then
        append_instruction_file "$current_dir/AGENTS.override.md"
      else
        append_instruction_file "$current_dir/AGENTS.md"
      fi

      [[ "$current_dir" == "$cwd" ]] && break
      relative_path=${cwd#"$current_dir"/}
      next_segment=${relative_path%%/*}
      [[ -n "$next_segment" && "$next_segment" != "$relative_path" ]] || {
        [[ -n "$next_segment" ]] && current_dir="$current_dir/$next_segment"
        [[ "$current_dir" == "$cwd" ]] && continue
        break
      }
      current_dir="$current_dir/$next_segment"
    done
  fi
else
  if [[ -f "$cwd/AGENTS.override.md" ]]; then
    append_instruction_file "$cwd/AGENTS.override.md"
  else
    append_instruction_file "$cwd/AGENTS.md"
  fi
fi

((${#instruction_files[@]} > 0)) || exit 0

printf 'Applicable standard AGENTS.md guidance follows, ordered from broad to specific.\n'
for instruction_file in "${instruction_files[@]}"; do
  printf '\n--- %s ---\n' "$instruction_file"
  cat "$instruction_file"
done
