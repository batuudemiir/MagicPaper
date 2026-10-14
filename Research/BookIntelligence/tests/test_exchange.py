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


class UxTargetsAndHandoffs(TestCase):
    """UX proposals are argued with their own owner; approval turns into a work package."""

    def setUp(self):
        super().setUp()
        self.wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")

    def claim(self, cid, target):
        self.store.put("claim", {
            "claim_id": cid, "statement": "A quiet page precedes the ending in 1 of 1 analysed books.",
            "kind": "OBSERVED", "layers": ["textual_mechanism"], "scope": {"language": "en"},
            "supporting_works": [self.wid], "counterexample_works": [], "sources": [], "status": "active",
            "magicpaper": {"target": target, "current": "none", "suggested": "try it", "review_status": "proposed"}})
        confidence.recompute_all(self.store)
        return exchange.open_proposal(self.store, cid)

    def approve(self, pid, owner, action="adopt_guidance"):
        exchange.post(self.store, pid, owner, "support", "fits")
        exchange.post(self.store, pid, "privacy-safety", "support", "no child data")
        exchange.recommend(self.store, pid, "book-research", action=action, rationale="r")
        exchange.decide(self.store, pid, verdict="approved", note="go")

    def test_ux_target_needs_its_owner_not_story_engine(self):
        pid = self.claim("c_quiet_page", "reader.page_turn")
        exchange.post(self.store, pid, "story-engine", "support", "fine")
        exchange.post(self.store, pid, "privacy-safety", "support", "fine")
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, pid, "book-research", action="adopt_guidance", rationale="r")
        exchange.post(self.store, pid, "reader", "support", "a quiet page before the end fits the reader")
        exchange.recommend(self.store, pid, "book-research", action="adopt_guidance", rationale="r")

    def test_impact_on_a_ux_target_is_written_by_its_owner(self):
        pid = self.claim("c_parent_flow", "ux.parent_flow")
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_impact(self.store, pid, "story-engine", fields=[], files=[], tests=[], owner="x",
                                cost="S", reversible=True, notes="")
        exchange.set_impact(self.store, pid, "parent-ux", fields=["onboarding"], files=[], tests=[],
                            owner="parent-ux", cost="S", reversible=True, notes="")
        self.assertEqual(exchange.validate(self.store), [])

    def test_ux_targets_cannot_be_experiments(self):
        pid = self.claim("c_layout", "reader.layout")
        exchange.post(self.store, pid, "reader", "support", "ok")
        exchange.post(self.store, pid, "privacy-safety", "support", "ok")
        exchange.set_impact(self.store, pid, "reader", fields=[], files=[], tests=[], owner="reader", cost="S",
                            reversible=True, notes="")
        exchange.set_safety(self.store, pid, "privacy-safety", verdict="pass", notes="ok")
        with self.assertRaises(exchange.ExchangeError):
            exchange.recommend(self.store, pid, "book-research", action="experiment", rationale="r")

    def test_approval_creates_a_work_package_for_the_owner(self):
        pid = self.claim("c_quiet_page", "reader.page_turn")
        self.approve(pid, "reader")
        handoff = exchange.load(self.store, pid) and exchange.all_handoffs(self.store)[0]
        self.assertEqual((handoff["owner"], handoff["status"]), ("reader", "waiting"))
        self.assertTrue(any("design law" in d for d in handoff["done_when"]))
        exchange.write_docs(self.store)
        self.assertTrue((self.ws.docs / "handoffs" / f"{pid}.md").exists())
        self.assertIn("reader", (self.ws.docs / "HANDOFFS.md").read_text())

    def test_guidance_goes_to_content_library_and_experiments_are_led_by_story_engine(self):
        guidance = self.claim("c_guide", "writing_guidance")
        self.approve(guidance, "story-engine")
        experiment = self.claim("c_exp", "validator.repetition")
        exchange.post(self.store, experiment, "story-engine", "support", "ok")
        exchange.post(self.store, experiment, "privacy-safety", "support", "ok")
        exchange.set_impact(self.store, experiment, "story-engine", fields=[], files=[], tests=[],
                            owner="story-engine", cost="M", reversible=True, notes="")
        exchange.set_safety(self.store, experiment, "privacy-safety", verdict="pass", notes="ok")
        exchange.recommend(self.store, experiment, "book-research", action="experiment", rationale="r")
        exchange.decide(self.store, experiment, verdict="approved", note="go")
        owners = {h["proposal_id"]: (h["owner"], h["with"]) for h in exchange.all_handoffs(self.store)}
        self.assertEqual(owners[guidance][0], "content-library")
        self.assertEqual(owners[experiment], ("story-engine", ["content-library"]))

    def test_rejected_or_parked_proposals_get_no_package(self):
        pid = self.claim("c_no", "ux.child_area")
        exchange.post(self.store, pid, "ui-agent", "object", "not for the child area")
        exchange.post(self.store, pid, "privacy-safety", "support", "ok")
        exchange.recommend(self.store, pid, "book-research", action="decline", rationale="r")
        exchange.decide(self.store, pid, verdict="rejected", note="no")
        self.assertEqual(exchange.all_handoffs(self.store), [])

    def test_only_the_owner_or_the_human_moves_a_package(self):
        pid = self.claim("c_quiet_page", "reader.page_turn")
        self.approve(pid, "reader")
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_handoff_status(self.store, pid, "story-engine", "in_progress", "")
        with self.assertRaises(exchange.ExchangeError):
            exchange.set_handoff_status(self.store, pid, "reader", "done", "")
        exchange.set_handoff_status(self.store, pid, "reader", "in_progress", "")
        h = exchange.set_handoff_status(self.store, pid, "reader", "done", "reader-quiet-page@abc1234")
        self.assertEqual([x["status"] for x in h["history"]], ["waiting", "in_progress", "done"])

    def test_validation_catches_a_package_without_approval(self):
        pid = self.claim("c_quiet_page", "reader.page_turn")
        (self.ws.data / "exchange" / pid / "handoff.json").write_text(
            '{"proposal_id": "%s", "owner": "reader", "status": "waiting", "history": []}' % pid)
        self.assertTrue(any("without an approved decision" in e for e in exchange.validate(self.store)))
