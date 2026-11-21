# Reviewed discovery expansion implementation plan

> For agentic workers: use subagent-driven-development; test execution only at final window per AGENTS.

**Goal:** Expand exact-source discovery artwork from bell to eleven reviewed isolated subjects.
**Architecture:** Shared source/recall allowlists and explicit subject/asset fingerprints; authorization returns asset plus proof. v1 first, reviewed fallback second. Saved schema/policy unchanged.
**Tech:** Swift, Codable, CryptoKit, ImageIO, XCTest; existing bundled mpart files.

- [x] Inspect policy, canonical definitions, five full notice and 38 recall texts, existing asset drawings and ownership.
- [x] Write exact review decisions and pinned expansion manifest (11 entries); retain original bell resource.
- [x] Tests first: authorization cross-product/negative proofs, excluded subjects, corruption, real composer/map/save, all asset decodes and v1 priority.
- [x] Generalize ReviewedDiscoveryArtPolicy to entries and asset+proof authorization; preserve original bell load compatibility and pins.
- [x] Update ReviewedDiscoveryArtBinder to use authorization; keep complete-page guards.
- [x] Refactor StorySpotBinder to v1 helper then reviewed fallback without early-return loss; preserve nil catalog no-art behavior.
- [x] Spec review, code review, final focused Xcode tests; no engine code or full suite rerun without new reason.
- [x] Report actual coverage/tests/limitations; memory and own journal entry; commit only owned files.

Ownership: builder owns three bridge Swift files and reviewed tests plus the existing StorySpotBindingTests eligibility expectations; root owns manifest/review/spec/plan/report/memory/journal. Neither owns ReaderImageLoader, Classic/Originals, engine prose/selection. Shared checkout is dirty and another session may stage its own changes: never stage all or commit others' index entries.

Final verification: selected Xcode run TEST SUCCEEDED; 76 tests, 75 passed, 1 skipped, 0 failures. New policy 11/11; art/provenance combined 27/27. No engine edits or rerun, no device install or new UI matrix. Prior unrelated series failure remains unresolved.
