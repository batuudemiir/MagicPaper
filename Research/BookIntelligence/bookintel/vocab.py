"""Loads the closed vocabularies. One place, so a typo in a record is an error."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

VOCAB_DIR = Path(__file__).resolve().parent / "vocab"


@lru_cache(maxsize=None)
def _load(name: str) -> dict:
    with open(VOCAB_DIR / name, encoding="utf-8") as handle:
        return json.load(handle)


def vocab() -> dict:
    return _load("research_vocab.json")


def engine_mapping() -> dict:
    return _load("engine_mapping.json")


def research_plan() -> dict:
    return _load("research_plan.json")


def terms(key: str) -> set[str]:
    return set(vocab()[key])
