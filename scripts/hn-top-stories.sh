#!/bin/sh
# Hacker News top stories for the Flash status bar's #{cycle:…} token.
# Emits ONE story per line: a clickable `#[link=…]title#[nolink]` run linking to
# the HN discussion, followed when space permits by the article domain in
# parentheses linking to HN's submissions for that domain, then a `↗` linking
# straight to the article (omitted for self/Ask/Show posts that carry no external
# URL). The bar reels through them. The static "HN" label links to HN from the
# template, not here. Network work is cached with a TTL and refreshed in the
# background so the bar never blocks on curl.

DOTFILES_SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" 2>/dev/null && pwd) || exit 1
. "$DOTFILES_SCRIPT_DIR/lib.sh"

now=$(date +%s)
cache_root="${TMPDIR:-/tmp}/flash-hn-top-stories"
# rendered-v5: each marked-up carousel row also carries its percent-encoded
# hover preview, keeping the visible story and popup body in one atomic value.
rendered_cache="$cache_root/rendered-v5.txt"
preview_cache_dir="$cache_root/previews-v1"
refresh_lock="$cache_root/refresh.lock"
preview_helper="$DOTFILES_SCRIPT_DIR/hn-article-preview.py"
: "${HN_STORIES_COUNT:=8}"
: "${HN_RENDER_TTL_SECONDS:=300}"
: "${HN_REFRESH_LOCK_SECONDS:=180}"
# Keep the title itself below the bar's 80-column token cap; the formatter owns
# final truncation of the optional domain and arrow suffix.
: "${HN_TITLE_MAX_CHARS:=160}"
: "${HN_PREVIEW_MAX_CHARS:=280}"

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

fetch_top_ids() {
  if [ -n "${HN_TEST_TOP_IDS:-}" ]; then
    printf '%s\n' "$HN_TEST_TOP_IDS"
    return
  fi
  curl -fsS --max-time 5 \
    'https://hacker-news.firebaseio.com/v0/topstories.json' 2>/dev/null |
    jq -r ".[:${HN_STORIES_COUNT}] // [] | .[]" 2>/dev/null
}

fetch_item() {
  id=$1
  if [ -n "${HN_TEST_ITEMS_DIR:-}" ] && [ -f "$HN_TEST_ITEMS_DIR/$id.json" ]; then
    command cat "$HN_TEST_ITEMS_DIR/$id.json"
    return
  fi
  curl -fsS --max-time 5 \
    "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null
}

extract_preview() {
  command -v python3 >/dev/null 2>&1 || return 1
  [ -f "$preview_helper" ] || return 1
  python3 "$preview_helper" --max-chars "$HN_PREVIEW_MAX_CHARS"
}

article_preview() {
  id=$1
  url=$2
  cache="$preview_cache_dir/$id.txt"
  preview=

  if [ -n "${HN_TEST_ARTICLE_HTML_FILE:-}" ]; then
    if [ -f "$HN_TEST_ARTICLE_HTML_FILE" ]; then
      preview=$(extract_preview <"$HN_TEST_ARTICLE_HTML_FILE" 2>/dev/null) || preview=
    fi
  elif [ "${HN_SKIP_EXTERNAL_PREVIEWS:-}" != 1 ]; then
    mkdir -p "$cache_root" 2>/dev/null
    article_tmp="$cache_root/article-${id}.$$.html"
    if curl -fsSL --compressed --connect-timeout 2 --max-time 4 \
      -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/537.36 Safari/537.36' \
      --max-filesize 1048576 "$url" >"$article_tmp" 2>/dev/null; then
      preview=$(extract_preview <"$article_tmp" 2>/dev/null) || preview=
    fi
    if [ -z "$preview" ]; then
      # Some publishers reject non-browser clients outright. Jina Reader is
      # a bounded fallback for the same public URL and returns article
      # markdown; the helper removes its provenance header before truncating.
      reader_url="https://r.jina.ai/$url"
      if curl -fsSL --compressed --connect-timeout 2 --max-time 8 \
        --max-filesize 2097152 "$reader_url" >"$article_tmp" 2>/dev/null; then
        preview=$(extract_preview <"$article_tmp" 2>/dev/null) || preview=
      fi
    fi
    rm -f "$article_tmp"
  fi

  if [ -n "$preview" ]; then
    mkdir -p "$preview_cache_dir" 2>/dev/null
    preview_tmp="$preview_cache_dir/$id.$$.tmp"
    if printf '%s' "$preview" >"$preview_tmp"; then
      mv "$preview_tmp" "$cache"
    else
      rm -f "$preview_tmp"
    fi
    printf '%s' "$preview"
  elif [ -s "$cache" ]; then
    command cat "$cache"
  fi
}

flash_escape() {
  # Dynamic values are parsed as Flash markup. Double `#` so article text
  # containing a marker-looking `#[…]` sequence stays literal.
  printf '%s' "$1" | sed 's/#/##/g'
}

# Fetch the top N stories and render one marked-up line each. Titles are
# HTML-entity-decoded, whitespace-collapsed, and loosely length-capped; the
# bar owns the final width via `#{=N…:…}`.
render_stories() {
  command -v curl >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  ids=$(fetch_top_ids)
  [ -n "$ids" ] || return 1

  out=
  for id in $ids; do
    item=$(fetch_item "$id")
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
    display_title=$(flash_escape "$title")

    # Article URL powers the optional domain + ↗ suffix; self/Ask/Show posts have
    # none, so they keep only the HN-discussion title link.
    url=$(printf '%s' "$item" | jq -r '.url // empty' 2>/dev/null)
    domain=$(printf '%s' "$item" |
      jq -r '
        (.url // "") as $url
        | if $url == "" then ""
          else
            try (
              $url
              | capture("^[A-Za-z][A-Za-z0-9+.-]*://(?<host>[^/:?#]+)")
              | .host
              | sub("^www\\."; "")
            ) catch ""
          end
      ' 2>/dev/null)

    preview=
    if [ -n "$url" ]; then
      preview=$(article_preview "$id" "$url")
    else
      item_text=$(printf '%s' "$item" | jq -r '.text // empty' 2>/dev/null)
      if [ -n "$item_text" ]; then
        preview=$(printf '%s' "$item_text" | extract_preview 2>/dev/null) || preview=
      fi
    fi
    [ -n "$preview" ] || preview='Article or OP text unavailable'

    popup_title=$(flash_escape "$title")
    popup_preview=$(flash_escape "$preview")
    popup_body=$(printf '#[fg=colour178,bold]%s#[default]\n%s' "$popup_title" "$popup_preview")
    popup_encoded=$(url_encode "$popup_body")

    line="#[popup=inline:${popup_encoded}]#[link=https://news.ycombinator.com/item?id=${id}]#[shrink]${display_title}#[noshrink]#[nolink]"
    if [ -n "$url" ]; then
      if [ -n "$domain" ]; then
        line="${line} #[link=https://news.ycombinator.com/from?site=${domain}]#[fg=colour245](${domain})#[nolink] #[link=${url}]#[fg=colour178]↗#[fg=colour245]#[nolink]"
      else
        line="${line} #[link=${url}]#[fg=colour178]↗#[fg=colour245]#[nolink]"
      fi
    fi
    line="${line}#[nopopup]"
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

# On a cold cache, publish story rows promptly and let the normal background
# refresh fill external article previews. Self-post bodies are already in the
# HN item response and remain available immediately.
HN_SKIP_EXTERNAL_PREVIEWS=1
rendered=$(render_stories) || exit 0
mkdir -p "$cache_root" 2>/dev/null
printf '%s' "$rendered" >"$rendered_cache" 2>/dev/null || true
start_refresh
printf '%s' "$rendered"
exit 0
