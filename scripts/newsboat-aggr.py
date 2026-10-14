#!/usr/bin/env python3
"""Rewrite the aggr RSS feed so newsboat can show a source column.

aggr's article list shows the publisher before "via" (github.com/omlahore,
youtube.com/@t3dotgg). The RSS feed only carries that as the original URL, and
a YouTube watch URL does not name the channel, so the channel is recovered
from the item path. The result replaces dc:creator, which is newsboat's author
column.
"""

import sys
import xml.etree.ElementTree as ET
from urllib.parse import urlparse

DC_CREATOR = "{http://purl.org/dc/elements/1.1/}creator"
ATOM_LINK = "{http://www.w3.org/2005/Atom}link"

# Hosts where the first path segment is the publisher, matching aggr's source label.
ACCOUNT_HOSTS = {"github.com", "gitlab.com", "codeberg.org"}


def host_of(url):
    host = (urlparse(url).hostname or "").lower()
    if host.startswith("www."):
        host = host[4:]
    return host


def youtube_channel(item_link):
    marker = "/items/"
    if marker not in item_link:
        return ""
    slug = item_link.split(marker, 1)[1].split("/", 1)[0]
    prefix = "youtube-com-"
    if slug.startswith(prefix) and len(slug) > len(prefix):
        return "youtube.com/@" + slug[len(prefix) :]
    return ""


def source_of(via, item_link):
    """Publisher label: the site, or host/account on a shared host."""
    target = via or item_link
    host = host_of(target)
    if not host:
        return ""
    path = [segment for segment in urlparse(target).path.split("/") if segment]
    if host == "youtube.com" and (not path or path[0] in {"watch", "shorts", "live", "embed", "playlist"}):
        channel = youtube_channel(item_link)
        if channel:
            return channel
    if host == "youtube.com" and path and path[0].startswith("@"):
        return f"youtube.com/{path[0]}"
    if host in ACCOUNT_HOSTS and path:
        return f"{host}/{path[0]}"
    return host


def via_url(item):
    for link in item.findall(ATOM_LINK):
        if link.attrib.get("rel") == "via" and link.attrib.get("href"):
            return link.attrib["href"]
    return ""


def rewrite(root):
    for item in root.findall(".//item"):
        label = source_of(via_url(item), item.findtext("link") or "")
        if not label:
            continue
        creators = item.findall(DC_CREATOR)
        if creators:
            creators[0].text = label
            for extra in creators[1:]:
                item.remove(extra)
        else:
            element = ET.Element(DC_CREATOR)
            element.text = label
            item.append(element)


def main():
    raw = sys.stdin.buffer.read()
    try:
        root = ET.fromstring(raw)
    except ET.ParseError:
        sys.stdout.buffer.write(raw)
        return
    rewrite(root)
    ET.register_namespace("atom", "http://www.w3.org/2005/Atom")
    ET.register_namespace("content", "http://purl.org/rss/1.0/modules/content/")
    ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")
    ET.ElementTree(root).write(sys.stdout.buffer, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
