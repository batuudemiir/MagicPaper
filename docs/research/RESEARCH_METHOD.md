# Research method

2026-10-08. How the Children's Book Intelligence Agent turns books into evidence, and
evidence into reviewed guidance. Every rule here that can be checked is checked by
`book-agent validate` or by the confidence calculation; the file and test that enforce
it are named.

The governing idea, inherited from [AGE_BANDING.md](../AGE_BANDING.md): **a finding that
does not name the engine field or content gate it would change is not a recommendation.**
And from [PROSE_PRODUCTION_GUIDE.md](../../../PROSE_PRODUCTION_GUIDE.md) §1: what transfers
from existing books is *moves*, never sentences.

---

## 1. Workflow

```
RESEARCH → ANALYSIS → INSIGHT → HUMAN REVIEW → PRODUCT RULE → IMPLEMENTATION
```

The agent can reach INSIGHT and mark it `proposed`. Review, acceptance and implementation
are human steps; implementation is a separate task for the owning agent (story-engine,
content-library). The research subsystem has no write path into `StoryEngine/`, `Content/`
or the app (`tests/test_engine_mapping_and_boundary.py::Boundary`).

---

## 2. Rights and acquisition

| Rights | Fetch | Page text kept in `data/pages` | Analysis can be |
|---|---|---|---|
| `public_domain` (+ jurisdiction, basis) | yes | yes | full |
| `open_license` (+ license, attribution) | per license | yes | full |
| `licensed` (+ licence reference) | per licence | yes | full |
| `publisher_preview` | the preview only | **no** | partial |
| `metadata_only`, `commentary` | metadata / page record | **no** | partial |

- No pirated copies, no paywall/login/DRM circumvention, no shadow libraries.
- Adapters declare their hosts; any other host is refused before a socket opens. robots.txt
  is honoured; if it cannot be read, the fetch is refused, not assumed allowed (`adapters/base.py`).
- Which sources, and why: [SOURCES.md](SOURCES.md). Gutendex is not used (robots.txt); African
  Storybook and StoryWeaver have no automated route (their readers serve content only through app
  mechanics / their terms limit site use to personal use) and are added by hand.
- Internet Archive: only editions published ≤ current year − 96 and outside lending collections.
- Redirects to hosts outside an adapter's allow-list are refused.
- Every edition records `text_origin`: `publisher_text`, `plain_text_edition`, `ocr` or
  `analyst_transcription`. OCR and transcription can contain errors; language metrics on them
  are as good as the text.
- Gutenberg's "Public domain in the USA." is recorded with jurisdiction US. Elsewhere
  (life + 70 years) the status can differ.
- Sources never store bodies or quotations; reviews are paraphrased with their URL
  (`schema.validate_source`). Deep dives and reports never reproduce book text.
- Raw files live in `cache/` (gitignored), reproducible from source URL + sha256.

## 3. Works, editions, deduplication

Evidence is counted per **work**. A reprint, translation, audiobook or second URL is an
edition and adds nothing (`confidence.Context.work_of`, `test_editions_do_not_add_support`).
Matching: shared identifier → same; same normalized title + creator surname → same;
same title with another creator, or a near title (≥ 0.88) with the same creator →
**ambiguous**, queued in `data/review/dedup.json`, never merged automatically.

## 4. Page boundaries

| `page_boundary_source` | Language metrics | Page-turn analysis |
|---|---|---|
| `original_scan`, `publisher_layout` | yes | yes |
| `reconstructed` (e.g. Gutenberg plain text) | yes | **no** — the validator rejects page-turn fields |

## 5. Judgments vs. computations

- **Computed by the CLI** (overwritten on every `analyze`/`metrics`): words, sentences,
  sentence lengths, dialogue share, questions, direct address, sound words, repetition,
  rhyme heuristic, emotional curve, beat positions, completeness, appeal label, claim confidence.
  Word and sentence rules are a port of `TextMetrics.swift` so numbers compare with the
  18-38 band (`tests/test_text_metrics.py`).
- **Judged by the analyst**, each page labelled `OBSERVED` (visible in text/image) or
  `INFERRED`: beat, emotion and intensity (0-5), what changes, the open question, page-turn
  mechanism and strength (1-5), humor type, repetition type, illustration function, characters,
  strengths, weaknesses, anti-patterns, content flags, age suitability.

Research vocabulary is closed (`bookintel/vocab/research_vocab.json`) and deliberately not
the engine's. `engine_mapping.json` joins them; a test fails if a mapped engine value
disappears from `StoryBeat.swift` / `EmotionalArc.swift`. Note: research intensity 0-5 is
per page; engine intensity 0-3 is a per-state safety ceiling. Compare shapes, not numbers.

## 6. Three evidence layers (+ one)

| Layer | Question | Typical source |
|---|---|---|
| `popularity` | What is demonstrably popular? | award listings, long-term in print, library visibility, download counts |
| `quality` / `adult_interpretation` | What do parents, teachers, librarians, reviewers say? | tier B/C sources |
| `textual_mechanism` | What does the book itself do? | our complete analyses |
| `child_response` | What do children themselves do? | research with children — rare |

Popularity is never quality. A claim that children like something must carry
`child_response` evidence; otherwise the validator rejects the wording and asks for a corpus
observation ("12 of 20 analysed books …") — English and Turkish (`schema._PREFERENCE`).

## 7. Source tiers

A: publisher, library, award body, authorized full text · B: professional review, educational
organization, reputable database · C: parent review, teacher discussion, community ·
D: anonymous aggregation (an aggregator is always D). A claim with no A/B source behind it
cannot rise above HYPOTHESIS.

## 8. Confidence

Calculated in `bookintel/confidence.py`; the analyst never sets it. Starting defaults —
revisit after ~20 complete analyses (decision D5):

| Sample scope (works examined) | |
|---|---|
| ONE_BOOK | 1 |
| SMALL_SAMPLE | 2-9 |
| CORPUS | 10-49 |
| LARGE_CORPUS | 50+ |

- **HYPOTHESIS**: claim kind is HYPOTHESIS, or one book, or no tier A/B source.
- **LOW**: small sample, or support ratio < 0.6.
- **MEDIUM**: corpus scope and ratio ≥ 0.6.
- **HIGH**: corpus scope, ratio ≥ 0.75, ≥ 2 evidence layers, kind OBSERVED, counterexamples reviewed.
- INFERRED claims stop at MEDIUM.

Each claim stores `supporting_works`, `counterexample_works`, `sources`, the computed
`n_examined / support / counter / sample_scope / best_source_tier`, and a confidence history.

## 9. Contradictions and wording

- A claim with any counterexample is reported as "common, not universal"; universal wording
  ("always", "every book", "her zaman", "zorunlu" …) is rejected when counterexamples exist.
- A work cannot both support and contradict a claim.
- Rejected claims stay with `status: rejected` and their reason, so they are not rediscovered.
- Findings are stored per `(language, age_band)`. A finding is called language-independent only
  when it holds separately in ≥ 2 languages, each at CORPUS scope.

## 10. Anti-pattern library

Closed list in the vocabulary; the analyst records `{id, pages, note}`.

| id | Meaning |
|---|---|
| `complicated_opening` | The first spread asks the reader to hold too much before anything happens |
| `unnecessary_exposition` | Explanation the pictures or events already carry |
| `weak_ending` | The ending does not answer the question the book opened |
| `repetitive_conflict` | The same obstacle recurs without escalation or change |
| `passive_protagonist` | Things happen to the protagonist; they do not act |
| `generic_dialogue` | Lines any character could say |
| `vocabulary_above_age` | Words the band cannot reach from context |
| `too_many_characters` | More named characters than the band can track |
| `unclear_stakes` | The reader cannot say what would be lost |
| `resolves_too_quickly` | Solution arrives before the problem has weight |
| `page_without_change` | A page ends where it began |
| `adult_rescues_child` | An adult resolves the child's problem for them |
| `moral_stated_not_shown` | The lesson is said rather than enacted |
| `boring_repetition` | Repetition that adds no rhythm, anticipation, humor or comfort |

Repetition is not assumed good: each repetition item is judged `effective: true/false` with a reason.

## 11. Child-appeal heuristic

Ten dimensions (curiosity, humor, participation, emotional identification, surprise,
character warmth, agency, visual novelty, predictability balance, resolution satisfaction),
1-5. Always labelled **"Research heuristic — not validated"**; the label is set by the CLI and
cannot be renamed (`test_appeal_label_cannot_be_renamed`). It is never a preference score.

## 12. Safety

Popular is not suitable. Each work and analysis carries `content_flags` (peril, death,
frightening imagery, imitable unsafe behaviour, stereotype, dated social norms …) and a
MagicPaper suitability (`suitable`, `adapt_with_care`, `study_only`, `unsuitable`).
`study_only` books inform structure findings but never serve as models for MagicPaper content.

## 13. Gap detection

`book-agent gaps` compares the corpus with `vocab/research_plan.json` (per-language and
per-band targets, story types, tones, structures, page-turn-eligible books, contemporary
share, female protagonists, illustration coverage, languages) and fills query templates for
each shortfall. Targets are a research plan, not a quality bar; raise them as the corpus grows.

## 14. Translation into MagicPaper

A claim may carry a `magicpaper` block: `target` (one of `AgeBand.pageBudget`,
`AgeBand.maxSentenceWords`, `NarrativeFamily.minimumAge`, `EmotionalState.intensity`,
`beat_sequences`, `validator.BANDS`, `writing_guidance`, `new_validator_gate`, …),
`current`, `suggested`, `note`, `review_status`. UX targets (`reader.page_turn`, `reader.layout`, `reader.read_aloud`, `ux.parent_flow`,
`ux.child_area`, `design.visual_language`, `illustration.brief`) carry findings about the reading experience
and design; their owners are listed in [EXCHANGE_PROTOCOL.md](EXCHANGE_PROTOCOL.md). `book-agent insights` renders them into
`MAGICPAPER_STORY_INSIGHTS.md`, grouped by review status.
