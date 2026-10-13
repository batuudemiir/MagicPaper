#!/usr/bin/env python3
"""book-agent — MagicPaper Children's Book Intelligence CLI.

    python3 Research/BookIntelligence/book_agent.py status
    python3 Research/BookIntelligence/book_agent.py gaps
    python3 Research/BookIntelligence/book_agent.py run start --goal "..." --strategy "..."
    python3 Research/BookIntelligence/book_agent.py discover --source gutenberg --query "rabbit" --lang en
    python3 Research/BookIntelligence/book_agent.py discover --source ia --query "potter"
    python3 Research/BookIntelligence/book_agent.py discover --source bookdash --query "*"
    python3 Research/BookIntelligence/book_agent.py ingest gutenberg 14838 --age-band 5-6 --age-basis analyst
    python3 Research/BookIntelligence/book_agent.py ingest ia the-tale-of-peter-rabbit_202609
    python3 Research/BookIntelligence/book_agent.py ingest bookdash mud     # twice: images, then transcription
    python3 Research/BookIntelligence/book_agent.py images w_... --pages 1-4
    python3 Research/BookIntelligence/book_agent.py analyze w_tale_of_peter_rabbit_potter
    python3 Research/BookIntelligence/book_agent.py analyze w_... --complete --analyst book-research
    python3 Research/BookIntelligence/book_agent.py validate
    python3 Research/BookIntelligence/book_agent.py compare --age 5-6 --write
    python3 Research/BookIntelligence/book_agent.py insights
    python3 Research/BookIntelligence/book_agent.py deep-dive w_... --write
    python3 Research/BookIntelligence/book_agent.py run finish --summary "..."
    python3 Research/BookIntelligence/book_agent.py report

Only `discover`, `ingest gutenberg|ia|bookdash` and `images` use the network. Method and rules:
docs/research/BOOK_RESEARCH_AGENT.md and docs/research/RESEARCH_METHOD.md.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from bookintel import aggregate, analyze, confidence, cycle, exchange, experiments, gaps, ingest, report, runs  # noqa: E402
from bookintel.adapters.base import AccessRefused  # noqa: E402
from bookintel.adapters.bookdash import BookDashAdapter  # noqa: E402
from bookintel.adapters.gutenberg import GutenbergAdapter  # noqa: E402
from bookintel.adapters.internet_archive import InternetArchiveAdapter  # noqa: E402
from bookintel.schema import validate_store  # noqa: E402
from bookintel.store import Store  # noqa: E402
from bookintel.workspace import Workspace  # noqa: E402


def _creators(values: list[str]) -> list[dict]:
    """`Name:role` → creator dicts; role defaults to author."""
    out = []
    for value in values or []:
        name, _, role = value.rpartition(":") if ":" in value else (value, "", "author")
        out.append({"name": name.strip(), "role": (role or "author").strip()})
    return out


def _print(obj) -> None:
    print(json.dumps(obj, indent=2, ensure_ascii=False) if not isinstance(obj, str) else obj)


def cmd_status(store, args):
    s = report.status(store)
    _print(s if args.json else report.status_text(s))


def cmd_gaps(store, args):
    found = gaps.gaps(store)
    if args.json:
        _print(found)
        return
    if not found:
        print("No gaps against the current research plan.")
    for g in found:
        print(f"- {g['gap']}: have {g['have']}, want {g['want']}" + (f"  ({g['note']})" if g.get("note") else ""))
        for q in g["suggested_queries"][:3]:
            print(f"    query: {q}")


def cmd_run(store, args):
    if args.action == "start":
        run = runs.start(store, args.goal, args.strategy or [])
        print(f"Opened {run['run_id']}")
    else:
        confidence.recompute_all(store)
        run = runs.finish(store, args.summary)
        path = store.ws.docs / "reports" / f"{run['run_id']}.md"
        from bookintel.store import write_if_changed
        write_if_changed(path, report.run_report(store, run))
        print(f"Closed {run['run_id']} → {path}")


def cmd_discover(store, args):
    try:
        if args.source == "gutenberg":
            found = GutenbergAdapter(store.cache_path()).search(args.query, args.lang, args.shelf)
            rows = [(c["gutenberg_id"], c["title"], c["authors"], c["language"], c["issued"], c["page_url"])
                    for c in found]
        elif args.source == "ia":
            found = InternetArchiveAdapter().search(args.query, args.lang, rows=args.limit)
            rows = [(c["identifier"], c["title"], c["creator"], c["language"], c["year"], c["page_url"])
                    for c in found]
        else:
            slugs = BookDashAdapter().list_books()
            tokens = args.query.lower().split()
            rows = [(slug, slug.replace("-", " "), "Book Dash", "", "", f"https://bookdash.org/books/{slug}/")
                    for slug in slugs if all(t in slug for t in tokens) or args.query == "*"]
    except AccessRefused as error:
        runs.log(store, "failures", {"url": f"{args.source} search", "reason": str(error)})
        raise
    runs.log(store, "queries", {"adapter": args.source, "query": args.query, "lang": args.lang,
                                "shelf": args.shelf, "results": len(rows)})
    for key, title, creator, lang, year, url in rows[: args.limit]:
        print(f"{str(key):>24}  {str(title)[:60]} — {str(creator or '')[:35]} [{lang or ''}] {year or ''}")
        runs.log(store, "candidates", {"title": title, "creator": creator, "url": url, "decision": "listed",
                                       "reason": f"{args.source}: {args.query}"})
    print(f"{len(rows)} matches" + (f" (showing {args.limit})" if len(rows) > args.limit else ""))


def cmd_images(store, args):
    work = store.get("work", args.work_id)
    if work is None:
        raise SystemExit(f"unknown work {args.work_id}")
    edition_id = args.edition or (work["editions"][0] if work.get("editions") else None)
    wanted = None
    if args.pages:
        wanted = set()
        for part in args.pages.split(","):
            low, _, high = part.partition("-")
            wanted.update(range(int(low), int(high or low) + 1))
    for item in ingest.page_images(store, edition_id, sorted(wanted) if wanted else None):
        print(f"page {item['page']}: " + "  ".join(item["files"]))


def cmd_ingest(store, args):
    common = {"age_band": args.age_band, "basis": args.age_basis, "force_work": args.work,
              "force_new": args.new_work}
    if args.route == "gutenberg":
        result = ingest.ingest_gutenberg(store, int(args.id), mode=args.mode, **common)
    elif args.route == "ia":
        result = ingest.ingest_internet_archive(store, args.id, confirm_scan=args.confirm_scan,
                                                transcribe=args.transcribe, **common)
        if result["decision"] == "needs_transcription":
            print(f"Leaf images: {result['images']}\nCorrect the OCR draft in: {result['transcription']}\n"
                  f"Then run the same command again (without --transcribe).")
    elif args.route == "bookdash":
        result = ingest.ingest_bookdash(store, args.id, **common)
        if result["decision"] == "needs_transcription":
            print(f"Page images: {result['images']}\nTranscribe into: {result['transcription']}\n"
                  f"Then run the same command again.")
    else:
        detail = {k: v for k, v in {"jurisdiction": args.jurisdiction, "basis": args.basis_text,
                                    "license": args.license, "attribution": args.attribution,
                                    "licence_reference": args.licence_ref}.items() if v}
        result = ingest.ingest_manual(
            store, Path(args.path), url=args.url, rights=args.rights, rights_detail=detail,
            kind=args.kind, tier=args.tier, title=args.title, creators=_creators(args.creator),
            language=args.lang, page_boundary_source=args.boundary, year=args.year,
            original_language=args.original_lang, edition_id=args.edition_id,
            text_origin=args.text_origin, **common)
    _print(result)


def cmd_work(store, args):
    if args.action == "add":
        _print(ingest.add_metadata_work(store, title=args.title, creators=_creators(args.creator),
                                        language=args.lang, year=args.year, age_band=args.age_band,
                                        basis=args.age_basis, force_new=args.new_work))
    else:
        work = store.get("work", args.work_id)
        if work is None:
            raise SystemExit(f"unknown work {args.work_id}")
        work["rejected"] = {"reason": args.reason, "at": runs.now()}
        store.put("work", work)
        print(f"Rejected {args.work_id}")


def cmd_source(store, args):
    ingest.add_source(store, source_id=args.id, url=args.url, kind=args.kind, tier=args.tier,
                      rights=args.rights, note=args.note)
    print(f"Recorded source {args.id}")


def cmd_analyze(store, args):
    key = f"{args.work_id}.v{args.version}"
    if args.complete:
        _print(analyze.complete(store, args.work_id, args.version, args.analyst or "unknown"))
        return
    if store.get("analysis", key) is None:
        _print(analyze.scaffold(store, args.work_id, args.version, args.edition, args.pages))
        print(f"Fill judgments in:\n  {store.path('pages', key)}\n  {store.path('analysis', key)}")
    result = analyze.refresh(store, args.work_id, args.version)
    print(f"{key}: completeness {result['completeness']}; pages missing judgments: {len(result['missing'])}")
    for line in result["missing"][:10]:
        print(f"  {line}")


def cmd_metrics(store, args):
    targets = [a for a in store.all("analysis") if not args.work_id or a["work_id"] == args.work_id]
    for a in targets:
        analyze.refresh(store, a["work_id"], a["analysis_version"])
    print(f"Refreshed {len(targets)} analyses")


def cmd_validate(store, args):
    errors = validate_store(store) + exchange.validate(store)
    for error in errors:
        print(f"✗ {error}")
    print(f"{'FAILED' if errors else 'OK'}: {len(errors)} errors")
    return 1 if errors else 0


def cmd_compare(store, args):
    result = aggregate.compare(store, args.age, args.lang)
    if args.json:
        _print(result)
    else:
        print(report.compare_markdown(result))
    store.write_index(f"patterns_{args.age or 'all'}_{args.lang or 'all'}", result)
    if args.write:
        name = f"{args.age or 'all'}_{args.lang or 'all'}"
        path = store.ws.docs / "patterns" / f"{name}.md"
        report.write_generated(path, f"Patterns — age {args.age or 'all'}, language {args.lang or 'all'}",
                               report.compare_markdown(result),
                               "Generated by `book-agent compare --write`. Interpretation goes outside the generated block.")
        print(f"→ {path}")


def cmd_insights(store, args):
    changes = confidence.recompute_all(store)
    docs = store.ws.docs
    report.write_generated(docs / "FINDINGS.md", "Research findings", report.claims_markdown(store),
                           "Every claim with its evidence count, scope and computed confidence. "
                           "Confidence is calculated by `book-agent insights`, never written by hand.")
    report.write_generated(docs / "MAGICPAPER_STORY_INSIGHTS.md", "MagicPaper Story Design Insights",
                           report.insights_markdown(store),
                           "Research → analysis → insight → **human review** → product rule → implementation.")
    for change in changes:
        print(f"{change['claim_id']}: {change['from']} → {change['to']}")
    print(f"{len(changes)} confidence changes · docs refreshed in {docs}")


def cmd_deep_dive(store, args):
    text = report.deep_dive(store, args.work_id)
    if args.write:
        path = store.ws.docs / "deep-dives" / f"{args.work_id}.md"
        from bookintel.store import write_if_changed
        write_if_changed(path, text)
        print(f"→ {path}")
    else:
        print(text)


def cmd_report(store, args):
    all_runs = sorted(store.all("run"), key=lambda r: r["run_id"])
    run = next((r for r in all_runs if r["run_id"] == args.run), None) if args.run else (all_runs[-1] if all_runs else None)
    if run is None:
        raise SystemExit("no run to report on — `run start` first")
    from bookintel.store import write_if_changed
    path = store.ws.docs / "reports" / f"{run['run_id']}.md"
    write_if_changed(path, report.run_report(store, run))
    report.write_generated(store.ws.docs / "BOOK_CORPUS.md", "Book corpus", report.corpus_markdown(store),
                           "Every work the research knows about, with the rights of the material it was read from.")
    print(f"→ {path}")


def _split(value):
    return [v.strip() for v in (value or "").split(",") if v.strip()]


def cmd_exchange(store, args):
    a = args.action
    if a == "open":
        claims = [c["claim_id"] for c in store.all("claim") if c.get("magicpaper") and c.get("status") == "active"] \
            if args.target == "--all" or args.all else [args.target]
        for cid in claims:
            print(exchange.open_proposal(store, cid))
    elif a == "post":
        turn = exchange.post(store, exchange.check_id(args.target), args.agent, args.stance, args.text,
                             _split(args.evidence), args.reply_to)
        print(f"posted {turn['id']}")
    elif a == "impact":
        exchange.set_impact(store, exchange.check_id(args.target), args.agent, fields=_split(args.fields),
                            files=_split(args.files), tests=_split(args.tests), owner=args.owner or "story-engine",
                            cost=args.cost, reversible=args.reversible == "yes", notes=args.notes or "")
        print("impact recorded")
    elif a == "prototype":
        exchange.set_prototype(store, exchange.check_id(args.target), args.agent, path=args.path,
                               description=args.description or "")
        print("prototype recorded")
    elif a == "safety":
        exchange.set_safety(store, exchange.check_id(args.target), args.agent, verdict=args.verdict,
                            notes=args.notes or "")
        print("safety recorded")
    elif a == "recommend":
        exchange.recommend(store, exchange.check_id(args.target), args.agent, action=args.rec_action,
                           rationale=args.rationale or "")
        print("recommendation recorded")
    elif a == "decide":
        exchange.decide(store, exchange.check_id(args.target), verdict=args.verdict, note=args.note or "")
        print("decision recorded")
    elif a == "show":
        print(exchange.render(store, exchange.check_id(args.target)))
    elif a == "lessons":
        _print(exchange.lessons(store))
    else:  # digest
        for path in exchange.write_docs(store):
            print(f"→ {path}")


def cmd_experiment(store, args):
    a = args.action
    if a == "create":
        record = experiments.create(store, experiment_id=args.id, proposal_id=args.proposal, control=args.control,
                                    variant=args.variant, age_band=args.age_band, mode=args.mode,
                                    direction=args.direction, min_effect=args.min_effect,
                                    confidence=args.confidence, rationale=args.rationale or "",
                                    bedtime_specific=args.bedtime_specific)
        print(f"registered {record['experiment_id']} (draft) with prediction: {args.direction} "
              f"by ≥{args.min_effect}, confidence {args.confidence}")
    elif a == "preflight":
        problems = experiments.preflight(store, args.id, Path(args.package) if args.package else None)
        print("READY" if not problems else "NOT READY:\n  " + "\n  ".join(problems))
        return 0 if not problems else 1
    elif a == "mark":
        experiments.mark(store, args.id, args.status, args.note or "")
        print(f"{args.id} → {args.status}")
    elif a == "show":
        _print(experiments.get(store, args.id))
    else:
        for e in experiments.all_experiments(store):
            print(f"{e['experiment_id']:28} {e['status']:10} {e['control']} ↔ {e['variant']} ({e['age_band']}, {e['mode']})")


def cmd_usage(store, args):
    print(f"imported period ending {experiments.import_usage(store, Path(args.path))}")


def cmd_evaluate(store, args):
    _print(experiments.evaluate(store))


def cmd_calibration(store, args):
    _print(experiments.calibration(store))


def cmd_cycle(store, args):
    result = cycle.run(store)
    print(f"imported {len(result['imported'])} usage period(s), refused {len(result['refused'])}; "
          f"{len(result['experiments'])} experiment(s) evaluated; {len(result['confidence'])} confidence change(s)")
    print(f"→ {result['path']}")


def cmd_review(store, args):
    _print(store.review_items())


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="book-agent", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="command", required=True)

    s = sub.add_parser("status"); s.add_argument("--json", action="store_true"); s.set_defaults(fn=cmd_status)
    s = sub.add_parser("gaps"); s.add_argument("--json", action="store_true"); s.set_defaults(fn=cmd_gaps)

    s = sub.add_parser("run"); s.add_argument("action", choices=["start", "finish"])
    s.add_argument("--goal"); s.add_argument("--strategy", action="append"); s.add_argument("--summary")
    s.set_defaults(fn=cmd_run)

    s = sub.add_parser("discover", help="search a vetted source for candidate books")
    s.add_argument("--source", choices=["gutenberg", "ia", "bookdash"], default="gutenberg")
    s.add_argument("--query", required=True, help="'*' lists every Book Dash book"); s.add_argument("--lang")
    s.add_argument("--shelf", help="e.g. \"Children's Picture Books\"")
    s.add_argument("--limit", type=int, default=20); s.set_defaults(fn=cmd_discover)

    s = sub.add_parser("ingest"); routes = s.add_subparsers(dest="route", required=True)
    for route in ("gutenberg", "ia", "bookdash", "file"):
        r = routes.add_parser(route)
        if route == "gutenberg":
            r.add_argument("id")
            r.add_argument("--mode", choices=["illustrations", "pack"], default="illustrations")
        elif route in ("ia", "bookdash"):
            r.add_argument("id", help="Internet Archive identifier / Book Dash slug")
            if route == "ia":
                r.add_argument("--confirm-scan", action="store_true",
                               help="user upload: you viewed its images and they reproduce the printed book")
                r.add_argument("--transcribe", action="store_true",
                               help="write an OCR draft + leaf images for correction instead of ingesting OCR")
        else:
            r.add_argument("path")
            r.add_argument("--url", required=True); r.add_argument("--rights", required=True)
            r.add_argument("--kind", default="authorized_full_text"); r.add_argument("--tier", default="A")
            r.add_argument("--title", required=True); r.add_argument("--creator", action="append", required=True,
                                                                       help="'Name:role' (role defaults to author)")
            r.add_argument("--lang", required=True); r.add_argument("--original-lang")
            r.add_argument("--boundary", required=True, choices=["original_scan", "publisher_layout", "reconstructed"])
            r.add_argument("--year", type=int); r.add_argument("--edition-id")
            r.add_argument("--jurisdiction"); r.add_argument("--basis-text")
            r.add_argument("--license"); r.add_argument("--attribution"); r.add_argument("--licence-ref")
            r.add_argument("--text-origin", default="publisher_text",
                           choices=["publisher_text", "plain_text_edition", "ocr", "analyst_transcription"])
        r.add_argument("--age-band"); r.add_argument("--age-basis")
        r.add_argument("--work", help="attach to this existing work (resolves a dedup ambiguity)")
        r.add_argument("--new-work", action="store_true", help="treat as a new work (resolves a dedup ambiguity)")
    s.set_defaults(fn=cmd_ingest)

    s = sub.add_parser("work"); s.add_argument("action", choices=["add", "reject"])
    s.add_argument("work_id", nargs="?"); s.add_argument("--reason")
    s.add_argument("--title"); s.add_argument("--creator", action="append"); s.add_argument("--lang")
    s.add_argument("--year", type=int); s.add_argument("--age-band"); s.add_argument("--age-basis")
    s.add_argument("--new-work", action="store_true"); s.set_defaults(fn=cmd_work)

    s = sub.add_parser("source", help="record a source (review, award list, library record…) without its body")
    s.add_argument("action", choices=["add"]); s.add_argument("--id", required=True); s.add_argument("--url", required=True)
    s.add_argument("--kind", required=True); s.add_argument("--tier", required=True)
    s.add_argument("--rights", default="commentary"); s.add_argument("--note", required=True)
    s.set_defaults(fn=cmd_source)

    s = sub.add_parser("analyze"); s.add_argument("work_id"); s.add_argument("--version", default="1")
    s.add_argument("--edition"); s.add_argument("--pages", type=int)
    s.add_argument("--complete", action="store_true"); s.add_argument("--analyst")
    s.set_defaults(fn=cmd_analyze)

    s = sub.add_parser("images", help="local page images for the analyst to look at")
    s.add_argument("work_id"); s.add_argument("--edition"); s.add_argument("--pages", help="e.g. 1-4,9")
    s.set_defaults(fn=cmd_images)

    s = sub.add_parser("metrics"); s.add_argument("work_id", nargs="?"); s.set_defaults(fn=cmd_metrics)
    s = sub.add_parser("validate"); s.set_defaults(fn=cmd_validate)
    s = sub.add_parser("compare"); s.add_argument("--age"); s.add_argument("--lang")
    s.add_argument("--json", action="store_true"); s.add_argument("--write", action="store_true"); s.set_defaults(fn=cmd_compare)
    s = sub.add_parser("insights"); s.set_defaults(fn=cmd_insights)
    s = sub.add_parser("deep-dive"); s.add_argument("work_id"); s.add_argument("--write", action="store_true")
    s.set_defaults(fn=cmd_deep_dive)
    s = sub.add_parser("report"); s.add_argument("--run"); s.set_defaults(fn=cmd_report)
    s = sub.add_parser("review"); s.set_defaults(fn=cmd_review)

    s = sub.add_parser("exchange", help="idea exchange between agents (see docs/research/EXCHANGE_PROTOCOL.md)")
    s.add_argument("action", choices=["open", "post", "impact", "prototype", "safety", "recommend", "decide",
                                      "show", "digest", "lessons"])
    s.add_argument("target", nargs="?", help="claim id (open) or proposal id")
    s.add_argument("--all", action="store_true", help="open: every active claim with a MagicPaper proposal")
    s.add_argument("--agent"); s.add_argument("--stance"); s.add_argument("--text")
    s.add_argument("--evidence", help="comma-separated claim ids, work ids, repo paths or URLs")
    s.add_argument("--reply-to")
    s.add_argument("--fields"); s.add_argument("--files"); s.add_argument("--tests"); s.add_argument("--owner")
    s.add_argument("--cost", choices=["S", "M", "L"]); s.add_argument("--reversible", choices=["yes", "no"])
    s.add_argument("--notes"); s.add_argument("--path"); s.add_argument("--description")
    s.add_argument("--verdict"); s.add_argument("--note")
    s.add_argument("--action", dest="rec_action",
                   choices=["experiment", "adopt_guidance", "research_more", "park", "decline"])
    s.add_argument("--rationale")
    s.set_defaults(fn=cmd_exchange)

    s = sub.add_parser("experiment", help="experiments that test approved proposals with children")
    s.add_argument("action", choices=["create", "preflight", "mark", "show", "list"])
    s.add_argument("id", nargs="?", help="experiment id (x_…)")
    s.add_argument("--proposal"); s.add_argument("--control"); s.add_argument("--variant")
    s.add_argument("--age-band"); s.add_argument("--mode")
    s.add_argument("--direction", choices=["better", "worse", "same"])
    s.add_argument("--min-effect", type=float, default=0.03, help="smallest difference in rate that matters")
    s.add_argument("--confidence", type=float, help="probability you give your predicted direction (0.5-0.99)")
    s.add_argument("--rationale"); s.add_argument("--bedtime-specific", action="store_true")
    s.add_argument("--package", help="remote content package that carries the variant")
    s.add_argument("--status", choices=["live", "stopped"]); s.add_argument("--note")
    s.set_defaults(fn=cmd_experiment)

    s = sub.add_parser("usage", help="import one server aggregate (outcomeAggregates export)")
    s.add_argument("action", choices=["import"]); s.add_argument("path"); s.set_defaults(fn=cmd_usage)
    s = sub.add_parser("evaluate", help="score live experiments against imported usage"); s.set_defaults(fn=cmd_evaluate)
    s = sub.add_parser("calibration", help="how well the research agent's predictions held"); s.set_defaults(fn=cmd_calibration)
    s = sub.add_parser("cycle", help="the weekly deterministic loop + one-page report"); s.set_defaults(fn=cmd_cycle)
    return p


def main(argv: list[str] | None = None, workspace: Workspace | None = None) -> int:
    args = build_parser().parse_args(argv)
    store = Store(workspace or Workspace.default())
    try:
        return args.fn(store, args) or 0
    except (ingest.IngestError, analyze.AnalyzeError, exchange.ExchangeError, experiments.ExperimentError,
            AccessRefused, RuntimeError,
            ValueError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
