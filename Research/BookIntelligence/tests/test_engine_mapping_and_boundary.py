"""Engine vocabulary sync, and the subsystem's write boundary."""

import io
import re
from contextlib import redirect_stdout, redirect_stderr

from helpers import FIXTURES, TestCase, TOOL_ROOT
from bookintel.vocab import engine_mapping, terms
from bookintel.workspace import REPO_ROOT

import book_agent


def swift_raw_values(path, enum_name):
    text = (REPO_ROOT / path).read_text(encoding="utf-8")
    body = text[text.index(f"enum {enum_name}"):]
    body = body[:body.index("\n}\n")]
    values = set()
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("case ") or "(" in line or ":" in line:
            continue
        for part in line[5:].split(","):
            part = part.strip()
            match = re.match(r'(\w+)\s*=\s*"([^"]+)"', part)
            values.add(match.group(2) if match else part)
    return values


class EngineMapping(TestCase):
    def test_beat_targets_exist_in_storybeat(self):
        engine = swift_raw_values(engine_mapping()["engine_files"]["beats"], "StoryBeat")
        self.assertIn("warm_close", engine)
        for research, targets in engine_mapping()["beats"].items():
            self.assertIn(research, terms("beats"))
            self.assertTrue(set(targets) <= engine, f"{research}: {set(targets) - engine} not in StoryBeat")

    def test_emotion_targets_exist_in_emotional_state(self):
        engine = swift_raw_values(engine_mapping()["engine_files"]["emotions"], "EmotionalState")
        self.assertIn("calm", engine)
        for research, targets in engine_mapping()["emotions"].items():
            self.assertIn(research, terms("emotions"))
            self.assertTrue(set(targets) <= engine, f"{research}: {set(targets) - engine} not in EmotionalState")

    def test_every_research_beat_and_emotion_is_mapped(self):
        self.assertEqual(set(engine_mapping()["beats"]), terms("beats"))
        self.assertEqual(set(engine_mapping()["emotions"]), terms("emotions"))


def snapshot(*roots):
    files = {}
    for root in roots:
        if root.exists():
            for path in root.rglob("*"):
                if path.is_file():
                    files[path] = path.stat().st_mtime_ns
    return files


class Boundary(TestCase):
    def cli(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = book_agent.main(list(argv), workspace=self.ws)
        return code, out.getvalue(), err.getvalue()

    def test_full_cli_flow_writes_only_inside_its_workspace(self):
        watched = (REPO_ROOT / "StoryEngine", REPO_ROOT / "Content", REPO_ROOT / "docs", TOOL_ROOT / "data",
                   REPO_ROOT / "MagicPaper")
        before = snapshot(*watched)
        self.assertEqual(self.cli("run", "start", "--goal", "boundary test", "--strategy", "fixtures")[0], 0)
        code, out, err = self.cli("ingest", "file", str(FIXTURES / "fox_and_lantern.pages.txt"),
                                  "--url", "https://example.org/fox", "--rights", "open_license",
                                  "--license", "CC BY 4.0", "--attribution", "fixture",
                                  "--title", "Little Fox and the Lantern", "--creator", "Ada Test",
                                  "--lang", "en", "--boundary", "original_scan", "--age-band", "5-6",
                                  "--age-basis", "publisher")
        self.assertEqual(code, 0, err)
        wid = "w_little_fox_and_the_lantern_test"
        self.assertIn(wid, out)
        self.assertEqual(self.cli("analyze", wid)[0], 0)
        code, _, err = self.cli("analyze", wid, "--complete", "--analyst", "x")
        self.assertEqual(code, 2)
        self.assertIn("page judgments missing", err)
        for command in (("status",), ("gaps",), ("validate",), ("compare", "--age", "5-6", "--write"),
                        ("insights",), ("deep-dive", wid, "--write"), ("run", "finish", "--summary", "ok"),
                        ("report",)):
            code, _, err = self.cli(*command)
            self.assertEqual(code, 0, f"{command}: {err}")
        self.assertEqual(before, snapshot(*watched), "the CLI wrote outside its workspace")
        written = {p.relative_to(self.root).parts[0] for p in self.root.rglob("*") if p.is_file()}
        self.assertEqual(written, {"data", "cache", "docs"})
        self.assertTrue((self.ws.docs / "BOOK_CORPUS.md").exists())
        self.assertTrue((self.ws.docs / "MAGICPAPER_STORY_INSIGHTS.md").exists())
