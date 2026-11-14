"""Writing lessons for MagicPaper Original: cause → effect and endings, read from complete analyses.

Each complete analysis may carry a `craft` block the analyst fills (paraphrase, never book text):

    causal_chain   [{cause, effect, pages, driver}]   who or what makes each step happen
    ending         {type, answers, last_page_move, returns_to_opening, pages_after_resolution}
    writer_note    one move a writer could reuse

`brief` turns them into docs/research/ORIGINALS_CRAFT.md, the page original-writer reads before it
writes, grouped by the MagicPaper mode a book is closest to. The page also carries the questions
book-research and original-writer asked each other (data/requests, `to`). Counts are corpus
observations about books, never what children prefer.
"""

from __future__ import annotations

from collections import Counter
from statistics import median

from . import learning, report
from .store import Store

# closest MagicPaper mode for a research book; a book can sit in more than one
MODE_OF = {
    "bedtime": {"bedtime"},
    "adventure": {"adventure", "courage"},
    "learning": {"concept", "discovery", "nature", "problem-solving"},
}
MODE_NAMES = {"bedtime": "Uyku öncesi", "adventure": "Maceraya çıkalım", "learning": "Yeni şeyler öğrenelim",
              "other": "Diğer"}
ENDING_NAMES = {"problem_solved": "sorun çözülür", "wish_fulfilled": "istek gerçekleşir",
                "reconciliation": "barışma", "return_home": "eve dönüş", "settling_to_sleep": "uykuya yatışma",
                "celebration": "kutlama", "change_of_heart": "fikir/duygu değişir",
                "open_invitation": "okura açık davet", "twist": "son sayfada ters köşe",
                "circular_return": "başa dönen çember"}
DRIVER_NAMES = {"protagonist": "kahraman", "peer": "akran", "companion": "yol arkadaşı", "adult": "yetişkin",
                "antagonist": "karşı güç", "chance": "rastlantı", "nature": "doğa"}


def _complete(store: Store) -> list[tuple[dict, dict]]:
    rows = []
    for work in store.all("work"):
        if work.get("rejected"):
            continue
        analysis = store.latest("analysis", work["work_id"])
        if analysis and analysis.get("status") == "complete":
            rows.append((work, analysis))
    return rows


def todo(store: Store) -> list[str]:
    """Complete analyses without a craft block, newest books first (backfill order)."""
    rows = [(w, a) for w, a in _complete(store) if not a.get("craft")]
    rows.sort(key=lambda r: -(r[0].get("first_publication_year") or 0))
    return [w["work_id"] for w, _ in rows]


def modes(work: dict) -> list[str]:
    types = set((work.get("classification") or {}).get("story_types") or [])
    found = [m for m, keys in MODE_OF.items() if types & keys]
    return found or ["other"]


def _group(rows: list[tuple[dict, dict]]) -> dict:
    links = [link for _, a in rows for link in a["craft"]["causal_chain"]]
    endings = [a["craft"]["ending"] for _, a in rows]
    last_driver = Counter(a["craft"]["causal_chain"][-1]["driver"] for _, a in rows)
    return {
        "n": len(rows),
        "endings": Counter(e["type"] for e in endings),
        "drivers": Counter(link["driver"] for link in links),
        "links": len(links),
        "chain_median": median(len(a["craft"]["causal_chain"]) for _, a in rows) if rows else 0,
        "last_driver": last_driver,
        "returns": sum(1 for e in endings if e["returns_to_opening"]),
        "after_median": median(e["pages_after_resolution"] for e in endings) if endings else 0,
    }


def brief(store: Store) -> dict:
    rows = [(w, a) for w, a in _complete(store) if a.get("craft")]
    by_mode: dict[str, list] = {}
    for w, a in rows:
        for m in modes(w):
            by_mode.setdefault(m, []).append((w, a))
    return {
        "n_with_craft": len(rows),
        "n_complete": len(_complete(store)),
        "groups": {m: _group(r) for m, r in sorted(by_mode.items())},
        "books": [{"work_id": w["work_id"], "title": w["title"], "year": w.get("first_publication_year"),
                   "age_band": (w.get("classification") or {}).get("age_band"), "modes": modes(w),
                   "ending": a["craft"]["ending"], "chain": a["craft"]["causal_chain"],
                   "note": a["craft"]["writer_note"]} for w, a in rows],
        "dialogue": [r for r in learning.all_requests(store)
                     if {r["from"], learning.addressee(r)} == {"book-research", "original-writer"}],
    }


def _counts(counter: Counter, names: dict, total: int) -> str:
    return ", ".join(f"{names.get(k, k)} {v}/{total}" for k, v in counter.most_common()) or "—"


def markdown(b: dict) -> str:
    out = [f"{b['n_with_craft']} of {b['n_complete']} complete analyses carry craft notes "
           "(the rest are backfilled week by week: `book-agent craft todo`).", "",
           "Corpus observations about published picture books, not rules and not what children prefer. "
           "A pattern from fewer than 5 books is a hint. Every line is the analyst's paraphrase; no book text.", ""]
    out += ["## Moda göre", ""]
    for mode, g in b["groups"].items():
        n = g["n"]
        out += [f"### {MODE_NAMES.get(mode, mode)} ({n} kitap)", "",
                f"- Final türü: {_counts(g['endings'], ENDING_NAMES, n)}",
                f"- Neden-sonuç zinciri: ortanca {g['chain_median']} halka; halkaları yürüten: "
                f"{_counts(g['drivers'], DRIVER_NAMES, g['links'])}",
                f"- Son halkayı (çözümü) yürüten: {_counts(g['last_driver'], DRIVER_NAMES, n)}",
                f"- Final açılış yerine/imgesine döner: {g['returns']}/{n}",
                f"- Çözümden sonra kalan sayfa: ortanca {g['after_median']}", ""]
    out += ["## Kitap kitap", "", "| Kitap | Yıl | Yaş | Final | Zincir (sürücü) | Yazara not |", "|---|---|---|---|---|---|"]
    for book in b["books"]:
        chain = " → ".join(f"{link['effect']} ({DRIVER_NAMES.get(link['driver'], link['driver'])})"
                           for link in book["chain"])
        ending = ENDING_NAMES.get(book["ending"]["type"], book["ending"]["type"])
        out.append(f"| {report._cell(book['title'])} | {book['year'] or 'yıl bilinmiyor'} | {book['age_band'] or '—'} "
                   f"| {ending}: {report._cell(book['ending']['last_page_move'])} | {report._cell(chain)} "
                   f"| {report._cell(book['note'])} |")
    out += ["", "## book-research ↔ original-writer", ""]
    if not b["dialogue"]:
        out.append("- Henüz soru yok.")
    for r in b["dialogue"]:
        line = f"- `{r['request_id']}` {r['from']} → {learning.addressee(r)} ({r['status']}): {r['question']}"
        if r.get("answer"):
            cited = ", ".join(r["answer"].get("tales") or r["answer"].get("claims") or [])
            line += f"\n  - Cevap: {r['answer']['text']}" + (f" ({cited})" if cited else "")
        out.append(line)
    return "\n".join(out)


def write(store: Store) -> str:
    path = store.ws.docs / "ORIGINALS_CRAFT.md"
    report.write_generated(path, "MagicPaper Original için yazım dersleri", markdown(brief(store)),
                           intro="book-research okuduğu kitaplardan neden-sonuç ve final derslerini buraya yazar; "
                                 "original-writer yazmadan önce okur. Soru sormak için: `book-agent request ask "
                                 "--agent original-writer --question … --why …`.")
    return str(path)
