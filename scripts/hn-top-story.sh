#!/bin/sh
# Hacker News top story for the Flash status bar.
# Renders the "HN" label + top-story title, plus the start of the OP's
# self-post text (if any) in italics, all wrapped in a clickable link to
# the post. The caller supplies the leading separator and owns the overall
# length limit via Flash's `#{=N…:…}` ellipsis-truncation operator, so this
# script emits the full (lightly capped) text and lets the bar trim it.

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

now=$(date +%s)
cache_root="${TMPDIR:-/tmp}/tmux-hn-top-story"
# story-v3.tsv: id + score + title + OP post text (4 TSV columns).
# rendered-v4.last: the rendered string with `#[link=…]`/`#[italics]`
# markers — bumped to v4 for the split links ("HN" → the front page, the
# title/post → this story's discussion page).
rendered_cache="$cache_root/rendered-v4.last"
story_cache="$cache_root/story-v3.tsv"
story_backoff="$cache_root/story.next"
refresh_lock="$cache_root/refresh.lock"
: "${HN_RENDER_TTL_SECONDS:=300}"
: "${HN_STORY_TTL_SECONDS:=300}"
: "${HN_STORY_RETRY_SECONDS:=120}"
: "${HN_REFRESH_LOCK_SECONDS:=60}"
# Flash caps the visible width; this is only a sanity bound on the raw post
# text so the cached/piped string never balloons on a long Ask HN body.
: "${HN_POST_MAX_CHARS:=200}"

cache_is_fresh() {
  file=${1:-}
  ttl=${2:-0}
  [ -e "$file" ] || return 1
  mtime=$(file_mtime "$file") || return 1
  [ $((now - mtime)) -lt "$ttl" ]
}

script_path() {
  case "$0" in
    /*) printf '%s' "$0" ;;
    *)
      dir=$(dirname "$0")
      base=$(basename "$0")
      dir=$(cd "$dir" 2>/dev/null && pwd) || return
      printf '%s/%s' "$dir" "$base"
      ;;
  esac
}

write_cache_file() {
  file=${1:-}
  contents=${2:-}
  [ -n "$file" ] || return 1
  [ -n "$contents" ] || return 1

  tmp="${file}.$$"
  mkdir -p "${file%/*}" 2>/dev/null
  if printf '%s' "$contents" >"$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

start_refresh() {
  [ "${HN_REFRESH:-}" = 1 ] && return
  mkdir -p "$cache_root" 2>/dev/null

  if [ -d "$refresh_lock" ] && ! cache_is_fresh "$refresh_lock" "$HN_REFRESH_LOCK_SECONDS"; then
    rmdir "$refresh_lock" 2>/dev/null || true
  fi

  if mkdir "$refresh_lock" 2>/dev/null; then
    path=$(script_path) || {
      rmdir "$refresh_lock" 2>/dev/null || true
      return
    }

    (
      trap 'rmdir "$refresh_lock" 2>/dev/null || true' EXIT INT TERM
      HN_REFRESH=1 sh "$path" >/dev/null 2>&1
    ) &
  fi
}

# Fetch the current top story as "id<TAB>score<TAB>title<TAB>post". The post
# column is the OP's self-text (empty for link submissions) with HTML tags
# stripped, common entities decoded, and whitespace collapsed to single
# spaces so it stays on one TSV line. Honours a TTL cache plus a backoff
# window so a flaky network doesn't hammer the API.
live_top_story() {
  command -v curl >/dev/null 2>&1 || return
  command -v jq >/dev/null 2>&1 || return

  if cache_is_fresh "$story_cache" "$HN_STORY_TTL_SECONDS"; then
    cat "$story_cache"
    return
  fi

  if [ -f "$story_backoff" ]; then
    next_retry=$(cat "$story_backoff" 2>/dev/null || printf 0)
    if [ "${next_retry:-0}" -gt "$now" ]; then
      [ -f "$story_cache" ] && cat "$story_cache"
      return
    fi
  fi

  top_id=$(curl -fsS --max-time 5 \
    'https://hacker-news.firebaseio.com/v0/topstories.json' 2>/dev/null |
    jq -r '.[0] // empty' 2>/dev/null)

  story=
  if [ -n "$top_id" ]; then
    story=$(curl -fsS --max-time 5 \
      "https://hacker-news.firebaseio.com/v0/item/${top_id}.json" 2>/dev/null |
      jq -r '
        select(.title != null)
        | (
            (.text // "")
            | gsub("<p>"; " ")
            | gsub("<[^>]*>"; "")
            | gsub("&#x27;"; ([39] | implode))
            | gsub("&#x2F;"; "/")
            | gsub("&quot;"; "\"")
            | gsub("&gt;"; ">")
            | gsub("&lt;"; "<")
            | gsub("&amp;"; "&")
            | gsub("\\s+"; " ")
            | gsub("^ +| +$"; "")
          ) as $post
        | [ (.id | tostring), (.score // 0 | tostring), .title, $post ]
        | @tsv
      ' 2>/dev/null)
  fi

  if [ -n "$story" ]; then
    mkdir -p "$cache_root" 2>/dev/null
    if write_cache_file "$story_cache" "$story"; then
      rm -f "$story_backoff"
    fi
    printf '%s' "$story"
  else
    mkdir -p "$cache_root" 2>/dev/null
    printf '%s' "$((now + HN_STORY_RETRY_SECONDS))" >"$story_backoff" 2>/dev/null || true
    [ -f "$story_cache" ] && cat "$story_cache"
  fi
}

format_story() {
  story=${1:-}
  [ -n "$story" ] || return 1

  id=$(printf '%s\n' "$story" | awk -F '\t' 'NR==1 {print $1}')
  title=$(printf '%s\n' "$story" | awk -F '\t' 'NR==1 {print $3}')
  post=$(printf '%s\n' "$story" | awk -F '\t' 'NR==1 {print $4}')
  [ -n "$title" ] || return 1

  # The "HN" label + title; the OP post (if any) follows in italics. Flash
  # owns the total length budget (`#{=N…:…}`), so cap the post only loosely
  # here to keep the piped/cached string bounded.
  post=$(printf '%s' "$post" | awk -v max="$HN_POST_MAX_CHARS" '
    { if (length($0) > max) printf "%s", substr($0, 1, max); else printf "%s", $0 }')

  # Two separate link runs (URLs are whitespace/comma-free, as the
  # `#[link=…]` parser requires): the "HN" label opens the Hacker News
  # front page, while the title — and the OP post, if any — opens this
  # story's own discussion page. The title link is dropped when the id is
  # missing, leaving the text plain (the "HN" link still works).
  hn='#[link=https://news.ycombinator.com]#[fg=colour178]HN#[fg=colour245]#[nolink]'

  article="$title"
  if [ -n "$post" ]; then
    article="${article} #[italics]${post}#[noitalics]"
  fi
  if [ -n "$id" ] && [ "$id" != "null" ]; then
    article="#[link=https://news.ycombinator.com/item?id=${id}]${article}#[nolink]"
  fi

  printf '%s %s' "$hn" "$article"
}

render_story() {
  story=$(live_top_story)
  status=$(format_story "$story") || return 1
  [ -n "$status" ] || return 1
  printf '%s' "$status"
}

if [ "${HN_REFRESH:-}" != 1 ] && [ -s "$rendered_cache" ]; then
  if ! cache_is_fresh "$rendered_cache" "$HN_RENDER_TTL_SECONDS"; then
    start_refresh
  fi
  cat "$rendered_cache"
  exit 0
fi

status=$(render_story)
if [ -n "$status" ]; then
  write_cache_file "$rendered_cache" "$status" || true
  printf '%s' "$status"
elif [ -s "$rendered_cache" ]; then
  cat "$rendered_cache"
fi
exit 0
