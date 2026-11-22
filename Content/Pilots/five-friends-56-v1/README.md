# Five friends 5–6: isolated authoring corpus v1

Internal editorial source; **not a bundled engine package**. Thirty complete eight-page Turkish books implement the thirty approved pairs of nine structural plans. The child is the synthetic fixture Deniz. These texts are original pilot sources, not aliases of legacy lines. No legacy source, profile, setting or blueprint was changed.

## Reading and consuming

- `manifest.json`: exact allowed books, companion IDs, mode/setting relationship, file hashes and acceptance status.
- `structures.json`: nine reusable causal structures and page moves. IDs identify genuine authored structure records, **not loaded StoryBlueprint instances**.
- `books/*.json`: complete books with ordered pages, full source trace, temporal subject inventory and page-specific art needs. Pages 3/5/6 tailor each character's contribution; other page functions are shared within each structure.
- `sources.json`: actual full-page sources and orthographic sentence-segment records, each with SHA-256 over exact UTF-8 text. One full-page source constitutes the page's one provenance part; sentence records partition that source and are not extra composed parts. Quotes can remain within a segment; this is not linguistic sentence parsing.
- `authoring_source.py`: editable editorial master and deterministic serializer. Running it rewrites only this package's JSON files.
- `validate_authoring.py`: read-only offline integrity check, deliberately separate from runtime validation.

File digests hash exact bytes including formatting/newline. Text digests hash exact Unicode UTF-8 text without normalization. The manifest supplies the source payload digest; every page references its exact source plus file pointer. Book-level context repeats on each page so an art handoff cannot lose the setting, cast or unsupported request context.

`semantics.subjects` includes present child and companion even on pages using pronouns. Memory and intention entries are separate temporal mentions of the same subject; a remembered child is not a second visible child. Discovery IDs are **pilot semantic groups**, not existing runtime object records. The prop description enumerates their contents; these groups need catalog/schema design before a runtime adapter. Sound itself is not a visible object. Negative statements are constraints, not action evidence. Full text always accompanies the action summary; illustrations cannot be approved from a single verb.

## Important limits

Author reviewed means the author inspected the intended scene meaning. It does not mean independent editorial acceptance, exhaustive production semantic schema compliance, artwork acceptance or runtime binding approval. `artHandoff.actionNeed` is sometimes the entire tailored page to preserve constraints and temporal context. It is not a prompt approved for generation. No art is pinned.

`orderedBeatIDs`, page moves and `stateBefore/After` are a new **editorial vocabulary**, not `StoryBeat` values or proven engine precondition/produce-state transitions. In particular U3 must receive a real compiler/state mapping; do not claim false care needs or relax validators to force it through. A2 owl contributes an observation; fox/bear stabilize only the explicit edge. A3 owl short flight is explicit on p5; it never replaces the child's personal recollection.

Family, guest, recall, occasion, series, topics and personalized name/inflection expansion are unsupported. Reject those contexts as `unsupported-in-pilot`; never silently omit them. Simit remains the same visiting city cat. The new room is a pilot-only setting, not a rename of any historic room. Sleep stories end in that same room; child closes eyes, but neither closing eyes nor awake resting asserts actual sleep.

No runtime sampling, engine age validation, safety filtering, visual coverage measurement, 1,500-seed trial or independent review has been completed. The corpus is consumable for editorial/art analysis and future explicit adapter work. It cannot currently be selected by the app. Production policy stays unchanged.
