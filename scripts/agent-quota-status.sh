#!/bin/sh
# Claude/Codex quota usage for tmux status-right.

. "${DOTFILES:-$HOME/.dotfiles}/scripts/lib.sh"

now=$(date +%s)
cache_root="${TMPDIR:-/tmp}/tmux-agent-quota-status"
last_good="$cache_root/rendered-v3.last"
last_good_dir=${last_good%/*}
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

fmt_remaining_percent() {
  awk -v used="${1:-}" '
    BEGIN {
      if (used == "" || used == "null") {
        printf "?%%"
      } else {
        left = 100 - (used + 0)
        if (left > 100) left = 100
        if (left < 0) left = 0
        pct = int(left)
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

write_status_cache() {
  cached_status=${1:-}
  [ -n "$cached_status" ] || return 1

  tmp="${last_good}.$$"
  mkdir -p "$last_good_dir" 2>/dev/null
  if printf '%s' "$cached_status" >"$tmp"; then
    mv "$tmp" "$last_good"
  else
    rm -f "$tmp"
    return 1
  fi
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
    *[!A-Za-z0-9._-]*|'') printf '%s' "claude-code-user" ;;
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

format_period() {
  used_pct=${1:-}
  reset_at=${2:-}
  reset_kind=${3:-}

  [ -n "$used_pct" ] || return
  [ -n "$reset_at" ] || return
  [ "$reset_at" != "null" ] || return

  case "$reset_kind" in
    hours) reset=$(fmt_hours_until "$reset_at") ;;
    days) reset=$(fmt_days_until "$reset_at") ;;
    *) return ;;
  esac

  case "$reset" in
    *'?'*) return ;;
  esac

  pct=$(fmt_remaining_percent "$used_pct")
  case "$pct" in
    *'?'*) return ;;
  esac

  left=${pct%\%}
  segment="${pct}↻$reset"
  if [ "$left" -lt 20 ]; then
    printf '#[fg=colour196]%s#[fg=colour245]' "$segment"
  else
    printf '%s' "$segment"
  fi
}

format_provider() {
  label=${1:-}
  session_pct=${2:-}
  session_reset=${3:-}
  week_pct=${4:-}
  week_reset=${5:-}

  session=$(format_period "$session_pct" "$session_reset" hours)
  week=$(format_period "$week_pct" "$week_reset" days)
  [ -n "$session" ] && [ -n "$week" ] || return

  printf '#[fg=colour178]%s#[fg=colour245]' "$label"
  printf ' %s %s' "$session" "$week"
}

render_status() {
  claude_session_pct=
  claude_session_reset=
  claude_week_pct=
  claude_week_reset=
  codex_session_pct=
  codex_session_reset=
  codex_week_pct=
  codex_week_reset=

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
      codex_week_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $3}')
      codex_week_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $4}')
    fi
  fi

  claude_status=$(format_provider Cld "$claude_session_pct" "$claude_session_reset" "$claude_week_pct" "$claude_week_reset")
  codex_status=$(format_provider Cdx "$codex_session_pct" "$codex_session_reset" "$codex_week_pct" "$codex_week_reset")
  [ -n "$claude_status" ] && [ -n "$codex_status" ] || return

  printf '%s#[fg=colour245] · %s' "$claude_status" "$codex_status"
}

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
