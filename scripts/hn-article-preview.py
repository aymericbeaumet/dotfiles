#!/usr/bin/env python3
"""Extract a short, single-line article preview from HTML on stdin."""

from __future__ import annotations

import argparse
import html
import re
import sys
from html.parser import HTMLParser


SKIPPED_TAGS = {"script", "style", "noscript", "svg", "template"}


class ArticleTextParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._skip_depth = 0
        self._article_depth = 0
        self._main_depth = 0
        self.article: list[str] = []
        self.main: list[str] = []
        self.body: list[str] = []
        self.description = ""

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        values = {key.lower(): value or "" for key, value in attrs}
        if tag == "meta":
            kind = (values.get("name") or values.get("property") or "").lower()
            if not self.description and kind in {"description", "og:description"}:
                self.description = values.get("content", "")
        if tag in SKIPPED_TAGS:
            self._skip_depth += 1
        if tag == "article":
            self._article_depth += 1
        if tag == "main":
            self._main_depth += 1

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in SKIPPED_TAGS and self._skip_depth:
            self._skip_depth -= 1
        if tag == "article" and self._article_depth:
            self._article_depth -= 1
        if tag == "main" and self._main_depth:
            self._main_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._skip_depth:
            return
        self.body.append(data)
        if self._article_depth:
            self.article.append(data)
        if self._main_depth:
            self.main.append(data)


def normalized(value: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def truncated(value: str, limit: int) -> str:
    value = normalized(value)
    if len(value) <= limit:
        return value
    head = value[: limit - 1].rstrip()
    word_boundary = head.rfind(" ")
    if word_boundary >= max(1, limit * 3 // 5):
        head = head[:word_boundary].rstrip()
    return head + "…"


def extract(source: str, limit: int) -> str:
    # Jina Reader is the fallback for publisher pages that reject ordinary
    # HTTP clients. Its response has a small provenance header followed by
    # the article markdown; never expose that header as if it were content.
    reader_marker = "\nMarkdown Content:\n"
    if reader_marker in source:
        source = source.split(reader_marker, 1)[1]
    parser = ArticleTextParser()
    parser.feed(source)
    parser.close()
    candidates = (parser.article, parser.main, [parser.description], parser.body)
    for chunks in candidates:
        value = normalized(" ".join(chunks))
        if value:
            return truncated(value, limit)
    return ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-chars", type=int, default=280)
    args = parser.parse_args()
    if not 40 <= args.max_chars <= 4_000:
        return 2
    preview = extract(sys.stdin.read(), args.max_chars)
    if not preview:
        return 1
    sys.stdout.write(preview)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
