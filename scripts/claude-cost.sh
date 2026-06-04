#!/bin/sh
# Claude Code cost for the current calendar day (midnight → midnight, local time).
# Cache for 60s, refresh in background to avoid blocking the status bar. The
# cache key includes today's date so the displayed cost resets at midnight even
# if the previous day's cache hasn't expired yet.
#
# Uses `ccusage claude daily` (NOT `ccusage daily`) so the total excludes Codex
# and every other agent ccusage knows about — Codex is on a flat subscription
# while Claude is pay-per-usage, so only Claude belongs in the budget readout.

today=$(date +%Y-%m-%d)
cache="${TMPDIR:-/tmp}/tmux-claude-cost.${today}.cache"
ttl=60
now=$(date +%s)

# Clean up yesterday's (and older) cache files so /tmp doesn't accumulate.
rm -f "${TMPDIR:-/tmp}"/tmux-claude-cost.[0-9]*.cache.old 2>/dev/null
for old in "${TMPDIR:-/tmp}"/tmux-claude-cost.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].cache; do
  [ "$old" = "$cache" ] || rm -f "$old" 2>/dev/null
done

mtime=0
[ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
age=$((now - mtime))

if [ "$age" -ge "$ttl" ]; then
  (
    day="$today"

    if command -v ccusage >/dev/null 2>&1; then
      cost=$(ccusage claude daily --json --since "$day" --until "$day" --offline 2>/dev/null |
        jq -r '.daily[-1].totalCost // 0' 2>/dev/null)
    fi

    if [ -n "${cost:-}" ] && [ "$cost" != "null" ]; then
      printf '#[range=user|budget fg=colour178]$%.2f#[norange]' "$cost" >"$cache"
    else
      printf '#[range=user|budget fg=colour245]$?.??#[norange]' >"$cache"
    fi
  ) >/dev/null 2>&1 &
fi

[ -f "$cache" ] && cat "$cache"
