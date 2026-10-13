"""The idea-exchange protocol: ownership, required voices, the safety gate, the human gate."""

from helpers import TestCase, analysed
from bookintel import confidence, exchange


class Exchange(TestCase):
    def setUp(self):
        super().setUp()
        self.wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        self.store.put("claim", {
            "claim_id": "c_refrain_test", "statement": "A refrain appears in 1 of 1 analysed books.",
            "kind": "OBSERVED", "layers": ["textual_mechanism"], "scope": {"language": "en"},
            "supporting_works": [self.wid], "counterexample_works": [], "sources": [], "status": "active",
            "magicpaper": {"target": "writing_guidance", "current": "none", "suggested": "allow refrains",
                           "review_status": "proposed"}})
        confidence.recompute_all(self.store)
        self.pid = exchange.open_proposal(self.store, "c_refrain_test")

    def hear_everyone(self):
        exchange.post(self.store, self.pid, "story-engine", "concern", "The validator flags repeated phrases.",
                      evidence=["StoryEngine/Tools/validate_beat_corpus.py"])
        exchange.post(self.store, self.pid, "privacy-safety", "support", "No child data involved.")

    def test_open_is_idempotent_and_posts_the_proposal(self):
        self.assertEqual(exchange.open_proposal(self.store, "c_refrain_test"), "p_refrain_test")
        record = exchange.load(self.store, self.pid)
        self.assertEqual([t["stance"] for t in record["turns"]], ["proposal"])
        self.assertEqual(record["thread"]["status"], "open")

    def test_parts_belong_to_their_owners(self):
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_safety(self.store, self.pid, "book-research", verdict="pass", notes="")
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_impact(self.store, self.pid, "content-library", fields=[], files=[], tests=[],
                                owner="x", cost="S", reversible=True, notes="")
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, self.pid, "story-engine", action="park", rationale="")

    def test_prototypes_never_go_to_production_paths(self):
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_prototype(self.store, self.pid, "content-library",
                                   path="StoryEngine/Sources/StoryEngine/Resources/x.json", description="")

    def test_recommendation_needs_engine_and_safety_voices(self):
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, self.pid, "book-research", action="adopt_guidance", rationale="r")
        self.hear_everyone()
        exchange.recommend(self.store, self.pid, "book-research", action="adopt_guidance", rationale="r")
        self.assertEqual(exchange.load(self.store, self.pid)["thread"]["status"], "ready_for_decision")

    def test_experiment_needs_impact_and_safety_pass(self):
        self.hear_everyone()
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, self.pid, "book-research", action="experiment", rationale="r")
        exchange.set_impact(self.store, self.pid, "story-engine", fields=["validator.repetition"], files=[],
                            tests=[], owner="story-engine", cost="S", reversible=True, notes="")
        exchange.set_safety(self.store, self.pid, "privacy-safety", verdict="concerns", notes="check wording")
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, self.pid, "book-research", action="experiment", rationale="r")
        exchange.set_safety(self.store, self.pid, "privacy-safety", verdict="pass", notes="ok")
        exchange.recommend(self.store, self.pid, "book-research", action="experiment", rationale="r")

    def test_safety_block_limits_the_recommendation(self):
        self.hear_everyone()
        exchange.set_safety(self.store, self.pid, "privacy-safety", verdict="block", notes="unsafe")
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, self.pid, "book-research", action="adopt_guidance", rationale="r")
        exchange.recommend(self.store, self.pid, "book-research", action="park", rationale="blocked")

    def test_human_gate_updates_claim_and_freezes_thread(self):
        self.hear_everyone()
        with self.assertRaises(exchange.ExchangeError):
            exchange.decide(self.store, self.pid, verdict="approved", note="too early")
        exchange.recommend(self.store, self.pid, "book-research", action="adopt_guidance", rationale="r")
        exchange.decide(self.store, self.pid, verdict="approved", note="go")
        self.assertEqual(self.store.get("claim", "c_refrain_test")["magicpaper"]["review_status"], "accepted")
        with self.assertRaises(exchange.ExchangeError):
            exchange.post(self.store, self.pid, "story-engine", "concern", "late")
        lessons = exchange.lessons(self.store)
        self.assertEqual(lessons["by_target"]["writing_guidance"]["approved"], 1)
        self.assertTrue(any(n.get("objection_by") == "story-engine" for n in lessons["notes"]))

    def test_bad_evidence_is_refused_at_post_and_project_files_are_accepted(self):
        with self.assertRaises(exchange.ExchangeError):
            exchange.post(self.store, self.pid, "content-library", "support", "x", evidence=["no/such/file.swift"])
        exchange.post(self.store, self.pid, "privacy-safety", "support", "x", evidence=["CLAUDE.md"])

    def test_validation_catches_tampering_and_bad_evidence(self):
        self.hear_everyone()
        root = self.ws.data / "exchange" / self.pid
        (root / "turns" / "content-library-001.json").write_text(
            '{"agent": "content-library", "n": 1, "id": "content-library-1", "stance": "support", "text": "x",'
            ' "evidence": ["no/such/file.swift"], "reply_to": null, "at": "2026-10-08T09:00:00Z"}')
        (root / "decision.json").write_text('{"verdict": "approved", "by": "story-engine"}')
        errors = exchange.validate(self.store)
        self.assertTrue(any("human gate" in e for e in errors))
        self.assertTrue(any("no/such/file.swift" in e for e in errors))

    def test_parallel_agents_do_not_collide(self):
        self.hear_everyone()
        exchange.post(self.store, self.pid, "story-engine", "answer", "second")
        ids = [t["id"] for t in exchange.load(self.store, self.pid)["turns"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn("story-engine-2", ids)

    def test_digest_puts_decisions_first(self):
        self.hear_everyone()
        exchange.recommend(self.store, self.pid, "book-research", action="adopt_guidance", rationale="worth it")
        paths = exchange.write_docs(self.store)
        digest = (self.ws.docs / "EXCHANGE_DIGEST.md").read_text()
        self.assertIn("Waiting for your decision (1)", digest)
        self.assertIn("worth it", digest)
        self.assertTrue(any(p.name == "p_refrain_test.md" for p in paths))
