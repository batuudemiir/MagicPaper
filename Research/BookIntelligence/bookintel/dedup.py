"""Work / edition resolution.

Evidence is counted per WORK. A reprint, a translation, an audiobook or a second
URL for the same file is an edition of a work and adds nothing to a claim's
support. When a match is uncertain the records are NOT merged: the pair goes to
the review list, because a wrong merge silently deletes evidence and a wrong
split silently doubles it, and only the second is visible later.
"""

from __future__ import annotations

import re
import unicodedata
from difflib import SequenceMatcher

LEADING_ARTICLES = {
    "en": ("the ", "a ", "an "),
    "de": ("der ", "die ", "das ", "ein ", "eine "),
    "fr": ("le ", "la ", "les ", "l'", "un ", "une "),
    "es": ("el ", "la ", "los ", "las ", "un ", "una "),
}

# External identifiers that, when equal, prove two records are one work.
WORK_IDS = ("openlibrary_work", "wikidata", "oclc_work")
# Identifiers that prove two records are one edition.
EDITION_IDS = ("gutenberg", "isbn", "internet_archive", "storyweaver")


def fold(text: str) -> str:
    """Casefold, strip diacritics, keep letters/digits/spaces.

    Turkish ı/İ are mapped first so `Işık` and `ışık` fold to the same key.
    """
    text = text.replace("İ", "i").replace("ı", "i")
    decomposed = unicodedata.normalize("NFKD", text.casefold())
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    cleaned = re.sub(r"[^0-9a-z' ]+", " ", stripped)
    return re.sub(r"\s+", " ", cleaned).strip()


def normalize_title(title: str, language: str = "en") -> str:
    folded = fold(title)
    # Subtitles and series tags vary between editions; the main title does not.
    folded = re.split(r"\s(?:or|ya da|veya)\s", folded)[0]
    for article in LEADING_ARTICLES.get(language, ()):
        if folded.startswith(article):
            folded = folded[len(article):]
            break
    return folded.replace("'", "").strip()


def creator_key(name: str) -> str:
    """Surname key: `Potter, Beatrix` and `Beatrix Potter` both give `potter`."""
    if "," in name:
        name = name.split(",")[0]
        parts = fold(name).split(" ")
        return parts[-1] if parts and parts[-1] else ""
    parts = fold(name).split(" ")
    return parts[-1] if parts and parts[-1] else ""


def slug(text: str) -> str:
    return re.sub(r"[^0-9a-z]+", "_", fold(text)).strip("_")[:60]


def work_id_for(title: str, primary_creator: str, language: str) -> str:
    return f"w_{slug(normalize_title(title, language))}_{creator_key(primary_creator)}".rstrip("_")


def _primary_creator(record: dict) -> str:
    for role in ("author", "reteller", "illustrator"):
        for creator in record.get("creators", []):
            if creator.get("role") == role:
                return creator.get("name", "")
    return ""


def match(candidate: dict, works: list[dict]) -> tuple[str, str | None, list[str]]:
    """Resolve a candidate work against known works.

    Returns (decision, work_id, reasons) where decision is:
      "same"      — an existing work; add the candidate as an edition of it
      "new"       — no plausible match
      "ambiguous" — plausible but unproven; goes to the review list
    """
    cand_ids = candidate.get("external_ids", {})
    for work in works:
        ids = work.get("external_ids", {})
        for key in WORK_IDS + EDITION_IDS:
            if cand_ids.get(key) and cand_ids.get(key) == ids.get(key):
                return "same", work["work_id"], [f"shared identifier {key}"]

    language = candidate.get("original_language", "en")
    cand_title = normalize_title(candidate.get("title", ""), language)
    cand_creator = creator_key(_primary_creator(candidate))
    ambiguous: list[tuple[str, str]] = []
    for work in works:
        title = normalize_title(work.get("title", ""), work.get("original_language", "en"))
        creator = creator_key(_primary_creator(work))
        same_creator = bool(cand_creator) and cand_creator == creator
        if title == cand_title and same_creator:
            return "same", work["work_id"], ["same normalized title and creator"]
        similarity = SequenceMatcher(None, title, cand_title).ratio()
        if title == cand_title and not same_creator:
            ambiguous.append((work["work_id"], "same title, different creator"))
        elif similarity >= 0.88 and same_creator:
            ambiguous.append((work["work_id"], f"similar title ({similarity:.2f}), same creator"))
    if ambiguous:
        return "ambiguous", ambiguous[0][0], [reason for _, reason in ambiguous]
    return "new", None, []
