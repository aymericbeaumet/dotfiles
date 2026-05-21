#!/bin/bash
# Update tmux pane title with agent session info from hook stdin JSON
# Called by Codex/agy Stop hooks to show model/cost/context in pane border
[ -z "$TMUX_PANE" ] && exit 0

input=$(cat)
[ -z "$input" ] && exit 0

model=$(echo "$input" | jq -r '.model // empty' 2>/dev/null)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null)
dir="${cwd##*/}"
title="${dir:-agent}"

if [ -n "$model" ]; then
  tmux set-option -p -t "$TMUX_PANE" pane-title "${title} | ${model}" 2>/dev/null
else
  tmux set-option -p -t "$TMUX_PANE" pane-title "${title}" 2>/dev/null
fi
