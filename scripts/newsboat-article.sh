#!/usr/bin/env bash
# Show one article's text for the status-bar headline hover.
#
# Flash expands $FLASH_STATUS_LINK to the headline's item URL and passes it
# as the only argument. The resident list already holds
# ~/.cache/newsboat/flash-feed.db, so this reader only queries that file.
# A stored body is shown as text. A stub that is only a link is replaced
# with the original page aggr points at. The item URL itself is not the page.
set -euo pipefail

url=${1:-}
if [[ -z $url || $url == '$FLASH_STATUS_LINK' ]]; then
  printf 'article: this hover needs the article link\n' >&2
  exit 1
fi
case $url in
  http://* | https://*) ;;
  *)
    printf 'article: refusing a non-http article link\n' >&2
    exit 1
    ;;
esac
case $url in
  *[[:space:]]* | *\\* | *\"* | *\'* | *\`*)
    printf 'article: refusing an article link with quotes or spaces\n' >&2
    exit 1
    ;;
esac

cache_dir=$HOME/.cache/newsboat
source_db=$cache_dir/flash-feed.db
mkdir -p "$cache_dir"
# One file, replaced on every hover. A dismissed popup is killed, so a temp
# file would be left behind; the next hover overwrites this one.
page=$cache_dir/flash-article.txt

python3 - "$url" "$source_db" "$page" <<'PY'
import json
import re
import sqlite3
import sys
import urllib.error
import urllib.request
from html.parser import HTMLParser
from urllib.parse import urlparse

item_url, database, destination = sys.argv[1:]
FETCH_LIMIT = 1_000_000
STUB_TEXT = 400
USER_AGENT = "flash-article-hover"
SKIP_TAGS = {"script", "style", "noscript", "svg", "head", "nav", "footer", "form"}
VOID_TAGS = {
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link",
    "meta", "param", "source", "track", "wbr",
}
BLOCK_TAGS = {
    "p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "li", "tr", "blockquote",
    "pre", "section", "article", "br", "ul", "ol", "table", "figure",
}


class Text(HTMLParser):
    """Turn an HTML fragment into paragraphs. Link targets are dropped."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag in SKIP_TAGS:
            self.skip += 1
            return
        if self.skip or tag in VOID_TAGS and tag != "br":
            return
        if tag == "li":
            self.parts.append("\n- ")
        elif tag in BLOCK_TAGS:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in SKIP_TAGS and self.skip:
            self.skip -= 1
            return
        if self.skip:
            return
        if tag in BLOCK_TAGS and tag not in {"br", "li"}:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data)

    def text(self):
        raw = "".join(self.parts).replace("\r", "")
        raw = re.sub(r"[ \t]+\n", "\n", raw)
        raw = re.sub(r"[ \t]{2,}", " ", raw)
        raw = re.sub(r" *\n *", "\n", raw)
        raw = re.sub(r"\n{3,}", "\n\n", raw)
        return raw.strip()


class Region(HTMLParser):
    """Keep the first article or main, and a body fallback without chrome."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.in_body = False
        self.region_depth = 0
        self.region_tag = ""
        self.region = []
        self.body = []

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag == "body":
            self.in_body = True
        if tag in SKIP_TAGS:
            self.skip += 1
            return
        if tag in {"article", "main"} and self.region_depth == 0 and not self.region:
            self.region_depth = 1
            self.region_tag = tag
            return
        if self.region_depth and tag == self.region_tag:
            self.region_depth += 1
        if self.skip or tag in VOID_TAGS and tag != "br":
            return
        target = self.region if self.region_depth else self.body if self.in_body else None
        if target is None:
            return
        if tag == "li":
            target.append("\n- ")
        elif tag in BLOCK_TAGS:
            target.append("\n")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in SKIP_TAGS and self.skip:
            self.skip -= 1
            return
        if self.region_depth and tag == self.region_tag:
            self.region_depth -= 1
            if self.region_depth == 0:
                self.region.append("\n")
            return
        if self.skip:
            return
        target = self.region if self.region_depth else self.body if self.in_body else None
        if target is not None and tag in BLOCK_TAGS and tag not in {"br", "li"}:
            target.append("\n")

    def handle_data(self, data):
        if self.skip:
            return
        if self.region_depth:
            self.region.append(data)
        elif self.in_body:
            self.body.append(data)

    def text(self):
        chosen = self.region if len("".join(self.region).strip()) >= STUB_TEXT else self.body
        raw = "".join(chosen).replace("\r", "")
        raw = re.sub(r"[ \t]+\n", "\n", raw)
        raw = re.sub(r"[ \t]{2,}", " ", raw)
        raw = re.sub(r" *\n *", "\n", raw)
        raw = re.sub(r"\n{3,}", "\n\n", raw)
        return raw.strip()


def html_to_text(fragment):
    parser = Text()
    parser.feed(fragment)
    parser.close()
    return parser.text()


def page_text(document):
    parser = Region()
    parser.feed(document)
    parser.close()
    return parser.text()


def fetch(target):
    parsed = urlparse(target)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        return "", ""
    request = urllib.request.Request(target, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=12) as response:
        final = urlparse(response.geturl())
        if final.scheme not in {"http", "https"}:
            return "", ""
        kind = response.headers.get("content-type", "")
        payload = response.read(FETCH_LIMIT)
    match = re.search(r"charset=([\w.-]+)", kind, re.I)
    charset = match.group(1) if match else "utf-8"
    return payload.decode(charset, errors="replace"), kind.lower()


def readable(target):
    raw_github = re.match(
        r"^https://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$", target
    )
    if raw_github:
        user, repo, ref, path = raw_github.groups()
        path = path.split("?", 1)[0]
        target = f"https://raw.githubusercontent.com/{user}/{repo}/{ref}/{path}"
    try:
        body, kind = fetch(target)
    except (urllib.error.URLError, TimeoutError, ValueError):
        return ""
    if not body or kind.startswith(("image/", "audio/", "video/", "application/pdf")):
        return ""
    if "html" not in kind and not body.lstrip().lower().startswith("<!doctype html"):
        return body.strip()
    return page_text(body)


def original_of(aggr_html):
    match = re.search(
        r'"view":"article","data":\{"header":\{"path":"(?:\\.|[^"\\])*",'
        r'"url":"(?:\\.|[^"\\])*","link":"((?:\\.|[^"\\])*)"',
        aggr_html,
    )
    if not match:
        return ""
    link = json.loads(f'"{match.group(1)}"')
    parsed = urlparse(link)
    if parsed.scheme not in {"http", "https"} or not parsed.hostname:
        return ""
    host = parsed.hostname.lower().removeprefix("www.")
    if host in {"youtube.com", "youtu.be"}:
        return ""
    return link


def stored():
    if not database:
        return "", ""
    try:
        connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    except sqlite3.Error:
        return "", ""
    try:
        row = connection.execute(
            "SELECT title, content FROM rss_item "
            "WHERE url = ? AND deleted = 0 ORDER BY pubDate DESC LIMIT 1",
            (item_url,),
        ).fetchone()
    except sqlite3.Error:
        return "", ""
    finally:
        connection.close()
    if row is None:
        return "", ""
    return row[0] or "", row[1] or ""


title, content = stored()
body = html_to_text(content) if content else ""
if len(body) < STUB_TEXT:
    try:
        aggr_html, _kind = fetch(item_url)
    except (urllib.error.URLError, TimeoutError, ValueError):
        aggr_html = ""
    original = original_of(aggr_html) if aggr_html else ""
    if original and original != item_url:
        fetched = readable(original)
        if len(fetched) > len(body):
            body = fetched

lines = [title.strip(), ""]
if body:
    lines.append(body)
else:
    lines.append("This item has no article text.")
with open(destination, "w", encoding="utf-8") as handle:
    handle.write("\n".join(lines).rstrip() + "\n")
PY

if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
  # Match Flash's other hover pagers: an empty prompt row, mouse wheel, no
  # tilde gutter. The page is a file so less can scroll the whole article.
  less -R --mouse --wheel-lines=3 -~ -Ps$'\e[27m' "$page"
else
  cat "$page"
fi
