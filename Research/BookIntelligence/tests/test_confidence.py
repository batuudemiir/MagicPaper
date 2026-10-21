"""Confidence is a function of evidence, and only of evidence."""

from helpers import TestCase
from bookintel import confidence


def make_works(store, n, tier="A", prefix="w"):
    ids = []
    store.put("source", {"source_id": f"s_{prefix}", "url": "https://x.org", "kind": "authorized_full_text",
                         "tier": tier, "rights": "open_license",
                         "rights_detail": {"license": "CC BY", "attribution": "x", "verified_on": "2026-10-08"}})
    for i in range(n):
        wid = f"{prefix}_{i}"
        store.put("edition", {"edition_id": f"e_{prefix}_{i}", "work_id": wid, "source_id": f"s_{prefix}",
                              "language": "en", "format": "web", "page_boundary_source": "original_scan"})
        store.put("work", {"work_id": wid, "title": wid, "editions": [f"e_{prefix}_{i}"]})
        ids.append(wid)
    return ids


def claim(support, counter=(), **kw):
    base = {"claim_id": "c_x", "statement": "s", "kind": "OBSERVED", "layers": ["textual_mechanism"],
            "supporting_works": list(support), "counterexample_works": list(counter), "sources": [],
            "counterexamples_reviewed": True, "status": "active"}
    base.update(kw)
    return base


class Scope(TestCase):
    def test_sample_scope_boundaries(self):
        self.assertEqual([confidence.sample_scope(n) for n in (1, 2, 9, 10, 49, 50)],
                         ["ONE_BOOK", "SMALL_SAMPLE", "SMALL_SAMPLE", "CORPUS", "CORPUS", "LARGE_CORPUS"])


class Levels(TestCase):
    def level(self, c):
        return confidence.compute(c, confidence.Context(self.store))

    def test_one_book_is_a_hypothesis(self):
        works = make_works(self.store, 1)
        self.assertEqual(self.level(claim(works))["confidence"], "HYPOTHESIS")

    def test_small_sample_is_low(self):
        works = make_works(self.store, 5)
        self.assertEqual(self.level(claim(works))["confidence"], "LOW")

    def test_corpus_with_one_layer_is_medium(self):
        works = make_works(self.store, 12)
        result = self.level(claim(works[:9], works[9:]))
        self.assertEqual((result["confidence"], result["support_ratio"], result["wording"]),
                         ("MEDIUM", 0.75, "common, not universal"))

    def test_high_needs_two_layers_ratio_and_review(self):
        works = make_works(self.store, 12)
        two_layers = ["textual_mechanism", "adult_interpretation"]
        self.assertEqual(self.level(claim(works[:10], works[10:], layers=two_layers))["confidence"], "HIGH")
        self.assertEqual(self.level(claim(works[:10], works[10:], layers=two_layers,
                                          counterexamples_reviewed=False))["confidence"], "MEDIUM")
        self.assertEqual(self.level(claim(works[:7], works[7:], layers=two_layers))["confidence"], "LOW")

    def test_inferred_claims_stop_at_medium(self):
        works = make_works(self.store, 12)
        c = claim(works, layers=["textual_mechanism", "adult_interpretation"], kind="INFERRED")
        self.assertEqual(self.level(c)["confidence"], "MEDIUM")

    def test_weak_sources_only_is_a_hypothesis(self):
        works = make_works(self.store, 20, tier="C")
        self.assertEqual(self.level(claim(works))["confidence"], "HYPOTHESIS")

    def test_editions_do_not_add_support(self):
        works = make_works(self.store, 2)
        work = self.store.get("work", works[0])
        self.store.put("edition", {"edition_id": "e_w_0_reprint", "work_id": works[0], "source_id": "s_w",
                                   "language": "en", "format": "print", "page_boundary_source": "original_scan"})
        work["editions"].append("e_w_0_reprint")
        self.store.put("work", work)
        result = self.level(claim([works[0], "e_w_0_reprint", "e_w_0"]))
        self.assertEqual((result["support"], result["n_examined"]), (1, 1))

    def test_recompute_records_history_and_skips_rejected(self):
        works = make_works(self.store, 3)
        self.store.put("claim", claim(works))
        self.store.put("claim", {**claim(works), "claim_id": "c_rejected", "status": "rejected", "rejected_reason": "r"})
        changes = confidence.recompute_all(self.store)
        self.assertEqual(changes, [{"claim_id": "c_x", "from": None, "to": "LOW"}])
        self.assertIsNone(self.store.get("claim", "c_rejected").get("computed"))
        self.assertEqual(confidence.recompute_all(self.store), [])
