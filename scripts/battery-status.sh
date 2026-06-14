#!/bin/sh
DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

if ! is_darwin; then
  exit 0
fi

out=$(pmset -g batt 2>/dev/null)
pct=$(printf '%s\n' "$out" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
[ -n "$pct" ] || { printf '#[range=user|bat-prefs fg=red]??#[norange]'; exit 0; }
on_ac=0
printf '%s\n' "$out" | grep -qE "AC Power|; charging|; charged|; finishing charge" && on_ac=1
if [ "$on_ac" = "1" ] || [ "$pct" -gt 25 ]; then
  printf '#[range=user|bat-prefs fg=colour178]%s%%#[norange]' "$pct"
else
  printf '#[range=user|bat-prefs fg=red]%s%%#[norange]' "$pct"
fi
