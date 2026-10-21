import unittest

from helpers import TestCase, analysed, ingest_fixture  # noqa: F401
from bookintel import dedup
from bookintel.ingest import IngestError


def work(work_id, title, creator, lang="en", **ids):
    return {"work_id": work_id, "title": title, "original_language": lang,
            "creators": [{"name": creator, "role": "author"}], "external_ids": ids}


class Normalization(unittest.TestCase):
    def test_titles(self):
        self.assertEqual(dedup.normalize_title("The Tale of Peter Rabbit"), "tale of peter rabbit")
        self.assertEqual(dedup.normalize_title("THE TALE OF PETER RABBIT!"), "tale of peter rabbit")
        self.assertEqual(dedup.normalize_title("Işıklı Orman", "tr"), dedup.normalize_title("ışıklı orman", "tr"))

    def test_creator_key(self):
        self.assertEqual(dedup.creator_key("Potter, Beatrix"), dedup.creator_key("Beatrix Potter"))


class Matching(unittest.TestCase):
    def setUp(self):
        self.works = [work("w_peter", "The Tale of Peter Rabbit", "Beatrix Potter", gutenberg="14838")]

    def test_shared_identifier_is_same_work(self):
        decision, wid, _ = dedup.match(work("x", "Peter Rabbit (illustrated)", "Anyone", gutenberg="14838"), self.works)
        self.assertEqual((decision, wid), ("same", "w_peter"))

    def test_other_edition_same_title_and_creator(self):
        decision, wid, _ = dedup.match(work("x", "THE TALE OF PETER RABBIT", "Potter, Beatrix"), self.works)
        self.assertEqual((decision, wid), ("same", "w_peter"))

    def test_same_title_other_creator_is_ambiguous_not_merged(self):
        decision, _, reasons = dedup.match(work("x", "The Tale of Peter Rabbit", "Someone Else"), self.works)
        self.assertEqual(decision, "ambiguous")
        self.assertIn("different creator", reasons[0])

    def test_unrelated_is_new(self):
        self.assertEqual(dedup.match(work("x", "Owl at Home", "Arnold Lobel"), self.works)[0], "new")


class IngestDedup(TestCase):
    def test_second_edition_attaches_to_existing_work(self):
        first = ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        second = ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Test, Ada",
                                edition_id="e_reprint_fox")
        self.assertEqual(second["decision"], "same")
        self.assertEqual(first["work_id"], second["work_id"])
        self.assertEqual(len(self.store.all("work")), 1)
        self.assertEqual(len(self.store.get("work", first["work_id"])["editions"]), 2)

    def test_ambiguous_match_is_queued_and_stops(self):
        ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        with self.assertRaises(IngestError):
            ingest_fixture(self.store, "hen_and_seed.pages.txt", "Little Fox and the Lantern", "Other Person")
        self.assertEqual(len(self.store.review_items()), 1)
        self.assertEqual(len(self.store.all("work")), 1)
        resolved = ingest_fixture(self.store, "hen_and_seed.pages.txt", "Little Fox and the Lantern",
                                  "Other Person", force_new=True)
        self.assertEqual(resolved["decision"], "new")
        self.assertEqual(len(self.store.all("work")), 2)


if __name__ == "__main__":
    unittest.main()
