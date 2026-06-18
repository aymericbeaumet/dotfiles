#!/bin/sh
# Toggle macOS output mute.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_mute.sh: macOS only" >&2
  exit 0
fi

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

flash_alert "Mute..." --duration=3

if label=$(osascript -e 'if output muted of (get volume settings) then
  set volume without output muted
  return "OFF"
else
  set volume with output muted
  return "ON"
end if'); then
  flash_alert "Mute $label"
else
  flash_alert "Mute failed" --duration=4 --style=error
  exit 1
fi
