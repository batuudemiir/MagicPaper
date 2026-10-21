"""Internet Archive and Book Dash routes, against recorded responses."""

import unittest
from pathlib import Path
from datetime import date
from urllib.parse import unquote

from helpers import FIXTURES, TestCase
from bookintel import analyze, ingest
from bookintel.adapters import base
from bookintel.adapters.bookdash import BookDashAdapter, parse_book
from bookintel.adapters.internet_archive import (InternetArchiveAdapter, eligibility, leaves_to_pages,
                                                 parse_djvu, us_public_domain_cutoff)
from bookintel.schema import validate_store

FAKE_JPEG = b"\xff\xd8\xff\xe0fake-image\xff\xd9"


def ia_fetcher(url: str) -> bytes:
    url = unquote(url)
    if url == "https://archive.org/robots.txt":
        return b"User-agent: *\nDisallow: /control/\nDisallow: /report/\n"
    routes = {
        "https://archive.org/metadata/patientsnail1905": "ia_metadata_pd.json",
        "https://archive.org/metadata/patientsnail1905lend": "ia_metadata_lending.json",
        "https://archive.org/metadata/snailreprint1992": "ia_metadata_modern.json",
        "https://archive.org/download/patientsnail1905/patientsnail1905_djvu.xml": "ia_djvu.xml",
        "https://archive.org/metadata/patientsnailupload": "ia_metadata_upload.json",
        "https://archive.org/download/patientsnailupload/patientsnailupload_djvu.xml": "ia_djvu.xml",
    }
    if url in routes:
        return (FIXTURES / routes[url]).read_bytes()
    if url.startswith("https://archive.org/advancedsearch.php?"):
        return (FIXTURES / "ia_search.json").read_bytes()
    if url.startswith("https://archive.org/download/patientsnail1905/page/n"):
        return FAKE_JPEG
    raise AssertionError(f"unexpected URL in test: {url}")


def bookdash_fetcher(url: str) -> bytes:
    if url == "https://bookdash.org/robots.txt":
        return b"User-agent: *\nDisallow:\n"
    if url == "https://bookdash.org/books/":
        return (FIXTURES / "bookdash_list.html").read_bytes()
    if url == "https://bookdash.org/books/mud/":
        return (FIXTURES / "bookdash_mud.html").read_bytes()
    if url.startswith("https://bookdash.org/wp-content/uploads/"):
        return FAKE_JPEG
    raise AssertionError(f"unexpected URL in test: {url}")


class Redirects(unittest.TestCase):
    def test_subdomain_entries(self):
        allowed = {"archive.org", ".archive.org"}
        self.assertTrue(base.host_allowed("ia600400.us.archive.org", allowed))
        self.assertTrue(base.host_allowed("dn710300.ca.archive.org", allowed))
        self.assertFalse(base.host_allowed("evil-archive.org", allowed))
        self.assertFalse(base.host_allowed("us.archive.org.evil.com", allowed))
        self.assertFalse(base.host_allowed("notarchive.org", allowed))

    def test_redirect_off_the_list_is_refused(self):
        handler = base._GuardedRedirects({"archive.org", ".archive.org"})
        with self.assertRaises(base.AccessRefused):
            handler.redirect_request(None, None, 302, "Found", {}, "https://mirror.example.com/file")
        with self.assertRaises(base.AccessRefused):
            handler.redirect_request(None, None, 302, "Found", {}, "http://ia600.us.archive.org/file")  # not https


class InternetArchiveRules(unittest.TestCase):
    def test_public_domain_cutoff_moves_with_the_year(self):
        self.assertEqual(us_public_domain_cutoff(date(2026, 10, 8)), 1930)
        self.assertEqual(us_public_domain_cutoff(date(2027, 1, 1)), 1931)

    def test_eligibility_rules(self):
        import json
        load = lambda name: json.loads((FIXTURES / name).read_text())
        today = date(2026, 10, 8)
        self.assertTrue(eligibility(load("ia_metadata_pd.json"), today)[0])
        ok, reason = eligibility(load("ia_metadata_lending.json"), today)
        self.assertFalse(ok)
        self.assertIn("controlled-lending", reason)
        ok, reason = eligibility(load("ia_metadata_modern.json"), today)
        self.assertFalse(ok)
        self.assertIn("1992", reason)
        self.assertFalse(eligibility({"metadata": {"date": "1901"}, "is_dark": True}, today)[0])
        self.assertFalse(eligibility({"metadata": {"date": "1901", "access-restricted-item": "true"}}, today)[0])
        self.assertFalse(eligibility({"metadata": {"title": "undated"}}, today)[0])

    def test_leaves_become_pages_with_their_pictures(self):
        pages = leaves_to_pages(parse_djvu((FIXTURES / "ia_djvu.xml").read_bytes()))
        self.assertEqual([p["leaf"] for p in pages], [1, 3, 5])
        self.assertEqual(pages[0]["illustration_leaves"], [0, 2])   # cover (1 word) before, picture after
        self.assertEqual(pages[0]["text"], "Once there was a snail\nwho wanted to climb.")
        self.assertEqual(pages[1]["illustration_leaves"], [4])
        self.assertEqual(pages[0]["page"], 1)


class InternetArchiveRoute(TestCase):
    def adapter(self):
        return InternetArchiveAdapter(fetcher=ia_fetcher)

    def test_search_excludes_lending_and_recent_years_in_the_query(self):
        calls = []
        adapter = InternetArchiveAdapter(fetcher=lambda u: calls.append(unquote(u)) or ia_fetcher(u))
        results = adapter.search("snail")
        self.assertEqual(results[0]["identifier"], "patientsnail1905")
        query = next(c for c in calls if "advancedsearch" in c)
        self.assertIn("NOT collection:(browserlending OR inlibrary OR lendinglibrary OR printdisabled)", query.replace("+", " "))
        self.assertIn(f"year:[1400 TO {us_public_domain_cutoff()}]", query.replace("+", " "))

    def test_lending_and_modern_items_are_refused(self):
        for identifier in ("patientsnail1905lend", "snailreprint1992"):
            with self.assertRaises(base.AccessRefused):
                ingest.ingest_internet_archive(self.store, identifier, adapter=self.adapter())
        self.assertEqual(self.store.all("work"), [])

    def test_ingest_scan_and_analyse_page_turns(self):
        result = ingest.ingest_internet_archive(self.store, "patientsnail1905", adapter=self.adapter(),
                                                age_band="5-6", basis="analyst")
        self.assertEqual(result["pages"], 3)
        edition = self.store.get("edition", result["edition_id"])
        self.assertEqual((edition["page_boundary_source"], edition["text_origin"]), ("original_scan", "ocr"))
        source = self.store.get("source", edition["source_id"])
        self.assertIn("published 1905", source["rights_detail"]["basis"])
        self.assertIn("scanned at nyc from Test Public Library", source["rights_detail"]["basis"])
        work = self.store.get("work", result["work_id"])
        self.assertEqual(work["creators"][0]["name"], "Testwright, Ada")
        info = analyze.scaffold(self.store, result["work_id"])
        self.assertTrue(info["page_turn_ok"])
        page = self.store.get("pages", f"{result['work_id']}.v1")["pages"][0]
        self.assertEqual(page["source_leaves"], [1, 0, 2])
        self.assertTrue(page["illustration"]["available"])
        self.assertEqual(validate_store(self.store), [])

    def test_user_upload_is_not_trusted_as_original_scan(self):
        result = ingest.ingest_internet_archive(self.store, "patientsnailupload", adapter=self.adapter())
        edition = self.store.get("edition", result["edition_id"])
        self.assertEqual(edition["page_boundary_source"], "reconstructed")
        self.assertFalse(edition["boundary_confirmed_by_analyst"])
        source = self.store.get("source", edition["source_id"])
        self.assertIn("uploader's claim", source["rights_detail"]["basis"])
        self.assertFalse(analyze.scaffold(self.store, result["work_id"])["page_turn_ok"])

    def test_analyst_can_confirm_an_upload_after_viewing_it(self):
        result = ingest.ingest_internet_archive(self.store, "patientsnailupload", adapter=self.adapter(),
                                                confirm_scan=True)
        edition = self.store.get("edition", result["edition_id"])
        self.assertEqual(edition["page_boundary_source"], "original_scan")
        self.assertTrue(edition["boundary_confirmed_by_analyst"])

    def test_ocr_correction_route(self):
        first = ingest.ingest_internet_archive(self.store, "patientsnail1905", adapter=self.adapter(), transcribe=True)
        self.assertEqual(first["decision"], "needs_transcription")
        self.assertEqual(self.store.all("work"), [])
        draft = open(first["transcription"], encoding="utf-8").read()
        self.assertEqual(draft.count("\n[draft]\n"), 3)
        self.assertIn("[leaf: 1, 0, 2]", draft)
        with self.assertRaises(ingest.IngestError):     # drafts left
            ingest.ingest_internet_archive(self.store, "patientsnail1905", adapter=self.adapter())
        fixed = draft.replace("[draft]\n", "").replace("[leaf: 5]", "[leaf: 5]\n[skip: back cover]")
        open(first["transcription"], "w", encoding="utf-8").write(fixed)
        result = ingest.ingest_internet_archive(self.store, "patientsnail1905", adapter=self.adapter())
        self.assertEqual(result["pages"], 2)
        edition = self.store.get("edition", result["edition_id"])
        self.assertEqual(edition["text_origin"], "analyst_transcription")
        self.assertEqual(edition["skipped_pages"], [{"file_page": 3, "reason": "back cover"}])
        images = ingest.page_images(self.store, result["edition_id"], [1], adapter=self.adapter())
        self.assertEqual(len(images[0]["files"]), 3)
        self.assertEqual(validate_store(self.store), [])

    def test_page_images_are_fetched_on_request_and_cached(self):
        result = ingest.ingest_internet_archive(self.store, "patientsnail1905", adapter=self.adapter())
        images = ingest.page_images(self.store, result["edition_id"], [1], adapter=self.adapter())
        self.assertEqual(len(images[0]["files"]), 3)
        self.assertTrue(all(Path(f).read_bytes() == FAKE_JPEG for f in images[0]["files"]))


class BookDashRoute(TestCase):
    def adapter(self):
        return BookDashAdapter(fetcher=bookdash_fetcher)

    def test_parse_book_page(self):
        book = parse_book((FIXTURES / "bookdash_mud.html").read_text(), "mud")
        self.assertEqual(book["title"], "MUD!")
        self.assertEqual(book["isbn"], "978-1-77623-040-2")
        self.assertEqual((book["year"], book["year_basis"]), (2023, "book_dash_event"))
        undated = parse_book((FIXTURES / "bookdash_mud.html").read_text().replace("Created at Book Dash 22: Cape Town, 14 October 2023", ""), "mud")
        self.assertEqual((undated["year"], undated["year_basis"]), (2023, "web_upload_year"))
        self.assertEqual(book["language"], "en")
        self.assertEqual([c["role"] for c in book["creators"]], ["editor", "designer", "author", "illustrator"])
        self.assertEqual(book["images"], [
            "https://bookdash.org/wp-content/uploads/2023/10/mud_cover-1536x1536.jpg",
            "https://bookdash.org/wp-content/uploads/2023/10/mud_page4-1536x768.jpg",
            "https://bookdash.org/wp-content/uploads/2023/10/mud_page6-scaled.jpg",
        ])
        self.assertIn("Penny Waterkeyn (author)", BookDashAdapter.attribution(book))

    def test_list(self):
        self.assertEqual(self.adapter().list_books(), ["a-tiny-seed", "mud"])

    def test_two_step_ingest_through_a_transcription(self):
        first = ingest.ingest_bookdash(self.store, "mud", adapter=self.adapter())
        self.assertEqual(first["decision"], "needs_transcription")
        self.assertEqual(first["pages"], 3)
        self.assertEqual(self.store.all("work"), [])
        scaffold = open(first["transcription"], encoding="utf-8").read()
        self.assertEqual(scaffold.count("[image: "), 3)

        with self.assertRaises(ingest.IngestError):
            ingest.ingest_bookdash(self.store, "mud", adapter=self.adapter())   # nothing transcribed yet

        filled = scaffold.replace("=== page 1 ===\n", "=== page 1 ===\n[no text]\n") \
                         .replace("=== page 2 ===\n", "=== page 2 ===\nZama jumps in the mud.\n") \
                         .replace("=== page 3 ===\n", "=== page 3 ===\nSplosh! Mama frowns.\n")
        open(first["transcription"], "w", encoding="utf-8").write(filled)
        second = ingest.ingest_bookdash(self.store, "mud", adapter=self.adapter(), age_band="5-6", basis="publisher")
        self.assertEqual(second["decision"], "new")
        edition = self.store.get("edition", second["edition_id"])
        self.assertEqual((edition["page_boundary_source"], edition["text_origin"]),
                         ("publisher_layout", "analyst_transcription"))
        source = self.store.get("source", edition["source_id"])
        self.assertEqual(source["rights"], "open_license")
        self.assertIn("Book Dash", source["rights_detail"]["attribution"])
        work = self.store.get("work", second["work_id"])
        self.assertIn({"name": "Thea de Klerk", "role": "illustrator"}, work["creators"])
        self.assertEqual(work["external_ids"]["isbn"], "978-1-77623-040-2")

        info = analyze.scaffold(self.store, second["work_id"])
        self.assertTrue(info["page_turn_ok"])
        pages = self.store.get("pages", f"{second['work_id']}.v1")["pages"]
        self.assertTrue(pages[0]["illustration"]["available"])
        self.assertEqual(pages[0]["metrics"]["words"], 0)
        self.assertEqual(validate_store(self.store), [])
        images = ingest.page_images(self.store, second["edition_id"], [2])
        self.assertTrue(images[0]["files"][0].endswith("p02.jpg"))
        for path in self.ws.data.rglob("*.json"):
            self.assertNotIn(str(self.root), path.read_text(), f"local path leaked into {path.name}")


if __name__ == "__main__":
    unittest.main()
