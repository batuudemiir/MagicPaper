# Story art wave3 implementation plan

**Goal:** Grow reviewed object pool from 14 to 20 with six new literal gouache objects and actual story mappings.
**Architecture:** Existing exact-source publishing policy and persisted art pins; new closed manifest edition only. No engine or UI change.
**Tech:** Built-in image_gen, transparent PNG/mpart, Swift/CryptoKit/ImageIO/XCTest.

- [x] Inspect canonical six objects, source contract, actual preschool constraints and duplicate-copy absence.
- [x] Generate/reference-review six objects; preserve exact attributes; root packages byte-identical mpart and source PNGs.
- [x] Root creates SHA-pinned wave3 manifest/review records preserving all prior14 entries and source/recall/paired records.
- [x] Builder tests first: actual six subject fixtures, valid preschool toys with village-green habitat, all20 decodes, old14 manifest and existing legacy/v1/corruption guards.
- [x] Builder updates only policy loader edition/count/SHA and tests; authorization/binder/engine/reader unchanged.
- [x] Spec then independent quality review, fix blockers; final selected app tests once per AGENTS.
- [x] Root exports actual fixture evidence, report/production record/memory/own journal hunk; explicit-path commit, no push.

Ownership: root assets/resources/docs; builder ReviewedDiscoveryArtPolicy.swift + ReviewedDiscoveryArtPolicyTests.swift. Dirty shared journal is preserved; no other worktree or unrelated code edits. Known metric/series issues remain outside scope. No every-story or every-age-per-subject guarantee.

Final: selected app91 tests,90passed/1skip/0fail. Six genuine fixture attachments exported,20reader decodes. Zero engine/UI/binder edits. Legacy resources and authorization lists unchanged. No phone install or newUI/VoiceOver matrix.
