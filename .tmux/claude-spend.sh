#!/bin/sh
# Claude spend since 6am local time (in whole dollars).
# Yellow normally, red if > $100. Cached 5 min, refresh in background.
#
# Trick: ccusage groups entries by date in a given timezone. Picking a
# timezone whose midnight falls at 6am local time gives us a 6am-to-6am
# "day". For local UTC offset +N hours, that timezone is UTC-(6-N), aka
# Etc/GMT+(6-N) (Etc/GMT signs are reversed).

cache="${TMPDIR:-/tmp}/tmux-claude-spend.cache"
ttl=300
now=$(date +%s)

mtime=0
[ -f "$cache" ] && mtime=$(stat -f %m "$cache" 2>/dev/null || echo 0)
age=$(( now - mtime ))

if [ "$age" -ge "$ttl" ]; then
  (
    offset=$(date +%z | awk '{
      sign = substr($0,1,1); hh = substr($0,2,2);
      printf "%d", (sign == "-" ? -1 : 1) * hh
    }')
    shift=$(( 6 - offset ))
    if [ "$shift" -ge 0 ]; then
      tz="Etc/GMT+${shift}"
    else
      tz="Etc/GMT-$(( -shift ))"
    fi
    today=$(TZ="$tz" date +%Y-%m-%d)

    json=$(/opt/homebrew/bin/npx --yes ccusage daily --json -O --timezone "$tz" 2>/dev/null) || exit 0
    daily=$(printf '%s' "$json" | /opt/homebrew/bin/jq -r \
      --arg today "$today" \
      '[.daily[] | select(.date == $today) | .totalCost] | add // 0 | round') || exit 0
    [ -z "$daily" ] && exit 0
    if [ "$daily" -gt 100 ]; then
      printf '#[fg=red]$%s' "$daily" > "$cache"
    else
      printf '#[fg=colour178]$%s' "$daily" > "$cache"
    fi
  ) >/dev/null 2>&1 &
fi

[ -f "$cache" ] && cat "$cache"
