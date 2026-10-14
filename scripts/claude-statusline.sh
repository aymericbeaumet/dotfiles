#!/usr/bin/env bash
# Claude Code status line.
#
# Claude pipes one JSON object on stdin after each response. This prints a
# one-line summary and, when that object carries a weekly rate limit, records
# it at ${XDG_CACHE_HOME:-$HOME/.cache}/claude/rate-limits.json. The Flash Cld
# label and claude-week read that file. It holds percentages and reset times
# only. CLAUDE_USAGE_NOW pins the clock for tests; otherwise the clock is now.
set -u

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input=$(cat || true)
[ -n "$input" ] || exit 0

now=${CLAUDE_USAGE_NOW:-$(date +%s)}
filter=$(
  cat <<'JQ'
def epoch:
  if type == "number" then
    if . >= 100000000000 then (. / 1000 | floor) else floor end
  elif type == "string" then
    try fromdateiso8601 catch null
  else null end;
def rounded:
  if type == "number" then round else null end;
def signed:
  if . > 0 then "+\(.)" elif . < 0 then "\(.)" else "+0" end;
. as $root
| ($root.model.display_name // "") as $model
| ($root.rate_limits.five_hour.used_percentage | rounded) as $five
| $root.rate_limits.seven_day.used_percentage as $used
| ($used | rounded) as $seven
| ($root.rate_limits.seven_day.resets_at | epoch) as $resets
| ($root.context_window.used_percentage | rounded) as $ctx
| (if ($seven | type) == "number" and ($resets | type) == "number" and $resets > $now then
    (((1 - (($resets - $now) / 604800)) * 100) | if . < 0 then 0 else . end) as $pace
    | ($used - $pace | round | signed) as $delta
    | " (\($delta))"
  else "" end) as $pace_delta
| [
    (if $model != "" then $model else empty end),
    (if ($five | type) == "number" then "5h \($five)%" else empty end),
    (if ($seven | type) == "number" then "7d \($seven)%\($pace_delta)" else "7d —" end),
    (if ($ctx | type) == "number" then "ctx \($ctx)%" else empty end)
  ]
| join(" · ")
JQ
)

if ! line=$(printf '%s' "$input" | jq -r --argjson now "$now" "$filter"); then
  exit 0
fi
printf '%s\n' "$line"

cache_filter=$(
  cat <<'JQ'
select(.rate_limits.seven_day.used_percentage | type == "number")
| {updated_at: $now, rate_limits}
JQ
)
if ! cache_json=$(printf '%s' "$input" | jq -c --argjson now "$now" "$cache_filter"); then
  exit 0
fi
[ -n "$cache_json" ] || exit 0

umask 077
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude
mkdir -p "$cache_dir" || exit 0
tmp=$(mktemp "${cache_dir}/rate-limits.XXXXXX") || exit 0
trap 'rm -f "$tmp"' EXIT
chmod 600 "$tmp" || exit 0
printf '%s\n' "$cache_json" >"$tmp" || exit 0
mv -f "$tmp" "${cache_dir}/rate-limits.json" || exit 0
