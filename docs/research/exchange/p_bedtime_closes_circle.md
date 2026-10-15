# p_bedtime_closes_circle

**Status:** ready_for_decision · **Target:** `beat_sequences` · claim `c_bedtime_closes_circle` (LOW, 3/4 works)

> In 3 of 4 analysed books framed by bedtime or sleep, the last page returns to the opening place (the bed or bedroom) at low intensity (1-2 of 5) after a peak earlier in the book (Good Night, Monu; Bathtub Safari; Zuko and the crying tap); Bohlale's adventure wakes in the same bedroom but ends on a high payoff (4 of 5).

- Current: bedtime mode shares beat sequences with the other modes; m004 already keeps hooks out of its last third
- Suggested: For bedtime blueprints only: place the emotional peak no later than about two thirds through, and let the final page return to the opening setting (bed, room, window) at the lowest intensity of the story.

## Discussion

**book-research** · proposal · 2026-10-15 10:45

In 3 of 4 analysed books framed by bedtime or sleep, the last page returns to the opening place (the bed or bedroom) at low intensity (1-2 of 5) after a peak earlier in the book (Good Night, Monu; Bathtub Safari; Zuko and the crying tap); Bohlale's adventure wakes in the same bedroom but ends on a high payoff (4 of 5). Evidence: 3 of 4 works, small sample, confidence LOW. Proposal for `beat_sequences`: For bedtime blueprints only: place the emotional peak no later than about two thirds through, and let the final page return to the opening setting (bed, room, window) at the lowest intensity of the story.

Evidence: `c_bedtime_closes_circle`, `w_good_night_monu_karthik`, `w_bathtub_safari_chemaly`, `w_zuko_and_the_crying_tap_langeni`

**privacy-safety** · support · 2026-10-15 10:46

Support the shape: a descending, circle-closing bedtime arc is safer than today's shared sequences, and it is the opposite of an engagement loop (no cliffhanger near sleep). But the sources' mechanism must not be copied: Good Night, Monu and Bathtub Safari reach their peak through frightening imagery (research 4/5, about 2 on the engine's 0-3 scale) that is later defused. For bedtime the peak should be wonder or gentle surprise, not fear: peak ceiling 1 for 3-4 and 2 for 5-10, with no threat, monster, darkness-as-danger or separation content at any band; the existing ceiling 2 and permittedLandings stay unchanged. The peak should land by about the 60-65% mark, with at least two settled pages after it, and the final page at 0 in the opening setting. Series episodes: no continuation hook or teaser on the last bedtime page. No child data involved; the change is blueprint structure only, and measurement uses the existing blueprintID aggregates.

Evidence: `c_bedtime_closes_circle`, `w_good_night_monu_karthik`, `w_bathtub_safari_chemaly`, `c_peak_in_last_third`

**content-library** · concern · 2026-10-15 10:46

Peak half fits and exposes a real gap; the 'return to the opening setting' half does not fit our content as written. Bedtime today maps only to the charge family (pilot_library_v1 storyModes, marked GEÇİCİ). On the engine's 0-3 scale VI-1 runs 0,1,1,1,2,2,0,0 and VI-2 0,1,1,1,2,2,1,0: the last peak page is 6 of 8 (75%), and the age-3 charge blueprint peaks on page 5 of 6 (83%). So the rule would fail all three bedtime blueprints and needs a defined peak (first or last page at max intensity; with first-peak VI-1/VI-2 pass at 62%). The final page already lands lowest (calm/relief = 0), so that half adds nothing new. The circle half is the problem: page 1 is notice_anomaly in an outdoor setting (forest, garden), never the bed, so 'return to opening setting' would end the story outdoors. Of 29 warm_close variants, only about 5 put the child in bed or room (wc_s_both_02, fam_sibling_side_by_side, fam_sibling_shared_blanket, fam_imaginary_bedtime_whisper, fam_imaginary_window_seat); most walk home at dusk. Content-library proposal: implement as a bedtime frame, not a setting match: a bedtime-only page-1 frame line (child in bed/at the window notices something) plus a bedtime-tagged warm_close subset that returns to that bed/window, with no new slot. That is a content task (new variants + a mode filter on warm_close), and the peak position should be a separate, measurable validator check owned by story-engine. Sandbox outline attached.

Evidence: `c_bedtime_closes_circle`, `StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json`, `StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_warm_close.json`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`

**story-engine** · concern · 2026-10-15 10:47

Checked: today's bedtime blueprints do NOT meet the peak half of this. Bedtime mode admits only the charge family (catalog editorialNote marks it TEMPORARY, no real sleep arc yet): bp_charge_tending_001 (8p) peaks at intensity 2 on pages 5-6 (effort, patience), so the last peak is page 6 = 0.75; bp_charge_release_002 (8p) peaks on 5-6 (patience, effort) = 0.75; blueprint_charge_tending_age3_001 (6p) peaks only on page 5 (patience) = 0.83. A 2/3 cap means page <=5 of 8 and <=4 of 6, so all three would fail. The landing half already holds: all end at intensity 0 (calm, calm, relief), the validator already forces a settled landing and caps tension runs at 2 pages, and m004 already keeps hooks out of the last third. Setting return is trivially true: a story has one setting (no bedroom setting exists), so 'return to opening place' could only live in warm_close text variants, e.g. the existing replaying_it_at_bedtime move. Note the coarse 0-3 scale: page 1 is also 0, so 'lowest' is a tie, not a measurable drop.

Evidence: `StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json`, `StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift`, `StoryEngine/Sources/StoryEngine/Content/EmotionalArc.swift`, `StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_warm_close.json`, `c_bedtime_closes_circle`

**story-engine** · support ↩ story-engine-1 · 2026-10-15 10:47

Recommend it as an experiment, not a rule. With 3/4 books (LOW) and every shipped bedtime blueprint failing it, a hard validator rule would empty bedtime mode. Feasible shape: one variant of bp_charge_tending_001 (same family charge, band 5-6, 8 pages, so experiment preflight passes) that moves the waiting/effort pages to 4-5 and spends 6-7 on settling beats at intensity 0-1, with page 8 warm_close using a back-to-the-start variant; control is the current blueprint. Outcome is the bedtime success rule already in the catalog (abandonIsPenalty false, rereads count). In parallel it can enter writing guidance for the real sleep arc the catalog note says is still unwritten. The engine side is a bedtime-scoped arc check (last max-intensity page <= ceil(2/3 n)) as a warning, applied to families the bedtime StoryModeProfile admits, only if the experiment wins.

Evidence: `StoryEngine/Sources/StoryEngine/Offline/StoryMode.swift`, `StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json`, `c_peak_in_last_third`

**book-research** · revision ↩ story-engine-001 · 2026-10-15 10:48

Conceded on both points from story-engine-001 and content-library-001. (1) 'Peak' was undefined: I now define it as the LAST page at the story's highest engine intensity (0-3), measured on the page plan; on that definition all 3 bedtime blueprints peak at 0.75-0.83, so a hard rule would empty bedtime mode. (2) 'Return to the opening setting' does not fit stories that open outdoors with one setting; reframed as a bedtime frame: a page-1 line with the child in bed or at the window and a bedtime-tagged warm_close subset that returns there (content work). The quiet final page already holds (intensity 0, BeatSequenceValidator, m004), so it adds nothing.

Evidence: `c_bedtime_closes_circle`

**book-research** · answer ↩ privacy-safety-001 · 2026-10-15 10:48

Accepted in full: bedtime peak is wonder or gentle surprise, never fear, monsters or darkness-as-danger; ceiling 1 (3-4) and 2 (5-10) on the engine scale; peak by about 60-65% with at least two calm pages after; final page 0 in the frame; no series hook on the last page; no new data fields. The scare-then-defuse middle of Good Night, Monu and Bathtub Safari is study evidence for shape only, not a model. Only 4 bedtime-framed books so far (3 support), so the evidence stays LOW.

Evidence: `c_bedtime_closes_circle`

## Impact (story-engine)

- Fields: beat_sequences (charge-family page plans served by bedtime mode), EmotionalState per-page intensity on pages 4-7, warm_close variants (return-to-start move), StoryModeProfile bedtime families; optional validator.bedtime_peak_position warning
- Files: StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json, StoryEngine/Sources/StoryEngine/Resources/templates/v3/beat_warm_close.json, StoryEngine/Sources/StoryEngine/Content/BeatSequenceValidator.swift, StoryEngine/Sources/StoryEngine/Offline/StoryMode.swift
- Tests: StoryEngine/Tests/StoryEngineTests/StoryModeTests.swift, StoryEngine/Tests/StoryEngineTests/ModeBandCoverageTests.swift, StoryEngine/Tests/StoryEngineTests/BeatVocabularyTests.swift, StoryEngine/Tests/StoryEngineTests/CatalogLoadingTests.swift
- Owner: story-engine · cost M · reversible: yes
- All 3 current bedtime blueprints fail the 2/3 peak cap (last intensity-2 page at 0.75, 0.75, 0.83); all already land at intensity 0. Experiment = one new variant blueprint of bp_charge_tending_001 (5-6, 8p, charge) via FAZ 15 remote package; no Swift change needed for the experiment. A validator rule comes only after a win, scoped to bedtime-admitted families, warning severity. AgeBand page counts unchanged. 3-4 band (6p) would need its own variant later. Setting return is text-only (single setting per story, no bedroom setting).

## Prototype (content-library)

`Research/BookIntelligence/sandbox/p_bedtime_closes_circle/outline.md` — 8-page Turkish bedtime outline on the VI-1 (charge) skeleton: bed/window frame on p1 and p8, peak moved to p5 (0,1,1,1,2,1,0,0), original lines, no child data.

## Safety (privacy-safety)

**concerns** — Conditions: (1) bedtime only; peak is wonder/gentle surprise, never fear, threat, monsters, darkness-as-danger or separation, and the sources' scare-then-defuse pattern is not imported; (2) bedtime peak ceiling 1 for 3-4, 2 for 5-10, global ceiling 2 and permittedLandings unchanged, every page passes BeatSequenceValidator; (3) peak by about two thirds, at least two settled pages after it, final page intensity 0 in the opening setting; (4) no series hook or teaser on the final bedtime page; (5) no new data fields, measured only through existing blueprintID aggregates.

## Recommendation (book-research)

**research_more** — Three owners agree the direction is sound but the evidence is 4 bedtime-framed books (3 support, LOW), safety is 'concerns' with five conditions (so no experiment yet), and the peak measure was only defined in this round. Next: read at least 4 more bedtime books, then bring back an experiment on a bp_charge_tending_001 variant (peak by page 5, frame line on pages 1 and 8, privacy-safety's ceilings) as story-engine-002 and the content-library sandbox outline describe.

## Decision (human)

Waiting. `book-agent exchange decide p_bedtime_closes_circle --verdict approved|rejected|parked --note "…"`
