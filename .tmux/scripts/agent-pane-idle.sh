#!/bin/bash
# Toggle @agent-idle pane option for tmux border status
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

kind=$(agent_kind "${2:-}")
[ -n "$kind" ] && set_pane_option @agent-kind "$kind"

fallback_title() {
  path=$(show_pane_value '#{pane_current_path}')
  title="${path##*/}"
  echo "${title:-agent}"
}

ensure_title() {
  current=$(show_pane_value '#{pane_title}')
  [ -n "$current" ] || set_pane_option pane-title "$(fallback_title)"
}

case "${1:-idle}" in
  idle) set_pane_option @agent-idle 1
        ensure_title ;;
  busy) set_pane_option -u @agent-idle
        ensure_title ;;
  clear) set_pane_option @agent-idle 1
         set_pane_option pane-title "$(fallback_title)" ;;
esac

exit 0
