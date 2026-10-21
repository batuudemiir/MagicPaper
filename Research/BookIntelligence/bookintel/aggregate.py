"""Cross-book comparison over complete analyses.

Every number carries its n. Language metrics come only from books whose full
text was read; judgment statistics (beats, emotions, page turns) come from
every complete analysis, and page-turn statistics only from books with real
page boundaries. A table never mixes those populations silently.
"""

from __future__ import annotations

from collections import Counter

from .rights import page_turn_eligible
from .stats import summary

BUCKETS = 10


def _in_scope(work: dict, edition: dict, age_band: str | None, lang: str | None) -> bool:
    if age_band and (work.get("classification") or {}).get("age_band") != age_band:
        return False
    if lang and edition.get("language") != lang:
        return False
    return not work.get("rejected")


def corpus(store, age_band: str | None = None, lang: str | None = None) -> list[tuple[dict, dict, dict, dict]]:
    """(work, edition, analysis, pages) for the newest complete analysis of each work in scope."""
    works = {w["work_id"]: w for w in store.all("work")}
    editions = {e["edition_id"]: e for e in store.all("edition")}
    rows = []
    for work_id, work in sorted(works.items()):
        analysis = store.latest("analysis", work_id)
        if not analysis or analysis.get("status") != "complete":
            continue
        key = f"{work_id}.v{analysis['analysis_version']}"
        pages = store.get("pages", key)
        edition = editions.get(analysis.get("edition_id"), {})
        if pages and _in_scope(work, edition, age_band, lang):
            rows.append((work, edition, analysis, pages))
    return rows


def _curve_buckets(curve: list[int]) -> list[float]:
    """Resample a per-page curve to BUCKETS points so books of different length compare."""
    if not curve:
        return []
    if len(curve) == 1:
        return [float(curve[0])] * BUCKETS
    out = []
    for i in range(BUCKETS):
        position = i * (len(curve) - 1) / (BUCKETS - 1)
        low = int(position)
        high = min(low + 1, len(curve) - 1)
        out.append(curve[low] + (curve[high] - curve[low]) * (position - low))
    return out


def _has_repeated_line(repetition: dict) -> bool:
    """A sentence, or a phrase of 4+ words, that the reader meets on 2+ pages."""
    return bool(repetition["refrains"]) or any(len(p.split()) >= 4 for p in repetition["repeated_phrases"])


def _compress(sequence: list[str]) -> tuple[str, ...]:
    out: list[str] = []
    for item in sequence:
        if not out or out[-1] != item:
            out.append(item)
    return tuple(out)


def compare(store, age_band: str | None = None, lang: str | None = None) -> dict:
    rows = corpus(store, age_band, lang)
    result: dict = {"scope": {"age_band": age_band, "language": lang},
                    "n_works": len(rows), "works": [w["work_id"] for w, *_ in rows]}

    full_text = [(w, a) for w, _, a, _ in rows if a.get("metrics")]
    page_words = [p["metrics"]["words"] for *_, pages in rows for p in pages["pages"]
                  if (p.get("metrics") or {}).get("computed_by") == "cli"]
    result["language"] = {
        "n_full_text_works": len(full_text),
        "words_per_page": summary(page_words),
        "total_words": summary([a["metrics"]["total_words"] for _, a in full_text]),
        "pages": summary([len(pages["pages"]) for *_, pages in rows]),
        "mean_sentence_words": summary([a["metrics"]["mean_sentence_words"] for _, a in full_text]),
        "longest_sentence": summary([a["metrics"]["longest_sentence"] for _, a in full_text]),
        "dialogue_ratio": summary([a["metrics"]["dialogue_ratio"] for _, a in full_text]),
        "questions_per_page": summary([a["metrics"]["questions_per_page"] for _, a in full_text]),
        "type_token_ratio": summary([a["metrics"]["type_token_ratio"] for _, a in full_text]),
        "works_with_repeated_line": sum(1 for _, a in full_text if _has_repeated_line(a["metrics"]["repetition"])),
        "works_with_end_rhyme": sum(1 for _, a in full_text if a["metrics"]["repetition"]["end_rhyme_pairs"] >= 3),
    }

    beat_presence: Counter = Counter()
    first_positions: dict[str, list[float]] = {}
    sequences: Counter = Counter()
    for _, _, analysis, _ in rows:
        positions = analysis.get("beat_positions") or {}
        beat_presence.update(positions.keys())
        for beat, position in positions.items():
            first_positions.setdefault(beat, []).append(position)
        ordered = [b["beat"] for b in sorted(analysis.get("beats", []), key=lambda b: b.get("start_page") or 0)]
        sequences[" → ".join(_compress(ordered))] += 1
    result["structure"] = {
        "beat_presence": dict(beat_presence.most_common()),
        "beat_first_position": {b: summary(v) for b, v in sorted(first_positions.items(),
                                                                     key=lambda kv: sorted(kv[1])[len(kv[1]) // 2])},
        "sequences": dict(sequences.most_common(10)),
    }

    curves = [a["emotional_curve"] for _, _, a, _ in rows if a.get("emotional_curve")]
    bucketed = [_curve_buckets(c) for c in curves]
    peaks = [c.index(max(c)) / max(len(c) - 1, 1) for c in curves]
    dominant: Counter = Counter(p.get("emotion") for *_, pages in rows for p in pages["pages"] if p.get("emotion"))
    result["emotion"] = {
        "n_curves": len(curves),
        "median_curve": [summary([b[i] for b in bucketed])["median"] for i in range(BUCKETS)] if bucketed else [],
        "peak_position": summary(peaks),
        "peak_intensity": summary([max(c) for c in curves]),
        "ending_intensity": summary([c[-1] for c in curves]),
        "page_emotions": dict(dominant.most_common()),
    }

    eligible = [(a, pages) for _, _, a, pages in rows if page_turn_eligible(pages.get("page_boundary_source"))]
    mechanisms: Counter = Counter()
    strengths = []
    for _, pages in eligible:
        for page in pages["pages"][:-1]:
            mechanisms.update(page.get("page_turn_mechanism") or [])
            if isinstance(page.get("page_turn_strength"), int):
                strengths.append(page["page_turn_strength"])
    result["page_turns"] = {"n_eligible_works": len(eligible),
                            "mechanisms": dict(mechanisms.most_common()),
                            "strength": summary(strengths)}

    roles: Counter = Counter()
    humor: Counter = Counter()
    repetition_types: Counter = Counter()
    repetition_functions: Counter = Counter()
    effective: Counter = Counter()
    anti: Counter = Counter()
    flags: Counter = Counter()
    appeal: dict[str, list[int]] = {}
    humor_share = []
    for work, _, analysis, pages in rows:
        roles.update(c.get("role") for c in analysis.get("characters", []) if c.get("role"))
        page_list = pages["pages"]
        for page in page_list:
            humor.update(page.get("humor") or [])
        humor_share.append(sum(1 for p in page_list if p.get("humor")) / len(page_list))
        for item in analysis.get("repetition", []):
            repetition_types[item.get("type")] += 1
            repetition_functions.update(item.get("functions", []))
            effective[str(item.get("effective"))] += 1
        anti.update(i.get("id") for i in analysis.get("anti_patterns", []))
        flags.update(set(work.get("content_flags", [])) | set(analysis.get("content_flags", [])))
        for dimension, score in ((analysis.get("child_appeal_heuristic") or {}).get("scores") or {}).items():
            if isinstance(score, int):
                appeal.setdefault(dimension, []).append(score)
    result["characters"] = {"roles": dict(roles.most_common()),
                            "per_book": summary([len(a.get("characters", [])) for _, _, a, _ in rows]),
                            "protagonist_agency": summary([a["protagonist_agency"] for _, _, a, _ in rows
                                                           if isinstance(a.get("protagonist_agency"), int)])}
    result["humor"] = {"types": dict(humor.most_common()), "share_of_pages": summary(humor_share)}
    result["repetition"] = {"types": dict(repetition_types.most_common()),
                            "functions": dict(repetition_functions.most_common()),
                            "judged_effective": dict(effective)}
    result["anti_patterns"] = dict(anti.most_common())
    result["content_flags"] = dict(flags.most_common())
    result["appeal_heuristic"] = {"label": "Research heuristic — not validated",
                                  "dimensions": {d: summary(v) for d, v in sorted(appeal.items())}}
    return result
