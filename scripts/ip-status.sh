#!/bin/sh
# Public IPv4, load, temperature, and platform for tmux status.
# "no internet" is shown in red when the public IP cannot be fetched.
# Cache for 60s, refresh in background to avoid blocking the status bar.

DOTFILES_SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

cache="${TMPDIR:-/tmp}/tmux-ip-status-v13.cache"
refresh_lock="${cache}.lock"
ttl=60
now=$(date +%s)
yellow='#[fg=colour178]'
gray='#[fg=colour245]'

platform_id() {
  case "$(dotfiles_uname)" in
    Darwin) os=darwin ;;
    Linux) os=linux ;;
    FreeBSD) os=freebsd ;;
    OpenBSD) os=openbsd ;;
    NetBSD) os=netbsd ;;
    *) os=$(dotfiles_uname | tr '[:upper:]' '[:lower:]') ;;
  esac

  case "$(uname -m 2>/dev/null || printf unknown)" in
    arm64 | aarch64) arch=aarch64 ;;
    x86_64 | amd64) arch=x86_64 ;;
    i386 | i686) arch=i686 ;;
    armv7l | armv7*) arch=armv7 ;;
    *) arch=$(uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]') ;;
  esac

  printf '%s-%s' "${os:-unknown}" "${arch:-unknown}"
}

macmon_temperature() {
  is_darwin || return
  command -v macmon >/dev/null 2>&1 || return

  # macmon samples through private IOReport APIs and can hang when a macOS
  # update changes those metrics. Bound it independently of the cache refresh
  # so a broken sampler cannot leave one resident process per tmux redraw.
  output="${cache}.macmon.$$"
  macmon pipe --samples 1 --interval 1000 >"$output" 2>/dev/null &
  macmon_pid=$!
  (
    sleep 3
    kill -KILL "$macmon_pid" 2>/dev/null || true
  ) &
  watchdog_pid=$!

  wait "$macmon_pid" 2>/dev/null
  macmon_status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true

  if [ "$macmon_status" -eq 0 ]; then
    awk '
      {
        line = $0
        while (match(line, /"(cpu|gpu)_temp_avg":[0-9]+([.][0-9]+)?/)) {
          value = substr(line, RSTART, RLENGTH)
          sub(/^.*:/, "", value)
          value += 0
          if (value > 0 && value < 150 && (!found || value > max)) {
            max = value
            found = 1
          }
          line = substr(line, RSTART + RLENGTH)
        }
      }
      END { if (found) printf "%.0f°", max }
    ' "$output"
  fi
  rm -f "$output"
}

sensors_temperature() {
  command -v sensors >/dev/null 2>&1 || return

  sensors 2>/dev/null |
    awk '
      {
        line = $0
        while (match(line, /[-+]?[0-9]+([.][0-9]+)?[^0-9.]*C/)) {
          value = substr(line, RSTART, RLENGTH)
          gsub(/[^0-9.+-]/, "", value)
          value += 0
          if (value > 0 && value < 150 && (!found || value > max)) {
            max = value
            found = 1
          }
          line = substr(line, RSTART + RLENGTH)
        }
      }
      END { if (found) printf "%.0f°", max }
    '
}

sysfs_temperature() {
  for path in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$path" ] || continue
    awk '
      {
        value = $1 + 0
        if (value > 1000) value = value / 1000
        if (value > 0 && value < 150 && (!found || value > max)) {
          max = value
          found = 1
        }
      }
      END { if (found) print max }
    ' "$path" 2>/dev/null
  done |
    awk 'NR == 1 || $1 > max { max = $1 } END { if (NR) printf "%.0f°", max }'
}

hottest_temperature() {
  temp=$(macmon_temperature)
  [ -n "$temp" ] && printf '%s' "$temp" && return

  temp=$(sensors_temperature)
  [ -n "$temp" ] && printf '%s' "$temp" && return

  sysfs_temperature
}

load_average() {
  if [ -r /proc/loadavg ]; then
    awk '{ printf "%.2f", $1 }' /proc/loadavg
    return
  fi

  if command -v sysctl >/dev/null 2>&1; then
    load=$(sysctl -n vm.loadavg 2>/dev/null |
      awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+([.][0-9]+)?$/) { printf "%.2f", $i; exit } }')
    [ -n "$load" ] && printf '%s' "$load" && return
  fi

  uptime 2>/dev/null |
    awk -F'load averages?: ' 'NF > 1 { split($2, a, /[, ]+/); printf "%.2f", a[1]; exit }'
}

join_status() {
  status=$1
  shift

  for component; do
    [ -n "$component" ] || continue
    status="$status$gray · $yellow$component"
  done

  printf '%s' "$status"
}

refresh_cache() {
  platform=$(platform_id)
  temp=$(hottest_temperature)
  load=$(load_average)
  ip=
  if command -v curl >/dev/null 2>&1; then
    ip=$(curl -fsS -4 --max-time 2 https://api.ipify.org 2>/dev/null || true)
  fi

  tmp="${cache}.$$"
  if [ -n "$ip" ]; then
    status="#[range=user|net-prefs fg=colour178]$ip#[norange]"
  else
    status='#[range=user|net-prefs fg=red]no internet#[norange]'
  fi
  join_status "$status" "$load" "$temp" "$platform" >"$tmp"
  mv "$tmp" "$cache"
}

acquire_refresh_lock() {
  if mkdir "$refresh_lock" 2>/dev/null; then
    printf '%s\n' "$$" >"$refresh_lock/pid"
    return 0
  fi

  refresh_pid=
  [ -f "$refresh_lock/pid" ] && IFS= read -r refresh_pid <"$refresh_lock/pid"
  case "$refresh_pid" in
    '' | *[!0-9]*) ;;
    *) kill -0 "$refresh_pid" 2>/dev/null && return 1 ;;
  esac

  rm -f "$refresh_lock/pid"
  rmdir "$refresh_lock" 2>/dev/null || return 1
  mkdir "$refresh_lock" 2>/dev/null || return 1
  printf '%s\n' "$$" >"$refresh_lock/pid"
}

refresh_cache_async() {
  acquire_refresh_lock || return
  (
    trap 'rm -f "$refresh_lock/pid"; rmdir "$refresh_lock" 2>/dev/null || true' EXIT HUP INT TERM
    refresh_cache
  ) >/dev/null 2>&1 &
  refresh_pid=$!
  [ -d "$refresh_lock" ] && printf '%s\n' "$refresh_pid" >"$refresh_lock/pid"
}

mtime=0
[ -f "$cache" ] && mtime=$(file_mtime "$cache" 2>/dev/null || echo 0)
age=$((now - mtime))

if [ ! -f "$cache" ] || [ "$age" -ge "$ttl" ]; then
  refresh_cache_async
fi

[ -f "$cache" ] && cat "$cache"
