#!/usr/bin/env python3
"""Günlük kataloğunu (FAZ 20) kaynak dosyalardan kurar.

Girdi:  Content/Classics/tales/*.json, Content/Classics/series/*.json,
        Content/Classics/covers.json
Çıktı:  MagicPaper/Models/Classics/classics_catalog.json (pakete girer)

Id'ler slug'dan türetilir (uuid5), her çalıştırmada aynıdır: çocukların
okuma defteri id ile tutulduğu için slug değiştirmek ilerlemeyi sıfırlar.

Kullanım: python3 Scripts/ClassicsCatalog/build_classics_catalog.py
"""
import glob, json, os, sys, uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "Content", "Classics")
OUT = os.path.join(ROOT, "MagicPaper", "Screens", "Gunluk", "Model", "classics_catalog.json")
NS = uuid.UUID("6d1f0c5e-6a47-4b8a-9f2e-0d4a6a47b820")

def uid(slug): return str(uuid.uuid5(NS, "classic:" + slug)).upper()
def load(p): return json.load(open(p, encoding="utf-8"))

covers = load(os.path.join(SRC, "covers.json"))
pending = set(covers["pending"])
credit_pending = covers["pendingCredit"]

def cover_fields(slug):
    meta = covers["covers"].get(slug)
    if meta is None and slug not in pending:
        sys.exit(f"kapak bilgisi yok: {slug} (covers.json'a ekle ya da pending'e koy)")
    focus = (meta or {}).get("focus", [0.5, 0.4])
    return {"cover": "classic-" + slug, "coverFocus": {"x": focus[0], "y": focus[1]},
            "coverCredit": (meta or {}).get("credit", credit_pending)}

series_list, series_ids = [], {}
for p in sorted(glob.glob(os.path.join(SRC, "series", "*.json"))):
    s = load(p)
    series_ids[s["slug"]] = uid(s["slug"])
    series_list.append({"id": series_ids[s["slug"]], "slug": s["slug"], "title": s["title"],
                        "byline": s["byline"], "ageMin": s["ageMin"], "ageMax": s["ageMax"],
                        "summary": s["summary"], "shelves": s["shelves"], **cover_fields(s["slug"]),
                        "attribution": s["attribution"], "bookTitle": s["bookTitle"], "unitName": s["unitName"]})

def order(path):
    t = load(path)
    return (t.get("series") or "", t.get("episode") or 0, os.path.basename(path))

tales = []
for p in sorted(glob.glob(os.path.join(SRC, "tales", "*.json")), key=order):
    t = load(p)
    sid = t.get("series")
    if sid and sid not in series_ids: sys.exit(f"{p}: seri yok: {sid}")
    cov = cover_fields(sid or t["slug"])
    tales.append({"id": uid(t["slug"]), "slug": t["slug"], "title": t["title"], "origin": t["origin"],
                  "byline": t["byline"], "ageMin": t["ageMin"], "ageMax": t["ageMax"], "minutes": t["minutes"],
                  "summary": t["summary"], "shelves": t.get("shelves") or [], **cov,
                  "attribution": t["attribution"], "soft": t["soft"], "classic": t.get("classic"),
                  "seriesID": series_ids.get(sid), "episode": t.get("episode")})

# Önce tek masallar, sonra seri bölümleri (katalog sırası raflarda görünen sıradır).
tales.sort(key=lambda t: (t["seriesID"] is not None, t["seriesID"] or "", t["episode"] or 0))
standalone_order = ["rapunzel", "kirmizi-baslikli-kiz", "pamuk-prenses", "kulkedisi", "hansel-ile-gretel",
                    "kurbaga-prens", "uyuyan-guzel", "alti-kugu", "pamuk-ile-gul", "rumpelstiltskin",
                    "kaz-cobani-kiz", "ormandaki-ev", "tavsan-ile-kaplumbaga", "kadife-tavsan",
                    "uc-turunclar", "billur-kosk"]
rank = {s: i for i, s in enumerate(standalone_order)}
tales.sort(key=lambda t: (t["seriesID"] is not None, rank.get(t["slug"], 999), t["seriesID"] or "", t["episode"] or 0))
series_order = ["keloglan", "nasreddin-hoca", "dede-korkut-bamsi-beyrek", "karagoz-ile-hacivat", "kelile-ve-dimne"]
series_list.sort(key=lambda s: series_order.index(s["slug"]) if s["slug"] in series_order else 999)

known = {t["slug"]: t["id"] for t in tales} | series_ids
picks = [known[s] for s in covers["weeklyPicks"]["slugs"] if s in known]

originals = [{"feedID": o["feedID"], **cover_fields(o["slug"]), "shelves": o["shelves"]} for o in covers["originals"]]

catalog = {"version": 1, "tales": tales, "series": series_list,
           "weeklyPicks": {"weekOf": covers["weeklyPicks"]["weekOf"], "ids": picks},
           "originals": originals,
           "pendingCovers": sorted("classic-" + s for s in pending)}
if covers.get("featured"):
    catalog["featuredID"] = known[covers["featured"]]
json.dump(catalog, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(tales)} masal ({sum(1 for t in tales if not t['seriesID'])} tek), {len(series_list)} seri, "
      f"{len(picks)} seçki, {len(originals)} orijinal -> {os.path.relpath(OUT, ROOT)}")
missing = [s for s in covers["weeklyPicks"]["slugs"] if s not in known]
if missing: print("UYARI: seçkide henüz yazılmamış:", ", ".join(missing))
