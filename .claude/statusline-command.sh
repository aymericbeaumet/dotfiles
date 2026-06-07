#!/bin/sh
input=$(cat)

add() { [ -n "$parts" ] && parts="$parts  $1" || parts="$1"; }

# Model
model=$(echo "$input" | jq -r '.model.id // empty')
[ -n "$model" ] && add "model:${model}"

# Effort level
effort=$(echo "$input" | jq -r '.effort.level // empty')
if [ "$effort" = "xhigh" ] || [ "$effort" = "max" ]; then
  add "$(printf '\033[1;97meffort:%s\033[0m' "$effort")"
elif [ -n "$effort" ]; then
  add "effort:${effort}"
fi

# Fast mode
thinking=$(echo "$input" | jq -r '.thinking.enabled')
[ "$thinking" = "false" ] && add "$(printf '\033[1;97mfast:on\033[0m')" || add "fast:off"

# Context window usage
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
add "ctx:${ctx}%"

# Set tmux pane title for border display
if [ -n "$TMUX_PANE" ]; then
  tmux set-option -p -t "$TMUX_PANE" @agent-kind claude 2>/dev/null
  cwd=$(echo "$input" | jq -r '.cwd // empty')
  dir="${cwd##*/}"
  name=$(echo "$input" | jq -r '.session_name // empty')
  title="${name:-${dir:-claude}}"
  tmux set-option -p -t "$TMUX_PANE" pane-title "${title} | ctx:${ctx}%" 2>/dev/null
fi

echo "$parts"
