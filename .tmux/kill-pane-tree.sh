#!/usr/bin/env bash
# Recursively SIGKILL pane_pid and every descendant, plus each descendant's
# process group. zsh job control puts every foreground job in its own PG, so
# killing only pane_pid's PG leaves children (servers, dev tools, &-disowned
# jobs) alive after kill-pane closes the PTY.
#
# Usage: kill-pane-tree.sh <pane_pid>

set -u

root_pid=${1:-}
[ -z "$root_pid" ] && exit 0

# Walk the descendant tree (children of children of ...).
collect() {
  local p=$1
  printf '%s\n' "$p"
  local kids
  kids=$(pgrep -P "$p" 2>/dev/null) || return 0
  for k in $kids; do collect "$k"; done
}

pids=$(collect "$root_pid" | sort -u)
[ -z "$pids" ] && exit 0

# Stop the tree first so children can't fork while we're killing.
# shellcheck disable=SC2086
kill -STOP $pids 2>/dev/null || true

# Unique PGIDs across the whole tree — kills siblings spawned within each job.
pgids=$(ps -o pgid= -p $pids 2>/dev/null | tr -d ' ' | sort -u)
for pgid in $pgids; do
  [ -n "$pgid" ] && [ "$pgid" != 0 ] && kill -KILL -- "-$pgid" 2>/dev/null || true
done

# Belt-and-suspenders: SIGKILL each PID directly in case any escaped its PG.
# shellcheck disable=SC2086
kill -KILL $pids 2>/dev/null || true

exit 0
