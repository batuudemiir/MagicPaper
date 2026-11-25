#!/usr/bin/env python3
"""Beş arkadaş metin denetimi.

Kullanım:
  python3 p56_text_lint.py payload.json            # P56 runtime payload
  python3 p56_text_lint.py rewrites.json           # yeniden yazım taslağı
  python3 p56_text_lint.py payload.json --cell adventure/companion_hedgehog_pilot_001

Denetimler (kitap başına):
  - kural cümlesi kalıpları (en fazla 1)
  - cümle başına en fazla 14 kelime (5-6 yaş)
  - arkadaşın tekrar eden sözü en fazla 2 kez
  - arkadaşın adı en az 3 sayfada (huy anları için kaba ölçü)
  - en az bir gülümseten an
Payload için ayrıca: aynı iskeletten çıkan kitaplarda birebir aynı sayfa payı (hedef en fazla %40).
"""
import json, re, sys, collections

RULE_PATTERNS = [
    r"\byoktu\b", r"gerekmiyordu", r"zorunda değildi", r"\bdeğildi\.",
    r"kucağına almadı", r"\bçekmedi\b", r"kaldırmıyordu", r"\bezmedi\b",
    r"\bkatkı", r"tehlike", r"uçurum", r"\bsapmadı\b", r"\btahmin etmedi\b",
]
RULE_RE = re.compile("|".join(RULE_PATTERNS), re.IGNORECASE)
HUMOR_RE = re.compile(r"güldü|kıkırda|gülümse|gülerek|sevindi|top oldu", re.IGNORECASE)
CATCHPHRASES = {
    "companion_fox_pilot_001": ("Tarçın", "Bir koklayalım bakalım"),
    "companion_hedgehog_pilot_001": ("Kestane", "Küçük bir adım, sonra bir tane daha"),
    "companion_owl_pilot_001": ("Yıldız", "sen ne görüyorsun"),
    "companion_city_cat_001": ("Simit", "Şehirde böyle değil ama"),
    "companion_bear_001": ("Böğürtlen", "Acele yok, ben buradayım"),
}
MAX_WORDS = 14

def sentences(text):
    t = re.sub(r"[\"“”]", "", text)
    return [s.strip() for s in re.split(r"(?<=[.!?…])\s+", t) if s.strip()]

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
    long = [s for p in book["pages"] for s in sentences(p) if len(s.split()) > MAX_WORDS]
    if long: issues.append(f"uzun cümle {len(long)}: “{long[0][:60]}…”")
    n_phrase = text.count(phrase) if phrase else 0
    if n_phrase > 2: issues.append(f"tekrar eden söz {n_phrase} kez")
    pages_with_name = sum(1 for p in book["pages"] if name and name in p)
    if pages_with_name < 3: issues.append(f"arkadaş adı yalnız {pages_with_name} sayfada")
    if not HUMOR_RE.search(text): issues.append("gülümseten an yok")
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

def main():
    args = sys.argv[1:]
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
    sys.exit(1 if failing else 0)

if __name__ == "__main__":
    main()
