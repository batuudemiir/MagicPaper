"""Human-readable output: status, deep dives, run reports, generated doc sections.

Generated markdown lives between markers so the hand-written interpretation
around it survives regeneration:

    <!-- bookintel:generated:start -->
    ...
    <!-- bookintel:generated:end -->

No report reproduces book text. Deep dives use the analyst's paraphrases and
computed numbers only.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path

from . import aggregate, gaps as gaps_module
from .store import write_if_changed

START, END = "<!-- bookintel:generated:start -->", "<!-- bookintel:generated:end -->"


def write_generated(path: Path, title: str, body: str, intro: str = "") -> bool:
    """Replace only the generated block; create the file with a header if missing."""
    block = f"{START}\n{body.rstrip()}\n{END}"
    if path.exists():
        current = path.read_text(encoding="utf-8")
        if START in current and END in current:
            before, rest = current.split(START, 1)
            after = rest.split(END, 1)[1]
            return write_if_changed(path, before + block + after)
        return write_if_changed(path, current.rstrip() + "\n\n" + block + "\n")
    header = f"# {title}\n\n{intro.strip()}\n\n" if intro else f"# {title}\n\n"
    return write_if_changed(path, header + block + "\n")


def _fmt_summary(s: dict) -> str:
    if not s or not s.get("n"):
        return "n=0"
    return f"median {s['median']} (p25 {s['p25']}, p75 {s['p75']}, range {s['min']}-{s['max']}), n={s['n']}"


def _scope_label(n: int) -> str:
    from .confidence import sample_scope
    return sample_scope(n).replace("_", " ").lower()


# -- status ------------------------------------------------------------------------

def status(store) -> dict:
    works = store.all("work")
    editions = {e["edition_id"]: e for e in store.all("edition")}
    sources = {s["source_id"]: s for s in store.all("source")}
    states = Counter()
    for work in works:
        if work.get("rejected"):
            states["rejected"] += 1
            continue
        analysis = store.latest("analysis", work["work_id"])
        if analysis and analysis.get("status") == "complete":
            states[f"analysed_{analysis.get('completeness')}"] += 1
        elif analysis:
            states["analysis_draft"] += 1
        elif work.get("editions"):
            states["ingested"] += 1
        else:
            states["metadata_only"] += 1
    rights = Counter(sources[e["source_id"]]["rights"] for e in editions.values() if e["source_id"] in sources)
    claims = store.all("claim")
    runs = store.all("run")
    return {
        "works": len(works),
        "editions": len(editions),
        "sources": len(sources),
        "states": dict(states),
        "by_age_band": dict(Counter((w.get("classification") or {}).get("age_band") or "unknown" for w in works)),
        "by_language": dict(Counter(w.get("original_language") for w in works)),
        "edition_rights": dict(rights),
        "claims": dict(Counter((c.get("computed") or {}).get("confidence") or c.get("status") for c in claims)),
        "dedup_review_pending": len(store.review_items()),
        "open_run": next((r["run_id"] for r in runs if r.get("status") == "open"), None),
        "last_run": max((r["run_id"] for r in runs), default=None),
    }


def status_text(s: dict) -> str:
    lines = [
        f"Works {s['works']} · editions {s['editions']} · sources {s['sources']}",
        "States: " + (", ".join(f"{k} {v}" for k, v in sorted(s["states"].items())) or "—"),
        "Age bands: " + ", ".join(f"{k} {v}" for k, v in sorted(s["by_age_band"].items())),
        "Languages: " + ", ".join(f"{k} {v}" for k, v in sorted(s["by_language"].items(), key=lambda kv: str(kv[0]))),
        "Edition rights: " + (", ".join(f"{k} {v}" for k, v in sorted(s["edition_rights"].items())) or "—"),
        "Claims: " + (", ".join(f"{k} {v}" for k, v in sorted(s["claims"].items(), key=lambda kv: str(kv[0]))) or "—"),
        f"Dedup review pending: {s['dedup_review_pending']}",
        f"Open run: {s['open_run'] or '—'} · last run: {s['last_run'] or '—'}",
    ]
    return "\n".join(lines)


# -- compare -----------------------------------------------------------------------

def compare_markdown(result: dict) -> str:
    scope = result["scope"]
    n = result["n_works"]
    lang, struct, emo, turns = result["language"], result["structure"], result["emotion"], result["page_turns"]
    out = [
        f"Scope: age {scope['age_band'] or 'all'} · language {scope['language'] or 'all'} · "
        f"**{n} complete analyses ({_scope_label(n)})**. Works: {', '.join(result['works']) or '—'}",
        "",
        "Descriptive only. A distribution is a guidance range for the content line, not a rule — "
        "and below 10 works it is an anecdote with numbers.",
        "",
        "## Language (full-text works only)",
        "",
        f"- Full-text works: {lang['n_full_text_works']}",
        f"- Words per page: {_fmt_summary(lang['words_per_page'])}",
        f"- Words per book: {_fmt_summary(lang['total_words'])}",
        f"- Pages per book: {_fmt_summary(lang['pages'])}",
        f"- Mean sentence length (words): {_fmt_summary(lang['mean_sentence_words'])}",
        f"- Longest sentence: {_fmt_summary(lang['longest_sentence'])}",
        f"- Dialogue share: {_fmt_summary(lang['dialogue_ratio'])}",
        f"- Questions per page: {_fmt_summary(lang['questions_per_page'])}",
        f"- Works with a repeated line (a sentence or 4+ word phrase on 2+ pages): {lang['works_with_repeated_line']} of {lang['n_full_text_works']}",
        f"- Works with sustained end rhyme (heuristic): {lang['works_with_end_rhyme']} of {lang['n_full_text_works']}",
        "",
        "## Structure",
        "",
        "Beat present in (works): " + (", ".join(f"{b} {c}" for b, c in struct["beat_presence"].items()) or "—"),
        "",
        "| Beat | First appears at (share of book) |",
        "|---|---|",
    ]
    out += [f"| {beat} | {_fmt_summary(s)} |" for beat, s in struct["beat_first_position"].items()]
    out += ["", "Beat orders seen:", ""]
    out += [f"- {seq} — {count}" for seq, count in struct["sequences"].items()] or ["- —"]
    out += [
        "",
        "## Emotional arc",
        "",
        f"- Curves: {emo['n_curves']}",
        f"- Median curve (10 points, intensity 0-5): {' → '.join(str(round(v, 1)) for v in emo['median_curve']) or '—'}",
        f"- Peak position (share of book): {_fmt_summary(emo['peak_position'])}",
        f"- Peak intensity: {_fmt_summary(emo['peak_intensity'])}",
        f"- Ending intensity: {_fmt_summary(emo['ending_intensity'])}",
        "- Page emotions: " + (", ".join(f"{k} {v}" for k, v in emo["page_emotions"].items()) or "—"),
        "",
        "## Page turns (works with original page boundaries only)",
        "",
        f"- Eligible works: {turns['n_eligible_works']}",
        "- Mechanisms: " + (", ".join(f"{k} {v}" for k, v in turns["mechanisms"].items()) or "—"),
        f"- Strength (1-5): {_fmt_summary(turns['strength'])}",
        "",
        "## Characters, humor, repetition",
        "",
        "- Roles: " + (", ".join(f"{k} {v}" for k, v in result["characters"]["roles"].items()) or "—"),
        f"- Characters per book: {_fmt_summary(result['characters']['per_book'])}",
        f"- Protagonist agency (1-5, analyst judgment): {_fmt_summary(result['characters']['protagonist_agency'])}",
        "- Humor types (pages): " + (", ".join(f"{k} {v}" for k, v in result["humor"]["types"].items()) or "—"),
        f"- Share of pages with humor: {_fmt_summary(result['humor']['share_of_pages'])}",
        "- Repetition types: " + (", ".join(f"{k} {v}" for k, v in result["repetition"]["types"].items()) or "—"),
        "- Repetition functions: " + (", ".join(f"{k} {v}" for k, v in result["repetition"]["functions"].items()) or "—"),
        "- Repetition judged effective: " + (", ".join(f"{k} {v}" for k, v in result["repetition"]["judged_effective"].items()) or "—"),
        "",
        "## Anti-patterns and content flags",
        "",
        "- Anti-patterns: " + (", ".join(f"{k} {v}" for k, v in result["anti_patterns"].items()) or "—"),
        "- Content flags: " + (", ".join(f"{k} {v}" for k, v in result["content_flags"].items()) or "—"),
        "",
        f"## Child-appeal heuristic — *{result['appeal_heuristic']['label']}*",
        "",
    ]
    out += [f"- {d}: {_fmt_summary(s)}" for d, s in result["appeal_heuristic"]["dimensions"].items()] or ["- —"]
    return "\n".join(out)


# -- deep dive ---------------------------------------------------------------------

def deep_dive(store, work_id: str) -> str:
    work = store.get("work", work_id)
    analysis = store.latest("analysis", work_id)
    if work is None or analysis is None:
        raise ValueError(f"{work_id}: no analysis")
    pages = store.get("pages", f"{work_id}.v{analysis['analysis_version']}") or {"pages": []}
    edition = store.get("edition", analysis.get("edition_id")) or {}
    source = store.get("source", edition.get("source_id", "")) or {}
    m = analysis.get("metrics") or {}
    creators = ", ".join(f"{c['name']} ({c['role']})" for c in work.get("creators", []))
    c = work.get("classification") or {}
    out = [
        f"# Book deep dive — {work['title']}",
        "",
        f"{creators} · {work.get('first_publication_year') or 'year unknown'} · {work.get('original_language')}",
        "",
        f"- Analysis: v{analysis['analysis_version']} · status **{analysis.get('status')}** · "
        f"completeness **{analysis.get('completeness')}** · analyst {analysis.get('analyst') or '—'}",
        f"- Material: {edition.get('edition_id')} · rights {source.get('rights')} "
        f"({(source.get('rights_detail') or {}).get('jurisdiction') or (source.get('rights_detail') or {}).get('license') or '—'}) · "
        f"tier {source.get('tier')} · page boundaries **{pages.get('page_boundary_source')}**",
        f"- Age band: {c.get('age_band') or '—'} (basis: {c.get('age_band_basis') or '—'}) · "
        f"types: {', '.join(c.get('story_types', [])) or '—'} · structures: {', '.join(c.get('structures', [])) or '—'} · "
        f"tones: {', '.join(c.get('tones', [])) or '—'}",
        f"- Content flags: {', '.join(sorted(set(work.get('content_flags', [])) | set(analysis.get('content_flags', [])))) or 'none'} · "
        f"MagicPaper suitability: {(analysis.get('age_suitability') or {}).get('magicpaper') or (work.get('age_suitability') or {}).get('magicpaper') or '—'}",
        "",
        "This is one book. Nothing below generalises without the corpus.",
        "",
        "## Summary (paraphrase)",
        "",
        analysis.get("summary_paraphrase") or "—",
        "",
        "## Language",
        "",
    ]
    if m:
        wpp = m["words_per_page"]
        out += [f"- {m['pages']} pages, {m['total_words']} words; words per page {wpp['min']}-{wpp['max']} (median {wpp['median']})",
                f"- Mean sentence {m['mean_sentence_words']} words, longest {m['longest_sentence']}; type/token {m['type_token_ratio']}",
                f"- Dialogue share {m['dialogue_ratio']}, questions {m['questions']}, direct address {m['direct_address']}, sound words {m['sound_words']} (lexicon floor)",
                f"- Refrains: {len(m['repetition']['refrains'])} · repeated phrases: {len(m['repetition']['repeated_phrases'])} · end-rhyme pairs: {m['repetition']['end_rhyme_pairs']}"]
    else:
        out.append("- Not computed: the full text was not available. Analysis is **partial**.")
    out += ["", "## Page by page", "",
            "| Page | Words | Beat | Emotion (0-5) | What changes | Question left open | Page turn |",
            "|---|---|---|---|---|---|---|"]
    for page in pages["pages"]:
        words = (page.get("metrics") or {}).get("words", "—")
        turn = ", ".join(page.get("page_turn_mechanism") or []) or "—"
        if page.get("page_turn_strength"):
            turn += f" ({page['page_turn_strength']}/5)"
        out.append(f"| {page['page']} | {words} | {page.get('beat') or '—'} | {page.get('emotion') or '—'} "
                   f"{page.get('emotion_intensity') if page.get('emotion_intensity') is not None else ''} | "
                   f"{_cell(page.get('change'))} | {_cell(page.get('question_created'))} | {turn} |")
    curve = analysis.get("emotional_curve")
    out += ["", f"Emotional curve: {' → '.join(map(str, curve)) if curve else '—'}", "",
            "## Beats", ""]
    out += [f"- {b.get('beat')} p{b.get('start_page')}-{b.get('end_page')}: {b.get('function') or ''}"
            for b in sorted(analysis.get("beats", []), key=lambda b: b.get("start_page") or 0)] or ["- —"]
    out += ["", "## Characters", ""]
    for ch in analysis.get("characters", []):
        details = "; ".join(f"{k}: {ch[k]}" for k in ("desire", "fear", "change", "relation_to_protagonist",
                                                     "humor_source", "tension_source") if ch.get(k))
        out.append(f"- **{ch.get('name') or ch.get('id')}** ({ch.get('role')}) {details}")
    out += ["", f"Protagonist agency (1-5): {analysis.get('protagonist_agency') or '—'}", "", "## Repetition", ""]
    out += [f"- {r.get('type')}: {r.get('description')} — functions {', '.join(r.get('functions', []))}; "
            f"effective: {r.get('effective')}{' — ' + r['why'] if r.get('why') else ''}"
            for r in analysis.get("repetition", [])] or ["- —"]
    vis = analysis.get("visual_storytelling") or {}
    out += ["", "## Visual storytelling", ""]
    out += [f"- {n}" for n in vis.get("notes", [])] or ["- Not analysed (illustrations not available)."]
    out += ["", "## Strengths", ""] + ([f"- {s}" for s in analysis.get("strengths", [])] or ["- —"])
    out += ["", "## Weaknesses", ""] + ([f"- {s}" for s in analysis.get("weaknesses", [])] or ["- —"])
    out += ["", "## Anti-patterns observed", ""]
    out += [f"- {a.get('id')} (pages {a.get('pages')}): {a.get('note')}" for a in analysis.get("anti_patterns", [])] or ["- none recorded"]
    appeal = analysis.get("child_appeal_heuristic") or {}
    out += ["", f"## Child-appeal heuristic — *{appeal.get('label') or 'Research heuristic — not validated'}*", ""]
    out += [f"- {d}: {s}" for d, s in (appeal.get("scores") or {}).items()] or ["- not scored"]
    if appeal.get("rationale"):
        out += ["", appeal["rationale"]]
    out += ["", "## Against the corpus", ""]
    band = c.get("age_band")
    corpus = aggregate.compare(store, age_band=band)
    others = corpus["n_works"]
    if m and corpus["language"]["n_full_text_works"] > 1:
        out.append(f"- Words per page here: median {m['words_per_page']['median']}; corpus ({band}): "
                   f"{_fmt_summary(corpus['language']['words_per_page'])}")
        out.append(f"- Mean sentence here: {m['mean_sentence_words']}; corpus: {_fmt_summary(corpus['language']['mean_sentence_words'])}")
    else:
        out.append(f"- Corpus in band {band}: {others} complete analyses — too few to compare.")
    claims = [cl for cl in store.all("claim") if work_id in cl.get("supporting_works", []) + cl.get("counterexample_works", [])]
    out += ["", "## Claims this book bears on", ""]
    out += [f"- {cl['claim_id']}: {cl['statement']} — {'supports' if work_id in cl.get('supporting_works', []) else 'counterexample'} "
            f"({(cl.get('computed') or {}).get('confidence', '—')})" for cl in claims] or ["- none yet"]
    return "\n".join(out) + "\n"


def _cell(text) -> str:
    return (str(text).replace("|", "/").replace("\n", " ") if text else "—")


# -- claims and insights -------------------------------------------------------------

def claims_markdown(store) -> str:
    claims = sorted(store.all("claim"), key=lambda c: (c.get("status") != "active",
                    ["HIGH", "MEDIUM", "LOW", "HYPOTHESIS", None].index((c.get("computed") or {}).get("confidence")),
                    c["claim_id"]))
    out = ["| Claim | Kind | Scope | n (support/counter) | Confidence | Status |", "|---|---|---|---|---|---|"]
    for c in claims:
        comp = c.get("computed") or {}
        scope = c.get("scope", {})
        out.append(f"| {c['claim_id']}: {_cell(c['statement'])} | {c['kind']} | "
                   f"{scope.get('age_band') or 'all'}/{scope.get('language') or 'all'} | "
                   f"{comp.get('n_examined', '—')} ({comp.get('support', '—')}/{comp.get('counter', '—')}), "
                   f"{(comp.get('sample_scope') or '—').replace('_', ' ').lower()} | "
                   f"{comp.get('confidence', '—')} | {c['status']}{' — ' + c['rejected_reason'] if c.get('rejected_reason') else ''} |")
    return "\n".join(out)


def insights_markdown(store) -> str:
    rows = [c for c in store.all("claim") if c.get("magicpaper") and c.get("status") == "active"]
    out = ["Every entry names the engine field or content gate it would affect. The research agent can only "
           "write `proposed`; review, acceptance and implementation are separate, human-owned steps.", ""]
    if not rows:
        return "\n".join(out + ["No proposals yet."])
    by_status = {}
    for c in rows:
        by_status.setdefault(c["magicpaper"].get("review_status", "proposed"), []).append(c)
    for status in ("proposed", "reviewed", "accepted", "implemented", "declined"):
        group = by_status.get(status, [])
        if not group:
            continue
        out += [f"## {status.capitalize()}", ""]
        for c in group:
            mp, comp = c["magicpaper"], c.get("computed") or {}
            out += [f"### {c['claim_id']}", "",
                    f"- **Finding:** {c['statement']}",
                    f"- **Evidence:** {comp.get('support')} of {comp.get('n_examined')} works "
                    f"({(comp.get('sample_scope') or '').replace('_', ' ').lower()}), confidence **{comp.get('confidence')}**"
                    + (f", counterexamples: {', '.join(c.get('counterexample_works', []))}" if c.get("counterexample_works") else ""),
                    f"- **Target:** `{mp.get('target')}` · current: {mp.get('current') or '—'} · suggested: {mp.get('suggested') or '—'}",
                    f"- **Note:** {mp.get('note') or '—'}", ""]
    return "\n".join(out)


# -- run report ----------------------------------------------------------------------

def run_report(store, run: dict) -> str:
    s = status(store)
    states = s["states"]
    out = [
        f"# Children's Book Research Report — {run['run_id']}",
        "",
        f"{run['started_at']} → {run.get('finished_at') or 'open'} · goal: {run['goal']}",
        "",
        "## Corpus",
        "",
        f"- Works known: {s['works']} (this run added {len(run['works_added'])})",
        f"- Fully analysed: {states.get('analysed_full', 0)} · partially analysed: {states.get('analysed_partial', 0)} · "
        f"drafts: {states.get('analysis_draft', 0)} · ingested, not analysed: {states.get('ingested', 0)} · "
        f"metadata only: {states.get('metadata_only', 0)} · rejected: {states.get('rejected', 0)}",
        f"- Sources added: {len(run['sources_added'])} · editions added: {len(run['editions_added'])} · "
        f"analyses completed: {len(run['analyses_completed'])}",
        f"- Query strategy: {'; '.join(run.get('query_strategy', [])) or '—'}",
        f"- Queries run: {len(run['queries'])} · candidates considered: {len(run['candidates'])}",
        "",
    ]
    if run["failures"]:
        out += ["Failed or refused sources:", ""] + [f"- {f.get('url')}: {f.get('reason')}"
                                                    + (f" — {f['resolution']}" if f.get("resolution") else "")
                                                    for f in run["failures"]] + [""]

    claims = [c for c in store.all("claim") if c.get("status") == "active"]
    by_level = {lvl: [c for c in claims if (c.get("computed") or {}).get("confidence") == lvl]
                for lvl in ("HIGH", "MEDIUM", "LOW", "HYPOTHESIS")}

    def listing(items):
        return [f"{i}. {c['statement']} — {(c.get('computed') or {}).get('support')}/"
                f"{(c.get('computed') or {}).get('n_examined')} works ({c['claim_id']})"
                for i, c in enumerate(items, 1)] or ["—"]

    out += ["## Strong findings (HIGH)", ""] + listing(by_level["HIGH"]) + [""]
    out += ["## Emerging patterns (MEDIUM / LOW)", ""] + listing(by_level["MEDIUM"] + by_level["LOW"]) + [""]
    out += ["## Hypotheses", ""] + listing(by_level["HYPOTHESIS"]) + [""]
    contradicted = [c for c in claims if c.get("counterexample_works")]
    out += ["## Contradictions", ""]
    out += [f"{i}. {c['statement']} — counterexamples: {', '.join(c['counterexample_works'])}"
            for i, c in enumerate(contradicted, 1)] or ["—"]
    rejected = [c for c in store.all("claim") if c.get("status") == "rejected"]
    if rejected:
        out += ["", "Rejected hypotheses (kept so they are not rediscovered):", ""]
        out += [f"- {c['statement']} — {c.get('rejected_reason')}" for c in rejected]
    out += ["", "## Confidence changes this run", ""]
    out += [f"- {ch['claim_id']}: {ch['from']} → {ch['to']}" for ch in run.get("confidence_changes", [])] or ["- none"]
    out += [f"- new claim: {cid}" for cid in run.get("new_claims", [])]

    plan_band = "5-6"
    result = aggregate.compare(store, age_band=plan_band)
    out += ["", f"## Age {plan_band} corpus", "", compare_markdown(result).replace("\n## ", "\n### ")]
    out += ["", "## MagicPaper recommendations", "", insights_markdown(store).replace("\n## ", "\n### ")]
    found = gaps_module.gaps(store)
    out += ["", "## Research gaps → next tasks", ""]
    out += [f"- {g['gap']}: have {g['have']}, want {g['want']}"
            + (f" — try: “{g['suggested_queries'][0]}”" if g["suggested_queries"] else "")
            + (f" ({g['note']})" if g.get("note") else "") for g in found[:20]] or ["- none against the current plan"]
    if run.get("summary"):
        out += ["", "## Analyst summary", "", run["summary"]]
    return "\n".join(out) + "\n"


def corpus_markdown(store) -> str:
    out = ["| Work | Creators | Year | Lang | Age | Rights of material | Pages | Analysis |", "|---|---|---|---|---|---|---|---|"]
    editions = {e["edition_id"]: e for e in store.all("edition")}
    sources = {s["source_id"]: s for s in store.all("source")}
    for work in sorted(store.all("work"), key=lambda w: w["title"].lower()):
        analysis = store.latest("analysis", work["work_id"])
        edition = editions.get((analysis or {}).get("edition_id")) or (editions.get(work["editions"][0]) if work.get("editions") else None)
        rights = sources.get(edition["source_id"], {}).get("rights") if edition else "metadata_only"
        state = "rejected: " + work["rejected"].get("reason", "") if work.get("rejected") else (
            f"{analysis['status']} / {analysis.get('completeness')}" if analysis else ("ingested" if edition else "metadata"))
        out.append(f"| {_cell(work['title'])} ({work['work_id']}) | {_cell(', '.join(c['name'] for c in work.get('creators', [])))} | "
                   f"{work.get('first_publication_year') or '—'} | {work.get('original_language')} | "
                   f"{(work.get('classification') or {}).get('age_band') or '—'} | {rights} | "
                   f"{(edition or {}).get('page_boundary_source') or '—'} | {state} |")
    return "\n".join(out)
