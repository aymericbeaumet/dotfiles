#!/bin/sh
# Toggle macOS output mute.
set -eu

muted=$(osascript -e 'output muted of (get volume settings)')
if [ "$muted" = "true" ]; then
  osascript -e 'set volume without output muted' >/dev/null
  label="OFF"
else
  osascript -e 'set volume with output muted' >/dev/null
  label="ON"
fi

encoded=$(printf '%s' "Mute $label" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 || true
