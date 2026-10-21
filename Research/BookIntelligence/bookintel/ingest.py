"""Acquire → segment → dedup → store. One entry point per acquisition route.

Ingest never judges a book. It records where the text came from, what may be
kept, how far its page boundaries can be trusted, and which work it belongs to.
"""

from __future__ import annotations

from pathlib import Path

from . import dedup, runs, segment
from .adapters import manual
from .adapters.bookdash import BookDashAdapter
from .adapters.gutenberg import GutenbergAdapter
from .adapters.internet_archive import InternetArchiveAdapter, leaves_to_pages, parse_djvu
from .rights import can_store_text
from .store import Store


class IngestError(RuntimeError):
    pass


def _resolve_work(store: Store, candidate: dict, force_work: str | None, force_new: bool) -> tuple[str, str]:
    """Returns (decision, work_id). Ambiguity stops the ingest and is queued for review."""
    works = store.all("work")
    if force_work:
        if store.get("work", force_work) is None:
            raise IngestError(f"unknown work {force_work}")
        return "same", force_work
    decision, work_id, reasons = ("new", None, []) if force_new else dedup.match(candidate, works)
    if decision == "ambiguous":
        store.add_review({"candidate_title": candidate["title"],
                          "candidate_ids": candidate.get("external_ids", {}),
                          "possible_work": work_id, "reasons": reasons})
        raise IngestError(f"'{candidate['title']}' may be {work_id} ({'; '.join(reasons)}). "
                          "Queued in data/review/dedup.json — re-run with --work <id> or --new-work.")
    if decision == "new":
        primary = next((c["name"] for c in candidate["creators"] if c["role"] in ("author", "reteller")),
                       candidate["creators"][0]["name"] if candidate["creators"] else "")
        work_id = dedup.work_id_for(candidate["title"], primary, candidate["original_language"])
        if store.get("work", work_id) is not None:
            work_id = f"{work_id}_{len(works) + 1}"
    return decision, work_id


def _new_work(candidate: dict, work_id: str, age_band: str | None, basis: str | None) -> dict:
    return {
        "work_id": work_id,
        "title": candidate["title"],
        "creators": [{"name": c["name"], "role": c["role"]} for c in candidate["creators"]
                     if c["role"] != "translator"],
        "first_publication_year": candidate.get("year"),
        "original_language": candidate["original_language"],
        "external_ids": candidate.get("external_ids", {}),
        "classification": {"age_band": age_band, "age_band_basis": basis if age_band else None,
                           "story_types": [], "structures": [], "tones": [], "visual_style": []},
        "protagonist": None,
        "evidence": {"popularity": [], "quality": [], "adult_interpretation": []},
        "content_flags": [],
        "age_suitability": {"magicpaper": None, "notes": None},
        "editions": [],
        "rejected": None,
        "created_at": runs.now(),
    }


def _store_all(store: Store, candidate: dict, source: dict, edition: dict, pages: list[dict],
               raw: bytes, raw_suffix: str, force_work: str | None, force_new: bool,
               age_band: str | None, basis: str | None) -> dict:
    decision, work_id = _resolve_work(store, candidate, force_work, force_new)
    edition["work_id"] = work_id
    edition["pages_count"] = len(pages)
    edition["content_sha256"] = manual.sha256(raw)

    raw_path = store.cache_path("raw", f"{edition['edition_id']}{raw_suffix}")
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw_path.write_bytes(raw)
    edition["cache_file"] = str(raw_path.relative_to(store.ws.cache))

    work = store.get("work", work_id) or _new_work(candidate, work_id, age_band, basis)
    if edition["edition_id"] not in work["editions"]:
        work["editions"].append(edition["edition_id"])
    for key, value in candidate.get("external_ids", {}).items():
        work.setdefault("external_ids", {}).setdefault(key, value)

    store.put("source", source)
    store.put("edition", edition)
    store.put("work", work)
    store.put_segmented(edition["edition_id"], {
        "edition_id": edition["edition_id"],
        "page_boundary_source": edition["page_boundary_source"],
        "text_storable": can_store_text(source["rights"]),
        "pages": pages,
    })
    runs.log(store, "sources_added", source["source_id"])
    runs.log(store, "editions_added", edition["edition_id"])
    if decision == "new":
        runs.log(store, "works_added", work_id)
    return {"decision": decision, "work_id": work_id, "edition_id": edition["edition_id"], "pages": len(pages)}


def ingest_gutenberg(store: Store, gutenberg_id: int, adapter: GutenbergAdapter | None = None,
                     mode: str = "illustrations", age_band: str | None = None, basis: str | None = None,
                     force_work: str | None = None, force_new: bool = False) -> dict:
    adapter = adapter or GutenbergAdapter(store.cache_path())
    candidate = adapter.book(gutenberg_id)
    try:
        raw = adapter.fetch_text(candidate)
    except Exception as error:
        runs.log(store, "failures", {"url": candidate.get("page_url"), "reason": str(error)})
        raise
    text = raw.decode("utf-8", "replace")
    pages = segment.reconstruct_pages(segment.strip_gutenberg(text), mode=mode)
    translated = any(c["role"] == "translator" for c in candidate["creators"])
    work_candidate = {
        "title": candidate["title"],
        "creators": [{"name": c["name"], "role": c["role"]} for c in candidate["creators"]],
        "original_language": candidate["language"] if not translated else "other",
        "external_ids": {"gutenberg": str(gutenberg_id)},
    }
    source = GutenbergAdapter.source_record(candidate, runs.today())
    source["retrieved_at"] = runs.now()
    edition = {
        "edition_id": f"e_gutenberg_{gutenberg_id}",
        "source_id": source["source_id"],
        "title": candidate["title"],
        "language": candidate["language"],
        "is_translation": translated,
        "format": "ebook",
        "page_boundary_source": "reconstructed",
        "text_origin": "plain_text_edition",
        "segmentation": {"mode": mode},
        "external_ids": {"gutenberg": str(gutenberg_id)},
        "signals": {"gutenberg_download_count": candidate.get("download_count"),
                    "gutenberg_subjects": candidate.get("subjects", []),
                    "observed_on": runs.today()},
    }
    return _store_all(store, work_candidate, source, edition, pages, raw, ".txt",
                      force_work, force_new, age_band, basis)


def ingest_manual(store: Store, path: Path, *, url: str, rights: str, rights_detail: dict,
                  kind: str, tier: str, title: str, creators: list[dict], language: str,
                  page_boundary_source: str, year: int | None = None, original_language: str | None = None,
                  edition_id: str | None = None, external_ids: dict | None = None,
                  age_band: str | None = None, basis: str | None = None,
                  force_work: str | None = None, force_new: bool = False,
                  text_origin: str = "publisher_text") -> dict:
    if not can_store_text(rights):
        raise IngestError(f"rights {rights!r} do not allow keeping a text; register the source with "
                          "`source add` and analyse without ingesting the text")
    raw = Path(path).read_bytes()
    pages = segment.parse_page_file(raw.decode("utf-8"))
    missing = segment.untranscribed(pages)
    if missing:
        raise IngestError(f"pages without text or [no text]: {missing}")
    eid = manual.edition_id_for(Path(path), edition_id)
    source = {
        "source_id": "s_" + eid[2:],
        "url": url,
        "kind": kind,
        "tier": tier,
        "rights": rights,
        "rights_detail": {**rights_detail, "verified_on": rights_detail.get("verified_on") or runs.today()},
        "retrieved_at": runs.now(),
        "note": "Registered by hand with stated provenance.",
    }
    candidate = {"title": title, "creators": creators, "year": year,
                 "original_language": original_language or language,
                 "external_ids": external_ids or {}}
    edition = {
        "edition_id": eid,
        "source_id": source["source_id"],
        "title": title,
        "language": language,
        "is_translation": bool(original_language and original_language != language),
        "format": "scan" if page_boundary_source == "original_scan" else "web",
        "page_boundary_source": page_boundary_source,
        "text_origin": text_origin,
        "external_ids": external_ids or {},
    }
    return _store_all(store, candidate, source, edition, pages, raw, Path(path).suffix or ".txt",
                      force_work, force_new, age_band, basis)


def add_metadata_work(store: Store, *, title: str, creators: list[dict], language: str,
                      year: int | None, age_band: str | None, basis: str | None,
                      external_ids: dict | None = None, force_new: bool = False) -> dict:
    """A book we cannot read in full: metadata and evidence only."""
    candidate = {"title": title, "creators": creators, "year": year, "original_language": language,
                 "external_ids": external_ids or {}}
    decision, work_id = _resolve_work(store, candidate, None, force_new)
    if decision == "same":
        return {"decision": "same", "work_id": work_id}
    store.put("work", _new_work(candidate, work_id, age_band, basis))
    runs.log(store, "works_added", work_id)
    return {"decision": "new", "work_id": work_id}


def add_source(store: Store, *, source_id: str, url: str, kind: str, tier: str, rights: str,
               note: str, rights_detail: dict | None = None) -> bool:
    source = {"source_id": source_id if source_id.startswith("s_") else f"s_{source_id}",
              "url": url, "kind": kind, "tier": tier, "rights": rights,
              "rights_detail": rights_detail or {}, "retrieved_at": runs.now(), "note": note}
    changed = store.put("source", source)
    runs.log(store, "sources_added", source["source_id"])
    return changed


def ingest_internet_archive(store: Store, identifier: str, adapter: InternetArchiveAdapter | None = None,
                            age_band: str | None = None, basis: str | None = None,
                            force_work: str | None = None, force_new: bool = False,
                            confirm_scan: bool = False, transcribe: bool = False) -> dict:
    """A public-domain scan: OCR per printed leaf.

    Boundaries are `original_scan` for IA/library scans. A user upload is
    `reconstructed` unless the analyst viewed its images and passes confirm_scan.

    OCR of hand-lettered or decorated pages is noisy. `transcribe=True` writes a
    transcription file — OCR as a draft, every page marked [draft], every leaf's
    image downloaded — and stops. Once the analyst has corrected it against the
    images (removing [draft], adding [skip: …] for non-story pages), the same
    call ingests the transcription instead of the OCR."""
    adapter = adapter or InternetArchiveAdapter()
    candidate = adapter.candidate(identifier)
    try:
        raw = adapter.fetch_djvu(candidate)
    except Exception as error:
        runs.log(store, "failures", {"url": candidate["page_url"], "reason": str(error)})
        raise
    leaves = parse_djvu(raw)
    pages = leaves_to_pages(leaves)
    if not pages:
        raise IngestError(f"{identifier}: no OCR text on any leaf")
    eid = "e_ia_" + InternetArchiveAdapter.source_record(candidate)["source_id"][len("s_ia_"):]
    transcription = store.cache_path("transcribe", f"{eid}.pages.txt")
    text_origin, skipped_pages = "ocr", []
    if transcription.exists():
        content = transcription.read_text(encoding="utf-8")
        pages = segment.parse_page_file(content)
        missing = segment.untranscribed(pages)
        if missing:
            raise IngestError(f"transcription unfinished — pages still [draft] or empty: {missing}. "
                              f"Edit {transcription}")
        text_origin, skipped_pages = "analyst_transcription", segment.skipped(content)
    elif transcribe:
        lines = [f"# Internet Archive — {candidate['title']} ({candidate['page_url']})",
                 "# OCR draft. Correct each page against its images, then delete its [draft] line.",
                 "# Not story (cover, title, copyright, notes): [skip: reason]. Wordless story page: [no text].",
                 "# Image paths are relative to the cache directory."]
        for page in pages:
            leaf_ids = [page["leaf"]] + page["illustration_leaves"]
            lines += [f"=== page {page['page']} ===", "[draft]", f"[leaf: {', '.join(map(str, leaf_ids))}]"]
            for leaf in leaf_ids:
                target = store.cache_path("images", eid, f"leaf_{leaf:04d}.jpg")
                if not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(adapter.page_image(identifier, leaf))
                lines.append(f"[image: images/{eid}/leaf_{leaf:04d}.jpg]")
            lines += [page["text"], ""]
        transcription.parent.mkdir(parents=True, exist_ok=True)
        transcription.write_text("\n".join(lines) + "\n", encoding="utf-8")
        return {"decision": "needs_transcription", "transcription": str(transcription), "pages": len(pages),
                "images": str(store.cache_path("images", eid))}
    source = InternetArchiveAdapter.source_record(candidate, runs.today())
    source["retrieved_at"] = runs.now()
    work_candidate = {"title": candidate["title"], "creators": candidate["creators"], "year": candidate["year"],
                      "original_language": candidate["language"],
                      "external_ids": {"internet_archive": identifier}}
    edition = {
        "edition_id": eid,
        "source_id": source["source_id"],
        "title": candidate["title"],
        "language": candidate["language"],
        "is_translation": False,
        "format": "scan",
        "page_boundary_source": ("original_scan" if candidate["institutional_scan"] or confirm_scan
                                 else "reconstructed"),
        "scan_provenance": candidate["scan_provenance"],
        "boundary_confirmed_by_analyst": bool(confirm_scan and not candidate["institutional_scan"]),
        "text_origin": text_origin,
        "skipped_pages": skipped_pages,
        "publication_year": candidate["year"],
        "external_ids": {"internet_archive": identifier},
        "images": {"adapter": "internet_archive", "identifier": identifier},
    }
    return _store_all(store, work_candidate, source, edition, pages, raw, ".djvu.xml",
                      force_work, force_new, age_band, basis)


def _transcription_scaffold(book: dict, image_paths: list[str]) -> str:
    lines = [f"# Book Dash — {book['title']} ({book['page_url']})",
             "# Image paths are relative to the cache directory (`book-agent images <work>` prints full paths).",
             "# Transcribe the words printed on each page image, exactly, line by line.",
             "# A page with no words: write [no text]. Describe pictures with [illustration: …].",
             "# The first image is usually the cover and the last ones credits: keep them as pages,",
             "# write [no text] if they carry no story text, and say so in the analysis."]
    for number, path in enumerate(image_paths, start=1):
        lines += [f"=== page {number} ===", f"[image: {path}]", ""]
    return "\n".join(lines) + "\n"


def ingest_bookdash(store: Store, slug: str, adapter: BookDashAdapter | None = None,
                    age_band: str | None = None, basis: str | None = None,
                    force_work: str | None = None, force_new: bool = False) -> dict:
    """Two steps. First call: download page images and write a transcription file.
    After the analyst has transcribed it: the same call ingests the transcription."""
    adapter = adapter or BookDashAdapter()
    book = adapter.book(slug)
    if not book["images"]:
        raise IngestError(f"{slug}: no page images found in the web reader")
    eid = f"e_bookdash_{slug.replace('-', '_')}"
    transcription = store.cache_path("transcribe", f"{eid}.pages.txt")

    if not transcription.exists():
        paths = []
        for number, url in enumerate(book["images"], start=1):
            target = store.cache_path("images", eid, f"p{number:02d}.jpg")
            if not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(adapter.image(url))
            paths.append(str(target.relative_to(store.ws.cache)))   # never a local absolute path
        transcription.parent.mkdir(parents=True, exist_ok=True)
        transcription.write_text(_transcription_scaffold(book, paths), encoding="utf-8")
        return {"decision": "needs_transcription", "transcription": str(transcription),
                "pages": len(paths), "images": str(store.cache_path("images", eid))}

    raw = transcription.read_bytes()
    pages = segment.parse_page_file(raw.decode("utf-8"))
    skipped_pages = segment.skipped(raw.decode("utf-8"))
    missing = segment.untranscribed(pages)
    if missing:
        raise IngestError(f"transcription unfinished — pages without text or [no text]: {missing}. "
                          f"Edit {transcription}")
    source = BookDashAdapter.source_record(book, runs.today())
    source["retrieved_at"] = runs.now()
    ids = {"bookdash": slug, **({"isbn": book["isbn"]} if book["isbn"] else {})}
    work_candidate = {"title": book["title"], "creators": book["creators"], "year": book["year"],
                      "original_language": book["language"], "external_ids": ids}
    edition = {
        "edition_id": eid,
        "source_id": source["source_id"],
        "title": book["title"],
        "language": book["language"],
        "is_translation": False,
        "format": "web",
        "page_boundary_source": "publisher_layout",
        "text_origin": "analyst_transcription",
        "skipped_pages": skipped_pages,
        "publication_year": book["year"],
        "publication_year_basis": book.get("year_basis"),
        "external_ids": ids,
        "images": {"adapter": "bookdash", "directory": f"images/{eid}"},
    }
    return _store_all(store, work_candidate, source, edition, pages, raw, ".pages.txt",
                      force_work, force_new, age_band, basis)


def page_images(store: Store, edition_id: str, pages: list[int] | None = None,
                adapter: InternetArchiveAdapter | None = None) -> list[dict]:
    """Local image files for an edition's pages, fetching IA leaves on demand."""
    edition = store.get("edition", edition_id)
    segmented = store.segmented(edition_id)
    if edition is None or segmented is None:
        raise IngestError(f"{edition_id}: not ingested")
    info = edition.get("images") or {}
    out = []
    for page in segmented["pages"]:
        if pages and page["page"] not in pages:
            continue
        if info.get("adapter") == "internet_archive":
            adapter = adapter or InternetArchiveAdapter()
            files = []
            for leaf in [page["leaf"]] + page.get("illustration_leaves", []):
                target = store.cache_path("images", edition_id, f"leaf_{leaf:04d}.jpg")
                if not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(adapter.page_image(info["identifier"], leaf))
                files.append(str(target))
            out.append({"page": page["page"], "files": files})
        elif page.get("images"):
            out.append({"page": page["page"], "files": [str(store.cache_path(p)) for p in page["images"]]})
    if not out:
        raise IngestError(f"{edition_id}: this edition has no page images")
    return out
