#!/bin/sh
# Toggle Wi-Fi power on the primary Wi-Fi interface.
set -eu

device=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/ {getline; print $2; exit}')
[ -n "$device" ] || {
  echo "Wi-Fi interface not found" >&2
  exit 1
}

state=$(networksetup -getairportpower "$device" | awk '{print $NF}')
if [ "$state" = "On" ]; then
  networksetup -setairportpower "$device" off
  label="OFF"
else
  networksetup -setairportpower "$device" on
  label="ON"
fi

encoded=$(printf '%s' "Wi-Fi $label" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 || true
