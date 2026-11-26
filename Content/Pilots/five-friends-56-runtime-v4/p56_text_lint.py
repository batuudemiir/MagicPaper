#!/usr/bin/env python3
"""Beş arkadaş metin denetimi.

Kullanım:
  python3 p56_text_lint.py payload.json            # P56 runtime payload
  python3 p56_text_lint.py rewrites.json           # yeniden yazım taslağı
  python3 p56_text_lint.py payload.json --cell adventure/companion_hedgehog_pilot_001

Denetimler (kitap başına):
  - kural cümlesi kalıpları (en fazla 1)
  - cümle başına en fazla 14 kelime, sayfa başına 18-38 kelime (motorun TextMetrics kuralıyla)
  - arkadaşın tekrar eden sözü en fazla 2 kez
  - arkadaşın adı en az 3 sayfada (huy anları için kaba ölçü)
  - en az bir gülümseten an
Payload için ayrıca: aynı hücredeki kitaplar arası 4 kelimelik öbek örtüşmesi (hedef en fazla %20) ve aynı iskeletten çıkan kitaplarda birebir aynı sayfa payı (hedef en fazla %40).
"""
import json, re, sys, collections

RULE_PATTERNS = [
    r"\byoktu\b", r"gerekmiyordu", r"zorunda değildi", r"\bdeğildi\.",
    r"kucağına almadı", r"\bçekmedi\b", r"kaldırmıyordu", r"\bezmedi\b",
    r"\bkatkı", r"tehlike", r"uçurum", r"\bsapmadı\b", r"\btahmin etmedi\b",
]
RULE_RE = re.compile("|".join(RULE_PATTERNS), re.IGNORECASE)
HUMOR_RE = re.compile(r"güldü|güldür|gülme|kahkaha|kıkırda|kıkırtı|gülümse|gülerek|sevindi|top oldu", re.IGNORECASE)
CATCHPHRASES = {
    "companion_fox_pilot_001": ("Tarçın", "Bir koklayalım bakalım"),
    "companion_hedgehog_pilot_001": ("Kestane", "Küçük bir adım, sonra bir tane daha"),
    "companion_owl_pilot_001": ("Yıldız", "sen ne görüyorsun"),
    "companion_city_cat_001": ("Simit", "Şehirde böyle değil ama"),
    "companion_bear_001": ("Böğürtlen", "Acele yok, ben buradayım"),
}
MAX_WORDS = 14
PAGE_MIN, PAGE_MAX = 18, 38  # motorun 5-6 yaş sayfa bütçesi (P56StoryComposer)

# Motorun TextMetrics.swift kurallarının birebir karşılığı.
def words(text):
    import unicodedata
    out = []
    for tok in text.split():
        a, b = 0, len(tok)
        while a < b and unicodedata.category(tok[a]).startswith("P"): a += 1
        while b > a and unicodedata.category(tok[b-1]).startswith("P"): b -= 1
        if a < b: out.append(tok[a:b])
    return out

_TERM = set(".!?…"); _CLOSE = set("\"”'’)]»")
def sentences(text):
    res, cur, i, n = [], "", 0, len(text)
    while i < n:
        ch = text[i]; cur += ch; i += 1
        if ch not in _TERM: continue
        while i < n and (text[i] in _TERM or text[i] in _CLOSE): cur += text[i]; i += 1
        j = i
        while j < n and text[j].isspace(): j += 1
        if j < n and text[j].islower(): continue
        if cur.strip(): res.append(cur.strip())
        cur = ""
    if cur.strip(): res.append(cur.strip())
    return res

def load(path, cell=None):
    data = json.load(open(path, encoding="utf-8"))
    books = []
    if "books" in data and data["books"] and "authoredBookJSON" in data["books"][0]:
        for b in data["books"]:
            a = json.loads(b["authoredBookJSON"])
            key = b["mode"] + "/" + b["companionID"]
            if cell and key != cell: continue
            books.append(dict(id=b["id"], title=b["titleTemplate"], companion=b["companionID"],
                              frame=(b["structureID"], b.get("discoveryID")), pages=[p["text"] for p in a["pages"]]))
    else:
        comp = data["cell"].split("/")[1]
        for b in data["books"]:
            books.append(dict(id=b["sourceBookID"] + " (yeni)", title=b["title"], companion=comp, frame=None, pages=b["pages"]))
    return books

def check(book):
    name, phrase = CATCHPHRASES.get(book["companion"], ("", None))
    text = " ".join(book["pages"])
    issues = []
    rules = [m.group(0) for p in book["pages"] for m in RULE_RE.finditer(p)]
    if len(rules) > 1: issues.append(f"kural cümlesi {len(rules)}: {', '.join(rules[:4])}")
    long = [s for p in book["pages"] for s in sentences(p) if len(words(s)) > MAX_WORDS]
    if long: issues.append(f"uzun cümle {len(long)}: “{long[0][:60]}…”")
    budget = [(i, len(words(p))) for i, p in enumerate(book["pages"], 1) if not PAGE_MIN <= len(words(p)) <= PAGE_MAX]
    if budget: issues.append("sayfa bütçesi dışı (18-38 kelime): " + ", ".join(f"s{i}={n}" for i, n in budget))
    n_phrase = text.count(phrase) if phrase else 0
    if n_phrase > 2: issues.append(f"tekrar eden söz {n_phrase} kez")
    pages_with_name = sum(1 for p in book["pages"] if name and name in p)
    if pages_with_name < 3: issues.append(f"arkadaş adı yalnız {pages_with_name} sayfada")
    if not HUMOR_RE.search(text): issues.append("gülümseten an yok")
    rep = collections.Counter(x for p in book["pages"] for x in sentences(p) if len(words(x)) >= 3 and not (phrase and phrase in x))
    dup = [x for x, k in rep.items() if k > 1]
    if dup: issues.append(f"kitap içinde tekrar eden cümle: «{dup[0]}»")
    return dict(rules=len(rules), long=len(long), phrase=n_phrase, namePages=pages_with_name,
                humor=bool(HUMOR_RE.search(text)), issues=issues)

def shared_share(books):
    by = collections.defaultdict(list)
    for b in books:
        if b["frame"]: by[b["frame"]].append(b["pages"])
    same = total = 0
    for group in by.values():
        if len(group) < 2: continue
        for i in range(min(len(g) for g in group)):
            total += 1
            same += len({g[i] for g in group}) == 1
    return (same, total)

def shingles(text, n=4):
    w = re.findall(r"\w+", text.lower())
    return {tuple(w[i:i+n]) for i in range(len(w)-n+1)}

def cell_overlap(path):
    """Aynı hücredeki (mod+arkadaş) kitap çiftleri için 4 kelimelik öbek örtüşmesi (küçük kitaba göre)."""
    data = json.load(open(path, encoding="utf-8"))
    if not (data.get("books") and "authoredBookJSON" in data["books"][0]): return None
    cells = collections.defaultdict(list)
    for b in data["books"]:
        a = json.loads(b["authoredBookJSON"])
        cells[b["mode"] + "/" + b["companionID"]].append((b["id"], shingles(" ".join(p["text"] for p in a["pages"]))))
    worst = (0, None); vals = []
    for books in cells.values():
        for i in range(len(books)):
            for j in range(i+1, len(books)):
                x, y = books[i][1], books[j][1]
                v = len(x & y) / max(1, min(len(x), len(y))); vals.append(v)
                if v > worst[0]: worst = (v, (books[i][0], books[j][0]))
    return (sum(vals)/len(vals) if vals else 0, worst)

MAX_CELL_OVERLAP = 0.20


# Havuz geneli tekrar denetimi: birden çok dosya, ör. dalga1/kitaplar/*.json dalga2/kitaplar/*.json
MAX_POOL_SHARED_PAGES = 0.05   # başka bir kitapta harfi harfine geçen sayfa payı
MAX_POOL_SENTENCE = 25         # aynı cümlenin havuzdaki en fazla kullanımı (arkadaş sözleri hariç)
MAX_CELL_SENTENCE = 3          # aynı cümlenin bir hücredeki (mod × arkadaş) en fazla kullanımı

def pool_report(paths):
    books = [b for p in paths for b in load(p)]
    pc = collections.Counter(p for b in books for p in b["pages"])
    total = sum(len(b["pages"]) for b in books)
    shared = sum(1 for b in books for p in b["pages"] if pc[p] > 1)
    allowed = {ph for _, ph in CATCHPHRASES.values() if ph} | {"Hım hım"}
    sc = collections.Counter(s for b in books for p in b["pages"] for s in sentences(p)
                             if len(words(s)) >= 2 and not any(a in s for a in allowed))
    over = [(s, n) for s, n in sc.most_common() if n > MAX_POOL_SENTENCE]
    print(f"Havuz: {len(books)} kitap, {total} sayfa")
    print(f"Başka kitapta birebir geçen sayfa: %{100*shared/max(1,total):.0f} ({shared}), hedef en fazla %{100*MAX_POOL_SHARED_PAGES:.0f}")
    print(f"{MAX_POOL_SENTENCE} kereden sık geçen cümle: {len(over)}" + ("" if not over else " · " + "; ".join(f"«{s}» {n}" for s, n in over[:8])))
    cells = collections.defaultdict(collections.Counter)
    for p in paths:
        d = json.load(open(p, encoding="utf-8"))
        key = d.get("cell") or p
        for b in d["books"]:
            for pg in b["pages"]:
                for x in sentences(pg):
                    if len(words(x)) >= 2 and not any(a in x for a in allowed): cells[key][x] += 1
    cell_over = [(k, x, n) for k, c in cells.items() for x, n in c.items() if n > MAX_CELL_SENTENCE]
    print(f"Bir hücrede {MAX_CELL_SENTENCE} kereden sık geçen cümle: {len(cell_over)}" + ("" if not cell_over else " · " + "; ".join(f"{k}: «{x}» {n}" for k, x, n in cell_over[:20])))
    return shared / max(1, total) <= MAX_POOL_SHARED_PAGES and not over and not cell_over

def main():
    args = sys.argv[1:]
    if args and args[0] == "--pool":
        sys.exit(0 if pool_report(args[1:]) else 1)
    cell = None
    if "--cell" in args:
        cell = args[args.index("--cell") + 1]
    books = load(args[0], cell)
    totals = collections.Counter()
    failing = 0
    for b in books:
        r = check(b)
        totals["rules"] += r["rules"]; totals["long"] += r["long"]; totals["humor"] += r["humor"]
        if r["issues"]:
            failing += 1
            print(f"- {b['id']} «{b['title']}»: " + "; ".join(r["issues"]))
    titles = collections.Counter(b["title"] for b in books)
    print(f"\nKitap: {len(books)} · denetimden geçmeyen: {failing}")
    print(f"Kural kalıbı toplamı: {totals['rules']} · 14 kelimeyi aşan cümle: {totals['long']} · gülümseten anı olan kitap: {totals['humor']}")
    print(f"En çok tekrar eden başlık: {titles.most_common(1)[0] if titles else '-'}")
    same, total = shared_share(load(args[0]) if cell else books)
    if total:
        print(f"Aynı iskelette birebir aynı sayfa payı (tüm paket): %{100*same/total:.0f} ({same}/{total}), hedef en fazla %40")
    ov = cell_overlap(args[0])
    if ov:
        avg, (w, pair) = ov
        print(f"Hücre içi kitaplar arası öbek örtüşmesi: ortalama %{100*avg:.0f}, en yüksek %{100*w:.0f} {pair}, hedef en fazla %{100*MAX_CELL_OVERLAP:.0f}")
        if w > MAX_CELL_OVERLAP: failing += 1
    sys.exit(1 if failing else 0)

if __name__ == "__main__":
    main()
