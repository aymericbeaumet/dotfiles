#!/bin/sh
# Toggle macOS appearance between Light and Dark.
set -eu

osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode' >/dev/null

state=$(osascript -e 'tell app "System Events" to tell appearance preferences to get dark mode')
[ "$state" = "true" ] && label="Dark" || label="Light"

encoded=$(printf '%s' "Appearance $label" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 || true
