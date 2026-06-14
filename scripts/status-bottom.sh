#!/bin/sh
# Render the bottom status line: ╚════...════╝ spanning the full client width.
# Called from tmux as: #(.dotfiles/scripts/status-bottom.sh #{client_width})
# tmux expands #{client_width} before invoking, and re-runs when it changes.

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

width=${1:-80}
inner=$((width - 2))
[ "$inner" -lt 0 ] && inner=0

fill=$(repeat_char '═' "$inner")
printf '╚%s╝' "$fill"
