# V4 illustration integration plan

User authorization: 27 November, integrate generated artwork following approved source-bound design. Base: codex/bes-arkadas/claude-uygulama; isolated codex/v4-story-art-integration. Preserve unrelated checkout deletions; no engine/content/selection/pin changes.

- [x] Bundle 35 selected assets as immutable revisioned .mpart files, preserving PNG bytes and SHA; exclude rejected variants.
- [x] SHA-pin an app policy with exact V4 payload, complete book templates and parent provenance, asset metadata and explicit page rules.
- [x] Validate whole composed book, personalized text and rendered SHA before binding. Reject mutations, duplicate/missing pages, invalid policy and old versions. Preserve existing images; at most three distributed new moments.
- [x] Bind only from new P56StoryMapper.story creation. Persist StoryPage.art policy4 with strict V4 namespace; preserve old policy1–3 and oldbooks.
- [x] Connect V4 five identities using new canonical portrait assets; retain old assets and current choice/layout behavior.
- [x] Author source-mutation, persistence, integrity, reader and legacy tests first; run final checks once per AGENTS.
- [x] Review, report bundled/authorized/reachable counts and limitations, journal and scoped commit. No device or full-coverage claim without evidence.

Immutable engine artApproved=false remains historical metadata. User-authorized app rules independently approve specific asset/source pairs; auto semantics/frequency are not authorization.

Validation limitation:6facade tests pass; iOS test/build blocked at package fetch. No main merge or device install. Full report: docs/research/v4-art-integration/REPORT.md.
