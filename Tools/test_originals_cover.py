"""Original kapak aracı testleri (spec 2026-11-12). Ağ yok, yalnız stdlib.

    python3 Tools/test_originals_cover.py
"""

import base64
import pathlib
import tempfile
import unittest

import originals_cover as c

WORLD = """# Fener Kasabası

## Karakterler

### Lale
Kızıl örgülü saç.

## Kapak stili
Gouache, warm paper texture, soft dusk light.

## Ton
Sakin.
"""

REVIEW = """# Fenerin Sesi

## Kapak sahnesi
Lale climbs the lighthouse stairs holding a small lantern.

## Notlar
"""


class SectionTests(unittest.TestCase):
    def test_reads_only_its_own_section(self):
        self.assertEqual(c.section(WORLD, "Kapak stili"), "Gouache, warm paper texture, soft dusk light.")
        self.assertEqual(c.section(REVIEW, "Kapak sahnesi"), "Lale climbs the lighthouse stairs holding a small lantern.")
        self.assertEqual(c.section(REVIEW, "Notlar"), "")
        self.assertEqual(c.section(WORLD, "Yok"), "")


class PromptTests(unittest.TestCase):
    def test_prompt_has_style_scene_and_rules(self):
        prompt = c.build_prompt("Gouache.", "Lale on the stairs.")
        self.assertIn("Gouache.", prompt)
        self.assertIn("Lale on the stairs.", prompt)
        self.assertIn("no text", prompt)

    def test_missing_parts_are_named(self):
        with self.assertRaises(ValueError):
            c.build_prompt("", "Sahne")
        with self.assertRaises(ValueError):
            c.build_prompt("Stil", "")

    def test_request_asks_for_a_portrait_image(self):
        body = c.request_body("p")
        self.assertEqual(body["generationConfig"]["imageConfig"]["aspectRatio"], "3:4")
        self.assertEqual(body["generationConfig"]["responseModalities"], ["IMAGE"])


class ResponseTests(unittest.TestCase):
    def test_first_inline_image_is_returned(self):
        raw = b"\x89PNG..."
        response = {"candidates": [{"content": {"parts": [
            {"text": "işte"}, {"inlineData": {"mimeType": "image/png", "data": base64.b64encode(raw).decode()}}]}}]}
        self.assertEqual(c.image_bytes(response), raw)

    def test_no_image_raises(self):
        with self.assertRaises(RuntimeError):
            c.image_bytes({"candidates": []})


class KeyTests(unittest.TestCase):
    def test_key_comes_from_secrets_when_env_is_empty(self):
        with tempfile.TemporaryDirectory() as root:
            pathlib.Path(root, "Secrets.xcconfig").write_text("OTHER = x\nGEMINI_API_KEY = abc123\n", encoding="utf-8")
            self.assertEqual(c.api_key(pathlib.Path(root), env={}), "abc123")
            self.assertEqual(c.api_key(pathlib.Path(root), env={"GEMINI_API_KEY": "env"}), "env")
            self.assertIsNone(c.api_key(pathlib.Path(root, "yok"), env={}))


if __name__ == "__main__":
    unittest.main()
