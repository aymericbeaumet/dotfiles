#!/bin/sh
# Toggle sleep while still allowing display sleep and lock.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_sleep.sh: macOS only" >&2
  exit 0
fi

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

flash_alert "Sleep..." --duration=3

PIDFILE="${TMPDIR:-/tmp}/sleep-toggle.pid"
OLD_PIDFILE="${TMPDIR:-/tmp}/caffeinate-toggle.pid"
LABEL="com.aymericbeaumet.flash.sleep-toggle"
DOMAIN="gui/$(id -u)"
STATE_DIR="${TMPDIR:-/tmp}/flash"
PLIST="$STATE_DIR/$LABEL.plist"

if [ ! -f "$PIDFILE" ] && [ -f "$OLD_PIDFILE" ]; then
  mv "$OLD_PIDFILE" "$PIDFILE" 2>/dev/null || true
fi

notify() {
  flash_alert "Sleep $1"
}

notify_error() {
  flash_alert "Sleep $1" --duration=4 --style=error
}

legacy_pid() {
  [ -f "$PIDFILE" ] || return 1
  pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  printf '%s\n' "$pid"
}

job_loaded() {
  launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1
}

job_running() {
  launchctl print "$DOMAIN/$LABEL" 2>/dev/null | grep -q "state = running"
}

write_plist() {
  mkdir -p "$STATE_DIR"
  cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/caffeinate</string>
    <string>-i</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/dev/null</string>
  <key>StandardErrorPath</key>
  <string>/dev/null</string>
</dict>
</plist>
EOF
}

stop_legacy() {
  if pid=$(legacy_pid); then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$PIDFILE" "$OLD_PIDFILE"
}

if job_running || legacy_pid >/dev/null; then
  if job_loaded && ! launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    notify_error "ON failed"
    exit 1
  fi
  stop_legacy
  rm -f "$PLIST"
  notify "ON"
else
  stop_legacy
  if job_loaded; then
    launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  fi
  write_plist
  if launchctl bootstrap "$DOMAIN" "$PLIST" >/dev/null 2>&1; then
    sleep 0.2
  else
    notify_error "OFF failed"
    exit 1
  fi
  if job_running; then
    notify "OFF"
  else
    notify_error "OFF failed"
    launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
    rm -f "$PLIST"
    exit 1
  fi
fi
