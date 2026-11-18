# Reader Layout Implementation Plan

> **For agentic workers:** Use the approved implementation delegation in this session. Work task by task on the current branch in the main repository. Repository/user rules override skill defaults: no worktree, branch switch, intermediate build/test/simulator run, or commit. Write regression tests first; execute the complete verification once after all changes.

**Goal:** Deliver the approved scene/spot reading composition and beautiful text-only pages while retaining every existing reading capability.

**Why:** Product pillars 4 Beautiful illustration, 5 Storybook reading, 6 Parent simplicity, and 9 Low operating cost.

**Architecture / layer decision:** Extend the existing app story format with optional presentation metadata and map it through the existing transient `ReaderStory` projection. Keep deterministic composition/layout decisions in a small reader presentation value; SwiftUI renders that value using existing typography and speech spans. No engine, CharacterEngine, remote generation, illustration preset, content matching or release-feature change.

**Tech stack:** SwiftUI, existing UIKit page curl, Codable, XCTest, existing MP design system.

**Authority:** User approved `reader-concept-61.html` and application implementation after the dated BRIEF/REVIEW were written; their “not approved” status is historical. Source design: `design-handoff/proposals/2026-11-18-reader-concept/{BRIEF,REVIEW}.md`.

## Inspected implementation and ownership

Builder owns Story.swift, ReaderStory.swift, StoryPageView.swift, optional reader helper, ReaderImageLoader.swift if required, MPSheets.swift, and reader tests excluding ReaderThemeTests.swift. Lead exclusively owns MPTheme.swift and new MagicPaperTests/ReaderThemeTests.swift, plus final documentation/changelog and verification. Planner owns only this plan. Reviewer reads the resulting diff.

| Target | Responsibility |
| --- | --- |
| `MagicPaper/Models/Story.swift` | Existing persisted `StoryPage`; optional spot role/description/source metadata only |
| `MagicPaper/Screens/StoryReader/ReaderStory.swift` | Preserve legacy mapping; project metadata and choose scene/spot/text |
| `MagicPaper/Screens/StoryReader/ReaderPageComposition.swift` (new, if needed) | Small deterministic composition and geometry policy, testable without a view |
| `MagicPaper/Screens/StoryReader/StoryPageView.swift` | Scene sizing, top-aligned readable column, modest post-text spot, existing spread |
| `MagicPaper/Screens/MPSheets.swift` | Reader settings order, current size label and live sample only |
| `MagicPaper/DesignSystem/MPTheme.swift` | Gündüz maps to existing `Palette.kagit0`; correct obsolete paper comment |
| `MagicPaperTests/ReaderStoryMappingTests.swift` | Mapping, persisted metadata compatibility and precedence regressions |
| `MagicPaperTests/ReaderTextTests.swift` | Extend only if text transformations change; preserve existing cases |
| `MagicPaperTests/ReaderPageCompositionTests.swift` (new, if policy extracted) | Adaptive deterministic layout rules |
| `MagicPaperTests/DesignSystemSnapshotTests.swift` | Existing paper snapshot and focused layout fixtures where supported |
| `design-handoff/reference/DEMO_CHANGELOG.md`, `docs/PROJE_HAFIZASI.md` | Lead records implementation and actual validation |

`Models/` is not an automatically synchronized Xcode group: put any new reader helper in synchronized `Screens/StoryReader/`, not Models or Services. A new test file requires confirming target membership; extending existing mapping tests avoids a project-file change.

## Steps

### 1. Specify compatibility in tests first

- [ ] Extend existing mapping tests before implementation; do not run them yet. Decode a legacy StoryPage JSON fixture without any new keys; assert fields individually because `StoryPage.==` compares only UUID.
- [ ] Specify cases: legacy file image → scene; resolved B2 scene remains scene even if a file has spot metadata; no art → text; explicit valid spot → spot with exact source/alt text; empty/missing art → text; unknown future role → legacy scene fallback without throwing.
- [ ] Round-trip new optional metadata through JSONEncoder/JSONDecoder and assert individual fields. Verify `opensAsTextOnly` suppresses every art path even when metadata exists. Existing leaf indexes, words, page count and spokenText must be identical before/after metadata.

Acceptance: tests encode backward compatibility and preserve existing image-reference priority, English-prompt exclusion, offline title and empty-page behavior.

### 2. Add a minimal optional presentation contract

- [ ] Add an optional metadata value to `StoryPage` carrying role, semantic alternative text, and source identity; existing imageFileName/imageUrl remains the art location. Prefer optional raw role String with typed resolution, or loss-tolerant decoding: a synthesized raw-value enum would reject unknown future values and could make an old library unreadable.
- [ ] Map metadata into `ReaderPage` with defaults on new stored projection properties to preserve current initializers. A real resolved `scene` takes precedence. Resolve a spot only with an actual image reference and explicit spot role; absent metadata preserves the legacy scene composition. Never infer the role from story text, page parity, seed, name or filename.
- [ ] Keep metadata optional in Codable. No migration/rewrite of saved stories, template versions or engine output; legacy whole-library blobs and newer per-story LibraryShelf files must both decode. Missing semantic spot information should conservatively render the existing scene/text fallback, never fabricate a narrative description.

Acceptance: no production story gains new art; every old illustrated page still opens; old text stories remain text-only. No demo assets added to the production catalog and no B2 Release enablement.

### 3. Render the approved reading pages

- [ ] Use scene/spot/text composition throughout `StoryPageView`, rather than treating `hasIllustration` as “large image above text”. Keep actual typography, paragraph/breath renderers, name and sound emphasis, speech observations, word actions and OpenURL handling intact.
- [ ] Portrait scenes occupy approximately 40% of usable height, bounded by source aspect ratio where known. Reduce image allocation for compact landscape and accessibility sizes; readable text wins. Preserve PaperLip and unframed edge-to-edge scene treatment.
- [ ] Make every text column start at the top; remove the short-page minHeight center alignment. Art-free and spot pages clear navBarHeight, use existing gutter/measure, and retain empty paper below short prose. Do not add symbols, decoration, repeated book title or filler art.
- [ ] Place transparent spot art after the text with x6 separation, centered in the text measure with fit sizing. Never scale it into the full iPad left leaf. Constrain or omit a spot when viewport/text size makes it compete with prose; keep long text vertically scrollable without shrinking font or changing folio.
- [ ] Reserve bottom chrome/folio clearance. Confirm current outer reader insets before adding padding to avoid double-insetting. Preserve iPad landscape scene-left/text-right spread and switch accessibility text sizes to a single readable column; text-only iPad must remain editorial rather than gaining decorative filler.
- [ ] Retain local asynchronous downsampling and stable reserved scene geometry while loading. Missing spot disappears; failed scene leaves readable text, without replacement artwork or repeated layout retries. Current ReaderImageLoader supports local story files only: do not expand this task into remote URL download/security work.

Acceptance: scene, valid spot, missing-image and text-only pages all read comfortably on small/large phones and iPad; text never disappears behind controls; narrative accessibility remains continuous while informative art is separately described.

### 4. Make settings reflect the approved design

- [ ] Reorder only ReaderSettingsSheet groups: Yazı → Kâğıt → Daha fazla. Show the current size name by the four-stop slider, preserving writes to app.readSize, settings.readSize and readSizeChosen.
- [ ] Add a short localized reading sample rendered with the selected MP.F.read size, line spacing and easy-reading tracking; do not invent story content or constrain it to a fixed height. Keep voice, rate, sound, haptics, auto-night and grain controls and the one bottom return action.
- [ ] Follow this checkout’s existing Turkish app-string conventions. The architecture-map `Services/LocalizationManager.swift` and string catalogs do not exist here; do not invent a localization service for this scope. Use a clearly identified short settings sample, not fictional story data. Allow labels to wrap rather than shrink.
- [ ] Change `ReadTheme.light.background` to existing white `Palette.kagit0`. Keep theme raw values and chosen preferences unchanged; retain the other four papers and contrast. Update misleading `paper` comment. Leave shared warm readerDayBackground asset unchanged because MPStoryPDF consumes it independently.

Acceptance: settings changes apply immediately without restarting speech, resetting progress, changing leaves or resetting saved choices; preview grows at accessibility sizes and all controls remain reachable.

### 5. Preserve interaction contracts and prepare final review

- [ ] Keep StoryReaderView/ReaderChrome/StoryReaderModel/page-turn container APIs unchanged unless an actual layout input requires a minimal modification. Permanent X, favorites, secondary-control timing, speech, adjustable seeking, previous/next, completion, page curl, Reduce Motion fallback and vocabulary interaction must survive.
- [ ] Check touched code for token-only fonts/colors/spacing/motion, accessible labels, no horizontal overflow, no new sensitive logging, and no decorative accessibility nodes.
- [ ] Lead updates changelog and memory with the final file list and honest verification result. Do not overwrite other sessions' documentation or treat stale “pending approval” lines as current authorization.

Acceptance: reviewer can trace every changed file to this approved reader scope; no content/engine/identity/entitlement changes.

## Tests and one final verification window

Write tests in steps 1–2, defer execution. No baseline run. Once all implementation edits and static review are finished, lead performs the single combined test/build/simulator window authorized by repository rules.

Use the installed Xcode context (`xcode-select -p`) and simulator inventory (`xcrun simctl list devices available`) to choose the existing iPhone 17 Pro / iOS 27 snapshot destination and available SE/Pro Max/iPad devices. Never run `xcodebuild -list`: project memory records package-resolution hangs. Reuse the lead's existing DerivedData/package cache path when present.

```sh
xcode-select -p
xcrun simctl list devices available
perl -e 'alarm 900; exec @ARGV' xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -testPlan TestPlan -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -disableAutomaticPackageResolution -skipPackageUpdates -derivedDataPath /tmp/magicpaper-membership-build -clonedSourcePackagesDirPath /tmp/magicpaper-membership-packages -resultBundlePath /private/tmp/MagicPaper-reader-layout.xcresult
```

Expected: relevant tests and existing regression targets pass; inspect test summaries and result bundle even if xcodebuild times out on exit (documented hang, exit 142). Do not report timeout as success. Snapshot references are iPhone 17 Pro/iOS 27 at 1x; changed light-paper/text-placement reference differences require visual inspection before any approved reference update. Use exact installed device OS if `latest` selects a mismatched snapshot environment. If dependency cache resolution is required, use the existing `-clonedSourcePackagesDirPath` cache; do not start a package update.

In that same final simulator window verify: text-only short/long/breath/paragraph pages; real existing scene; test fixture with transparent spot and missing spot; Gündüz/Krem/Sepya/Akşam/Gece; light/dark system; largest Dynamic Type; SE and Pro Max portrait, compact landscape, iPad landscape; VoiceOver labels/seek; Reduce Motion; page curl/buttons, close/favorite, settings live preview, word card, speech highlight/pause/seek/resume, last-page completion and reopening saved progress. Fixtures are test/demo data only, never attached to arbitrary saved stories. Capture required screenshots and report any unavailable device or unperformed check honestly. Run repository design-law searches on touched Swift files in this final window; existing violations outside the changed lines are separate debt.

## Risks, dependencies and cost

- Persistence: optional keys only; unknown role fallback and legacy decode tests protect the legacy blob and LibraryShelf per-story format. Inspect sync/PDF consumers but do not change them gratuitously.
- Layout: fixed scenes/spots can starve large prose; constrain image area, keep prose scrollable and reserve existing chrome clearance. Preserve paragraph character offsets for speech and vocabulary.
- Artwork: layout support does not prove semantic matching. The offline gouache pilot is a separate content task, with known variant/subject mismatches recorded in memory. Do not promote its sample art.
- Shared files: MPSheets and MPTheme are broad files; builder edits only reader sections. Lead coordinates with active owners; planner edits this file only.
- Dependencies: existing MPTheme, MPAppState, MPSettingsStore, ReaderImageLoader, LibraryShelf, MPSpeech/MPSpokenPosition, ReaderWords and existing page-turn renderer. No new package or service.
- Cost: zero remote AI calls, zero runtime generation; deterministic presentation of already available local images.
- Scope estimate: M (1–2 days including accessibility matrix and review). One phase; later semantic art integration is explicitly separate.
