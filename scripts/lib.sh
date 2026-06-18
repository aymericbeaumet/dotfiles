#!/bin/sh
# Shared portable helpers for dotfiles shell scripts.

dotfiles_uname() {
  uname -s 2>/dev/null || printf unknown
}

is_darwin() {
  [ "$(dotfiles_uname)" = "Darwin" ]
}

is_linux() {
  [ "$(dotfiles_uname)" = "Linux" ]
}

file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}

epoch_from_iso() {
  iso=${1:-}
  [ -z "$iso" ] || [ "$iso" = "null" ] && return
  iso=$(printf '%s' "$iso" |
    sed -E 's/\.[0-9]+([Z+-])/\1/; s/Z$/+0000/; s/([+-][0-9][0-9]):([0-9][0-9])$/\1\2/')
  date -j -f "%Y-%m-%dT%H:%M:%S%z" "$iso" +%s 2>/dev/null ||
    date -d "$iso" +%s 2>/dev/null
}

url_encode() {
  printf '%s' "$1" | od -An -tx1 -v | tr -d ' \n' | sed 's/../%&/g'
}

repeat_char() {
  char=${1:-}
  count=${2:-0}
  awk -v char="$char" -v count="$count" 'BEGIN { for (i = 0; i < count; i++) printf "%s", char }'
}

dotfiles_dir() {
  if [ -n "${DOTFILES_SCRIPT_DIR:-}" ]; then
    dirname "$DOTFILES_SCRIPT_DIR"
    return
  fi

  script_dir=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || return
  case "$script_dir" in
    */scripts) dirname "$script_dir" ;;
    *) printf '%s' "$script_dir" ;;
  esac
}

flash_alert() {
  message=${1:-}
  shift || true
  [ -n "$message" ] || return 0

  if command -v flash >/dev/null 2>&1; then
    flash_bin=$(command -v flash)
  elif [ -n "${HOME:-}" ] && [ -x "$HOME/.local/bin/flash" ]; then
    flash_bin=$HOME/.local/bin/flash
  else
    return 0
  fi

  "$flash_bin" alert_show "--message=$message" "$@" >/dev/null 2>&1 || true
}
