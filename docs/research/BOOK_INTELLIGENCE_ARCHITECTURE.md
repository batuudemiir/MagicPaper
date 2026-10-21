# Children's Book Intelligence Agent — Architecture Proposal

2026-10-07 · Status: **approved 2026-10-08 (D1-D10 as recommended); MVP built.**
Usage: [BOOK_RESEARCH_AGENT.md](BOOK_RESEARCH_AGENT.md) · method: [RESEARCH_METHOD.md](RESEARCH_METHOD.md).

### What changed while building (2026-10-08)

- **Gutendex dropped.** Its robots.txt disallows `/books/` for every agent. The Gutenberg adapter
  uses Project Gutenberg's own program channels instead: the catalog feed
  (`cache/epub/feeds/pg_catalog.csv.gz`, searched locally, refreshed every 30 days), the per-book
  RDF (rights statement, roles, downloads) and `cache/epub/N/pgN.txt`.
- **robots.txt failures refuse.** If robots.txt cannot be read (other than 404) the fetch is refused.
- **macOS python.org builds** lack a CA bundle; the client falls back to `/etc/ssl/cert.pem`.
  Certificate verification is never disabled.
- **Validators are Python** (`bookintel/schema.py`), not JSON Schema files: no dependency needed.
- **Generated docs:** `BOOK_CORPUS.md`, `FINDINGS.md`, `MAGICPAPER_STORY_INSIGHTS.md`,
  `patterns/<age>_<lang>.md`, `deep-dives/`, `reports/`. The topic files listed in the brief
  (STORY_STRUCTURE_PATTERNS etc.) are folded into `patterns/` until the corpus is large enough
  to need them split.
- **Sources added 2026-10-08 (D7 approved):** Internet Archive (public-domain scans: real page
  boundaries, page images, OCR) and Book Dash (CC BY 4.0 contemporary picture books: page images,
  analyst transcription). African Storybook and StoryWeaver are manual-only; see [SOURCES.md](SOURCES.md).
- **Learning loop (2026-10-08, product owner):** the goal is a loop where research learns, agents argue
  proposals, and the app improves. Decision: one human gate at "reaches children"; everything before it is
  automatic. Built first: the idea exchange ([EXCHANGE_PROTOCOL.md](EXCHANGE_PROTOCOL.md)). Next: experiment arms
  in the engine, usage data (FAZ 14/16) flowing back as `child_response` evidence, heuristic calibration,
  scheduled weekly runs. This supersedes §8's "agent can only write proposed": the agent still cannot decide,
  but it now drives proposals through other agents to a decision-ready state.
- **Loop closed (2026-10-13):** experiment registry with pre-registered predictions and preflight gates;
  server aggregation `aggregateOutcomes` (firebase/functions/src/outcomes.js, not deployed); usage import with
  the privacy floor; Beta-binomial evaluation feeding `child_response` evidence; prediction calibration;
  `book-agent cycle`; weekly scheduled task. No engine code changed: arms are sibling blueprints in remote
  packages, identified by blueprintID.
- **Live smoke test** (scratch workspace, not committed): catalog search for "rabbit" on the picture-book
  shelf returned 6 works; ingesting Gutenberg 14838 and 14304 produced one work with two editions
  (dedup held), 16 reconstructed pages, 982 words; `validate` clean.

This document proposes how MagicPaper can study real children's books and turn what
it learns into reviewed guidance for the content line. It is Phase 0 + Phase 1 of the
brief. Decisions that need a human are collected in §13.

---

## 0. What the inspection found

The research agent is not starting from nothing. Three things already exist and the
design is built around them, not beside them.

| Existing | What it means for the research agent |
|---|---|
| `docs/AGE_BANDING.md` (2026-09-16) | A first, hand-made research pass. Its rule — *"a finding without an engine field is not written here"* — is exactly the translation layer the brief asks for. The agent continues this document's method at scale; it does not replace it. |
| `PROSE_PRODUCTION_GUIDE.md` §1 "harvest" | The team already learned that what transfers from existing text is **rhetorical moves** (ordinary-then-interruption, sound before sight), not sentences. Research output is shaped the same way. |
| `StoryEngine` vocabulary: `StoryBeat` (32 beats), `EmotionalState` (with `intensity` 0-3), `CuriosityMechanism`, `ConflictMechanism`, `ResolutionMechanism`, `NarrativeFamily.minimumAge`, `AgeBand.pageBudget / maxSentenceWords`, `TextMetrics` | The insight layer maps findings onto these names. The research vocabulary itself stays external (HOOK, SETUP, …) so that the engine's current shape does not bias what the research sees. |
| `StoryEngine/Tools/validate_beat_corpus.py` | House convention for offline content tooling: Python 3 stdlib, no dependencies, reads JSON, exits non-zero on failure. The research tool follows it. |
| `Scripts/ContentPublisher` | Precedent for a separate tool package next to the app that reads, but never forks, engine rules. |
| İçerik hattı (Faz Planı Ekim, §İÇERİK HATTI) | The real consumer. Insights reach the product as writing guidance for Batuhan and as proposed gate changes (e.g. the 18-38 word band, 14-word sentence ceiling), after review. |

Things the agent must not touch, confirmed by inspection: `StoryEngine/Sources/**`,
`StoryGenerationManager.swift` (single-owner), `Content/DailyFeed`, catalogs, scene library,
avatar, paywall/RevenueCat, the app target. The research subsystem has **no runtime path
into the app** and never handles child data.

---

## 1. Recommended architecture

Split by what can be computed honestly and what needs judgment.

```
                ┌───────────────────────────────────────────────┐
                │  Analyst: Claude Code agent `book-research`   │
                │  discovers, reads, judges (beats, emotion,    │
                │  page-turn, characters, humor, appeal)        │
                └──────────────┬──────────────▲─────────────────┘
                   writes JSON │              │ reads status, gaps,
                   per schema  ▼              │ corpus, prior findings
┌──────────────────────────────────────────────────────────────────┐
│  `book-agent` CLI (Python 3 stdlib, deterministic)               │
│                                                                  │
│  adapters/  →  ingest/  →  metrics/  →  store/  →  aggregate/  → report/
│  (legal       (segment,     (words,      (JSON     (patterns,     (md
│   sources)     dedup,        sentences,   files,    confidence,    reports)
│                rights)       repetition)  schemas)  gaps)                    │
└──────────────────────────────────────────────────────────────────┘
                               │ writes only to
                               ▼
        Research/BookIntelligence/data/   docs/research/*.md
                               │
                     HUMAN REVIEW (Batuhan / product)
                               │
                 product rule → content line / engine field (separate task)
```

**Why the split.** A heuristic cannot detect "this page ends on a reveal" or "the companion
works as an emotional amplifier". Pretending it can would produce exactly the fake insights
§42 of the brief forbids. So:

- **The CLI** does everything mechanical and checkable: acquisition from vetted sources,
  rights enforcement, page segmentation, text metrics, deduplication, schema validation,
  evidence aggregation, confidence calculation, contradiction bookkeeping, gap detection,
  reports. Same input → same output. Fully unit-tested on fixtures.
- **The analyst** (a Claude Code agent run by a person in a session) does the reading and
  judgment, and must write it in the schema. The CLI rejects analyses that break the schema,
  cite unrecorded sources, or carry text they are not allowed to carry.
- **No LLM API calls from the CLI** in the MVP. Low-cost first; and keeping judgment in a
  reviewed session keeps it auditable. An API-backed analyst can be added later behind the
  same schema if volume requires it (§13, D2).

---

## 2. Module structure

Location: inside the git repo (`MagicPaper/`), isolated from app and engine.

```
MagicPaper/Research/BookIntelligence/
  book_agent.py                 # CLI entry: python3 Research/BookIntelligence/book_agent.py <cmd>
  bookintel/
    schema/                     # JSON Schemas + Python validators (stdlib only)
      book.schema.json  work.schema.json  source.schema.json
      analysis.schema.json  page.schema.json  insight.schema.json  run.schema.json
    vocab/
      research_vocab.json       # beats, emotions, page-turn mechanisms, humor types, tones…
      engine_mapping.json       # research term → StoryEngine term (many-to-many, with notes)
    adapters/                   # one file per source; network only here
      base.py                   # Adapter protocol: search / fetch_metadata / fetch_text
      gutenberg.py              # Project Gutenberg catalog feed + RDF + text (public domain)
      internet_archive.py       # IA scans with page structure (PD only)
      openlibrary.py            # metadata, editions, subjects (no text)
      storyweaver.py            # CC-licensed, page-structured picture books (verify terms first)
      manual.py                 # a person drops in a file + provenance (e.g. a licensed text)
    ingest/
      rights.py                 # rights model + storage policy enforcement
      segment.py                # page/spread segmentation; records page_boundary_source
      dedup.py                  # work/edition/translation resolution
    metrics/
      text.py                   # words, sentences, n-grams (port of TextMetrics rules, TR-aware)
      language.py               # dialogue ratio, questions, direct address, sound words, rhyme
      repetition.py             # repeated phrases/structures, cumulative patterns
    store/
      repo.py                   # read/write data/, stable ordering, no duplicates
    aggregate/
      patterns.py               # cross-book distributions by age/lang/genre/tone
      confidence.py             # deterministic confidence + sample-scope labels
      contradictions.py         # counterexample tracking
      gaps.py                   # corpus-coverage gaps → research tasks
    report/
      run_report.py  deep_dive.py  docs_writer.py
  data/                         # the knowledge base (committed)
  cache/                        # fetched raw material (gitignored, reproducible by URL+sha256)
  tests/                        # unittest, fixtures only, no network
    fixtures/
```

Docs (committed, human-readable, regenerated sections are marked as such):

```
MagicPaper/docs/research/
  BOOK_RESEARCH_AGENT.md   RESEARCH_METHOD.md   BOOK_CORPUS.md
  STORY_STRUCTURE_PATTERNS.md   AGE_BAND_PATTERNS.md   LANGUAGE_PATTERNS.md
  CHILD_APPEAL_PATTERNS.md   VISUAL_STORYTELLING_PATTERNS.md   ANTI_PATTERNS.md
  MAGICPAPER_STORY_INSIGHTS.md   reports/<date>-<run>.md   deep-dives/<work-id>.md
```

Agent definition: `.claude/agents/book-research.md` (next to the existing 15 agents), narrow
scope: may write only `Research/BookIntelligence/**` and `docs/research/**`.

---

## 3. Data model

Storage: **one JSON file per record** under `data/`, plus regenerated index files. Reasons:
no new dependency (no SQLite schema to migrate), diffs are reviewable line by line, parallel
sessions do not fight over one giant `books.json`, and git history *is* the audit trail.

```
data/
  works/<work_id>.json          # the book as a work (dedup unit, evidence-count unit)
  editions/<edition_id>.json    # a specific edition/translation/format of a work
  sources/<source_id>.json      # every URL/document used, with tier + rights
  analyses/<work_id>.<analysis_version>.json   # book-level analysis
  pages/<work_id>.<analysis_version>.json      # page/spread-level analysis
  claims/<claim_id>.json        # insights with evidence + counterexamples
  runs/<run_id>.json            # research runs
  index/                        # generated: works.json, patterns.json, gaps.json (never hand-edited)
```

### 3.1 Work and edition (dedup)

Evidence is counted on **works**, never editions, so a translation or a reprint cannot
inflate a claim.

```json
{
  "work_id": "w_tale_of_peter_rabbit",
  "title": "The Tale of Peter Rabbit",
  "creators": [{"name": "Beatrix Potter", "role": "author"}, {"name": "Beatrix Potter", "role": "illustrator"}],
  "first_publication_year": 1902,
  "original_language": "en",
  "editions": ["e_gutenberg_14838", "e_ia_taleofpeterrabbit00pott"],
  "translation_of": null,
  "classification": {
    "age_band": "5-6", "age_band_basis": "publisher|library|derived|analyst", "age_band_confidence": "MEDIUM",
    "story_types": ["adventure", "rule-breaking"], "structures": ["problem-attempt-failure-solution", "circular"],
    "tones": ["suspenseful", "comforting"], "visual_style": ["illustration+short-text"]
  },
  "evidence": {
    "popularity": [{"kind": "long_term_in_print", "source_id": "s_…", "observed": "…"}],
    "quality":    [{"kind": "award", "source_id": "s_…", "observed": "…"}],
    "adult_interpretation": [{"who": "librarian|teacher|parent|reviewer", "source_id": "s_…", "paraphrase": "…"}]
  },
  "content_flags": ["peril", "death_reference"],
  "age_suitability": {"magicpaper_5_6": "adapt_with_care", "notes": "…"},
  "read_status": "full|partial|metadata_only|rejected",
  "rejection_reason": null
}
```

Dedup keys: normalized title (case, punctuation, articles, diacritics folded) + primary
creator + original language; ISBN / OCLC / Open Library work id / Wikidata QID when
available. Ambiguous matches are *not* merged automatically — they go to a review list.

### 3.2 Source and trust

```json
{
  "source_id": "s_gutenberg_14838",
  "url": "https://www.gutenberg.org/ebooks/14838",
  "kind": "authorized_full_text|publisher_page|library_record|award_listing|professional_review|educational_org|book_database|parent_review|teacher_discussion|community|aggregator",
  "tier": "A|B|C|D",
  "rights": "public_domain|open_license|licensed|publisher_preview|metadata_only|commentary",
  "rights_detail": {"jurisdiction": "US", "license": null, "attribution": null, "verified_on": "2026-10-07"},
  "retrieved_at": "…", "content_sha256": "…", "robots_ok": true, "terms_checked": true
}
```

Tiers follow the brief (A: publisher, library, award body, authorized text · B: professional
review, educational org, reputable database · C: parent/teacher/community · D: anonymous
aggregation). Tier D can never be the only support for a claim.

### 3.3 Page analysis

```json
{
  "work_id": "w_…", "edition_id": "e_…", "analysis_version": "1",
  "page_boundary_source": "original_scan|publisher_layout|reconstructed",
  "text_stored": true,
  "pages": [{
    "page": 4, "spread": false,
    "text": "…only when rights ∈ {public_domain, open_license}, else omitted…",
    "metrics": {"words": 32, "sentences": 3, "longest_sentence": 14, "dialogue_ratio": 0.0, "questions": 1},
    "beat": "COMPLICATION", "engine_beats": ["obstacle_raises"],
    "emotion": "fear", "emotion_intensity": 4,
    "characters": ["peter", "mr_mcgregor"], "location": "garden",
    "change": "…", "question_created": "…",
    "page_turn_mechanism": ["danger", "anticipation"], "page_turn_strength": 4,
    "illustration": {"available": true, "only_in_image": "…", "function": "visual reveal"},
    "humor": [], "repetition": ["callback"],
    "label": "OBSERVED|INFERRED"
  }]
}
```

`metrics` is computed by the CLI and overwritten on every run; the analyst cannot set it.
Judgment fields are the analyst's, and every judgment field carries `OBSERVED` (visible in
the text/image) or `INFERRED`.

Book-level analysis holds: beat sequence with page position (as % of book), emotional curve,
characters (role, desire, fear, change, relation to protagonist, humor/tension source),
humor map, repetition map, visual-storytelling notes, strengths, weaknesses, anti-patterns
observed, and the experimental **child-appeal heuristic** (10 dimensions, 1-5, always
labelled *"Research heuristic — not validated"*).

### 3.4 Claim (insight)

```json
{
  "claim_id": "c_participation_phrases_5_6_en",
  "statement": "Repeated participation phrases appear in most analyzed read-aloud books for 5-6 (en).",
  "kind": "OBSERVED|INFERRED|HYPOTHESIS",
  "layer": "popularity|adult_interpretation|textual_mechanism|combined",
  "scope": {"age_band": "5-6", "language": "en", "genre": null},
  "supporting_works": ["w_…"], "counterexample_works": ["w_…"], "sources": ["s_…"],
  "computed": {"n_analyzed_in_scope": 15, "support": 12, "counter": 3, "sample_scope": "CORPUS"},
  "confidence": "MEDIUM", "confidence_history": [{"run_id": "r_…", "value": "LOW"}],
  "status": "active|rejected|superseded", "rejected_reason": null
}
```

`computed` and `confidence` are always recalculated by the CLI from the evidence; the analyst
proposes the statement and the evidence links, never the confidence.

---

## 4. Legal and content-acquisition boundaries

This is the part the tool enforces in code, not in a prompt.

| Rights | May fetch | May store full text | May store page text in analyses | Analysis label |
|---|---|---|---|---|
| `public_domain` (with jurisdiction) | yes | cache only (gitignored) | yes | full |
| `open_license` (CC BY etc.) | yes, per license | cache only | yes, with attribution kept | full |
| `licensed` (we hold a licence) | per licence | per licence | per licence | full |
| `publisher_preview` | the preview only | no | no — metrics + paraphrase only | **partial** |
| `metadata_only` / `commentary` | metadata / short pages | no | no | **partial** |

Hard rules, each with a test:

- Adapters exist only for vetted sources. There is no "fetch any URL" path; the analyst can
  register a URL as a *commentary/metadata* source, which records it but never stores its body.
- `robots.txt` and source terms are checked per adapter; rate-limited; a descriptive User-Agent.
- No paywall, login, DRM or access-control circumvention. No shadow libraries, no "free PDF"
  mirrors. An edition whose provenance cannot be shown is rejected with a reason.
- The store validator rejects any `text` field on a work whose rights are not
  `public_domain`/`open_license`/`licensed`.
- Reviews are stored as paraphrase + URL. Quotations are not stored.
- **Near-copy guard (new, Phase 7):** `book-agent overlap` compares MagicPaper's own corpus
  (`templates/v3`, DailyFeed) with every stored text by word 6-grams and fails on matches.
  This turns "never generate near-copies" from a promise into a check.
- Nothing in the research data is a child's data. The tool has no access to app storage.

Public domain is jurisdictional (US: published before 1930; Turkey and EU: 70 years after the
author's death). Every `public_domain` record names its jurisdiction and basis.

---

## 5. Source strategy — and the corpus reality

The corpus will have **two populations with different evidence**, and the reports must keep
them apart:

1. **Fully readable** — public-domain classics (e.g. Beatrix Potter, Kipling's *Just So
   Stories*, Lear, translations of Andersen/Grimm) and openly licensed contemporary picture
   books (StoryWeaver, African Storybook, Book Dash, Global Digital Library — licenses and
   terms to be verified per source before an adapter is written). Deep page-level analysis.
2. **Acclaimed but copyrighted** — modern award winners and read-aloud favourites
   (Caldecott, Kate Greenaway, Astrid Lindgren Memorial Award, Hans Christian Andersen Award,
   Turkish awards and reading lists). Metadata, reviews, publisher previews, library records:
   partial analysis only.

Consequence the team should accept up front: **the best-evidenced popular books are the ones
we cannot read in full, and the books we can read in full are either old or less celebrated.**
Page-level claims will rest mostly on population 1; popularity and adult-interpretation claims
on population 2. A claim that combines both must say so.

Two more limits worth knowing now:
- **Page turns need real page boundaries.** Gutenberg plain text usually has none. Page-turn
  analysis is only done where `page_boundary_source` is `original_scan` or `publisher_layout`
  (Internet Archive scans, page-structured CC platforms). Reconstructed pagination is allowed
  for language metrics, never for page-turn claims.
- **Turkish full texts are scarce.** Turkish public domain needs the author to have died
  before 1956, and Turkish picture-book culture largely postdates that. The Turkish corpus will
  start metadata-heavy (publisher lists, MEB/library reading lists, Turkish awards) and the gap
  report will say so rather than filling it with English findings.

Discovery is query-template driven (the brief's §29 list plus generated gap queries), run by
the analyst with web search; every query, hit and rejection is recorded in the run file.
Bestseller lists are one signal among many, not the seed.

---

## 6. Analysis pipeline

```
DISCOVER → FILTER (age band, language, structure gaps) → VERIFY SOURCE (tier, rights)
→ ACQUIRE (adapter) → SEGMENT (pages, boundary source) → DEDUP (work/edition)
→ METRICS (CLI) → READ + ANALYZE (analyst, per schema) → VALIDATE (CLI, rejects bad records)
→ STORE → COMPARE (CLI aggregates) → CLAIMS (analyst proposes, CLI scores, counterexamples attached)
→ GAPS → REPORT → INSIGHTS for review
```

**Deterministic metrics** (`metrics/`): word and sentence counts using the same rules as
`TextMetrics` (sentence terminators, closers, ellipsis), longest sentence, words per page,
type/token ratio, repeated n-grams and repeated sentence openers, dialogue share (quote-marked
spans), questions, direct address (second-person markers, per language), sound words (per
language list), end-rhyme detection for verse. Turkish needs its own tokenization rules
(apostrophe suffixes: `Ragi'nin` is one word) — the tests take cases from the existing
resolver's suffix behaviour.

**Confidence** (`aggregate/confidence.py`), deterministic and documented in
`RESEARCH_METHOD.md`. Proposed defaults (D5):

| Sample scope | Works in scope |
|---|---|
| ONE_BOOK | 1 |
| SMALL_SAMPLE | 2-9 |
| CORPUS | 10-49 |
| LARGE_CORPUS | 50+ |

- HYPOTHESIS: ONE_BOOK, or only `INFERRED` support, or only tier C/D sources.
- LOW: SMALL_SAMPLE, or support ratio < 0.6.
- MEDIUM: ≥ CORPUS, support ≥ 0.6, at least one tier A/B source.
- HIGH: ≥ CORPUS, support ≥ 0.75, ≥ 2 of the 3 evidence layers agree, counterexamples examined.
- Any claim with counterexamples is worded "common, not universal" by the report writer.

Statements that read as children's preferences ("children love…") are rejected by the claim
validator unless their layer includes evidence about children themselves; otherwise they must
be phrased as corpus observations.

---

## 7. Knowledge-base strategy

- **Memory is the data directory**, not chat. Every run starts with `book-agent status` and
  `book-agent gaps`, and the agent definition requires reading them first.
- Runs are additive and idempotent: re-ingesting a known edition updates it; re-analysis bumps
  `analysis_version` and keeps the old one until the new one validates.
- Rejected hypotheses stay in `claims/` with `status: rejected` and the reason, so they are not
  rediscovered as new.
- Findings are stored per `(language, age_band)`. A finding becomes "language-independent"
  only when it holds separately in ≥ 2 languages, each at ≥ CORPUS scope.
- Markdown docs are partly generated (tables, counts) between marker comments and partly
  hand-written (interpretation), the same way `PROSE_PRODUCTION_GUIDE.md` mixes measured
  tables with prose.
- Embeddings / clustering: not in the first implementation. Revisit when the corpus passes
  ~150 works and similarity search becomes a real need.

---

## 8. MagicPaper translation layer

`MAGICPAPER_STORY_INSIGHTS.md` follows the AGE_BANDING rule: **every recommendation names the
engine field or the content gate it would affect, or it is not a recommendation.**

| Research finding type | Where it could land (after review) |
|---|---|
| Words per page, sentence length by age | `AgeBand.pageBudget`, `AgeBand.maxSentenceWords`, validator `BANDS` / `MAX_SENTENCE_WORDS` |
| Beat order and position by mode | blueprint beat sequences (`beat_sequences.json`, `BLUEPRINT_CATALOG_V2.md`) |
| Structure vs. cognitive age | `NarrativeFamily.minimumAge` |
| Emotional curves, safe peak intensity | `EmotionalState.intensity`, `permittedLandings` |
| Page-turn mechanisms | writing guidance for the content line (page-end lines), not code |
| Companion functions | `meet_companion` / `companion_offers` variant guidance, Masal ailem moments |
| Repetition and callbacks | the repetition metrics in `PROSE_PRODUCTION_GUIDE.md` |
| Anti-patterns | new validator gates, proposed — never added by the agent |

Each insight entry has: statement, evidence summary (n, scope, confidence, counterexamples),
the target field/gate, current value, suggested range, and a **status**:
`proposed → reviewed → accepted as product rule → implemented (link to commit)` or `declined`.
The agent can only write `proposed`. The workflow RESEARCH → ANALYSIS → INSIGHT → HUMAN REVIEW
→ PRODUCT RULE → IMPLEMENTATION is enforced by who may set which status, and implementation is
always a separate task by the owning agent (story-engine / content-library).

---

## 9. CLI design

`python3 Research/BookIntelligence/book_agent.py <command>` (alias `book-agent` via a tiny
shell wrapper if wanted).

| Command | Does | Network |
|---|---|---|
| `status` | corpus counts by age/lang/rights/read_status, last run, open gaps | no |
| `gaps` | coverage gaps → suggested research tasks and queries | no |
| `discover --adapter X --query …` | catalog search through a vetted adapter; records candidates | yes |
| `ingest <source-url-or-file> [--rights …]` | acquire, segment, dedup, store edition + source | adapter only |
| `metrics [work_id]` | (re)compute deterministic metrics | no |
| `validate` | schema + rights + reference checks on all data; non-zero exit on failure | no |
| `analyze <work_id>` | prints the analysis template + metrics for the analyst; validates what comes back | no |
| `compare [--age 5-6 --lang en]` | cross-book distributions and pattern tables | no |
| `insights` | recompute claim confidence, attach counterexamples, refresh insight doc | no |
| `deep-dive <work_id>` | Book-of-the-week report | no |
| `report [--run r_…]` | run report in `docs/research/reports/` | no |
| `overlap` | near-copy guard against MagicPaper's own corpus | no |
| `run start/finish` | open/close a research run record | no |

Only `discover` and `ingest` touch the network, and only through adapters.

---

## 10. Testing strategy

`python3 -m unittest discover Research/BookIntelligence/tests` — stdlib `unittest`, no network
(adapters are tested against recorded fixture responses; a test fails if a socket is opened).

| Area | Tests |
|---|---|
| Source parsing | each adapter parses its recorded fixture (metadata, rights, page structure) |
| Rights | text on a `metadata_only` work is rejected; preview analyses are labelled partial |
| Dedup | edition vs. work, translation, audiobook, duplicate URL, ambiguous → review list |
| Segmentation | page boundaries from scan fixtures; reconstructed pagination is flagged |
| Metrics | word/sentence parity with `TextMetrics` cases; Turkish apostrophe suffixes; dialogue, questions |
| Age band | basis precedence (publisher > library > derived) and mapping to 3-4/5-6/7-8/9-10 |
| Beats | vocabulary validation; engine mapping stays in sync with `StoryBeat.swift` raw values |
| Confidence | each threshold boundary; tier-D-only → HYPOTHESIS; editions don't add support |
| Aggregation / contradictions | counterexamples attached; "universal" wording refused when any exist |
| Persistence | run twice → no duplicate records; analysis_version bump keeps the old version |
| Boundary | the package writes nothing outside `Research/BookIntelligence/` and `docs/research/` |

Fixture corpus: 4-5 tiny invented "books" written for the tests (not real books), shaped to
exercise repetition, cumulative structure, a reveal page turn, a duplicate edition, and a
Turkish text — so the test data has no rights question at all.

---

## 11. Integration boundary with MagicPaper

- **Reads:** engine Swift sources for vocabulary sync only (test-time), `templates/v3` and
  DailyFeed for the overlap check. Read-only.
- **Writes:** `Research/BookIntelligence/**`, `docs/research/**`. Nothing else.
- **Not in Xcode, not in `StoryEngine/Package.swift`, not shipped.** No new dependency
  anywhere. `cache/` is gitignored.
- **Ownership:** a new `book-research` agent owns these paths; it holds no shared files.
  Product rules leave the system as tasks for story-engine / content-library.

---

## 12. Phased plan and the smallest useful MVP

| Phase | Content | Output |
|---|---|---|
| 0 | Inspection | §0 of this document ✅ |
| 1 | Technical design | this document, after approval → `BOOK_RESEARCH_AGENT.md`, `RESEARCH_METHOD.md` |
| 2 | Discovery | adapters: Gutenberg catalog + RDF ✅, Open Library (metadata) ⏳; query templates ✅; run records |
| 3 | Ingestion | rights model, segmentation, dedup, Internet Archive + one CC platform adapter |
| 4 | Deep analysis | analysis + page schemas, `analyze` loop, validator, deep-dive report |
| 5 | Structured corpus | first deliberate corpus, 5-6 first |
| 6 | Cross-book patterns | `compare`, distributions, contradictions |
| 7 | Insight layer | claims, confidence, MagicPaper insights, overlap guard |
| 8 | Reporting + CLI | run reports, status, gaps |
| 9 | Tests + fixtures | built alongside each phase, not at the end |

### MVP: "one honest loop, five books"

Smallest thing that is useful by itself and exercises every boundary:

1. Schemas (work, edition, source, page analysis, claim, run) + `validate`, with the rights rule.
2. `ingest` from **two** sources only: Project Gutenberg (PD text) and `manual` (a file + provenance,
   for a page-structured scan or a CC-licensed book a person downloaded by hand). No crawler.
3. `metrics` (TextMetrics-parity, Turkish-aware) and `dedup`.
4. `analyze` + `deep-dive` for the analyst loop.
5. `compare`, `status`, `gaps`, `report` — enough to produce one run report.
6. Unit tests on the fixture corpus.
7. Pilot content: **5 age 5-6 books with real page boundaries** (mix of PD classics with scans
   and CC-licensed contemporary picture books), each with a deep dive, and one run report whose
   findings are all labelled SMALL_SAMPLE / LOW or HYPOTHESIS — because that is what 5 books
   honestly support.

What the MVP gives the team on day one: a page-by-page analysis method they can read and
critique on five concrete books, before scaling. If the method is wrong, it is cheap to fix at
five books and expensive at two hundred.

Not in the MVP: Internet Archive / StoryWeaver adapters (Phase 3), claim confidence history
(Phase 7), overlap guard (Phase 7), visual analysis beyond analyst notes, any Turkish full-text
corpus, embeddings.

---

## 13. Decisions that need human approval

| # | Decision | Recommendation |
|---|---|---|
| D1 | Language/runtime of the tool | **Python 3 stdlib**, matching `validate_beat_corpus.py`. Alternative: a Swift package depending on `StoryEngine` (like ContentPublisher) — stronger vocabulary sharing, weaker for web/text tooling. |
| D2 | Who does the judgment work | **Claude Code agent in a reviewed session**, CLI validates. No LLM API in the CLI for now. |
| D3 | Location | `MagicPaper/Research/BookIntelligence/` + `MagicPaper/docs/research/`, committed; `cache/` gitignored. |
| D4 | Store source texts in git? | **No.** PD/CC page text appears inside page analyses only; raw files live in the gitignored cache, reproducible by URL + checksum. |
| D5 | Confidence thresholds (§6) | Accept as starting defaults; revisit after the first 20 works. |
| D6 | Research beat vocabulary separate from `StoryBeat`, joined by a mapping | Yes — keeps the research from seeing only what the engine already models. |
| D7 | Which CC platforms are acceptable sources | Verify StoryWeaver / African Storybook / Book Dash / GDL terms (incl. automated access) before writing adapters. Needs a human sign-off per source. |
| D8 | Turkish corpus plan | Start metadata-heavy; ask whether a Turkish publisher could license a small set of picture-book texts for analysis-only use. |
| D9 | Who reviews insights | Proposed: Batuhan for content-line guidance; story-engine owner for anything touching `AgeBand` / validator gates. |
| D10 | A new `book-research` agent in `.claude/agents/` | Yes, scoped to the two research paths. |

---

## 14. Assumptions made

- The repo root is `MagicPaper/` (where `.git` is); the outer `MagicPaperAPP/` folder is not versioned.
- Primary research target is 5-6, English and Turkish first, other languages via openly
  licensed multilingual collections.
- The research tool is internal and never ships to devices, so its cost and dependencies are
  judged as tooling, not as app features.
