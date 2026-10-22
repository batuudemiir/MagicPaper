"""Nadir kelime raporu testleri (22 Ekim 2026, docs/Kelime_Plani_kitapokur.md B).

Yalnız stdlib: sıklık ve kök bulma sahte tablolarla verilir, wordfreq ve
simplemma kurulu olmadan çalışır.

    python3 Tools/test_nadir_kelime_raporu.py
"""

import unittest

import nadir_kelime_raporu as r


ZIPF = {
    "ağaç": 4.2, "ağacın": 2.5,
    "sabır": 3.9, "sabırla": 3.0,
    "fener": 3.5, "feneri": 2.6, "kafeneri": 0.0,
    "bahçe": 4.4, "çıktı": 5.2,
    "usulca": 2.4, "yavaş": 4.6, "ada": 4.0,
    "ihtimal": 4.1, "sessiz": 4.3,
    "tarçın": 3.1, "ragi": 0.0,
    "kıpır": 2.0, "yumuşak": 5.1,
    # simplemma fiilde çıplak gövde verir; gövde nadir, fiil yaygın.
    "kork": 3.2, "korkmak": 3.9, "korktu": 4.6, "korkma": 3.7,
    "burada": 5.3, "buradaydı": 2.9, "bura": 3.3,
}

LEMMAS = {"sabırla": "xyzq",  # anlamsız kök: Zipf kontrolü reddetmeli
          "korkma": "kork", "buradaydı": "bura"}


def analyzer():
    return r.Analyzer(zipf=lambda w: ZIPF.get(w, 0.0), lemmatize=lambda w: LEMMAS.get(w, w))


def line(band, text, words=(), source="b/x_v1"):
    return r.Line(band=band, source=source, text=text, words=list(words))


class TextTests(unittest.TestCase):
    def test_a_slot_and_its_suffix_become_a_mark_that_is_not_a_word(self):
        self.assertEqual(r.clean(" {{child.name}}'nin feneri"), f"{r.SLOT_MARK} feneri")
        self.assertEqual([t.surface for t in r.tokens("{{setting.name}}'ne doğru yürüdü.")], ["doğru", "yürüdü"])

    def test_a_slot_still_starts_a_sentence(self):
        self.assertEqual(r.sentences(r.clean("Kedi esnedi. {{child.name}} sessizdi.")),
                         ["Kedi esnedi.", f"{r.SLOT_MARK} sessizdi."])
        self.assertEqual(r.example([r.clean("{{child.name}} sessizdi.")]), "{…} sessizdi.")

    def test_turkish_lowercase(self):
        self.assertEqual(r.tr_lower("IŞIK İz"), "ışık iz")

    def test_sentences_keep_dialogue_together(self):
        self.assertEqual(r.sentences("Ragi durdu. — Bak, fener! dedi Ragi. Ada güldü."),
                         ["Ragi durdu.", "— Bak, fener! dedi Ragi.", "Ada güldü."])

    def test_a_long_first_sentence_gives_way_to_a_short_one(self):
        long = "Fener " + " ".join(["uzun"] * 60) + "."
        self.assertEqual(r.example([long, "Fener söndü."]), "Fener söndü.")
        self.assertEqual(r.example(["Fener yandı.", "Fener söndü."]), "Fener yandı.")


class RootTests(unittest.TestCase):
    def test_a_suffix_is_stripped_and_the_consonant_restored(self):
        self.assertEqual(analyzer().root("ağacın"), "ağaç")

    def test_a_lemma_far_rarer_than_the_word_is_rejected(self):
        self.assertEqual(analyzer().root("sabırla"), "sabır")

    def test_only_the_end_of_a_word_is_stripped(self):
        self.assertNotEqual(analyzer().root("kafeneri"), "fener")

    def test_an_unknown_word_stays_itself(self):
        self.assertEqual(analyzer().root("usulca"), "usulca")

    def test_a_verb_stem_is_shown_as_its_infinitive(self):
        self.assertEqual(analyzer().root("korkma"), "korkmak")

    def test_a_verb_is_judged_by_its_most_common_form(self):
        # "kork" 3.2 nadir görünür; ailenin en yaygın biçimi "korktu" 4.6.
        self.assertEqual(analyzer().family_zipf("korkma"), 4.6)

    def test_a_copula_is_stripped(self):
        self.assertEqual(analyzer().family_zipf("buradaydı"), 5.3)


class ReportTests(unittest.TestCase):
    def build(self, lines, glossary=(), names=()):
        return r.build_report(lines, list(glossary), set(names), analyzer())

    def roots(self, report, band):
        return [row.root for row in report.rare.get(band, [])]

    def test_catalog_names_and_mid_sentence_proper_nouns_are_dropped(self):
        rep = self.build([line("5-6", "Ada ile Ragi yürüdü. Sonra Tarçın usulca geldi.")], names={"Ragi"})
        roots = self.roots(rep, "5-6")
        self.assertIn("usulca", roots)
        self.assertNotIn("ragi", roots)
        self.assertNotIn("tarçın", roots)

    def test_a_capital_at_sentence_start_is_still_a_word(self):
        rep = self.build([line("3-4", "Yavaş yürüdü. Çok yavaş."), line("3-4", "Kıpır geldi.")])
        self.assertIn("kıpır", self.roots(rep, "3-4"))

    def test_the_threshold_depends_on_the_band(self):
        rep = self.build([line("3-4", "Ada feneri aldı."), line("7-8", "Ada feneri aldı.")])
        self.assertIn("fener", self.roots(rep, "3-4"))     # 3.5 < 4.0
        self.assertNotIn("fener", self.roots(rep, "7-8"))  # 3.5 ≥ 3.5
        self.assertTrue(r.is_rare(3.8, "3-4"))
        self.assertFalse(r.is_rare(3.8, "9-10"))

    def test_a_common_word_is_not_rare_for_the_youngest(self):
        # 22 Ekim: 3-4 eşiği 4.5'ten 4.0'a; bahçe, pencere, uyumak artık listede değil.
        self.assertEqual(r.THRESHOLDS["3-4"], 4.0)
        rep = self.build([line("3-4", "Ada bahçeye çıktı.")])
        self.assertNotIn("bahçe", self.roots(rep, "3-4"))  # 4.4

    def test_a_word_the_line_explains_is_not_unexplained(self):
        gloss = [r.GlossaryEntry(id="w56_usulca", term="usulca", forms=[], bands=["5-6"])]
        rep = self.build([line("5-6", "Kedi usulca geldi.", words=["w56_usulca"]),
                          line("5-6", "Ada feneri aldı.")], glossary=gloss)
        rows = {row.root: row for row in rep.rare["5-6"]}
        self.assertTrue(rows["usulca"].explained)
        self.assertFalse(rows["fener"].explained)
        self.assertEqual([row.root for row in rep.unexplained("5-6")], ["fener"])

    def test_common_verbs_and_copulas_are_not_rare(self):
        rep = self.build([line("3-4", '"Korkma," dedi. Ragi korktu. Ada buradaydı.')], names={"Ragi"})
        roots = self.roots(rep, "3-4")
        self.assertNotIn("korkmak", roots)
        self.assertNotIn("bura", roots)

    def test_a_row_keeps_count_sources_and_an_example(self):
        rep = self.build([line("5-6", "Ada feneri aldı.", source="a_v1"),
                          line("5-6", "Ada feneri yaktı.", source="b_v2")])
        row = next(row for row in rep.rare["5-6"] if row.root == "fener")
        self.assertEqual(row.count, 2)
        self.assertEqual(row.sources, ["a_v1", "b_v2"])
        self.assertEqual(row.example, "Ada feneri aldı.")

    def test_a_common_glossary_word_is_flagged_as_unnecessary(self):
        # sessiz 4.3: 9-10 için 3.0 + 1 = 4.0'ı geçer, 3-4 için 4.0 + 1 = 5.0'ı geçmez.
        gloss = [r.GlossaryEntry(id="w34_sessiz", term="sessiz", forms=[], bands=["3-4"]),
                 r.GlossaryEntry(id="w910_sessiz", term="sessiz", forms=[], bands=["9-10"]),
                 r.GlossaryEntry(id="w56_usulca", term="usulca", forms=[], bands=["5-6"])]
        rep = self.build([], glossary=gloss)
        self.assertEqual([(u.entry.id, u.band) for u in rep.unnecessary], [("w910_sessiz", "9-10")])

    def test_a_multiword_term_is_judged_by_its_rarest_word(self):
        entry = r.GlossaryEntry(id="w56_kipir", term="kıpır kıpır", forms=[], bands=["5-6"])
        self.assertEqual(analyzer().term_zipf(entry), 2.0)

    def test_an_explanation_outside_its_bands_is_reported(self):
        gloss = [r.GlossaryEntry(id="w56_ihtimal", term="ihtimal", forms=[], bands=["5-6"])]
        rep = self.build([line("3-4", "Bir ihtimal var.", words=["w56_ihtimal"], source="age3_v1"),
                          line("5-6", "Bir ihtimal var.", words=["w56_ihtimal"])], glossary=gloss)
        self.assertEqual([(o.entry.id, o.band, o.source) for o in rep.out_of_band],
                         [("w56_ihtimal", "3-4", "age3_v1")])

    def test_the_markdown_names_each_band_and_its_words(self):
        rep = self.build([line("3-4", "Ada usulca yürüdü.")])
        md = r.render_markdown(rep, date="2026-10-22")
        self.assertIn("## 3-4 yaş", md)
        self.assertIn("usulca", md)
        csv_text = r.render_csv(rep)
        self.assertTrue(csv_text.splitlines()[0].startswith("bant,kök,zipf"))
        self.assertIn("3-4,usulca,2.40", csv_text)


if __name__ == "__main__":
    unittest.main()
