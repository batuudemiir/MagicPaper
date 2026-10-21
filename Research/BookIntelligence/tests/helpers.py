"""Shared test scaffolding: temp workspaces, a network guard, fixture ingestion."""

from __future__ import annotations

import json
import os
import socket
import sys
import tempfile
import unittest
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOL_ROOT))

from bookintel import analyze, ingest  # noqa: E402
from bookintel.adapters.gutenberg import GutenbergAdapter  # noqa: E402
from bookintel.store import Store  # noqa: E402
from bookintel.workspace import Workspace  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"
os.environ["BOOKINTEL_NOW"] = "2026-10-08T09:00:00Z"


class _NoNetwork(socket.socket):
    def __init__(self, *args, **kwargs):
        raise AssertionError("unit tests must not open sockets — use a fixture fetcher")


class TestCase(unittest.TestCase):
    """Every test runs offline in a fresh workspace."""

    def setUp(self):
        self._socket = socket.socket
        socket.socket = _NoNetwork
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.ws = Workspace.under(self.root)
        self.store = Store(self.ws)

    def tearDown(self):
        socket.socket = self._socket
        self._tmp.cleanup()


def fixture_fetcher(url: str) -> bytes:
    """Recorded Project Gutenberg responses. Anything else fails the test."""
    import gzip
    if url == "https://www.gutenberg.org/robots.txt":
        return b"User-agent: *\nDisallow: /ebooks/search\n"
    if url == "https://www.gutenberg.org/cache/epub/feeds/pg_catalog.csv.gz":
        return gzip.compress((FIXTURES / "pg_catalog.csv").read_bytes())
    for gid in (9001, 9002):
        if url == f"https://www.gutenberg.org/cache/epub/{gid}/pg{gid}.rdf":
            return (FIXTURES / f"pg{gid}.rdf").read_bytes()
    if url == "https://www.gutenberg.org/cache/epub/9001/pg9001.txt":
        return (FIXTURES / "gutenberg_9001.txt").read_bytes()
    raise AssertionError(f"unexpected URL in test: {url}")


def gutenberg(cache_dir=None) -> GutenbergAdapter:
    return GutenbergAdapter(cache_dir, fetcher=fixture_fetcher)


OPEN_LICENSE = {"license": "CC BY 4.0", "attribution": "MagicPaper test fixture"}


def ingest_fixture(store: Store, name: str, title: str, creator: str, language: str = "en",
                   boundary: str = "original_scan", age_band: str = "5-6", **extra) -> dict:
    return ingest.ingest_manual(
        store, FIXTURES / name, url=f"https://example.org/{name}", rights="open_license",
        rights_detail=dict(OPEN_LICENSE), kind="authorized_full_text", tier="A", title=title,
        creators=[{"name": creator, "role": "author"}], language=language,
        page_boundary_source=boundary, year=2020, age_band=age_band, basis="publisher", **extra)


def fill_judgments(store: Store, work_id: str, version: str = "1", curve: list[int] | None = None,
                   mechanisms: list[str] | None = None, beats: list[tuple] | None = None,
                   humor_pages: set[int] | None = None) -> None:
    """Plays the analyst: writes plausible judgments into a scaffolded analysis."""
    key = f"{work_id}.v{version}"
    pages = store.get("pages", key)
    analysis = store.get("analysis", key)
    n = len(pages["pages"])
    curve = curve or [1 + (i * 3) // max(n - 1, 1) for i in range(n)]
    eligible = pages["page_boundary_source"] in ("original_scan", "publisher_layout")
    for i, page in enumerate(pages["pages"]):
        page.update({
            "beat": "HOOK" if i == 0 else ("ENDING" if i == n - 1 else "ESCALATION"),
            "emotion": "curiosity" if i < n - 1 else "relief",
            "emotion_intensity": curve[i],
            "label": "OBSERVED",
            "change": f"something changes on page {page['page']}",
            "humor": ["absurdity"] if humor_pages and page["page"] in humor_pages else [],
        })
        if eligible and i < n - 1:
            page["page_turn_mechanism"] = mechanisms or ["question"]
            page["page_turn_strength"] = 3
    beats = beats or [("HOOK", 1, 1), ("PROBLEM", 2, 2), ("SOLUTION", n - 1, n - 1), ("ENDING", n, n)]
    analysis.update({
        "summary_paraphrase": "A small creature meets a problem and solves it with help.",
        "beats": [{"beat": b, "start_page": s, "end_page": e, "intensity": 2, "function": "test"} for b, s, e in beats],
        "characters": [{"id": "hero", "name": "Hero", "role": "protagonist"},
                       {"id": "friend", "name": "Friend", "role": "helper"}],
        "protagonist_agency": 4,
        "repetition": [{"type": "refrain", "description": "a repeated line", "pages": [1, n],
                        "functions": ["rhythm", "comfort"], "effective": True, "why": "lands at the end"}],
        "child_appeal_heuristic": {"label": None, "scores": {"curiosity": 4, "humor": 2}, "rationale": "test"},
    })
    store.put("pages", pages)
    store.put("analysis", analysis)


def analysed(store: Store, name: str, title: str, creator: str, **kwargs) -> str:
    """Ingest a fixture, scaffold, fill and complete its analysis. Returns the work id."""
    fill = {k: kwargs.pop(k) for k in ("curve", "mechanisms", "beats", "humor_pages") if k in kwargs}
    result = ingest_fixture(store, name, title, creator, **kwargs)
    analyze.scaffold(store, result["work_id"])
    fill_judgments(store, result["work_id"], **fill)
    analyze.complete(store, result["work_id"], "1", "test-analyst")
    return result["work_id"]


def load(path: Path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)
