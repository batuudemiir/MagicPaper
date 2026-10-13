"""The analyst loop: scaffold → the analyst fills judgments → refresh + check.

The CLI owns every computed field (metrics, emotional curve, completeness,
page position of beats). The analyst owns every judgment field. `refresh`
overwrites the computed ones from the cached text each time, so a hand-edited
number cannot survive.
"""

from __future__ import annotations

from . import language, runs
from .rights import can_store_text, completeness, page_turn_eligible
from .store import Store, analysis_key

PAGE_JUDGMENTS = ("beat", "emotion", "emotion_intensity", "label", "change")


class AnalyzeError(RuntimeError):
    pass


def _empty_page(page: dict, keep_text: bool, page_turn_ok: bool) -> dict:
    return {
        "page": page["page"],
        "spread": page.get("spread", False),
        "text": page["text"] if keep_text else None,
        "metrics": None,
        "beat": None,
        "emotion": None,
        "emotion_intensity": None,
        "characters": [],
        "location": None,
        "action": None,
        "change": None,
        "question_created": None,
        "page_turn_mechanism": [] if page_turn_ok else None,
        "page_turn_strength": None,
        "page_turn_note": None if page_turn_ok else "not analysed: page boundaries are reconstructed",
        "illustration": {"available": bool(page.get("illustration_notes") or page.get("images")
                                           or page.get("illustration_leaves")),
                         "notes": page.get("illustration_notes", []),
                         "only_in_image": None, "functions": []},
        "source_leaves": ([page["leaf"]] + page.get("illustration_leaves", [])) if "leaf" in page else None,
        "humor": [],
        "repetition": [],
        "label": None,
    }


def _empty_analysis(work_id: str, version: str, edition_id: str | None) -> dict:
    return {
        "work_id": work_id,
        "analysis_version": version,
        "edition_id": edition_id,
        "status": "draft",
        "analyst": None,
        "analyzed_at": None,
        "completeness": None,
        "summary_paraphrase": None,
        "beats": [],
        "beat_positions": None,
        "characters": [],
        "protagonist_agency": None,
        "emotional_curve": None,
        "humor_notes": None,
        "repetition": [],
        "visual_storytelling": {"available": False, "notes": []},
        "strengths": [],
        "weaknesses": [],
        "anti_patterns": [],
        "child_appeal_heuristic": {"label": None, "scores": {}, "rationale": None},
        "content_flags": [],
        "age_suitability": {"magicpaper": None, "notes": None},
        "metrics": None,
        "_template_help": {
            "beats": "[{beat, start_page, end_page, intensity 0-5, function}] — research beats from vocab",
            "characters": "[{id, name, role, age, personality, desire, fear, goal, problem, strengths, "
                          "weakness, change, relation_to_protagonist, humor_source, tension_source}]",
            "repetition": "[{type, description, pages, functions[], effective: true|false|null, why}]",
            "anti_patterns": "[{id, pages, note}]",
            "child_appeal_heuristic": "scores 1-5 per appeal dimension; label is set by the CLI",
        },
    }


def scaffold(store: Store, work_id: str, version: str = "1", edition_id: str | None = None,
             page_count: int | None = None) -> dict:
    """Create draft pages + analysis records. Never overwrites an existing version."""
    work = store.get("work", work_id)
    if work is None:
        raise AnalyzeError(f"unknown work {work_id}")
    key = analysis_key(work_id, version)
    if store.get("analysis", key) or store.get("pages", key):
        raise AnalyzeError(f"{key} already exists — bump --version to re-analyse")

    edition_id = edition_id or (work["editions"][0] if work.get("editions") else None)
    if edition_id is None:
        raise AnalyzeError(f"{work_id} has no edition; register the material it is analysed from first")
    edition = store.get("edition", edition_id)
    if edition is None:
        raise AnalyzeError(f"unknown edition {edition_id}")
    source = store.get("source", edition["source_id"]) or {}
    segmented = store.segmented(edition_id)

    keep_text = can_store_text(source.get("rights", ""))
    page_turn_ok = page_turn_eligible(edition.get("page_boundary_source"))
    if segmented:
        source_pages = segmented["pages"]
    elif page_count:
        source_pages = [{"page": i, "text": None} for i in range(1, page_count + 1)]
        keep_text = False
    else:
        raise AnalyzeError(f"{edition_id} has no segmented text; pass --pages N to analyse from notes")

    pages = {
        "work_id": work_id,
        "analysis_version": version,
        "edition_id": edition_id,
        "page_boundary_source": edition.get("page_boundary_source"),
        "text_stored": keep_text,
        "pages": [_empty_page(p, keep_text, page_turn_ok) for p in source_pages],
    }
    analysis = _empty_analysis(work_id, version, edition_id)
    store.put("pages", pages)
    store.put("analysis", analysis)
    refresh(store, work_id, version)
    return {"key": key, "pages": len(source_pages), "text_stored": keep_text, "page_turn_ok": page_turn_ok}


def missing_judgments(pages_record: dict) -> list[str]:
    missing = []
    for page in pages_record["pages"]:
        absent = [field for field in PAGE_JUDGMENTS if page.get(field) in (None, "")]
        if absent:
            missing.append(f"p{page['page']}: {', '.join(absent)}")
    return missing


def _beat_positions(beats: list[dict], page_total: int) -> dict:
    """First appearance of each beat as a share of the book (0 = first page, 1 = last)."""
    positions: dict[str, float] = {}
    span = max(page_total - 1, 1)
    for beat in sorted(beats, key=lambda b: (b.get("start_page") or 0)):
        name, start = beat.get("beat"), beat.get("start_page")
        if name and isinstance(start, int) and name not in positions:
            positions[name] = round((start - 1) / span, 3)
    return positions


def refresh(store: Store, work_id: str, version: str) -> dict:
    """Recompute every CLI-owned field. Returns the gaps left for the analyst."""
    key = analysis_key(work_id, version)
    pages_record, analysis = store.get("pages", key), store.get("analysis", key)
    if pages_record is None or analysis is None:
        raise AnalyzeError(f"{key} not found — run `analyze {work_id}` first")
    edition = store.get("edition", pages_record["edition_id"]) or {}
    source = store.get("source", edition.get("source_id", "")) or {}
    lang = edition.get("language", "en")
    segmented = store.segmented(pages_record["edition_id"])
    texts_by_page = {p["page"]: p["text"] for p in segmented["pages"]} if segmented else {}

    texts = []
    for page in pages_record["pages"]:
        text = texts_by_page.get(page["page"])
        if text is not None:
            page["metrics"] = language.page_metrics(text, lang)
            texts.append(text)
            if pages_record.get("text_stored"):
                page["text"] = text
        elif (page.get("metrics") or {}).get("computed_by") == "cli":
            page["metrics"] = None
    if texts and len(texts) == len(pages_record["pages"]):
        analysis["metrics"] = language.book_metrics(texts, lang)

    intensities = [p.get("emotion_intensity") for p in pages_record["pages"]]
    analysis["emotional_curve"] = intensities if all(isinstance(i, int) for i in intensities) else None
    analysis["beat_positions"] = _beat_positions(analysis.get("beats", []), len(pages_record["pages"]))
    missing = missing_judgments(pages_record)
    analysis["completeness"] = completeness(source.get("rights", ""), not missing)
    appeal = analysis.get("child_appeal_heuristic") or {}
    if appeal.get("scores"):
        from .vocab import vocab
        appeal["label"] = vocab()["appeal_label"]
        analysis["child_appeal_heuristic"] = appeal

    store.put("pages", pages_record)
    store.put("analysis", analysis)
    return {"key": key, "missing": missing, "completeness": analysis["completeness"]}


def complete(store: Store, work_id: str, version: str, analyst: str) -> dict:
    """Mark an analysis complete; refuses while judgments are missing."""
    from .schema import validate_analysis, validate_pages

    result = refresh(store, work_id, version)
    if result["missing"]:
        raise AnalyzeError("page judgments missing: " + "; ".join(result["missing"][:8]))
    key = analysis_key(work_id, version)
    analysis, pages_record = store.get("analysis", key), store.get("pages", key)
    analysis["status"] = "complete"
    analysis["analyst"] = analyst
    analysis["analyzed_at"] = runs.now()
    errors = validate_analysis(analysis) + validate_pages(
        pages_record, "complete", page_turn_eligible(pages_record.get("page_boundary_source")))
    if errors:
        raise AnalyzeError("cannot complete:\n  " + "\n  ".join(errors[:15]))
    store.put("analysis", analysis)
    runs.log(store, "analyses_completed", key)
    return {"key": key, "completeness": analysis["completeness"]}
