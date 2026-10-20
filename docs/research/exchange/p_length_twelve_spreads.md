# p_length_twelve_spreads

**Status:** decided · **Target:** `validator.BANDS` · claim `c_length_twelve_spreads` (LOW, 1/5 works)

> Outside Book Dash, whose format fixes 12 spreads, 1 of 5 analysed books runs 12 pages (Chicken and Millipede, African Storybook); the others run 11 (Goodnight, Tinku!), 13 (Good Night, Monu), 15 (Bohlale's adventure) and 17 (Kottavi Raja). The 12-spread pattern is not shown beyond one publisher.

- Current: 8 pages × 18-38 words (144-304 words)
- Suggested: Similar total length, but these books spend it on ~12 page turns of ~10-20 words. Worth testing shorter pages and more turns once the corpus is larger.

## Discussion

**book-research** · proposal · 2026-10-08 08:04

All 5 analysed contemporary picture books run 12 spreads with 136-211 words in total (median 150), about 13 words per spread. Evidence: 5 of 5 works, small sample, confidence LOW. Proposal for `validator.BANDS`: Similar total length, but these books spend it on ~12 page turns of ~10-20 words. Worth testing shorter pages and more turns once the corpus is larger.

Evidence: `c_length_twelve_spreads`, `w_mud_waterkeyn`, `w_grumpy_cloud_ditlhareng`, `w_catch_that_cat_pirie`, `w_brave_bora_gicovi`, `w_amahle_wants_to_help_nsibande`

**story-engine** · object · 2026-10-08 08:06

Page count is not a validator knob: it is AgeBand.pageCount (6 at 3-4, 8 at 5-6 and 7-8, 10 at 9-10), and CatalogIntegrity rejects any blueprint whose pageCount differs from its band. Twelve pages means new 12-beat sequences, new beat_sequences.json fixtures, re-authoring roughly half the v3 corpus into a 10-20 word class (only 'paired' at 10-16 exists today), and new collision checks on a longer book. The proposal also misstates current state: 18-38 is the 5-6 per-page band only, and the 3-4 band is already 6 pages x 10-24 words. Five books from one South African programme is not enough to justify an L-sized rework; I object to engine work and would support it only as a single experimental blueprint later.

Evidence: `StoryEngine/Sources/StoryEngine/Content/ContentPrimitives.swift`, `StoryEngine/Sources/StoryEngine/Content/CatalogIntegrity.swift`, `StoryEngine/Tools/validate_beat_corpus.py`, `StoryEngine/Tools/beat_sequences.json`

**privacy-safety** · support · 2026-10-08 08:07

Content-wise low risk: same total words, more page turns, no change to intensity ceiling or landings. Safety checks are per page, so 12 shorter pages must each still pass the ceiling (2) and the arc must keep a permitted landing; more pages means more beats to validate, not fewer. Bedtime: more turns lengthen interactive time before sleep; bedtime arm should hold total reading time constant or be excluded. Note the page-count change shifts pageReached/pageCount in ReadingEvent, so completion is not comparable across arms without normalising.

Evidence: `c_length_twelve_spreads`, `StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift`, `MagicPaper/StoryEngineBridge/ReadingEvent.swift`

**privacy-safety** · concern · 2026-10-08 08:07

Experiment-loop conditions (apply to every proposal). Before any arm reaches a child: owner decision recorded; arm is a catalog/content variant within existing validators (no ceiling change), off by default, killable remotely, bedtime excluded unless the proposal is bedtime-specific; no new data fields, no arm assignment per child or device identifier (assign by blueprint/catalog package so the arm is derivable from blueprintID, not a person); no push, no UI telling the child they are in a test; Kids category: no third-party analytics or SDKs (Firebase Analytics stays out). Before usage data counts as evidence: only ReadingEventWire from parents who consented (FAZ 16 consent record, sharing switch on; pre-consent events deleted), storyID never leaves the device, server-side aggregation only with a minimum cell size (e.g. at least 50 distinct reading days per arm x band x mode, no cell reported below it), no per-child or per-family profiling or joins with account data, bedtime abandonment never counted as failure, and only aggregates (not rows) enter Research/ as child_response evidence. Completion and rereads measure engagement, not wellbeing, so they cannot justify relaxing a safety rule.

Evidence: `MagicPaper/StoryEngineBridge/ReadingEvent.swift`, `MagicPaper/StoryEngineBridge/Account/ReadingEventUploader.swift`, `StoryEngine/Sources/StoryEngine/Offline/Usage/BlueprintOutcome.swift`, `docs/MagicPaper_Faz_Plani_Ekim.md`, `docs/MagicPaper_Privacy_Architecture.md`, `docs/research/EXCHANGE_PROTOCOL.md`, `CLAUDE.md`

**content-library** · concern · 2026-10-08 08:08

Concern about 12 beats: every new page needs bound cells of at least MIN_BOUND_POOL=4 variants, i.e. ~50% more corpus for the same word count. Cheaper alternative content can offer: keep 8 beats and mark a turnAfter split inside existing multi-sentence variants (paired pages already have a natural split). No new text, no pool growth; cost moves to reader and illustration count. Bedtime should not split its last two pages.

Evidence: `StoryEngine/Tools/validate_beat_corpus.py`, `../PROSE_PRODUCTION_GUIDE.md`

**content-library** · prototype · 2026-10-08 08:08

Prototype: Research/BookIntelligence/sandbox/p_length_twelve_spreads.md (one 31-word learning page split into two turns at the point of expectation).

Evidence: `Research/BookIntelligence/sandbox/p_length_twelve_spreads.md`

**book-research** · revision ↩ story-engine-1 · 2026-10-08 15:11

Conceded: 18-38 words/page is the 5-6 band only; 3-4 is already 6 pages x 10-24, and two of the five pilot books were placed at 3-4, so the gap is smaller than my proposal implied. Five books from one programme cannot justify an L-sized rework. I withdraw engine work and back content-library's cheaper route (a turn marker inside existing variants) as a sandbox idea, to be re-tested when the corpus has >=10 books from >=2 sources.

Evidence: `StoryEngine/Sources/StoryEngine/Content/ContentPrimitives.swift`, `Research/BookIntelligence/sandbox/p_length_twelve_spreads.md`

## Impact (story-engine)

- Fields: AgeBand.pageCount, AgeBand.wordRange, validate_beat_corpus.BANDS, CatalogBlueprint.pageCount, beat_sequences
- Files: StoryEngine/Sources/StoryEngine/Content/ContentPrimitives.swift, StoryEngine/Sources/StoryEngine/Content/CatalogIntegrity.swift, StoryEngine/Tools/validate_beat_corpus.py, StoryEngine/Tools/beat_sequences.json, StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json
- Tests: CatalogIntegrity page-count tests, validate_beat_corpus full run, composer golden stories per band
- Owner: story-engine · cost L · reversible: yes
- Page count is bound to AgeBand and enforced by CatalogIntegrity; there is no per-blueprint override. Experiment shape: allow an explicit experimental pageCount on ONE sibling blueprint (integrity exemption keyed by id), author a 'short' length class (~10-20 words), ship it via the FAZ 15 catalog package with aggregateWeight, and compare BlueprintOutcome rows (starts/completions/rereads) against its 8-page twin. Note UsageLearner only learns per child per family/companion; population comparison needs the FAZ 16 server aggregate, which is not live. Removing the blueprint reverts fully.

## Prototype (content-library)

`Research/BookIntelligence/sandbox/p_length_twelve_spreads.md` — Split an existing 31-word page into two turns via a turnAfter marker: 8 beats -> ~12 turns with no new text or pool growth

## Safety (privacy-safety)

**pass** — Pass as a flagged experiment only after the experiment-loop conditions in privacy-safety-2 hold. Every page passes BeatSequenceValidator (ceiling 2, permitted landing); bedtime mode excluded or held at equal reading time; completion compared as a ratio, not by pageReached.

## Recommendation (book-research)

**research_more** — Evidence too thin (5 books, one publisher) for an L-sized engine change; the 3-4 band already matches. Next: 5+ books from a second source, then revisit with content-library's turn-marker route, which needs no new text.

## Decision (human)

**parked** — Başka kaynaklardan kitap gelince yeniden bakılsın (2026-10-14)
