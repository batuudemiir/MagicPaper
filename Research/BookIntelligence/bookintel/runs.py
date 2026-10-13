"""Research runs: what one session set out to do, what it found, what changed.

A run snapshots claim confidences when it starts, so finishing it can report
which confidences moved. Commands that add data attach it to the open run.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone

from .store import Store


def now() -> str:
    """UTC timestamp; BOOKINTEL_NOW pins it for deterministic tests."""
    return os.environ.get("BOOKINTEL_NOW") or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def today() -> str:
    return now()[:10]


def open_run(store: Store) -> dict | None:
    runs = [r for r in store.all("run") if r.get("status") == "open"]
    return runs[0] if runs else None


def start(store: Store, goal: str, strategy: list[str]) -> dict:
    if open_run(store):
        raise RuntimeError(f"run {open_run(store)['run_id']} is still open — finish it first")
    stamp = now()
    run = {
        "run_id": "r_" + stamp.replace("-", "").replace(":", "").replace("T", "_").rstrip("Z"),
        "status": "open",
        "started_at": stamp,
        "finished_at": None,
        "goal": goal,
        "query_strategy": strategy,
        "queries": [],
        "candidates": [],
        "sources_added": [],
        "works_added": [],
        "editions_added": [],
        "analyses_completed": [],
        "failures": [],
        "claims_snapshot_start": {c["claim_id"]: (c.get("computed") or {}).get("confidence")
                                  for c in store.all("claim")},
        "confidence_changes": [],
        "new_claims": [],
        "summary": None,
    }
    store.put("run", run)
    return run


def log(store: Store, field: str, item) -> None:
    """Append to the open run, once. No open run → nothing is recorded."""
    run = open_run(store)
    if run is None:
        return
    if item not in run[field]:
        run[field].append(item)
        store.put("run", run)


def finish(store: Store, summary: str | None = None) -> dict:
    run = open_run(store)
    if run is None:
        raise RuntimeError("no open run")
    before = run["claims_snapshot_start"]
    for claim in store.all("claim"):
        cid = claim["claim_id"]
        current = (claim.get("computed") or {}).get("confidence")
        if cid not in before:
            run["new_claims"].append(cid)
        elif before[cid] != current:
            run["confidence_changes"].append({"claim_id": cid, "from": before[cid], "to": current})
    run["status"] = "closed"
    run["finished_at"] = now()
    run["summary"] = summary
    store.put("run", run)
    return run
