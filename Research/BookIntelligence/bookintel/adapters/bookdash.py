"""Book Dash: contemporary South African picture books under CC BY 4.0.

bookdash.org (read 2026-10-08): every book is CC BY 4.0; "there is no
restriction on what people can do with the books, as long as they acknowledge
Book Dash and the original creators" (author, illustrator, designer, editor).
robots.txt allows everything.

The web reader shows each page as a designed image, so the words are inside the
pictures. The adapter downloads the page images; the analyst reads them and
transcribes the text into a page file; ingest then records the transcription as
`analyst_transcription`. Page boundaries are the publisher's (`publisher_layout`)
and every page comes with its illustration — the combination the rest of the
corpus lacks.
"""

from __future__ import annotations

import html
import re
from datetime import date

from .base import Fetcher, HttpClient

HOSTS = {"bookdash.org"}
BASE = "https://bookdash.org"
ROLES = {"writer": "author", "author": "author", "illustrator": "illustrator",
         "designer": "designer", "editor": "editor", "translator": "translator"}
LANGUAGES = {"english": "en", "afrikaans": "af", "isizulu": "zu", "isixhosa": "xh", "sesotho": "st",
             "setswana": "tn", "sepedi": "nso", "xitsonga": "ts", "tshivenda": "ve", "siswati": "ss",
             "isindebele": "nr", "french": "fr", "portuguese": "pt", "spanish": "es", "kiswahili": "sw"}
TARGET_WIDTH = 1536


def _text(fragment: str) -> str:
    return " ".join(html.unescape(re.sub(r"<[^>]+>", " ", fragment)).split())


def parse_list(page: str) -> list[str]:
    return sorted(set(re.findall(r'href="https://bookdash\.org/books/([a-z0-9-]+)/"', page)))


def _best_variant(anchor: str) -> str:
    """The srcset image nearest TARGET_WIDTH; the full-size link if none."""
    full = re.search(r'<a href="([^"]+)"', anchor).group(1)
    srcset = re.search(r'data-srcset="([^"]+)"', anchor)
    if not srcset:
        return full
    variants = []
    for part in srcset.group(1).split(","):
        bits = part.strip().split()
        if len(bits) == 2 and bits[1].endswith("w"):
            variants.append((int(bits[1][:-1]), bits[0]))
    wide = sorted(v for v in variants if v[0] >= TARGET_WIDTH * 0.75)
    return wide[0][1] if wide else full


def parse_book(page: str, slug: str) -> dict:
    title_match = re.search(r"<title>(.*?)</title>", page, re.S)
    title = _text(title_match.group(1)).replace(" - Book Dash", "").strip() if title_match else slug

    creators = []
    for name, role in re.findall(r'<span class="txt-bold">([^<]+)</span>\s*\(([^)]+)\)', page):
        creators.append({"name": html.unescape(name).strip(), "role": ROLES.get(role.strip().lower(), "author")})

    reader = page[page.find('id="read-book"'):] if 'id="read-book"' in page else ""
    reader = reader[: reader.find("</section>")] if "</section>" in reader else reader
    anchors = re.findall(r'<a href="https://bookdash\.org/wp-content/uploads/[^"]+"[^>]*>.*?</a>', reader, re.S)
    images = [_best_variant(a) for a in anchors]

    plain = _text(page)
    isbn = re.search(r"ISBN:\s*([0-9-]{10,17})", plain)
    created = re.search(r"Created at Book Dash[^:]*:[^,]*,\s*\d{1,2}\s+\w+\s+(\d{4})", plain)
    language = None
    after_files = plain.split("Download this book's source files", 1)
    if len(after_files) == 2:
        first_word = after_files[1].split()[0].lower() if after_files[1].split() else ""
        language = LANGUAGES.get(first_word)
    # The "Created at Book Dash" line is missing on many pages; the upload folder of
    # the page images (wp-content/uploads/YYYY/MM) then gives the web publication year.
    upload = re.search(r"/wp-content/uploads/(\d{4})/", images[0]) if images else None
    year, year_basis = (int(created.group(1)), "book_dash_event") if created else \
        ((int(upload.group(1)), "web_upload_year") if upload else (None, None))
    return {
        "slug": slug,
        "title": title,
        "creators": creators,
        "language": language or "en",
        "isbn": isbn.group(1) if isbn else None,
        "year": year,
        "year_basis": year_basis,
        "images": images,
        "page_url": f"{BASE}/books/{slug}/",
    }


class BookDashAdapter:
    name = "bookdash"

    def __init__(self, fetcher: Fetcher | None = None):
        self.http = HttpClient(HOSTS, fetcher)

    def list_books(self) -> list[str]:
        return parse_list(self.http.get(f"{BASE}/books/").decode("utf-8", "replace"))

    def book(self, slug: str) -> dict:
        if not re.fullmatch(r"[a-z0-9-]+", slug):
            raise ValueError(f"not a Book Dash slug: {slug!r}")
        return parse_book(self.http.get(f"{BASE}/books/{slug}/").decode("utf-8", "replace"), slug)

    def image(self, url: str) -> bytes:
        return self.http.get(url)

    @staticmethod
    def attribution(book: dict) -> str:
        names = ", ".join(f"{c['name']} ({c['role']})" for c in book["creators"])
        return (f"Originally published by Book Dash under a Creative Commons CC BY 4.0 licence. "
                f"This book can be read for free on www.bookdash.org and was created by {names}.")

    @classmethod
    def source_record(cls, book: dict, today: str | None = None) -> dict:
        return {
            "source_id": f"s_bookdash_{book['slug'].replace('-', '_')}",
            "url": book["page_url"],
            "kind": "authorized_full_text",
            "tier": "A",
            "rights": "open_license",
            "rights_detail": {
                "license": "CC BY 4.0",
                "attribution": cls.attribution(book),
                "verified_on": today or date.today().isoformat(),
            },
            "note": "Book Dash web reader page images; text transcribed by the analyst from the images.",
        }
