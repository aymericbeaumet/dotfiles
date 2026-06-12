#!/bin/sh
# Dispatch tmux status-bar clicks. Range names are set in:
#   - status-format[0]      : session-picker, <window-index>
#   - ip-status.sh          : net-prefs
#   - battery-status.sh     : bat-prefs
#   - .tmux.conf status-right: cal

r="${1:-}"
[ -z "$r" ] && exit 0

case "$r" in
  session-picker)
    tmux list-sessions -F '#{session_name}' \
      | fzf-tmux -p --reverse --header="Switch session" \
      | xargs -r -I{} tmux switch-client -t {}
    ;;
  cal)        tmux display-popup -E -w 60 -h 12 "$HOME/.dotfiles/scripts/cal-popup.sh" ;;
  net-prefs)  open "x-apple.systempreferences:com.apple.Network-Settings.extension" ;;
  bat-prefs)  open "x-apple.systempreferences:com.apple.Battery-Settings.extension" ;;
  *[!0-9]*)   tmux switch-client -t "$r" ;;
  *)          tmux select-window -t ":$r" ;;
esac
