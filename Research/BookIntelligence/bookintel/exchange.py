"""Idea exchange between agents: research proposals argued out before anything reaches the engine.

A proposal comes from a claim's `magicpaper` block. Around it, each agent writes
only its own part, so agents can work in parallel without overwriting each other:

    data/exchange/<proposal_id>/
      thread.json          research (book-research): the proposal, its status, the recommendation
      turns/<agent>-<n>.json   any participant: a turn in the discussion (append-only)
      impact.json          the target's owner: what it would touch, cost, reversibility
                           (story-engine for engine targets, reader / parent-ux / ui-agent /
                           illustration-system for UX targets; see TARGET_OWNERS)
      prototype.json       content-library: a sample (lives in Research/BookIntelligence/sandbox/)
      safety.json          privacy-safety: pass / concerns / block
      decision.json        human only: approved / rejected / parked
      handoff.json         written when a proposal is approved: the work package for the agent
                           that implements it; only that agent (or the human) moves its status

The loop's single human gate (decision 2026-10-08): everything up to a
recommendation is automatic; nothing reaches children without decision.json.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from . import runs
from .store import Store, dumps, write_if_changed

AGENTS = {"book-research", "story-engine", "content-library", "privacy-safety", "reviewer",
          "reader", "parent-ux", "ui-agent", "illustration-system", "design-system", "human"}
STANCES = {"proposal", "support", "concern", "object", "question", "answer", "prototype", "revision"}
COSTS = {"S", "M", "L"}
SAFETY = {"pass", "concerns", "block"}
ACTIONS = {"experiment", "adopt_guidance", "research_more", "park", "decline"}
VERDICTS = {"approved", "rejected", "parked"}
STATUSES = {"open", "ready_for_decision", "decided"}
OWNERS = {"thread": "book-research", "impact": "story-engine", "prototype": "content-library",
          "safety": "privacy-safety", "decision": "human"}
# Who owns each proposal target: that agent writes impact.json and must be heard before a
# recommendation. Engine targets (everything not listed) belong to story-engine.
TARGET_OWNERS = {
    "reader.page_turn": "reader", "reader.layout": "reader", "reader.read_aloud": "reader",
    "ux.parent_flow": "parent-ux", "ux.child_area": "ui-agent", "design.visual_language": "ui-agent",
    "illustration.brief": "illustration-system",
}
UX_TARGETS = frozenset(TARGET_OWNERS)
# Who implements an approved proposal, when it is not the target's owner.
IMPLEMENTERS = {"writing_guidance": "content-library"}
HANDOFF_STATUSES = ("waiting", "in_progress", "blocked", "done")
# Before a recommendation, privacy-safety and the target's owner must have been heard.
REQUIRED_VOICES = ("story-engine", "privacy-safety")


def owner_of(target: str | None) -> str:
    return TARGET_OWNERS.get(target or "", "story-engine")


def required_voices(target: str | None) -> tuple[str, str]:
    return (owner_of(target), "privacy-safety")


class ExchangeError(RuntimeError):
    pass


def _dir(store: Store, pid: str) -> Path:
    return store.ws.data / "exchange" / pid


def _read(path: Path):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None


def evidence_ok(store: Store, ref: str, claims: set[str] | None = None, works: set[str] | None = None) -> bool:
    """A claim, a work, a proposal, a URL, or a file in the repo or the project folder above it
    (CLAUDE.md and PROSE_PRODUCTION_GUIDE.md live one level above the git repo)."""
    claims = claims if claims is not None else {c["claim_id"] for c in store.all("claim")}
    works = works if works is not None else {w["work_id"] for w in store.all("work")}
    path = ref.split(":")[0]
    return (ref in claims or ref in works or ref.startswith(("http://", "https://", "p_"))
            or (store.ws.repo / path).exists() or (store.ws.repo.parent / path).exists())


def _check_agent(part: str, agent: str, target: str | None = None) -> None:
    owner = owner_of(target) if part == "impact" else OWNERS[part]
    if owner != agent:
        raise ExchangeError(f"{part} is written by {owner}, not {agent}")


def proposal_id(claim_id: str) -> str:
    return "p_" + claim_id[2:] if claim_id.startswith("c_") else "p_" + claim_id


def load(store: Store, pid: str) -> dict:
    root = _dir(store, pid)
    thread = _read(root / "thread.json")
    if thread is None:
        raise ExchangeError(f"no proposal {pid}")
    turns = [_read(p) for p in sorted((root / "turns").glob("*.json"))] if (root / "turns").exists() else []
    turns.sort(key=lambda t: (t["at"], t["agent"], t["n"]))
    return {"thread": thread, "turns": turns, "impact": _read(root / "impact.json"),
            "prototype": _read(root / "prototype.json"), "safety": _read(root / "safety.json"),
            "decision": _read(root / "decision.json")}


def all_ids(store: Store) -> list[str]:
    root = store.ws.data / "exchange"
    return sorted(p.name for p in root.iterdir() if (p / "thread.json").exists()) if root.exists() else []


# -- writes, one per owner -------------------------------------------------------------

def open_proposal(store: Store, claim_id: str) -> str:
    claim = store.get("claim", claim_id)
    if claim is None or not claim.get("magicpaper"):
        raise ExchangeError(f"{claim_id}: no claim with a magicpaper proposal")
    pid = proposal_id(claim_id)
    root = _dir(store, pid)
    if (root / "thread.json").exists():
        return pid
    mp, computed = claim["magicpaper"], claim.get("computed") or {}
    thread = {"proposal_id": pid, "claim_id": claim_id, "status": "open", "opened_at": runs.now(),
              "target": mp.get("target"), "current": mp.get("current"), "suggested": mp.get("suggested"),
              "recommendation": None}
    write_if_changed(root / "thread.json", dumps(thread))
    evidence = (f"{computed.get('support')} of {computed.get('n_examined')} works, "
                f"{(computed.get('sample_scope') or '').replace('_', ' ').lower()}, confidence {computed.get('confidence')}")
    post(store, pid, "book-research", "proposal",
         f"{claim['statement']} Evidence: {evidence}. Proposal for `{mp.get('target')}`: {mp.get('suggested')}",
         evidence=[claim_id] + claim.get("supporting_works", []))
    return pid


def post(store: Store, pid: str, agent: str, stance: str, text: str, evidence: list[str] | None = None,
         reply_to: str | None = None) -> dict:
    if agent not in AGENTS - {"human"}:
        raise ExchangeError(f"unknown agent {agent!r}")
    if stance not in STANCES:
        raise ExchangeError(f"unknown stance {stance!r}")
    root = _dir(store, pid)
    if not (root / "thread.json").exists():
        raise ExchangeError(f"no proposal {pid}")
    if (root / "decision.json").exists():
        raise ExchangeError(f"{pid} is decided; open a new proposal to reopen it")
    bad = [ref for ref in evidence or [] if not evidence_ok(store, ref)]
    if bad:
        raise ExchangeError(f"evidence not found: {bad} — cite a claim, work, repo file or URL")
    turns_dir = root / "turns"
    n = len(list(turns_dir.glob(f"{agent}-*.json"))) + 1 if turns_dir.exists() else 1
    turn = {"agent": agent, "n": n, "id": f"{agent}-{n}", "stance": stance, "text": text.strip(),
            "evidence": evidence or [], "reply_to": reply_to, "at": runs.now()}
    write_if_changed(turns_dir / f"{agent}-{n:03d}.json", dumps(turn))
    return turn


def set_impact(store: Store, pid: str, agent: str, *, fields: list[str], files: list[str], tests: list[str],
               owner: str, cost: str, reversible: bool, notes: str) -> None:
    _check_agent("impact", agent, load(store, pid)["thread"].get("target"))
    if cost not in COSTS:
        raise ExchangeError(f"cost must be one of {sorted(COSTS)}")
    write_if_changed(_dir(store, pid) / "impact.json", dumps(
        {"fields": fields, "files": files, "tests": tests, "owner": owner, "cost": cost,
         "reversible": reversible, "notes": notes, "by": agent, "at": runs.now()}))


def set_prototype(store: Store, pid: str, agent: str, *, path: str, description: str) -> None:
    _check_agent("prototype", agent)
    if not path.startswith("Research/BookIntelligence/sandbox/"):
        raise ExchangeError("prototypes live in Research/BookIntelligence/sandbox/, never in production content")
    write_if_changed(_dir(store, pid) / "prototype.json", dumps(
        {"path": path, "description": description, "by": agent, "at": runs.now()}))


def set_safety(store: Store, pid: str, agent: str, *, verdict: str, notes: str) -> None:
    _check_agent("safety", agent)
    if verdict not in SAFETY:
        raise ExchangeError(f"verdict must be one of {sorted(SAFETY)}")
    write_if_changed(_dir(store, pid) / "safety.json", dumps(
        {"verdict": verdict, "notes": notes, "by": agent, "at": runs.now()}))


def recommend(store: Store, pid: str, agent: str, *, action: str, rationale: str) -> None:
    _check_agent("thread", agent)
    if action not in ACTIONS:
        raise ExchangeError(f"action must be one of {sorted(ACTIONS)}")
    record = load(store, pid)
    target = record["thread"].get("target")
    voices = {t["agent"] for t in record["turns"]}
    missing = [v for v in required_voices(target) if v not in voices]
    if missing:
        raise ExchangeError(f"{pid}: not heard yet from {', '.join(missing)}")
    if action == "experiment" and target in UX_TARGETS:
        raise ExchangeError(f"{pid}: experiments test story blueprints; a UX target can be adopted as guidance, "
                            "parked, declined or sent back for research")
    if action == "experiment":
        if not record["impact"]:
            raise ExchangeError(f"{pid}: an experiment needs story-engine's impact assessment")
        if (record["safety"] or {}).get("verdict") != "pass":
            raise ExchangeError(f"{pid}: an experiment needs a privacy-safety 'pass'")
    if (record["safety"] or {}).get("verdict") == "block" and action not in ("park", "decline", "research_more"):
        raise ExchangeError(f"{pid}: safety blocked it; only park, decline or research_more are possible")
    thread = record["thread"]
    thread["recommendation"] = {"action": action, "rationale": rationale, "by": agent, "at": runs.now()}
    thread["status"] = "ready_for_decision"
    write_if_changed(_dir(store, pid) / "thread.json", dumps(thread))


def decide(store: Store, pid: str, *, verdict: str, note: str) -> None:
    """The human gate. Only the product owner runs this; agent definitions forbid it."""
    if verdict not in VERDICTS:
        raise ExchangeError(f"verdict must be one of {sorted(VERDICTS)}")
    record = load(store, pid)
    if record["thread"]["status"] != "ready_for_decision":
        raise ExchangeError(f"{pid}: not ready for decision (status {record['thread']['status']})")
    write_if_changed(_dir(store, pid) / "decision.json", dumps(
        {"verdict": verdict, "note": note, "by": "human", "at": runs.now()}))
    thread = record["thread"]
    thread["status"] = "decided"
    write_if_changed(_dir(store, pid) / "thread.json", dumps(thread))
    claim = store.get("claim", thread["claim_id"])
    if claim and claim.get("magicpaper"):
        claim["magicpaper"]["review_status"] = {"approved": "accepted", "rejected": "declined",
                                                "parked": "reviewed"}[verdict]
        store.put("claim", claim)
    if verdict == "approved":
        ensure_handoff(store, pid)


# -- handoffs: from an approved proposal to the agent that builds it ---------------------

def _handoff_path(store: Store, pid: str) -> Path:
    return _dir(store, pid) / "handoff.json"


def ensure_handoff(store: Store, pid: str) -> dict | None:
    """Write the work package for an approved proposal (idempotent: an existing one is kept)."""
    record = load(store, pid)
    if (record["decision"] or {}).get("verdict") != "approved":
        return None
    existing = _read(_handoff_path(store, pid))
    if existing:
        return existing
    t = record["thread"]
    target, rec = t.get("target"), t.get("recommendation") or {}
    # An experiment changes the engine first (story-engine leads); guidance goes to whoever writes it.
    owner = owner_of(target) if rec.get("action") == "experiment" else IMPLEMENTERS.get(target, owner_of(target))
    impact, safety = record["impact"] or {}, record["safety"] or {}
    # Whoever assessed the impact, and content-library for an experiment's sibling blueprints, works alongside.
    helpers = {impact.get("owner"), "content-library" if rec.get("action") == "experiment" else None}
    with_agents = sorted(a for a in helpers - {owner, None} if a in AGENTS - {"human"})
    done_when = [
        "Works on its own branch or worktree, never on main; nothing is merged without the product owner.",
        "Existing tests stay green and new behaviour has tests.",
        "A Değişiklik günlüğü entry is added (CLAUDE.md).",
        "`ba exchange handoff " + pid + " --status done --note <branch@commit>` is recorded.",
    ]
    if rec.get("action") == "experiment":
        done_when.insert(0, "Variant arms are built and validated offline; they reach children only after "
                            "`ba experiment preflight` is ready and the product owner marks the experiment live.")
    elif target in UX_TARGETS:
        done_when.insert(0, "Design brief or screen change follows the design law in CLAUDE.md "
                            "(tokens, accessibility, light + dark, largest Dynamic Type).")
    elif target == "writing_guidance":
        done_when.insert(0, "The guidance is written into the content line's writing rules; corpus validators still pass.")
    handoff = {
        "proposal_id": pid, "claim_id": t["claim_id"], "target": target, "kind": rec.get("action"),
        "owner": owner, "with": with_agents,
        "task": t.get("suggested"), "current": t.get("current"),
        "recommendation": rec.get("rationale"), "decision_note": record["decision"].get("note"),
        "touches": {"fields": impact.get("fields", []), "files": impact.get("files", []),
                    "tests": impact.get("tests", []), "cost": impact.get("cost")},
        "safety": {"verdict": safety.get("verdict"), "notes": safety.get("notes")},
        "done_when": done_when,
        "status": "waiting", "history": [{"status": "waiting", "by": "human", "note": "approved", "at": runs.now()}],
        "created_at": runs.now(),
    }
    write_if_changed(_handoff_path(store, pid), dumps(handoff))
    return handoff


def ensure_handoffs(store: Store) -> list[str]:
    return [pid for pid in all_ids(store) if ensure_handoff(store, pid)]


def set_handoff_status(store: Store, pid: str, agent: str, status: str, note: str) -> dict:
    handoff = _read(_handoff_path(store, pid))
    if handoff is None:
        raise ExchangeError(f"{pid}: no work package (only approved proposals have one)")
    if status not in HANDOFF_STATUSES:
        raise ExchangeError(f"status must be one of {', '.join(HANDOFF_STATUSES)}")
    if agent not in {handoff["owner"], *handoff.get("with", []), "human"}:
        raise ExchangeError(f"{pid}: the work package belongs to {handoff['owner']}, not {agent}")
    if status in ("done", "blocked") and not note.strip():
        raise ExchangeError(f"{pid}: say where the work is (branch@commit) or what blocks it")
    handoff["status"] = status
    handoff["history"].append({"status": status, "by": agent, "note": note.strip(), "at": runs.now()})
    write_if_changed(_handoff_path(store, pid), dumps(handoff))
    return handoff


def all_handoffs(store: Store) -> list[dict]:
    return [h for h in (_read(_handoff_path(store, pid)) for pid in all_ids(store)) if h]


def render_handoff(h: dict) -> str:
    out = [f"# İş paketi: {h['proposal_id']}", "",
           f"**Durum:** {h['status']} · **Sahibi:** {h['owner']}"
           + (f" (birlikte: {', '.join(h['with'])})" if h.get("with") else "")
           + f" · **Tür:** {h.get('kind')} · **Hedef:** `{h.get('target')}`", "",
           "## Ne yapılacak", "", h.get("task") or "—", "",
           f"- Bugün: {h.get('current') or '—'}",
           f"- Neden: {h.get('recommendation') or '—'}",
           f"- Ürün sahibinin notu: {h.get('decision_note') or '—'}",
           f"- Kanıt: iddia `{h['claim_id']}`, tartışma [exchange/{h['proposal_id']}.md](../exchange/{h['proposal_id']}.md)", ""]
    touches = h.get("touches") or {}
    if any(touches.get(k) for k in ("fields", "files", "tests")):
        out += ["## Dokunacağı yerler", "",
                f"- Alanlar: {', '.join(touches.get('fields') or []) or '—'}",
                f"- Dosyalar: {', '.join(touches.get('files') or []) or '—'}",
                f"- Testler: {', '.join(touches.get('tests') or []) or '—'}",
                f"- Maliyet: {touches.get('cost') or '—'}", ""]
    safety = h.get("safety") or {}
    if safety.get("verdict"):
        out += ["## Güvenlik koşulları", "", f"**{safety['verdict']}**: {safety.get('notes') or '—'}", ""]
    out += ["## Bitti sayılması için", ""] + [f"- {d}" for d in h["done_when"]] + ["", "## Geçmiş", ""]
    out += [f"- {x['at'][:10]} · {x['status']} · {x['by']}" + (f": {x['note']}" if x.get("note") else "")
            for x in h["history"]]
    return "\n".join(out) + "\n"


def handoff_index(store: Store) -> str:
    rows = all_handoffs(store)
    out = [f"# İş paketleri — {runs.today()}", "",
           "Onaylanan her öneri, onu uygulayacak ajan için bir iş paketine dönüşür. "
           "Ajan kendi dalında çalışır; ana koda ürün sahibinin onayıyla girer.", ""]
    for status in HANDOFF_STATUSES:
        group = [h for h in rows if h["status"] == status]
        out += [f"## {status} ({len(group)})", ""]
        out += [f"- [{h['proposal_id']}](handoffs/{h['proposal_id']}.md) → **{h['owner']}**: {h.get('task') or '—'}"
                for h in group] or ["- Yok."]
        out.append("")
    return "\n".join(out)


# -- checks, learning, rendering --------------------------------------------------------

def validate(store: Store) -> list[str]:
    errors = []
    repo = store.ws.repo
    claims = {c["claim_id"] for c in store.all("claim")}
    works = {w["work_id"] for w in store.all("work")}
    for pid in all_ids(store):
        r = load(store, pid)
        t = r["thread"]
        if t.get("claim_id") not in claims:
            errors.append(f"{pid}: unknown claim {t.get('claim_id')}")
        if t.get("status") not in STATUSES:
            errors.append(f"{pid}: bad status {t.get('status')}")
        if t.get("status") == "decided" and not r["decision"]:
            errors.append(f"{pid}: decided without decision.json")
        if r["decision"] and r["decision"].get("by") != "human":
            errors.append(f"{pid}: decision.json must be written by the human gate")
        for part in ("prototype", "safety"):
            if r[part] and r[part].get("by") != OWNERS[part]:
                errors.append(f"{pid}: {part} written by {r[part].get('by')}, owner is {OWNERS[part]}")
        if (r["thread"].get("recommendation") or {}).get("action") == "experiment" and \
                (r["safety"] or {}).get("verdict") != "pass":
            errors.append(f"{pid}: experiment recommended without a safety pass")
        for turn in r["turns"]:
            if turn.get("agent") not in AGENTS or turn.get("stance") not in STANCES:
                errors.append(f"{pid}/{turn.get('id')}: unknown agent or stance")
            for ref in turn.get("evidence", []):
                if not evidence_ok(store, ref, claims, works):
                    errors.append(f"{pid}/{turn['id']}: evidence {ref!r} is not a claim, work, repo file or URL")
        if r["prototype"] and not (repo / r["prototype"]["path"]).exists():
            errors.append(f"{pid}: prototype file {r['prototype']['path']} missing")
        target = t.get("target")
        if r["impact"] and r["impact"].get("by") != owner_of(target):
            errors.append(f"{pid}: impact written by {r['impact'].get('by')}, owner of {target} is {owner_of(target)}")
        handoff = _read(_handoff_path(store, pid))
        if handoff:
            if (r["decision"] or {}).get("verdict") != "approved":
                errors.append(f"{pid}: work package without an approved decision")
            if handoff.get("status") not in HANDOFF_STATUSES:
                errors.append(f"{pid}: bad work package status {handoff.get('status')}")
            if handoff.get("owner") not in AGENTS - {"human"}:
                errors.append(f"{pid}: work package owner {handoff.get('owner')} is not an agent")
    return errors


def lessons(store: Store) -> dict:
    """What past decisions teach the research agent: read before proposing again."""
    by_target: dict[str, dict] = {}
    notes = []
    for pid in all_ids(store):
        r = load(store, pid)
        target = r["thread"].get("target") or "?"
        slot = by_target.setdefault(target, {"proposed": 0, "approved": 0, "rejected": 0, "parked": 0})
        slot["proposed"] += 1
        if r["decision"]:
            slot[r["decision"]["verdict"]] += 1
            notes.append({"proposal": pid, "verdict": r["decision"]["verdict"], "note": r["decision"]["note"]})
        for turn in r["turns"]:
            if turn["stance"] in ("object", "concern") and turn["agent"] != "book-research":
                notes.append({"proposal": pid, "objection_by": turn["agent"], "text": turn["text"][:240]})
    return {"by_target": by_target, "notes": notes}


def render(store: Store, pid: str) -> str:
    r = load(store, pid)
    t = r["thread"]
    claim = store.get("claim", t["claim_id"]) or {}
    computed = claim.get("computed") or {}
    out = [f"# {pid}", "",
           f"**Status:** {t['status']} · **Target:** `{t.get('target')}` · claim `{t['claim_id']}` "
           f"({computed.get('confidence')}, {computed.get('support')}/{computed.get('n_examined')} works)", "",
           f"> {claim.get('statement', '')}", "",
           f"- Current: {t.get('current') or '—'}", f"- Suggested: {t.get('suggested') or '—'}", "", "## Discussion", ""]
    for turn in r["turns"]:
        reply = f" ↩ {turn['reply_to']}" if turn.get("reply_to") else ""
        out += [f"**{turn['agent']}** · {turn['stance']}{reply} · {turn['at'][:16].replace('T', ' ')}", "", turn["text"], ""]
        if turn.get("evidence"):
            out += ["Evidence: " + ", ".join(f"`{e}`" for e in turn["evidence"]), ""]
    if r["impact"]:
        i = r["impact"]
        out += [f"## Impact ({i.get('by')})", "",
                f"- Fields: {', '.join(i['fields']) or '—'}", f"- Files: {', '.join(i['files']) or '—'}",
                f"- Tests: {', '.join(i['tests']) or '—'}", f"- Owner: {i['owner']} · cost {i['cost']} · "
                f"reversible: {'yes' if i['reversible'] else 'no'}", f"- {i['notes']}", ""]
    if r["prototype"]:
        out += ["## Prototype (content-library)", "", f"`{r['prototype']['path']}` — {r['prototype']['description']}", ""]
    if r["safety"]:
        out += ["## Safety (privacy-safety)", "", f"**{r['safety']['verdict']}** — {r['safety']['notes']}", ""]
    if t.get("recommendation"):
        rec = t["recommendation"]
        out += ["## Recommendation (book-research)", "", f"**{rec['action']}** — {rec['rationale']}", ""]
    out += ["## Decision (human)", ""]
    out += [f"**{r['decision']['verdict']}** — {r['decision']['note']} ({r['decision']['at'][:10]})"] if r["decision"] \
        else ["Waiting. `book-agent exchange decide " + pid + " --verdict approved|rejected|parked --note \"…\"`"]
    return "\n".join(out) + "\n"


def digest(store: Store) -> str:
    ids = all_ids(store)
    groups = {s: [] for s in ("ready_for_decision", "open", "decided")}
    for pid in ids:
        r = load(store, pid)
        groups[r["thread"]["status"]].append(r)
    out = [f"# Exchange digest — {runs.today()}", "",
           "One page for the product owner. Only the first section needs you.", "",
           f"## Waiting for your decision ({len(groups['ready_for_decision'])})", ""]
    for r in groups["ready_for_decision"]:
        t, rec = r["thread"], r["thread"]["recommendation"]
        safety = (r["safety"] or {}).get("verdict", "—")
        cost = (r["impact"] or {}).get("cost", "—")
        out += [f"### {t['proposal_id']} → **{rec['action']}**", "",
                f"{rec['rationale']}", "",
                f"Target `{t.get('target')}` · safety **{safety}** · cost {cost} · "
                f"[thread](exchange/{t['proposal_id']}.md)", ""]
    if not groups["ready_for_decision"]:
        out += ["Nothing.", ""]
    out += [f"## Still being discussed ({len(groups['open'])})", ""]
    for r in groups["open"]:
        heard = sorted({t['agent'] for t in r['turns']})
        out.append(f"- {r['thread']['proposal_id']} — heard from: {', '.join(heard)}")
    out += ["", f"## Decided ({len(groups['decided'])})", ""]
    for r in groups["decided"]:
        out.append(f"- {r['thread']['proposal_id']}: {r['decision']['verdict']} — {r['decision']['note']}")
    handoffs = all_handoffs(store)
    out += ["", f"## Work packages ({len(handoffs)})", ""]
    out += [f"- {h['proposal_id']} → {h['owner']} [{h['status']}]" for h in handoffs] or ["- None."]
    out.append("[HANDOFFS.md](HANDOFFS.md)")
    return "\n".join(out) + "\n"


def write_docs(store: Store) -> list[Path]:
    written = []
    for pid in all_ids(store):
        path = store.ws.docs / "exchange" / f"{pid}.md"
        write_if_changed(path, render(store, pid))
        written.append(path)
    ensure_handoffs(store)
    for h in all_handoffs(store):
        path = store.ws.docs / "handoffs" / f"{h['proposal_id']}.md"
        write_if_changed(path, render_handoff(h))
        written.append(path)
    path = store.ws.docs / "HANDOFFS.md"
    write_if_changed(path, handoff_index(store))
    written.append(path)
    path = store.ws.docs / "EXCHANGE_DIGEST.md"
    write_if_changed(path, digest(store))
    written.append(path)
    store.write_index("lessons", lessons(store))
    return written


_SAFE_ID = re.compile(r"^p_[a-z0-9_]+$")


def check_id(pid: str) -> str:
    if not _SAFE_ID.match(pid):
        raise ExchangeError(f"not a proposal id: {pid!r}")
    return pid
