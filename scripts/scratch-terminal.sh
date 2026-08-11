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

log() {
  printf '[scratch-terminal] %s\n' "$*" >&2
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
    log "local tmux client exited with status $status; reattaching in 1 second"
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

  while true; do
    log "connecting to Moria with Mosh"
    log "if Mosh reports blocked UDP, press Ctrl-^ then . to switch to SSH"
    run_mosh
    mosh_status=$?
    if ((mosh_status == 127)); then
      log "Mosh is unavailable; using SSH"
    else
      log "Mosh exited with status $mosh_status; falling back to SSH"
    fi

    run_ssh
    ssh_status=$?
    delay=${RETRY_DELAYS[$delay_index]}
    log "SSH exited with status $ssh_status; retrying Mosh in $delay seconds"
    sleep "$delay"
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
  printf 'Usage: %s {bootstrap|local|remote}\n' "${0##*/}" >&2
  exit 64
}

case "${1:-bootstrap}" in
  bootstrap)
    create_remote_window || true
    run_local
    ;;
  local) run_local ;;
  remote) run_remote ;;
  *) usage ;;
esac
