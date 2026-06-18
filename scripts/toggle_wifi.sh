#!/bin/sh
# Toggle Wi-Fi power on the primary Wi-Fi interface.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_wifi.sh: macOS only" >&2
  exit 0
fi

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

flash_alert "Wi-Fi..." --duration=3

CACHE="${TMPDIR:-/tmp}/wifi_device"
device=""
[ -r "$CACHE" ] && device=$(cat "$CACHE")
if [ -z "$device" ]; then
  device=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/ {getline; print $2; exit}')
  [ -n "$device" ] && printf '%s' "$device" >"$CACHE"
fi
[ -n "$device" ] || {
  echo "Wi-Fi interface not found" >&2
  flash_alert "Wi-Fi failed" --duration=4 --style=error
  exit 1
}

state=$(networksetup -getairportpower "$device" | awk '{print $NF}')
if [ "$state" = "On" ]; then
  label="OFF"
  if ! networksetup -setairportpower "$device" off; then
    flash_alert "Wi-Fi OFF failed" --duration=4 --style=error
    exit 1
  fi
else
  label="ON"
  if ! networksetup -setairportpower "$device" on; then
    flash_alert "Wi-Fi ON failed" --duration=4 --style=error
    exit 1
  fi
fi

flash_alert "Wi-Fi $label"
