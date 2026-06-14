#!/bin/bash
# Universal Shift+Click handler for Alacritty hints.
# Routes: http(s) → opener, media files → opener, text/dirs → $EDITOR tmux popup.

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
opener="${DOTFILES:-$HOME/.dotfiles}/scripts/open-url.sh"
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
  exec "$opener" "$input"
fi

# Rust compiler error codes (E0001..E9999) → docs
if [[ "$input" =~ ^E[0-9]{4}$ ]]; then
  exec "$opener" "https://doc.rust-lang.org/error_codes/${input}.html"
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

if [[ ! -e "$file" ]]; then
  # Bare-domain fallback: aisstream.io, github.com/user/repo, etc.
  if [[ "$input" =~ ^([A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+)(/.*)?$ ]]; then
    host="${BASH_REMATCH[1]}"
    tld="${host##*.}"
    case "$tld" in
      sh | bash | zsh | fish | js | ts | jsx | tsx | py | rb | go | rs | md | txt | log | conf | toml | yaml | yml | json | html | htm | css | lua | c | h | cpp | hpp | swift | kt | java | php | sql | csv | xml | jpg | jpeg | png | gif | bmp | tiff | webp | svg | ico | heic | pdf | mp3 | mp4 | mkv | avi | mov | flac | wav | aac | ogg | m4a | m4v | webm | wmv | zip | tar | gz | bz2 | xz | 7z | dmg | iso | exe | bin | app | env | lock | sum | mod) ;;
      *) exec "$opener" "https://$input" ;;
    esac
  fi
  exit 0
fi

# Images → Preview (only for regular files)
if [[ -f "$file" ]]; then
  lower_file=$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')
  case "$lower_file" in
    *.png | *.jpg | *.jpeg | *.gif | *.bmp | *.tiff | *.webp | *.svg | *.ico | *.heic | *.pdf)
      exec "$opener" "$file"
      ;;
    *.mp3 | *.mp4 | *.mkv | *.avi | *.mov | *.flac | *.wav | *.aac | *.ogg | *.m4a | *.m4v | *.webm | *.wmv)
      exec "$opener" "$file"
      ;;
  esac
fi

# Everything else (text files and directories) → $EDITOR in tmux popup
cmd="$editor"
if [[ -f "$file" && -n "$line" ]]; then
  cmd+=" +$line"
fi
cmd+=" $(printf '%q' "$file")"
if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux display-popup -E -w 90% -h 90% "$cmd"
else
  exec bash -lc "$cmd"
fi
