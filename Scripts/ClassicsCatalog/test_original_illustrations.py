import json
from pathlib import Path
import tempfile
import unittest

from original_illustrations import build_page_illustrations


class OriginalIllustrationsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.book = self.root / "book"
        self.book.mkdir()
        self.assets = self.root / "assets"

    def manifest(self, entries):
        (self.book / "illustrations.json").write_text(json.dumps({"pages": entries}))

    def entry(self, page=1, **extra):
        return {"page": page, "file": f"page-{page:02d}.jpg", "altText": "Karlı istasyon.", **extra}

    def image(self, page=1):
        folder = self.book / "illustrations"
        folder.mkdir(exist_ok=True)
        (folder / f"page-{page:02d}.jpg").write_bytes(b"\xff\xd8\xff\xe0test\xff\xd9")

    def test_legacy_book_has_no_metadata_or_assets(self):
        self.assertIsNone(build_page_illustrations(self.book, "book", 2, self.assets))
        self.assertFalse(self.assets.exists())

    def test_complete_sequence_copies_assets_and_preserves_page_order(self):
        self.manifest([self.entry(1), self.entry(2)])
        self.image(1)
        self.image(2)
        result = build_page_illustrations(self.book, "book", 2, self.assets)
        self.assertEqual(result, [
            {"asset": "original-book-page-01", "altText": "Karlı istasyon."},
            {"asset": "original-book-page-02", "altText": "Karlı istasyon."}
        ])
        for page in (1, 2):
            name = f"original-book-page-{page:02d}"
            folder = self.assets / (name + ".imageset")
            self.assertEqual((folder / (name + ".jpg")).read_bytes(),
                             (self.book / "illustrations" / f"page-{page:02d}.jpg").read_bytes())
            meta = json.loads((folder / "Contents.json").read_text())
            self.assertEqual(meta["images"][0]["filename"], name + ".jpg")

    def test_rejects_partial_or_wrong_order_before_writing_assets(self):
        for entries in ([self.entry(1)], [self.entry(2), self.entry(1)]):
            with self.subTest(entries=entries):
                self.manifest(entries)
                self.image(1)
                self.image(2)
                with self.assertRaises(ValueError):
                    build_page_illustrations(self.book, "book", 2, self.assets)
                self.assertFalse(self.assets.exists())

    def test_rejects_missing_blank_alt_text_and_unsafe_files(self):
        for entry in (self.entry(), self.entry(altText=" "), self.entry(file="../cover.jpg")):
            with self.subTest(entry=entry):
                self.manifest([entry])
                with self.assertRaises(ValueError):
                    build_page_illustrations(self.book, "book", 1, self.assets)
                self.assertFalse(self.assets.exists())

    def test_missing_later_image_does_not_copy_earlier_image(self):
        self.manifest([self.entry(1), self.entry(2)])
        self.image(1)
        with self.assertRaises(ValueError):
            build_page_illustrations(self.book, "book", 2, self.assets)
        self.assertFalse(self.assets.exists())

    def test_rejects_non_jpeg_source(self):
        self.manifest([self.entry()])
        self.image()
        (self.book / "illustrations/page-01.jpg").write_bytes(b"not an image")
        with self.assertRaises(ValueError):
            build_page_illustrations(self.book, "book", 1, self.assets)


if __name__ == "__main__":
    unittest.main()
