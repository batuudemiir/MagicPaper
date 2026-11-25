# Five friends 5–6: event expansion draft

This directory is an isolated authored expansion: 60 new books / 480 pages, two new event variants for each of the existing 30 structure/companion pairs. Together with the unchanged legacy 30-book corpus, the target is 90 books / 720 pages.

`authoring_source.py` is the explicit manuscript and reproducible serializer. Run `python3 Content/Pilots/five-friends-56-expansion-v1/authoring_source.py` from the repository root to serialize this directory only. It reads original contracts/context from `../five-friends-56-v1/`; it does not write that corpus or runtime files. Existing `_v2` legacy source revisions remain unrelated to new `event02` / `event03` IDs.

Files:

- `books/`: complete new eight-page books, `baseBookID` and `variantID` identify the relationship without aliasing source text.
- `sources.json`: new full-page and sentence-segment sources, exact UTF-8 SHA, context, local pointer indices.
- `manifest.json`: file-byte digests, source payload digest, counts and draft acceptance flags. `structuresFile` refers explicitly to the unchanged existing nine structure contracts.
- `causal-evidence.json`: exact positive first-sentence spans and same-page named attribution; one source statement per page. These are authored page-context evidence, not independently approved atomic action annotations.

Event differences are defined in `docs/research/five-friends-p56-runtime/C2_VARIANT_DESIGN.md`: stop a sustained sound vs avoid restarting it; flatten a surface vs clear adjacent space; select a still moment vs a release moment; compare temporal contact vs two candidates; external occlusion vs self-curl; merging drops vs moving drop; light-transition pause vs ground-color threshold; rotate a part vs select sequence; remembered spatial relation vs remembered action order.

Companion contributions are authored separately. Yıldız observes in A2; it does not hold pieces with invented hands/wings. The child compares and places the pieces. Simit is a city visitor today. All books preserve species contracts and child resolution ownership. U3 remains calm, closes without hooks, and marks daytime objects as remembered.

This is a manuscript delivery, not a runtime package. `productionEnabled`, runtime compatibility, independent editorial approval, art approval, release approval, and engine mapping approval remain false. No safety or topic suitability is asserted. Topic support needs current catalog evidence; safety tagging needs a separate review of each actual narrative against current policy keys.

Serialization was executed. Tests, corpus validation, runtime composition, N1500 sampling and independent editorial review were not run. The word/sentence budgets (18–38 words per page, maximum 14 words per sentence) remain acceptance requirements for the planned editorial/validation pass; serialization is not evidence that they passed. No art is authorized.
