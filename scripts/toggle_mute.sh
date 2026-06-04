#!/bin/sh
# Toggle macOS output mute.
set -eu

label=$(osascript -e 'if output muted of (get volume settings) then
  set volume without output muted
  return "OFF"
else
  set volume with output muted
  return "ON"
end if')

encoded=$(printf '%s' "Mute $label" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 &
wait
