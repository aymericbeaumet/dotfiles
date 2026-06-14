#!/usr/bin/env bash
# Cross-platform URL/file opener with headless Linux fallbacks.
set -eu

target=${1:-}
[ -n "$target" ] || {
  echo "open-url.sh: missing URL or file path" >&2
  exit 2
}

case "$(uname -s 2>/dev/null || printf unknown)" in
  Darwin)
    if command -v open >/dev/null 2>&1; then
      exec open "$@"
    fi
    ;;
esac

if { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; } && command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$@"
fi

case "$target" in
  http://*|https://*|file://*)
    for browser in "${BROWSER:-}" w3m elinks links lynx; do
      [ -n "$browser" ] || continue
      if command -v "$browser" >/dev/null 2>&1; then
        exec "$browser" "$target"
      fi
    done
    ;;
esac

file=${target#file://}
if [ -d "$file" ]; then
  exec "${PAGER:-less}" "$file"
elif [ -f "$file" ]; then
  lower_file=$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')
  case "$lower_file" in
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff|*.webp|*.svg|*.ico|*.heic)
      if command -v chafa >/dev/null 2>&1; then
        chafa "$file"
        exit 0
      fi
      ;;
  esac

  if command -v bat >/dev/null 2>&1; then
    exec bat --paging=always -- "$file"
  elif command -v less >/dev/null 2>&1; then
    exec less -R -- "$file"
  else
    exec cat -- "$file"
  fi
fi

if command -v open >/dev/null 2>&1; then
  exec open "$@"
elif command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$@"
else
  echo "open-url.sh: no opener found (install xdg-utils, w3m, elinks, links, or lynx)" >&2
  exit 1
fi
