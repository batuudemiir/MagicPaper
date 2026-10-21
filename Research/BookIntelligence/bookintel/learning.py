"""How the research agent improves itself: questions from other agents, blind re-reads, method rules.

Three loops, each leaving a record the weekly page reports:

    data/requests/<q_id>.json      another agent (or the owner) asks; book-research answers with evidence
    data/rechecks/<work>.<n>.json  a complete book read again without its first analysis; the
                                   agreement per judgment field is the agent's measured reliability
    data/method/rules.json         a mistake someone caught becomes a rule `validate` enforces,
                                   so the same mistake cannot pass twice

Reliability feeds confidence: a claim that rests on a judgment field the agent reads
inconsistently cannot rise above LOW (see confidence.compute).

Nothing here touches the engine or the app; the human gate stays in exchange.decide.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from . import runs
from .analyze import PAGE_JUDGMENTS
from .store import Store, dumps, write_if_changed

ASKERS = {"story-engine", "content-library", "privacy-safety", "reader", "parent-ux", "ui-agent",
          "illustration-system", "design-system", "reviewer", "human"}
REQUEST_STATUSES = ("open", "researching", "answered", "declined")


class LearningError(RuntimeError):
    pass


def _read(path: Path):
    if not path.exists():
        return None
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def _slug(text: str, limit: int = 40) -> str:
    table = str.maketrans("çğıöşüÇĞİÖŞÜ", "cgiosuCGIOSU")
    words = re.sub(r"[^a-z0-9]+", "_", text.translate(table).lower()).strip("_")
    return words[:limit].rstrip("_") or "soru"


# -- 1. questions from other agents --------------------------------------------------------

def _requests_dir(store: Store) -> Path:
    return store.ws.data / "requests"


def ask(store: Store, agent: str, question: str, why: str, *, target: str | None = None,
        age_band: str | None = None) -> dict:
    if agent not in ASKERS:
        raise LearningError(f"{agent!r} cannot ask; askers: {', '.join(sorted(ASKERS))}")
    if not question.strip() or not why.strip():
        raise LearningError("a request needs a question and why it matters to your work")
    base, n = "q_" + _slug(question), 1
    rid = base
    while (_requests_dir(store) / f"{rid}.json").exists():
        n += 1
        rid = f"{base}_{n}"
    record = {"request_id": rid, "from": agent, "question": question.strip(), "why": why.strip(),
              "target": target, "age_band": age_band, "status": "open", "answer": None,
              "history": [{"status": "open", "by": agent, "at": runs.now()}], "created_at": runs.now()}
    write_if_changed(_requests_dir(store) / f"{rid}.json", dumps(record))
    return record


def get_request(store: Store, rid: str) -> dict:
    record = _read(_requests_dir(store) / f"{rid}.json")
    if record is None:
        raise LearningError(f"no request {rid}")
    return record


def all_requests(store: Store) -> list[dict]:
    folder = _requests_dir(store)
    return [_read(p) for p in sorted(folder.glob("q_*.json"))] if folder.exists() else []


def open_requests(store: Store) -> list[dict]:
    """Oldest first: the research agent works the queue before its own gaps."""
    rows = [r for r in all_requests(store) if r["status"] in ("open", "researching")]
    return sorted(rows, key=lambda r: r["created_at"])


def _move(store: Store, record: dict, status: str, by: str, note: str = "") -> dict:
    record["status"] = status
    record["history"].append({"status": status, "by": by, "at": runs.now(), **({"note": note} if note else {})})
    write_if_changed(_requests_dir(store) / f"{record['request_id']}.json", dumps(record))
    return record


def take(store: Store, rid: str) -> dict:
    record = get_request(store, rid)
    if record["status"] != "open":
        raise LearningError(f"{rid} is {record['status']}")
    return _move(store, record, "researching", "book-research")


def answer(store: Store, rid: str, text: str, *, claims: list[str], works: list[str]) -> dict:
    """An answer cites what it rests on; 'not enough evidence yet' is an answer too (no citations)."""
    record = get_request(store, rid)
    if record["status"] not in ("open", "researching"):
        raise LearningError(f"{rid} is {record['status']}")
    if not text.strip():
        raise LearningError("an answer needs text")
    known_claims = {c["claim_id"] for c in store.all("claim")}
    known_works = {w["work_id"] for w in store.all("work")}
    bad = [c for c in claims if c not in known_claims] + [w for w in works if w not in known_works]
    if bad:
        raise LearningError(f"unknown evidence: {bad}")
    record["answer"] = {"text": text.strip(), "claims": claims, "works": works,
                        "evidence_strength": _strength(store, claims), "at": runs.now()}
    return _move(store, record, "answered", "book-research")


def decline(store: Store, rid: str, reason: str) -> dict:
    record = get_request(store, rid)
    if not reason.strip():
        raise LearningError("say why the question cannot be researched (e.g. no legal source)")
    return _move(store, record, "declined", "book-research", reason.strip())


def _strength(store: Store, claims: list[str]) -> str:
    levels = ["HYPOTHESIS", "LOW", "MEDIUM", "HIGH"]
    found = [(store.get("claim", c) or {}).get("computed") or {} for c in claims]
    best = [f.get("confidence") for f in found if f.get("confidence") in levels]
    return max(best, key=levels.index) if best else "none"


# -- 2. blind re-reads: how consistently the agent judges ---------------------------------

COMPARED = ("beat", "emotion", "emotion_intensity", "page_turn_mechanism", "humor", "repetition",
            "only_in_image")
MIN_PAGES = 20          # judgments compared before a field is called reliable or not
RELIABLE = 0.7
UNRELIABLE = 0.6


def _rechecks_dir(store: Store) -> Path:
    return store.ws.data / "rechecks"


def all_rechecks(store: Store) -> list[dict]:
    folder = _rechecks_dir(store)
    return [_read(p) for p in sorted(folder.glob("*.json"))] if folder.exists() else []


def _complete_works(store: Store) -> list[str]:
    return sorted({a["work_id"] for a in store.all("analysis") if a.get("status") == "complete"})


def pick(store: Store) -> str | None:
    """The complete book re-read least often, oldest re-read first."""
    done: dict[str, list[str]] = {}
    for r in all_rechecks(store):
        done.setdefault(r["work_id"], []).append(r["started_at"])
    works = _complete_works(store)
    if not works:
        return None
    return min(works, key=lambda w: (len(done.get(w, [])), max(done.get(w, [""])), w))


def _blank(page: dict) -> dict:
    """The page as the reader sees it, with every judgment emptied."""
    keep = {k: page.get(k) for k in ("page", "spread", "text", "source_leaves")}
    illustration = page.get("illustration") or {}
    keep.update({field: None for field in PAGE_JUDGMENTS})
    keep.update({"page_turn_mechanism": [], "humor": [], "repetition": [],
                 "illustration": {"available": illustration.get("available", False), "only_in_image": None}})
    return keep


def start(store: Store, work_id: str) -> Path:
    if work_id not in _complete_works(store):
        raise LearningError(f"{work_id}: only a complete analysis can be re-read")
    pending = [r for r in all_rechecks(store) if r["work_id"] == work_id and r["status"] == "blind"]
    if pending:
        raise LearningError(f"{work_id}: a re-read is already open ({pending[0]['recheck_id']})")
    original = store.latest("pages", work_id)
    n = sum(1 for r in all_rechecks(store) if r["work_id"] == work_id) + 1
    rid = f"{work_id}.{n}"
    record = {"recheck_id": rid, "work_id": work_id, "against_version": original["analysis_version"],
              "status": "blind", "started_at": runs.now(),
              "instructions": "Read the book again from the page images and this text only. Do not open "
                              "data/pages/ or data/analyses/ for this work until `recheck score`.",
              "pages": [_blank(p) for p in original["pages"]], "score": None}
    path = _rechecks_dir(store) / f"{rid}.json"
    write_if_changed(path, dumps(record))
    return path


def _value(page: dict, field: str):
    if field == "only_in_image":
        return bool((page.get("illustration") or {}).get("only_in_image"))
    if field in ("humor", "repetition"):
        return bool(page.get(field))
    return page.get(field)


def _agree(field: str, a, b) -> bool:
    if field == "emotion_intensity":
        return abs(int(a) - int(b)) <= 1
    if field == "page_turn_mechanism":
        sa, sb = set(a or []), set(b or [])
        if not sa and not sb:
            return True
        return len(sa & sb) / len(sa | sb) >= 0.5
    return a == b


def score(store: Store, work_id: str) -> dict:
    """Compare the blind re-read with the first analysis. Final: a scored re-read is never rescored."""
    open_ = [r for r in all_rechecks(store) if r["work_id"] == work_id and r["status"] == "blind"]
    if not open_:
        raise LearningError(f"{work_id}: no open re-read (start one with `recheck start`)")
    record = open_[0]
    missing = [f"p{p['page']}" for p in record["pages"] if any(p.get(f) in (None, "") for f in PAGE_JUDGMENTS)]
    if missing:
        raise LearningError(f"{record['recheck_id']}: judgments missing on {', '.join(missing[:8])}")
    original = {p["page"]: p for p in (store.get("pages", f"{work_id}.v{record['against_version']}") or {})["pages"]}
    fields: dict[str, dict] = {}
    for page in record["pages"]:
        first = original.get(page["page"])
        if first is None:
            continue
        for field in COMPARED:
            if field == "page_turn_mechanism" and not (first.get(field) or page.get(field)):
                continue  # boundary not usable for page turns in either reading
            if field == "only_in_image" and not (page.get("illustration") or {}).get("available"):
                continue
            a, b = _value(first, field), _value(page, field)
            if a is None or b is None:
                continue
            slot = fields.setdefault(field, {"agree": 0, "total": 0, "differ": []})
            slot["total"] += 1
            if _agree(field, a, b):
                slot["agree"] += 1
            else:
                slot["differ"].append(page["page"])
    record["score"] = {f: {**v, "rate": round(v["agree"] / v["total"], 3)} for f, v in fields.items()}
    record["status"] = "scored"
    record["scored_at"] = runs.now()
    write_if_changed(_rechecks_dir(store) / f"{record['recheck_id']}.json", dumps(record))
    runs.log(store, "rechecks_scored", record["recheck_id"])
    return record


def reliability(store: Store) -> dict:
    """Agreement per judgment field across every scored re-read."""
    totals: dict[str, list[int]] = {}
    for r in all_rechecks(store):
        for field, s in (r.get("score") or {}).items():
            t = totals.setdefault(field, [0, 0])
            t[0] += s["agree"]
            t[1] += s["total"]
    out = {}
    for field, (agree, total) in sorted(totals.items()):
        rate = round(agree / total, 3) if total else 0.0
        state = ("measuring" if total < MIN_PAGES else
                 "reliable" if rate >= RELIABLE else "unreliable" if rate < UNRELIABLE else "uncertain")
        out[field] = {"agree": agree, "total": total, "rate": rate, "state": state}
    return out


def unreliable_fields(store: Store) -> set[str]:
    return {f for f, v in reliability(store).items() if v["state"] == "unreliable"}


# -- 3. method rules: a caught mistake becomes a check --------------------------------------

RULE_KINDS = ("forbid", "require_when", "note")
RULE_SCOPES = ("claim", "turn")


def _rules_path(store: Store) -> Path:
    return store.ws.data / "method" / "rules.json"


def method(store: Store) -> dict:
    return _read(_rules_path(store)) or {"version": 0, "rules": [], "history": []}


def _evidence_ok(store: Store, ref: str) -> bool:
    from . import exchange  # late: exchange is large and only needed here
    proposal = ref.split("/")[0]
    return exchange.evidence_ok(store, ref) or (store.ws.data / "exchange" / proposal).exists()


def add_rule(store: Store, *, kind: str, text: str, evidence: list[str], pattern: str | None = None,
             when: str | None = None, scope: list[str] | None = None) -> dict:
    if kind not in RULE_KINDS:
        raise LearningError(f"kind must be one of {', '.join(RULE_KINDS)}")
    if not text.strip():
        raise LearningError("a rule says, in words, what went wrong and what to do instead")
    if not evidence:
        raise LearningError("a rule cites the mistake it comes from (proposal/turn, claim, lesson or file)")
    bad = [ref for ref in evidence if not _evidence_ok(store, ref)]
    if bad:
        raise LearningError(f"evidence not found: {bad}")
    if kind != "note" and not pattern:
        raise LearningError(f"a {kind} rule needs --pattern")
    if kind == "require_when" and not when:
        raise LearningError("a require_when rule needs --when (the pattern that triggers it)")
    for p in (pattern, when):
        if p:
            try:
                re.compile(p, re.IGNORECASE)
            except re.error as error:
                raise LearningError(f"bad pattern {p!r}: {error}") from None
    scope = scope or ["claim", "turn"]
    if any(s not in RULE_SCOPES for s in scope):
        raise LearningError(f"scope must be among {', '.join(RULE_SCOPES)}")
    m = method(store)
    rule_id = f"m{len(m['rules']) + 1:03d}"
    rule = {"rule_id": rule_id, "kind": kind, "text": text.strip(), "pattern": pattern, "when": when,
            "scope": scope, "evidence": evidence, "active": True, "added_at": runs.now()}
    m["rules"].append(rule)
    m["version"] += 1
    m["history"].append({"version": m["version"], "change": "added", "rule_id": rule_id, "at": runs.now()})
    write_if_changed(_rules_path(store), dumps(m))
    return rule


def retire_rule(store: Store, rule_id: str, reason: str) -> dict:
    if not reason.strip():
        raise LearningError("say why the rule no longer holds")
    m = method(store)
    rule = next((r for r in m["rules"] if r["rule_id"] == rule_id), None)
    if rule is None or not rule["active"]:
        raise LearningError(f"no active rule {rule_id}")
    rule["active"] = False
    m["version"] += 1
    m["history"].append({"version": m["version"], "change": "retired", "rule_id": rule_id,
                         "reason": reason.strip(), "at": runs.now()})
    write_if_changed(_rules_path(store), dumps(m))
    return rule


def _claim_texts(claim: dict) -> str:
    mp = claim.get("magicpaper") or {}
    return "\n".join(t for t in (claim.get("statement"), claim.get("analyst_note"), mp.get("suggested")) if t)


def _research_turns(store: Store):
    root = store.ws.data / "exchange"
    for path in sorted(root.glob("*/turns/book-research-*.json")) if root.exists() else []:
        turn = _read(path)
        yield f"{path.parent.parent.name}/{turn['id']}", turn


def _breaks(rule: dict, text: str) -> bool:
    flags = re.IGNORECASE
    if rule["kind"] == "forbid":
        return bool(re.search(rule["pattern"], text, flags))
    if rule["kind"] == "require_when":
        return bool(re.search(rule["when"], text, flags)) and not re.search(rule["pattern"], text, flags)
    return False


def check(store: Store) -> list[str]:
    """Every active rule against the current claims and the research agent's turns.

    Claims are living records and must always pass. Turns are append-only, so a rule only
    binds turns written after it was added."""
    problems = []
    rules = [r for r in method(store)["rules"] if r["active"] and r["kind"] != "note"]
    if not rules:
        return problems
    claims = [c for c in store.all("claim") if c.get("status") == "active"]
    turns = list(_research_turns(store))
    for rule in rules:
        if "claim" in rule["scope"]:
            problems += [f"{c['claim_id']}: breaks method rule {rule['rule_id']} — {rule['text']}"
                         for c in claims if _breaks(rule, _claim_texts(c))]
        if "turn" in rule["scope"]:
            problems += [f"{ref}: breaks method rule {rule['rule_id']} — {rule['text']}"
                         for ref, turn in turns if turn["at"] >= rule["added_at"] and _breaks(rule, turn["text"])]
    return problems


def validate(store: Store) -> list[str]:
    errors = check(store)
    for r in all_requests(store):
        if r["status"] not in REQUEST_STATUSES:
            errors.append(f"{r['request_id']}: unknown status {r['status']}")
        if r["status"] == "answered" and not (r.get("answer") or {}).get("text"):
            errors.append(f"{r['request_id']}: answered without an answer")
    return errors


# -- the weekly page's section ---------------------------------------------------------------

def summary(store: Store, since: str | None = None) -> dict:
    m = method(store)
    return {
        "requests": open_requests(store),
        "answered": [r for r in all_requests(store) if r["status"] == "answered"
                     and (since is None or r["answer"]["at"] >= since)],
        "reliability": reliability(store),
        "rechecks": [r for r in all_rechecks(store) if r["status"] == "scored"
                     and (since is None or r.get("scored_at", "") >= since)],
        "method_version": m["version"],
        "rule_changes": [h for h in m["history"] if since is None or h["at"] >= since],
        "rules": {r["rule_id"]: r for r in m["rules"]},
        "next_recheck": pick(store),
    }


def weekly_lines(s: dict) -> list[str]:
    names = {"beat": "olay işlevi", "emotion": "duygu", "emotion_intensity": "duygu yoğunluğu (±1)",
             "page_turn_mechanism": "sayfa çevirme nedeni", "humor": "mizah var mı",
             "repetition": "tekrar var mı", "only_in_image": "yalnızca resimde olan bilgi"}
    states = {"reliable": "güvenilir", "uncertain": "belirsiz", "unreliable": "güvenilmez — bu alana dayanan "
              "iddialar LOW'u geçemez", "measuring": f"ölçülüyor (en az {MIN_PAGES} sayfa gerekli)"}
    out = ["## Ajanlardan gelen sorular", ""]
    out += [f"- `{r['request_id']}` ({r['from']}, {r['status']}): {r['question']}" for r in s["requests"]] \
        or ["- Açık soru yok."]
    out += [f"- Cevaplandı: `{r['request_id']}` → {r['answer']['text']} (kanıt gücü: {r['answer']['evidence_strength']})"
            for r in s["answered"]]
    out += ["", "## Ajan kendini nasıl geliştirdi", ""]
    out += [f"- Kör yeniden okuma: `{r['recheck_id']}`" for r in s["rechecks"]] or ["- Bu dönem kör yeniden okuma yok."]
    if s["reliability"]:
        out += ["", "Okuma tutarlılığı (aynı kitabı iki kez, ilkine bakmadan okuyunca aynı karar):", ""]
        out += [f"- {names.get(f, f)}: %{round(v['rate'] * 100)} ({v['agree']}/{v['total']}) — {states[v['state']]}"
                for f, v in s["reliability"].items()]
    out += ["", f"Yöntem kuralları sürüm {s['method_version']}:", ""]
    for h in s["rule_changes"]:
        rule = s["rules"].get(h["rule_id"], {})
        verb = "eklendi" if h["change"] == "added" else f"kaldırıldı ({h.get('reason')})"
        out.append(f"- `{h['rule_id']}` {verb}: {rule.get('text', '')}")
    if not s["rule_changes"]:
        out.append("- Bu dönem kural değişmedi.")
    if s["next_recheck"]:
        out += ["", f"Sıradaki kör yeniden okuma: `{s['next_recheck']}`"]
    return out
