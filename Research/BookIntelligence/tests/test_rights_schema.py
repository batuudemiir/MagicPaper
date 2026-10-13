"""The rules the validator enforces: rights, page turns, wording."""

from helpers import TestCase, analysed, ingest_fixture
from bookintel import analyze
from bookintel.schema import validate_claim, validate_source, validate_store


def claim(**overrides):
    base = {"claim_id": "c_test", "statement": "Refrains appear in 3 of 5 analysed books.", "kind": "OBSERVED",
            "layers": ["textual_mechanism"], "scope": {"age_band": "5-6", "language": "en"},
            "supporting_works": [], "counterexample_works": [], "sources": [], "status": "active"}
    base.update(overrides)
    return base


class Sources(TestCase):
    def test_public_domain_needs_jurisdiction_and_basis(self):
        errors = validate_source({"source_id": "s_x", "url": "https://x.org", "kind": "authorized_full_text",
                                  "tier": "A", "rights": "public_domain", "rights_detail": {"verified_on": "2026-10-08"}})
        self.assertTrue(any("jurisdiction" in e for e in errors))
        self.assertTrue(any("basis" in e for e in errors))

    def test_open_license_needs_license_and_attribution(self):
        errors = validate_source({"source_id": "s_x", "url": "https://x.org", "kind": "authorized_full_text",
                                  "tier": "A", "rights": "open_license", "rights_detail": {"verified_on": "x"}})
        self.assertEqual(len(errors), 2)

    def test_sources_never_store_quotations(self):
        errors = validate_source({"source_id": "s_x", "url": "https://x.org", "kind": "parent_review", "tier": "C",
                                  "rights": "commentary", "rights_detail": {}, "quotation": "..."})
        self.assertTrue(any("quotation" in e for e in errors))


class TextAndPageTurns(TestCase):
    def test_text_on_a_non_storable_source_is_rejected(self):
        wid = ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")["work_id"]
        analyze.scaffold(self.store, wid)
        source = self.store.get("source", "s_manual_fox_and_lantern")
        source["rights"] = "metadata_only"
        self.store.put("source", source)
        errors = validate_store(self.store)
        self.assertTrue(any("page text stored" in e for e in errors))

    def test_page_turn_on_reconstructed_boundaries_is_rejected(self):
        wid = ingest_fixture(self.store, "hen_and_seed.pages.txt", "Hen and the Seed", "Ada Test",
                             boundary="reconstructed")["work_id"]
        analyze.scaffold(self.store, wid)
        pages = self.store.get("pages", f"{wid}.v1")
        pages["pages"][0]["page_turn_mechanism"] = ["reveal"]
        pages["pages"][0]["page_turn_strength"] = 4
        self.store.put("pages", pages)
        self.assertTrue(any("page-turn fields need original page boundaries" in e for e in validate_store(self.store)))

    def test_unknown_vocabulary_is_rejected(self):
        wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        pages = self.store.get("pages", f"{wid}.v1")
        pages["pages"][0]["beat"] = "INCITING_INCIDENT"
        self.store.put("pages", pages)
        self.assertTrue(any("INCITING_INCIDENT" in e for e in validate_store(self.store)))

    def test_appeal_label_cannot_be_renamed(self):
        wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        analysis = self.store.get("analysis", f"{wid}.v1")
        analysis["child_appeal_heuristic"]["label"] = "Child preference score"
        self.store.put("analysis", analysis)
        self.assertTrue(any("Research heuristic" in e for e in validate_store(self.store)))


class ClaimWording(TestCase):
    def test_preference_claim_needs_child_evidence(self):
        self.assertTrue(validate_claim(claim(statement="Children love repetition.")))
        self.assertTrue(validate_claim(claim(statement="Çocuklar tekrarı sever.")))
        self.assertEqual(validate_claim(claim(statement="Children love repetition.",
                                              layers=["child_response", "textual_mechanism"])), [])

    def test_universal_wording_with_counterexamples(self):
        errors = validate_claim(claim(statement="Every book ends calmly.", supporting_works=["w_a"],
                                      counterexample_works=["w_b"]))
        self.assertTrue(any("universal" in e for e in errors))

    def test_a_work_cannot_both_support_and_contradict(self):
        self.assertTrue(validate_claim(claim(supporting_works=["w_a"], counterexample_works=["w_a"])))

    def test_rejected_claim_keeps_reason(self):
        self.assertTrue(validate_claim(claim(status="rejected")))
        self.assertEqual(validate_claim(claim(status="rejected", rejected_reason="5 counterexamples")), [])

    def test_textual_claims_only_cite_complete_analyses(self):
        wid = ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")["work_id"]
        self.store.put("claim", claim(supporting_works=[wid]))
        self.assertTrue(any("no complete analysis" in e for e in validate_store(self.store)))
