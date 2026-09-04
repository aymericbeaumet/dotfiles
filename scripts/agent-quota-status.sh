#!/bin/sh
# Claude, Fable, Codex, and Grok quota usage for status bars.

DOTFILES_SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

# GUI apps launched by macOS inherit launchd's minimal PATH, so Flash cannot
# otherwise find the mise-managed codex/jq binaries used by this helper.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

now=${AGENT_QUOTA_TEST_NOW:-$(date +%s)}
cache_root="${TMPDIR:-/tmp}/tmux-agent-quota-status"
last_good="$cache_root/rendered-v9.last"
legacy_last_good="$cache_root/rendered-v8.last"
claude_status_cache="$cache_root/rendered-claude-v5.last"
fable_status_cache="$cache_root/rendered-fable-v4.last"
codex_status_cache="$cache_root/rendered-codex-v5.last"
grok_status_cache="$cache_root/rendered-grok-v4.last"
claude_usage_cache="$cache_root/claude-usage-v4.tsv"
claude_usage_backoff="$cache_root/claude-usage-v4.next"
claude_usage_lock="$cache_root/claude-usage-v4.lock"
claude_oauth_backoff="$cache_root/claude-oauth-refresh-v1.next"
legacy_claude_usage_cache="$cache_root/claude-usage-v2.tsv"
codex_usage_cache="$cache_root/codex-usage-v1.tsv"
codex_usage_lock="$cache_root/codex-usage-v1.lock"
grok_usage_cache="$cache_root/grok-usage-v1.tsv"
grok_usage_backoff="$cache_root/grok-usage-v1.next"
grok_usage_lock="$cache_root/grok-usage-v1.lock"
grok_oauth_backoff="$cache_root/grok-oauth-refresh-v1.next"
refresh_lock="$cache_root/refresh.lock"
: "${AGENT_QUOTA_RENDER_TTL_SECONDS:=30}"
: "${AGENT_QUOTA_REFRESH_LOCK_SECONDS:=30}"
: "${AGENT_QUOTA_USAGE_LOCK_SECONDS:=30}"
: "${AGENT_QUOTA_OAUTH_RETRY_SECONDS:=300}"
: "${CLAUDE_USAGE_TTL_SECONDS:=600}"
: "${CLAUDE_USAGE_RETRY_SECONDS:=300}"
: "${CODEX_USAGE_TTL_SECONDS:=120}"
: "${GROK_USAGE_TTL_SECONDS:=120}"
: "${GROK_USAGE_RETRY_SECONDS:=60}"

fmt_days_until() {
  awk -v target="${1:-}" -v now="$now" '
    BEGIN {
      if (target == "" || target == "null" || target <= 0) {
        printf "?d"
      } else {
        seconds = target - now
        if (seconds < 0) seconds = 0
        hours = int(seconds / 3600)
        if (hours < 1) {
          printf "%dmin", int(seconds / 60)
        } else if (hours < 24) {
          printf "%dh", hours
        } else {
          printf "%dd", int(hours / 24)
        }
      }
    }'
}

fmt_window_duration() {
  awk -v minutes="${1:-}" '
    BEGIN {
      if (minutes == "" || minutes == "null" || minutes <= 0) {
        exit 1
      }
      printf "%dd", int((minutes + 1439) / 1440)
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

session_window_exhausted() {
  awk -v used="${1:-}" '
    BEGIN {
      if (used == "" || used == "null") exit 1
      if (100 - int(used + 0) <= 0) exit 0
      exit 1
    }'
}

weekly_usage_ahead_of_pace() {
  awk -v used="${1:-}" -v reset_at="${2:-}" -v window_mins="${3:-}" -v now="$now" '
    BEGIN {
      if (used == "" || used == "null" ||
          reset_at == "" || reset_at == "null" ||
          window_mins == "" || window_mins == "null" ||
          window_mins != 10080) {
        exit 1
      }

      duration = window_mins * 60
      remaining = reset_at - now
      if (remaining < 0 || remaining > duration) exit 1

      elapsed = duration - remaining
      # Include the current 24-hour quota day in the available pace budget.
      allowed_days = int(elapsed / 86400) + 1
      if (allowed_days > 7) allowed_days = 7
      if ((used + 0) * 7 > allowed_days * 100) exit 0
      exit 1
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

acquire_usage_lock() {
  lock=${1:-}
  [ -n "$lock" ] || return 1
  mkdir -p "${lock%/*}" 2>/dev/null || return 1

  if [ -d "$lock" ] && ! cache_path_is_fresh "$lock" "$AGENT_QUOTA_USAGE_LOCK_SECONDS"; then
    rmdir "$lock" 2>/dev/null || true
  fi
  mkdir "$lock" 2>/dev/null
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

claude_oauth_token_needs_refresh() {
  [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] || return 1
  credentials=$(claude_credentials_json)
  [ -n "$credentials" ] || return 1
  expires=$(printf '%s' "$credentials" | jq -r '.claudeAiOauth.expiresAt // empty' 2>/dev/null)
  case "$expires" in
    '' | *[!0-9]*) return 0 ;;
  esac
  [ "$expires" -le "$(((now + 120) * 1000))" ]
}

store_claude_credentials() {
  credentials_file=${1:-}
  [ -s "$credentials_file" ] || return 1

  if command -v security >/dev/null 2>&1; then
    account=$(claude_keychain_account)
    service=$(claude_keychain_service)
    if security find-generic-password -a "$account" -s "$service" >/dev/null 2>&1; then
      security add-generic-password -U -a "$account" -s "$service" -w \
        <"$credentials_file" >/dev/null 2>&1
      return
    fi
  fi

  config_dir=$(claude_config_dir)
  target=
  for path in "$config_dir/.credentials.json" "$HOME/.claude/.credentials.json"; do
    if [ -f "$path" ]; then
      target=$path
      break
    fi
  done
  [ -n "$target" ] || target="$config_dir/.credentials.json"
  mkdir -p "${target%/*}" 2>/dev/null || return
  mv "$credentials_file" "$target"
}

refresh_claude_oauth_token() {
  credentials=$(claude_credentials_json)
  [ -n "$credentials" ] || return
  refresh=$(printf '%s' "$credentials" | jq -r '.claudeAiOauth.refreshToken // empty' 2>/dev/null)
  [ -n "$refresh" ] || return

  if [ "${AGENT_QUOTA_TEST_CLAUDE_REFRESH_JSON+x}" ]; then
    response=$AGENT_QUOTA_TEST_CLAUDE_REFRESH_JSON
  else
    response=$(printf '%s' "$refresh" |
      jq -Rs '{
        grant_type: "refresh_token",
        refresh_token: .,
        client_id: "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
      }' |
      curl -fsS --max-time 5 \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'anthropic-beta: oauth-2025-04-20' \
        -H 'User-Agent: anthropic-sdk-typescript/0.94.0 userOAuthProvider' \
        --data-binary @- \
        'https://platform.claude.com/v1/oauth/token' 2>/dev/null)
  fi

  printf '%s' "$response" | jq -e '
    (.access_token | type == "string" and length > 0)
    and ((.refresh_token // "") | type == "string")
  ' >/dev/null 2>&1 || return

  expires_in=$(printf '%s' "$response" | jq -r '(.expires_in | tonumber?) // 3600' 2>/dev/null)
  case "$expires_in" in
    '' | *[!0-9]*) expires_in=3600 ;;
  esac
  expires=$(((now + expires_in) * 1000))

  mkdir -p "$cache_root" 2>/dev/null
  umask 077
  credentials_file="$cache_root/claude-credentials.$$"
  token_file="$cache_root/claude-oauth-refresh.$$"
  if ! printf '%s' "$credentials" >"$credentials_file" || ! printf '%s' "$response" >"$token_file"; then
    rm -f "$credentials_file" "$token_file"
    return
  fi
  updated_file="$cache_root/claude-credentials-updated.$$"
  if ! jq -c --slurpfile token "$token_file" --argjson expires "$expires" --argjson now_ms "$((now * 1000))" '
    .claudeAiOauth.accessToken = $token[0].access_token
    | .claudeAiOauth.refreshToken = (
        if (($token[0].refresh_token // "") | length) > 0
        then $token[0].refresh_token
        else .claudeAiOauth.refreshToken
        end
      )
    | .claudeAiOauth.expiresAt = $expires
    | ($token[0].refresh_token_expires_in | tonumber?) as $refresh_expires_in
    | if $refresh_expires_in != null
      then .claudeAiOauth.refreshTokenExpiresAt = ($now_ms + ($refresh_expires_in * 1000))
      else .
      end
  ' "$credentials_file" >"$updated_file"; then
    rm -f "$credentials_file" "$token_file" "$updated_file"
    return
  fi

  rm -f "$credentials_file" "$token_file"
  if store_claude_credentials "$updated_file"; then
    rm -f "$updated_file"
    claude_oauth_token
    return
  fi
  rm -f "$updated_file"
}

claude_org_uuid() {
  settings=$(claude_settings_path)
  [ -f "$settings" ] || return
  jq -r '.oauthAccount.organizationUuid // empty' "$settings" 2>/dev/null
}

# Weekly Claude + Fable columns from the previous 6-column usage TSV, plus
# the session utilization used only for unavailable coloring. Old data has
# no session reset timestamp, so the final field is explicitly unknown.
claude_usage_from_legacy() {
  [ -f "$legacy_claude_usage_cache" ] || return
  awk -F '\t' 'NF >= 6 { printf "%s\t%s\t%s\t%s\t%s\tnull", $3, $4, $5, $6, $1 }' "$legacy_claude_usage_cache"
}

cached_claude_usage() {
  [ -f "$claude_usage_cache" ] && cat "$claude_usage_cache" && return
  claude_usage_from_legacy
}

live_claude_usage() {
  if [ "${AGENT_QUOTA_TEST_CLAUDE_TSV+x}" ]; then
    printf '%s' "$AGENT_QUOTA_TEST_CLAUDE_TSV"
    return
  fi

  command -v curl >/dev/null 2>&1 || return
  command -v jq >/dev/null 2>&1 || return

  if cache_is_fresh "$claude_usage_cache" "$CLAUDE_USAGE_TTL_SECONDS"; then
    cat "$claude_usage_cache"
    return
  fi

  # Flash renders provider segments independently. Serialize the shared
  # Claude/Fable request so a cold cache does not send two simultaneous calls
  # to Anthropic's aggressively rate-limited usage endpoint.
  if ! acquire_usage_lock "$claude_usage_lock"; then
    cached_claude_usage
    return
  fi

  if cache_is_fresh "$claude_usage_cache" "$CLAUDE_USAGE_TTL_SECONDS"; then
    cat "$claude_usage_cache"
    rmdir "$claude_usage_lock" 2>/dev/null || true
    return
  fi

  token=
  if claude_oauth_token_needs_refresh; then
    next_retry=$(cat "$claude_oauth_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -le "$now" ]; then
      token=$(refresh_claude_oauth_token)
      if [ -n "$token" ]; then
        rm -f "$claude_oauth_backoff"
      else
        printf '%s' "$((now + AGENT_QUOTA_OAUTH_RETRY_SECONDS))" >"$claude_oauth_backoff" 2>/dev/null || true
        printf '%s\n' 'Claude OAuth refresh failed; run: claude auth login --claudeai' >&2
      fi
    fi
  else
    token=$(claude_oauth_token)
  fi
  if [ -z "$token" ]; then
    cached_claude_usage
    rmdir "$claude_usage_lock" 2>/dev/null || true
    return
  fi
  org=$(claude_org_uuid)

  if [ -f "$claude_usage_backoff" ]; then
    next_retry=$(cat "$claude_usage_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -gt "$now" ]; then
      cached_claude_usage
      rmdir "$claude_usage_lock" 2>/dev/null || true
      return
    fi
  fi

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
    printf 'header = "User-Agent: claude-code/quota-status"\n'
    [ -n "$org" ] && printf 'header = "x-organization-uuid: %s"\n' "$org"
  } |
    curl -fsS --max-time 5 -K - 'https://api.anthropic.com/api/oauth/usage' 2>/dev/null |
    jq -r '
      ([
        (.limits // [])[]
        | select(
            .kind == "weekly_scoped"
            and ((.scope.model.display_name // "") | ascii_downcase) == "fable"
          )
      ] | first) as $fable
      |
      [
        (.seven_day.utilization // "null"),
        (.seven_day.resets_at // "null"),
        ($fable.percent // "null"),
        ($fable.resets_at // "null"),
        (.five_hour.utilization // "null"),
        (.five_hour.resets_at // "null")
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
    cached_claude_usage
  fi
  rmdir "$claude_usage_lock" 2>/dev/null || true
}

live_codex_rate_limits() {
  if [ "${AGENT_QUOTA_TEST_CODEX_TSV+x}" ]; then
    printf '%s' "$AGENT_QUOTA_TEST_CODEX_TSV"
    return
  fi

  command -v codex >/dev/null 2>&1 || return

  if cache_is_fresh "$codex_usage_cache" "$CODEX_USAGE_TTL_SECONDS"; then
    cat "$codex_usage_cache"
    return
  fi

  if ! acquire_usage_lock "$codex_usage_lock"; then
    [ -f "$codex_usage_cache" ] && cat "$codex_usage_cache"
    return
  fi

  if cache_is_fresh "$codex_usage_cache" "$CODEX_USAGE_TTL_SECONDS"; then
    cat "$codex_usage_cache"
    rmdir "$codex_usage_lock" 2>/dev/null || true
    return
  fi

  usage=$(
    (
      printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"clientInfo":{"name":"tmux-status","version":"1"},"capabilities":{"experimentalApi":true,"requestAttestation":false}}}'
      printf '%s\n' '{"jsonrpc":"2.0","method":"initialized"}'
      printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"account/rateLimits/read"}'
      sleep 2
    ) |
      codex app-server --stdio 2>/dev/null |
      jq -r '
      # Codex reports rate-limit windows under .primary/.secondary, but which
      # slot holds the weekly window is not stable. Classify by duration:
      # keep only windows of at least one day.
      select(.id == 2 and .result)
      | (.result.rateLimitsByLimitId.codex // .result.rateLimits) as $r
      | ([$r.primary, $r.secondary] | map(select(. != null))) as $wins
      | ($wins | map(select((.windowDurationMins // 0) >= 1440)) | first) as $week
      | ($wins | map(select((.windowDurationMins // 0) > 0 and (.windowDurationMins // 0) < 1440)) | first) as $session
      | [
          ($week.usedPercent // "null"),
          ($week.resetsAt // "null"),
          ($week.windowDurationMins // "null"),
          ($session.usedPercent // "null"),
          ($session.resetsAt // "null"),
          ($session.windowDurationMins // "null")
        ]
      | @tsv
    ' 2>/dev/null |
      tail -n 1
  )

  if [ -n "$usage" ]; then
    write_cache_file "$codex_usage_cache" "$usage" || true
    printf '%s' "$usage"
  elif [ -f "$codex_usage_cache" ]; then
    cat "$codex_usage_cache"
  fi
  rmdir "$codex_usage_lock" 2>/dev/null || true
}

opencode_auth_path() {
  if [ -n "${AGENT_QUOTA_TEST_XAI_AUTH_PATH:-}" ]; then
    printf '%s' "$AGENT_QUOTA_TEST_XAI_AUTH_PATH"
  else
    printf '%s/opencode/auth.json' "${XDG_DATA_HOME:-$HOME/.local/share}"
  fi
}

xai_oauth_token() {
  auth=$(opencode_auth_path)
  [ -f "$auth" ] || return
  jq -r '.xai | select(.type == "oauth") | .access // empty' "$auth" 2>/dev/null
}

xai_oauth_token_needs_refresh() {
  auth=$(opencode_auth_path)
  [ -f "$auth" ] || return 1
  expires=$(jq -r '.xai | select(.type == "oauth") | .expires // empty' "$auth" 2>/dev/null)
  case "$expires" in
    '' | *[!0-9]*) return 0 ;;
  esac
  [ "$expires" -le "$(((now + 120) * 1000))" ]
}

refresh_xai_oauth_token() {
  auth=$(opencode_auth_path)
  [ -f "$auth" ] || return
  refresh=$(jq -r '.xai | select(.type == "oauth") | .refresh // empty' "$auth" 2>/dev/null)
  [ -n "$refresh" ] || return

  if [ "${AGENT_QUOTA_TEST_XAI_REFRESH_JSON+x}" ]; then
    response=$AGENT_QUOTA_TEST_XAI_REFRESH_JSON
  else
    response=$(printf 'grant_type=refresh_token&refresh_token=%s&client_id=b1a00492-073a-47ea-816f-4c329264a828' \
      "$(url_encode "$refresh")" |
      curl -fsS --max-time 5 \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H 'User-Agent: opencode/quota-status' \
        --data-binary @- \
        'https://auth.x.ai/oauth2/token' 2>/dev/null)
  fi

  printf '%s' "$response" | jq -e '
    (.access_token | type == "string" and length > 0)
    and ((.refresh_token // "") | type == "string")
  ' >/dev/null 2>&1 || return

  expires_in=$(printf '%s' "$response" | jq -r '(.expires_in | tonumber?) // 3600' 2>/dev/null)
  case "$expires_in" in
    '' | *[!0-9]*) expires_in=3600 ;;
  esac
  expires=$(((now + expires_in) * 1000))

  mkdir -p "$cache_root" 2>/dev/null
  umask 077
  token_file="$cache_root/xai-oauth-refresh.$$"
  tmp_auth="${auth}.quota.$$"
  if ! printf '%s' "$response" >"$token_file"; then
    return
  fi
  if jq --slurpfile token "$token_file" --argjson expires "$expires" '
    .xai.access = $token[0].access_token
    | .xai.refresh = (
        if (($token[0].refresh_token // "") | length) > 0
        then $token[0].refresh_token
        else .xai.refresh
        end
      )
    | .xai.expires = $expires
  ' "$auth" >"$tmp_auth" && mv "$tmp_auth" "$auth"; then
    rm -f "$token_file"
    xai_oauth_token
    return
  fi

  rm -f "$token_file" "$tmp_auth"
}

parse_grok_usage() {
  jq -r '
    (.config.currentPeriod // {}) as $period
    | select($period.type == "USAGE_PERIOD_TYPE_WEEKLY")
    | ([
        (.config.productUsage // [])[]
        | select(.product == "GrokBuild")
      ] | first) as $grok
    | [
        # xAI omits productUsage for a valid week with no usage yet.
        ($grok.usagePercent // 0),
        ($period.end // .config.billingPeriodEnd // "null"),
        10080
      ]
    | @tsv
  ' 2>/dev/null
}

live_grok_usage() {
  if [ "${AGENT_QUOTA_TEST_GROK_TSV+x}" ]; then
    printf '%s' "$AGENT_QUOTA_TEST_GROK_TSV"
    return
  fi
  if [ "${AGENT_QUOTA_TEST_GROK_JSON+x}" ]; then
    printf '%s' "$AGENT_QUOTA_TEST_GROK_JSON" | parse_grok_usage
    return
  fi

  command -v curl >/dev/null 2>&1 || return
  command -v jq >/dev/null 2>&1 || return

  if cache_is_fresh "$grok_usage_cache" "$GROK_USAGE_TTL_SECONDS"; then
    cat "$grok_usage_cache"
    return
  fi

  if ! acquire_usage_lock "$grok_usage_lock"; then
    [ -f "$grok_usage_cache" ] && cat "$grok_usage_cache"
    return
  fi

  if cache_is_fresh "$grok_usage_cache" "$GROK_USAGE_TTL_SECONDS"; then
    cat "$grok_usage_cache"
    rmdir "$grok_usage_lock" 2>/dev/null || true
    return
  fi

  token=
  if xai_oauth_token_needs_refresh; then
    next_retry=$(cat "$grok_oauth_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -le "$now" ]; then
      token=$(refresh_xai_oauth_token)
      if [ -n "$token" ]; then
        rm -f "$grok_oauth_backoff"
      else
        printf '%s' "$((now + AGENT_QUOTA_OAUTH_RETRY_SECONDS))" >"$grok_oauth_backoff" 2>/dev/null || true
        printf '%s\n' 'xAI OAuth refresh failed; reconnect xAI in OpenCode.' >&2
      fi
    fi
  else
    token=$(xai_oauth_token)
  fi
  if [ -z "$token" ]; then
    [ -f "$grok_usage_cache" ] && cat "$grok_usage_cache"
    rmdir "$grok_usage_lock" 2>/dev/null || true
    return
  fi

  if [ -f "$grok_usage_backoff" ]; then
    next_retry=$(cat "$grok_usage_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -gt "$now" ]; then
      [ -f "$grok_usage_cache" ] && cat "$grok_usage_cache"
      rmdir "$grok_usage_lock" 2>/dev/null || true
      return
    fi
  fi

  usage=$({
    printf 'header = "Authorization: Bearer %s"\n' "$token"
    printf 'header = "Accept: application/json"\n'
    printf 'header = "x-grok-client-identifier: grok-shell"\n'
    printf 'header = "x-grok-client-version: 1.0.5"\n'
    printf 'header = "X-XAI-Token-Auth: xai-grok-cli"\n'
  } |
    curl -fsS --max-time 5 -K - 'https://cli-chat-proxy.grok.com/v1/billing?format=credits' 2>/dev/null |
    parse_grok_usage)

  if [ -n "$usage" ]; then
    mkdir -p "$cache_root" 2>/dev/null
    tmp="${grok_usage_cache}.$$"
    if printf '%s' "$usage" >"$tmp"; then
      mv "$tmp" "$grok_usage_cache"
      rm -f "$grok_usage_backoff"
    else
      rm -f "$tmp"
    fi
    printf '%s' "$usage"
  else
    mkdir -p "$cache_root" 2>/dev/null
    printf '%s' "$((now + GROK_USAGE_RETRY_SECONDS))" >"$grok_usage_backoff" 2>/dev/null || true
    [ -f "$grok_usage_cache" ] && cat "$grok_usage_cache"
  fi
  rmdir "$grok_usage_lock" 2>/dev/null || true
}

format_period() {
  used_pct=${1:-}
  reset_at=${2:-}
  fallback_window_mins=${3:-}
  session_used_pct=${4:-}

  have_used=1
  [ -n "$used_pct" ] && [ "$used_pct" != "null" ] || have_used=0
  have_reset=1
  [ -n "$reset_at" ] && [ "$reset_at" != "null" ] || have_reset=0
  [ "$have_used" -eq 1 ] || [ "$have_reset" -eq 1 ] || return

  if [ "$have_reset" -eq 1 ]; then
    reset=$(fmt_days_until "$reset_at")
  else
    reset=$(fmt_window_duration "$fallback_window_mins" 2>/dev/null || true)
  fi

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
      if [ "$left" -lt 20 ] || session_window_exhausted "$session_used_pct"; then
        printf '#[fg=colour196]%s#[fg=colour245]' "$segment"
      elif weekly_usage_ahead_of_pace "$used_pct" "$reset_at" "$fallback_window_mins"; then
        printf '#[fg=#D08770]%s#[fg=colour245]' "$segment"
      else
        printf '%s' "$segment"
      fi
      ;;
    *) printf '%s' "$segment" ;;
  esac
}

format_provider() {
  label=${1:-}
  week_pct=${2:-}
  week_reset=${3:-}
  week_window_mins=${4:-}
  session_used_pct=${5:-}

  week=$(format_period "$week_pct" "$week_reset" "$week_window_mins" "$session_used_pct")
  [ -n "$week" ] || return

  printf '#[fg=colour178]%s#[fg=colour245] %s' "$label" "$week"
}

# Same content as `format_provider` minus the leading label + colour
# bracket. Used by the `--claude` / `--codex` flag path so callers
# (Flash's `[statusbar].template`) can supply the label and separators
# themselves and keep one ownership boundary per format concern.
format_provider_unlabelled() {
  week_pct=${1:-}
  week_reset=${2:-}
  week_window_mins=${3:-}
  session_used_pct=${4:-}

  week=$(format_period "$week_pct" "$week_reset" "$week_window_mins" "$session_used_pct")
  [ -n "$week" ] || return
  printf '%s' "$week"
}

unknown_weekly_provider_unlabelled() {
  printf '%s' '?%↻?d'
}

unknown_weekly_provider() {
  label=${1:-}
  [ -n "$label" ] || return
  printf '#[fg=colour178]%s#[fg=colour245] %s' "$label" "$(unknown_weekly_provider_unlabelled)"
}

# Fetch + render Claude usage on its own. Falls back to the last
# rendered cached value when the live fetch produces nothing.
render_claude_unlabelled() {
  week_pct=
  week_reset=
  week_window_mins=10080
  session_used_pct=

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_claude_usage)
    if [ -n "$limits" ]; then
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')")
      session_used_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $5}')
    fi
  fi

  status=$(format_provider_unlabelled "$week_pct" "$week_reset" "$week_window_mins" "$session_used_pct")
  cache="$cache_root/rendered-claude-unlabelled-v6.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_weekly_provider_unlabelled
  fi
}

render_fable_unlabelled() {
  week_pct=
  week_reset=
  week_window_mins=10080
  session_used_pct=

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_claude_usage)
    if [ -n "$limits" ]; then
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')")
      session_used_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $5}')
    fi
  fi

  status=$(format_provider_unlabelled "$week_pct" "$week_reset" "$week_window_mins" "$session_used_pct")
  cache="$cache_root/rendered-fable-unlabelled-v4.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_weekly_provider_unlabelled
  fi
}

render_codex_unlabelled() {
  week_pct=
  week_reset=
  week_window_mins=
  session_used_pct=

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_codex_rate_limits)
    if [ -n "$limits" ]; then
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      week_reset=$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')
      week_window_mins=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      session_used_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')
    fi
  fi

  status=$(format_provider_unlabelled "$week_pct" "$week_reset" "$week_window_mins" "$session_used_pct")
  cache="$cache_root/rendered-codex-unlabelled-v6.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_weekly_provider_unlabelled
  fi
}

render_grok_unlabelled() {
  week_pct=
  week_reset=
  week_window_mins=10080

  if command -v jq >/dev/null 2>&1; then
    limits=$(live_grok_usage)
    if [ -n "$limits" ]; then
      week_pct=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')")
      reported_window=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      [ -n "$reported_window" ] && [ "$reported_window" != null ] && week_window_mins=$reported_window
    fi
  fi

  status=$(format_provider_unlabelled "$week_pct" "$week_reset" "$week_window_mins")
  cache="$cache_root/rendered-grok-unlabelled-v4.last"
  if [ -n "$status" ]; then
    write_cache_file "$cache" "$status" || true
    printf '%s' "$status"
  elif [ -s "$cache" ]; then
    cat "$cache"
  else
    unknown_weekly_provider_unlabelled
  fi
}

render_status() {
  claude_week_pct=
  claude_week_reset=
  claude_week_window_mins=10080
  claude_session_used_pct=
  fable_week_pct=
  fable_week_reset=
  fable_week_window_mins=10080
  codex_week_pct=
  codex_week_reset=
  codex_week_window_mins=
  codex_session_used_pct=
  grok_week_pct=
  grok_week_reset=
  grok_week_window_mins=10080

  if command -v jq >/dev/null 2>&1; then
    claude_limits=$(live_claude_usage)
    if [ -n "$claude_limits" ]; then
      claude_week_pct=$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $1}')
      claude_week_reset=$(epoch_from_iso "$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $2}')")
      fable_week_pct=$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $3}')
      fable_week_reset=$(epoch_from_iso "$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $4}')")
      claude_session_used_pct=$(printf '%s\n' "$claude_limits" | awk -F '\t' '{print $5}')
    fi

    codex_limits=$(live_codex_rate_limits)
    if [ -n "$codex_limits" ]; then
      codex_week_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $1}')
      codex_week_reset=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $2}')
      codex_week_window_mins=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $3}')
      codex_session_used_pct=$(printf '%s\n' "$codex_limits" | awk -F '\t' '{print $4}')
    fi

    grok_limits=$(live_grok_usage)
    if [ -n "$grok_limits" ]; then
      grok_week_pct=$(printf '%s\n' "$grok_limits" | awk -F '\t' '{print $1}')
      grok_week_reset=$(epoch_from_iso "$(printf '%s\n' "$grok_limits" | awk -F '\t' '{print $2}')")
      reported_window=$(printf '%s\n' "$grok_limits" | awk -F '\t' '{print $3}')
      [ -n "$reported_window" ] && [ "$reported_window" != null ] && grok_week_window_mins=$reported_window
    fi
  fi

  claude_status=$(format_provider Cld "$claude_week_pct" "$claude_week_reset" "$claude_week_window_mins" "$claude_session_used_pct")
  fable_status=$(format_provider Fbl "$fable_week_pct" "$fable_week_reset" "$fable_week_window_mins" "$claude_session_used_pct")
  codex_status=$(format_provider Cdx "$codex_week_pct" "$codex_week_reset" "$codex_week_window_mins" "$codex_session_used_pct")
  grok_status=$(format_provider Grk "$grok_week_pct" "$grok_week_reset" "$grok_week_window_mins")

  if [ -n "$claude_status" ]; then
    write_cache_file "$claude_status_cache" "$claude_status" || true
  else
    claude_status=$(previous_provider_status Cld "$claude_status_cache")
  fi
  [ -n "$claude_status" ] || claude_status=$(unknown_weekly_provider Cld)

  if [ -n "$fable_status" ]; then
    write_cache_file "$fable_status_cache" "$fable_status" || true
  else
    fable_status=$(previous_provider_status Fbl "$fable_status_cache")
  fi
  [ -n "$fable_status" ] || fable_status=$(unknown_weekly_provider Fbl)

  if [ -n "$codex_status" ]; then
    write_cache_file "$codex_status_cache" "$codex_status" || true
  else
    codex_status=$(previous_provider_status Cdx "$codex_status_cache")
  fi
  [ -n "$codex_status" ] || codex_status=$(unknown_weekly_provider Cdx)

  if [ -n "$grok_status" ]; then
    write_cache_file "$grok_status_cache" "$grok_status" || true
  else
    grok_status=$(previous_provider_status Grk "$grok_status_cache")
  fi
  [ -n "$grok_status" ] || grok_status=$(unknown_weekly_provider Grk)

  status=
  if [ -n "$claude_status" ]; then
    status=$claude_status
  fi
  if [ -n "$fable_status" ]; then
    [ -n "$status" ] && status="$status#[fg=colour245] · "
    status="$status$fable_status"
  fi
  if [ -n "$codex_status" ]; then
    [ -n "$status" ] && status="$status#[fg=colour245] · "
    status="$status$codex_status"
  fi
  if [ -n "$grok_status" ]; then
    [ -n "$status" ] && status="$status#[fg=colour245] · "
    status="$status$grok_status"
  fi
  [ -n "$status" ] || return

  printf '%s' "$status"
}

valid_usage_percent() {
  awk -v value="${1:-}" '
    BEGIN {
      if (value !~ /^[0-9]+([.][0-9]+)?$/) exit 1
      if ((value + 0) < 0 || (value + 0) > 100) exit 1
    }'
}

valid_epoch() {
  case "${1:-}" in
    '' | *[!0-9]*) return 1 ;;
    *) [ "$1" -gt 0 ] ;;
  esac
}

format_detail_line() {
  label=${1:-}
  used_pct=${2:-}
  reset_at=${3:-}
  [ -n "$label" ] || return 1
  valid_usage_percent "$used_pct" || return 1

  pct=$(fmt_remaining_percent "$used_pct")
  if valid_epoch "$reset_at"; then
    printf '%s %s remaining · resets in %s' "$label" "$pct" "$(fmt_days_until "$reset_at")"
  else
    printf '%s %s remaining' "$label" "$pct"
  fi
}

format_window_label() {
  minutes=${1:-}
  case "$minutes" in
    '' | *[!0-9]*) printf '%s' Session ;;
    *)
      if [ "$minutes" -ge 1440 ] && [ $((minutes % 1440)) -eq 0 ]; then
        printf '%s-day' "$((minutes / 1440))"
      elif [ "$minutes" -ge 60 ] && [ $((minutes % 60)) -eq 0 ]; then
        printf '%s-hour' "$((minutes / 60))"
      else
        printf '%s-minute' "$minutes"
      fi
      ;;
  esac
}

format_cache_age() {
  file=${1:-}
  mtime=$(file_mtime "$file" 2>/dev/null) || {
    printf '%s' unknown
    return
  }
  age=$((now - mtime))
  [ "$age" -ge 0 ] || age=0
  if [ "$age" -lt 60 ]; then
    printf '%s' now
  elif [ "$age" -lt 3600 ]; then
    printf '%sm ago' "$((age / 60))"
  elif [ "$age" -lt 86400 ]; then
    printf '%sh ago' "$((age / 3600))"
  else
    printf '%sd ago' "$((age / 86400))"
  fi
}

# Popup reads are deliberately cache-only. Flash refreshes these through its
# normal status scheduler; moving the pointer must never perform OAuth, network,
# or app-server work.
render_usage_details() {
  provider=${1:-}
  file=
  printed=0

  case "$provider" in
    claude | fable)
      if [ -f "$claude_usage_cache" ]; then
        file=$claude_usage_cache
        limits=$(cat "$file")
      elif [ -f "$legacy_claude_usage_cache" ]; then
        file=$legacy_claude_usage_cache
        limits=$(claude_usage_from_legacy)
      else
        limits=
      fi
      session_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $5}')
      session_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $6}')")
      if [ "$provider" = claude ]; then
        week_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
        week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')")
        session_label=5-hour
      else
        week_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
        week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')")
        session_label='Shared 5-hour'
      fi
      session_line=$(format_detail_line "$session_label" "$session_used" "$session_reset" 2>/dev/null || true)
      week_line=$(format_detail_line 7-day "$week_used" "$week_reset" 2>/dev/null || true)
      ;;
    codex)
      file=$codex_usage_cache
      [ -f "$file" ] && limits=$(cat "$file") || limits=
      week_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      week_reset=$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')
      week_window=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      session_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $4}')
      session_reset=$(printf '%s\n' "$limits" | awk -F '\t' '{print $5}')
      session_window=$(printf '%s\n' "$limits" | awk -F '\t' '{print $6}')
      session_line=$(format_detail_line "$(format_window_label "$session_window")" "$session_used" "$session_reset" 2>/dev/null || true)
      week_line=$(format_detail_line "$(format_window_label "$week_window")" "$week_used" "$week_reset" 2>/dev/null || true)
      ;;
    grok)
      file=$grok_usage_cache
      [ -f "$file" ] && limits=$(cat "$file") || limits=
      week_used=$(printf '%s\n' "$limits" | awk -F '\t' '{print $1}')
      week_reset=$(epoch_from_iso "$(printf '%s\n' "$limits" | awk -F '\t' '{print $2}')")
      week_window=$(printf '%s\n' "$limits" | awk -F '\t' '{print $3}')
      session_line=
      week_line=$(format_detail_line "$(format_window_label "$week_window")" "$week_used" "$week_reset" 2>/dev/null || true)
      ;;
    *)
      printf '%s' 'No cached usage details'
      return
      ;;
  esac

  for line in "$session_line" "$week_line"; do
    [ -n "$line" ] || continue
    [ "$printed" -eq 0 ] || printf '\n'
    printf '%s' "$line"
    printed=1
  done
  if [ "$printed" -eq 1 ]; then
    printf '\nUpdated %s' "$(format_cache_age "$file")"
  else
    printf '%s' 'No cached usage details'
  fi
}

case "${1:-}" in
  --details=claude)
    render_usage_details claude
    exit 0
    ;;
  --details=fable)
    render_usage_details fable
    exit 0
    ;;
  --details=codex)
    render_usage_details codex
    exit 0
    ;;
  --details=grok)
    render_usage_details grok
    exit 0
    ;;
  --claude)
    render_claude_unlabelled
    exit 0
    ;;
  --codex)
    render_codex_unlabelled
    exit 0
    ;;
  --fable)
    render_fable_unlabelled
    exit 0
    ;;
  --grok)
    render_grok_unlabelled
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
