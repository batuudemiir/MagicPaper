"""Internet Archive scans of public-domain books, through IA's documented APIs.

- Discovery: `advancedsearch.php` (JSON).
- Item record: `/metadata/<id>`.
- Text: the item's `_djvu.xml` — OCR per scanned leaf, so page boundaries are
  the printed book's (`original_scan`).
- Pictures: `/download/<id>/page/n<leaf>_w800.jpg`, fetched only on request
  (`book-agent images`) so the analyst can look at them.

IA terms (archive.org/about/terms, read 2026-10-08): access is for scholarship and
research; do not burden its servers; use must be non-infringing; cite the Archive
in any publication that relies on it. So the gate here is strict:

- the edition's publication year must make it public domain in the US
  (published at least 96 years ago: 1930 or earlier in 2026), and
- the item must not be in a controlled-lending collection (`inlibrary`,
  `printdisabled`, `lendinglibrary`, …) or marked access-restricted or dark.

An uploader's licence claim alone is not trusted ("to the extent you trust the
declaration and declarer", in IA's own words); it is recorded, not relied on.

Library scans and user uploads are different evidence. A library or IA scanning
centre scan (`scanningcenter` set, e.g. NYPL, UC Libraries) photographs the
printed book, so its leaves are the printed pages. A user upload ("HTML5
Uploader") can be anything — the 2026-10-08 pilot met a "1901 Peter Rabbit"
that was a new ebook with an editor's note, footnotes and its own layout. An
upload's pages therefore count as `reconstructed` and its rights basis says the
year is the uploader's claim, until the analyst looks at the images and confirms
it reproduces the printed book (`ingest ia <id> --confirm-scan`).
"""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from datetime import date
from urllib.parse import quote, urlencode

from .base import AccessRefused, Fetcher, HttpClient

HOSTS = {"archive.org", ".archive.org"}   # data nodes: ia*.us., dn*.ca., dn*.eu.archive.org
BASE = "https://archive.org"
# Controlled digital lending: in-copyright books lent one reader at a time.
RESTRICTED_COLLECTIONS = {"inlibrary", "printdisabled", "lendinglibrary", "browserlending"}
US_PUBLIC_DOMAIN_LAG_YEARS = 96
LANGUAGES = {"eng": "en", "english": "en", "tur": "tr", "turkish": "tr", "ger": "de", "deu": "de",
             "fre": "fr", "fra": "fr", "spa": "es", "ita": "it", "dut": "nl", "nld": "nl",
             "swe": "sv", "nor": "no", "dan": "da", "fin": "fi", "rus": "ru", "por": "pt"}


def us_public_domain_cutoff(today: date | None = None) -> int:
    """Last publication year in the US public domain (1930 during 2026)."""
    return (today or date.today()).year - US_PUBLIC_DOMAIN_LAG_YEARS


def _first(value):
    return value[0] if isinstance(value, list) and value else value


def publication_year(metadata: dict) -> int | None:
    for key in ("year", "date"):
        match = re.search(r"\b(1[4-9]\d\d|20\d\d)\b", str(_first(metadata.get(key)) or ""))
        if match:
            return int(match.group(1))
    return None


def is_institutional_scan(metadata: dict) -> bool:
    """Scanned by IA or a partner library, not uploaded by a user."""
    return bool(metadata.get("scanningcenter"))


def eligibility(item: dict, today: date | None = None) -> tuple[bool, str]:
    """(eligible, reason). Every refusal names its rule."""
    meta = item.get("metadata") or {}
    if item.get("is_dark"):
        return False, "item is dark"
    if str(meta.get("access-restricted-item", "")).lower() == "true":
        return False, "item is access-restricted"
    collections = meta.get("collection") or []
    collections = {collections} if isinstance(collections, str) else set(collections)
    blocked = collections & RESTRICTED_COLLECTIONS
    if blocked:
        return False, f"controlled-lending collection: {', '.join(sorted(blocked))}"
    year = publication_year(meta)
    cutoff = us_public_domain_cutoff(today)
    if year is None:
        return False, "no publication year: public-domain status cannot be shown"
    if year > cutoff:
        return False, f"published {year}; US public domain reaches {cutoff}"
    return True, f"published {year} (US public domain: {cutoff} or earlier)"


def parse_djvu(content: bytes) -> list[dict]:
    """Leaves in scan order: [{leaf, text}] with OCR words joined per line."""
    root = ET.fromstring(content)
    leaves = []
    for index, obj in enumerate(root.iter("OBJECT")):
        lines = []
        for line in obj.iter("LINE"):
            words = [w.text.strip() for w in line.iter("WORD") if w.text and w.text.strip()]
            if words:
                lines.append(" ".join(words))
        leaves.append({"leaf": index, "text": "\n".join(lines)})
    return leaves


def leaves_to_pages(leaves: list[dict], min_words: int = 3) -> list[dict]:
    """Every leaf carrying text becomes a page; picture-only leaves are attached to
    the text page before them (leading ones to the first page).

    Pairing by position is a guess — a picture can face the text before or after
    it — so the leaves are recorded and the analyst confirms by looking.
    """
    pages: list[dict] = []
    pending: list[int] = []
    for leaf in leaves:
        words = len(leaf["text"].split())
        if words >= min_words:
            pages.append({"page": len(pages) + 1, "spread": False, "page_range": [len(pages) + 1] * 2,
                          "text": leaf["text"], "leaf": leaf["leaf"],
                          "illustration_leaves": pending, "illustration_notes": []})
            pending = []
        elif pages:
            pages[-1]["illustration_leaves"].append(leaf["leaf"])
        else:
            pending.append(leaf["leaf"])
    for page in pages:
        page["illustration_notes"] = [f"scan leaf {n} (picture or blank — view with `book-agent images`)"
                                      for n in page["illustration_leaves"]]
    return pages


class InternetArchiveAdapter:
    name = "internet_archive"

    def __init__(self, fetcher: Fetcher | None = None):
        self.http = HttpClient(HOSTS, fetcher)

    def search(self, query: str, language: str | None = None, rows: int = 50) -> list[dict]:
        cutoff = us_public_domain_cutoff()
        q = f"({query}) AND mediatype:texts AND year:[1400 TO {cutoff}]"
        if language:
            q += f" AND language:({language})"
        q += " AND NOT collection:(" + " OR ".join(sorted(RESTRICTED_COLLECTIONS)) + ")"
        params = [("q", q), ("rows", str(rows)), ("output", "json")]
        params += [("fl[]", f) for f in ("identifier", "title", "creator", "year", "date", "language", "collection")]
        payload = json.loads(self.http.get(f"{BASE}/advancedsearch.php?{urlencode(params)}").decode("utf-8"))
        return [{"identifier": d.get("identifier"), "title": _first(d.get("title")),
                 "creator": _first(d.get("creator")), "year": d.get("year") or _first(d.get("date")),
                 "language": _first(d.get("language")), "page_url": f"{BASE}/details/{d.get('identifier')}"}
                for d in payload.get("response", {}).get("docs", [])]

    def item(self, identifier: str) -> dict:
        return json.loads(self.http.get(f"{BASE}/metadata/{quote(identifier)}").decode("utf-8"))

    def candidate(self, identifier: str) -> dict:
        item = self.item(identifier)
        if not item.get("metadata"):
            raise AccessRefused(f"{identifier}: no such item")
        meta = item["metadata"]
        eligible, reason = eligibility(item)
        djvu = next((f["name"] for f in item.get("files", []) if f.get("format") == "Djvu XML"), None)
        creators = meta.get("creator") or []
        creators = [creators] if isinstance(creators, str) else creators
        language = str(_first(meta.get("language")) or "").lower()
        return {
            "identifier": identifier,
            "title": " ".join(str(_first(meta.get("title")) or "").split()),
            "creators": [{"name": re.sub(r",?\s*\d{4}-(\d{4})?\.?$", "", c).strip(), "role": "author"}
                         for c in creators],
            "year": publication_year(meta),
            "language": LANGUAGES.get(language, language if len(language) == 2 else "other"),
            "eligible": eligible,
            "eligibility_reason": reason,
            "uploader_licence": meta.get("licenseurl"),
            "collections": meta.get("collection"),
            "institutional_scan": is_institutional_scan(meta),
            "scan_provenance": (f"scanned at {meta.get('scanningcenter')}"
                                + (f" from {_first(meta.get('contributor'))}" if meta.get("contributor") else "")
                                if is_institutional_scan(meta) else "user upload (not an IA or library scan)"),
            "djvu_file": djvu,
            "page_url": f"{BASE}/details/{identifier}",
        }

    def fetch_djvu(self, candidate: dict) -> bytes:
        if not candidate["eligible"]:
            raise AccessRefused(f"{candidate['identifier']}: {candidate['eligibility_reason']}")
        if not candidate["djvu_file"]:
            raise AccessRefused(f"{candidate['identifier']}: no page-level OCR (Djvu XML) in this item")
        return self.http.get(f"{BASE}/download/{quote(candidate['identifier'])}/{quote(candidate['djvu_file'])}")

    def page_image(self, identifier: str, leaf: int) -> bytes:
        return self.http.get(f"{BASE}/download/{quote(identifier)}/page/n{int(leaf)}_w800.jpg")

    @staticmethod
    def source_record(candidate: dict, today: str | None = None) -> dict:
        return {
            "source_id": f"s_ia_{re.sub(r'[^0-9a-z]+', '_', candidate['identifier'].lower())}",
            "url": candidate["page_url"],
            "kind": "authorized_full_text",
            "tier": "A",
            "rights": "public_domain",
            "rights_detail": {
                "jurisdiction": "US",
                "basis": (f"Internet Archive {candidate['scan_provenance']}; {candidate['eligibility_reason']}"
                          + ("" if candidate.get("institutional_scan") else
                             " — the year is the uploader's claim")),
                "uploader_licence_claim": candidate.get("uploader_licence"),
                "verified_on": today or date.today().isoformat(),
                "terms_note": "IA access is for research; cite the Internet Archive in any publication.",
            },
            "note": "Internet Archive scan. Text is OCR per scanned leaf; page boundaries are the printed book's.",
        }
