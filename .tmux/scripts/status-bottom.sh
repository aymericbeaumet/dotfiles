#!/bin/sh
# Render the bottom status line: ╚════...════╝ spanning the full client width.
# Called from tmux as: #(~/.tmux/scripts/status-bottom.sh #{client_width})
# tmux expands #{client_width} before invoking, and re-runs when it changes.

width=${1:-80}
inner=$((width - 2))
[ "$inner" -lt 0 ] && inner=0

fill=$(printf '═%.0s' $(seq 1 "$inner"))
printf '╚%s╝' "$fill"
