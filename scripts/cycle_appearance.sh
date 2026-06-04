#!/bin/sh
# Cycle macOS appearance: auto -> light -> dark -> auto.
set -eu

auto=$(defaults read -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null || true)
style=$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)

if [ "$auto" = "1" ]; then
  osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false' >/dev/null &
  defaults delete -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null || true
  label="Light"
elif [ "$style" = "Dark" ]; then
  defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true &
  label="Auto"
else
  osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true' >/dev/null &
  label="Dark"
fi

encoded=$(printf '%s' "Appearance $label" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g')
open -g "flash://show_alert?message=$encoded" >/dev/null 2>&1 &
wait
