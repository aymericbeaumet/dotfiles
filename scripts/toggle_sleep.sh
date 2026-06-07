#!/bin/sh
# Toggle sleep while still allowing display sleep and lock.
set -eu

PIDFILE="${TMPDIR:-/tmp}/sleep-toggle.pid"
OLD_PIDFILE="${TMPDIR:-/tmp}/caffeinate-toggle.pid"

if [ ! -f "$PIDFILE" ] && [ -f "$OLD_PIDFILE" ]; then
  mv "$OLD_PIDFILE" "$PIDFILE" 2>/dev/null || true
fi

notify() {
  encoded=$(printf '%s' "Sleep $1" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
  open -g "flash://alert_show?message=$encoded" >/dev/null 2>&1 || true
}

if [ -f "$PIDFILE" ] && pid=$(cat "$PIDFILE" 2>/dev/null) && [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
  kill "$pid" 2>/dev/null || true
  rm -f "$PIDFILE"
  notify "ON"
else
  rm -f "$PIDFILE"
  nohup caffeinate -ims >/dev/null 2>&1 &
  echo $! >"$PIDFILE"
  notify "OFF"
fi
