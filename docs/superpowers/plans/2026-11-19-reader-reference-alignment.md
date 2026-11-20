# Reader Reference Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement task-by-task within the lead agent's assigned ownership. User approval is already present; no additional design gate. Author tests first; execute tests and simulator only in the final verification window, as required by AGENTS.md.

**Goal:** Match the approved reader's typography, quiet controls and settings while placing neutral story-object art prominently above the text.

**Why:** Product Pillars 4 (beautiful illustration), 5 (storybook reading), 6 (parent simplicity), with on-device operation and accessibility preserved.

**Architecture / layer decision:** Incremental app presentation changes in StoryReader views and existing layout helpers. Keep semantic art selection and persisted identity in the existing bridge/models, retain engine output, speech orchestration and settings persistence. No engine, asset, character, or generation changes.

**Tech Stack:** SwiftUI, existing MP tokens, UIKit page-curl host, XCTest.

## Audited gaps

| Area | Current implementation | Approved target / action |
|---|---|---|
| Neutral spot | `StoryPageView.textScroll` appends a small spot after narrative; helper caps width at 240 and height at 160 | Move into top artwork band before narrative; ~25–30% of usable portrait page, larger contained image, no frame/card. Latest user approval supersedes older BRIEF/HTML spot-after-text. |
| Artwork adaptation | Spot sizing takes the remaining text viewport; no top-art allocation | Resolve size from page's usable area after top/bottom control clearance; omit at AX and constrained heights, reduce in landscape; never scale identity/art differently or crop neutral art. |
| Body font | `MP.F.read` already uses Nunito semibold | Already matches HTML weight 600; retain family, size choices, age rules and spacing factors. No global weight change. |
| Name | `ReaderWords.attributed` applies `.bold` | HTML uses 800: use `.heavy` for child-name range only, preserving sound, vocabulary and read-along attributes. |
| Bottom chrome | Outer HStack places arrows either side of a central page/speech/progress VStack | One rounded glass surface with two full-width rows: page + speech above, previous + seek + next below. Keep 64pt navigation and 48pt minimum controls despite smaller CSS mockup sizes. |
| Favorite | Selected heart uses legacy brand pink | Use reading theme's highlight, matching reference purple on day paper and accessible night counterpart. |
| Seek | Long-press/drag progress line and adjustable accessibility already work | Preserve existing seek previews, drag lifecycle and callbacks; increase available width through two-row composition; no lost behavior. |
| Top controls | Permanent X and grouped heart/Aa already exist | Preserve geometry and withdrawal behavior; use text `Aa` from MP font role if system textformat glyph visibly differs from approved reference. |
| Paper | Gündüz already resolves to white; four other themes present | Preserve five themes, paper grain, automatic night and existing palette; no new lilac theme needed. Art renders directly against matching paper. |
| Settings | Yazı → Kâğıt → Daha fazla and live preview already implemented | Preserve bindings and order. Remove surplus panel density: live sample directly on paper, simple easy-reading row, explicit close in header alongside return action; match reference without deleting advanced settings. |
| Swatches | Adaptive columns, single-line labels with minimumScaleFactor, display-family Aa | Five columns when space permits; adaptive/wrapping at AX/narrow widths, no shrinking essential labels; Nunito Aa, selected mark plus trait/border. |

## Ordered steps

1. **Author regression cases first.** Targets: `MagicPaperTests/ReaderPageCompositionTests.swift`, `MagicPaperTests/ReaderTextTests.swift`, `MagicPaperTests/StorySpotReaderRenderingTests.swift`. Cover ordinary portrait top-art band bounds, constrained height/landscape reduction, AX omission, nonnegative dimensions, text-only missing art and existing scene bounds. Extend actual render evidence to include full reader chrome and settings, not page-only images. Do not run tests yet.
   - Acceptance: tests express top-art allocation from usable page geometry; existing bundled-art integrity and mapping tests remain applicable.
2. **Place spot art above prose.** Targets: `MagicPaper/Screens/StoryReader/ReaderPageComposition.swift`, `MagicPaper/Screens/StoryReader/StoryPageView.swift`.
   - Move spot rendering out of `textScroll` into the portrait stack above text. Keep `.scene` edge-to-edge rendering/PaperLip and iPad scene spread unchanged. Spot uses aspect-fit, no PaperLip, border, clipping-to-fill, card or shadow. Base normal portrait spot height on usable height (~0.28, bounded within 25–30% where normal geometry allows), with token-sized side gutters and width cap generous enough to read as primary art. Top clearance must keep X/heart/Aa clear; bottom clearance must match actual two-row chrome. When image fails, existing unavailable key switches to text for the visit.
   - Acceptance: first visible content after upper controls is neutral art, then prose; no duplicate art after prose; long text scrolls, short text stays still, AX omits optional art and keeps full readable column.
3. **Align typographic emphasis.** Target: `MagicPaper/Screens/StoryReader/ReaderWords.swift`; inspect-only shared source `MagicPaper/DesignSystem/MPTheme.swift`.
   - Change child-name emphasis to Nunito heavy (800) via MP.F.read; preserve body semibold (600), sound treatment, Turkish range detection and link/read-along ranges. Preserve 17/19/22/26 choices, breath one-step-up and `points × spacing.factor`; CSS line-height 2.05 is not SwiftUI lineSpacing.
   - Acceptance: body matches reference weight without making every word bold; names retain color + weight, vocabulary remains actionable.
4. **Recompose chrome, preserving contracts.** Target: `MagicPaper/Screens/StoryReader/ReaderChrome.swift`.
   - Use VStack inside existing glass surface: upper HStack page label / speech, lower HStack previous / progressLine / next. Retain callbacks, boundary states, family voice, finish route/checkered flag, hidden progress, scrub panel and permanent close. Selected heart uses theme.highlight. Keep navigation 64pt, speech hit height at least 48pt, flexible labels at AX; avoid `.lineLimit(1)` forcing essential controls into illegibility. Add AX adaptation as needed through wrapping/vertical arrangement, not font shrink. Use existing MP spacing/glyph/font tokens.
   - Acceptance: approved two-row arrangement visibly matches; every existing action works, visible controls do not cover last text line, hidden controls leave accessibility tree, no new haptic or timeout policy.
5. **Polish existing settings.** Target: only `ReaderSettingsSheet` section in shared `MagicPaper/Screens/MPSheets.swift`; lead must coordinate shared ownership before edit.
   - Add header close action using onClose; keep system half-sheet and bottom return. Preserve current size slider (approved BRIEF explicitly retains it even though HTML shows four segmented buttons), immediate bindings and chosen-setting persistence. Present sample with existing MP read typography on current paper without extra card treatment; simplify easy-reading presentation while keeping label/helper/toggle. Improve theme swatch checkmark and adaptive wrapping, Nunito sample glyphs; retain texture, automatic night, voice/speed/haptics under Daha fazla. All touched/new visible and accessibility text uses existing localization approach.
   - Acceptance: settings are visually quiet and scroll at AX, selected paper is evident without color, all existing preferences survive reopen and page position is unchanged.
6. **Final single verification window and documentation.** Targets: relevant app test targets, `docs/PROJE_HAFIZASI.md`, `design-handoff/reference/DEMO_CHANGELOG.md` (lead ownership).
   - Run focused reader/layout/text/mapping/theme/render tests once implementation is complete; inspect failures and distinguish known engine baseline failures. Capture SE and Pro Max day/night, largest Dynamic Type, iPad landscape, spot/text/scene, chrome shown/withdrawn and settings. Inspect real composed story spot plus long legacy text; exercise previous/next/seek, favorite, close, read aloud, vocabulary, settings and completion. Run changed-file design-law source checks. Record exact evidence and any unverified manual interaction honestly.
   - Acceptance: tests pass or documented pre-existing failures are isolated; screenshot evidence confirms art-before-text and two-row chrome; no clipping/overlap, no new appearance or persistence changes. Append changelog and memory before claiming complete.

## Tests

`MagicPaperTests` gains meaningful geometry regressions and rendering evidence; reuse `ReaderStoryMappingTests`, `StoryReaderModelTests`, `ReaderProgressTests`, `ReaderThemeTests`, `ReaderTextTests`, `StorySpotReaderRenderingTests`. No new StoryEngine tests or SPM changes required. Render tests currently only assert PNG presence; image attachments require visual inspection, and must not be described as automatic pixel-layout assertions.

## Risks and mitigations

- Enlarged art plus two-row chrome could squeeze SE prose: calculate from usable geometry, omit art at AX, retain vertical scrolling.
- Moving art can accidentally duplicate it or make missing art reserve empty space: single top slot and existing stable unavailable-image fallback.
- Styling attributed names can disturb word/read-along formatting: change only name font range, retain transformation order and range logic.
- Full-screen reference has OS-safe-area differences from 393px HTML: reproduce hierarchy/proportions with MP tokens, preserve tap sizes and system sheet behavior.
- Older BRIEF calls for spot below text; latest user explicitly approves top spot. Preserve this documented intentional override. Existing 64pt navigation and slider survive smaller HTML controls under AGENTS/BRIEF requirements.

## Dependencies and compatibility

No persisted formats, migrations, catalog, asset digest, source pins, story page counts, generation or CharacterEngine changes. `MPAppState` / `MPSettingsStore`, `ReaderImageLoader`, `MPSpeech` / `MPSpokenPosition`, page-curl container and bridge binding remain existing dependencies. This plan owns documentation only; lead assigns distinct app/test owners and records shared-file coordination. No other agent edits were reverted.

**Cost note:** Zero remote calls; all changes render bundled/cached existing illustrations and on-device text/settings.

**Scope estimate:** M (1–2 days including final adaptive and interaction verification); implementation itself is a small incremental reader change.

**Plan validation:** Read AGENTS, reader/spot memory, current implementation/tests, approved BRIEF and reader-concept-61.html. No application code, build, tests or simulator executed by plan author.


## Execution record — 19 November

- [x] Geometry/name regressions and genuine 5–6 story render fixture authored.
- [x] Top spot, Nunito800 name, two-row chrome, visible seek thumb and Aa settings implemented.
- [x] Removed AX3 caps; shared bottom clearance adapts to compact-height AX; host passes sizing environments.
- [x] Independent review: fixed scalable Aa being constrained to 48×48; minimum dimensions now expand. Final visual inspection also corrected reader-only segmented surface, opaque settings footer and filled speech glyph.
- [x] Initial selected app suite: 155 executed, one existing skip, zero failures. The first attempt exposed a render fixture missing ageBand; factory now uses blueprint.ageRange. Production mapper was unchanged.
- [x] Post-polish focused rerun:58 tests, zero failures;15 final attachments exported and key day/night/SE/text-only/settings normal+AX5 visually inspected (REPORT).

No interactive end-to-end gestures, physical-device acceptance, audio playback or VoiceOver session claimed. XCTest renders use real components with no-op callbacks at fixed viewports in one simulator. Package engine suite was not rerun because engine/content contracts are unchanged.
