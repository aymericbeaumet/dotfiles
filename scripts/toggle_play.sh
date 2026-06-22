#!/bin/sh
# Toggle system media play/pause, mimicking the physical play/pause key.
# Uses nowplaying-cli (MediaRemote framework), so it controls whatever app
# owns "Now Playing" — Spotify, Music, browser video (YouTube), etc.
set -eu

if [ "$(uname -s 2>/dev/null)" != "Darwin" ]; then
  echo "toggle_play.sh: macOS only" >&2
  exit 0
fi

# flash launches this with a minimal PATH (no /opt/homebrew/bin), so resolve
# the binary explicitly instead of relying on PATH lookup.
if command -v nowplaying-cli >/dev/null 2>&1; then
  npc=$(command -v nowplaying-cli)
elif [ -x /opt/homebrew/bin/nowplaying-cli ]; then
  npc=/opt/homebrew/bin/nowplaying-cli
elif [ -x /usr/local/bin/nowplaying-cli ]; then
  npc=/usr/local/bin/nowplaying-cli
else
  echo "toggle_play.sh: nowplaying-cli not found (brew install nowplaying-cli)" >&2
  exit 1
fi

exec "$npc" togglePlayPause
