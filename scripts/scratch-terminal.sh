#!/usr/bin/env bash

# Keep the single Alacritty window attached to the local scratch tmux session.
# Cmd+R detaches the client; the loop reattaches so the window never closes.

set -uo pipefail

readonly LOCAL_SESSION="scratch"
readonly LOCAL_ROOT="$HOME/workspace/aymericbeaumet"

log() {
  printf '[scratch-terminal] %s\n' "$*" >&2
}

while true; do
  if ! command -v tmux >/dev/null 2>&1; then
    log "tmux is unavailable; retrying in 15 seconds"
    sleep 15
    continue
  fi

  tmux new-session -A -s "$LOCAL_SESSION" -c "$LOCAL_ROOT"
  status=$?
  if ((status == 0)); then
    log "tmux client detached; reattaching"
    continue
  fi

  log "tmux client exited with status $status; retrying in 1 second"
  sleep 1
done
