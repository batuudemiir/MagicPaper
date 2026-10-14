"""The returning half of the loop: experiments, usage import, evaluation, calibration, the weekly cycle."""

import json

from helpers import TestCase, analysed
from bookintel import confidence, cycle, exchange, experiments

PACKAGE_BLUEPRINT = {"genre": "adventure", "theme": "t", "ageRange": "5-6", "pageCount": 8, "family": "threshold",
                     "pages": []}


def package(tmp, variant_overrides=None):
    blueprints = [{"id": "bp_control", **PACKAGE_BLUEPRINT},
                  {"id": "bp_variant", **PACKAGE_BLUEPRINT, **(variant_overrides or {})}]
    modes = [{"mode": "adventure", "families": ["threshold", "absence"]},
             {"mode": "bedtime", "families": ["charge", "threshold"], "success": {"abandonIsPenalty": False}}]
    path = tmp / "package.json"
    path.write_text(json.dumps({"schemaVersion": 1, "version": "9.9.9",
                                "libraries": [{"name": "lib.json", "content": {"blueprints": blueprints,
                                                                               "storyModes": modes}}], "beats": []}))
    return path


def usage_doc(period_start, period_end, cells, **overrides):
    doc = {"schemaVersion": 1, "periodStart": period_start, "periodEnd": period_end,
           "thresholds": {"minEvents": 50, "minDays": 7}, "cells": cells, "suppressedCells": 3,
           "rejectedEvents": 0, "weights": {}}
    doc.update(overrides)
    return doc


def cell(blueprint, starts, completions, rereads=0, mode="adventure", band="5-6"):
    return {"blueprintID": blueprint, "ageBand": band, "mode": mode, "starts": starts, "completions": completions,
            "rereads": rereads, "abandoned": starts - completions, "readingDays": 20}


class Loop(TestCase):
    def setUp(self):
        super().setUp()
        self.wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        self.store.put("claim", {
            "claim_id": "c_refrain_x", "statement": "A refrain appears in 1 of 1 analysed books.", "kind": "OBSERVED",
            "layers": ["textual_mechanism"], "scope": {"language": "en"}, "supporting_works": [self.wid],
            "counterexample_works": [], "sources": [], "status": "active",
            "magicpaper": {"target": "writing_guidance", "current": "-", "suggested": "-", "review_status": "proposed"}})
        confidence.recompute_all(self.store)
        self.pid = exchange.open_proposal(self.store, "c_refrain_x")
        self.package = package(self.root)

    def approve(self, action="experiment"):
        exchange.post(self.store, self.pid, "story-engine", "support", "ok")
        exchange.post(self.store, self.pid, "privacy-safety", "support", "ok")
        exchange.set_impact(self.store, self.pid, "story-engine", fields=[], files=[], tests=[], owner="story-engine",
                            cost="S", reversible=True, notes="")
        exchange.set_safety(self.store, self.pid, "privacy-safety", verdict="pass", notes="ok")
        exchange.recommend(self.store, self.pid, "book-research", action=action, rationale="r")
        exchange.decide(self.store, self.pid, verdict="approved", note="go")

    def create(self, eid="x_refrain", mode="adventure", **kw):
        args = dict(experiment_id=eid, proposal_id=self.pid, control="bp_control", variant="bp_variant",
                    age_band="5-6", mode=mode, direction="better", min_effect=0.03, confidence=0.7, rationale="r")
        args.update(kw)
        return experiments.create(self.store, **args)

    def go_live(self, eid="x_refrain"):
        self.assertEqual(experiments.preflight(self.store, eid, self.package), [])
        experiments.mark(self.store, eid, "live", "package 9.9.9 published")

    def import_doc(self, name, doc):
        path = self.root / name
        path.write_text(json.dumps(doc))
        return experiments.import_usage(self.store, path)

    # -- registration and preflight -------------------------------------------------------

    def test_prediction_is_written_once_before_data(self):
        self.create()
        with self.assertRaises(experiments.ExperimentError):
            self.create()
        with self.assertRaises(experiments.ExperimentError):
            self.create(eid="bad_id")
        with self.assertRaises(experiments.ExperimentError):
            self.create(eid="x_overconfident", confidence=1.0)

    def test_preflight_needs_the_owner_and_a_matching_twin(self):
        self.create()
        problems = experiments.preflight(self.store, "x_refrain", self.package)
        self.assertTrue(any("not approved" in p for p in problems))
        self.assertEqual(experiments.get(self.store, "x_refrain")["status"], "draft")
        self.approve()
        self.assertEqual(experiments.preflight(self.store, "x_refrain", self.package), [])
        self.assertEqual(experiments.get(self.store, "x_refrain")["status"], "ready")
        mismatched = package(self.root, {"pageCount": 12})
        self.create(eid="x_mismatch")
        self.assertTrue(any("pageCount" in p for p in experiments.preflight(self.store, "x_mismatch", mismatched)))

    def test_bedtime_only_when_the_proposal_is_bedtime_specific(self):
        self.approve()
        self.create(eid="x_bed", mode="bedtime")
        self.assertTrue(any("bedtime" in p for p in experiments.preflight(self.store, "x_bed", self.package)))
        self.create(eid="x_bed_ok", mode="bedtime", bedtime_specific=True)
        self.assertEqual(experiments.preflight(self.store, "x_bed_ok", self.package), [])

    def test_live_only_from_ready(self):
        self.create()
        with self.assertRaises(experiments.ExperimentError):
            experiments.mark(self.store, "x_refrain", "live", "too early")

    # -- usage import ------------------------------------------------------------------------

    def test_import_refuses_rows_identifiers_and_small_cells(self):
        with self.assertRaises(experiments.ExperimentError):
            self.import_doc("rows.json", usage_doc("2026-11-01", "2026-11-28", [], events=[{"day": "x"}]))
        with self.assertRaises(experiments.ExperimentError):
            self.import_doc("id.json", usage_doc("2026-11-01", "2026-11-28", [{**cell("bp_control", 100, 50), "familyID": "F"}]))
        with self.assertRaises(experiments.ExperimentError):
            self.import_doc("small.json", usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 20, 10)]))
        with self.assertRaises(experiments.ExperimentError):
            self.import_doc("lowfloor.json", usage_doc("2026-11-01", "2026-11-28", [], thresholds={"minEvents": 5, "minDays": 1}))
        self.assertEqual(experiments.usage_periods(self.store), [])
        self.assertEqual(self.import_doc("ok.json", usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 100, 50)])),
                         "2026-11-28")

    # -- evaluation, evidence, calibration -------------------------------------------------

    def test_collecting_until_both_arms_have_enough_readings(self):
        self.approve(); self.create(); self.go_live()
        self.import_doc("u1.json", usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 400, 200), cell("bp_variant", 120, 90)]))
        self.assertEqual(experiments.evaluate(self.store), [])
        self.assertEqual(experiments.get(self.store, "x_refrain")["result"]["state"], "collecting")

    def test_periods_before_launch_are_not_counted(self):
        self.approve(); self.create(); self.go_live()   # live on 2026-10-08 (BOOKINTEL_NOW)
        self.import_doc("old.json", usage_doc("2026-09-01", "2026-09-28", [cell("bp_control", 900, 100), cell("bp_variant", 900, 800)]))
        experiments.evaluate(self.store)
        self.assertEqual(experiments.get(self.store, "x_refrain")["result"]["state"], "collecting")

    def test_a_better_variant_becomes_child_response_evidence_and_scores_the_prediction(self):
        self.approve(); self.create(); self.go_live()
        self.import_doc("u.json", usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 400, 200), cell("bp_variant", 400, 280)]))
        changes = experiments.evaluate(self.store)
        self.assertEqual(changes[0]["observed"], "better")
        record = experiments.get(self.store, "x_refrain")
        self.assertEqual(record["status"], "concluded")
        self.assertGreater(record["result"]["p_variant_better"], 0.95)
        claim = self.store.get("claim", "c_refrain_x")
        self.assertIn("child_response", claim["layers"])
        self.assertEqual(claim["experiments"][0]["observed"], "better")
        cal = experiments.calibration(self.store)
        self.assertEqual((cal["resolved"], cal["hit_rate"]), (1, 1.0))
        self.assertIn("anecdote", cal["advice"])

    def test_a_worse_variant_caps_the_claim_and_counts_as_a_miss(self):
        self.approve(); self.create(); self.go_live()
        self.import_doc("u.json", usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 400, 300), cell("bp_variant", 400, 200)]))
        experiments.evaluate(self.store)
        claim = self.store.get("claim", "c_refrain_x")
        computed = confidence.compute(claim, confidence.Context(self.store))
        self.assertEqual(computed["wording"], "contradicted by an experiment with children")
        self.assertNotIn("child_response", claim["layers"])
        self.assertEqual(experiments.calibration(self.store)["hit_rate"], 0.0)

    def test_bedtime_counts_rereads_not_completions(self):
        control = {"starts": 300, "completions": 280, "rereads": 30}
        variant = {"starts": 300, "completions": 150, "rereads": 90}
        outcome = experiments.compare(control, variant, penalty=False)
        self.assertEqual(outcome["metric"], "reread rate")
        self.assertGreater(outcome["p_variant_better"], 0.95)
        self.assertEqual(experiments.compare(control, variant, penalty=False), outcome, "deterministic")

    # -- the weekly cycle --------------------------------------------------------------------

    def test_cycle_imports_inbox_and_writes_one_page(self):
        self.approve(); self.create(); self.go_live()
        inbox = cycle.inbox(self.store)
        inbox.mkdir(parents=True)
        (inbox / "2026-11-28.json").write_text(json.dumps(
            usage_doc("2026-11-01", "2026-11-28", [cell("bp_control", 400, 200), cell("bp_variant", 400, 280)])))
        (inbox / "bad.json").write_text(json.dumps(usage_doc("2026-11-01", "2026-11-27", [cell("bp_control", 10, 5)])))
        result = cycle.run(self.store)
        self.assertEqual(result["imported"], ["2026-11-28"])
        self.assertEqual(len(result["refused"]), 1)
        page = (self.ws.docs / "weekly" / "2026-10-08.md").read_text()
        for heading in ("## Senin kararın", "## Çocuklardan gelen", "## Deneyler",
                        "## Araştırma ajanı kendini ne kadar iyi tahmin ediyor", "## Sıradaki araştırma görevleri"):
            self.assertIn(heading, page)
        self.assertIn("P(varyant daha iyi)", page)
        again = cycle.run(self.store)
        self.assertEqual(again["imported"], [], "a period is imported once")


class WeeklyHtml(TestCase):
    def test_cycle_writes_a_readable_html_copy(self):
        report = cycle.run(self.store)
        html_path = (self.ws.docs / "weekly" / f"{report['date']}.html")
        page = html_path.read_text()
        self.assertIn("<h1>", page)
        self.assertIn("İş paketleri", page)
        self.assertNotIn("**", page)
