#!/bin/sh
# Dispatch tmux status-bar clicks.
# Active ranges are set in .tmux.conf status-format[0]:
#   - <window-index>

DOTFILES_SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

r="${1:-}"
[ -z "$r" ] && exit 0

case "$r" in
  cal) tmux display-popup -E -w 60 -h 12 "$(dotfiles_dir)/scripts/cal-popup.sh" ;;
  net-prefs) is_darwin && open "x-apple.systempreferences:com.apple.Network-Settings.extension" || true ;;
  bat-prefs) is_darwin && open "x-apple.systempreferences:com.apple.Battery-Settings.extension" || true ;;
  *[!0-9]*) tmux switch-client -t "$r" ;;
  *) tmux select-window -t ":$r" ;;
esac
