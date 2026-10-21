"""Parity with StoryEngine's TextMetrics.swift, plus Turkish cases."""

import unittest

from helpers import TestCase  # noqa: F401  (sets sys.path)
from bookintel import language
from bookintel import text_metrics as tm


class TextMetricsParity(unittest.TestCase):
    def test_speech_attribution_stays_in_one_sentence(self):
        self.assertEqual(tm.sentences('"Stop!" said Deniz. Then he ran.'), ['"Stop!" said Deniz.', "Then he ran."])

    def test_terminator_runs_and_ellipsis(self):
        self.assertEqual(tm.sentences("Wait... What?! Yes."), ["Wait...", "What?!", "Yes."])
        self.assertEqual(tm.sentences("Bekle… Sonra gel."), ["Bekle…", "Sonra gel."])

    def test_trailing_text_without_terminator_is_a_sentence(self):
        self.assertEqual(tm.sentences("One. And then"), ["One.", "And then"])

    def test_words_trim_outer_punctuation_only(self):
        self.assertEqual(tm.words("Ragi'nin şapkası, \"uçtu!\""), ["Ragi'nin", "şapkası", "uçtu"])
        self.assertEqual(tm.word_count(" — ... "), 0)

    def test_longest_sentence(self):
        self.assertEqual(tm.longest_sentence_word_count("A b. A b c d. E."), 4)

    def test_turkish_lowercasing_in_ngrams(self):
        self.assertEqual(tm.n_grams("IŞIK İPEK", 2, "tr"), ["ışık ipek"])
        self.assertEqual(tm.n_grams("one two", 3), [])


class LanguageMetrics(unittest.TestCase):
    def test_dialogue_questions_and_address(self):
        m = language.page_metrics('"Who will light the wood?" asked Fox. Do you know?', "en")
        self.assertEqual(m["questions"], 2)
        self.assertEqual(m["direct_address"], 1)
        self.assertGreater(m["dialogue_ratio"], 0.4)
        self.assertEqual(m["computed_by"], "cli")

    def test_turkish_dash_dialogue_and_sound_words(self):
        m = language.page_metrics("— Ay neden küçülüyor? dedi Kirpi.\nTık, tık, tık diye yürüdü.", "tr")
        self.assertGreater(m["dialogue_ratio"], 0)
        self.assertEqual(m["sound_words"], 3)

    def test_refrain_detected_across_pages_not_within(self):
        pages = ["The wood was dark, dark, dark.", "Fox ran.", "The wood was dark, dark, dark."]
        rep = language.repetition(pages, "en")
        self.assertIn("the wood was dark dark dark", rep["refrains"])
        self.assertNotIn("dark dark dark", rep["repeated_phrases"])  # contained in a longer repeat

    def test_stretched_sound_words_and_short_refrains(self):
        self.assertEqual(language.page_metrics("WHEEEE! Shhh. KER-SPLASH! Eek.", "en")["sound_words"], 4)
        rep = language.repetition(["Zama! It is fine.", "Zama! Go to bed now."], "en")
        self.assertNotIn("zama", rep["refrains"])

    def test_book_metrics_shape(self):
        m = language.book_metrics(["One two three.", "Four five?"], "en")
        self.assertEqual(m["total_words"], 5)
        self.assertEqual(m["words_per_page"]["median"], 2.5)
        self.assertEqual(m["questions_per_page"], 0.5)


if __name__ == "__main__":
    unittest.main()
