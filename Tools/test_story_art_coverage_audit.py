import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("audit", Path(__file__).with_name("story_art_coverage_audit.py"))
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class SourceAuditTests(unittest.TestCase):
    def test_visual_contract_preserves_absent_empty_auto_and_reviewed(self):
        self.assertEqual(audit.visual_record({})["visualStatus"], "absent")
        empty = audit.visual_record({"visual": [], "visualReview": "auto"})
        self.assertEqual(empty["visualStatus"], "empty")
        self.assertFalse(empty["runtimeBindingApproved"])
        mention = {"subject": "discovery", "presence": "present", "states": ["held"]}
        for review in ["auto", "reviewed"]:
            row = audit.visual_record({"visual": [mention], "visualReview": review})
            self.assertEqual(row["visual"], [mention])
            self.assertEqual(row["visualReview"], review)
            self.assertFalse(row["runtimeBindingApproved"])

    def test_inventory_keeps_source_and_duplicate_variant_ids_distinct(self):
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root)
            for name in ["a.json", "b.json"]:
                (folder / name).write_text(json.dumps({"variants": [{"id": "same", "text": "İki yaprak."}]}))
            records = audit.inventory(folder)
            self.assertEqual(len(records), 2)
            self.assertNotEqual(records[0]["key"], records[1]["key"])
            self.assertEqual(records[0]["pointer"], "/variants/0")
            self.assertTrue(all(r["text_sha256"] for r in records))

    def test_check_rejects_stale_missing_duplicate_and_unreviewed_annotations(self):
        records = [{"key": "one", "text_sha256": "abc"}, {"key": "two", "text_sha256": "def"}]
        notes = [{"key": "one", "text_sha256": "old", "status": "reviewed", "anchors": []},
                 {"key": "one", "text_sha256": "abc", "status": "reviewed", "anchors": []},
                 {"key": "extra", "text_sha256": "x", "status": "candidate", "anchors": []}]
        result = audit.check(records, notes)
        self.assertEqual(result["missing"], ["two"])
        self.assertEqual(result["extra"], ["extra"])
        self.assertEqual(result["duplicates"], ["one"])
        self.assertIn("one", result["stale"])
        self.assertFalse(result["annotation_complete"])
        self.assertEqual(result["guarantee"], "NOT_CERTIFIED")

    def test_exact_annotations_do_not_claim_runtime_coverage(self):
        records = [{"key": "one", "text_sha256": "abc"}]
        notes = [{"key": "one", "text_sha256": "abc", "status": "reviewed",
                  "anchors": [{"presence": "present", "subject": "discovery"}]}]
        result = audit.check(records, notes)
        self.assertTrue(result["annotation_complete"])
        self.assertEqual(result["guarantee"], "NOT_CERTIFIED")

    def test_inventory_is_read_only_and_extracts_slots_without_certifying_presence(self):
        with tempfile.TemporaryDirectory() as root:
            source = Path(root) / "a.json"
            raw = b'{"variants":[{"id":"v","text":"{{child.name}} {{setting.name}} yolundaydi."}]}'
            source.write_bytes(raw)
            record = audit.inventory(Path(root))[0]
            self.assertEqual(record["slots"], ["child.name", "setting.name"])
            self.assertEqual(source.read_bytes(), raw)
            self.assertEqual(record["status"], "unreviewed")

    def test_editorial_evidence_resolves_exact_pointer_and_rejects_stale_text(self):
        with tempfile.TemporaryDirectory() as root:
            source = Path(root) / "a.json"
            source.write_text(json.dumps({"variants": [{"text": "Çan."}]}))
            note = {"source": "a.json", "jsonPointer": "/variants/0", "textSHA256": audit.digest("Çan.")}
            self.assertEqual(audit.verify_editorial(Path(root), [note])["valid_records"], 1)
            note["textSHA256"] = "stale"
            self.assertEqual(audit.verify_editorial(Path(root), [note])["valid_records"], 0)
            note["source"] = "../outside.json"
            self.assertEqual(len(audit.verify_editorial(Path(root), [note])["errors"]), 1)

    def test_context_changes_invalidate_editorial_evidence_even_with_same_text(self):
        with tempfile.TemporaryDirectory() as root:
            source = Path(root) / "a.json"
            source.write_text('{"ageBand":"3-4","variants":[{"id":"old","text":"Çan."}]}')
            sha = audit.hashlib.sha256(source.read_bytes()).hexdigest()
            note = {"source": "a.json", "jsonPointer": "/variants/0", "variantID": "old",
                    "textSHA256": audit.digest("Çan.")}
            sources = [{"path": "a.json", "sha256": sha}]
            self.assertEqual(audit.verify_editorial(Path(root), [note], sources)["valid_records"], 1)
            source.write_text('{"ageBand":"7-8","variants":[{"id":"new","text":"Çan."}]}')
            self.assertEqual(audit.verify_editorial(Path(root), [note], sources)["valid_records"], 0)


if __name__ == "__main__":
    unittest.main()
