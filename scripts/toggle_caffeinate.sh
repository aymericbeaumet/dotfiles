#!/bin/sh
# Toggle display-sleep prevention (mirrors prior Hammerspoon hs.caffeinate displayIdle).
set -eu

PIDFILE="${TMPDIR:-/tmp}/caffeinate-toggle.pid"

notify() {
  encoded=$(printf '%s' "Caffeinate $1" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
  open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 || true
}

if [ -f "$PIDFILE" ] && pid=$(cat "$PIDFILE" 2>/dev/null) && [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
  kill "$pid" 2>/dev/null || true
  rm -f "$PIDFILE"
  notify "OFF"
else
  rm -f "$PIDFILE"
  nohup caffeinate -d >/dev/null 2>&1 &
  echo $! >"$PIDFILE"
  notify "ON"
fi
