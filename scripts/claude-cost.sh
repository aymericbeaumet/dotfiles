#!/bin/sh
# Claude Code cost for the current 6am→6am window (via ccusage).
# Cache for 60s, refresh in background to avoid blocking the status bar.

cache="${TMPDIR:-/tmp}/tmux-claude-cost.cache"
ttl=60
now=$(date +%s)

mtime=0
[ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
age=$(( now - mtime ))

if [ "$age" -ge "$ttl" ]; then
  (
    # ccusage daily groups by midnight; pick the day-bucket whose 6am→6am window
    # we are currently inside: hour<6 → yesterday, else today.
    if [ "$(date +%H)" -lt 6 ]; then
      day=$(date -v-1d +%Y-%m-%d)
    else
      day=$(date +%Y-%m-%d)
    fi

    if command -v ccusage >/dev/null 2>&1; then
      cost=$(ccusage claude daily --json --since "$day" --until "$day" --offline 2>/dev/null \
        | jq -r '.daily[-1].totalCost // 0' 2>/dev/null)
    fi

    if [ -n "${cost:-}" ] && [ "$cost" != "null" ]; then
      printf '#[range=user|budget fg=colour178]$%.2f#[norange]' "$cost" > "$cache"
    else
      printf '#[range=user|budget fg=colour245]$?.??#[norange]' > "$cache"
    fi
  ) >/dev/null 2>&1 &
fi

[ -f "$cache" ] && cat "$cache"
