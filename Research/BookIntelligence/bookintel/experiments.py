"""Experiments and usage evidence: the half of the loop that comes back from children.

An experiment tests one exchange proposal as a sibling blueprint (the variant)
against an existing one (the control), in one age band and mode. It ships as a
remote content package (FAZ 15) — never as an engine change — so the arm is
derivable from `blueprintID` alone (no new data fields, no per-child
assignment) and removing it from the next package switches it off.

    draft ──preflight──▶ ready ──(owner publishes package)──▶ live ──evaluate──▶ concluded / stopped

Usage comes in as the server's aggregate document (`firebase/functions/src/
outcomes.js`): cells of blueprint × band × mode, never rows. The importer refuses
anything else. Results become `child_response` evidence on the proposal's claim,
and every result is scored against the prediction the research agent wrote
before launch — that score is how the agent learns how far to trust itself.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from . import runs
from .store import Store, dumps, write_if_changed

STATUSES = ("draft", "ready", "live", "stopped", "concluded")
DIRECTIONS = ("better", "worse", "same")
CELL_KEYS = {"blueprintID", "ageBand", "mode", "starts", "completions", "rereads", "abandoned", "readingDays"}
DOC_KEYS = {"schemaVersion", "periodStart", "periodEnd", "thresholds", "cells", "suppressedCells",
            "rejectedEvents", "weights", "createdAt"}
# Privacy floor agreed in the exchange (privacy-safety): a file below it is refused, not trimmed.
MIN_EVENTS, MIN_DAYS = 50, 7
# Evidence bar before a result counts.
MIN_STARTS_PER_ARM = 200
DECISIVE = 0.95
SAMPLES = 20000
# Modes where stopping early is not failure (catalog `storyModes[].success.abandonIsPenalty`).
CATALOG = Path("StoryEngine/Sources/StoryEngine/Resources/blueprints/pilot_library_v1.json")


class ExperimentError(RuntimeError):
    pass


# -- catalog (read-only) ------------------------------------------------------------------

def load_catalog(repo: Path, package: Path | None = None) -> dict:
    """Blueprints and mode rules from the bundled library, or from a FAZ 15 package."""
    documents = []
    if package:
        data = json.loads(Path(package).read_text(encoding="utf-8"))
        documents = [entry["content"] for entry in data.get("libraries", [])]
    else:
        documents = [json.loads((repo / CATALOG).read_text(encoding="utf-8"))]
    blueprints, modes = {}, {}
    for doc in documents:
        for bp in doc.get("blueprints", []):
            blueprints[bp["id"]] = bp
        for mode in doc.get("storyModes", []):
            modes[mode["mode"]] = mode
    return {"blueprints": blueprints, "modes": modes}


def abandon_is_penalty(catalog: dict, mode: str) -> bool:
    return (catalog["modes"].get(mode, {}).get("success") or {}).get("abandonIsPenalty", True)


# -- records ------------------------------------------------------------------------------

def _path(store: Store, eid: str) -> Path:
    return store.ws.data / "experiments" / f"{eid}.json"


def get(store: Store, eid: str) -> dict:
    path = _path(store, eid)
    if not path.exists():
        raise ExperimentError(f"no experiment {eid}")
    return json.loads(path.read_text(encoding="utf-8"))


def all_experiments(store: Store) -> list[dict]:
    root = store.ws.data / "experiments"
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(root.glob("*.json"))] if root.exists() else []


def _save(store: Store, record: dict) -> None:
    write_if_changed(_path(store, record["experiment_id"]), dumps(record))


def create(store: Store, *, experiment_id: str, proposal_id: str, control: str, variant: str, age_band: str,
           mode: str, direction: str, min_effect: float, confidence: float, rationale: str,
           bedtime_specific: bool = False) -> dict:
    """Register an experiment with the research agent's prediction, written BEFORE any data."""
    from . import exchange
    if not experiment_id.startswith("x_"):
        raise ExperimentError("experiment ids start with x_")
    if _path(store, experiment_id).exists():
        raise ExperimentError(f"{experiment_id} exists; predictions are not rewritten")
    if direction not in DIRECTIONS:
        raise ExperimentError(f"direction must be one of {DIRECTIONS}")
    if not 0.5 <= confidence <= 0.99:
        raise ExperimentError("confidence is the probability you give your direction: 0.5-0.99")
    thread = exchange.load(store, proposal_id)["thread"]
    record = {
        "experiment_id": experiment_id, "proposal_id": proposal_id, "claim_id": thread["claim_id"],
        "status": "draft", "control": control, "variant": variant, "age_band": age_band, "mode": mode,
        "bedtime_specific": bedtime_specific,
        "prediction": {"direction": direction, "min_effect": min_effect, "confidence": confidence,
                       "rationale": rationale, "by": "book-research", "at": runs.now()},
        "preflight": None, "result": None, "history": [{"status": "draft", "at": runs.now()}],
    }
    _save(store, record)
    return record


def preflight(store: Store, experiment_id: str, package: Path | None = None) -> list[str]:
    """Everything that must be true before the owner publishes the arm. Empty list = ready."""
    from . import exchange
    record = get(store, experiment_id)
    problems = []
    thread = exchange.load(store, record["proposal_id"])
    decision = thread["decision"] or {}
    if decision.get("verdict") != "approved":
        problems.append("the product owner has not approved the proposal (exchange decide … --verdict approved)")
    if (thread["thread"].get("recommendation") or {}).get("action") != "experiment":
        problems.append("the exchange did not recommend an experiment")
    if (thread["safety"] or {}).get("verdict") != "pass":
        problems.append("privacy-safety has not passed this proposal")
    catalog = load_catalog(store.ws.repo, package)
    control, variant = catalog["blueprints"].get(record["control"]), catalog["blueprints"].get(record["variant"])
    if control is None:
        problems.append(f"control blueprint {record['control']} not in the catalog")
    if variant is None:
        problems.append(f"variant blueprint {record['variant']} not in the catalog"
                        + ("" if package else " (pass --package with the remote package that carries it)"))
    if control and variant:
        for field in ("ageRange", "pageCount", "family"):
            if control.get(field) != variant.get(field):
                problems.append(f"control and variant differ in {field}: {control.get(field)} vs {variant.get(field)}")
        if control.get("ageRange") != record["age_band"]:
            problems.append(f"age band {record['age_band']} is not the blueprints' {control.get('ageRange')}")
    mode = catalog["modes"].get(record["mode"])
    if mode is None:
        problems.append(f"mode {record['mode']} not in the catalog")
    elif control and control.get("family") not in mode.get("families", []):
        problems.append(f"family {control.get('family')} is not served in mode {record['mode']}")
    if record["mode"] == "bedtime" and not record["bedtime_specific"]:
        problems.append("bedtime is excluded unless the proposal is bedtime-specific (privacy-safety condition)")
    record["preflight"] = {"problems": problems, "at": runs.now(), "package": str(package) if package else None}
    if not problems and record["status"] == "draft":
        record["status"] = "ready"
        record["history"].append({"status": "ready", "at": runs.now()})
    _save(store, record)
    return problems


def mark(store: Store, experiment_id: str, status: str, note: str) -> dict:
    """The owner records what was published: live (package out) or stopped (pulled)."""
    record = get(store, experiment_id)
    allowed = {"live": ("ready",), "stopped": ("live", "ready")}
    if status not in allowed or record["status"] not in allowed[status]:
        raise ExperimentError(f"{experiment_id}: cannot go from {record['status']} to {status}")
    record["status"] = status
    record["history"].append({"status": status, "note": note, "at": runs.now()})
    _save(store, record)
    return record


# -- usage import -------------------------------------------------------------------------

def import_usage(store: Store, path: Path) -> str:
    """Accept one aggregate document. Refuses rows, unknown keys, or cells under the privacy floor."""
    doc = json.loads(Path(path).read_text(encoding="utf-8"))
    unknown = set(doc) - DOC_KEYS
    if unknown:
        raise ExperimentError(f"unexpected keys {sorted(unknown)} — only server aggregates are accepted")
    if doc.get("schemaVersion") != 1 or not isinstance(doc.get("cells"), list):
        raise ExperimentError("not an outcome aggregate (schemaVersion 1 with cells)")
    thresholds = doc.get("thresholds") or {}
    if thresholds.get("minEvents", 0) < MIN_EVENTS or thresholds.get("minDays", 0) < MIN_DAYS:
        raise ExperimentError(f"aggregated below the privacy floor ({MIN_EVENTS} readings, {MIN_DAYS} days)")
    for cell in doc["cells"]:
        if set(cell) - CELL_KEYS:
            raise ExperimentError(f"cell carries {sorted(set(cell) - CELL_KEYS)} — refusing the file")
        if cell["starts"] < MIN_EVENTS or cell["readingDays"] < MIN_DAYS:
            raise ExperimentError(f"cell {cell['blueprintID']} is under the privacy floor — refusing the file")
    period = doc["periodEnd"]
    record = {k: doc[k] for k in ("schemaVersion", "periodStart", "periodEnd", "thresholds", "cells",
                                  "suppressedCells", "rejectedEvents") if k in doc}
    record["imported_at"] = runs.now()
    write_if_changed(store.ws.data / "usage" / f"{period}.json", dumps(record))
    runs.log(store, "sources_added", f"usage:{period}")
    return period


def usage_periods(store: Store) -> list[dict]:
    root = store.ws.data / "usage"
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(root.glob("*.json"))] if root.exists() else []


# -- evaluation ---------------------------------------------------------------------------

def _arm(periods: list[dict], blueprint: str, band: str, mode: str, since: str | None) -> dict:
    totals = {"starts": 0, "completions": 0, "rereads": 0}
    for period in periods:
        # Only periods that started after the arm went live: before that the variant did not
        # exist, and counting the control's earlier readings would make the arms unequal.
        if since and period["periodStart"] < since:
            continue
        for cell in period["cells"]:
            if (cell["blueprintID"], cell["ageBand"], cell["mode"]) == (blueprint, band, mode):
                for key in totals:
                    totals[key] += cell[key]
    return totals


def _successes(arm: dict, penalty: bool) -> int:
    # Same rule as the server weight: where abandoning is not failure, only rereads count.
    return min(arm["completions"] if penalty else arm["rereads"], arm["starts"])


def compare(control: dict, variant: dict, penalty: bool, seed: int = 7) -> dict:
    """Beta-binomial comparison. Deterministic: fixed seed, fixed sample count."""
    sc, sv = _successes(control, penalty), _successes(variant, penalty)
    nc, nv = control["starts"], variant["starts"]
    rng = random.Random(seed)
    wins = sum(rng.betavariate(1 + sv, 1 + nv - sv) > rng.betavariate(1 + sc, 1 + nc - sc) for _ in range(SAMPLES))
    rate_c, rate_v = (1 + sc) / (2 + nc), (1 + sv) / (2 + nv)
    return {"metric": "completion rate" if penalty else "reread rate",
            "control": {**control, "rate": round(rate_c, 4)}, "variant": {**variant, "rate": round(rate_v, 4)},
            "difference": round(rate_v - rate_c, 4), "p_variant_better": round(wins / SAMPLES, 4)}


def evaluate(store: Store) -> list[dict]:
    """Score every live experiment against imported usage; conclude when the evidence is decisive."""
    catalog = load_catalog(store.ws.repo)
    periods = usage_periods(store)
    changes = []
    for record in all_experiments(store):
        if record["status"] != "live":
            continue
        since = next((h["at"][:10] for h in record["history"] if h["status"] == "live"), None)
        args = (record["age_band"], record["mode"], since)
        control, variant = _arm(periods, record["control"], *args), _arm(periods, record["variant"], *args)
        if min(control["starts"], variant["starts"]) < MIN_STARTS_PER_ARM:
            record["result"] = {"state": "collecting", "control_starts": control["starts"],
                                "variant_starts": variant["starts"], "at": runs.now()}
            _save(store, record)
            continue
        outcome = compare(control, variant, abandon_is_penalty(catalog, record["mode"]))
        p = outcome["p_variant_better"]
        min_effect = record["prediction"]["min_effect"]
        if p >= DECISIVE and outcome["difference"] >= min_effect:
            observed = "better"
        elif p <= 1 - DECISIVE and -outcome["difference"] >= min_effect:
            observed = "worse"
        elif abs(outcome["difference"]) < min_effect and 0.2 <= p <= 0.8:
            observed = "same"
        else:
            observed = None
        record["result"] = {"state": "concluded" if observed else "inconclusive", "observed": observed,
                            **outcome, "at": runs.now()}
        if observed:
            record["status"] = "concluded"
            record["history"].append({"status": "concluded", "observed": observed, "at": runs.now()})
            _attach_to_claim(store, record)
        _save(store, record)
        changes.append({"experiment_id": record["experiment_id"], "state": record["result"]["state"],
                        "observed": observed, "p_variant_better": p})
    return changes


def _attach_to_claim(store: Store, record: dict) -> None:
    claim = store.get("claim", record["claim_id"])
    if claim is None:
        return
    entry = {"experiment_id": record["experiment_id"], "observed": record["result"]["observed"],
             "metric": record["result"]["metric"], "difference": record["result"]["difference"],
             "p_variant_better": record["result"]["p_variant_better"],
             "age_band": record["age_band"], "mode": record["mode"]}
    experiments = [e for e in claim.get("experiments", []) if e["experiment_id"] != record["experiment_id"]]
    claim["experiments"] = experiments + [entry]
    if entry["observed"] == "better" and "child_response" not in claim["layers"]:
        claim["layers"].append("child_response")
    store.put("claim", claim)


# -- calibration: how far the research agent should trust itself ---------------------------

def calibration(store: Store) -> dict:
    resolved = []
    for record in all_experiments(store):
        result = record.get("result") or {}
        if record["status"] != "concluded" or not result.get("observed"):
            continue
        prediction = record["prediction"]
        hit = prediction["direction"] == result["observed"]
        resolved.append({"experiment_id": record["experiment_id"], "predicted": prediction["direction"],
                         "observed": result["observed"], "confidence": prediction["confidence"], "hit": hit,
                         "brier": round((prediction["confidence"] - (1.0 if hit else 0.0)) ** 2, 4)})
    n = len(resolved)
    summary = {"resolved": n, "predictions": resolved}
    if n:
        hit_rate = sum(r["hit"] for r in resolved) / n
        mean_conf = sum(r["confidence"] for r in resolved) / n
        summary.update({
            "hit_rate": round(hit_rate, 3), "mean_confidence": round(mean_conf, 3),
            "brier": round(sum(r["brier"] for r in resolved) / n, 4),
            "advice": ("overconfident: lower stated confidence" if mean_conf - hit_rate > 0.1 else
                       "underconfident: predictions can be bolder" if hit_rate - mean_conf > 0.1 else
                       "calibrated within ±0.1") + (" (fewer than 5 results: treat as anecdote)" if n < 5 else ""),
        })
    store.write_index("calibration", summary)
    return summary
