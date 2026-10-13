"""Turn acquired text into pages, and say how much the page boundaries can be trusted.

Two inputs:

- A page file a person prepared from a page-structured source (a scan, a
  CC-licensed picture book). Boundaries are real.

      # comments before the first marker are ignored
      === page 1 ===
      Once there was a small fox.
      [illustration: the fox at the edge of a dark wood]
      [image: cache/images/e_x/p02.jpg]
      === spread 2-3 ===
      [no text]
      ...

`[image: …]` points at the page's picture; `[no text]` marks a page that is
deliberately wordless (a transcription with neither is unfinished).
`[leaf: 6]` / `[leaf: 6, 7]` ties a page to scan leaves (first = the text leaf).
`[skip: reason]` drops a page that is not story — cover, title, copyright,
credits, an editor's note — and the remaining pages are renumbered 1..n.

- Plain text (e.g. Project Gutenberg). Boundaries are reconstructed: either one
  page per illustration marker, or paragraphs packed to a target length. Good
  for language metrics, never for page-turn claims.
"""

from __future__ import annotations

import re

from . import text_metrics as tm

_MARKER = re.compile(r"^===\s*(page|spread)\s+(\d+)(?:\s*-\s*(\d+))?\s*===\s*$", re.IGNORECASE)
_ILLUSTRATION_LINE = re.compile(r"^\s*\[illustration:\s*(.*?)\]\s*$", re.IGNORECASE)
_IMAGE_LINE = re.compile(r"^\s*\[image:\s*(.*?)\]\s*$", re.IGNORECASE)
_NO_TEXT = re.compile(r"^\s*\[no text\]\s*$", re.IGNORECASE)
_LEAF_LINE = re.compile(r"^\s*\[leaf:\s*([\d,\s]+)\]\s*$", re.IGNORECASE)
_DRAFT_LINE = re.compile(r"^\s*\[draft\]\s*$", re.IGNORECASE)
_SKIP_LINE = re.compile(r"^\s*\[skip(?::\s*(.*?))?\]\s*$", re.IGNORECASE)
_GUTENBERG_START = re.compile(r"^\*\*\*\s*START OF (THE|THIS) PROJECT GUTENBERG.*$", re.IGNORECASE | re.MULTILINE)
_GUTENBERG_END = re.compile(r"^\*\*\*\s*END OF (THE|THIS) PROJECT GUTENBERG.*$", re.IGNORECASE | re.MULTILINE)
_GUTENBERG_ILLUSTRATION = re.compile(r"\[Illustration[^\]]*\]", re.IGNORECASE | re.DOTALL)


class SegmentationError(ValueError):
    pass


def parse_page_file(content: str) -> list[dict]:
    pages: list[dict] = []
    current: dict | None = None
    for line in content.splitlines():
        marker = _MARKER.match(line)
        if marker:
            kind, start, end = marker.group(1).lower(), int(marker.group(2)), marker.group(3)
            current = {
                "page": start,
                "spread": kind == "spread",
                "page_range": [start, int(end) if end else start],
                "lines": [],
                "illustration_notes": [],
                "images": [],
                "wordless": False,
                "leaves": [],
                "skip": None,
                "draft": False,
            }
            pages.append(current)
            continue
        if current is None:
            if line.strip() and not line.lstrip().startswith("#"):
                raise SegmentationError("text before the first '=== page N ===' marker")
            continue
        illustration = _ILLUSTRATION_LINE.match(line)
        image = _IMAGE_LINE.match(line)
        leaf = _LEAF_LINE.match(line)
        skip = _SKIP_LINE.match(line)
        if _DRAFT_LINE.match(line):
            current["draft"] = True
        elif leaf:
            current["leaves"] = [int(n) for n in re.findall(r"\d+", leaf.group(1))]
        elif skip:
            current["skip"] = (skip.group(1) or "not story").strip()
        elif illustration:
            current["illustration_notes"].append(illustration.group(1).strip())
        elif image:
            current["images"].append(image.group(1).strip())
        elif _NO_TEXT.match(line):
            current["wordless"] = True
        else:
            current["lines"].append(line)

    if not pages:
        raise SegmentationError("no '=== page N ===' markers found")
    expected = 1
    for page in pages:
        if page["page"] != expected:
            raise SegmentationError(f"page numbering jumps to {page['page']}, expected {expected}")
        expected = page["page_range"][1] + 1

    kept = [p for p in pages if not p["skip"]]
    if not kept:
        raise SegmentationError("every page is marked [skip]")
    out = []
    number = 1
    for p in kept:
        width = p["page_range"][1] - p["page_range"][0]
        page = {
            "page": number,
            "spread": p["spread"],
            "page_range": [number, number + width],
            "text": "\n".join(p["lines"]).strip(),
            "illustration_notes": p["illustration_notes"],
            "images": p["images"],
            "wordless": p["wordless"],
            "draft": p["draft"],
        }
        number += width + 1
        if p["leaves"]:
            page["leaf"] = p["leaves"][0]
            page["illustration_leaves"] = p["leaves"][1:]
        out.append(page)
    return out


def skipped(content: str) -> list[dict]:
    """The pages a page file marks [skip], with their reasons (for the record)."""
    found, current = [], None
    for line in content.splitlines():
        marker = _MARKER.match(line)
        if marker:
            current = int(marker.group(2))
            continue
        skip = _SKIP_LINE.match(line)
        if skip and current is not None:
            found.append({"file_page": current, "reason": (skip.group(1) or "not story").strip()})
    return found


def untranscribed(pages: list[dict]) -> list[int]:
    """Pages with neither text nor an explicit `[no text]`, or still marked [draft]."""
    return [p["page"] for p in pages if p.get("draft") or (not p["text"] and not p.get("wordless"))]


def strip_gutenberg(content: str) -> str:
    start = _GUTENBERG_START.search(content)
    end = _GUTENBERG_END.search(content)
    body = content[start.end() if start else 0:end.start() if end else len(content)]
    return body.strip()


def _paragraphs(text: str) -> list[str]:
    blocks = re.split(r"\n\s*\n", text)
    return [re.sub(r"\s*\n\s*", " ", b).strip() for b in blocks if b.strip()]


def reconstruct_pages(text: str, mode: str = "illustrations", target_words: int = 40) -> list[dict]:
    """Plain text → pages.

    mode="illustrations": a new page starts after every [Illustration] marker.
    Many Gutenberg picture books keep one marker per original picture, which is
    the closest thing to the printed page a plain text has.
    mode="pack": paragraphs packed greedily up to ~target_words.
    """
    if mode == "illustrations" and _GUTENBERG_ILLUSTRATION.search(text):
        chunks = _GUTENBERG_ILLUSTRATION.split(text)
        groups = [" ".join(_paragraphs(chunk)) for chunk in chunks]
        groups = [g for g in groups if tm.word_count(g) > 0]
    else:
        groups = []
        current: list[str] = []
        for paragraph in _paragraphs(_GUTENBERG_ILLUSTRATION.sub("", text)):
            size = sum(tm.word_count(p) for p in current)
            if current and size + tm.word_count(paragraph) > target_words * 1.3:
                groups.append(" ".join(current))
                current = []
            current.append(paragraph)
        if current:
            groups.append(" ".join(current))
    if not groups:
        raise SegmentationError("no text left after stripping")
    return [
        {"page": i, "spread": False, "page_range": [i, i], "text": g, "illustration_notes": []}
        for i, g in enumerate(groups, start=1)
    ]
