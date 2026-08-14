#!/usr/bin/env bash

set -u

script_path=$(CDPATH='' cd "$(dirname "$0")" && pwd)/$(basename "$0")
readonly script_path

read_payload() {
  if [ -t 0 ]; then
    printf '{}\n'
  else
    cat
  fi
}

is_transient_payload() {
  local payload="$1"
  local error_kind
  local error_text
  local normalized

  error_kind=$(jq -r '.error // empty' <<<"$payload" 2>/dev/null) || return 1
  error_text=$(jq -r '
    [(.error_details // empty), (.last_assistant_message // empty)]
    | map(select(type == "string"))
    | join(" ")
  ' <<<"$payload" 2>/dev/null) || return 1
  normalized=$(printf '%s %s' "$error_kind" "$error_text" | tr '[:upper:]' '[:lower:]')

  case "$normalized" in
    *authentication* | *unauthorized* | *forbidden* | *oauth* | *billing* | *credit\ balance* | \
      *usage\ limit* | *weekly\ limit* | *monthly\ limit* | *invalid\ request* | \
      *max\ output* | *context\ window* | *policy* | *permission*) return 1 ;;
  esac

  case "$error_kind" in
    rate_limit | server_error) return 0 ;;
    unknown) ;;
    *) return 1 ;;
  esac

  case "$normalized" in
    *connection*closed* | *connection*lost* | *connection*reset* | *socket*closed* | \
      *socket*reset* | *stream*closed* | *stream*read*error* | *server*overload* | \
      *service*unavailable* | *server*capacity* | *upstream*error* | *network*error* | \
      *fetch*failed* | *timed*out* | *timeout* | *econnreset* | *too\ many\ requests* | \
      *rate*limit* | *\ 429* | \
      *\ 500* | *\ 502* | *\ 503* | *\ 504* | *\ 529*) return 0 ;;
  esac

  return 1
}

state_root() {
  printf '%s/agent-retry/claude\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}

state_key() {
  printf '%s' "$1" | cksum | awk '{ print $1 }'
}

retry_delay() {
  case "$1" in
    1) printf '15\n' ;;
    2) printf '30\n' ;;
    3) printf '60\n' ;;
    4) printf '120\n' ;;
    5) printf '300\n' ;;
    6) printf '600\n' ;;
    *) printf '900\n' ;;
  esac
}

pane_is_safe() {
  local pane="$1"
  local expected_pid="$2"
  local metadata
  local pane_dead
  local pane_in_mode
  local pane_pid
  local pane_command

  metadata=$(tmux display-message -p -t "$pane" \
    '#{pane_dead}|#{pane_in_mode}|#{pane_pid}|#{pane_current_command}' 2>/dev/null) || return 1
  IFS='|' read -r pane_dead pane_in_mode pane_pid pane_command <<<"$metadata"

  [ "$pane_dead" = "0" ] || return 1
  [ "$pane_in_mode" = "0" ] || return 1
  [ "$pane_pid" = "$expected_pid" ] || return 1
  case "$pane_command" in
    claude | claude.* | claude-*) return 0 ;;
  esac

  return 1
}

pane_signature() {
  tmux capture-pane -p -t "$1" -S -100 2>/dev/null | cksum | awk '{ print $1 ":" $2 }'
}

deliver_continue() {
  local pane="$1"
  local pane_pid="$2"
  local delay="$3"
  local lock_dir="$4"
  local initial_signature
  local final_signature

  cleanup() {
    rmdir "$lock_dir" 2>/dev/null || true
  }
  trap cleanup EXIT HUP INT TERM

  [ -d "$lock_dir" ] || return 0
  sleep 2
  [ -d "$lock_dir" ] || return 0
  pane_is_safe "$pane" "$pane_pid" || return 0
  initial_signature=$(pane_signature "$pane") || return 0

  sleep "$delay"
  [ -d "$lock_dir" ] || return 0
  pane_is_safe "$pane" "$pane_pid" || return 0
  final_signature=$(pane_signature "$pane") || return 0
  [ "$initial_signature" = "$final_signature" ] || return 0

  tmux send-keys -t "$pane" -l 'continue'
  tmux send-keys -t "$pane" Enter
}

schedule_continue() {
  local payload="$1"
  local pane="${TMUX_PANE:-}"
  local pane_number
  local pane_pid
  local session_id
  local root
  local key
  local lock_dir
  local attempt_file
  local attempt=0
  local delay

  is_transient_payload "$payload" || return 0
  command -v jq >/dev/null 2>&1 || return 0
  command -v tmux >/dev/null 2>&1 || return 0

  pane_number=${pane#%}
  case "$pane_number" in
    '' | *[!0-9]*) return 0 ;;
  esac
  pane_pid=$(tmux display-message -p -t "$pane" '#{pane_pid}' 2>/dev/null) || return 0
  pane_is_safe "$pane" "$pane_pid" || return 0

  session_id=$(jq -r '.session_id // "unknown"' <<<"$payload" 2>/dev/null) || return 0
  root=$(state_root)
  mkdir -p "$root" || return 0
  chmod 700 "$root" 2>/dev/null || true
  key=$(state_key "$session_id:$pane")
  lock_dir="$root/$key.lock"
  attempt_file="$root/$key.attempt"
  mkdir "$lock_dir" 2>/dev/null || return 0

  if [ -r "$attempt_file" ]; then
    IFS= read -r attempt <"$attempt_file"
  fi
  case "$attempt" in
    '' | *[!0-9]*) attempt=0 ;;
  esac
  attempt=$((attempt + 1))
  if ((attempt > 24)); then
    rmdir "$lock_dir" 2>/dev/null || true
    return 0
  fi
  printf '%s\n' "$attempt" >"$attempt_file"
  delay=$(retry_delay "$attempt")

  nohup "$script_path" deliver "$pane" "$pane_pid" "$delay" "$lock_dir" \
    </dev/null >/dev/null 2>&1 &
}

reset_attempts() {
  local payload="$1"
  local pane="${TMUX_PANE:-}"
  local session_id
  local root
  local key

  command -v jq >/dev/null 2>&1 || return 0
  session_id=$(jq -r '.session_id // "unknown"' <<<"$payload" 2>/dev/null) || return 0
  root=$(state_root)
  key=$(state_key "$session_id:$pane")
  rm -f "$root/$key.attempt"
  rmdir "$root/$key.lock" 2>/dev/null || true
}

action=${1:-}
case "$action" in
  classify)
    payload=$(read_payload)
    is_transient_payload "$payload"
    ;;
  deliver)
    shift
    deliver_continue "$@"
    ;;
  failure)
    payload=$(read_payload)
    schedule_continue "$payload"
    ;;
  reset)
    payload=$(read_payload)
    reset_attempts "$payload"
    ;;
  *) exit 2 ;;
esac
