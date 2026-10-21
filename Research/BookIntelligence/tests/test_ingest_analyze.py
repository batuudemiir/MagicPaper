"""Acquisition, the analyst loop, and persistence."""

from helpers import TestCase, analysed, fill_judgments, fixture_fetcher, gutenberg, ingest_fixture
from bookintel import analyze, ingest
from bookintel.adapters.base import AccessRefused
from bookintel.schema import validate_store


class GutenbergRoute(TestCase):
    def test_catalog_search_filters_type_language_and_shelf(self):
        adapter = gutenberg(self.ws.cache)
        self.assertEqual([r["gutenberg_id"] for r in adapter.search("snail", "en")], [9001, 9002])
        self.assertEqual([r["gutenberg_id"] for r in adapter.search("snail", "tr")], [])
        self.assertEqual([r["gutenberg_id"] for r in adapter.search("salyangoz", "tr")], [9003])
        self.assertEqual(len(adapter.search("snail", shelf="picture books")), 2)
        self.assertTrue(self.ws.cache.joinpath("catalog", "pg_catalog.csv.gz").exists())

    def test_catalog_is_cached(self):
        calls = []
        def counting(url):
            calls.append(url)
            return fixture_fetcher(url)
        from bookintel.adapters.gutenberg import GutenbergAdapter
        adapter = GutenbergAdapter(self.ws.cache, fetcher=counting)
        adapter.search("snail"); adapter.search("tale")
        self.assertEqual(sum(1 for u in calls if u.endswith("pg_catalog.csv.gz")), 1)

    def test_rdf_gives_rights_roles_and_downloads(self):
        book = gutenberg().book(9001)
        self.assertTrue(book["public_domain_us"])
        self.assertEqual([(c["name"], c["role"]) for c in book["creators"]],
                         [("Testwright, Ada", "author"), ("Inkwell, Bea", "illustrator")])
        self.assertEqual(book["download_count"], 1234)

    def test_copyrighted_text_is_refused(self):
        modern = gutenberg().book(9002)
        self.assertFalse(modern["public_domain_us"])
        with self.assertRaises(AccessRefused):
            gutenberg().fetch_text(modern)

    def test_hosts_outside_allow_list_are_refused(self):
        with self.assertRaises(AccessRefused):
            gutenberg().http.get("https://gutendex.com/books/1")
        with self.assertRaises(AccessRefused):
            gutenberg().http.get("http://www.gutenberg.org/cache/epub/1/pg1.txt")  # not https

    def test_robots_disallow_is_respected(self):
        with self.assertRaises(AccessRefused):
            gutenberg().http.get("https://www.gutenberg.org/ebooks/search/?query=snail")

    def test_ingest_records_source_rights_and_reconstructed_pages(self):
        result = ingest.ingest_gutenberg(self.store, 9001, adapter=gutenberg(), age_band="5-6", basis="analyst")
        self.assertEqual(result["pages"], 4)
        source = self.store.get("source", "s_gutenberg_9001")
        self.assertEqual((source["rights"], source["tier"], source["rights_detail"]["jurisdiction"]),
                         ("public_domain", "A", "US"))
        edition = self.store.get("edition", "e_gutenberg_9001")
        self.assertEqual(edition["page_boundary_source"], "reconstructed")
        self.assertEqual(edition["signals"]["gutenberg_download_count"], 1234)
        work = self.store.get("work", result["work_id"])
        self.assertEqual([c["role"] for c in work["creators"]], ["author", "illustrator"])
        self.assertTrue(self.store.cache_path("raw", "e_gutenberg_9001.txt").exists())
        self.assertEqual(validate_store(self.store), [])

    def test_reingest_is_idempotent(self):
        ingest.ingest_gutenberg(self.store, 9001, adapter=gutenberg())
        snapshot = {p: p.read_bytes() for p in self.ws.data.rglob("*.json")}
        ingest.ingest_gutenberg(self.store, 9001, adapter=gutenberg())
        after = {p: p.read_bytes() for p in self.ws.data.rglob("*.json")}
        self.assertEqual(set(snapshot), set(after))
        changed = [p.name for p in after if after[p] != snapshot[p]]
        self.assertEqual(changed, [], "a second ingest of the same edition must not change records")


class ManualRoute(TestCase):
    def test_rights_that_forbid_text_cannot_be_ingested(self):
        with self.assertRaises(ingest.IngestError):
            ingest.ingest_manual(self.store, "unused", url="https://x.org", rights="publisher_preview",
                                 rights_detail={}, kind="publisher_page", tier="A", title="T",
                                 creators=[{"name": "A B", "role": "author"}], language="en",
                                 page_boundary_source="publisher_layout")

    def test_metadata_only_work(self):
        result = ingest.add_metadata_work(self.store, title="A Celebrated Modern Book",
                                          creators=[{"name": "Some Author", "role": "author"}],
                                          language="en", year=2015, age_band="5-6", basis="publisher")
        self.assertEqual(result["decision"], "new")
        self.assertEqual(validate_store(self.store), [])


class AnalystLoop(TestCase):
    def setUp(self):
        super().setUp()
        self.wid = ingest_fixture(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")["work_id"]

    def test_scaffold_carries_text_and_cli_metrics(self):
        info = analyze.scaffold(self.store, self.wid)
        self.assertTrue(info["text_stored"])
        self.assertTrue(info["page_turn_ok"])
        pages = self.store.get("pages", f"{self.wid}.v1")
        self.assertEqual(pages["pages"][0]["metrics"]["computed_by"], "cli")
        self.assertEqual(pages["pages"][0]["illustration"]["available"], True)
        analysis = self.store.get("analysis", f"{self.wid}.v1")
        self.assertEqual(analysis["metrics"]["pages"], 6)
        self.assertEqual(analysis["completeness"], "partial")  # nothing judged yet

    def test_complete_refuses_missing_judgments(self):
        analyze.scaffold(self.store, self.wid)
        with self.assertRaises(analyze.AnalyzeError):
            analyze.complete(self.store, self.wid, "1", "tester")

    def test_full_loop_and_hand_edited_metrics_do_not_survive(self):
        analyze.scaffold(self.store, self.wid)
        fill_judgments(self.store, self.wid)
        pages = self.store.get("pages", f"{self.wid}.v1")
        pages["pages"][0]["metrics"]["words"] = 999
        self.store.put("pages", pages)
        result = analyze.complete(self.store, self.wid, "1", "tester")
        self.assertEqual(result["completeness"], "full")
        pages = self.store.get("pages", f"{self.wid}.v1")
        self.assertNotEqual(pages["pages"][0]["metrics"]["words"], 999)
        analysis = self.store.get("analysis", f"{self.wid}.v1")
        self.assertEqual(analysis["child_appeal_heuristic"]["label"], "Research heuristic — not validated")
        self.assertEqual(analysis["beat_positions"]["HOOK"], 0.0)
        self.assertEqual(analysis["beat_positions"]["ENDING"], 1.0)
        self.assertEqual(validate_store(self.store), [])

    def test_version_bump_keeps_old_analysis(self):
        analysed_id = self.wid
        analyze.scaffold(self.store, analysed_id)
        with self.assertRaises(analyze.AnalyzeError):
            analyze.scaffold(self.store, analysed_id)
        analyze.scaffold(self.store, analysed_id, version="2")
        self.assertIsNotNone(self.store.get("analysis", f"{analysed_id}.v1"))
        self.assertEqual(self.store.latest("analysis", analysed_id)["analysis_version"], "2")

    def test_reconstructed_pages_get_no_page_turn_fields(self):
        result = ingest.ingest_gutenberg(self.store, 9001, adapter=gutenberg())
        info = analyze.scaffold(self.store, result["work_id"])
        self.assertFalse(info["page_turn_ok"])
        page = self.store.get("pages", f"{result['work_id']}.v1")["pages"][0]
        self.assertIsNone(page["page_turn_mechanism"])

    def test_partial_analysis_from_notes_without_text(self):
        work = ingest.add_metadata_work(self.store, title="A Modern Award Winner",
                                        creators=[{"name": "Prize Author", "role": "author"}],
                                        language="en", year=2018, age_band="5-6", basis="award_body")
        ingest.add_source(self.store, source_id="s_preview_modern", url="https://publisher.example/preview",
                          kind="publisher_page", tier="A", rights="publisher_preview", note="8-page preview")
        edition = {"edition_id": "e_preview_modern", "work_id": work["work_id"], "source_id": "s_preview_modern",
                   "language": "en", "format": "web", "page_boundary_source": "publisher_layout"}
        self.store.put("edition", edition)
        w = self.store.get("work", work["work_id"]); w["editions"].append("e_preview_modern"); self.store.put("work", w)
        info = analyze.scaffold(self.store, work["work_id"], page_count=8)
        self.assertFalse(info["text_stored"])
        fill_judgments(self.store, work["work_id"])
        result = analyze.complete(self.store, work["work_id"], "1", "tester")
        self.assertEqual(result["completeness"], "partial")
        self.assertEqual(validate_store(self.store), [])


class Analysed(TestCase):
    def test_helper_produces_a_valid_complete_corpus(self):
        analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")
        analysed(self.store, "ay_ve_kirpi.pages.txt", "Ay ve Kirpi", "Deneme Yazar", language="tr")
        self.assertEqual(validate_store(self.store), [])
