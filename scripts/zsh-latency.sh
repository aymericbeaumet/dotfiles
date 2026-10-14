#!/bin/bash
# Measure the interactive zsh latency a user feels: the time from the end of a
# command to an editable prompt (precmd hooks plus prompt rendering), for empty
# Enter presses and for `cd`. It drives a real interactive zsh under a pty via
# script(1), so p10k, the zinit turbo plugins, and every hook load as in a
# terminal. Fails when p10k reports console output during initialization.
# Usage: scripts/zsh-latency.sh [directory]   (defaults to $HOME)
set -euo pipefail

dir=${1:-$HOME}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/zsh-latency.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/measure.zsh" <<'ZSH'
zmodload zsh/datetime
typeset -ga _lat_enter _lat_cd
typeset -gF _lat_t0=0
typeset -g _lat_mode=enter
_lat_start() { _lat_t0=$EPOCHREALTIME }
precmd_functions=(_lat_start $precmd_functions)
autoload -Uz add-zle-hook-widget
_lat_end() {
  (( _lat_t0 )) || return 0
  local name=_lat_$_lat_mode
  local -F sample=$(( (EPOCHREALTIME - _lat_t0) * 1000 ))
  set -A $name ${(P)name} $sample
  _lat_t0=0
}
add-zle-hook-widget line-init _lat_end
_lat_report() {
  local name
  local -a sorted
  # The preexec title write leaves the cursor mid-line; start the report fresh.
  print
  for name in _lat_enter _lat_cd; do
    sorted=(${(on)${(P)name}})
    (( ${#sorted} )) || continue
    printf 'LAT %-6s n=%d median=%.1f ms min=%.1f max=%.1f\n' ${name#_lat_} \
      ${#sorted} ${sorted[$(( (${#sorted} + 1) / 2 ))]} ${sorted[1]} ${sorted[-1]}
  done
}
ZSH

drive() {
  sleep 5
  printf 'source %s\n' "$tmp/measure.zsh"
  sleep 1
  for _ in $(seq 30); do
    printf '\n'
    sleep 0.15
  done
  printf '_lat_mode=cd\n'
  sleep 0.3
  for _ in $(seq 10); do
    printf 'cd /tmp\n'
    sleep 0.2
    printf 'cd -\n'
    sleep 0.2
  done
  printf '_lat_mode=enter\n'
  sleep 0.3
  printf '_lat_report\n'
  sleep 1
  printf 'exit\n'
}

cd "$dir"
if script -V >/dev/null 2>&1; then
  drive | script -q -c 'zsh -i' /dev/null 2>&1 | tr -d '\r' >"$tmp/log"
else
  drive | script -q /dev/null zsh -i 2>&1 | tr -d '\r' >"$tmp/log"
fi

status=0
if grep -aq 'Console output during zsh initialization' "$tmp/log"; then
  echo 'p10k reported console output during zsh initialization' >&2
  status=1
fi
grep -a '^LAT ' "$tmp/log" || {
  echo 'no measurements captured' >&2
  status=1
}
exit "$status"
