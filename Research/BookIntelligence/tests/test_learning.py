"""Self-improvement: questions from other agents, blind re-reads, method rules."""

import os
from pathlib import Path

from helpers import TestCase, analysed
from bookintel import confidence, cycle, exchange, learning
from bookintel.schema import validate_store


class Learning(TestCase):
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

    # -- questions -----------------------------------------------------------------------

    def test_another_agent_asks_and_the_answer_cites_evidence(self):
        r = learning.ask(self.store, "reader", "Do picture books end on a quiet page?",
                         "The reader's last-page layout depends on it", target="reader.layout", age_band="5-6")
        self.assertEqual(r["status"], "open")
        self.assertEqual([x["request_id"] for x in learning.open_requests(self.store)], [r["request_id"]])
        learning.take(self.store, r["request_id"])
        with self.assertRaises(learning.LearningError):
            learning.answer(self.store, r["request_id"], "Yes", claims=["c_missing"], works=[])
        done = learning.answer(self.store, r["request_id"], "1 of 1 analysed books does.",
                               claims=["c_refrain_test"], works=[self.wid])
        self.assertEqual(done["status"], "answered")
        self.assertEqual(done["answer"]["evidence_strength"],
                         self.store.get("claim", "c_refrain_test")["computed"]["confidence"])
        self.assertEqual(learning.open_requests(self.store), [])

    def test_the_research_agent_cannot_ask_itself_and_a_question_needs_a_reason(self):
        with self.assertRaises(learning.LearningError):
            learning.ask(self.store, "book-research", "Anything?", "because")
        with self.assertRaises(learning.LearningError):
            learning.ask(self.store, "story-engine", "Anything?", "")

    def test_same_question_twice_gets_its_own_id(self):
        a = learning.ask(self.store, "story-engine", "Where is the peak?", "beat order")
        b = learning.ask(self.store, "story-engine", "Where is the peak?", "beat order")
        self.assertNotEqual(a["request_id"], b["request_id"])

    # -- blind re-reads ------------------------------------------------------------------

    def reread(self, change=None):
        path = learning.start(self.store, self.wid)
        record = self.store.ws.data / "rechecks" / path.name
        import json
        data = json.loads(record.read_text(encoding="utf-8"))
        original = {p["page"]: p for p in self.store.get("pages", f"{self.wid}.v1")["pages"]}
        for page in data["pages"]:
            first = original[page["page"]]
            for field in ("beat", "emotion", "emotion_intensity", "label", "change", "humor",
                          "page_turn_mechanism"):
                page[field] = first.get(field)
            if change:
                change(page)
        record.write_text(json.dumps(data), encoding="utf-8")
        return learning.score(self.store, self.wid)

    def test_a_reread_starts_blind_and_scores_against_the_first_reading(self):
        path = learning.start(self.store, self.wid)
        import json
        blind = json.loads(path.read_text(encoding="utf-8"))
        self.assertTrue(all(p["beat"] is None and p["emotion"] is None for p in blind["pages"]))
        with self.assertRaises(learning.LearningError):
            learning.start(self.store, self.wid)  # one open re-read per book
        with self.assertRaises(learning.LearningError):
            learning.score(self.store, self.wid)  # judgments still empty
        path.unlink()
        result = self.reread(lambda p: p.update(emotion="sadness"))
        self.assertEqual(result["score"]["beat"]["rate"], 1.0)
        self.assertEqual(result["score"]["emotion"]["rate"], 0.0)
        with self.assertRaises(learning.LearningError):
            learning.score(self.store, self.wid)  # scored is final

    def test_intensity_agrees_within_one_step(self):
        result = self.reread(lambda p: p.update(emotion_intensity=(p["emotion_intensity"] or 0) + 1))
        self.assertEqual(result["score"]["emotion_intensity"]["rate"], 1.0)

    def test_an_unreliable_field_caps_claims_that_rest_on_it(self):
        old = learning.MIN_PAGES
        learning.MIN_PAGES = 1
        try:
            claim = self.store.get("claim", "c_refrain_test")
            claim.update(judgment_fields=["emotion"], kind="OBSERVED")
            self.store.put("claim", claim)
            self.reread(lambda p: p.update(emotion="sadness"))
            self.assertEqual(learning.reliability(self.store)["emotion"]["state"], "unreliable")
            ctx = confidence.Context(self.store)
            ctx.unreliable = {"emotion"}
            claim["supporting_works"] = [self.wid, "w_other"]
            computed = confidence.compute(claim, ctx)
            self.assertIn(computed["confidence"], ("HYPOTHESIS", "LOW"))
            self.assertEqual(computed.get("unreliable_fields"), ["emotion"])
        finally:
            learning.MIN_PAGES = old

    def test_pick_prefers_the_book_reread_least(self):
        self.assertEqual(learning.pick(self.store), self.wid)

    def test_claims_name_only_measured_judgment_fields(self):
        claim = self.store.get("claim", "c_refrain_test")
        claim["judgment_fields"] = ["mood"]
        self.store.put("claim", claim)
        self.assertTrue(any("judgment_fields" in e for e in validate_store(self.store)))

    # -- method rules --------------------------------------------------------------------

    def test_a_caught_mistake_becomes_a_rule_validate_enforces(self):
        pid = exchange.open_proposal(self.store, "c_refrain_test")
        with self.assertRaises(learning.LearningError):
            learning.add_rule(self.store, kind="forbid", pattern="refrain", text="x", evidence=[])
        rule = learning.add_rule(self.store, kind="forbid", pattern=r"\ballow refrains\b",
                                 text="Say what kind of repetition, not just 'refrains'.",
                                 evidence=[f"{pid}/book-research-1"], scope=["claim"])
        problems = learning.check(self.store)
        self.assertEqual(len(problems), 1)
        self.assertIn(rule["rule_id"], problems[0])
        learning.retire_rule(self.store, rule["rule_id"], "too broad")
        self.assertEqual(learning.check(self.store), [])
        self.assertEqual(learning.method(self.store)["version"], 2)

    def test_require_when_and_turns_only_after_the_rule(self):
        pid = exchange.open_proposal(self.store, "c_refrain_test")
        exchange.post(self.store, pid, "book-research", "answer", "Peak intensity 4 in this book.")
        os.environ["BOOKINTEL_NOW"] = "2026-10-09T09:00:00Z"
        try:
            learning.add_rule(self.store, kind="require_when", when=r"intensity\s*\d", pattern=r"0-3|engine scale",
                              text="State intensity on the engine's 0-3 scale.", evidence=[pid], scope=["turn"])
            self.assertEqual(learning.check(self.store), [])  # the old turn predates the rule
            exchange.post(self.store, pid, "book-research", "answer", "Peak intensity 4 again.")
            self.assertEqual(len(learning.check(self.store)), 1)
            exchange.post(self.store, pid, "book-research", "answer", "Peak intensity 3 on the engine scale.")
            self.assertEqual(len(learning.check(self.store)), 1)
        finally:
            os.environ["BOOKINTEL_NOW"] = "2026-10-08T09:00:00Z"

    def test_a_bad_pattern_is_refused(self):
        with self.assertRaises(learning.LearningError):
            learning.add_rule(self.store, kind="forbid", pattern="(", text="x", evidence=["c_refrain_test"])

    # -- the weekly page -----------------------------------------------------------------

    def test_weekly_page_reports_questions_and_self_improvement(self):
        learning.ask(self.store, "parent-ux", "How long are bedtime books?", "length picker copy")
        path = cycle.run(self.store)["path"]
        page = Path(path).read_text(encoding="utf-8")
        self.assertIn("## Ajanlardan gelen sorular", page)
        self.assertIn("How long are bedtime books?", page)
        self.assertIn("## Ajan kendini nasıl geliştirdi", page)
        self.assertIn(f"Sıradaki kör yeniden okuma: `{self.wid}`", page)


class OldRuns(Learning):
    def test_scoring_attaches_to_a_run_opened_before_rechecks_existed(self):
        from bookintel import runs
        run = runs.start(self.store, "old run", [])
        run.pop("rechecks_scored", None)
        self.store.put("run", run)
        self.reread()
        self.assertEqual(runs.open_run(self.store)["rechecks_scored"], [f"{self.wid}.1"])
