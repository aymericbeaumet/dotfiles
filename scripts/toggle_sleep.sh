#!/bin/sh
# Toggle sleep while still allowing display sleep and lock.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_sleep.sh: macOS only" >&2
  exit 0
fi

. "${DOTFILES:-$HOME/.dotfiles}/scripts/lib.sh"

PIDFILE="${TMPDIR:-/tmp}/sleep-toggle.pid"
OLD_PIDFILE="${TMPDIR:-/tmp}/caffeinate-toggle.pid"

if [ ! -f "$PIDFILE" ] && [ -f "$OLD_PIDFILE" ]; then
  mv "$OLD_PIDFILE" "$PIDFILE" 2>/dev/null || true
fi

notify() {
  flash_alert "Sleep $1"
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
