#!/bin/sh
# Toggle Wi-Fi power on the primary Wi-Fi interface.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_wifi.sh: macOS only" >&2
  exit 0
fi

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

CACHE="${TMPDIR:-/tmp}/wifi_device"
device=""
[ -r "$CACHE" ] && device=$(cat "$CACHE")
if [ -z "$device" ]; then
  device=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/ {getline; print $2; exit}')
  [ -n "$device" ] && printf '%s' "$device" >"$CACHE"
fi
[ -n "$device" ] || {
  echo "Wi-Fi interface not found" >&2
  exit 1
}

state=$(networksetup -getairportpower "$device" | awk '{print $NF}')
if [ "$state" = "On" ]; then
  networksetup -setairportpower "$device" off &
  label="OFF"
else
  networksetup -setairportpower "$device" on &
  label="ON"
fi

flash_alert "Wi-Fi $label" &
wait
