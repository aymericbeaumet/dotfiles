#!/bin/bash
# Toggle @agent-idle pane option for tmux border status
[ -z "$TMUX_PANE" ] && exit 0
case "${1:-idle}" in
  idle) tmux set-option -p -t "$TMUX_PANE" @agent-idle 1 ;;
  busy) tmux set-option -p -t "$TMUX_PANE" -u @agent-idle 2>/dev/null ;;
  clear) tmux set-option -p -t "$TMUX_PANE" @agent-idle 1
         tmux set-option -p -t "$TMUX_PANE" pane-title "" 2>/dev/null ;;
esac
