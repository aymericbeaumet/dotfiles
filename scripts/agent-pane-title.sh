#!/bin/bash
# Update the pane border with agent session info from hook stdin JSON.
# Called by Codex/agy Stop hooks (kind passed as $1). Inside a local tmux, set
# @agent-kind + pane-title on the pane. Over ssh (no local $TMUX_PANE) emit an
# OSC 2 title to the tty so the far-side tmux shows "[ssh:<host>] [<kind>] ..."
# (see .tmux.conf pane-border-format).

set_pane_option() {
  tmux set-option -p -t "$TMUX_PANE" "$@" >/dev/null 2>&1 || true
}

show_pane_value() {
  tmux display-message -p -t "$TMUX_PANE" "$1" 2>/dev/null || true
}

agent_kind() {
  case "${1:-}" in
    claude | codex | agy)
      echo "$1"
      return
      ;;
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

if command -v timeout >/dev/null 2>&1; then
  input=$(timeout 2 cat 2>/dev/null || true)
elif command -v gtimeout >/dev/null 2>&1; then
  input=$(gtimeout 2 cat 2>/dev/null || true)
else
  input=$(cat 2>/dev/null || true)
fi

model=$(echo "${input:-{}}" | jq -r 'if (.model | type) == "object" then (.model.id // .model.name // empty) else (.model // empty) end' 2>/dev/null)
cwd=$(echo "${input:-{}}" | jq -r '.cwd // .workspace_root // .workspace_roots[0] // empty' 2>/dev/null)
name=$(echo "${input:-{}}" | jq -r '.session_name // .title // empty' 2>/dev/null)

if [ -n "${TMUX_PANE:-}" ] && tmux display-message -p -t "$TMUX_PANE" '#{pane_id}' >/dev/null 2>&1; then
  # Local tmux: drive the pane options directly.
  [ -z "$cwd" ] && cwd=$(show_pane_value '#{pane_current_path}')
  dir="${cwd##*/}"
  title="${name:-${dir:-agent}}"
  kind=$(agent_kind "${1:-}")
  [ -n "$kind" ] && set_pane_option @agent-kind "$kind"
  if [ -n "$model" ]; then
    set_pane_option pane-title "${title} | ${model}"
  else
    set_pane_option pane-title "${title}"
  fi
elif [ -w /dev/tty ]; then
  # Over ssh (no local tmux): report via OSC title; kind comes from $1.
  dir="${cwd##*/}"
  title="${name:-${dir:-agent}}"
  kind="${1:-agent}"
  if [ -n "$model" ]; then
    { printf '\033]2;[%s] %s | %s\a' "$kind" "$title" "$model" >/dev/tty; } 2>/dev/null
  else
    { printf '\033]2;[%s] %s\a' "$kind" "$title" >/dev/tty; } 2>/dev/null
  fi
fi

exit 0
