#!/bin/sh
# Public IPv4 in yellow; "no internet" in red on failure.
# Cache for 60s, refresh in background to avoid blocking the status bar.

cache="${TMPDIR:-/tmp}/tmux-ip-status.cache"
ttl=60
now=$(date +%s)

mtime=0
[ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
age=$(( now - mtime ))

if [ "$age" -ge "$ttl" ]; then
  (
    ip=$(curl -fsS -4 --max-time 2 https://api.ipify.org 2>/dev/null)
    if [ -n "$ip" ]; then
      printf '#[fg=colour178]%s' "$ip" > "$cache"
    else
      printf '#[fg=red]no internet' > "$cache"
    fi
  ) >/dev/null 2>&1 &
fi

[ -f "$cache" ] && cat "$cache"
