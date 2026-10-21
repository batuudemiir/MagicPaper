"""A file a person obtained legitimately, registered with its provenance.

For page-structured material no adapter fetches: a scan of a public-domain
edition, a CC-licensed picture book downloaded by hand, a licensed text. The
person states the rights; the validator then holds the record to them.
"""

from __future__ import annotations

import hashlib
import re
from pathlib import Path


def edition_id_for(path: Path, explicit: str | None = None) -> str:
    if explicit:
        return explicit if explicit.startswith("e_") else f"e_{explicit}"
    name = path.name.lower()
    for suffix in (".pages.txt", ".pages", ".txt", ".md"):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
            break
    stem = re.sub(r"[^0-9a-z]+", "_", name).strip("_")
    return f"e_manual_{stem}"


def sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()
