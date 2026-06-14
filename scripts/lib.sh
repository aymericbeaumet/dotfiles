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
  if [ -n "${DOTFILES:-}" ]; then
    printf '%s' "$DOTFILES"
  else
    printf '%s/.dotfiles' "$HOME"
  fi
}

flash_alert() {
  message=${1:-}
  [ -n "$message" ] || return 0
  encoded=$(url_encode "$message")
  "$(dotfiles_dir)/scripts/open-url.sh" "flash://alert_show?message=$encoded" >/dev/null 2>&1 || true
}
