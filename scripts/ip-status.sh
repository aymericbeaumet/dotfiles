#!/bin/sh
# Public IPv4 in yellow; "no internet" in red on failure.
# Cache for 60s, refresh in background to avoid blocking the status bar.

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

cache="${TMPDIR:-/tmp}/tmux-ip-status-v3.cache"
ttl=60
now=$(date +%s)

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
    arm64|aarch64) arch=aarch64 ;;
    x86_64|amd64) arch=x86_64 ;;
    i386|i686) arch=i686 ;;
    armv7l|armv7*) arch=armv7 ;;
    *) arch=$(uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]') ;;
  esac

  printf '%s-%s' "${os:-unknown}" "${arch:-unknown}"
}

refresh_cache() {
  platform=$(platform_id)
  ip=
  if command -v curl >/dev/null 2>&1; then
    ip=$(curl -fsS -4 --max-time 2 https://api.ipify.org 2>/dev/null || true)
  fi

  tmp="${cache}.$$"
  if [ -n "$ip" ]; then
    printf '#[range=user|net-prefs fg=colour178]%s#[norange]#[fg=colour245] · #[fg=colour178]%s' "$ip" "$platform" > "$tmp"
  else
    printf '#[range=user|net-prefs fg=red]no internet#[norange]#[fg=colour245] · #[fg=colour178]%s' "$platform" > "$tmp"
  fi
  mv "$tmp" "$cache"
}

mtime=0
[ -f "$cache" ] && mtime=$(file_mtime "$cache" 2>/dev/null || echo 0)
age=$(( now - mtime ))

if [ ! -f "$cache" ]; then
  refresh_cache >/dev/null 2>&1
elif [ "$age" -ge "$ttl" ]; then
  refresh_cache >/dev/null 2>&1 &
fi

[ -f "$cache" ] && cat "$cache"
