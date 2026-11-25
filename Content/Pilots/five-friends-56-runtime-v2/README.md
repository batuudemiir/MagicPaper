# Five friends 5–6 runtime v2

Explicit internal offline derivative. Run `python3 build_runtime_package.py` to serialize the immutable 30-book authoring corpus and the separate 60-book expansion corpus. The serializer exports source bytes; it does not validate or approve the authoring material.

Payload schema 2 embeds independent source JSON and causal-evidence JSON snapshots with their SHA-256 digests, original book JSON and digests, and explicit corpus/event/base-book lineage. References continue to use identity schema 1 and behavior `offline-p56-v1`; the source format changes without introducing a new interpretation of typed states.

The old runtime v1 directory and exact payload bytes remain the historical replay source. V2 pointers include corpus identity. All 30 approved structure/companion pairs contain event01, event02 and event03, yielding six authored books per mode/companion cell and 90 books total. These are event variants of nine structures, not 90 mechanisms.

The runtime loader validates provenance, coverage and the existing typed causal rules. Full-book Turkish-name fixtures are distinct from balanced N1500 sampling: the latter uses exactly seeds 0–99 for each of 15 cells without retries. Internal `composeFixture` permits every authored book to be rendered directly in tests without changing the public selection API.

Production and artwork approval remain false. Authored semantics and source-span evidence do not grant independent atomic-action or artwork approval. ContentSafety is enforced only through the complete, independently reviewed exact-source annotations embedded in this payload. Missing/uncertain/noncanonical/hash-mismatched review fails closed; a v1 package without that review remains unsupported for supplied policies. Calm forbids unease/hesitation and avoided=nil excludes every topic in this finite reviewed source vocabulary. Explicit unknown avoided topics are unsupported, never dropped. Topic selection and family casting remain unsupported. This is not safety approval of future illustrations, newly edited text or unreviewed topic definitions.
