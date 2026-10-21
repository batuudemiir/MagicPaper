"""Deterministic confidence for claims. The analyst never sets it.

Rules (RESEARCH_METHOD.md §Confidence, starting defaults to revisit at ~20 works):

  sample scope   ONE_BOOK 1 · SMALL_SAMPLE 2-9 · CORPUS 10-49 · LARGE_CORPUS 50+
                 (counted on WORKS: an edition or translation never adds support)

  HYPOTHESIS  kind is HYPOTHESIS, or one book, or no tier A/B source behind it
  LOW         small sample, or support ratio < 0.6
  MEDIUM      corpus scope, ratio >= 0.6, a tier A/B source
  HIGH        corpus scope, ratio >= 0.75, >= 2 evidence layers, kind OBSERVED,
              counterexamples reviewed, a tier A/B source
  INFERRED claims stop at MEDIUM.
  A claim resting on a judgment field the agent reads inconsistently (blind re-reads,
  learning.reliability) stops at LOW.
"""

from __future__ import annotations

TIER_ORDER = {"A": 0, "B": 1, "C": 2, "D": 3}
LEVELS = ["HYPOTHESIS", "LOW", "MEDIUM", "HIGH"]


def sample_scope(n: int) -> str:
    if n <= 1:
        return "ONE_BOOK"
    if n < 10:
        return "SMALL_SAMPLE"
    if n < 50:
        return "CORPUS"
    return "LARGE_CORPUS"


class Context:
    """Lookups confidence needs, built once per store."""

    def __init__(self, store):
        self.works = {w["work_id"]: w for w in store.all("work")}
        self.editions = {e["edition_id"]: e for e in store.all("edition")}
        self.sources = {s["source_id"]: s for s in store.all("source")}
        from .learning import unreliable_fields
        self.unreliable = unreliable_fields(store)

    def work_of(self, identifier: str) -> str:
        if identifier in self.editions:
            return self.editions[identifier]["work_id"]
        return identifier

    def work_tiers(self, work_id: str) -> list[str]:
        tiers = []
        for edition_id in self.works.get(work_id, {}).get("editions", []):
            edition = self.editions.get(edition_id)
            source = self.sources.get(edition.get("source_id")) if edition else None
            if source:
                tiers.append(source["tier"])
        return tiers


def compute(claim: dict, ctx: Context) -> dict:
    support = sorted({ctx.work_of(w) for w in claim.get("supporting_works", [])})
    counter = sorted({ctx.work_of(w) for w in claim.get("counterexample_works", [])} - set(support))
    n = len(set(support) | set(counter))
    ratio = round(len(support) / n, 3) if n else 0.0

    tiers = [ctx.sources[s]["tier"] for s in claim.get("sources", []) if s in ctx.sources]
    if "textual_mechanism" in claim.get("layers", []):
        for work_id in support:
            tiers += ctx.work_tiers(work_id)
    best = min(tiers, key=lambda t: TIER_ORDER[t]) if tiers else None
    strong_source = best in ("A", "B")
    scope = sample_scope(n)
    kind = claim.get("kind")
    layers = set(claim.get("layers", []))

    if kind == "HYPOTHESIS" or n <= 1 or not strong_source:
        level = "HYPOTHESIS"
    elif scope == "SMALL_SAMPLE" or ratio < 0.6:
        level = "LOW"
    elif (ratio >= 0.75 and len(layers) >= 2 and kind == "OBSERVED"
          and claim.get("counterexamples_reviewed") and strong_source):
        level = "HIGH"
    else:
        level = "MEDIUM"
    if kind == "INFERRED" and level == "HIGH":
        level = "MEDIUM"
    # Children's reading is the strongest evidence we get: an experiment that went against the
    # claim caps it, whatever the books say.
    contradicted = [e for e in claim.get("experiments", []) if e.get("observed") == "worse"]
    if contradicted and LEVELS.index(level) > LEVELS.index("LOW"):
        level = "LOW"
    shaky = sorted(set(claim.get("judgment_fields", [])) & getattr(ctx, "unreliable", set()))
    if shaky and LEVELS.index(level) > LEVELS.index("LOW"):
        level = "LOW"

    return {
        "n_examined": n,
        "support": len(support),
        "counter": len(counter),
        "support_ratio": ratio,
        "sample_scope": scope,
        "best_source_tier": best,
        "confidence": level,
        "wording": ("contradicted by an experiment with children" if contradicted else
                    "common, not universal" if counter else ("single book" if n == 1 else None)),
        "experiments": len(claim.get("experiments", [])),
        **({"unreliable_fields": shaky} if shaky else {}),
    }


def recompute_all(store) -> list[dict]:
    """Recompute `computed` on every active claim; returns the changes."""
    ctx = Context(store)
    changes = []
    for claim in store.all("claim"):
        if claim.get("status") != "active":
            if claim.get("computed"):
                claim["computed"] = None
                store.put("claim", claim)
            continue
        before = (claim.get("computed") or {}).get("confidence")
        claim["computed"] = compute(claim, ctx)
        after = claim["computed"]["confidence"]
        if before != after:
            history = claim.setdefault("confidence_history", [])
            history.append({"from": before, "to": after})
            changes.append({"claim_id": claim["claim_id"], "from": before, "to": after})
        store.put("claim", claim)
    return changes
