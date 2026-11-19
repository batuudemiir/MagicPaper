# Offline reader rhythm · UI brief

19 November 2026. Design handoff for the approved local pilot; implementation and device verification remain with the builder. Baseline: f444129. This is a text-layout pilot, not a fully illustrated book or evidence of improved reading motivation.

## Feature

Child-facing story pages, shared reading at 3–6 and independent reading at 7–10. Preserve the existing breath/paragraph choice and all reading preferences. Age does not override the chosen reading mode. Add a small editorial difference between an opening, action and a quiet ending using authored page role and available space. Never alternate by page index.

No new art, scenes, characters, decorative icons, prompts, rewards, screens, remote calls or dependencies. Existing verified opening spot remains above text with its current sizing/pins. No art is repeated on later pages. Scene pages retain legacy rendering. A verified spot may accompany the text rhythm below it; its placement and size do not change.

## Layout

Retain `ZStack(ReaderPaper, GeometryReader, folio)`, current chrome clearances, `StoryPageView.gutter = MP.S.x7`, leading alignment, current measure (`readSize.points * 30`) and scroll container. Rhythm comes from grouping existing sentence ranges, not full-page top padding. No text centering, narrower column, panel, color change or changed title hierarchy.

Only a valid persisted `StoryPageReading` with a known authored role enables rhythm. Metadata comes through the offline mapper; old books without metadata keep their exact legacy rendering. Never infer role from page index, words, quoted speech, name, emotion or illustration subject.

### Paragraph mode (normally 7–10)

Use the existing `ReaderText.sentenceRanges` boundary policy on each original paragraph. Keep original paragraph boundaries; never merge text across them. Build visual groups of at most two consecutive existing sentences. Retain every original source range, punctuation and whitespace; group boundaries are presentation only, not rewritten paragraphs or inserted narration characters.

| Persisted authored role | Grouping |
|---|---|
| `hook`, `discovery` | Isolate the first existing sentence of the page as its own group; group remaining sentences in pairs within their original paragraphs. |
| `resolution`, `emotional_ending`, `bedtime_transition`, `celebration` | Group preceding sentences in pairs; isolate the final existing sentence as its own group. Add `MP.S.x6` to the ordinary gap immediately before that final group. |
| `companion`, `problem`, `attempt`, `challenge` | Pair consecutive sentences within each original paragraph. |
| Missing, malformed, future or unsupported role | Entire original legacy renderer. |

Use the current narrative paragraph gap (`readSize.points * 0.55`) between visual groups. A single-sentence page stays a single group, with no empty leading/trailing group or extra gap. Two-sentence opening/ending pages produce two groups. Existing short authored paragraphs remain separate. No duplicate title or additional heading. No progressive reveal: all groups are visible immediately and remain scrollable together.

### Breath mode (normally 3–6)

Keep existing one-sentence breath units, original paragraph membership, font and all normal sentence/paragraph gaps. Do not pair sentences or introduce another size increase. On the four quiet roles above, add only `MP.S.x6` before the final existing sentence when it is not the only sentence. Opening roles keep the ordinary breath layout because their sentences are already isolated. Use the same exact original sentence ranges as speech highlighting.

### Authored refrain

If optional authored refrain metadata exactly matches the trailing source text and its start and end align with existing sentence boundaries, treat that exact source range as one final visual group. It can contain more than one sentence only when the entire authored refrain explicitly does. Separate it by the same `MP.S.x6` extra gap. This takes precedence over the final-sentence role treatment: never apply two gaps or display the refrain twice. Preceding text still follows its role's grouping, with no empty groups.

Do not trim, translate, normalize, search for repeated words, or extract a likely refrain. Failed exact boundary validation means ignore refrain metadata and retain ordinary role behavior. Shipped blueprints currently declare no refrain; do not change catalog prose merely to demonstrate this treatment.

### Geometry and fallback

Use the actual text viewport remaining after existing chrome/spot clearance, not full screen height. Optional `MP.S.x6` quiet/refrain gap is permitted only when the complete grouped narrative with that gap fits at the final width, font, Dynamic Type, title and selected spacing. If it does not fit, drop only the optional extra gap; keep bounded sentence groups and ordinary scrolling. Until measurement is valid, omit the extra gap. Recompute without animation when geometry/preferences change. No font shrinking, reduced line spacing, clipping, truncated prose or partial/clamped decorative gap.

Accessibility Dynamic Type sizes, compact vertical size class, scene compositions and missing/invalid metadata use the complete original legacy renderer (not regrouped text). Unknown/invalid geometry also uses legacy until measurable. A small portrait screen with valid geometry may retain sentence groups and scroll normally; fit must never be achieved by hiding text. A failed art load follows the existing composition fallback; it creates no replacement drawing.

## Views and ownership

- `StoryPageView`: retains current inputs, speech observation and controls. Renders a resolved presentation plan. No new user setting. Measurement state is ephemeral.
- `ReaderText` presentation helper: accepts original paragraphs plus valid `StoryPageReading`, emits display groups containing original paragraph index and original UTF-16 ranges. Grouping and refrain validation live here, not as business logic in the SwiftUI view. Source paragraphs and `page.spokenText` remain immutable.
- Paragraph renderer: renders groups at the existing font, line spacing and tracking. For speech and word links map group-local positions through their original paragraph/range; never substitute regrouped indexes for source indexes. Preserve the existing dialogue treatment from the original paragraph, without inventing speakers or dialogue.
- Breath renderer: retains `readSize.larger.points`, minimum `.rahat` line spacing and existing word highlighting; only optional boundary gaps change.
- Mapper/model: owns persisted role/refrain transport. Layout helper owns eligibility/fit. No live engine calls from the reader.

## Tokens used

Use `MP.F.read` through existing `ReaderWords.attributed` (Nunito600 body, Nunito800 child name); existing `MP.F.displaySM` for an existing title only. Preserve `MP.ReadSize`, `MP.ReadSpacing`, easy-reading tracking and current name/sound emphasis.

Paper remains `ReaderPaper(theme:)`; text uses `theme.body`, `theme.foreground`, `theme.highlight`, `theme.readAlong`, and current `theme.muted` dialogue treatment. All five `MP.ReadTheme` papers remain selectable: light, cream, sepia, dusk, night. Components do not read `MP.Palette` directly. Extra spaces use only `MP.S.x6`; existing gutters and chrome tokens remain. Token additions requested: none.

## States

- Ready: role treatment only when all eligibility and fit checks pass.
- Unknown/old metadata, empty text or invalid geometry: existing baseline; no alert, badge or placeholder art. Overflow keeps grouped text scrollable but removes optional extra gaps.
- Art unavailable: existing loader behavior and readable text fallback, without new art.
- Loading/generating: existing story preparation remains unchanged; rhythm does not add a waiting phase or block opening.
- Speech active / word selected: retain current highlight, links, selection actions and source text. Rhythm never moves to follow speech or reveals text progressively.

## Adaptive and accessibility

SE and long Turkish/English text use the same fit rule; no device-name thresholds. Regular-width iPad text pages remain one column with the existing measure and gutter; no invented left-hand art page. Existing scene spread remains unchanged. Landscape compact height and all AX sizes use baseline. Preserve parent preferences on rotation and reopening.

Keep the single narrative accessibility label `page.spokenText`, existing static-text/narrative traits, accessibility order, word actions and folio behavior. Optional whitespace is not accessible content. `MPSpeech` reads the exact same text once, in the same order; no new spoken prompts. Existing targets stay at least `MP.S.tapMin` (48pt). VoiceOver and read-along correctness have priority over refrain styling.

## Localization and interactions

No new UI strings. Existing labels remain unchanged under the repository’s existing Turkish-string convention (no LocalizationManager exists here); authored story text remains story data. Never translate or normalize a refrain in the view to force a match. Validate both Turkish and English lengths.

Existing taps, swipe/page turn, seek, playback, close, favorite and Aa retain their behavior and `MPHaptics`. No new gesture, haptic, automatic turn, timed reveal or animation. Honor existing Reduce Motion handling.

## Acceptance / review evidence

Compare the same authored hook, attempt and quiet-ending pages at identical reading settings. Paragraph-mode opening and landing must differ visibly from paired flow groups. Overlong content must retain every sentence and source offset while scrolling; optional gaps disappear when fit fails. AX/compact-height and missing metadata return exactly to legacy. Verify both breath and paragraph layouts, all papers, SE/large phone/iPad landscape, largest AX, speech offsets and word links. Use real offline output; custom illustrated mock scenes cannot stand in for shipping evidence. No claim of engagement improvement before family observation.

Read: root `AGENTS.md`; reader section of `docs/PROJE_HAFIZASI.md`; `docs/research/2026-11-19-okuma-hevesi-arastirmasi.md`; `StoryPageView.swift`; `ReaderPageComposition.swift`; `ReaderText.swift`; `MPTheme.swift`; composer/blueprint role and refrain declarations. Conflicts: the initial padding-only brief is superseded by the lead-approved sentence-group pilot recorded here. Older spot-after-text proposal is superseded by the pinned top-spot baseline. Existing `.fixedSize(horizontal: false, vertical: true)` is intrinsic text sizing, not permission to fix font size. No implementation, builds, tests, simulator verification or commits performed for this brief.
