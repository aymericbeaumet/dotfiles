#!/bin/bash
# Universal Shift+Click handler for Alacritty hints.
# Routes: http(s) → opener, media files → opener, text/dirs → $EDITOR tmux popup.

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd) || exit 1
opener="$script_dir/open-url.sh"
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

# Only accept a numeric line number. $line is interpolated unquoted into the
# $EDITOR command run via `tmux display-popup -E` / `bash -lc` below, so reject
# anything non-numeric to prevent command injection if the calling hint source
# (currently the digit-only Alacritty regex) ever allows more in the line field.
[[ "$line" =~ ^[0-9]+$ ]] || line=""

# A relative path that does not exist under the pane's cwd was written
# relative to somewhere else (`../../scripts/toggle_sleep.sh` inside
# flash.toml, a path quoted from another checkout). Look for its trailing
# components: first up the pane's ancestors, then bounded under $HOME.
locate_relative() {
  local rel="$1" base="$2" suffix dir hit
  suffix="$rel"
  while [[ "$suffix" == ./* || "$suffix" == ../* ]]; do
    suffix="${suffix#./}"
    suffix="${suffix#../}"
  done
  [[ -n "$suffix" && "$suffix" != "$rel" ]] || return 1
  dir="$base"
  while [[ "$dir" == "$HOME"/* || "$dir" == "$HOME" ]]; do
    [[ -e "$dir/$suffix" ]] && {
      printf '%s\n' "$dir/$suffix"
      return 0
    }
    dir="${dir%/*}"
  done
  command -v fd >/dev/null 2>&1 || return 1
  hit=$(
    fd --hidden --full-path --absolute-path --max-depth 7 --max-results 50 \
      --exclude Library --exclude .git --exclude node_modules --exclude target \
      --exclude .cache --exclude .Trash --glob "**/$suffix" "$HOME" 2>/dev/null |
      awk '{ print length, $0 }' | sort -n | head -1 | cut -d' ' -f2-
  )
  [[ -n "$hit" ]] || return 1
  printf '%s\n' "$hit"
}

# Resolve relative paths against the active tmux pane's cwd
if [[ "$file" != /* ]]; then
  pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
  base="${pane_path:-$PWD}"
  if [[ -e "$base/$file" ]]; then
    file="$base/$file"
  elif located=$(locate_relative "$file" "$base"); then
    file="$located"
  else
    file="$base/$file"
  fi
fi

if [[ -n "${OPEN_HINT_DRY_RUN:-}" ]]; then
  printf '%s\n' "$file"
  exit 0
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
fi

# Alacritty launches hint commands as detached children of the terminal process,
# so they do not inherit TMUX from the active pane. The default tmux socket is
# still discoverable; target its most recently active attached client explicitly.
if command -v tmux >/dev/null 2>&1; then
  tmux_client=$(
    tmux list-clients -F '#{client_activity} #{client_name}' 2>/dev/null |
      sort -rn |
      awk 'NR == 1 { print $2; exit }'
  )
  if [[ -n "$tmux_client" ]]; then
    exec tmux display-popup -E -c "$tmux_client" -w 90% -h 90% "$cmd"
  fi
fi

exec bash -lc "$cmd"
