"""MagicPaper Original: craft notes (cause → effect, endings) and book-research ↔ original-writer questions."""

from helpers import TestCase, analysed
from bookintel import craft, learning
from bookintel.schema import validate_analysis, validate_store

CRAFT = {
    "causal_chain": [
        {"cause": "the lantern goes out", "effect": "fox cannot find the path", "pages": [2], "driver": "nature"},
        {"cause": "fox remembers the fireflies", "effect": "fox follows them home", "pages": [5, 6], "driver": "protagonist"},
    ],
    "ending": {"type": "return_home", "answers": "will fox get home", "last_page_move": "fox asleep by the door",
               "returns_to_opening": True, "pages_after_resolution": 1},
    "writer_note": "the child's own memory of an earlier page solves the problem",
}


class Craft(TestCase):
    def setUp(self):
        super().setUp()
        self.wid = analysed(self.store, "fox_and_lantern.pages.txt", "Little Fox and the Lantern", "Ada Test")

    def _with_craft(self, block):
        a = self.store.latest("analysis", self.wid)
        a["craft"] = block
        self.store.put("analysis", a)
        return a

    def test_craft_is_optional_and_listed_for_backfill(self):
        self.assertEqual(craft.todo(self.store), [self.wid])
        self.assertEqual(validate_store(self.store), [])

    def test_craft_terms_are_closed_and_every_part_is_needed(self):
        bad = dict(CRAFT, ending=dict(CRAFT["ending"], type="happily_ever_after"))
        errors = validate_analysis(self._with_craft(bad))
        self.assertTrue(any("ending.type" in e for e in errors))
        missing = {"causal_chain": [], "ending": {}, "writer_note": ""}
        self.assertGreaterEqual(len(validate_analysis(self._with_craft(missing))), 5)

    def test_brief_groups_by_mode_and_writes_the_page(self):
        self._with_craft(CRAFT)
        self.assertEqual(validate_store(self.store), [])
        self.assertEqual(craft.todo(self.store), [])
        b = craft.brief(self.store)
        group = next(iter(b["groups"].values()))
        self.assertEqual(group["endings"]["return_home"], 1)
        self.assertEqual(group["last_driver"]["protagonist"], 1)
        self.assertEqual(group["returns"], 1)
        path = craft.write(self.store)
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
        self.assertIn("eve dönüş", text)
        self.assertIn("Little Fox and the Lantern", text)


class Dialogue(TestCase):
    def test_research_and_writer_ask_each_other(self):
        q = learning.ask(self.store, "original-writer", "How do bedtime books end?", "next tale is bedtime")
        self.assertEqual(learning.addressee(q), "book-research")
        r = learning.ask(self.store, "book-research", "Why does the lullaby tale end outside the clock?",
                         "corpus bedtime books return to the opening place", to="original-writer")
        self.assertEqual([x["request_id"] for x in learning.open_requests(self.store, to="original-writer")],
                         [r["request_id"]])
        self.assertEqual([x["request_id"] for x in learning.open_requests(self.store, to="book-research")],
                         [q["request_id"]])
        with self.assertRaises(learning.LearningError):      # only the addressee answers
            learning.answer(self.store, r["request_id"], "because", claims=[], works=[], by="book-research")
        with self.assertRaises(learning.LearningError):      # a tale is cited by its slug
            learning.answer(self.store, r["request_id"], "because", claims=[], works=[], tales=["Saat İçinde"])
        done = learning.answer(self.store, r["request_id"], "The mode asks for slowing down, not a return.",
                               claims=[], works=[], tales=["saatin-icindeki-ninni"])
        self.assertEqual(done["answer"]["evidence_strength"], "writer")
        self.assertEqual(done["history"][-1]["by"], "original-writer")
        self.assertEqual(validate_store(self.store), [])

    def test_only_book_research_asks_the_writer_and_nobody_asks_itself(self):
        with self.assertRaises(learning.LearningError):
            learning.ask(self.store, "story-engine", "Anything?", "because", to="original-writer")
        with self.assertRaises(learning.LearningError):
            learning.ask(self.store, "original-writer", "Anything?", "because", to="original-writer")
        with self.assertRaises(learning.LearningError):
            learning.ask(self.store, "book-research", "Anything?", "because", to="reader")
