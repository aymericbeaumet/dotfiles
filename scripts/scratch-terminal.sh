#!/usr/bin/env bash

set -uo pipefail

readonly LOCAL_SESSION="scratch"
readonly LOCAL_ROOT="$HOME/workspace/aymericbeaumet"
readonly REMOTE_HOST="ab@moria.zone"
readonly REMOTE_SESSION="scratch"
readonly REMOTE_ROOT="/home/ab"
readonly REMOTE_TMUX="/home/ab/.local/share/mise/shims/tmux"
readonly MOSH_PORT_RANGE="61000:61009"
readonly MOSH_NETWORK_TIMEOUT="86400"
readonly -a RETRY_DELAYS=(15 30 60)

scratch_tmp_root="${TMPDIR:-/tmp}"
if [[ -d "$scratch_tmp_root" ]]; then
  scratch_tmp_root=$(cd "$scratch_tmp_root" && pwd -P)
fi
readonly SCRATCH_STATE_ROOT="${scratch_tmp_root%/}/scratch-terminal-$UID"
unset scratch_tmp_root

remote_state_dir=""

log() {
  printf '[scratch-terminal] %s\n' "$*" >&2
}

cleanup_remote_state() {
  [[ -n "$remote_state_dir" ]] || return 0

  rm -f -- \
    "$remote_state_dir/reload" \
    "$remote_state_dir/role" \
    "$remote_state_dir/supervisor.pid"
  rmdir "$remote_state_dir" 2>/dev/null || true
}

setup_remote_state() {
  if [[ -L "$SCRATCH_STATE_ROOT" ]]; then
    log "refusing symlinked state directory: $SCRATCH_STATE_ROOT"
    return 1
  fi

  umask 077
  mkdir -p "$SCRATCH_STATE_ROOT" || return 1
  chmod 700 "$SCRATCH_STATE_ROOT" || return 1

  remote_state_dir=$(mktemp -d "$SCRATCH_STATE_ROOT/remote.XXXXXX") || return 1
  printf '%s\n' "$$" >"$remote_state_dir/supervisor.pid"
  printf '%s\n' remote >"$remote_state_dir/role"
  trap cleanup_remote_state EXIT

  # Alacritty launches binding commands from its foreground process's cwd.
  # Keeping transports here gives Cmd+R an exact per-window supervisor target.
  cd "$remote_state_dir" || return 1
}

consume_reload_request() {
  [[ -n "$remote_state_dir" && -f "$remote_state_dir/reload" ]] || return 1
  rm -f -- "$remote_state_dir/reload"
}

direct_child_pid() {
  ps -axo pid=,ppid= | awk -v parent="$1" '$2 == parent { print $1; exit }'
}

reload_current() {
  local child_pid=""
  local current_child
  local state_dir
  local role
  local supervisor_command
  local supervisor_pid

  state_dir=$(pwd -P) || return 1
  case "$state_dir" in
    "$SCRATCH_STATE_ROOT"/remote.*) ;;
    *) return 0 ;;
  esac

  [[ ! -L "$state_dir" ]] || return 1
  IFS= read -r role <"$state_dir/role" || return 1
  IFS= read -r supervisor_pid <"$state_dir/supervisor.pid" || return 1
  [[ "$role" == remote ]] || return 1
  case "$supervisor_pid" in
    '' | *[!0-9]*) return 1 ;;
  esac

  supervisor_command=$(ps -o command= -p "$supervisor_pid" 2>/dev/null) || return 1
  case "$supervisor_command" in
    *"scratch-terminal.sh remote"*) ;;
    *) return 1 ;;
  esac

  : >"$state_dir/reload"

  # The marker is enough when the supervisor is between children. Signaling a
  # later child would race with the supervisor consuming the marker first.
  child_pid=$(direct_child_pid "$supervisor_pid")
  [[ -n "$child_pid" ]] || return 0

  # Give a healthy transport half a second to tell the remote server to exit.
  # Mosh otherwise waits up to ten seconds when UDP is broken, so bound that
  # graceful path and terminate only the local client if it cannot finish.
  kill -TERM "$child_pid" 2>/dev/null || return 0
  for _ in {1..10}; do
    sleep 0.05
    current_child=$(direct_child_pid "$supervisor_pid")
    [[ "$current_child" == "$child_pid" ]] || return 0
  done

  kill -KILL "$child_pid" 2>/dev/null || true
}

restore_terminal() {
  [[ -t 0 ]] && stty sane 2>/dev/null || true
}

run_local() {
  local status

  while true; do
    if ! command -v tmux >/dev/null 2>&1; then
      log "tmux is unavailable; retrying in 15 seconds"
      sleep 15
      continue
    fi

    tmux new-session -A -s "$LOCAL_SESSION" -c "$LOCAL_ROOT"
    status=$?
    if ((status == 0)); then
      log "local tmux client detached; reattaching"
      continue
    fi

    log "local tmux client exited with status $status; retrying in 1 second"
    sleep 1
  done
}

run_mosh() {
  command -v mosh >/dev/null 2>&1 || return 127

  MOSH_TITLE_NOPREFIX=1 mosh \
    --bind-server=ssh \
    --port="$MOSH_PORT_RANGE" \
    --server="/usr/bin/env MOSH_SERVER_NETWORK_TMOUT=$MOSH_NETWORK_TIMEOUT /usr/bin/mosh-server" \
    --ssh="ssh -o BatchMode=yes -o ConnectTimeout=10 -o ConnectionAttempts=1 -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes" \
    "$REMOTE_HOST" -- \
    "$REMOTE_TMUX" new-session -A -s "$REMOTE_SESSION" -c "$REMOTE_ROOT"
}

run_ssh() {
  ssh -tt \
    -o BatchMode=yes \
    -o Compression=no \
    -o ConnectionAttempts=1 \
    -o ConnectTimeout=10 \
    -o IdentitiesOnly=yes \
    -o ServerAliveCountMax=3 \
    -o ServerAliveInterval=30 \
    -o StrictHostKeyChecking=yes \
    -o TCPKeepAlive=no \
    "$REMOTE_HOST" \
    "$REMOTE_TMUX" new-session -A -s "$REMOTE_SESSION" -c "$REMOTE_ROOT"
}

run_remote() {
  local delay_index=0
  local delay
  local mosh_status
  local ssh_status

  setup_remote_state || {
    log "failed to initialize remote-window state"
    return 1
  }

  while true; do
    if consume_reload_request; then
      delay_index=0
    fi

    log "connecting to Moria with Mosh"
    log "if Mosh reports blocked UDP, press Ctrl-^ then . to switch to SSH"
    run_mosh
    mosh_status=$?
    restore_terminal
    if consume_reload_request; then
      log "terminal reload requested; reconnecting with Mosh"
      delay_index=0
      continue
    fi

    if ((mosh_status == 127)); then
      log "Mosh is unavailable; using SSH"
    else
      log "Mosh exited with status $mosh_status; falling back to SSH"
    fi

    run_ssh
    ssh_status=$?
    restore_terminal
    if consume_reload_request; then
      log "terminal reload requested; reconnecting with Mosh"
      delay_index=0
      continue
    fi

    if ((ssh_status == 0)); then
      log "SSH session exited cleanly; retrying Mosh"
      delay_index=0
      continue
    fi

    delay=${RETRY_DELAYS[$delay_index]}
    log "SSH exited with status $ssh_status; retrying Mosh in $delay seconds"
    sleep "$delay"
    if consume_reload_request; then
      log "terminal reload requested; retrying Mosh"
      delay_index=0
      continue
    fi

    if ((delay_index < ${#RETRY_DELAYS[@]} - 1)); then
      ((delay_index += 1))
    fi
  done
}

create_remote_window() {
  if [[ "$(uname -s)" != "Darwin" || -z "${ALACRITTY_SOCKET:-}" || ! -S "${ALACRITTY_SOCKET:-}" ]]; then
    return 0
  fi

  if ! command -v alacritty >/dev/null 2>&1; then
    log "Alacritty CLI is unavailable; cannot create the Moria window"
    return 1
  fi

  for _ in {1..20}; do
    if alacritty msg --socket "$ALACRITTY_SOCKET" create-window \
      --title "scratch@moria.zone" \
      --command /bin/zsh -l -c \
      'exec "$HOME/.dotfiles/scripts/scratch-terminal.sh" remote'; then
      return 0
    fi
    sleep 0.1
  done

  log "failed to create the Moria window after 20 attempts"
  return 1
}

usage() {
  printf 'Usage: %s {bootstrap|local|remote|reload}\n' "${0##*/}" >&2
  exit 64
}

case "${1:-bootstrap}" in
  bootstrap)
    create_remote_window || true
    run_local
    ;;
  local) run_local ;;
  remote) run_remote ;;
  reload) reload_current ;;
  *) usage ;;
esac
