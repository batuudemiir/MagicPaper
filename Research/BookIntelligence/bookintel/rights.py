"""The rights model: what may be fetched, stored and claimed for a source.

These rules are enforced by the validator, not by convention. A record that
breaks one fails `book-agent validate`, and nothing downstream reads data that
has not validated.
"""

from __future__ import annotations

# Rights under which page text may live in data/pages (and so in git).
TEXT_STORABLE = {"public_domain", "open_license", "licensed"}

# Page boundaries good enough to say why a page ends where it ends.
PAGE_TURN_BOUNDARIES = {"original_scan", "publisher_layout"}


def can_store_text(rights: str) -> bool:
    return rights in TEXT_STORABLE


def page_turn_eligible(page_boundary_source: str | None) -> bool:
    return page_boundary_source in PAGE_TURN_BOUNDARIES


def completeness(rights: str, all_pages_judged: bool) -> str:
    """`full` only when the whole text was legally read and every page judged."""
    return "full" if can_store_text(rights) and all_pages_judged else "partial"


def rights_errors(source: dict) -> list[str]:
    """Checks the rights detail a source must carry for its rights class."""
    errors: list[str] = []
    rights = source.get("rights")
    detail = source.get("rights_detail") or {}
    sid = source.get("source_id", "?")
    if rights == "public_domain" and not detail.get("jurisdiction"):
        errors.append(f"{sid}: public_domain needs rights_detail.jurisdiction (public domain is per country)")
    if rights == "public_domain" and not detail.get("basis"):
        errors.append(f"{sid}: public_domain needs rights_detail.basis (e.g. 'published before 1930', 'author died 1943')")
    if rights == "open_license":
        if not detail.get("license"):
            errors.append(f"{sid}: open_license needs rights_detail.license (e.g. CC BY 4.0)")
        if not detail.get("attribution"):
            errors.append(f"{sid}: open_license needs rights_detail.attribution")
    if rights == "licensed" and not detail.get("licence_reference"):
        errors.append(f"{sid}: licensed needs rights_detail.licence_reference (who granted it, where it is kept)")
    if rights in TEXT_STORABLE and not detail.get("verified_on"):
        errors.append(f"{sid}: rights_detail.verified_on is required when text is stored")
    return errors
