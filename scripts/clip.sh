#!/usr/bin/env bash
# Cross-platform clipboard writer: reads stdin, writes to system clipboard.
# Order of preference: pbcopy (macOS) → wl-copy (Wayland) → xclip / xsel (X11).
set -eu

if command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy
elif [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
elif command -v xclip >/dev/null 2>&1; then
  exec xclip -selection clipboard -in
elif command -v xsel >/dev/null 2>&1; then
  exec xsel --clipboard --input
else
  cat >/dev/null
  echo "clip.sh: no clipboard tool found (install wl-clipboard or xclip)" >&2
  exit 1
fi
