#!/bin/bash
# Update tmux pane title with agent session info from hook stdin JSON
# Called by Codex/agy Stop hooks to show model/cost/context in pane border
[ -z "${TMUX_PANE:-}" ] && exit 0

tmux display-message -p -t "$TMUX_PANE" '#{pane_id}' >/dev/null 2>&1 || exit 0

set_pane_option() {
  tmux set-option -p -t "$TMUX_PANE" "$@" >/dev/null 2>&1 || true
}

show_pane_value() {
  tmux display-message -p -t "$TMUX_PANE" "$1" 2>/dev/null || true
}

agent_kind() {
  case "${1:-}" in
    claude|codex|agy) echo "$1"; return ;;
  esac

  existing=$(show_pane_value '#{@agent-kind}')
  cmd=$(show_pane_value '#{pane_current_command}')
  case "$cmd" in
    claude*) echo claude ;;
    codex*) echo codex ;;
    agy*) echo agy ;;
    *) echo "$existing" ;;
  esac
}

kind=$(agent_kind "${1:-}")
[ -n "$kind" ] && set_pane_option @agent-kind "$kind"

if command -v timeout >/dev/null 2>&1; then
  input=$(timeout 2 cat 2>/dev/null || true)
elif command -v gtimeout >/dev/null 2>&1; then
  input=$(gtimeout 2 cat 2>/dev/null || true)
else
  input=$(cat 2>/dev/null || true)
fi

model=$(echo "${input:-{}}" | jq -r 'if (.model | type) == "object" then (.model.id // .model.name // empty) else (.model // empty) end' 2>/dev/null)
cwd=$(echo "${input:-{}}" | jq -r '.cwd // .workspace_root // .workspace_roots[0] // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd=$(show_pane_value '#{pane_current_path}')
dir="${cwd##*/}"
name=$(echo "${input:-{}}" | jq -r '.session_name // .title // empty' 2>/dev/null)
title="${name:-${dir:-agent}}"

if [ -n "$model" ]; then
  set_pane_option pane-title "${title} | ${model}"
else
  set_pane_option pane-title "${title}"
fi

exit 0
