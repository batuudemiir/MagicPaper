"""A readable HTML copy of a generated Markdown page, for a reader without a Markdown viewer.

Only the small Markdown subset the CLI itself writes: headings, bullets, paragraphs,
tables, **bold**, `code`, [links](…) (link targets are dropped; the pages are read offline).
"""

from __future__ import annotations

import html
import re
from pathlib import Path

from .store import write_if_changed

_CSS = """:root{--ink:#2a2238;--paper:#fbf8f3;--line:#e3dccf;--accent:#6a47b8;--code:#efe9df}
@media (prefers-color-scheme:dark){:root{--ink:#ece6f5;--paper:#1d1826;--line:#3a3348;--accent:#b9a3ec;--code:#2c2538}}
body{font-family:-apple-system,Helvetica,sans-serif;max-width:820px;margin:40px auto;padding:0 16px;
line-height:1.6;color:var(--ink);background:var(--paper)}
h1,h2{color:var(--accent)}h2{border-bottom:1px solid var(--line);padding-bottom:4px;margin-top:32px}
code{background:var(--code);padding:1px 5px;border-radius:4px;font-size:.9em;overflow-wrap:anywhere}
li{margin:6px 0}table{border-collapse:collapse;width:100%}
td,th{border:1px solid var(--line);padding:6px;text-align:left;vertical-align:top}
hr{margin:48px 0;border:0;border-top:2px dashed var(--line)}"""


def _inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    return re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)


def convert(markdown: str) -> str:
    out: list[str] = []
    in_list = in_table = False
    for line in markdown.splitlines():
        s = line.rstrip()
        if s.startswith("<!--"):
            continue
        if s.startswith("|"):
            cells = [c.strip() for c in s.strip("|").split("|")]
            if all(re.fullmatch(r":?-+:?", c) for c in cells if c):
                continue
            tag = "td" if in_table else "th"
            if not in_table:
                out.append("<table>")
                in_table = True
            out.append("<tr>" + "".join(f"<{tag}>{_inline(c)}</{tag}>" for c in cells) + "</tr>")
            continue
        if in_table:
            out.append("</table>")
            in_table = False
        bullet = re.match(r"^\s*[-*] (.*)", s)
        if bullet:
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append(f"<li>{_inline(bullet.group(1))}</li>")
            continue
        if in_list:
            out.append("</ul>")
            in_list = False
        heading = re.match(r"^(#{1,4}) (.*)", s)
        if heading:
            level = len(heading.group(1))
            out.append(f"<h{level}>{_inline(heading.group(2))}</h{level}>")
        elif s.strip():
            out.append(f"<p>{_inline(s)}</p>")
    if in_list:
        out.append("</ul>")
    if in_table:
        out.append("</table>")
    return "\n".join(out)


def write(path: Path, title: str, markdown_parts: list[str]) -> Path:
    body = "<hr>".join(convert(part) for part in markdown_parts)
    page = (f'<!doctype html><html lang="tr"><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f"<title>{html.escape(title)}</title><style>{_CSS}</style><body>{body}</body></html>\n")
    write_if_changed(path, page)
    return path
