# Unchanged Prose Art Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow the user's existing delegation authorization; do not request execution permission again.

**Goal:** Establish and eventually enforce meaningful bundled narrative illustration coverage while preserving every authored sentence and the current story selection distribution.

**Architecture:** Inventory existing semantic anchors in an external reviewed sidecar, then match illustrations against the actual selected source evidence across all narrative pages. A coverage checker distinguishes proven coverage, proven counterexamples and unresolved cases. Production integration is a later bounded slice after its coverage and asset prerequisites are satisfied.

**Tech Stack:** Python standard-library offline audit tools; JSON annotation data; existing Swift StoryEngine composer, app mapper, pinned bundled-art resolver and SwiftUI reader.

---

## Scope and execution boundaries

The immediately executable slice is Tasks 1–3: audit tooling and annotation data only. It must not edit app/engine production sources, template prose, selectors, bundled art, package acceptance or reader behavior. Tasks 4–7 specify subsequent separate reviewable slices and their acceptance contracts; produce their implementation details after audit results identify actual gaps. No universal coverage claim follows from samples or an incomplete inventory.

The proposed hard floor is at least one genuinely illustrated narrative page per newly written offline story, excluding cover, dedication and ending leaves. The age-density suggestion of three younger/two older pages is not an approved or certified requirement. Record distinct illustrated pages and distinct visual moments separately from reuse of the same asset.

Repository rules override ordinary incremental test commands: prepare tests first, inspect while implementing, and execute the relevant checks once at the end of the completed slice. Do not build the app or run simulator tests for the audit-only slice. The lead owns shared architecture/spec/changelog files; this plan does not assign those files to another worker. No commits or publishing are implied by this plan.

## File ownership map

Immediate slice:

- Create `Tools/story_art_coverage_audit.py`: read-only resource inventory, annotation validation and deterministic report generation. No writes to corpus inputs and no import side effects.
- Create `Tools/test_story_art_coverage_audit.py`: synthetic fixtures that expose stale evidence, missing annotations, ambiguity and unjustified proof claims.
- Consume `docs/research/2026-11-20-art-anchor-audit.json`: content agent's reviewed sidecar; coordinate its schema before editing. The content agent owns this file and its `.md` explanation.
- Create `docs/research/2026-11-20-art-anchor-coverage.json`: generated status report; identify source hashes, inventory scope and unresolved cases.

Subsequent slices:

- New `StoryEngine/Sources/StoryEngine/Offline/StoryArtEvidence.swift`: proposed pure semantic evidence and matching types.
- `OfflineStoryComposer.swift`, `RecallLines.swift`, `AuthoredSourceFingerprint.swift`: carry exact source evidence without changing prose or variant selection.
- New `StoryEngine/Sources/StoryEngine/Content/StoryArtCompatibility.swift`: explicit versioned art compatibility contract.
- `Content/ContentPackage.swift`, app `StoryEngineBridge/RemoteContent/CatalogSourceResolver.swift`, `Scripts/ContentPublisher/Sources/PublisherKit/Publisher.swift`: publication and runtime package acceptance.
- `MagicPaper/StoryEngineBridge/StorySpotBinder.swift`, `StorySpotCatalog.swift`, `StorySpotAssetResolver.swift`, `OfflineStoryMapper.swift`: bind and verify actual bundled assets.
- `MagicPaper/StoryEngineBridge/SeriesManager.swift`, `StorySeries.swift`: new/recomposed episode boundary; preserve saved decisions.
- `MagicPaper/Screens/StoryReader/ReaderStory.swift`, `ReaderPageComposition.swift`, `StoryPageView.swift`, `ReaderImageLoader.swift`: reliable visible illustration and saved-pin resolution.

## Task 1: Fix the audit data contract

- [ ] Read the current spec and content agent inventory before selecting fields. Preserve their existing evidence instead of replacing their work.
- [ ] Agree on annotation records equivalent to the following schema. IDs are contextual, never globally assumed unique. `sourceTextSHA256` hashes the exact UTF-8 authored text. `anchorRange` uses Unicode scalar offsets in that authored text; this avoids confusing Turkish/emoji indices with UTF-16 reader indices. Unresolved authoring judgments remain explicit.

```json
{
  "schemaVersion": 1,
  "records": [{
    "sourcePath": "relative/resource.json",
    "templateID": "template-id",
    "variantID": "variant-id",
    "sourceTextSHA256": "64 lowercase hexadecimal characters",
    "reviewStatus": "reviewed",
    "anchors": [{
      "kind": "discovery_presence",
      "anchorRange": [0, 20],
      "subjectSlot": "discovery",
      "requiredFacts": ["present"],
      "forbiddenDepictionFacts": ["unattested_identity"],
      "reviewNote": "Literal presence is established; no child depiction is authorized."
    }]
  }]
}
```

This is a proposed normalization contract, not permission to invent annotations. Other allowed kinds: `setting_presence`, `environment_feature`, `literal_sound_source`, `reviewed_concept`. A metaphorical opening door does not imply a physical door. Missing state is unknown, not permission to depict any state.

- [ ] Define output statuses exactly: `inventory_only`, `sampled`, `proven_covered`, `proven_uncovered`, `unresolved`. Only a sound exhaustive reachability/overapproximation argument can emit `proven_covered`; the first slice emits `inventory_only` even if all inventoried records are annotated.

## Task 2: Implement the read-only inventory and annotation validator

- [ ] Write synthetic tests before implementation. Include the following independent assertions, using temporary directories rather than modifying repository resources:

```python
def test_missing_annotation_never_means_no_anchor():
    report = audit_fixture(variants=[variant("one", "Bir ses geldi.")], records=[])
    assert report["status"] == "inventory_only"
    assert report["unresolved"][0]["reason"] == "unreviewed_source"


def test_stale_text_hash_invalidates_annotation():
    record = reviewed_record("one", "Eski söz.")
    report = audit_fixture(variants=[variant("one", "Yeni söz.")], records=[record])
    assert report["errors"][0]["reason"] == "stale_source_hash"


def test_complete_sample_does_not_certify_universal_coverage():
    report = audit_fixture(variants=[variant("one", "Bir zil vardı.")],
                          records=[reviewed_record("one", "Bir zil vardı.")])
    assert report["status"] == "inventory_only"
    assert report["certifiedMinimumNarrativePages"] is None
```

Define `variant`, `reviewed_record` and `audit_fixture` in the test module as small JSON fixture builders around the tool's public `audit(resource_root, annotation_path)` function. Add fixtures for identical variant IDs in different files, orphan annotations, invalid ranges, unknown anchor kinds, duplicate conflicting annotations, and reordered input files producing identical reports. The validator must reject an absolute or escaping `sourcePath`.

- [ ] Implement `audit(resource_root: Path, annotation_path: Path) -> dict` and `main(argv=None) -> int`. Traverse resource JSON with sorted paths; recursively inventory objects containing a string `id` and string `text` beneath a `variants` array. Do not treat notes, titles or facts as template variants. Retain source path plus enclosing template ID when present; use the enclosing file's beat identity where no template ID exists.
- [ ] Inventory all authored template families, including age-specific, bedtime, recall, occasion, family and series sources; report unrecognized resource shapes instead of silently ignoring them. This inventories sources, not effective selector eligibility.
- [ ] Validate exact source hashes, ranges and contextual identities. Distinguish `reviewed` with zero anchors from unreviewed sources. Preserve editorial uncertainty rather than deriving semantic truth from keyword search.
- [ ] Implement CLI options `--resources`, `--annotations`, `--output`. The output path must be supplied; otherwise print JSON to stdout. Exit 0 for a valid incomplete inventory, 2 for malformed/stale annotations or resource parsing failures. An incomplete result is not an operational failure and is never a coverage certificate.

## Task 3: Produce a reviewable baseline once the slice is complete

- [ ] Inspect the diff to confirm only tool/tests/report files changed; coordinate content-agent sidecar updates without overwriting them.
- [ ] Run the final audit-only validation batch once:

```bash
python3 -m unittest discover -s StoryEngine/Tools/tests -p 'test_audit_art_anchors.py'
python3 Tools/story_art_coverage_audit.py --resources StoryEngine/Sources/StoryEngine/Resources --annotations docs/research/2026-11-20-art-anchor-audit.json --output docs/research/2026-11-20-art-anchor-coverage.json
```

Expected: tests pass; real audit produces a deterministic valid report or precise annotation errors. Do not expect universal coverage. Fix actual failures and rerun only affected checks after fixes.

- [ ] Report total source records, reviewed records, unresolved records, stale/orphan records, and inventory blind spots. Do not confuse the number of records with selectable stories.
- [ ] Give the lead the change summary and final check results for the required `design-handoff/reference/DEMO_CHANGELOG.md` entry. Keep app/engine production changes out of this slice.

## Task 4: Separate pure matching and reachability analysis slice

Prerequisite: reviewed sidecar semantics and an explicit list of inventory blind spots. Before implementation, write a focused follow-up plan with complete Swift code and executable tests.

- [ ] Introduce proposed `StoryArtEvidence` containing exact authored-source identity, current page number, anchor kind, bound subject ID, supported facts and unresolved/contradiction flags. `StoryArtCandidate` declares asset identity/revision and facts the depiction asserts. `StoryArtMatcher.matches(evidence:candidate:)` must be pure and reject unknown required facts, contradictions or ambiguous bindings.
- [ ] Define `StoryArtCoverageAssessment` with separate `certifiedMinimumNarrativePages`, `unresolvedCases`, `counterexamples` and provenance of the assessed corpus. Match all narrative pages; never select text variants to obtain art.
- [ ] Reuse the real composer's eligibility logic or expose a pure shared eligibility seam. Do not implement a Python approximation and call it authoritative. Include history-dependent preference fallback, parent safety, family/occasion replacements, age-band serving, series keepsakes/calm endings and recall/refrain transformations.
- [ ] Prove coverage over a sound finite abstraction of semantic states. If the abstraction admits an uncovered case, determine reachability or retain `unresolved`; do not silently discard it. Concrete composer fixtures witness counterexamples but successful samples never prove the universal claim.
- [ ] Require byte-for-byte composed text, chosen variants and fingerprints to match pre-change outputs across fixed representative inputs. Add adversarial semantic tests for physical/metaphorical doors, audible/visible discovery, changed state, page-level contradiction and duplicate IDs.

## Task 5: Asset production and reviewed binding slice

Prerequisite: the checker identifies which meaningful assets cover actual gaps. A setting-only floor is one candidate, not a preselected universal solution.

- [ ] Select a mixed bank of setting plates, discovery/state spots and reviewed contextual illustrations. Commission only evidenced requirements. No generated child/companion/family identity is inferred from prose.
- [ ] Extend the existing manifest with versioned semantic rules beside the unchanged strict pilot rules. New rules attest exact reviewed source evidence; preserve revision/digest/style/alt-text pins. Keep optional richer art separate from the sole guaranteed illustration designation.
- [ ] Carry selected-source evidence through `ComposedPage`; preserve it when recall is appended. Validate final-page contradictions after all transformations. An unrelated recall must neither erase a valid anchor nor authorize depiction of the remembered object in the present scene.
- [ ] Bind in `OfflineStoryMapper` once, including all precomposed series episodes and family-removal recompositions. Require at least one compatible verified **decodable** local asset before asserting the completed-story art contract. Retain source-semantic fingerprints and exact page association.
- [ ] Add corrupt-image-with-valid-checksum, missing-file, wrong-revision, unsupported-state and multi-page-selection tests. An invalid optional asset must not invalidate a separately valid guaranteed floor; absence of all eligible floor assets must produce an explicit contract failure rather than false success.

## Task 6: Publication, compatibility and saved episodes slice

- [ ] Add an explicit art-contract version/capability declaration to catalog packages and validate it in publisher `buildPackage` plus runtime `CatalogSourceResolver`/`RemoteCatalogPolicy`. Catalog version equality alone is neither a semantic proof nor a compatibility mechanism.
- [ ] A future setting/subject ID needs a reviewed supported mapping and compatible local art. Reject activation of incompatible packages atomically and retain the previous compatible catalog. Never silently remove individual options from an accepted catalog to obtain coverage.
- [ ] Test accepted compatible text updates, stale semantic hashes, unknown IDs, compatible reviewed aliases, incompatible app versions and invalid staged packages. Ensure valid pinned saved books remain independent of today's matching rules.
- [ ] Preserve saved `SeriesEpisode.pages` pins on unlock/library copy. Cover new series creation, all episodes, family-character removal recomposition and reopen after catalog update. Existing stored episodes lacking art remain legacy; no implicit retroactive prose or pin invention.
- [ ] State package-health behavior explicitly: publication proves authored coverage; valid installed bytes enable the guarantee. Corrupt/missing bytes cannot be repaired by semantic rules. Saved stories remain readable as text. A newly written unillustrated book must not be labeled as satisfying the new contract; decide recovery UX in its own product brief before changing app failure behavior.

## Task 7: Reader visibility and end-to-end contract slice

- [ ] Give the sole guaranteed illustration a layout policy that remains visible in scrollable narrative content at accessibility sizes and compact heights. Current optional spot sizing returns zero in these cases and cannot certify visible coverage. Preserve text readability and existing controls.
- [ ] Keep `opensAsTextOnly` handling for legacy unfinished jobs; new offline mapped stories remain `.completed`. Assert that the new art contract cannot be accidentally suppressed by reader mapping.
- [ ] Resolve saved asset pins, never rerun semantic selection when opening a book. Show no misleading alt description when bytes fail. Test real image decoding and accessibility image labels.
- [ ] Once this entire slice is ready, run the affected engine/app suites and the required single final visual matrix: light/dark, largest Dynamic Type, small/large phones, compact orientation, all reader papers. Capture evidence of at least one **visible narrative** illustration, not merely a cover or stored metadata.
- [ ] Publish a universal floor claim only with the completed coverage certificate and package/render verification. Treat three-younger/two-older density as a separate proposed extension requiring distinct-page proof and product approval.

## Plan self-review

This plan preserves unchanged prose and selection; supports all bands/modes/recall/family/occasion/series; separates inventory from proof; identifies compatibility, corruption and reader limits; and keeps the first deliverable independently useful. No sample-derived guarantee, universal decorative fallback, blanket subject-state assumptions, runtime image API or unapproved exact age counts are introduced.


## First-slice execution record (20 November)

- [x] Approved mixed-bank/no-prose/no-selection-change spec recorded.
- [x] `Tools/story_art_coverage_audit.py` and synthetic tests authored. Actual CLI is `--sources`/`--output` plus `--editorial-audit`/`--repo`; actual public functions are `inventory`, `check`, `verify_editorial`. Above proposed schema/functions are future normalization guidance, not current API promises.
- [x] Generic raw resource walker emitted2331 id/text objects; this broad all-JSON scope includes non-template source objects and is deliberately separate from content audit2043 authored variants/recall records. Neither is the runtime-selected corpus.
- [x] Content audit173sources/2043records with exact pointers/hashes;51 anchor-only editorial reviews,1992 unresolved,0 art bindings. Content source evidence was verified2043/2043.
- [x] Five focused tool tests passed; no application build/tests for this tool-only slice.
- [ ] Complete normalized anchor range/kind/context validation. Current validator checks source existence/path confinement/duplicate pointer/text hash, NOT semantic correctness or anchor ranges.
- [ ] Resolve production corpus replacement/reachability, then finish editorial source reviews and derive certified asset requirements.
- [ ] Implement pure engine evidence/matcher, exact artist-approved assets and reader/package integration only as separate slices after evidence is ready.

Actual commands:

```sh
python3 -m unittest discover -s Tools -p test_story_art_coverage_audit.py -v
python3 Tools/story_art_coverage_audit.py --sources StoryEngine/Sources/StoryEngine/Resources --repo . --editorial-audit docs/research/2026-11-20-art-anchor-audit.json --output docs/research/2026-11-20-authored-art-source-inventory.json
```

No guarantee was certified and no runtime binding was added in this slice. Old draft checklist details remain unchecked where more than the bounded source validator is required.


### Refresh after concurrent repository integration

At HEADa7685ca the source audit was refreshed to238documents/3016authored records; generic all-JSON walker3304records (broader scope).973source records were added; no prior text records were removed or changed at their exact pointer. Source context/file hashes changed for830old records;49of51old anchor reviews were invalidated conservatively,2retained,3014unresolved,0approved art bindings. All3016source pointers/IDs/text/file hashes verified with0errors. Six focused tool tests passed; existing12asset file digests also verified. No app/engine/prose/selector/visualKeys changes were made by this slice. Claude owns engine semantic fields and saved provenance; see `docs/research/2026-11-20-art-engine-app-handoff.md`. Earlier counts in this execution record are historical snapshots.
