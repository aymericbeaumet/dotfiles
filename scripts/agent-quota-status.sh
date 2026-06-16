#!/bin/sh
# Claude/Codex quota usage for tmux status-right.

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

now=$(date +%s)
cache_root="${TMPDIR:-/tmp}/tmux-agent-quota-status"
last_good="$cache_root/rendered-v4.last"
legacy_last_good="$cache_root/rendered-v3.last"
last_good_dir=${last_good%/*}
claude_status_cache="$cache_root/rendered-claude-v1.last"
codex_status_cache="$cache_root/rendered-codex-v1.last"
claude_usage_cache="$cache_root/claude-usage.tsv"
claude_usage_backoff="$cache_root/claude-usage.next"
refresh_lock="$cache_root/refresh.lock"
: "${AGENT_QUOTA_RENDER_TTL_SECONDS:=30}"
: "${AGENT_QUOTA_REFRESH_LOCK_SECONDS:=30}"
: "${CLAUDE_USAGE_TTL_SECONDS:=120}"
: "${CLAUDE_USAGE_RETRY_SECONDS:=60}"

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

fmt_window_duration() {
  awk -v minutes="${1:-}" -v kind="${2:-}" '
    BEGIN {
      if (minutes == "" || minutes == "null" || minutes <= 0) {
        exit 1
      } else if (kind == "hours") {
        printf "%dh", int((minutes + 59) / 60)
      } else if (kind == "days") {
        printf "%dd", int((minutes + 1439) / 1440)
      } else {
        exit 1
      }
    }'
}

fmt_remaining_percent() {
  awk -v used="${1:-}" '
    BEGIN {
      if (used == "" || used == "null") {
        printf "?%%"
      } else {
        pct = 100 - int(used + 0)
        if (pct > 100) pct = 100
        if (pct < 0) pct = 0
        printf "%d%%", pct
      }
    }'
}

cache_is_fresh() {
  file=${1:-}
  ttl=${2:-0}
  [ -f "$file" ] || return 1
  mtime=$(file_mtime "$file") || return 1
  [ $((now - mtime)) -lt "$ttl" ]
}

cache_path_is_fresh() {
  path=${1:-}
  ttl=${2:-0}
  [ -e "$path" ] || return 1
  mtime=$(file_mtime "$path") || return 1
  [ $((now - mtime)) -lt "$ttl" ]
}

script_path() {
  case "$0" in
    /*) printf '%s' "$0" ;;
    *)
      dir=$(dirname "$0")
      base=$(basename "$0")
      dir=$(cd "$dir" 2>/dev/null && pwd) || return
      printf '%s/%s' "$dir" "$base"
      ;;
  esac
}

write_cache_file() {
  file=${1:-}
  cached_status=${2:-}
  [ -n "$file" ] || return 1
  [ -n "$cached_status" ] || return 1

  tmp="${file}.$$"
  mkdir -p "${file%/*}" 2>/dev/null
  if printf '%s' "$cached_status" >"$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

write_status_cache() {
  write_cache_file "$last_good" "${1:-}"
}

extract_provider_status() {
  label=${1:-}
  file=${2:-}
  [ -n "$label" ] || return
  [ -f "$file" ] || return

  awk -v label="$label" '
    BEGIN {
      RS = "#\\[fg=colour245\\] · "
      ORS = ""
      prefix = "#[fg=colour178]" label "#[fg=colour245]"
    }
    index($0, prefix) == 1 {
      print
      exit
    }
  ' "$file"
}

previous_provider_status() {
  label=${1:-}
  cache=${2:-}
  [ -s "$cache" ] && cat "$cache" && return

  for file in "$last_good" "$legacy_last_good"; do
    status=$(extract_provider_status "$label" "$file")
    [ -n "$status" ] && printf '%s' "$status" && return
  done
}

start_refresh() {
  [ "${AGENT_QUOTA_REFRESH:-}" = 1 ] && return
  mkdir -p "$cache_root" 2>/dev/null

  if [ -d "$refresh_lock" ] && ! cache_path_is_fresh "$refresh_lock" "$AGENT_QUOTA_REFRESH_LOCK_SECONDS"; then
    rmdir "$refresh_lock" 2>/dev/null || true
  fi

  if mkdir "$refresh_lock" 2>/dev/null; then
    path=$(script_path) || {
      rmdir "$refresh_lock" 2>/dev/null || true
      return
    }

    (
      trap 'rmdir "$refresh_lock" 2>/dev/null || true' EXIT INT TERM
      AGENT_QUOTA_REFRESH=1 sh "$path" >/dev/null 2>&1
    ) &
  fi
}

sha256_8() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print substr($1, 1, 8)}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print substr($1, 1, 8)}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r | awk '{print substr($1, 1, 8)}'
  fi
}

claude_config_dir() {
  if [ "${CLAUDE_SECURESTORAGE_CONFIG_DIR+x}" ]; then
    if [ -n "$CLAUDE_SECURESTORAGE_CONFIG_DIR" ]; then
      printf '%s' "$CLAUDE_SECURESTORAGE_CONFIG_DIR"
    else
      printf '%s/.claude' "$HOME"
    fi
  else
    printf '%s' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  fi
}

claude_settings_path() {
  config_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
  if [ -f "$config_dir/.config.json" ]; then
    printf '%s/.config.json' "$config_dir"
  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    printf '%s/.claude.json' "$CLAUDE_CONFIG_DIR"
  else
    printf '%s/.claude.json' "$HOME"
  fi
}

claude_keychain_account() {
  user=${USER:-}
  if [ -z "$user" ] && command -v id >/dev/null 2>&1; then
    user=$(id -un 2>/dev/null)
  fi
  case "$user" in
    *[!A-Za-z0-9._-]* | '') printf '%s' "claude-code-user" ;;
    *) printf '%s' "$user" ;;
  esac
}

claude_keychain_service() {
  suffix=
  [ -n "${CLAUDE_CODE_CUSTOM_OAUTH_URL:-}" ] && suffix="-custom-oauth"
  service="Claude Code${suffix}-credentials"
  hash=

  if [ "${CLAUDE_SECURESTORAGE_CONFIG_DIR+x}" ]; then
    [ -n "$CLAUDE_SECURESTORAGE_CONFIG_DIR" ] && hash=$(printf '%s' "$(claude_config_dir)" | sha256_8)
  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    hash=$(printf '%s' "$(claude_config_dir)" | sha256_8)
  fi

  if [ -n "$hash" ]; then
    printf '%s-%s' "$service" "$hash"
  else
    printf '%s' "$service"
  fi
}

claude_credentials_json() {
  if command -v security >/dev/null 2>&1; then
    account=$(claude_keychain_account)
    service=$(claude_keychain_service)
    security find-generic-password -a "$account" -s "$service" -w 2>/dev/null && return
  fi

  config_dir=$(claude_config_dir)
  for path in "$config_dir/.credentials.json" "$HOME/.claude/.credentials.json"; do
    [ -f "$path" ] && cat "$path" && return
  done
}

claude_oauth_token() {
  if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN"
    return
  fi

  credentials=$(claude_credentials_json)
  [ -n "$credentials" ] || return
  printf '%s' "$credentials" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
}

claude_org_uuid() {
  settings=$(claude_settings_path)
  [ -f "$settings" ] || return
  jq -r '.oauthAccount.organizationUuid // empty' "$settings" 2>/dev/null
}

live_claude_usage() {
  command -v curl >/dev/null 2>&1 || return
  command -v jq >/dev/null 2>&1 || return

  if cache_is_fresh "$claude_usage_cache" "$CLAUDE_USAGE_TTL_SECONDS"; then
    cat "$claude_usage_cache"
    return
  fi

  if [ -f "$claude_usage_backoff" ]; then
    next_retry=$(cat "$claude_usage_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -gt "$now" ]; then
      [ -f "$claude_usage_cache" ] && cat "$claude_usage_cache"
      return
    fi
  fi

  token=$(claude_oauth_token)
  [ -n "$token" ] || return
  org=$(claude_org_uuid)

  case "$(dotfiles_uname)" in
    Darwin) client_platform=macos ;;
    Linux) client_platform=linux ;;
    *) client_platform=unknown ;;
  esac

  usage=$({
    printf 'header = "Authorization: Bearer %s"\n' "$token"
    printf 'header = "Content-Type: application/json"\n'
    printf 'header = "anthropic-version: 2023-06-01"\n'
    printf 'header = "anthropic-beta: oauth-2025-04-20"\n'
    printf 'header = "anthropic-client-platform: %s"\n' "$client_platform"
    [ -n "$org" ] && printf 'header = "x-organization-uuid: %s"\n' "$org"
  } |
    curl -fsS --max-time 5 -K - 'https://api.anthropic.com/api/oauth/usage' 2>/dev/null |
    jq -r '
      [
        (.five_hour.utilization // "null"),
        (.five_hour.resets_at // "null"),
        (.seven_day.utilization // "null"),
        (.seven_day.resets_at // "null")
      ]
      | @tsv
    ' 2>/dev/null)

  if [ -n "$usage" ]; then
    mkdir -p "$cache_root" 2>/dev/null
    tmp="${claude_usage_cache}.$$"
    if printf '%s' "$usage" >"$tmp"; then
      mv "$tmp" "$claude_usage_cache"
      rm -f "$claude_usage_backoff"
    else
      rm -f "$tmp"
    fi
    printf '%s' "$usage"
  else
    mkdir -p "$cache_root" 2>/dev/null
    printf '%s' "$((now + CLAUDE_USAGE_RETRY_SECONDS))" >"$claude_usage_backoff" 2>/dev/null || true
    [ -f "$claude_usage_cache" ] && cat "$claude_usage_cache"
  fi
}

live_codex_rate_limits() {
  command -v codex >/dev/null 2>&1 || return

  (
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"tmux-status","version":"1"},"capabilities":{"experimentalApi":true,"requestAttestation":false}}}'
    printf '%s\n' '{"jsonrpc":"2.0","method":"initialized"}'
    printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read"}'
    sleep 2
  ) |
    codex app-server --stdio 2>/dev/null |
    jq -r '
      select(.id == 2 and .result)
      | (.result.rateLimitsByLimitId.codex // .result.rateLimits)
      | [
          .primary.usedPercent,
          .primary.resetsAt,
          (.primary.windowDurationMins // 300),
          .secondary.usedPercent,
          .secondary.resetsAt,
          (.secondary.windowDurationMins // 10080)
        ]
      | @tsv
    ' 2>/dev/null |
    tail -n 1
}

format_period() {
  used_pct=${1:-}
  reset_at=${2:-}
  reset_kind=${3:-}
  fallback_window_mins=${4:-}

  have_used=1
  [ -n "$used_pct" ] && [ "$used_pct" != "null" ] || have_used=0
  have_reset=1
  [ -n "$reset_at" ] && [ "$reset_at" != "null" ] || have_reset=0
  [ "$have_used" -eq 1 ] || [ "$have_reset" -eq 1 ] || return

  case "$reset_kind" in
    hours)
      if [ "$have_reset" -eq 1 ]; then
        reset=$(fmt_hours_until "$reset_at")
      else
        reset=$(fmt_window_duration "$fallback_window_mins" hours 2>/dev/null || true)
      fi
      ;;
    days)
      if [ "$have_reset" -eq 1 ]; then
        reset=$(fmt_days_until "$reset_at")
      else
        reset=$(fmt_window_duration "$fallback_window_mins" days 2>/dev/null || true)
      fi
      ;;
    *) return ;;
  esac

  if [ "$have_used" -eq 1 ]; then
    pct=$(fmt_remaining_percent "$used_pct")
  else
    pct='?%'
  fi

  if [ -n "${reset:-}" ]; then
    segment="${pct}↻$reset"
  else
    segment=$pct
  fi
  case "$pct" in
    [0-9]*%)
      left=${pct%\%}
      if [ "$left" -lt 20 ]; then
        printf '#[fg=colour196]%s#[fg=colour245]' "$segment"
      else
        printf '%s' "$segment"
      fi
      ;;
    *) printf '%s' "$segment" ;;
  esac
}

unknown_period() {
  case "${1:-}" in
    hours) printf '%s' '?%↻?h' ;;
    days) printf '%s' '?%↻?d' ;;
  esac
}

format_provider() {
  label=${1:-}
  session_pct=${2:-}
  session_reset=${3:-}
  week_pct=${4:-}
  week_reset=${5:-}
  session_window_mins=${6:-}
  week_window_mins=${7:-}

  session=$(format_period "$session_pct" "$session_reset" hours "$session_window_mins")
  week=$(format_period "$week_pct" "$week_reset" days "$week_window_mins")
  [ -n "$session" ] || [ -n "$week" ] || return
  [ -n "$session" ] || session=$(unknown_period hours)
  [ -n "$week" ] || week=$(unknown_period days)

  printf '#[fg=colour178]%s#[fg=colour245]' "$label"
  printf ' %s %s' "$session" "$week"
}

# Same content as `format_provider` minus the leading label + colour
# bracket. Used by the `--claude` / `--codex` flag path so callers
# (Flash's `[statusbar].template`) can supply the label and separators
# themselves and keep one ownership boundary per format concern.
format_provider_unlabelled() {
  session_pct=${1:-}
  session_reset=${2:-}
  week_pct=${3:-}
  week_reset=${4:-}
  session_window_mins=${5:-}
  week_window_mins=${6:-}

  session=$(format_period "$session_pct" "$session_reset" hours "$session_window_mins")
  week=$(format_period "$week_pct" "$week_reset" days "$week_window_mins")
  [ -n "$session" ] || [ -n "$week" ] || return
  [ -n "$session" ] || session=$(unknown_period hours)
  [ -n "$week" ] || week=$(unknown_period days)

  printf '%s %s' "$session" "$week"
}

unknown_provider_unlabelled() {
  printf '%s' '?%↻?h ?%↻?d'
}

unknown_provider() {
  label=${1:-}
  [ -n "$label" ] || return
  printf '#[fg=colour178]%s#[fg=colour245] %s' "$label" "$(unknown_provider_unlabelled)"
}

# Fetch + render Claude usage on its own. Falls back to the last
# rendered cached value when the live fetch produces nothing.
render_claude_unlabelled() {
  session_pct=
  session_reset=
  session_window_mins=300
  week_pct=
  week_reset=
  week_window_mins=10080

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_claude_usage)
    if [ -n "$limits" ]; then
      session_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      session_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')")
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')")
    fi
  fi

  status=$(format_provider_unlabelled "$session_pct" "$session_reset" "$week_pct" "$week_reset" "$session_window_mins" "$week_window_mins")
  cache="$cache_root/rendered-claude-unlabelled-v1.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_provider_unlabelled
  fi
}

render_codex_unlabelled() {
  session_pct=
  session_reset=
  session_window_mins=
  week_pct=
  week_reset=
  week_window_mins=

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_codex_rate_limits)
    if [ -n "$limits" ]; then
      session_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      session_reset=$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')
      session_window_mins=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')
      week_reset=$(printf '%s\n' "$limits" | awk -F '\t' '{print $5}')
      week_window_mins=$(printf '%s\n' "$limits" | awk -F '\t' '{print $6}')
    fi
  fi

  status=$(format_provider_unlabelled "$session_pct" "$session_reset" "$week_pct" "$week_reset" "$session_window_mins" "$week_window_mins")
  cache="$cache_root/rendered-codex-unlabelled-v1.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_provider_unlabelled
  fi
}

render_status() {
  claude_session_pct=
  claude_session_reset=
  claude_session_window_mins=300
  claude_week_pct=
  claude_week_reset=
  claude_week_window_mins=10080
  codex_session_pct=
  codex_session_reset=
  codex_session_window_mins=
  codex_week_pct=
  codex_week_reset=
  codex_week_window_mins=

  if command -v jq >/dev/null 2>&1; then
    claude_limits=$(live_claude_usage)
    if [ -n "$claude_limits" ]; then
      claude_session_pct=$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $1}')
      claude_session_reset=$(epoch_from_iso "$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $2}')")
      claude_week_pct=$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $3}')
      claude_week_reset=$(epoch_from_iso "$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $4}')")
    fi

    codex_limits=$(live_codex_rate_limits)
    if [ -n "$codex_limits" ]; then
      codex_session_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $1}')
      codex_session_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $2}')
      codex_session_window_mins=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $3}')
      codex_week_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $4}')
      codex_week_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $5}')
      codex_week_window_mins=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $6}')
    fi
  fi

  claude_status=$(format_provider Cld "$claude_session_pct" "$claude_session_reset" "$claude_week_pct" "$claude_week_reset" "$claude_session_window_mins" "$claude_week_window_mins")
  codex_status=$(format_provider Cdx "$codex_session_pct" "$codex_session_reset" "$codex_week_pct" "$codex_week_reset" "$codex_session_window_mins" "$codex_week_window_mins")

  if [ -n "$claude_status" ]; then
    write_cache_file "$claude_status_cache" "$claude_status" || true
  else
    claude_status=$(previous_provider_status Cld "$claude_status_cache")
  fi
  [ -n "$claude_status" ] || claude_status=$(unknown_provider Cld)

  if [ -n "$codex_status" ]; then
    write_cache_file "$codex_status_cache" "$codex_status" || true
  else
    codex_status=$(previous_provider_status Cdx "$codex_status_cache")
  fi
  [ -n "$codex_status" ] || codex_status=$(unknown_provider Cdx)

  status=
  if [ -n "$claude_status" ]; then
    status=$claude_status
  fi
  if [ -n "$codex_status" ]; then
    [ -n "$status" ] && status="$status#[fg=colour245] · "
    status="$status$codex_status"
  fi
  [ -n "$status" ] || return

  printf '%s' "$status"
}

case "${1:-}" in
  --claude)
    render_claude_unlabelled
    exit 0
    ;;
  --codex)
    render_codex_unlabelled
    exit 0
    ;;
esac

if [ "${AGENT_QUOTA_REFRESH:-}" != 1 ] && [ -f "$last_good" ]; then
  if ! cache_is_fresh "$last_good" "$AGENT_QUOTA_RENDER_TTL_SECONDS"; then
    start_refresh
  fi
  cat "$last_good"
  exit 0
fi

status=$(render_status)
if [ -n "$status" ]; then
  write_status_cache "$status" || true
  printf '%s' "$status"
elif [ -f "$last_good" ]; then
  cat "$last_good"
fi
exit 0
