"""The weekly cycle: every deterministic step of the loop, in order, plus one page for the owner.

    inbox usage → metrics → experiments → confidence → calibration → gaps → exchange digest → weekly report

The agentic half (reading new books, an exchange round with the other agents)
is the scheduled Claude task's job; it runs this first and last.
"""

from __future__ import annotations

from pathlib import Path

from . import analyze, confidence, exchange, experiments, gaps, htmlpage, runs
from .store import Store, write_if_changed


def inbox(store: Store) -> Path:
    # Server aggregate exports are dropped here (gitignored); only the accepted copy enters data/.
    return store.ws.cache.parent / "inbox" / "usage"


def run(store: Store) -> dict:
    report: dict = {"date": runs.today(), "imported": [], "refused": [], "experiments": [], "confidence": []}
    known = {p["periodEnd"] for p in experiments.usage_periods(store)}
    folder = inbox(store)
    for path in sorted(folder.glob("*.json")) if folder.exists() else []:
        try:
            period = experiments.import_usage(store, path)
            if period not in known:
                report["imported"].append(period)
        except experiments.ExperimentError as error:
            report["refused"].append({"file": path.name, "reason": str(error)})
    for record in store.all("analysis"):
        analyze.refresh(store, record["work_id"], record["analysis_version"])
    report["experiments"] = experiments.evaluate(store)
    report["confidence"] = confidence.recompute_all(store)
    report["calibration"] = experiments.calibration(store)
    report["gaps"] = gaps.gaps(store)
    exchange.write_docs(store)
    report["path"] = str(write_weekly(store, report))
    return report


def write_weekly(store: Store, report: dict) -> Path:
    ids = exchange.all_ids(store)
    threads = [exchange.load(store, pid) for pid in ids]
    waiting = [t for t in threads if t["thread"]["status"] == "ready_for_decision"]
    open_threads = [t for t in threads if t["thread"]["status"] == "open"]
    all_exp = experiments.all_experiments(store)
    cal = report["calibration"]
    out = [f"# MagicPaper öğrenme döngüsü — hafta {report['date']}", "",
           "Tek sayfa. Yalnızca **Senin kararın** bölümü bir şey bekliyor.", "",
           "## Senin kararın", ""]
    if waiting:
        for t in waiting:
            rec = t["thread"]["recommendation"]
            out.append(f"- `{t['thread']['proposal_id']}` → **{rec['action']}** — {rec['rationale']}")
    else:
        out.append("- Bekleyen karar yok.")
    ready = [e for e in all_exp if e["status"] == "ready"]
    if ready:
        out += ["", "Yayına hazır deneyler (paketi Batuhan yayınlar, sonra `experiment mark … live`):", ""]
        out += [f"- `{e['experiment_id']}`: {e['control']} ↔ {e['variant']} ({e['age_band']}, {e['mode']})" for e in ready]
    out += ["", "## Çocuklardan gelen", ""]
    if report["imported"]:
        out.append(f"- Yeni kullanım dönemleri: {', '.join(report['imported'])}")
    if report["refused"]:
        out += [f"- Reddedilen dosya `{r['file']}`: {r['reason']}" for r in report["refused"]]
    if not report["imported"] and not report["refused"]:
        out.append("- Yeni kullanım verisi yok (sunucu toplaması yayında değilse beklenen durum).")
    out += ["", "## Deneyler", ""]
    if all_exp:
        for e in all_exp:
            result = e.get("result") or {}
            line = f"- `{e['experiment_id']}` [{e['status']}]"
            if result.get("state") == "collecting":
                line += f" — veri toplanıyor ({result['control_starts']} / {result['variant_starts']} okuma, kol başına {experiments.MIN_STARTS_PER_ARM} gerekli)"
            elif result.get("metric"):
                line += (f" — {result['metric']}: kontrol {result['control']['rate']}, varyant {result['variant']['rate']}, "
                         f"P(varyant daha iyi) = {result['p_variant_better']}; sonuç: {result.get('observed') or 'kararsız'}")
            elif e.get("preflight") and e["preflight"]["problems"]:
                line += " — ön kontrol: " + "; ".join(e["preflight"]["problems"])
            out.append(line)
    else:
        out.append("- Kayıtlı deney yok.")
    out += ["", "## Araştırma ajanı kendini ne kadar iyi tahmin ediyor", ""]
    if cal.get("resolved"):
        out.append(f"- {cal['resolved']} sonuçlanmış tahmin · isabet {cal['hit_rate']} · ortalama güven "
                   f"{cal['mean_confidence']} · Brier {cal['brier']} · {cal['advice']}")
    else:
        out.append("- Henüz sonuçlanmış tahmin yok.")
    out += ["", "## Güven değişiklikleri", ""]
    out += [f"- `{c['claim_id']}`: {c['from']} → {c['to']}" for c in report["confidence"]] or ["- Yok."]
    out += ["", "## İş paketleri (onaylanan öneriler)", ""]
    out += [f"- `{h['proposal_id']}` → {h['owner']}" + (f" + {', '.join(h['with'])}" if h.get("with") else "")
            + f" [{h['status']}]: {h.get('task') or '—'}" for h in exchange.all_handoffs(store)] or ["- Yok."]
    out += ["", "## Tartışması süren öneriler", ""]
    out += [f"- `{t['thread']['proposal_id']}` — konuşanlar: {', '.join(sorted({x['agent'] for x in t['turns']}))}"
            for t in open_threads] or ["- Yok."]
    out += ["", "## Sıradaki araştırma görevleri", ""]
    out += [f"- {g['gap']}: {g['have']} / {g['want']}" for g in report["gaps"][:6]] or ["- Plan hedefleri karşılanıyor."]
    out += ["", f"Ayrıntı: [EXCHANGE_DIGEST.md](../EXCHANGE_DIGEST.md) · [FINDINGS.md](../FINDINGS.md)"]
    path = store.ws.docs / "weekly" / f"{report['date']}.md"
    page = "\n".join(out) + "\n"
    write_if_changed(path, page)
    # The owner reads HTML, not Markdown: the weekly page and the decision digest in one file.
    htmlpage.write(path.with_suffix(".html"), f"MagicPaper hafta {report['date']}",
                   [page, exchange.digest(store), exchange.handoff_index(store)])
    return path
