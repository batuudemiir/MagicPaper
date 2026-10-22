"""Yaş bandına göre nadir kelime raporu (22 Ekim 2026).

Katalogdaki masal satırlarını okur; her yaş bandı için o bandın okuru adına
nadir olan kelimeleri, sözlükte açıklanıp açıklanmadıklarıyla listeler. Ayrıca
çok yaygın olduğu hâlde açıklanan ve bandı dışında açıklanan sözlük girdilerini
gösterir. Öneri verir; karar yazarındır (`Glossary.swift`).

Plan: docs/Kelime_Plani_kitapokur.md (B). Yaklaşım ka1nsha/kitapokur'dan
uyarlandı; oradan kod alınmadı.

Bağımlılıklar yalnız bu betik için: wordfreq (Türkçe sıklık, Zipf ölçeği) ve
simplemma (kök). Uygulamaya ve içerik paketine girmez.

    python3 -m venv Tools/.venv
    Tools/.venv/bin/pip install -r Tools/requirements-nadir-kelime.txt
    Tools/.venv/bin/python Tools/nadir_kelime_raporu.py

Testler (yalnız stdlib): python3 Tools/test_nadir_kelime_raporu.py
"""

from __future__ import annotations

import argparse
import csv
import datetime
import io
import json
import re
import unicodedata
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parent.parent
RESOURCES = ROOT / "StoryEngine/Sources/StoryEngine/Resources"
DOCUMENTS = [
    "templates/offline/v2/shared_content_library_v2.json",
    "blueprints/pilot_library_v1.json",
]

# Bu Zipf değerinin altındaki kök o bandın okuru için nadir sayılır.
# 3-4: 22 Ekim 2026'da 4.5'ten 4.0'a (Batuhan; ilk raporda uyumak, pencere,
# bahçe nadir çıkıyordu). Diğerleri başlangıç değeri, kalibre edilmedi.
THRESHOLDS = {"3-4": 4.0, "5-6": 4.0, "7-8": 3.5, "9-10": 3.0}
BANDLESS = "bantsız"
BAND_ORDER = list(THRESHOLDS) + [BANDLESS]
CANDIDATE_CEILING = 5.0   # bunun üstü her bantta yaygın
LEMMA_DROP = 1.5          # kök, kelimeden bu kadar nadirse şüpheli
LONG_SENTENCE = 260

# Çekim ekleri (yapım ekleri değil: "usulca" "usul" olmasın), uzundan kısaya.
SUFFIXES = sorted({
    "larından", "lerinden", "larına", "lerine", "larını", "lerini", "ları", "leri", "lar", "ler",
    "ımız", "imiz", "umuz", "ümüz", "ınız", "iniz", "unuz", "ünüz",
    "ından", "inden", "undan", "ünden", "ında", "inde", "unda", "ünde",
    "ıyordu", "iyordu", "uyordu", "üyordu", "ıyor", "iyor", "uyor", "üyor", "yordu", "yor",
    "mıştı", "mişti", "muştu", "müştü", "mış", "miş", "muş", "müş",
    "acak", "ecek", "arak", "erek", "ınca", "ince", "unca", "ünce",
    "dı", "di", "du", "dü", "tı", "ti", "tu", "tü",
    "nda", "nde", "dan", "den", "tan", "ten", "da", "de", "ta", "te",
    "nın", "nin", "nun", "nün", "ın", "in", "un", "ün",
    "ya", "ye", "yı", "yi", "yu", "yü", "sı", "si", "su", "sü",
    "yla", "yle", "la", "le", "ım", "im", "um", "üm",
    "mak", "mek", "ken", "ı", "i", "u", "ü", "a", "e",
    # ek-fiil: "buradaydı" → "burada"
    "ydı", "ydi", "ydu", "ydü", "ymış", "ymiş", "ymuş", "ymüş", "dır", "dir", "dur", "dür",
    "tır", "tir", "tur", "tür",
}, key=len, reverse=True)
# Fiil gövdesinin sık biçimleri: simplemma "kork" der, metin "korktu" der.
VERB_ENDINGS = ["dı", "di", "du", "dü", "tı", "ti", "tu", "tü", "ıyor", "iyor", "uyor", "üyor",
                "mış", "miş", "muş", "müş", "ma", "me", "ar", "er", "ır", "ir", "ur", "ür"]
BACK_VOWELS, FRONT_VOWELS = set("aıou"), set("eiöü")
SOFTENED = {"b": "p", "c": "ç", "d": "t", "ğ": "k"}

SLOT = re.compile(r"\{\{[^}]+\}\}(?:['’][^\W\d_]+)?")
SLOT_MARK = "Ⓧ"  # isupper() doğru, harf değil
SLOT_SHOWN = "{…}"
WORD = re.compile(r"[^\W\d_]+(?:['’][^\W\d_]+)?")
TERMINATORS = set(".!?…")
CLOSERS = set("\"”’»)")
OPENERS = set("\"“‘«(—–-")


# MARK: - Metin

def tr_lower(s: str) -> str:
    return s.replace("I", "ı").replace("İ", "i").lower()


def infinitive(stem: str) -> str:
    """Büyük ünlü uyumuyla mastar eki."""
    for ch in reversed(stem):
        if ch in BACK_VOWELS:
            return "mak"
        if ch in FRONT_VOWELS:
            return "mek"
    return "mak"


def clean(text: str) -> str:
    """NFKC, yer tutucular yapışık ekleriyle `SLOT_MARK` olur, boşluk tekleşir.
    İşaret büyük harf sayılır ama kelime değildir: "{{child.name}} uyudu"
    cümle başı olarak kalır, ad kelime listesine girmez."""
    text = SLOT.sub(SLOT_MARK, unicodedata.normalize("NFKC", text))
    return "\n".join(" ".join(p.split()) for p in text.splitlines()).strip()


def sentences(text: str) -> list[str]:
    """Okuyucudaki kural (`MPVocabulary.sentences`): paragraf sonu böler;
    `. ! ? …` yalnız ardından büyük harf, rakam, açılan tırnak ya da tire
    gelirse böler."""
    out: list[str] = []
    for paragraph in text.splitlines():
        chars = " ".join(paragraph.split())
        start = i = 0
        while i < len(chars):
            if chars[i] in TERMINATORS:
                end = i + 1
                while end < len(chars) and (chars[end] in TERMINATORS or chars[end] in CLOSERS):
                    end += 1
                if end + 1 < len(chars) and chars[end] == " ":
                    nxt = chars[end + 1]
                    if nxt.isupper() or nxt.isdigit() or nxt in OPENERS:
                        out.append(chars[start:end])
                        start = i = end + 1
                        continue
                i = end
            else:
                i += 1
        if start < len(chars):
            out.append(chars[start:])
    return [s for s in out if s]


def example(found: list[str]) -> str:
    """İlk geçiş; çok uzunsa en kısası."""
    if not found:
        return ""
    chosen = found[0] if len(found[0]) <= LONG_SENTENCE else min(found, key=len)
    return chosen.replace(SLOT_MARK, SLOT_SHOWN)


@dataclass
class Token:
    surface: str
    sentence: str
    starts_sentence: bool
    apostrophe: bool


def tokens(text: str) -> list[Token]:
    out: list[Token] = []
    for sentence in sentences(clean(text)):
        for n, m in enumerate(WORD.finditer(sentence)):
            head, *tail = re.split(r"['’]", m.group(), maxsplit=1)
            out.append(Token(surface=head, sentence=sentence, starts_sentence=n == 0, apostrophe=bool(tail)))
    return out


# MARK: - Kök

class Analyzer:
    """Kök bulma ve sıklık. Testler sahte tablolarla kurar."""

    def __init__(self, zipf: Callable[[str], float], lemmatize: Callable[[str], str]):
        self.zipf = lru_cache(maxsize=None)(zipf)
        self.lemmatize = lru_cache(maxsize=None)(lemmatize)

    @lru_cache(maxsize=None)
    def _lemma(self, w: str) -> str | None:
        """simplemma'nın kökü; kitapokur'daki kontrolle: kelimeden çok daha
        nadirse yanlış köktür, `None`."""
        lemma = tr_lower(self.lemmatize(w) or w)
        if lemma != w and len(lemma) >= 2 and self.zipf(lemma) >= self.zipf(w) - LEMMA_DROP:
            return lemma
        return None

    @lru_cache(maxsize=None)
    def _base(self, w: str) -> str:
        if lemma := self._lemma(w):
            return lemma
        best, best_z = w, self.zipf(w)
        for cand in self._stripped(w):
            z = self.zipf(cand)
            if len(cand) >= 3 and (z > best_z or (z == best_z and z > 0 and len(cand) > len(best))):
                best, best_z = cand, z
        return best

    @lru_cache(maxsize=None)
    def root(self, word: str) -> str:
        """Raporda gösterilen kök; fiil gövdesi mastarıyla ("kork" → "korkmak")."""
        base = self._base(tr_lower(word))
        verb = base + infinitive(base)
        return verb if self.zipf(verb) > self.zipf(base) else base

    @lru_cache(maxsize=None)
    def family_zipf(self, word: str) -> float:
        """Nadirlik ölçüsü: kelimenin en yaygın makul biçimi. Türkçede sıklık
        çekimli biçimlere dağılır; çıplak gövde ("kork") kendi başına nadir
        görünür, oysa "korktu" her yerdedir."""
        w = tr_lower(word)
        forms = {w, *self._stripped(w)}
        for stem in {s for s in (self._lemma(w), self._base(w)) if s}:
            forms.add(stem)
            forms.add(stem + infinitive(stem))
            forms.update(stem + e for e in VERB_ENDINGS)
        return max(self.zipf(f) for f in forms if len(f) >= 3) if any(len(f) >= 3 for f in forms) else 0.0

    def _stripped(self, w: str, depth: int = 3) -> list[str]:
        """Sondan çekim eki soyulmuş adaylar (en çok üç katman); ünsüz
        yumuşaması geri alınır: ağac → ağaç."""
        out: list[str] = []
        frontier = [w]
        for _ in range(depth):
            nxt = []
            for word in frontier:
                for suffix in SUFFIXES:
                    if word.endswith(suffix) and len(word) - len(suffix) >= 2:
                        stem = word[: -len(suffix)]
                        nxt.append(stem)
                        if stem[-1] in SOFTENED:
                            nxt.append(stem[:-1] + SOFTENED[stem[-1]])
            out += nxt
            frontier = nxt
        return out

    def term_zipf(self, entry: "GlossaryEntry") -> float:
        """Çok kelimeli terim en nadir kelimesiyle ölçülür."""
        return min(self.zipf(tr_lower(part)) for part in entry.term.split())


# MARK: - Katalog

@dataclass
class Line:
    band: str | None
    source: str
    text: str
    words: list[str] = field(default_factory=list)


@dataclass
class GlossaryEntry:
    id: str
    term: str
    forms: list[str]
    bands: list[str]

    def keys(self) -> set[str]:
        keys = {tr_lower(self.term)} | {tr_lower(f) for f in self.forms}
        keys |= {k[:-3] for k in keys if k.endswith(("mak", "mek")) and len(k) > 5}
        return keys


def _walk(node, band: str | None, source: str, out: list[Line]) -> None:
    if isinstance(node, dict):
        band = node.get("ageBand") or node.get("ageRange") or band
        if isinstance(node.get("text"), str) and isinstance(node.get("id"), str):
            out.append(Line(band=band if band in THRESHOLDS else None, source=node["id"],
                            text=node["text"], words=list(node.get("words") or [])))
        for key, value in node.items():
            if key != "glossary":
                _walk(value, band, source, out)
    elif isinstance(node, list):
        for value in node:
            _walk(value, band, source, out)


def load_catalog(resources: Path) -> tuple[list[Line], list[GlossaryEntry], set[str], list[str]]:
    """Yükleyicinin okuduğu dosyalar (`ContentCatalogLoader`): iki belge ve
    her `beat_*.json`."""
    files = [resources / d for d in DOCUMENTS] + sorted(resources.rglob("beat_*.json"))
    lines: list[Line] = []
    glossary: list[GlossaryEntry] = []
    names = {"Ragi"}
    for path in files:
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        _walk(data, None, path.name, lines)
        for g in data.get("glossary", []) if isinstance(data, dict) else []:
            glossary.append(GlossaryEntry(id=g["id"], term=g["term"], forms=g.get("forms", []), bands=g.get("bands", [])))
        for c in data.get("companions", []) if isinstance(data, dict) else []:
            names |= set(c.get("name", "").split())
    return lines, glossary, names, [str(p.relative_to(resources)) for p in files if p.exists()]


# MARK: - Rapor

@dataclass
class Row:
    band: str
    root: str
    zipf: float
    count: int = 0
    sources: list[str] = field(default_factory=list)
    found: list[str] = field(default_factory=list)
    explained: bool = False

    @property
    def example(self) -> str:
        return example(self.found)


@dataclass
class Unnecessary:
    entry: GlossaryEntry
    band: str
    zipf: float


@dataclass
class OutOfBand:
    entry: GlossaryEntry
    band: str
    source: str


@dataclass
class Report:
    rare: dict[str, list[Row]]
    unnecessary: list[Unnecessary]
    out_of_band: list[OutOfBand]
    line_counts: dict[str, int]
    files: list[str] = field(default_factory=list)

    def unexplained(self, band: str) -> list[Row]:
        return [row for row in self.rare.get(band, []) if not row.explained]


def is_rare(zipf: float, band: str) -> bool:
    return zipf < THRESHOLDS.get(band, THRESHOLDS["3-4"])


def _proper_nouns(lines: list[Line], names: set[str]) -> set[str]:
    """Cümle ortasında büyük harfle geçip hiç küçük harfle geçmeyenler,
    kesme işaretiyle ek alanlar ve katalogdaki adlar (büyük harfle geçtiğinde)."""
    lower, mid_capital, apostrophe = set(), set(), set()
    for line in lines:
        for t in tokens(line.text):
            key = tr_lower(t.surface)
            if t.apostrophe:
                apostrophe.add(key)
            if t.surface[:1].islower():
                lower.add(key)
            elif not t.starts_sentence:
                mid_capital.add(key)
    return (mid_capital | apostrophe) - lower


def build_report(lines: list[Line], glossary: list[GlossaryEntry], names: set[str],
                 analyzer: Analyzer, files: list[str] | None = None) -> Report:
    proper = _proper_nouns(lines, names)
    name_keys = {tr_lower(n) for n in names}
    by_id = {g.id: g for g in glossary}
    rows: dict[tuple[str, str], Row] = {}
    counts: dict[str, int] = {}
    out_of_band: list[OutOfBand] = []

    for line in lines:
        band = line.band or BANDLESS
        counts[band] = counts.get(band, 0) + 1
        for wid in line.words:
            entry = by_id.get(wid)
            if entry and line.band and line.band not in entry.bands:
                out_of_band.append(OutOfBand(entry=entry, band=line.band, source=line.source))
        for t in tokens(line.text):
            key = tr_lower(t.surface)
            if key in proper or (t.surface[:1].isupper() and key in name_keys):
                continue
            root = analyzer.root(key)
            z = analyzer.family_zipf(key)
            if len(root) < 3 or not (0 < z < CANDIDATE_CEILING) or not is_rare(z, band):
                continue
            row = rows.setdefault((band, root), Row(band=band, root=root, zipf=z))
            row.count += 1
            if line.source not in row.sources:
                row.sources.append(line.source)
            if t.sentence not in row.found:
                row.found.append(t.sentence)

    for row in rows.values():
        row.explained = any(
            (row.band in g.bands or row.band == BANDLESS)
            and any(row.root == k or row.root.startswith(k) and len(k) >= 3 for k in g.keys())
            for g in glossary)

    rare: dict[str, list[Row]] = {}
    for (band, _), row in rows.items():
        rare.setdefault(band, []).append(row)
    for band in rare:
        rare[band].sort(key=lambda r: (r.zipf, r.root))

    unnecessary = [Unnecessary(entry=g, band=b, zipf=analyzer.term_zipf(g))
                   for g in glossary for b in g.bands
                   if b in THRESHOLDS and analyzer.term_zipf(g) >= THRESHOLDS[b] + 1]
    return Report(rare=rare, unnecessary=unnecessary, out_of_band=out_of_band,
                  line_counts=counts, files=files or [])


# MARK: - Çıktı

def _cell(s: str) -> str:
    return s.replace("|", "\\|").replace("\n", " ")


def _sources(row: Row, limit: int = 3) -> str:
    more = len(row.sources) - limit
    return ", ".join(row.sources[:limit]) + (f" +{more}" if more > 0 else "")


def _band_title(band: str) -> str:
    return f"Bantsız satırlar ({THRESHOLDS['3-4']} eşiğiyle)" if band == BANDLESS else f"{band} yaş"


def render_markdown(rep: Report, date: str) -> str:
    out = [f"# Nadir kelime raporu · {date}", "",
           "Kaynak: `Tools/nadir_kelime_raporu.py` (plan: `docs/Kelime_Plani_kitapokur.md` B). "
           "Öneridir; kelimeyi sadeleştirmeye ya da sözlüğe eklemeye yazar karar verir.", "",
           "Eşikler (Zipf, altı nadir): " + " · ".join(f"{b} → {t}" for b, t in THRESHOLDS.items())
           + f". {CANDIDATE_CEILING} ve üstü her bantta yaygın sayılır. 3-4 eşiği 22 Ekim 2026'da 4.5'ten 4.0'a "
           "çekildi; diğerleri başlangıç değeridir, kalibre edilmedi.", ""]
    if rep.files:
        out += [f"Okunan dosyalar: {len(rep.files)} (`ContentCatalogLoader` ile aynı küme).", ""]
    out += ["Nadirlik, kelimenin en yaygın makul biçimiyle ölçülür (kök, eki soyulmuş adaylar, "
            "fiilin sık çekimleri); Türkçede sıklık çekimli biçimlere dağıldığı için çıplak gövde tek başına "
            "nadir görünür. Kök bulma kural tabanlıdır: bazı biçimler köke inmez (\"omzuna\"), "
            "bazı fiiller gövdesiyle görünür (\"otur\"). `sözlükte`, o bandın sözlüğünde eşleşen bir girdi "
            "olduğunu söyler; satırın o kelimeyi `words` ile açıklayıp açıklamadığını değil.", ""]
    for band in BAND_ORDER:
        if band not in rep.line_counts:
            continue
        rows = rep.rare.get(band, [])
        out += [f"## {_band_title(band)}", "",
                f"{rep.line_counts[band]} satır · {len(rows)} nadir kök · "
                f"{len(rep.unexplained(band))} açıklamasız", ""]
        if rows:
            out += ["| kök | Zipf | geçiş | sözlükte | kaynak | örnek cümle |", "|---|---:|---:|---|---|---|"]
            out += [f"| {r.root} | {r.zipf:.2f} | {r.count} | {'evet' if r.explained else '**hayır**'} | "
                    f"{_cell(_sources(r))} | {_cell(r.example)} |" for r in rows]
            out.append("")
    out += ["## Gereksiz açıklama", "",
            "Sözlükte olup o bant için çok yaygın olanlar (Zipf ≥ bant eşiği + 1).", ""]
    out += ([f"- `{u.entry.id}` {u.entry.term} · {u.band} · Zipf {u.zipf:.2f}" for u in rep.unnecessary] or ["Yok."])
    out += ["", "## Bant dışı açıklama", "",
            "Satır bir sözlük girdisini açıklıyor ama girdinin `bands` alanında bu bant yok.", ""]
    out += ([f"- `{o.entry.id}` {o.entry.term} · {o.band} bandında · `{o.source}`" for o in rep.out_of_band] or ["Yok."])
    return "\n".join(out) + "\n"


def render_csv(rep: Report) -> str:
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(["bant", "kök", "zipf", "geçiş", "sözlükte", "kaynaklar", "örnek"])
    for band in BAND_ORDER:
        for r in rep.rare.get(band, []):
            w.writerow([band, r.root, f"{r.zipf:.2f}", r.count, "evet" if r.explained else "hayır",
                        " ".join(r.sources), r.example])
    return buf.getvalue()


# MARK: - Komut

def real_analyzer() -> Analyzer:
    from wordfreq import zipf_frequency
    import simplemma
    return Analyzer(zipf=lambda w: zipf_frequency(w, "tr"),
                    lemmatize=lambda w: simplemma.lemmatize(w, lang="tr"))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--resources", type=Path, default=RESOURCES)
    p.add_argument("--out", type=Path, default=ROOT / "docs/research")
    p.add_argument("--date", default=datetime.date.today().isoformat())
    a = p.parse_args()
    lines, glossary, names, files = load_catalog(a.resources)
    rep = build_report(lines, glossary, names, real_analyzer(), files)
    a.out.mkdir(parents=True, exist_ok=True)
    md = a.out / f"nadir_kelimeler_{a.date}.md"
    md.write_text(render_markdown(rep, a.date), encoding="utf-8")
    (a.out / f"nadir_kelimeler_{a.date}.csv").write_text(render_csv(rep), encoding="utf-8")
    print(f"{len(lines)} satır, {sum(len(v) for v in rep.rare.values())} nadir kök → {md}")


if __name__ == "__main__":
    main()
