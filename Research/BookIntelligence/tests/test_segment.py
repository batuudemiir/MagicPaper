import unittest

from helpers import FIXTURES, TestCase  # noqa: F401
from bookintel import segment


class PageFiles(unittest.TestCase):
    def test_pages_spreads_and_illustration_notes(self):
        pages = segment.parse_page_file((FIXTURES / "fox_and_lantern.pages.txt").read_text())
        self.assertEqual([p["page"] for p in pages], [1, 2, 3, 4, 5, 7])
        self.assertTrue(pages[4]["spread"])
        self.assertEqual(pages[4]["page_range"], [5, 6])
        self.assertEqual(pages[0]["illustration_notes"], ["a small fox at a burrow door, the wood black behind"])
        self.assertNotIn("illustration", pages[0]["text"].lower())

    def test_numbering_gap_is_an_error(self):
        with self.assertRaises(segment.SegmentationError):
            segment.parse_page_file("=== page 1 ===\na\n=== page 3 ===\nb")

    def test_text_before_first_marker_is_an_error(self):
        with self.assertRaises(segment.SegmentationError):
            segment.parse_page_file("stray line\n=== page 1 ===\na")


class Reconstruction(unittest.TestCase):
    def setUp(self):
        self.body = segment.strip_gutenberg((FIXTURES / "gutenberg_9001.txt").read_text())

    def test_gutenberg_header_and_footer_removed(self):
        self.assertNotIn("PROJECT GUTENBERG", self.body)

    def test_one_page_per_illustration(self):
        pages = segment.reconstruct_pages(self.body, mode="illustrations")
        self.assertEqual(len(pages), 4)
        self.assertTrue(pages[1]["text"].startswith('"Too slow!"'))
        self.assertIn("kept on climbing", pages[1]["text"])  # wrapped lines joined

    def test_pack_mode(self):
        pages = segment.reconstruct_pages(self.body, mode="pack", target_words=20)
        self.assertGreaterEqual(len(pages), 2)
        self.assertTrue(all("[Illustration" not in p["text"] for p in pages))


if __name__ == "__main__":
    unittest.main()
