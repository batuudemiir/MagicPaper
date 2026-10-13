""""What don't we know yet?" — corpus coverage against the research plan.

Each gap comes with suggested queries filled from research_plan.json, so the
next run starts from the corpus's weakest point instead of from a bestseller list.
"""

from __future__ import annotations

from collections import Counter

from .rights import page_turn_eligible
from .vocab import research_plan


def _fill(template: str, **values) -> str:
    out = template
    for key, value in values.items():
        out = out.replace("{" + key + "}", str(value))
    return " ".join(out.split()) if "{" not in out else ""


def _queries(group: str, **values) -> list[str]:
    plan = research_plan()
    return [q for q in (_fill(t, **values) for t in plan["query_templates"].get(group, [])) if q]


def coverage(store) -> dict:
    works = [w for w in store.all("work") if not w.get("rejected")]
    editions = {e["edition_id"]: e for e in store.all("edition")}
    complete: dict[str, dict] = {}
    pages_by_work: dict[str, dict] = {}
    for work in works:
        analysis = store.latest("analysis", work["work_id"])
        if analysis and analysis.get("status") == "complete":
            complete[work["work_id"]] = analysis
            pages_by_work[work["work_id"]] = store.get("pages", f"{work['work_id']}.v{analysis['analysis_version']}") or {}

    def lang_of(work):
        analysis = complete.get(work["work_id"])
        edition = editions.get(analysis.get("edition_id")) if analysis else None
        return (edition or {}).get("language") or work.get("original_language")

    analyzed = [w for w in works if w["work_id"] in complete]
    band = lambda w: (w.get("classification") or {}).get("age_band")
    return {
        "works": works,
        "analyzed": analyzed,
        "complete": complete,
        "by_band": Counter(band(w) for w in analyzed),
        "by_lang_full": Counter(lang_of(w) for w in analyzed if complete[w["work_id"]].get("completeness") == "full"),
        "languages": {lang_of(w) for w in analyzed},
        "page_turn_eligible": [w for w in analyzed
                               if page_turn_eligible(pages_by_work[w["work_id"]].get("page_boundary_source"))],
        "band": band,
    }


def gaps(store) -> list[dict]:
    plan = research_plan()
    targets = plan["targets"]
    primary = plan["primary"]["age_band"]
    cov = coverage(store)
    analyzed, band = cov["analyzed"], cov["band"]
    primary_works = [w for w in analyzed if band(w) == primary]
    found: list[dict] = []

    def gap(name: str, have, want, queries: list[str], note: str | None = None):
        found.append({"gap": name, "have": have, "want": want, "suggested_queries": queries, "note": note})

    for lang in plan["primary"]["languages"]:
        have = cov["by_lang_full"].get(lang, 0)
        want = targets["analyzed_full_per_primary_language"]
        if have < want:
            group = "language_tr" if lang == "tr" else "legal_full_text"
            gap(f"fully analysed books in '{lang}'", have, want,
                _queries(group, age=primary, story_type="", language=lang),
                "Turkish public-domain picture books are scarce; expect metadata-only works first." if lang == "tr" else None)

    for age, want in targets["analyzed_per_age_band"].items():
        have = cov["by_band"].get(age, 0)
        if have < want:
            gap(f"analysed books for age {age}", have, want, _queries("general", age=age, story_type="", year_range=""))

    have = len([w for w in cov["page_turn_eligible"] if band(w) == primary])
    if have < targets["page_turn_eligible_in_primary_band"]:
        gap(f"books with real page boundaries for {primary} (page-turn evidence)", have,
            targets["page_turn_eligible_in_primary_band"],
            _queries("legal_full_text", story_type="picture book", language="en"),
            "Reconstructed pagination cannot support page-turn claims.")

    for field, key, group in (("story_types", "per_story_type_in_primary_band", "story_type"),
                              ("tones", "per_tone_in_primary_band", "tone"),
                              ("structures", "per_structure_in_primary_band", "structure")):
        counts = Counter(t for w in primary_works for t in (w.get("classification") or {}).get(field, []))
        interest = plan[f"{field}_of_interest"]
        for term in interest:
            if counts.get(term, 0) < targets[key]:
                values = {"age": primary, "story_type": term, "tone": term, "structure": term}
                gap(f"{field[:-1].replace('_', ' ')} '{term}' in {primary}", counts.get(term, 0), targets[key],
                    _queries(group, **values))

    if analyzed:
        years = [w.get("first_publication_year") for w in analyzed if w.get("first_publication_year")]
        recent = sum(1 for y in years if y >= targets["contemporary_min_year"])
        share = recent / len(analyzed)
        if share < targets["contemporary_share_min"]:
            gap(f"contemporary books (since {targets['contemporary_min_year']})", f"{share:.0%}",
                f"{targets['contemporary_share_min']:.0%}", _queries("legal_full_text", story_type="", language="en"),
                "Openly licensed platforms are the main legal route to recent full texts.")
        female = sum(1 for w in analyzed if (w.get("protagonist") or {}).get("gender") == "female")
        if female / len(analyzed) < targets["female_protagonist_share_min"]:
            gap("books with a female protagonist", f"{female / len(analyzed):.0%}",
                f"{targets['female_protagonist_share_min']:.0%}",
                _queries("general", age=primary, story_type="girl protagonist", year_range=""))
        visual = sum(1 for wid, a in cov["complete"].items() if (a.get("visual_storytelling") or {}).get("available"))
        if visual / len(analyzed) < targets["visual_analysis_share_min"]:
            gap("analyses that include illustrations", f"{visual / len(analyzed):.0%}",
                f"{targets['visual_analysis_share_min']:.0%}", [],
                "Prefer scans and page-structured CC books, where pictures are part of the material.")
    if len(cov["languages"]) < targets["languages_min"]:
        gap("languages represented", len(cov["languages"]), targets["languages_min"],
            _queries("legal_full_text", story_type="", language="multilingual"))

    unclaimed_layers = Counter(layer for c in store.all("claim") if c.get("status") == "active"
                               for layer in c.get("layers", []))
    if store.all("claim") and not unclaimed_layers.get("adult_interpretation"):
        gap("claims backed by adult interpretation (teachers, librarians, reviewers)", 0, 1,
            _queries("general", age=primary, story_type="", year_range=""))
    return found
