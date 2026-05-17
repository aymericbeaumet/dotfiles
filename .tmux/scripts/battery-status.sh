#!/bin/sh
out=$(pmset -g batt 2>/dev/null)
pct=$(printf '%s\n' "$out" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
[ -n "$pct" ] || { printf '#[fg=red]??'; exit 0; }
on_ac=0
printf '%s\n' "$out" | grep -qE "AC Power|; charging|; charged|; finishing charge" && on_ac=1
if [ "$on_ac" = "1" ] || [ "$pct" -gt 25 ]; then
  printf '#[fg=colour178]%s%%' "$pct"
else
  printf '#[fg=red]%s%%' "$pct"
fi
