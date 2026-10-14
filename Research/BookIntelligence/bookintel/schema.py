"""Record validation. Stdlib only: each validator returns a list of error strings.

Two levels:
- shape: one record against its own rules (types, closed vocabularies, ranges)
- references: across records (`validate_store`): ids exist, text only where
  rights allow it, page-turn judgments only on trustworthy page boundaries,
  claims only cite complete analyses.
"""

from __future__ import annotations

import re

from . import rights as rights_rules
from .vocab import terms, vocab

ANALYSIS_STATUSES = {"draft", "complete"}
CLAIM_STATUSES = {"active", "rejected", "superseded"}
FORMATS = {"print", "ebook", "scan", "audiobook", "web"}

# Statements about what children feel or want need evidence about children.
_PREFERENCE = re.compile(
    r"\b(children|kids|child)\s+(\w+\s+)?(love|loves|like|likes|prefer|prefers|enjoy|enjoys|want|wants|adore)\b"
    # Turkish puts the verb last: "Çocuklar tekrarı sever."
    r"|\bçocuk\w*\b[^.!?]*\b(sever|severler|bayılır|bayılırlar|ister|isterler|tercih eder|hoşlanır)\b",
    re.IGNORECASE,
)
_UNIVERSAL = re.compile(r"\b(always|never|every book|all books|universal|mandatory)\b|\b(her zaman|asla|bütün kitaplar|tüm kitaplar|zorunlu)\b", re.IGNORECASE)


class Errors(list):
    def need(self, condition: bool, message: str) -> None:
        if not condition:
            self.append(message)

    def one_of(self, value, allowed: set, where: str, nullable: bool = False) -> None:
        if value is None and nullable:
            return
        if value not in allowed:
            self.append(f"{where}: {value!r} is not in the vocabulary")

    def all_of(self, values, allowed: set, where: str) -> None:
        if not isinstance(values, list):
            self.append(f"{where}: expected a list")
            return
        for value in values:
            if value not in allowed:
                self.append(f"{where}: {value!r} is not in the vocabulary")

    def int_range(self, value, low: int, high: int, where: str, nullable: bool = False) -> None:
        if value is None and nullable:
            return
        if not isinstance(value, int) or isinstance(value, bool) or not low <= value <= high:
            self.append(f"{where}: expected an integer {low}-{high}, got {value!r}")


# -- works, editions, sources -------------------------------------------------

def validate_work(work: dict) -> list[str]:
    e = Errors()
    wid = work.get("work_id", "?")
    e.need(str(wid).startswith("w_"), f"{wid}: work_id must start with w_")
    e.need(bool(work.get("title")), f"{wid}: title is required")
    creators = work.get("creators", [])
    e.need(isinstance(creators, list) and len(creators) > 0, f"{wid}: at least one creator")
    for creator in creators if isinstance(creators, list) else []:
        e.one_of(creator.get("role"), terms("creator_roles"), f"{wid}.creators.role")
    e.one_of(work.get("original_language"), terms("languages"), f"{wid}.original_language")
    year = work.get("first_publication_year")
    e.need(year is None or (isinstance(year, int) and 1400 <= year <= 2100), f"{wid}: first_publication_year out of range")

    c = work.get("classification", {})
    e.one_of(c.get("age_band"), terms("age_bands"), f"{wid}.classification.age_band", nullable=True)
    if c.get("age_band"):
        e.one_of(c.get("age_band_basis"), terms("age_band_basis"), f"{wid}.classification.age_band_basis")
    e.all_of(c.get("story_types", []), terms("story_types"), f"{wid}.classification.story_types")
    e.all_of(c.get("structures", []), terms("structures"), f"{wid}.classification.structures")
    e.all_of(c.get("tones", []), terms("tones"), f"{wid}.classification.tones")
    e.all_of(c.get("visual_style", []), terms("visual_styles"), f"{wid}.classification.visual_style")

    protagonist = work.get("protagonist")
    if protagonist:
        e.one_of(protagonist.get("kind"), terms("protagonist_kinds"), f"{wid}.protagonist.kind", nullable=True)
        e.one_of(protagonist.get("gender"), terms("protagonist_genders"), f"{wid}.protagonist.gender", nullable=True)

    for layer in ("popularity", "quality", "adult_interpretation"):
        for item in work.get("evidence", {}).get(layer, []):
            e.need(bool(item.get("source_id")), f"{wid}.evidence.{layer}: every item cites a source_id")
            e.need(bool(item.get("note")), f"{wid}.evidence.{layer}: every item has a note (paraphrase, not a quotation)")
    e.all_of(work.get("content_flags", []), terms("content_flags"), f"{wid}.content_flags")
    suitability = work.get("age_suitability") or {}
    e.one_of(suitability.get("magicpaper"), terms("age_suitability"), f"{wid}.age_suitability.magicpaper", nullable=True)
    return e


def validate_edition(edition: dict) -> list[str]:
    e = Errors()
    eid = edition.get("edition_id", "?")
    e.need(str(eid).startswith("e_"), f"{eid}: edition_id must start with e_")
    for field in ("work_id", "source_id", "language"):
        e.need(bool(edition.get(field)), f"{eid}: {field} is required")
    e.one_of(edition.get("language"), terms("languages"), f"{eid}.language")
    e.one_of(edition.get("format"), FORMATS, f"{eid}.format")
    e.one_of(edition.get("page_boundary_source"), terms("page_boundary_sources"), f"{eid}.page_boundary_source", nullable=True)
    e.one_of(edition.get("text_origin"), terms("text_origins"), f"{eid}.text_origin", nullable=True)
    return e


def validate_source(source: dict) -> list[str]:
    e = Errors()
    sid = source.get("source_id", "?")
    e.need(str(sid).startswith("s_"), f"{sid}: source_id must start with s_")
    e.need(str(source.get("url", "")).startswith(("http://", "https://", "file:")), f"{sid}: url is required")
    e.one_of(source.get("kind"), terms("source_kinds"), f"{sid}.kind")
    e.one_of(source.get("tier"), terms("tiers"), f"{sid}.tier")
    e.one_of(source.get("rights"), terms("rights"), f"{sid}.rights")
    e.extend(rights_rules.rights_errors(source))
    if source.get("kind") == "aggregator":
        e.need(source.get("tier") == "D", f"{sid}: an aggregator is tier D")
    if "quotation" in source or "body" in source:
        e.append(f"{sid}: sources do not store bodies or quotations — paraphrase in `note`")
    return e


# -- analyses -----------------------------------------------------------------

def _validate_page(page: dict, where: str, judged_required: bool, page_turn_ok: bool) -> list[str]:
    e = Errors()
    e.int_range(page.get("page"), 1, 500, f"{where}.page")
    e.one_of(page.get("beat"), terms("beats"), f"{where}.beat", nullable=not judged_required)
    e.one_of(page.get("emotion"), terms("emotions"), f"{where}.emotion", nullable=not judged_required)
    e.int_range(page.get("emotion_intensity"), 0, 5, f"{where}.emotion_intensity", nullable=not judged_required)
    e.one_of(page.get("label"), terms("judgment_labels"), f"{where}.label", nullable=not judged_required)
    if judged_required:
        e.need(bool(page.get("change")), f"{where}.change: what changes on this page (paraphrase)")

    mechanisms = page.get("page_turn_mechanism")
    strength = page.get("page_turn_strength")
    if not page_turn_ok:
        e.need(not mechanisms and strength is None,
               f"{where}: page-turn fields need original page boundaries (original_scan or publisher_layout)")
    else:
        if mechanisms is not None:
            e.all_of(mechanisms, terms("page_turn_mechanisms"), f"{where}.page_turn_mechanism")
        e.int_range(strength, 1, 5, f"{where}.page_turn_strength", nullable=True)

    e.all_of(page.get("humor", []), terms("humor_types"), f"{where}.humor")
    e.all_of(page.get("repetition", []), terms("repetition_types"), f"{where}.repetition")
    illustration = page.get("illustration") or {}
    e.all_of(illustration.get("functions", []), terms("visual_functions"), f"{where}.illustration.functions")
    return e


def validate_pages(record: dict, status: str = "draft", page_turn_ok: bool = False) -> list[str]:
    e = Errors()
    key = f"pages:{record.get('work_id')}.v{record.get('analysis_version')}"
    e.one_of(record.get("page_boundary_source"), terms("page_boundary_sources"), f"{key}.page_boundary_source")
    pages = record.get("pages", [])
    e.need(isinstance(pages, list) and pages, f"{key}: no pages")
    numbers = [p.get("page") for p in pages]
    e.need(numbers == sorted(set(numbers)), f"{key}: page numbers must be unique and ascending")
    for page in pages:
        e.extend(_validate_page(page, f"{key}.p{page.get('page')}", status == "complete", page_turn_ok))
    return e


def validate_analysis(analysis: dict) -> list[str]:
    e = Errors()
    key = f"analysis:{analysis.get('work_id')}.v{analysis.get('analysis_version')}"
    status = analysis.get("status")
    e.one_of(status, ANALYSIS_STATUSES, f"{key}.status")
    complete = status == "complete"
    for beat in analysis.get("beats", []):
        e.one_of(beat.get("beat"), terms("beats"), f"{key}.beats")
        e.int_range(beat.get("start_page"), 1, 500, f"{key}.beats.start_page")
        e.int_range(beat.get("end_page"), 1, 500, f"{key}.beats.end_page")
        if isinstance(beat.get("start_page"), int) and isinstance(beat.get("end_page"), int):
            e.need(beat["start_page"] <= beat["end_page"], f"{key}.beats: start_page after end_page")
    for character in analysis.get("characters", []):
        e.need(bool(character.get("id")), f"{key}.characters: every character has an id")
        e.one_of(character.get("role"), terms("character_roles"), f"{key}.characters[{character.get('id')}].role", nullable=not complete)
    e.int_range(analysis.get("protagonist_agency"), 1, 5, f"{key}.protagonist_agency", nullable=not complete)
    for item in analysis.get("repetition", []):
        e.one_of(item.get("type"), terms("repetition_types"), f"{key}.repetition.type")
        e.all_of(item.get("functions", []), terms("repetition_functions"), f"{key}.repetition.functions")
    for item in analysis.get("anti_patterns", []):
        e.one_of(item.get("id"), terms("anti_patterns"), f"{key}.anti_patterns")
    e.all_of(analysis.get("content_flags", []), terms("content_flags"), f"{key}.content_flags")

    appeal = analysis.get("child_appeal_heuristic")
    if appeal and appeal.get("scores"):
        e.need(appeal.get("label") == vocab()["appeal_label"],
               f"{key}.child_appeal_heuristic.label must read exactly {vocab()['appeal_label']!r}")
        for dimension, score in appeal["scores"].items():
            e.one_of(dimension, terms("appeal_dimensions"), f"{key}.child_appeal_heuristic")
            e.int_range(score, 1, 5, f"{key}.child_appeal_heuristic.{dimension}", nullable=True)

    if complete:
        e.need(bool(analysis.get("beats")), f"{key}: a complete analysis has a beat map")
        e.need(bool(analysis.get("characters")), f"{key}: a complete analysis lists characters")
        e.need(bool(analysis.get("summary_paraphrase")), f"{key}: a complete analysis has summary_paraphrase")
    return e


# -- claims and runs ------------------------------------------------------------

def validate_claim(claim: dict) -> list[str]:
    e = Errors()
    cid = claim.get("claim_id", "?")
    e.need(str(cid).startswith("c_"), f"{cid}: claim_id must start with c_")
    statement = claim.get("statement", "")
    e.need(bool(statement), f"{cid}: statement is required")
    e.one_of(claim.get("kind"), terms("claim_kinds"), f"{cid}.kind")
    e.all_of(claim.get("layers", []), terms("evidence_layers"), f"{cid}.layers")
    e.need(bool(claim.get("layers")), f"{cid}: at least one evidence layer")
    from .learning import COMPARED  # page judgments whose reliability is measured
    e.all_of(claim.get("judgment_fields", []), set(COMPARED), f"{cid}.judgment_fields")
    e.one_of(claim.get("status"), CLAIM_STATUSES, f"{cid}.status")
    if claim.get("status") == "rejected":
        e.need(bool(claim.get("rejected_reason")), f"{cid}: a rejected claim keeps its reason")
    scope = claim.get("scope", {})
    e.one_of(scope.get("age_band"), terms("age_bands"), f"{cid}.scope.age_band", nullable=True)
    e.one_of(scope.get("language"), terms("languages"), f"{cid}.scope.language", nullable=True)

    if _PREFERENCE.search(statement) and "child_response" not in claim.get("layers", []):
        e.append(f"{cid}: statement asserts what children like; without child_response evidence, "
                 "phrase it as a corpus observation (e.g. '12 of 20 analyzed books …')")
    if claim.get("counterexample_works") and _UNIVERSAL.search(statement):
        e.append(f"{cid}: statement reads as universal but the claim has counterexamples")
    overlap = set(claim.get("supporting_works", [])) & set(claim.get("counterexample_works", []))
    e.need(not overlap, f"{cid}: works both support and contradict: {sorted(overlap)}")

    mp = claim.get("magicpaper")
    if mp:
        e.one_of(mp.get("target"), terms("insight_targets"), f"{cid}.magicpaper.target")
        e.one_of(mp.get("review_status"), terms("insight_review_status"), f"{cid}.magicpaper.review_status")
    return e


def validate_run(run: dict) -> list[str]:
    e = Errors()
    rid = run.get("run_id", "?")
    e.need(str(rid).startswith("r_"), f"{rid}: run_id must start with r_")
    e.one_of(run.get("status"), {"open", "closed"}, f"{rid}.status")
    e.need(bool(run.get("goal")), f"{rid}: a run states its goal")
    return e


# -- cross-record ---------------------------------------------------------------

def validate_store(store) -> list[str]:
    errors: list[str] = []
    works = {w["work_id"]: w for w in store.all("work")}
    editions = {x["edition_id"]: x for x in store.all("edition")}
    sources = {s["source_id"]: s for s in store.all("source")}
    analyses = store.all("analysis")
    pages_records = store.all("pages")
    claims = store.all("claim")

    for work in works.values():
        errors += validate_work(work)
        for layer, items in work.get("evidence", {}).items():
            for item in items:
                if item.get("source_id") and item["source_id"] not in sources:
                    errors.append(f"{work['work_id']}.evidence.{layer}: unknown source {item['source_id']}")
        for edition_id in work.get("editions", []):
            if edition_id not in editions:
                errors.append(f"{work['work_id']}: unknown edition {edition_id}")
    for edition in editions.values():
        errors += validate_edition(edition)
        if edition.get("work_id") not in works:
            errors.append(f"{edition['edition_id']}: unknown work {edition.get('work_id')}")
        if edition.get("source_id") not in sources:
            errors.append(f"{edition['edition_id']}: unknown source {edition.get('source_id')}")
    for source in sources.values():
        errors += validate_source(source)

    analysis_status = {}
    for analysis in analyses:
        errors += validate_analysis(analysis)
        if analysis.get("work_id") not in works:
            errors.append(f"analysis {analysis.get('work_id')}: unknown work")
        analysis_status[(analysis.get("work_id"), analysis.get("analysis_version"))] = analysis.get("status")

    for record in pages_records:
        key = (record.get("work_id"), record.get("analysis_version"))
        edition = editions.get(record.get("edition_id"))
        source = sources.get(edition.get("source_id")) if edition else None
        where = f"pages:{key[0]}.v{key[1]}"
        if edition is None:
            errors.append(f"{where}: unknown edition {record.get('edition_id')}")
            continue
        rights = source.get("rights") if source else None
        page_turn_ok = rights_rules.page_turn_eligible(record.get("page_boundary_source"))
        errors += validate_pages(record, analysis_status.get(key, "draft"), page_turn_ok)
        if not rights_rules.can_store_text(rights or ""):
            if any(p.get("text") for p in record.get("pages", [])) or record.get("text_stored"):
                errors.append(f"{where}: page text stored but source rights are {rights!r} — "
                              "only public_domain, open_license or licensed text may be kept")
            for page in record.get("pages", []):
                metrics = page.get("metrics") or {}
                if metrics and metrics.get("computed_by") == "cli":
                    errors.append(f"{where}.p{page.get('page')}: CLI metrics without stored text; "
                                  "mark analyst estimates computed_by='analyst_estimate'")
        if record.get("page_boundary_source") != edition.get("page_boundary_source"):
            errors.append(f"{where}: page_boundary_source differs from its edition")

    complete = {wid for (wid, _), status in analysis_status.items() if status == "complete"}
    for claim in claims:
        errors += validate_claim(claim)
        cid = claim.get("claim_id")
        for wid in claim.get("supporting_works", []) + claim.get("counterexample_works", []):
            if wid not in works:
                errors.append(f"{cid}: unknown work {wid}")
            elif "textual_mechanism" in claim.get("layers", []) and wid not in complete:
                errors.append(f"{cid}: {wid} has no complete analysis, so it cannot count as textual evidence")
        for sid in claim.get("sources", []):
            if sid not in sources:
                errors.append(f"{cid}: unknown source {sid}")

    for run in store.all("run"):
        errors += validate_run(run)
    open_runs = [r["run_id"] for r in store.all("run") if r.get("status") == "open"]
    if len(open_runs) > 1:
        errors.append(f"more than one open run: {open_runs}")
    return errors
