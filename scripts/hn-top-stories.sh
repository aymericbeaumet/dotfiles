#!/bin/sh
# Hacker News top stories for the Flash status bar's #{cycle:…} token.
# Emits ONE story per line: a clickable `#[link=…]title#[nolink]` run linking to
# the HN discussion, followed by a `↗` linking straight to the article (omitted
# for self/Ask/Show posts that carry no external URL). The bar reels through
# them. The static "HN" label lives in the template, not here. Network work is
# cached with a TTL and refreshed in the background so the bar never blocks on
# curl.

DOTFILES_SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

now=$(date +%s)
cache_root="${TMPDIR:-/tmp}/flash-hn-top-stories"
# rendered-v1: the multi-line, marked-up output (one story per line).
rendered_cache="$cache_root/rendered-v1.txt"
refresh_lock="$cache_root/refresh.lock"
: "${HN_STORIES_COUNT:=8}"
: "${HN_RENDER_TTL_SECONDS:=300}"
: "${HN_REFRESH_LOCK_SECONDS:=60}"
# Capped below the bar's 80-col width so the trailing " ↗" always fits.
: "${HN_TITLE_MAX_CHARS:=78}"

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

# Fetch the top N stories and render one marked-up line each. Titles are
# HTML-entity-decoded, whitespace-collapsed, and loosely length-capped; the
# bar owns the final width via `#{=N…:…}`.
render_stories() {
  command -v curl >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  ids=$(curl -fsS --max-time 5 \
    'https://hacker-news.firebaseio.com/v0/topstories.json' 2>/dev/null |
    jq -r ".[:${HN_STORIES_COUNT}] // [] | .[]" 2>/dev/null)
  [ -n "$ids" ] || return 1

  out=
  for id in $ids; do
    item=$(curl -fsS --max-time 5 \
      "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null)
    [ -n "$item" ] || continue

    title=$(printf '%s' "$item" |
      jq -r '
        select(.title != null)
        | (.title
            | gsub("&#x27;"; ([39] | implode))
            | gsub("&#x2F;"; "/")
            | gsub("&quot;"; "\"")
            | gsub("&gt;"; ">")
            | gsub("&lt;"; "<")
            | gsub("&amp;"; "&")
            | gsub("\\s+"; " ")
            | gsub("^ +| +$"; ""))
      ' 2>/dev/null)
    [ -n "$title" ] || continue
    title=$(printf '%s' "$title" | awk -v max="$HN_TITLE_MAX_CHARS" \
      '{ if (length($0) > max) printf "%s…", substr($0, 1, max - 1); else printf "%s", $0 }')

    # Article URL powers the trailing ↗; self/Ask/Show posts have none → no arrow.
    url=$(printf '%s' "$item" | jq -r '.url // empty' 2>/dev/null)

    line="#[link=https://news.ycombinator.com/item?id=${id}]${title}#[nolink]"
    [ -n "$url" ] && line="${line} #[link=${url}]#[fg=colour178]↗#[fg=colour245]#[nolink]"
    out="${out}${line}
"
  done

  [ -n "$out" ] || return 1
  printf '%s' "$out"
}

# Background refresh writes the cache and exits silently.
if [ "${HN_REFRESH:-}" = 1 ]; then
  rendered=$(render_stories) || exit 0
  mkdir -p "$cache_root" 2>/dev/null
  tmp="${rendered_cache}.$$"
  if printf '%s' "$rendered" >"$tmp"; then
    mv "$tmp" "$rendered_cache"
  else
    rm -f "$tmp"
  fi
  exit 0
fi

# Foreground: serve the cache immediately, kicking a background refresh when
# stale. Fall back to a synchronous fetch only when there's no cache at all.
if [ -s "$rendered_cache" ]; then
  cache_is_fresh "$rendered_cache" "$HN_RENDER_TTL_SECONDS" || start_refresh
  cat "$rendered_cache"
  exit 0
fi

rendered=$(render_stories) || exit 0
mkdir -p "$cache_root" 2>/dev/null
printf '%s' "$rendered" >"$rendered_cache" 2>/dev/null || true
printf '%s' "$rendered"
exit 0
