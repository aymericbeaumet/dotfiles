#!/bin/sh
# Claude/Codex quota usage for tmux status-right.
#
# Claude quotas are token denominators because ccusage can measure usage but
# does not know subscription limits. Override from tmux's environment if needed.
: "${CLAUDE_SESSION_TOKEN_LIMIT:=7123835350}"
: "${CLAUDE_WEEK_TOKEN_LIMIT:=8878727688}"

today=$(date +%Y-%m-%d)
dow=$(date +%w)
week_start=$(date -v-"${dow}"d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
now=$(date +%s)
last_good="${TMPDIR:-/tmp}/tmux-agent-quota-status.last"
last_good_dir=${last_good%/*}

epoch_from_iso_z() {
  iso=${1:-}
  [ -z "$iso" ] || [ "$iso" = "null" ] && return
  iso=$(printf '%s' "$iso" | sed 's/\.[0-9][0-9]*Z$/Z/')
  date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null
}

fmt_hours_until() {
  awk -v target="${1:-}" -v now="$now" '
    BEGIN {
      if (target == "" || target == "null" || target <= 0) {
        printf "?h"
      } else {
        seconds = target - now
        if (seconds < 0) seconds = 0
        printf "%dh", int((seconds + 3599) / 3600)
      }
    }'
}

fmt_days_until() {
  awk -v target="${1:-}" -v now="$now" '
    BEGIN {
      if (target == "" || target == "null" || target <= 0) {
        printf "?d"
      } else {
        seconds = target - now
        if (seconds < 0) seconds = 0
        printf "%dd", int((seconds + 86399) / 86400)
      }
    }'
}

fmt_native_percent() {
  awk -v pct="${1:-}" '
    BEGIN {
      if (pct == "" || pct == "null") {
        printf "?%%"
      } else {
        pct = int((pct + 0) + 0.5)
        if (pct > 100) pct = 100
        if (pct < 0) pct = 0
        printf "%d%%", pct
      }
    }'
}

fmt_percent() {
  awk -v used="${1:-}" -v limit="${2:-}" '
    BEGIN {
      if (used == "" || used == "null" || limit == "" || limit == "null" || limit <= 0) {
        printf "?%%"
      } else {
        pct = int((used / limit * 100) + 0.5)
        if (pct > 100) pct = 100
        if (pct < 0) pct = 0
        printf "%d%%", pct
      }
    }'
}

live_codex_rate_limits() {
  command -v codex >/dev/null 2>&1 || return

  (
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"tmux-status","version":"1"},"capabilities":{"experimentalApi":true}}}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read","params":null}'
    sleep 0.75
  ) |
    codex app-server --stdio 2>/dev/null |
    jq -r '
      select(.id == 2 and .result)
      | (.result.rateLimitsByLimitId.codex // .result.rateLimits)
      | [.primary.usedPercent, .primary.resetsAt, .secondary.usedPercent, .secondary.resetsAt]
      | @tsv
    ' 2>/dev/null |
    tail -n 1
}

render_status() {
  claude_session=
  claude_session_reset=
  claude_week=
  claude_week_reset=
  codex_session_pct=
  codex_session_reset=
  codex_week_pct=
  codex_week_reset=

  if command -v jq >/dev/null 2>&1; then
    codex_limits=$(live_codex_rate_limits)
    if [ -n "$codex_limits" ]; then
      codex_session_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $1}')
      codex_session_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $2}')
      codex_week_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $3}')
      codex_week_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $4}')
    fi
  fi

  if command -v ccusage >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    claude_block=$(ccusage claude blocks --active --json --offline 2>/dev/null |
      jq -r '(.blocks // [] | map(select(.isActive == true)) | last // .[-1] // {} | [.totalTokens, .endTime] | @tsv) // empty' 2>/dev/null)
    if [ -n "$claude_block" ]; then
      claude_session=$(printf '%s\n' "$claude_block" | awk -F '\t' '{print $1}')
      claude_session_reset=$(epoch_from_iso_z "$(printf '%s\n' "$claude_block" | awk -F '\t' '{print $2}')")
    fi
    claude_week=$(ccusage claude weekly --json --since "$week_start" --until "$today" --offline 2>/dev/null |
      jq -r '(.weekly[-1].totalTokens // .totals.totalTokens) // empty' 2>/dev/null)
    claude_week_reset=$(date -v+tue -v5H -v0M -v0S +%s 2>/dev/null)
  fi

  printf '#[fg=colour178]Cld#[fg=colour245] %s↻%s %s↻%s' \
    "$(fmt_percent "$claude_session" "$CLAUDE_SESSION_TOKEN_LIMIT")" \
    "$(fmt_hours_until "$claude_session_reset")" \
    "$(fmt_percent "$claude_week" "$CLAUDE_WEEK_TOKEN_LIMIT")" \
    "$(fmt_days_until "$claude_week_reset")"
  printf '#[fg=colour245] · #[fg=colour178]Cdx#[fg=colour245] %s↻%s %s↻%s' \
    "$(fmt_native_percent "$codex_session_pct")" \
    "$(fmt_hours_until "$codex_session_reset")" \
    "$(fmt_native_percent "$codex_week_pct")" \
    "$(fmt_days_until "$codex_week_reset")"
}

status=$(render_status)
case "$status" in
  *'?'*)
    if [ -f "$last_good" ]; then
      cat "$last_good"
    fi
    ;;
  *)
    printf '%s' "$status"
    tmp="${last_good}.$$"
    mkdir -p "$last_good_dir" 2>/dev/null
    if printf '%s' "$status" >"$tmp"; then
      mv "$tmp" "$last_good"
    else
      rm -f "$tmp"
    fi
    ;;
esac
exit 0
