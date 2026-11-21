# Neutral story spot integration implementation plan

> For agentic workers: implement the tasks in order using the executing-plans workflow. The user has authorized implementation. Follow AGENTS.md: author tests first, but run builds/tests only once after the complete phase. Do not ask for another design approval.

**Goal:** Newly written offline books and prepared series episodes retain a reviewed, deterministic first-page object illustration when their complete page provenance matches an authored rule.

**Why:** Beautiful illustration, storybook reading, family memories and low operating cost.

**Layer decision:** Engine exposes selected authored-source identity; bridge owns matching and adaptation; app model persists an optional decision; reader resolves a saved file reference. Views do not infer subject matter. B2 character scene selection remains independent.

**Tech stack:** Swift, local StoryEngine SPM, Codable, bundled PNG files, existing reader downsampling.

## Bounded scope

This is the complete first-page neutral-object slice, not all-page semantic metadata. Only page 1, one `notice_anomaly` beat, hook role, a single reviewed visual variant, exact catalog version and exact authored-source fingerprint, with no refrain, qualify. Start with `na_neutral_01` and `na_neutral_02`; read their complete source and each eligible object's catalog description before authoring a rule. Every additional variant ID (including recall), extra beat, unknown source revision, family/occasion substitution, or unsupported discovery fails closed. Series can legitimately have no matching pages; do not force keepsake pictures into reminder text.

The twelve user-approved images may be promoted into a production manifest, but approval of an image is distinct from semantic eligibility. Initially bind only reviewed subject/state pairs. Defer music-box runtime rules because the image asserts an open lid and visible mechanism absent from generic hook prose. Exclude `na_neutral_04` for hanging paper lanterns because its middle-of-path placement conflicts with the drawing; map forest-route artwork also needs compatible setting restrictions. In particular, internally lit lanterns/crystal, open music box and empty nest require the text's object description to support those states; omit a rule if it does not. Do not equate pilot and shared shell IDs. Do not change template wording merely to increase art coverage.

## Inspected seams and file ownership

- `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`: `ComposedPage.variantIDs` already represents all selected beats and appended recall IDs; page grouping can combine beats. Add a small defaulted source identity property here rather than a second composition pipeline.
- `MagicPaper/StoryEngineBridge/IllustratedBookBinder.swift`: currently returns immediately for B2 guard failures. Neutral binding must execute outside that guard, also in Release with no avatar.
- `MagicPaper/StoryEngineBridge/SeriesManager.swift`: `episode(number:composed:seriesID:childName:childID:plan:strategy:family:)` maps all prepared episodes and is reused during family removal. This is the series binding seam. Unlock uses saved `episode.pages`.
- `MagicPaper/Models/Story.swift`: extend existing `StoryPageArt`, retaining its forgiving decoder and initializer compatibility.
- `MagicPaper/Screens/StoryReader/ReaderImageLoader.swift`: currently reads only Stories directory files. Add explicit bundle resolution, retaining async actor cache and downsampling.

Preferred universal seam: `OfflineStoryMapper.appStory` already owns both composed and mapped story plus catalogVersion for standalone, series preparation and family recomposition. Bind once at its final return. This avoids duplicate calls or editing SeriesManager/IllustratedBookBinder merely for neutral art.

Planner owns only this document. Builder owns engine provenance, Story.swift, StorySpotCatalog/StorySpotBinder, OfflineStoryMapper and core tests. Lead owns StoryArtResources packaging, ReaderImageLoader, resolver/reader tests, changelog and memory updates; no other agent may overwrite concurrent edits.

## Ordered steps

### 1. Pin authored source identity

- [x] Modify `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`; add defaulted `ComposedPage.authoredSourceFingerprint: String? = nil` and build it from a versioned canonical sequence of every selected template ID, variant ID and raw variant text, plus the bound discovery's exact semantic catalog fields (ID/name/description/traits). Use `EngineFoundation.StableHash` deterministic fingerprinting, never Swift `Hasher`; this is content identity evidence, not a cryptographic catalog integrity claim. Preserve ordered variants and include selected series/family/occasion source text. On appended recall either recompute including recall or clear the fingerprint; clearing is sufficient for this slice.
- [x] Tests in `StoryEngine/Tests/StoryEngineTests/StorySpotProvenanceTests.swift`: identical composition gives identical fingerprint; changing authored text under the same variant ID changes it; altered discovery name/traits changes it; appended recall cannot inherit the original fingerprint. Existing text/fingerprint generation and seed selection stay unchanged.

Acceptance: a downloaded catalog reusing version and IDs cannot acquire a reviewed rule when its selected source text or subject semantics differs. Existing direct ComposedPage construction compiles via the default property.

### 2. Publish local catalog and strict rule selector

- [x] Create `MagicPaper/StoryEngineBridge/StorySpotCatalog.swift`, `StorySpotBinder.swift`, and `MagicPaper/StoryEngineBridge/StoryArtResources/story-art-v1.json`; copy the approved PNG revisions from `design-handoff/proposals/2026-11-19-story-art-library/assets/` into `MagicPaper/StoryEngineBridge/StoryArtResources/`. Keep proposal files intact. Ensure Xcode resource membership preserves names/subdirectories; touch `MagicPaper.xcodeproj/project.pbxproj` only if existing project membership needs it.
- [x] Catalog entries carry schema version, asset ID, revision, SHA-256, style revision, file basename, approved status, exact subject ID/state and Turkish alt text. Rules carry policy version, exact catalogVersion, blueprint ID, first-page role/beat, complete ordered variant IDs and authoredSourceFingerprint. Record the reviewed rule evidence in `docs/research/2026-11-19-story-spot-rules.md` with raw source excerpts and real composed fixture seed/name/mode/age/content IDs. Do not call candidate inventory counts coverage.
- [x] Define `StorySpotBinder.bind(_ story: Story, composed: ComposedStory, catalog: StorySpotCatalog?) -> Story`. Require origin catalog version and content IDs, equal composed/app page counts and text, unique sorted page numbering, a clean selected page, every rule field and validated asset. Match page number explicitly, never unchecked zip/truncation. Preserve existing scene/image/art decisions. Nil/invalid catalog returns story unchanged.
- [x] Define `StorySpotCatalog.bundled` and an injectable loader/root for tests. Reject unknown schema/policy version, duplicate asset revisions, drafts, traversal filenames, missing files and digest mismatch. File verification happens once during catalog load, not during SwiftUI rendering.

Acceptance: output is deterministic; no keyword or substring matching, no random choice, no network calls, no B2 gate dependency.

### 3. Save the decision compatibly

- [x] Extend `StoryPageArt` in `MagicPaper/Models/Story.swift` with optional `schemaVersion`, `assetRevision`, `assetDigest`, `styleRevision`, `bundledFileName`, `subjectID`, `subjectState`, `variantIDs`, `authoredSourceFingerprint`, `bindingPolicyVersion`, and `catalogVersion`. Existing `sourceID` remains the stable asset ID. Default new initializer parameters to nil.
- [x] Preserve old art decoding. Malformed new fields must not throw away the library; unknown new schema/policy makes the new bundle art unusable, not silently render as a legacy scene. A saved valid pin resolves its own exact filename/digest without rematching today's rules. New catalog revisions retain old referenced bundled files.
- [x] In `MagicPaperTests/StorySpotBindingTests.swift`, test old Story JSON, round-trip full pin, malformed fields and unknown version fail closed. Assert art fields individually: `StoryPage.==` compares ID only and cannot establish pin preservation.

Acceptance: no library/series top-level schema migration or destructive rewrite. Old books remain unchanged and are never retroactively illustrated.

### 4. Connect standalone and series composition

- [x] In `MagicPaper/StoryEngineBridge/OfflineStoryMapper.swift`, replace the final mapped-story return with `StorySpotBinder.bind(story, composed: composed, catalog: .bundled)`. This single bridge seam handles standalone, initial series preparation and family-removal recomposition. Keep mapper initialization and B2 binder behavior unchanged. Inject catalog through a defaulted mapper parameter if test fixtures need it.
- [x] Keep `SeriesManager.episode`, unlock/restore/story(for:) and `IllustratedBookBinder` unchanged unless a demonstrated test requires a minimal adjustment. They copy saved pages or add B2 scenes later; no matching occurs on reading/unlock. Verify scene priority explicitly.
- [x] Tests in `MagicPaperTests/IllustratedBookFlowTests.swift` and `SeriesTests.swift`: eligible standalone gets spot with B2 disabled/no avatar; enabled B2 scene wins visually; five-episode state save/reload/unlock retains each episode's exact art fields; family removal leaves opened episode pins unchanged and newly composed unopened pages receive newly evaluated decisions. Missing content keeps existing calm-close behavior.

Acceptance: series episode 1 remains its existing library book; 2–5 bind once at preparation. A catalog change after preparation cannot alter unlock output.

### 5. Resolve saved bundle files in the reader

- [x] Add a focused `MagicPaper/StoryEngineBridge/StorySpotAssetResolver.swift` (Foundation only) with `url(for art: StoryPageArt, bundle: Bundle) -> URL?`, validating known saved metadata version, safe pinned filename, revision/digest and file presence independently of today's rule allowlist.
- [x] Extend `ReaderImageLoader` with `image(art: StoryPageArt, targetPixelWidth: CGFloat) -> UIImage?` using the resolver and existing downsampling/cache. Cache key includes revision/digest and width. If the existing image filename plumbing needs a discriminator, use `story-art://spot.torn-map/r5` with a strict local parser; resolve only the saved exact asset/revision filename through Bundle.main, never arbitrary paths or network URLs. Keep legacy `image(named:targetPixelWidth:)` unchanged.
- [x] Adapt existing reader model/composition mapping and `StoryPageView` image request to carry the saved bundle source. Inspect actual reader types before editing; do not put catalog selection into them. Preserve B2 scene priority and existing suppress-art-while-opening contract. Missing art returns the existing readable text layout with no empty reserved panel. Use saved Turkish alt text only; decorative art stays hidden if no approved description.
- [x] Extend `MagicPaperTests/ReaderPageCompositionTests.swift` and add resolver cases to `StorySpotBindingTests.swift`: valid saved pin, missing file, invalid path, wrong digest, unknown metadata version, legacy Stories directory image.

### 6. Verify real outputs and record delivery

- [x] Use the real bundled `ContentCatalogLoader` / `OfflineStoryComposer` fixtures in app tests. At least one eligible real composition must bind; another seed/name yielding a non-allowlisted variant must remain text. Include a genuine recall page and a genuine continuation page, not only hand-created ComposedPage doubles. Where the continuation cannot match this slice, assert nil art rather than changing its meaning.
- [x] Report actual fixture counts, asset IDs and covered page variants. Explicitly state that this phase does not claim all 12 assets or all age bands/pages are covered.
- [x] Lead updates `docs/PROJE_HAFIZASI.md` and prepends `design-handoff/reference/DEMO_CHANGELOG.md` with test evidence and limitations. No mid-phase test/build runs.

## Final verification commands

Run from repo root, once all steps are complete. First inspect installed simulator names with `xcrun simctl list devices available`; select an installed iPhone and use its exact name if the command below is unavailable.

```bash
swift test --package-path StoryEngine
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -only-testing:MagicPaperTests/StorySpotBindingTests -only-testing:MagicPaperTests/IllustratedBookFlowTests -only-testing:MagicPaperTests/SeriesTests -only-testing:MagicPaperTests/OfflineStoryMappingTests -only-testing:MagicPaperTests/ReaderPageCompositionTests -only-testing:MagicPaperTests/ReaderStoryMappingTests -resultBundlePath /private/tmp/MagicPaper-story-spots-20261119.xcresult
```

Expected: targeted tests pass; package failures are classified against documented baseline rather than reported as success. Existing code-sign/disk failures are blockers, not passing verification. Inspect reader with a real eligible composed book, unsupported page and missing asset across five papers; SE/Pro Max/iPad and largest Dynamic Type, light/dark. Capture actual evidence; do not update snapshots blindly.

## Risks and dependencies

- Fingerprint encoding must be unambiguous/versioned. Raw IDs alone are insufficient; content packages can replace authored text without new IDs. The source fingerprint is temporary narrow evidence, not a full semantic authoring schema.
- Bundled resources add app size; retain PNG revisions used by saved books and include checksum validation. Never fall back to a similar picture.
- Series persistence already carries pages, so no parallel book-level illustration metadata is introduced. Character art and appearance remain solely B2/CharacterEngine responsibilities.
- Reader new source plumbing touches shared files; keep changes minimal and preserve current image and text-only behavior.
- Dependencies touched: bundled image resources and manifest; optional StoryPageArt JSON fields; ComposedPage in-memory provenance; standalone binder and series helper. Remote content schema/package activation is unchanged.

**Cost note:** Zero remote AI calls, no download system. Matching and source fingerprints are deterministic on device; asset validation is cached at catalog load.

**Scope estimate:** M (days), one working bounded phase. All-page semantics, character art, remote asset packs and retroactive old-book art are later phases with separate plans.

## Execution record

Completed the bounded phase in the existing main checkout/branch under the user's repository preference. Root owned packaging/resolver/reader and documentation; builder owned engine provenance, persisted model, catalog/binder/mapper and core tests. Reviewer found a malformed-metadata legacy downgrade; raw key presence is now persisted and reader mapping fails closed. Test type ambiguity was corrected. No production selection text, seeds or B2 gate changed.

Packaging adjustment: Xcode rewrites PNG bytes, so checksum-pinned PNG payloads ship as `.mpart` resources; original proposal PNGs remain intact. Resolver supports safe `.mpart` and legacy `.png` names. All twelve packaged hashes and alpha decodes passed. Music box and nest have no runtime rule.

Verification: 145 app tests / zero failures / one skip; renderer one test / zero failures / eight attachments; new provenance two tests / zero failures. Full package: StoryEngine 933 tests / two skips / fifteen failed assertions in eight existing cases; unchanged baseline 068ca47 reproduces all eight cases and fifteen assertions. EngineFoundation17, CharacterEngine89 and VisualSystem51 tests pass. No test thresholds or authored narrative were changed to hide baseline failures.

Rendering acceptance is scoped: five papers, SE/Pro Max/iPad viewport sizes and AX5 were rendered inside iPhone17Pro simulator. Separate devices, full chrome gestures, VoiceOver and audio manual matrix remain unperformed; this record does not claim them. Commands/logs and real composed fixtures are in the research verification record. The checked implementation steps above are complete within this scope.
