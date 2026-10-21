"""Where the tool reads and writes. Every path the package touches comes from here.

Tests build a Workspace in a temp directory; the boundary test checks that no
command writes outside a workspace's roots.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

TOOL_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = TOOL_ROOT.parent.parent


@dataclass(frozen=True)
class Workspace:
    data: Path
    cache: Path
    docs: Path
    repo: Path = REPO_ROOT

    @classmethod
    def default(cls) -> "Workspace":
        return cls(
            data=Path(os.environ.get("BOOKINTEL_DATA", TOOL_ROOT / "data")),
            cache=Path(os.environ.get("BOOKINTEL_CACHE", TOOL_ROOT / "cache")),
            docs=Path(os.environ.get("BOOKINTEL_DOCS", REPO_ROOT / "docs" / "research")),
        )

    @classmethod
    def under(cls, root: Path) -> "Workspace":
        return cls(data=root / "data", cache=root / "cache", docs=root / "docs")

    def writable_roots(self) -> tuple[Path, ...]:
        return (self.data, self.cache, self.docs)
