"""Cross-book comparison, research gaps, research runs."""

from helpers import TestCase, analysed, ingest_fixture
from bookintel import aggregate, confidence, gaps, report, runs
from bookintel.schema import validate_store


class Corpus(TestCase):
    def setUp(self):
        super().setUp()
        self.fox = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test",
                            curve=[1, 2, 2, 3, 5, 1], mechanisms=["question", "anticipation"], humor_pages={2})
        self.hen = analysed(self.store, "hen_and_seed.pages.txt", "Hen and the Seed", "Bo Test",
                            curve=[0, 1, 2, 4, 2], beats=[("SETUP", 1, 3), ("TURN", 4, 4), ("ENDING", 5, 5)])
        self.kirpi = analysed(self.store, "ay_ve_kirpi.pages.txt", "Ay ve Kirpi", "Deneme Yazar", language="tr")
        ingest_fixture(self.store, "hen_and_seed.pages.txt", "Unanalysed Book", "Cy Test", edition_id="e_unanalysed")

    def test_compare_counts_only_complete_analyses_in_scope(self):
        result = aggregate.compare(self.store, age_band="5-6", lang="en")
        self.assertEqual(result["n_works"], 2)
        self.assertEqual(sorted(result["works"]), sorted([self.fox, self.hen]))
        self.assertEqual(result["language"]["n_full_text_works"], 2)
        self.assertEqual(result["language"]["works_with_repeated_line"], 2)  # fox refrain + hen cumulative chain
        self.assertEqual(result["page_turns"]["n_eligible_works"], 2)
        self.assertEqual(result["page_turns"]["mechanisms"]["question"], 5 + 4)  # every page but the last: fox 6 (one spread), hen 5
        self.assertEqual(len(result["emotion"]["median_curve"]), 10)
        self.assertEqual(result["structure"]["beat_presence"]["ENDING"], 2)
        self.assertEqual(result["appeal_heuristic"]["label"], "Research heuristic — not validated")

    def test_language_separation(self):
        self.assertEqual(aggregate.compare(self.store, lang="tr")["works"], [self.kirpi])

    def test_markdown_states_sample_size(self):
        text = report.compare_markdown(aggregate.compare(self.store, age_band="5-6"))
        self.assertIn("3 complete analyses (small sample)", text)

    def test_gaps_name_turkish_and_page_turn_shortfalls(self):
        names = [g["gap"] for g in gaps.gaps(self.store)]
        self.assertIn("fully analysed books in 'tr'", names)
        self.assertTrue(any("story type 'bedtime'" in n for n in names))
        tr = next(g for g in gaps.gaps(self.store) if g["gap"] == "fully analysed books in 'tr'")
        self.assertTrue(tr["suggested_queries"])
        self.assertTrue(all("{" not in q and "  " not in q for g in gaps.gaps(self.store) for q in g["suggested_queries"]))

    def test_deep_dive_has_no_book_text(self):
        text = report.deep_dive(self.store, self.fox)
        self.assertIn("This is one book.", text)
        self.assertNotIn("Lanterns need friends", text)
        self.assertIn("Research heuristic — not validated", text)


class Runs(TestCase):
    def test_run_lifecycle_records_additions_and_confidence_changes(self):
        run = runs.start(self.store, "pilot", ["fixtures"])
        with self.assertRaises(RuntimeError):
            runs.start(self.store, "second", [])
        fox = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        self.store.put("claim", {"claim_id": "c_refrain", "statement": "A refrain appears in 1 of 1 analysed books.",
                                 "kind": "OBSERVED", "layers": ["textual_mechanism"], "scope": {"age_band": "5-6"},
                                 "supporting_works": [fox], "counterexample_works": [], "sources": [],
                                 "status": "active"})
        confidence.recompute_all(self.store)
        closed = runs.finish(self.store, "done")
        self.assertEqual(closed["works_added"], [fox])
        self.assertEqual(closed["analyses_completed"], [f"{fox}.v1"])
        self.assertEqual(closed["new_claims"], ["c_refrain"])
        self.assertEqual(closed["status"], "closed")
        self.assertEqual(validate_store(self.store), [])
        text = report.run_report(self.store, closed)
        for heading in ("## Corpus", "## Strong findings", "## Contradictions", "## MagicPaper recommendations",
                        "## Research gaps"):
            self.assertIn(heading, text)
        self.assertNotEqual(run["run_id"], "")
