# Originals Page Illustrations Implementation Plan

> **For agentic workers:** Execute inline with executing-plans. User approved the design on 20 November and authorized occasional Ragi cameos. Do not dispatch implementation agents.

**Goal:** Bundle 14 narrative-matched illustrations for the two published Original books.

**Architecture:** Keep `ClassicText.pages` unchanged and add optional parallel `illustrations` metadata (`asset`, `altText`). The catalog builder validates and copies authored page images into image sets. `ClassicReading` maps complete metadata into `StoryPage.imageFileName` using an explicit `asset:` prefix and scene alt text; `ReaderImageLoader` loads that prefix without touching private story files. Existing reader composition handles images and fallback.

**Tech Stack:** Swift, UIKit image decoding, existing SwiftUI reader, Python catalog builder, built-in image_gen.

## Task 1 — Page art
- [ ] Create `Content/Originals/published/<slug>/illustrations/page-01.jpg` through `page-07.jpg`, separately generated from cover style references. Save exact prompts and Turkish alt text in each book's `illustrations.json`.
- [ ] Inspect every image: characters, six snowflake arms, scarf removal/replacement, hats, scene timing, no text. Ragi cameo only on lullaby pages 3/5 and snowflake page 1, per user authorization.
- [ ] Update WORLD.md to record that Ragi may appear as a silent visitor in interior art. Preserve story text.

## Task 2 — Backward-compatible content mapping
- [ ] Add tests first in `MagicPaperTests/OriginalTalesTests.swift`: legacy JSON decodes without illustration data; complete arrays map scenes and alt text; incomplete arrays stay text-only; all 14 shipped images exist and load using the reader loader.
- [ ] Add `ClassicPageIllustration: Codable, Equatable` with `asset: String` and `altText: String`. Add `ClassicText.illustrations: [ClassicPageIllustration]? = nil` and safe `illustration(at:)` that requires matching page count, valid index and nonempty fields.
- [ ] In `ClassicReading.story`, enumerate the selected narration's text pages. For each valid illustration set `imageFileName = "asset:" + art.asset`, and `page.art = StoryPageArt(role: "scene", altText: art.altText, sourceID: tale.slug)`.
- [ ] In `ReaderImageLoader.image(named:targetPixelWidth:)`, recognize only explicit `asset:` references; load `UIImage(named: String(fileName.dropFirst(6)))`, prepare a proportional thumbnail with maximum dimension `max(targetPixelWidth, 1)`, cache using the existing key. Private story files retain the existing ImageIO path.

## Task 3 — Catalog and authoring contract
- [ ] Extend `Scripts/ClassicsCatalog/build_classics_catalog.py` to read optional sibling `illustrations.json`. Require matching count, sequential `page` values, nonempty `altText`, safe exact file names `page-NN.jpg`, existing JPEG sources. Copy to `original-<slug>-page-NN.imageset`, emit `soft.illustrations` in page order. Validate manifest completely before copying its assets.
- [ ] Add a Python unittest for optional/complete/partial/unsafe manifests and a temporary source/assets directory, isolated from working content.
- [ ] Run catalog builder after art is ready and inspect changed catalog and asset counts. Update `Content/Originals/README.md` with new authoring files.

## Task 4 — Final checks and record
- [ ] Follow repository rule: tests and simulator only after the implementation plan is complete. Tests are authored before production changes, but the RED run is deferred by the repository's explicit rule; document that deviation honestly.
- [ ] Run Python validation tests, catalog determinism, `git diff --check`, and focused Xcode tests (`OriginalTalesTests`, `ClassicsCatalogTests`, `ReaderStoryTests` when available). Use `/private/tmp` derived data and record environmental restrictions.
- [ ] Inspect reader on small/large simulator with day/night and accessibility text sizes if simulator is available. Existing reader layout is reused.
- [ ] Review diff for unrelated changes, add own entry under `design-handoff/reference/DEMO_CHANGELOG.md` without modifying existing edits, and commit only this task's files.

## Execution ledger
- 20 Nov: Design approved; Ragi cameo permitted by user, overriding previous no-Ragi world restriction for these interior illustrations.
- Ruling: Reuse current checkout; unrelated edits and proposals are left in place.

- Steering: user supplied MagicPaper artwork and approved matching covers. Purple must not dominate. Final total is 14 interior images + 2 covers; detailed first-pass gouache is superseded. Canonical style reference copied to `Content/Originals/brand/interior-style-reference.png`.
