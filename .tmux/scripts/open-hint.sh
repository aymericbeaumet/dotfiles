#!/bin/bash
# Universal Shift+Click handler for Alacritty hints.
# Routes: http(s) → browser, image files → Preview, text/dirs → $EDITOR tmux popup.

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
editor="${EDITOR:-nvim}"

input="$1"

# Expand leading ~
input="${input/#\~/$HOME}"

# Expand leading $VAR or ${VAR}
if [[ "$input" =~ ^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?(/.*)?$ ]]; then
  varname="${BASH_REMATCH[1]}"
  varvalue="${!varname}"
  if [[ -n "$varvalue" ]]; then
    input="${varvalue}${BASH_REMATCH[2]}"
  fi
fi

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

# Images → Preview (only for regular files)
if [[ -f "$file" ]]; then
  case "${file,,}" in
    *.png|*.jpg|*.jpeg|*.gif|*.bmp|*.tiff|*.webp|*.svg|*.ico|*.heic|*.pdf)
      exec open -a Preview "$file"
      ;;
    *.mp3|*.mp4|*.mkv|*.avi|*.mov|*.flac|*.wav|*.aac|*.ogg|*.m4a|*.m4v|*.webm|*.wmv)
      exec open -a VLC "$file"
      ;;
  esac
fi

# Everything else (text files and directories) → $EDITOR in tmux popup
cmd="$editor"
if [[ -f "$file" && -n "$line" ]]; then
  cmd+=" +$line"
fi
cmd+=" $(printf '%q' "$file")"
exec tmux display-popup -E -w 90% -h 90% "$cmd"
