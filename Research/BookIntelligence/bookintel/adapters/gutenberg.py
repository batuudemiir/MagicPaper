"""Project Gutenberg, through the channels it publishes for programs.

- Discovery: the offline catalog feed (`cache/epub/feeds/pg_catalog.csv.gz`),
  downloaded at most once every CATALOG_MAX_AGE_DAYS and searched locally.
- Metadata and rights: the per-book RDF record (`cache/epub/N/pgN.rdf`).
- Text: `cache/epub/N/pgN.txt`.

Not used: gutendex.com, whose robots.txt disallows `/books/` for every agent,
and Gutenberg's site search, which its robots.txt disallows.

Only books whose RDF says "Public domain in the USA." are fetched. That is
Gutenberg's assertion for the US; elsewhere (life + 70 years) it can differ,
so the jurisdiction is recorded as US and nothing more is claimed.
"""

from __future__ import annotations

import csv
import gzip
import io
import time
import xml.etree.ElementTree as ET
from datetime import date
from pathlib import Path

from .base import AccessRefused, Fetcher, HttpClient

HOSTS = {"www.gutenberg.org"}
BASE = "https://www.gutenberg.org"
CATALOG_URL = f"{BASE}/cache/epub/feeds/pg_catalog.csv.gz"
CATALOG_MAX_AGE_DAYS = 30
PUBLIC_DOMAIN_US = "public domain in the usa"

NS = {
    "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "dcterms": "http://purl.org/dc/terms/",
    "pgterms": "http://www.gutenberg.org/2009/pgterms/",
    "marcrel": "http://id.loc.gov/vocabulary/relators/",
}


def _int(text: str | None) -> int | None:
    try:
        return int(text) if text else None
    except ValueError:
        return None


def parse_rdf(content: bytes, gutenberg_id: int) -> dict:
    root = ET.fromstring(content)
    book = root.find("pgterms:ebook", NS)
    if book is None:
        raise ValueError(f"gutenberg {gutenberg_id}: RDF has no ebook record")

    def text(path: str) -> str | None:
        node = book.find(path, NS)
        return node.text.strip() if node is not None and node.text else None

    def agents(tag: str, role: str) -> list[dict]:
        out = []
        for agent in book.findall(f"{tag}/pgterms:agent", NS):
            name = agent.find("pgterms:name", NS)
            out.append({"name": name.text.strip() if name is not None and name.text else "",
                        "role": role,
                        "birth_year": _int(getattr(agent.find("pgterms:birthdate", NS), "text", None)),
                        "death_year": _int(getattr(agent.find("pgterms:deathdate", NS), "text", None))})
        return out

    creators = agents("dcterms:creator", "author") + agents("marcrel:ill", "illustrator") \
        + agents("marcrel:trl", "translator")
    languages = [v.text for v in book.findall("dcterms:language/rdf:Description/rdf:value", NS) if v.text]
    subjects = [v.text for v in book.findall("dcterms:subject/rdf:Description/rdf:value", NS) if v.text]
    shelves = [v.text for v in book.findall("pgterms:bookshelf/rdf:Description/rdf:value", NS) if v.text]
    rights = text("dcterms:rights") or ""
    return {
        "gutenberg_id": gutenberg_id,
        "title": (text("dcterms:title") or "").replace("\n", " "),
        "creators": creators,
        "language": languages[0] if languages else "other",
        "subjects": subjects,
        "bookshelves": shelves,
        "download_count": _int(text("pgterms:downloads")),
        "rights_statement": rights,
        "public_domain_us": rights.strip().lower().rstrip(".") == PUBLIC_DOMAIN_US,
        "text_url": f"{BASE}/cache/epub/{gutenberg_id}/pg{gutenberg_id}.txt",
        "page_url": f"{BASE}/ebooks/{gutenberg_id}",
    }


def search_catalog(rows: list[dict], query: str, language: str | None = None,
                   shelf: str | None = None) -> list[dict]:
    tokens = [t for t in query.casefold().split() if t]
    found = []
    for row in rows:
        if row.get("Type") != "Text":
            continue
        if language and language not in [l.strip() for l in row.get("Language", "").split(";")]:
            continue
        if shelf and shelf.casefold() not in row.get("Bookshelves", "").casefold():
            continue
        haystack = " ".join(row.get(k, "") for k in ("Title", "Authors", "Subjects", "Bookshelves")).casefold()
        if all(t in haystack for t in tokens):
            found.append({
                "gutenberg_id": int(row["Text#"]),
                "title": " ".join(row.get("Title", "").split()),
                "authors": row.get("Authors", ""),
                "language": row.get("Language", ""),
                "issued": row.get("Issued", ""),
                "bookshelves": row.get("Bookshelves", ""),
                "page_url": f"{BASE}/ebooks/{row['Text#']}",
            })
    return found


class GutenbergAdapter:
    name = "gutenberg"

    def __init__(self, cache_dir: Path | None = None, fetcher: Fetcher | None = None):
        self.http = HttpClient(HOSTS, fetcher)
        self.cache_dir = cache_dir

    def catalog(self) -> list[dict]:
        raw = None
        path = self.cache_dir / "catalog" / "pg_catalog.csv.gz" if self.cache_dir else None
        if path and path.exists() and time.time() - path.stat().st_mtime < CATALOG_MAX_AGE_DAYS * 86400:
            raw = path.read_bytes()
        if raw is None:
            raw = self.http.get(CATALOG_URL)
            if path:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(raw)
        text = gzip.decompress(raw).decode("utf-8")
        return list(csv.DictReader(io.StringIO(text)))

    def search(self, query: str, language: str | None = None, shelf: str | None = None) -> list[dict]:
        return search_catalog(self.catalog(), query, language, shelf)

    def book(self, gutenberg_id: int) -> dict:
        gid = int(gutenberg_id)
        return parse_rdf(self.http.get(f"{BASE}/cache/epub/{gid}/pg{gid}.rdf"), gid)

    def fetch_text(self, candidate: dict) -> bytes:
        if not candidate.get("public_domain_us"):
            raise AccessRefused(f"gutenberg {candidate.get('gutenberg_id')}: rights are "
                                f"{candidate.get('rights_statement')!r}, not public domain in the USA")
        return self.http.get(candidate["text_url"])

    @staticmethod
    def source_record(candidate: dict, today: str | None = None) -> dict:
        return {
            "source_id": f"s_gutenberg_{candidate['gutenberg_id']}",
            "url": candidate["page_url"],
            "kind": "authorized_full_text",
            "tier": "A",
            "rights": "public_domain",
            "rights_detail": {
                "jurisdiction": "US",
                "basis": f"Project Gutenberg RDF: {candidate.get('rights_statement')!r}",
                "verified_on": today or date.today().isoformat(),
            },
            "note": "Project Gutenberg plain text. Page boundaries are not preserved.",
        }
