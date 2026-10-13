"""The knowledge base on disk: one JSON file per record.

One file per record keeps diffs reviewable and lets two sessions add different
books without touching the same file. Writes are stable (same record → same
bytes), so re-running a command on unchanged data produces no diff — that is
how "a new run must not duplicate data" is checked.
"""

from __future__ import annotations

import json
from pathlib import Path

from .workspace import Workspace

KINDS = {
    "work": ("works", "work_id"),
    "edition": ("editions", "edition_id"),
    "source": ("sources", "source_id"),
    "analysis": ("analyses", None),
    "pages": ("pages", None),
    "claim": ("claims", "claim_id"),
    "run": ("runs", "run_id"),
}


def dumps(record) -> str:
    return json.dumps(record, indent=2, ensure_ascii=False) + "\n"


def write_if_changed(path: Path, text: str) -> bool:
    if path.exists() and path.read_text(encoding="utf-8") == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return True


def analysis_key(work_id: str, version: str) -> str:
    return f"{work_id}.v{version}"


class Store:
    def __init__(self, workspace: Workspace):
        self.ws = workspace

    # -- paths ---------------------------------------------------------------
    def _dir(self, kind: str) -> Path:
        return self.ws.data / KINDS[kind][0]

    def path(self, kind: str, key: str) -> Path:
        return self._dir(kind) / f"{key}.json"

    def _key(self, kind: str, record: dict) -> str:
        field = KINDS[kind][1]
        if field:
            return record[field]
        return analysis_key(record["work_id"], record["analysis_version"])

    # -- records -------------------------------------------------------------
    def get(self, kind: str, key: str) -> dict | None:
        path = self.path(kind, key)
        if not path.exists():
            return None
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)

    def put(self, kind: str, record: dict) -> bool:
        return write_if_changed(self.path(kind, self._key(kind, record)), dumps(record))

    def all(self, kind: str) -> list[dict]:
        directory = self._dir(kind)
        if not directory.exists():
            return []
        records = []
        for path in sorted(directory.glob("*.json")):
            with open(path, encoding="utf-8") as handle:
                records.append(json.load(handle))
        return records

    def latest(self, kind: str, work_id: str) -> dict | None:
        """Newest analysis/pages record of a work (versions compared numerically)."""
        candidates = [r for r in self.all(kind) if r.get("work_id") == work_id]
        if not candidates:
            return None
        return max(candidates, key=lambda r: _version_tuple(r.get("analysis_version", "0")))

    # -- review list (ambiguous dedup) ----------------------------------------
    def review_path(self) -> Path:
        return self.ws.data / "review" / "dedup.json"

    def add_review(self, item: dict) -> bool:
        items = self.review_items()
        if item in items:
            return False
        items.append(item)
        return write_if_changed(self.review_path(), dumps(items))

    def review_items(self) -> list[dict]:
        path = self.review_path()
        if not path.exists():
            return []
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)

    # -- cache ---------------------------------------------------------------
    def cache_path(self, *parts: str) -> Path:
        return self.ws.cache.joinpath(*parts)

    def segmented(self, edition_id: str) -> dict | None:
        path = self.cache_path("segmented", f"{edition_id}.json")
        if not path.exists():
            return None
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)

    def put_segmented(self, edition_id: str, record: dict) -> bool:
        return write_if_changed(self.cache_path("segmented", f"{edition_id}.json"), dumps(record))

    # -- generated index -------------------------------------------------------
    def write_index(self, name: str, record) -> bool:
        return write_if_changed(self.ws.data / "index" / f"{name}.json", dumps(record))


def _version_tuple(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in str(version).split(".") if part.isdigit()) or (0,)
