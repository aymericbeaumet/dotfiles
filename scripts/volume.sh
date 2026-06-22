#!/bin/sh
# Adjust macOS output volume up or down.
# Usage: volume.sh up|down
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "volume.sh: macOS only" >&2
  exit 0
fi

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

# One notch ~= the hardware volume key step (1/16 of the range).
STEP=6

case "${1:-}" in
  up) delta=$STEP ;;
  down) delta=-$STEP ;;
  *)
    echo "volume.sh: usage: volume.sh up|down" >&2
    exit 1
    ;;
esac

# AppleScript clamps output volume to the 0-100 range. Raising volume also
# unmutes, matching the hardware volume-up key.
if level=$(osascript -e "set delta to $delta" -e '
set cur to output volume of (get volume settings)
set new to cur + delta
if new < 0 then set new to 0
if new > 100 then set new to 100
set volume output volume new
if delta > 0 then set volume without output muted
return new'); then
  flash_alert "Volume $level"
else
  flash_alert "Volume failed" --duration=4 --style=error
  exit 1
fi
