#!/bin/bash
# Universal Shift+Click handler for Alacritty hints.
# Routes: http(s) → browser, image files → Preview, text files → nvim tmux popup.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

input="$1"

# Expand leading ~
input="${input/#\~/$HOME}"

# URLs → browser
if [[ "$input" =~ ^https?:// ]]; then
  exec open "$input"
fi

# Strip file:// URI prefix
input="${input#file://}"

# Split path:line:col
file="${input%%:*}"
rest="${input#"$file"}"
rest="${rest#:}"
line="${rest%%:*}"

# Resolve relative paths against the active tmux pane's cwd
if [[ "$file" != /* ]]; then
  pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
  if [[ -n "$pane_path" ]]; then
    file="$pane_path/$file"
  fi
fi

[[ -e "$file" ]] || exit 0

# Images → Preview
case "${file,,}" in
  *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff|*.webp|*.svg|*.ico|*.heic|*.pdf)
    exec open -a Preview "$file"
    ;;
  *.mp3|*.mp4|*.mkv|*.avi|*.mov|*.flac|*.wav|*.aac|*.ogg|*.m4a|*.m4v|*.webm|*.wmv)
    exec open -a VLC "$file"
    ;;
esac

# Everything else → nvim in tmux popup
[[ -f "$file" ]] || exit 0
args=()
if [[ -n "$line" ]]; then
  args+=("+$line")
fi
args+=("$file")
exec tmux display-popup -E -w 90% -h 90% "nvim ${args[*]}"
