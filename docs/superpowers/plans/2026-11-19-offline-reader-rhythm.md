# Offline Reader Rhythm Implementation Plan

> **For agentic workers:** Execute the approved plan task by task within the lead agent's assigned scope. Repository AGENTS.md overrides intermediate test execution: write tests first, inspect during implementation, and run the agreed final verification once after all implementation steps.

**Goal:** Give newly composed offline stories meaningful role-based reading rhythm for ages 3–6 and 7–10 while preserving their exact authored text, page count, narration and canonical identity.

**Architecture:** Carry the existing active `ComposedPage` role and authored refrain through the bridge as optional app metadata. Resolve visual text blocks outside SwiftUI, retaining their original paragraph and UTF-16 coordinates; the view only renders those decisions. Keep existing artwork pins and their resolver unchanged.

**Tech Stack:** Swift, Foundation/NaturalLanguage, Codable, SwiftUI, existing XCTest app target.

## Why

Serves Story quality, Storybook reading, Parent simplicity and Low operating cost. This is a presentation pilot, not evidence that reading motivation has improved. User authorization to begin supersedes the research report's older pending approval checklist.

## Inspected implementation and layer decision

- `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`: active `ComposedPage` already carries `role`, `beats`, `emotion`, `refrain`, text and provenance. Its flush joins authored sentences with spaces. No engine change needed.
- `MagicPaper/StoryEngineBridge/OfflineStoryMapper.swift`: `appPage(from:)` currently drops role/refrain. This is the translation seam to change.
- `MagicPaper/Models/Story.swift`: actual persisted app `StoryPage` has optional art/words and synthesized Codable. Its equality checks only ID: tests must explicitly assert metadata/text fields.
- `MagicPaper/Screens/StoryReader/ReaderStory.swift`: actual `Story → ReaderPage` mapping lives in `ReaderStory.init(from:)`; **there is no `ReaderPageMapping` type/file at current HEAD**. `paragraphs` and `spokenText` are the narration contract.
- `MagicPaper/Screens/StoryReader/ReaderText.swift`: reuse Turkish sentence tokenization and current word/sentence narration tracking.
- `MagicPaper/Screens/StoryReader/StoryPageView.swift`: rendering only. Existing 3–6 sentences and 7–10 paragraphs are currently uniform across page roles.
- `MagicPaper/StoryEngineBridge/{StorySeries,SeriesManager}.swift`: episodes persist/copy `[StoryPage]`; no separate transport schema is necessary.
- `StoryEngine/Sources/StoryEngine/Domain/StoryPage.swift` is the separate illustrated pipeline. Its `layout`/`typographyPresetID` are not the active offline reader contract; leave it unchanged.

## Contract recommendation

Agreed public contract: optional `StoryPage.reading: StoryPageReading?`; `StoryPageReading` contains `schemaVersion: Int` (default 1), `role: String`, `refrain: String?`. Define it in synchronized `MagicPaper/StoryEngineBridge/StoryPageReading.swift`. Its tolerant decoder uses an empty role for malformed role fields, nil for malformed refrain, and preserves an unsupported integer version for resolver rejection; an explicitly malformed version becomes invalid rather than silently accepted as version 1. Missing version defaults to 1. Raw unknown roles remain decodable. Add `ReaderPage.reading: StoryPageReading? = nil`.

Create `ReaderReadingRhythm` as the pure resolver. Its agreed callable contract is `static func blocks(paragraphs: [String], reading: StoryPageReading?, layout: ReaderTextLayout) -> [ReaderRhythmBlock]?`. Nil means render the exact legacy path. `ReaderRhythmBlock` exposes `text: String`, `sourceParagraph: Int`, `sourceRange: Range<Int>` (UTF-16 coordinates in the original paragraph), and `kind: ReaderRhythmBlock.Kind` (`body`, `opening`, `quiet`, `refrain`). `kind` determines the optional preceding gap; quiet/refrain use `MP.S.x6` in the renderer only when measured content fits the viewport, never a persisted pixel value. Require version 1 and a known role. Add pure speech helpers to intersect a source-local `ReaderWords.ReadAlong` with a block and remap it to block-local coordinates. Keep original source paragraph identity in every age path.

Persisting refrain text rather than an offset avoids a second offset schema and stale saved ranges. It duplicates only an already authored short suffix. Only accept a nonempty exact authored suffix that maps to existing source sentence boundaries; otherwise ignore it. Never search arbitrary matching middle text and never add a refrain that is absent. Source slices/ranges are derived locally and validated before NSString operations; malformed or out-of-bounds input falls back to the original presentation. Reject negative/overflowing bounds, empty invalid slices and boundaries splitting composed characters. Unknown/missing role or unsupported schema version means baseline behavior, including no newly guessed semantics. A nonobject malformed metadata payload must also degrade to nil without failing the whole page decode; the page optional-field decoding must explicitly tolerate that case.

A fully transient alternative would derive roles from saved blueprint IDs on every open. Reject it: catalog changes would change old books, missing catalogs would remove presentation semantics, and series would not retain their original decisions. A richer engine layout schema is unnecessary for this pilot.

## Steps

1. **Write contract/regression tests first.** Target `MagicPaperTests/{OfflineStoryMappingTests,ReaderStoryMappingTests,ReaderTextTests,SeriesTests}.swift` and new `MagicPaperTests/ReaderReadingRhythmTests.swift`. Add cases before changing application code, but do not run them until final verification. Explicit TDD deviation: RED execution is intentionally unexecuted under repository AGENTS.md; do not claim a witnessed failing test. Acceptance: tests assert fields directly, including exact original text and spokenText, rather than relying on StoryPage equality.

2. **Persist only existing authored semantics.** Modify `MagicPaper/Models/Story.swift` minimally to add optional metadata; place any new helper model in an Xcode synchronized folder, e.g. `MagicPaper/StoryEngineBridge/StoryPageReading.swift` (Models is not synchronized). Update `OfflineStoryMapper.appPage(from:)` to copy `page.role.rawValue` and `page.refrain`. Add explicit tolerant decoding of malformed optional role/refrain values inside the small metadata type. Acceptance: old page JSON decodes with nil metadata; new metadata roundtrips; unknown roles remain readable; malformed optional metadata cannot discard the whole library. Do not change app story ID, seed, fingerprint, text, words, art, page count or engine composition.

3. **Transport metadata into the reader without changing speech.** Modify `MagicPaper/Screens/StoryReader/ReaderStory.swift` to copy optional metadata with a default nil. Keep its existing `paragraphs(of:)`, `paragraphs`, `spokenText`, page indexing and leaf offsets unchanged. Acceptance: ordinary stories and series reopen with preserved role/refrain; legacy/illustrated/classic pages without metadata keep current layout. No role inference from imagePrompt, nouns, blueprint name or artwork.

4. **Resolve meaningful visual blocks as a pure helper.** Create `MagicPaper/Screens/StoryReader/ReaderReadingRhythm.swift`; reuse `ReaderText.sentenceRanges(in:)`. The helper accepts original paragraphs, metadata and the existing `.breath`/`.paragraphs` preference. Reject unsupported metadata versions and unknown roles with nil. In the view bypass it entirely for `.scene`, accessibility Dynamic Type or compact height, retaining legacy speech coordinates. Every resulting block carries source coordinates, not a rewritten narration string. Use the following bounded rules:
   - 7–10 (`.paragraphs`), all supported roles: group consecutive existing sentences into blocks of at most two, preserving original paragraph boundaries.
   - `hook`/`discovery`: in older-reader mode isolate the first authored sentence as an opening block, then group remaining sentences in pairs. Younger-reader mode already renders each source sentence as one breath line; preserve that structure.
   - `resolution`/`celebration`/`emotional_ending`/`bedtime_transition`: isolate the final existing sentence as a quiet block in both age modes, with an optional preceding `MP.S.x6` gap only when actual measured narrative plus gap fits the available text viewport. Omit that optional gap for overflowing text while retaining readable grouping and scrolling. No headline styling, additional top padding, emotional copy or reward.
   - `companion`/`problem`/`attempt`/`challenge`: older-reader groups remain max-two sentences; younger breath lines retain their existing sentence units. Existing actual dialogue styling remains; invent no speaker, quote, bubble or new narrative meaning.
   - Valid authored refrain: isolate its existing exact suffix once only when the suffix boundary is sentence-safe. Preserve its source coordinates, and avoid a duplicate quiet/refrain block when both select the same sentence.
   - Missing/unknown role, unsupported version, unusable ranges or empty content: nil for the baseline presentation. Single-sentence pages remain a single block with no forced opening gap.
   Acceptance: both age layouts change meaningfully on suitable multi-sentence pages; 7–10 single-space composer output gains short visual paragraphs. Original characters appear in original order exactly once; original narration remains byte-for-byte unchanged. Role differences remain useful on text-only pages.

5. **Render projected blocks and adapt speech coordinates.** Modify `MagicPaper/Screens/StoryReader/StoryPageView.swift` to consume helper blocks only for eligible non-scene, non-AX, non-compact pages. Keep every block left-aligned, using the same existing age-specific fonts and selected size. Do not introduce a headline size, forced reveal or pause. Keep `ReaderWords.attributed`, child-name emphasis, sound-word treatment, font/size choices, spacing preference, easy reading, word actions and VoiceOver narration. Convert source-local speech marks into block-local marks by interval intersection; earlier blocks retain current already-read treatment. For 3–6 use source sentence positions rather than newly numbered visual groups to locate the spoken word. Acceptance: speaking a final separated sentence/refrain highlights the right text; no text is missed or duplicated; VoiceOver still reads one full narrative; long text/AX sizes scroll without truncation. Use MP tokens and existing read typography only. No new animation, interaction, microphone, remote service or controls.

6. **Preserve the exact artwork contract.** No changes to `StorySpotBinder`, catalogs, assets, `ReaderPage.composition`, B2 gates or image resolution. Acceptance: verified pinned opening artwork remains in its current approved upper position; unbound subsequent pages remain text-only. A missing art file falls back to text. The first-page map is never propagated to other pages. Character appearance and canonical identity are unchanged.

7. **Final verification and record once.** Lead runs the agreed app XCTest suite once at completion, including new rhythm tests and existing reader, spot and series tests. Perform source design-law checks on changed files. Inspect representative 3–4/5–6/7–8/9–10 offline outputs and the final simulator matrix: SE/Pro Max, light/dark, largest Dynamic Type, long text, narration and missing art. Update `docs/PROJE_HAFIZASI.md` and `design-handoff/reference/DEMO_CHANGELOG.md` through the lead's ownership. Record unexecuted checks honestly; no claim of measured reading-motivation improvement.

## Tests

App target `MagicPaperTests` gains:

- `OfflineStoryMappingTests`: all supported roles and authored refrain copied; composed/app text and page counts unchanged; art pins unchanged.
- `ReaderStoryMappingTests`: legacy nil metadata; optional metadata roundtrip; unknown raw role; wrong typed fields; malformed nonobject metadata; missing version defaults to 1; unsupported/malformed version baseline; exact narration unchanged; illustrated fallback unchanged.
- New `ReaderReadingRhythmTests`: older max-two-sentence grouping and isolated opening; younger breath units unchanged with quiet last gap; single-space older-reader prose splits; existing paragraphs preserved; Turkish quotes/attribution; exact suffix refrain appears once; duplicate middle occurrence untouched; invalid suffix and empty/unknown/unsupported-version metadata baseline; scene/AX/compact bypass; invalid/negative/overflow/surrogate boundaries safely rejected; source marks intersect correctly, including emoji/Turkish Unicode.
- `ReaderTextTests`: breath word and paragraph sentence tracking still target the same source text through grouping.
- `SeriesTests`: episode encode/decode and unlock retain role/refrain/art without reselecting; pre-metadata episodes still decode.
- Existing `ReaderPageCompositionTests`, `StorySpotReaderRenderingTests`, `StorySpotBindingTests` remain regression coverage. Engine test targets need no new cases because no engine code changes.

## Risks and mitigation

Narration offsets are the principal risk: preserve source text and map ranges rather than feeding reformatted blocks back into speech. Codable strictness can lose an entire library: keep fields optional and decode optional metadata defensively. Role-based presentation can become cosmetic: require real grouping differences in both age paths, particularly 7–10 composer output. Visual splitting can disrupt quoted attribution: reuse the existing tokenizer behavior and test it. Excess space can increase scrolling: retain top alignment and bounded inter-block gaps, never reduce fonts or constrain text height.

## Dependencies and compatibility

Touches library `StoryPage` JSON and nested series episode pages additively. No destructive migration or backfill; existing books keep baseline behavior. New books persist their authored semantics; unlocking series copies saved metadata. Previously prepared episodes have no metadata and stay baseline. No catalog/blueprint/template/version change, no new resource, no new CharacterEngine or engine API.

## Cost note

Zero additional AI/API calls, image creation, analytics or runtime story generation. Work is deterministic on-device projection of existing text; no new cache is required.

## Scope estimate and ownership

**S: several hours**, plus final device/simulator verification. This planner owns only this plan. Lead owns spec, implementation coordination, changelog/project memory and final verification. No other agent should concurrently edit the same Story.swift/ReaderStory.swift/StoryPageView.swift files. Existing unrelated worktree/assets/changelog edits are preserved.

## Resolved coordination decisions

Lead resolved the padding-only design conflict in favor of actual older-reader sentence grouping plus a restrained quiet final gap in both age modes. There is no top-padding requirement. Public contract above is final for this phase; implementation needs no additional approval. Scene, AX and compact layouts retain the legacy renderer. Planner changed only this document; lead records the completed planning work in the shared changelog.


## Execution checklist

- [x] Approved offline scope recorded in spec and UI brief; no API/new illustration.
- [x] Contract tests authored first (RED execution deferred under AGENTS).
- [x] Optional metadata, reader projection, source-safe block resolver and measured layout implemented.
- [x] Spec compliance reviewed; source-coverage and Unicode cases strengthened.
- [x] Independent quality review fixed breath-mode multi-sentence refrain and approved re-review.
- [x] Actual iPhone16 build/sign/install/launch succeeded;12 Foundation-source core tests passed.
- [ ] Full application XCTest/render and live reader acceptance remain unexecuted; user requested physical-phone build, recorded honestly in REPORT.
- [x] Final memory/changelog prepared; explicit-file commit includes this record.
