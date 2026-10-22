#!/usr/bin/env python3
"""
Validate the v3 Turkish beat corpus.

These are the gates from PROSE_PRODUCTION_GUIDE.md §4, plus the three that were
added after defects got through: the non-case-suffix lint (a copula in one
variant produced 128 render failures), the cross-beat collision check (a phrase
shared between page 4 and page 8 of the same book), and the effective-pool check
(every blueprint had a page-7 pool of two, so half of all repeat readings shared
their payoff page).

The Swift suite already renders every variant through the real Turkish resolver
(BeatCorpusRenderTests). That catches grammar. This catches everything grammar
cannot see: length, repetition, rhetorical sameness, and supply.

    python3 Tools/validate_beat_corpus.py            # check, exit 1 on failure
    python3 Tools/validate_beat_corpus.py -v         # list every variant
"""

from __future__ import annotations

import argparse
import itertools
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "Sources/StoryEngine/Resources/templates/v3"
LIBRARY = ROOT / "Sources/StoryEngine/Resources/templates/offline/v2/shared_content_library_v2.json"
SEQUENCES = Path(__file__).resolve().parent / "beat_sequences.json"
SHIPPED_BLUEPRINTS = ROOT / "Sources/StoryEngine/Resources/blueprints"

# Word bands per length class. A beat that shares its page carries a shorter
# variant, because the 18-38 band applies to the PAGE, not the variant.
BANDS = {
    None: (18, 38),
    "solo": (18, 38),
    "paired": (10, 16),
}
MAX_SENTENCE_WORDS = 14
# A bound cell below this means two books of one binding repeat the page too often.
MIN_BOUND_POOL = 4
# Masal ailem (FAZ 11): lines per relation at a family moment. Lower than
# MIN_BOUND_POOL on purpose — the pilot set is two per cell, and a relation with
# one line would give every book with that character the same opening.
MIN_FAMILY_CELL = 2
FAMILY_RELATIONS = ("sibling", "friend", "animal", "imaginary")
UNHARMONISED_CONJUNCTION = re.compile(r"\}\}(?:'[a-zçğıöşü]+)? (?:da|de|ta|te)\b")
AGE3_CORPUS = ROOT / "Sources/StoryEngine/Resources/templates/v3-age3"
# Series episodes (FAZ 13): lines only a continuation episode uses.
SERIES_CORPUS = ROOT / "Sources/StoryEngine/Resources/templates/series"
# Uyku arkı (21 Ekim 2026): lines only a bedtime-arc blueprint reads.
BEDTIME_CORPUS = ROOT / "Sources/StoryEngine/Resources/templates/bedtime"
# What no bedtime line or place may touch. Same list as
# `NarrativeArc.bedtimeExcludedTopics` in the engine.
BEDTIME_EXCLUDED_TOPICS = ("darkness", "alone", "fear")
# How an episode may not end (karar: 6 Ekim 2026). The same list as
# `CalmEnding` in the engine: word prefixes, then phrases. "ama" is allowed.
CALM_WORD_PREFIXES = ("yarın", "acaba", "birden")
CALM_PHRASES = ("?", "sonra ne olacak")

# Suffixes the Turkish renderer understands. Anything else after a slot — a
# copula like 'ydi, a typo — is emitted verbatim and reported at render time.
CASE_SUFFIXES = {
    "a", "e", "ne", "na", "ya", "ye",
    "da", "de", "ta", "te", "nda", "nde", "nta", "nte",
    "in", "ın", "un", "ün", "nin", "nın", "nun", "nün",
    "i", "ı", "u", "ü", "yi", "yı", "yu", "yü", "ni", "nı", "nu", "nü",
    "den", "dan", "ten", "tan", "nden", "ndan", "nten", "ntan",
    "daki", "deki", "taki", "teki", "ndaki", "ndeki", "ntaki", "nteki",
}

SLOT_PATTERN = re.compile(r"\{\{([a-z.]+)\}\}(?:'([a-zçğıöşü]+))?")
TOKEN_PATTERN = re.compile(r"\{\{([a-z.]+)\}\}")

# Nouns that imply a particular kind of place. A variant using one must declare
# the setting trait that guarantees it, or it renders as trees inside a cloud
# kingdom. Word-boundary matched so "kar" does not fire inside "Karşısında".
PLACE_NOUNS = re.compile(
    r"\b(ağaç\w*|orman\w*|deniz\w*|dalga\w*|kar|karlar\w*|kum\w*|mağara\w*|"
    r"köprü\w*|duvar\w*|çiçek\w*|yıldız\w*|gemi\w*|çimen\w*|yaprak\w*)\b",
    re.IGNORECASE,
)


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.notes: list[str] = []

    def fail(self, message: str) -> None:
        self.failures.append(message)

    def note(self, message: str) -> None:
        self.notes.append(message)

    @property
    def ok(self) -> bool:
        return not self.failures


def load_corpus() -> list[dict]:
    files = sorted(CORPUS.glob("beat_*.json"))
    if not files:
        sys.exit(f"no beat files under {CORPUS}")
    return [json.loads(path.read_text(encoding="utf-8")) for path in files]


def binding_extremes() -> list[dict[str, str]]:
    """
    Word count shifts with what binds: a one-word name in a two-word place is
    four or five words shorter than a long name in `Şırıl Şırıl Nehir`. Checking
    one binding passes variants that fail another, so the extremes come from the
    real library rather than being invented here.
    """
    fallback = [
        {"child.name": "Ada", "setting.name": "Minik Köy", "companion.name": "Zip",
         "companion.type": "robot", "discovery.name": "ayak izleri"},
        {"child.name": "Abdullah", "setting.name": "Şırıl Şırıl Nehir", "companion.name": "Böğürtlen",
         "companion.type": "kaplumbağa", "discovery.name": "parlayan bir deniz kabuğu"},
    ]
    if not LIBRARY.exists():
        return fallback

    library = json.loads(LIBRARY.read_text(encoding="utf-8"))
    settings = [s["name"] for s in library.get("settings", [])]
    companions = library.get("companions", [])
    objects = [o["name"] for o in library.get("objects", [])]
    if not (settings and companions and objects):
        return fallback

    def shortest(values): return min(values, key=lambda v: len(v.split()))
    def longest(values): return max(values, key=lambda v: len(v.split()))

    short_companion = shortest([c["name"] for c in companions])
    long_companion = longest([c["name"] for c in companions])
    return [
        {"child.name": "Ada", "setting.name": shortest(settings),
         "companion.name": short_companion,
         "companion.type": shortest([c["type"] for c in companions]),
         "discovery.name": shortest(objects)},
        {"child.name": "Abdullah", "setting.name": longest(settings),
         "companion.name": long_companion,
         "companion.type": longest([c["type"] for c in companions]),
         "discovery.name": longest(objects)},
    ]


def render(text: str, binding: dict[str, str]) -> str:
    """Substitute slots and drop suffix markers. Word counts only — the Swift
    suite owns actual grammar."""
    for key, value in binding.items():
        text = text.replace("{{%s}}" % key, value)
    return SLOT_PATTERN.sub(lambda m: m.group(0), re.sub(r"'[a-zçğıöşü]+", "", text))


def ngrams(text: str, binding: dict[str, str], size: int = 5) -> set[str]:
    words = render(text, binding).lower()
    for char in ',.:"?!;':
        words = words.replace(char, "")
    parts = words.split()
    return {" ".join(parts[i:i + size]) for i in range(len(parts) - size + 1)}


def band_for(beat_file: dict, length_class: str | None) -> tuple[int, int]:
    """
    Read the band the FILE declares, falling back to the defaults.

    The engine reads bands from `lengthClasses` too, so a hardcoded table here
    would be a second source that drifts — the same defect as keeping
    produces/requires in the content files. The declaration wins.
    """
    declared = beat_file.get("lengthClasses", {}).get(length_class)
    if isinstance(declared, str):
        match = re.match(r"\s*(\d+)\s*-\s*(\d+)\s+words", declared)
        if match:
            return int(match.group(1)), int(match.group(2))
    return BANDS[length_class]


# --- checks -----------------------------------------------------------------

def check_lengths(corpus, bindings, report, verbose) -> None:
    for beat_file in corpus:
        beat = beat_file["beat"]
        for variant in beat_file["variants"]:
            low, high = band_for(beat_file, variant.get("lengthClass"))
            counts = [len(render(variant["text"], b).split()) for b in bindings]
            sentences = [s for s in re.split(r"[.!?]", render(variant["text"], bindings[-1])) if s.strip()]
            longest = max(len(s.split()) for s in sentences) if sentences else 0
            if min(counts) < low or max(counts) > high:
                report.fail(f"{beat}/{variant['id']}: {min(counts)}-{max(counts)} words, band is {low}-{high}")
            if longest > MAX_SENTENCE_WORDS:
                report.fail(f"{beat}/{variant['id']}: longest sentence {longest} words, max {MAX_SENTENCE_WORDS}")
            if verbose:
                print(f"    {variant['id']:24} {min(counts)}-{max(counts)}w  longest {longest}w")


def check_suffixes(corpus, report) -> None:
    """A non-case suffix after a slot renders verbatim. One copula ('di) in one
    variant failed 128 render assertions."""
    for beat_file in corpus:
        for variant in beat_file["variants"]:
            for match in SLOT_PATTERN.finditer(variant["text"]):
                suffix = match.group(2)
                if suffix and suffix not in CASE_SUFFIXES:
                    report.fail(
                        f"{beat_file['beat']}/{variant['id']}: '{suffix}' is not a case ending "
                        f"(copula? typo?) — the renderer will emit it verbatim"
                    )


def check_declared_slots(corpus, report) -> None:
    for beat_file in corpus:
        for variant in beat_file["variants"]:
            used = set(TOKEN_PATTERN.findall(variant["text"]))
            declared = set(variant.get("requiredSlots", []))
            if used != declared:
                report.fail(
                    f"{beat_file['beat']}/{variant['id']}: requiredSlots {sorted(declared)} "
                    f"but text uses {sorted(used)}"
                )


def check_collisions(corpus, bindings, report) -> None:
    """Shared 5-grams. The engine's repetition validator allows zero repeated
    n-grams in a book, so two variants that can land in the same story must not
    share one — within a beat or across beats."""
    flat = [(bf["beat"], v) for bf in corpus for v in bf["variants"]]
    seen: set[tuple[str, str]] = set()
    for (beat_a, a), (beat_b, b) in itertools.combinations(flat, 2):
        key = (a["id"], b["id"])
        if key in seen:
            continue
        for binding in bindings:
            shared = ngrams(a["text"], binding) & ngrams(b["text"], binding)
            if shared:
                seen.add(key)
                scope = "within" if beat_a == beat_b else "across"
                report.fail(
                    f"{scope}-beat collision {beat_a}/{a['id']} <-> {beat_b}/{b['id']}: "
                    f"{sorted(shared)[0]!r}"
                )
                break


def check_moves(corpus, report) -> None:
    """Every variant carries a distinct rhetorical move. This is what stops
    sixteen sentences from being one sentence sixteen ways."""
    moves = Counter()
    owners: dict[str, list[str]] = {}
    for beat_file in corpus:
        for variant in beat_file["variants"]:
            move = variant.get("move")
            if not move:
                report.fail(f"{beat_file['beat']}/{variant['id']}: no `move` declared")
                continue
            moves[move] += 1
            owners.setdefault(move, []).append(f"{beat_file['beat']}/{variant['id']}")
    for move, count in moves.items():
        if count > 1:
            report.fail(f"rhetorical move {move!r} used {count}x: {owners[move]}")


def check_family_lines(corpus, report) -> None:
    """Masal ailem lines, in both bands. The 3-4 corpus is read here too,
    because the family moments exist there as well and nothing else in this
    script looks at it.

    - every beat that carries family lines has at least MIN_FAMILY_CELL for
      every relation, so a relation is never one sentence;
    - a family line names the character, and only family lines do;
    - an imaginary friend is "hayali arkadaşı" or just the name, never
      "hayali varlığı" (karar: 4 Ekim 2026).
    """
    files = list(corpus)
    for path in sorted(AGE3_CORPUS.glob("beat_*.json")):
        files.append(json.loads(path.read_text(encoding="utf-8")))
    for beat_file in files:
        label = f"{beat_file['beat']}[{beat_file.get('ageBand', '?')}]"
        cells = Counter()
        for variant in beat_file["variants"]:
            relations = variant.get("familyRelations", [])
            names = "{{family.name}}" in variant["text"]
            if relations and not names:
                report.fail(f"{label}/{variant['id']}: written for {relations} but never names the character")
            if names and not relations:
                report.fail(f"{label}/{variant['id']}: names a family character but declares no familyRelations")
            # The child opens the story (karar: 4 Ekim 2026): a family opening
            # names the child in its first sentence, so "Kardeşi Ela …" is
            # never the book's first sentence.
            if relations and beat_file["beat"] == "notice_anomaly":
                first = re.split(r"(?<=[.!?…])\s", variant["text"], maxsplit=1)[0]
                if "{{child.name}}" not in first:
                    report.fail(f"{label}/{variant['id']}: the first sentence must name the child")
            if "hayali varlı" in variant["text"].lower():
                report.fail(f"{label}/{variant['id']}: says 'hayali varlık' — write 'hayali arkadaşı' or just the name")
            for relation in relations:
                cells[relation] += 1
        if cells:
            for relation in FAMILY_RELATIONS:
                if cells[relation] < MIN_FAMILY_CELL:
                    report.fail(f"{label}: {cells[relation]} line(s) for a '{relation}' family character, "
                                f"need {MIN_FAMILY_CELL}")
            report.note(f"{label}: family lines " + ", ".join(
                f"{r}={cells[r]}" for r in FAMILY_RELATIONS))


def check_conjunctions(corpus, report) -> None:
    """"da/de" written after a slot cannot follow the name's vowel harmony: the
    same line gives "Ela da" and "Can de". Every line, in both bands — the
    child's name and a companion's are as varied as a family character's."""
    files = list(corpus)
    for path in sorted(AGE3_CORPUS.glob("beat_*.json")):
        files.append(json.loads(path.read_text(encoding="utf-8")))
    for beat_file in files:
        label = f"{beat_file['beat']}[{beat_file.get('ageBand', '?')}]"
        for variant in beat_file["variants"]:
            if UNHARMONISED_CONJUNCTION.search(variant["text"]):
                report.fail(f"{label}/{variant['id']}: 'da/de' after a slot does not follow the name's vowel harmony")


def calm_violations(text: str) -> list[str]:
    lowered = text.replace("I", "ı").replace("İ", "i").lower()
    words = re.findall(r"[a-zçğıöşüâîû]+", lowered)
    found = [p for p in CALM_PHRASES if p in lowered]
    found += [p for p in CALM_WORD_PREFIXES if any(w.startswith(p) for w in words)]
    return found


def series_bindings() -> list[dict[str, str]]:
    """The shortest and longest names the pilot library can bind, since the
    series is only ever written from the pilot's beat-model content."""
    library = _pilot_library() or {}
    settings = [s["name"] for s in library.get("settings", [])] or ["Minik Köy"]
    companions = library.get("companions", []) or [{"name": "Zip"}]
    objects = [o for o in library.get("objects", []) if o.get("traits")] or [{"name": "bir şey"}]
    def words(v): return len(v.split())
    def pick(values, f): return f(values, key=words)
    names = [c["name"] for c in companions]
    keeps = [o.get("keepsakeName", o["name"]) for o in objects]
    finds = [o["name"] for o in objects]
    return [
        {"child.name": "Ada", "setting.name": pick(settings, min), "companion.name": pick(names, min),
         "keepsake.name": pick(keeps, min), "discovery.name": pick(finds, min),
         "family.name": "Ela", "family.possessive": "kedisi"},
        {"child.name": "Abdullah", "setting.name": pick(settings, max), "companion.name": pick(names, max),
         "keepsake.name": pick(keeps, max), "discovery.name": pick(finds, max),
         "family.name": "Karamelli Pofuduk", "family.possessive": "kaplumbağası"},
    ]


def _check_line_file(beat_file, label, bindings, report, *, calm_label) -> int:
    """The per-line rules every layer outside v3 is held to (series, bedtime):
    word band from the file, sentence ceiling from the band (3-4: 10), case
    suffixes, declared slots, no "da/de" after a slot, family lines that name
    the character and only they do, MIN_FAMILY_CELL lines per relation, a
    place noun only with the setting trait that guarantees it, and a
    `warm_close` that ends calmly. Returns the number of lines checked."""
    band = beat_file.get("ageBand", "?")
    ceiling = 10 if band == "3-4" else MAX_SENTENCE_WORDS
    cells = Counter()
    total = 0
    for variant in beat_file["variants"]:
        total += 1
        vid = f"{label}/{variant['id']}"
        text = variant["text"]
        klass = variant.get("lengthClass")
        low, high = band_for(beat_file, klass)
        counts = [len(render(text, b).split()) for b in bindings]
        if min(counts) < low or max(counts) > high:
            report.fail(f"{vid}: {min(counts)}-{max(counts)} words, band is {low}-{high}")
        for b in bindings:
            sentences = [x for x in re.split(r"[.!?:]", render(text, b)) if x.strip()]
            longest = max((len(x.split()) for x in sentences), default=0)
            if longest > ceiling:
                report.fail(f"{vid}: longest sentence {longest} words, max {ceiling}")
                break
        for match in SLOT_PATTERN.finditer(text):
            if match.group(2) and match.group(2) not in CASE_SUFFIXES:
                report.fail(f"{vid}: '{match.group(2)}' is not a case ending")
        used = set(TOKEN_PATTERN.findall(text))
        if used != set(variant.get("requiredSlots", [])):
            report.fail(f"{vid}: requiredSlots {sorted(variant.get('requiredSlots', []))} but text uses {sorted(used)}")
        if UNHARMONISED_CONJUNCTION.search(text):
            report.fail(f"{vid}: 'da/de' after a slot does not follow the name's vowel harmony")
        if "hayali varlı" in text.lower():
            report.fail(f"{vid}: says 'hayali varlık'")
        relations = variant.get("familyRelations", [])
        names = "{{family.name}}" in text
        if relations and not names:
            report.fail(f"{vid}: written for {relations} but never names the character")
        if names and not relations:
            report.fail(f"{vid}: names a family character but declares no familyRelations")
        if relations and beat_file["beat"] == "revisit":
            first = re.split(r"(?<=[.!?…])\s", text, maxsplit=1)[0]
            if "{{child.name}}" not in first:
                report.fail(f"{vid}: the first sentence must name the child")
        for relation in relations:
            cells[relation] += 1
        if not variant.get("settingTraits"):
            found = PLACE_NOUNS.findall(TOKEN_PATTERN.sub("", text))
            if found:
                report.fail(f"{vid}: names {sorted(set(found))} but declares no settingTraits")
        if beat_file["beat"] == "warm_close":
            wrong = calm_violations(text)
            if wrong:
                report.fail(f"{vid}: {calm_label} must end calmly, found {wrong}")
    if cells:
        for relation in FAMILY_RELATIONS:
            if cells[relation] < MIN_FAMILY_CELL:
                report.fail(f"{label}: {cells[relation]} line(s) for '{relation}', need {MIN_FAMILY_CELL}")
    return total


def check_series_lines(report) -> None:
    """Series episode lines (FAZ 13), both bands, held to every rule the
    standalone lines are — and to the calm ending on the closing beat.

    - each file says `series: true`, so the engine keeps it out of standalone
      stories;
    - every per-line rule in `_check_line_file`; an opening (`revisit`) names
      the child first.
    """
    paths = sorted(SERIES_CORPUS.glob("beat_*.json"))
    if not paths:
        report.note("series: no episode lines yet")
        return
    bindings = series_bindings()
    total = 0
    for path in paths:
        beat_file = json.loads(path.read_text(encoding="utf-8"))
        label = f"series {beat_file['beat']}[{beat_file.get('ageBand', '?')}]"
        if beat_file.get("series") is not True:
            report.fail(f"{label}: {path.name} is in the series folder but does not say series: true")
        total += _check_line_file(beat_file, label, bindings, report, calm_label="an episode")
    report.note(f"series: {len(paths)} beat files, {total} lines")


def check_bedtime_lines(report) -> None:
    """Uyku arkı lines (arc: bedtime, 21 Ekim 2026), both bands.

    - each file says `arc: bedtime`, so the engine gives it only to a
      bedtime-arc blueprint and to nothing else;
    - every per-line rule in `_check_line_file`, and the calm ending;
    - no line touches the dark, being alone, or fear (privacy-safety koşul 1).
    """
    paths = sorted(BEDTIME_CORPUS.glob("beat_*.json"))
    if not paths:
        report.note("bedtime: no bedtime lines yet")
        return
    bindings = [dict(b, **{"companion.type": t}) for b, t in zip(series_bindings(), ("kirpi", "kaplumbağa"))]
    total = 0
    for path in paths:
        beat_file = json.loads(path.read_text(encoding="utf-8"))
        label = f"bedtime {beat_file['beat']}[{beat_file.get('ageBand', '?')}]"
        if beat_file.get("arc") != "bedtime":
            report.fail(f"{label}: {path.name} is in the bedtime folder but does not say arc: bedtime")
        for variant in beat_file["variants"]:
            touched = sorted(set(t.lower() for t in variant.get("topics", [])) & set(BEDTIME_EXCLUDED_TOPICS))
            if touched:
                report.fail(f"{label}/{variant['id']}: a bedtime line touches {touched}")
        total += _check_line_file(beat_file, label, bindings, report, calm_label="a bedtime story")
    report.note(f"bedtime: {len(paths)} beat files, {total} lines")


def check_banned(corpus, report) -> None:
    for beat_file in corpus:
        banned = [p.lower() for p in beat_file.get("bannedConstructions", [])]
        for variant in beat_file["variants"]:
            lowered = variant["text"].lower()
            for phrase in banned:
                if phrase in lowered:
                    report.fail(f"{beat_file['beat']}/{variant['id']}: banned construction {phrase!r}")


def check_place_welding(corpus, report) -> None:
    """A variant naming a place feature must declare the setting trait that
    guarantees it — otherwise it renders as trees inside a cloud kingdom."""
    for beat_file in corpus:
        for variant in beat_file["variants"]:
            if variant.get("settingTraits"):
                continue
            stripped = TOKEN_PATTERN.sub("", variant["text"])
            found = PLACE_NOUNS.findall(stripped)
            if found:
                report.fail(
                    f"{beat_file['beat']}/{variant['id']}: names {sorted(set(found))} "
                    f"but declares no settingTraits"
                )


def shipped_sequences() -> list[dict]:
    """
    Blueprints the ENGINE ships, which are not the same set as my fixture.

    This check exists because it was missed: `hesitate` had no paired variants
    because my own 14 blueprints never pair it — but a shipped pilot puts it
    beside `commit` on page 4, and the composer had nothing to choose. Reading
    only my fixture made the corpus look complete when it was not.
    """
    out: list[dict] = []
    if not SHIPPED_BLUEPRINTS.exists():
        return out
    for path in sorted(SHIPPED_BLUEPRINTS.glob("*.json")):
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        for blueprint in document.get("blueprints", []):
            # A bedtime-arc blueprint reads only the bedtime folder, which
            # `check_bedtime_lines` and the Swift suite hold to account; the
            # v3 corpus never serves it.
            if blueprint.get("arc", "standard") != "standard":
                continue
            beats = []
            for page in blueprint.get("pages", []):
                slot = [b for b in (page.get("beat"), page.get("supportingBeat")) if b]
                if slot:
                    beats.append(slot)
            if beats:
                out.append({
                    "id": blueprint.get("id", path.stem),
                    "beats": beats,
                    "requires": blueprint.get("requires"),
                    "forbids": blueprint.get("forbids"),
                })
    return out


def check_length_class_coverage(corpus, report) -> None:
    """Every (beat, length class) a shipped or fixture blueprint asks for must
    be authored. An unmet ask makes the composer fall back to the wrong length
    and blow the page budget."""
    have: dict[str, set] = {}
    for beat_file in corpus:
        have[beat_file["beat"]] = {v.get("lengthClass") for v in beat_file["variants"]}

    sequences = shipped_sequences()
    if SEQUENCES.exists():
        sequences += json.loads(SEQUENCES.read_text(encoding="utf-8"))["blueprints"]
    if not sequences:
        report.note("length-class coverage skipped: no blueprints found")
        return

    demand: dict[tuple[str, str], set[str]] = {}
    for blueprint in sequences:
        for slot in blueprint["beats"]:
            needed = "paired" if len(slot) > 1 else "solo"
            for beat in slot:
                demand.setdefault((beat, needed), set()).add(blueprint["id"])

    for (beat, needed), who in sorted(demand.items()):
        if beat in have and needed not in have[beat]:
            report.fail(
                f"{beat}: no `{needed}` variant authored, but {len(who)} blueprint(s) "
                f"need one — e.g. {sorted(who)[0]}"
            )
    report.note(f"length-class coverage checked against {len(sequences)} blueprints")


# Keys that describe the variant itself rather than gating when it is eligible.
# Everything else in a variant is a filter of some kind.
STRUCTURAL_KEYS = {"id", "text", "requiredSlots", "lengthClass", "move"}


def check_partitioned_pools(corpus, report) -> None:
    """
    Any key EVERY variant of a beat declares partitions that beat's supply.

    This replaces a hardcoded list of two axes (`register`, `conflictKinds`)
    which was incomplete when it was written — it missed `afterClosing` on
    `warm_close` and `afterState` on `commit`. Listing the axes is the same
    mistake as listing the bindings: a check must derive what it expects from
    the thing it is checking, never hold its own copy.

    The test is derivable from the corpus alone and needs no mapping. If some
    variants of a beat leave a key undeclared, those are an unconditional floor
    and a rare value is a bonus on top of it. If NONE do, the key's values carve
    the beat into cells, every story lands in exactly one, and each value must
    clear the floor by itself — whatever the engine derives the wanted value
    from, and whether or not this file can see that derivation.

    Caught at 3/3 (`form_belief.register`) and 1 (`obstacle_raises.duration`).
    """
    for beat_file in corpus:
        variants = beat_file["variants"]
        if not variants:
            continue
        candidates = {k for v in variants for k in v} - STRUCTURAL_KEYS
        for key in sorted(candidates):
            if any(not v.get(key) for v in variants):
                continue                      # an unconditional floor exists
            counts: dict[str, int] = {}
            for variant in variants:
                declared = variant[key]
                for value in ([declared] if isinstance(declared, str) else declared):
                    counts[value] = counts.get(value, 0) + 1
            for value, count in sorted(counts.items()):
                if count < MIN_BOUND_POOL:
                    report.fail(
                        f"{beat_file['beat']}: every variant declares `{key}`, so its values are "
                        f"cells — `{value}` holds {count}, and every story the engine sends there "
                        f"shares this page {1 / count:.0%} of the time"
                    )
            report.note(f"{beat_file['beat']}: `{key}` partitions into "
                        + ", ".join(f"{v}={n}" for v, n in sorted(counts.items())))


# Verbs that claim the child SAW or HEARD the discovery. A variant using one is
# asserting which sense the discovery reaches.
SEEING = re.compile(r"gördü|görüyordu|görünüyordu|görmüştü|baktı|bakıyordu|izledi|seyretti"
                    r"|göze çarp|parıltı|ışıl")
HEARING = re.compile(r"duydu|duyuyordu|duyuldu|dinledi|kulak|mırıl|tıkırtı|çıtırtı")
# Traits that guarantee the discovery can be seen / heard.
VISIBLE_TRAITS = {"isVisible", "isBeautiful"}
AUDIBLE_TRAITS = {"isAudible"}


TRAITS_SOURCE = ROOT / "Sources/StoryEngine/Content/ContentTraits.swift"

# Discovery traits this file has classified. Membership is a judgement about the
# WORLD (can you look at it, can you hear it), so it cannot be derived — which
# is exactly why it must be alarmed rather than trusted.
CLASSIFIED_DISCOVERY_TRAITS = (
    VISIBLE_TRAITS | AUDIBLE_TRAITS | {
        "isUnexplained", "emitsSignal", "impliesPresence",
        "impliesNeed", "isFragmentary", "isFragile",
    }
)


def check_deferrals_still_hold(corpus, report) -> None:
    """
    Alarms on the FACTS three decisions rest on, not on the decisions.

    Borrowed from the engine session, which hit a filter that hid every story
    idea because the catalog has exactly one age band. Their fix pins the
    premise: the test fails when a second band exists and names what to
    re-enable. Nobody has to remember to revisit it.

    Several choices here are "correct for now, because of a fact about the
    content today", and each lived only as a comment somebody had to happen to
    re-read.
    """
    # 1. Every band decision, sentence cap and word choice is calibrated for 5-6.
    bands = {bf.get("ageBand") for bf in corpus}
    if bands != {"5-6"}:
        report.fail(
            f"age bands are now {sorted(b for b in bands if b)} — the word bands, the "
            f"{MAX_SENTENCE_WORDS}-word sentence cap and the vocabulary in this corpus are "
            f"calibrated for 5-6 only. A second band needs its own bands, not these.")

    # 2. `check_bound_pools` reimplements the composer's filtering. That is a
    #    second copy of a rule, tolerated only because the 14 catalog blueprints
    #    live in a fixture the engine cannot see. Once they ship, the engine's
    #    own BoundPoolTests covers this from the authoritative side.
    shipped = set()
    for path in sorted(SHIPPED_BLUEPRINTS.glob("*.json")):
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        shipped |= {b.get("id") for b in document.get("blueprints", [])}
    if SEQUENCES.exists():
        fixture = {b["id"] for b in json.loads(SEQUENCES.read_text(encoding="utf-8"))["blueprints"]}
        landed = fixture & shipped
        if landed:
            report.fail(
                f"{len(landed)} catalog blueprint(s) now ship in the engine "
                f"(e.g. {sorted(landed)[0]}) — delete check_bound_pools and this fixture's "
                f"constraint blocks; BoundPoolTests covers them from the composer itself, and "
                f"two copies of the filtering rule is the defect this project keeps finding.")

    # 3. `check_modality_claims` knows two senses. A third would be under-checked
    #    in silence, which is how `isVisible` shipping without `isAudible` went
    #    unnoticed: one modality declared reads as modality handled.
    if TRAITS_SOURCE.exists():
        source = TRAITS_SOURCE.read_text(encoding="utf-8")
        block = re.search(r"enum DiscoveryTrait[^{]*\{(.*?)\n\}", source, re.S)
        if block:
            lines = re.findall(r"^\s*case\s+([A-Za-z0-9_,\s]+?)\s*$", block.group(1), re.M)
            names = {n.strip() for line in lines for n in line.split(",") if n.strip()}
            unknown = names - CLASSIFIED_DISCOVERY_TRAITS
            if unknown:
                report.fail(
                    f"DiscoveryTrait has grown {sorted(unknown)} — check_modality_claims only "
                    f"knows {sorted(VISIBLE_TRAITS)} and {sorted(AUDIBLE_TRAITS)}. Classify the "
                    f"new trait or the modality gate under-checks silently.")
            else:
                report.note(f"deferrals hold: one age band, {len(names)} discovery traits all "
                            f"classified, catalog blueprints still fixture-only")


def check_modality_claims(corpus, report) -> None:
    """
    A line may only claim a sense the discovery is guaranteed to reach.

    `emitsSignal` is worn by a light and by a sound, so it says something is
    salient, not how. Six variants gated on it could open a book by listening to
    a light or watching a sound blink. That was invisible to every other gate:
    each line is well-formed, inside its band, collision-free and reachable. It
    is merely about the wrong sense.

    The dangerous case is the UNCONDITIONAL variant. Those exist as a floor that
    lifts every cell at once, which means they are offered for every discovery —
    so a seeing verb in one is a claim no discovery can be relied on to honour.
    Five written as a floor were visual.
    """
    for beat_file in corpus:
        # A beat is about the discovery if ANY of its variants gates on a
        # discovery trait. Scoping by `discovery.name` in requiredSlots was the
        # first cut and was wrong: `na_sound_01` opens with "Önce sesi duydu"
        # and never interpolates the name, so the check skipped the very variant
        # that started this.
        about_discovery = any(v.get("discoveryTraits") for v in beat_file["variants"])
        for variant in beat_file["variants"]:
            if not about_discovery and "discovery.name" not in (variant.get("requiredSlots") or []):
                continue
            declared = set(variant.get("discoveryTraits") or [])
            text = variant["text"]
            seen, heard = SEEING.search(text), HEARING.search(text)
            if seen and not (declared & VISIBLE_TRAITS):
                report.fail(
                    f"{beat_file['beat']}/{variant['id']}: says `{seen.group(0)}` but declares "
                    f"{sorted(declared) or 'no discovery trait'} — nothing guarantees this "
                    f"discovery can be seen")
            if heard and not (declared & AUDIBLE_TRAITS):
                report.fail(
                    f"{beat_file['beat']}/{variant['id']}: says `{heard.group(0)}` but declares "
                    f"{sorted(declared) or 'no discovery trait'} — nothing guarantees this "
                    f"discovery can be heard")


def check_variants_reachable(corpus, report) -> None:
    """
    A variant whose declared traits match no content record can never be chosen.

    This is the Phase 1 defect in miniature. That audit measured 41% of the
    shipped corpus unreachable and the fix was structural — beats, state, a
    liveness rule. None of that helps here: these variants are reachable in the
    ARC and unreachable in the CONTENT, because they ask for a trait combination
    no setting or discovery actually has. Nothing fails; the line simply never
    appears, and the beat looks better supplied than it is.

    Found six: three asking for `emitsSignal ∧ isBeautiful` (no discovery has
    both — the pairing was over-specified) and three asking for a `hasWeather`
    setting, which the engine's own report had already flagged as declared and
    unexercised.
    """
    library = _pilot_library()
    if not library:
        report.note("reachability check skipped: no content library found")
        return
    settings = [set(s.get("traits", [])) for s in library["settings"]]
    discoveries = [set(o.get("traits", [])) for o in library["objects"]]
    companions = [set(c.get("traits", [])) for c in library["companions"]]
    roles = {r for c in library["companions"] for r in c.get("castRoles", [])}
    natures = {c.get("nature", "animal") for c in library["companions"]}

    for beat_file in corpus:
        for variant in beat_file["variants"]:
            reasons = []
            wanted = set(variant.get("settingTraits") or [])
            if wanted and not any(wanted <= held for held in settings):
                reasons.append(f"no setting has {sorted(wanted)}")
            wanted = set(variant.get("discoveryTraits") or [])
            if wanted and not any(wanted <= held for held in discoveries):
                reasons.append(f"no discovery has {sorted(wanted)}")
            wanted = set(variant.get("capabilityRequire") or [])
            if wanted and not any(wanted <= held for held in companions):
                reasons.append(f"no companion has {sorted(wanted)}")
            # A line written for a nature nobody in the pool has is a line no
            # child can be read. Mirrors `CatalogVariant.suits(nature:)`.
            wanted = set(variant.get("natureRequire") or [])
            if wanted and not (wanted & natures):
                reasons.append(f"no companion is {sorted(wanted)}")
            wanted = set(variant.get("castRoles") or [])
            if wanted and not (wanted & roles):
                reasons.append(f"no companion can be cast as {sorted(wanted)}")
            if reasons:
                report.fail(f"{beat_file['beat']}/{variant['id']}: unreachable — "
                            + "; ".join(reasons))


def check_blueprints_satisfiable(corpus, report) -> None:
    """
    A blueprint that matches no content is a silent hole, not a thin cell.

    `check_bound_pools` reports empty CELLS. A blueprint with no legal binding
    contributes no cells at all, so it passes that check by producing nothing —
    the failure mode is absence, and absence is what a walk cannot see.

    This is the defect that took `bp_threshold_joining_002` out of the catalog
    without anyone noticing: `thresholdKind = social` was required and no setting
    offered one. BLUEPRINT_CATALOG_V2 §6 recorded that as resolved because the
    BLUEPRINT had been rebuilt, which settled the architecture and not the
    content. Nothing could see the difference until the engine's load-time
    unexercised-vocabulary report met that claim.
    """
    library = _pilot_library()
    if not library:
        report.note("satisfiability check skipped: no content library found")
        return
    sequences = shipped_sequences()
    if SEQUENCES.exists():
        sequences += json.loads(SEQUENCES.read_text(encoding="utf-8"))["blueprints"]

    all_roles = {"guide", "needsCare", "hesitant", "reassuring"}
    for blueprint in sequences:
        requires = blueprint.get("requires") or {}
        forbids = blueprint.get("forbids") or {}
        if not requires and not forbids:
            continue
        legal = 0
        blocked: set[str] = set()
        for setting in library["settings"]:
            traits = set(setting.get("traits", []))
            if not _satisfies(traits, requires.get("setting")) or (traits & set(forbids.get("setting") or [])):
                blocked.add("setting")
                continue
            wanted = set(requires.get("thresholdKind") or [])
            if wanted and not (wanted & set(setting.get("thresholdKinds", []))):
                blocked.add(f"thresholdKind {sorted(wanted)}")
                continue
            for companion in library["companions"]:
                if not (set(companion.get("habitat", [])) & set(setting.get("habitat", []))):
                    continue
                caps = set(companion.get("traits", []))
                if not _satisfies(caps, requires.get("companion")) or (caps & set(forbids.get("companion") or [])):
                    blocked.add("companion")
                    continue
                if not ((set(companion.get("castRoles", [])) or all_roles)
                        & (set(requires.get("casting") or []) or all_roles)):
                    blocked.add("casting")
                    continue
                for discovery in library["objects"]:
                    found = set(discovery.get("traits", []))
                    if not _satisfies(found, requires.get("discovery")) or (found & set(forbids.get("discovery") or [])):
                        blocked.add("discovery")
                        continue
                    legal += 1
        if legal == 0:
            report.fail(
                f"{blueprint['id']}: NO legal binding exists — the blueprint matches no content "
                f"and can never be selected (narrowed away on: {', '.join(sorted(blocked)) or 'habitat'})"
            )
        elif legal < 4:
            report.fail(
                f"{blueprint['id']}: only {legal} legal binding(s) — every book of this blueprint "
                f"draws from the same handful of settings, companions and discoveries"
            )


def check_bound_pools(corpus, report) -> None:
    """
    Count supply per CELL, not per beat.

    `check_effective_pools` above was written after `afterBeat` was found to
    divide a beat's supply. It fixed one instance of the defect and named it too
    narrowly: EVERY declared filter partitions a pool, and they compose. A beat
    with 16 variants that declares `castRoles` and carries both length classes
    is eight pools of one to four, not one pool of sixteen — and the story is
    bound to exactly one cell before a single variant is eligible.

    So this walks real bindings: blueprint x setting x companion x cast role x
    discovery, applying every filter the composer applies, and asks what is
    actually left for each page. An empty cell is a page that cannot render. A
    cell of one is a page every book of that binding shares.

    The length-class gate cannot see this: it checks that a class EXISTS for a
    beat, never that the class survives the filters alongside it.
    """
    library = _pilot_library()
    if not library:
        report.note("bound-pool check skipped: no content library found")
        return
    sequences = shipped_sequences()
    if SEQUENCES.exists():
        sequences += json.loads(SEQUENCES.read_text(encoding="utf-8"))["blueprints"]
    if not sequences:
        report.note("bound-pool check skipped: no blueprints found")
        return

    by_beat = {bf["beat"]: bf["variants"] for bf in corpus}
    all_roles = {"guide", "needsCare", "hesitant", "reassuring"}
    worst: dict[tuple, tuple] = {}

    unconstrained = [b["id"] for b in sequences if not b.get("requires") and not b.get("forbids")]

    for blueprint in sequences:
        if blueprint["id"] in unconstrained:
            continue
        beats = blueprint["beats"]
        requires = blueprint.get("requires") or {}
        forbids = blueprint.get("forbids") or {}
        for setting in library["settings"]:
            if not _satisfies(set(setting.get("traits", [])), requires.get("setting")):
                continue
            if set(setting.get("traits", [])) & set(forbids.get("setting") or []):
                continue
            wanted_kinds = set(requires.get("thresholdKind") or [])
            if wanted_kinds and not (wanted_kinds & set(setting.get("thresholdKinds", []))):
                continue
            for companion in library["companions"]:
                if not (set(companion.get("habitat", [])) & set(setting.get("habitat", []))):
                    continue
                if not _satisfies(set(companion.get("traits", [])), requires.get("companion")):
                    continue
                if set(companion.get("traits", [])) & set(forbids.get("companion") or []):
                    continue
                for discovery in library["objects"]:
                    if not _satisfies(set(discovery.get("traits", [])), requires.get("discovery")):
                        continue
                    if set(discovery.get("traits", [])) & set(forbids.get("discovery") or []):
                        continue
                    traits = set(setting.get("traits", []))
                    caps = set(companion.get("traits", []))
                    found = set(discovery.get("traits", []))
                    cast = set(requires.get("casting") or []) or all_roles
                    for role in ((set(companion.get("castRoles", [])) or all_roles) & cast):
                        for index, slot in enumerate(beats):
                            wanted = "paired" if len(slot) > 1 else "solo"
                            previous = beats[index - 1][0] if index else None
                            for beat in slot:
                                variants = by_beat.get(beat)
                                if not variants:
                                    continue
                                pool = [
                                    v for v in variants
                                    if (v.get("lengthClass") or "solo") == wanted
                                    and set(v.get("settingTraits", [])) <= traits
                                    and set(v.get("discoveryTraits", [])) <= found
                                    and (not v.get("castRoles") or role in v["castRoles"])
                                    and (not v.get("natureRequire")
                                         or companion.get("nature", "animal") in v["natureRequire"])
                                    and set(v.get("capabilityRequire", [])) <= caps
                                    and not (set(v.get("capabilityForbid", [])) & caps)
                                    and (not v.get("afterBeat")
                                         or (previous and previous in v["afterBeat"]))
                                ]
                                key = (index + 1, beat, wanted)
                                binding = (f"{blueprint['id']} | {setting['name']} | "
                                           f"{companion['name']} as {role} | {discovery['name']}")
                                if key not in worst or len(pool) < worst[key][0]:
                                    worst[key] = (len(pool), binding)

    empty = [(k, v) for k, v in worst.items() if v[0] == 0]
    thin = [(k, v) for k, v in worst.items() if 0 < v[0] < MIN_BOUND_POOL]
    for (page, beat, cls), (_, binding) in sorted(empty):
        report.fail(f"page {page} {beat} [{cls}]: NO variant survives binding — {binding}")
    for (page, beat, cls), (size, binding) in sorted(thin, key=lambda x: x[1][0]):
        report.fail(f"page {page} {beat} [{cls}]: bound pool is {size} — two books of this "
                    f"binding share the page {1 / size:.0%} of the time — {binding}")
    report.note(f"bound pools: {len(worst)} cells walked across "
                f"{len(sequences) - len(unconstrained)} constrained blueprint(s), "
                f"{len(empty)} empty, {len(thin)} under {MIN_BOUND_POOL}")
    if unconstrained:
        report.note(f"bound pools: {len(unconstrained)} blueprint(s) skipped — no requires/forbids "
                    f"declared, so every binding would look legal and the check would invent "
                    f"defects (e.g. {sorted(unconstrained)[0]})")


def _satisfies(held: set, requirement) -> bool:
    """A TraitRequirement is either a flat list (all of) or {allOf, anyOf}."""
    if not requirement:
        return True
    if isinstance(requirement, list):
        return set(requirement) <= held
    if set(requirement.get("allOf") or []) - held:
        return False
    groups = requirement.get("anyOf") or []
    return not groups or any(set(g) <= held for g in groups)


def _pilot_library() -> dict | None:
    for path in sorted(SHIPPED_BLUEPRINTS.glob("*.json")):
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        if {"settings", "companions", "objects"} <= document.keys():
            return document
    return None


def check_effective_pools(corpus, report) -> None:
    """
    A beat that flavours by context divides its own supply. `succeed` and
    `restore` declare `afterBeat`, so a blueprint sees only the slice matching
    its page-6 beat — twelve variants became a pool of two, and two books of the
    same blueprint shared their payoff page half the time.

    Allocate by effective pool per blueprint, never by beat exposure.
    """
    if not SEQUENCES.exists():
        report.note(f"pool check skipped: {SEQUENCES.name} not found")
        return

    sequences = json.loads(SEQUENCES.read_text(encoding="utf-8"))
    by_beat = {bf["beat"]: bf["variants"] for bf in corpus}
    smallest = None

    for blueprint in sequences["blueprints"]:
        beats = blueprint["beats"]
        for index, slot in enumerate(beats):
            primary = slot[0]
            variants = by_beat.get(primary)
            if not variants:
                continue
            previous = beats[index - 1][0] if index else None
            pool = [
                v for v in variants
                if not v.get("afterBeat") or (previous and previous in v["afterBeat"])
            ]
            if len(pool) < 4:
                report.fail(
                    f"{blueprint['id']} page {index + 1} ({primary}): effective pool is "
                    f"{len(pool)} — two books of this blueprint would share this page "
                    f"{8 / max(len(pool), 1) / 8:.0%} of the time"
                )
            if smallest is None or len(pool) < smallest[0]:
                smallest = (len(pool), f"{blueprint['id']} p{index + 1}")

    if smallest:
        report.note(f"smallest effective pool: {smallest[0]} ({smallest[1]})")


def check_interest_vocabulary(corpus, report) -> None:
    """
    Every interest word content is tagged with must be defined in the
    vocabulary (FAZ 12). An undefined word matches no child's choice, so the
    tag silently does nothing — the same failure as a slot nobody fills.
    """
    library = _pilot_library()
    if library is None:
        report.note("interest check skipped: no pilot library")
        return
    defined = [i.get("id", "").lower() for i in library.get("interests", [])]
    for word in sorted({w for w in defined if defined.count(w) > 1}):
        report.fail(f"interest '{word}' is defined more than once")
    known = set(defined)
    for axis in ("settings", "companions", "objects", "blueprints"):
        for record in library.get(axis, []):
            for word in record.get("interests", []):
                if word.lower() not in known:
                    report.fail(f"{record.get('id')}: interest '{word}' is not in the vocabulary")
    tagged = sum(1 for axis in ("settings", "companions", "objects", "blueprints")
                 for record in library.get(axis, []) if record.get("interests"))
    report.note(f"interest vocabulary: {len(known)} words, {tagged} tagged records")


# Safety topics that must never be a choice (FAZ 17): no story tells of them,
# and offering one would suggest some story does. The same list as
# `CatalogIntegrityChecker.forbiddenSafetyTopics` in the engine.
FORBIDDEN_SAFETY_TOPICS = ("death", "loss", "olum", "ölüm", "kayip", "kayıp")


def _all_line_files() -> list[tuple[str, dict]]:
    """Every beat file a story can read lines from: 5-6, 3-4, series and bedtime."""
    files = []
    for folder in (CORPUS, AGE3_CORPUS, SERIES_CORPUS, BEDTIME_CORPUS):
        for path in sorted(folder.glob("*.json")):
            files.append((f"{folder.name}/{path.name}", json.loads(path.read_text(encoding="utf-8"))))
    return files


def check_safety_topics(corpus, report) -> None:
    """
    Every safety topic content is tagged with must be defined (FAZ 17). An
    undefined topic is never avoided, so the parent's choice silently does
    nothing for that line. "Ölüm ve kayıp" is never a topic.
    """
    library = _pilot_library()
    if library is None:
        report.note("safety check skipped: no pilot library")
        return
    defined = [t.get("id", "").lower() for t in library.get("safetyTopics", [])]
    for topic in sorted({t for t in defined if defined.count(t) > 1}):
        report.fail(f"safety topic '{topic}' is defined more than once")
    for topic in defined:
        if topic in FORBIDDEN_SAFETY_TOPICS:
            report.fail(f"safety topic '{topic}' is not a choice: no story tells of it")
    known = set(defined)
    tagged = 0
    for axis in ("settings", "companions", "objects", "blueprints"):
        for record in library.get(axis, []):
            for topic in record.get("topics", []):
                tagged += 1
                if topic.lower() not in known:
                    report.fail(f"{record.get('id')}: topic '{topic}' is not in the safety vocabulary")
    for name, beat_file in _all_line_files():
        for variant in beat_file.get("variants", []):
            for topic in variant.get("topics", []):
                tagged += 1
                if topic.lower() not in known:
                    report.fail(f"{name} {variant.get('id')}: topic '{topic}' is not in the safety vocabulary")
    report.note(f"safety vocabulary: {len(known)} topics, {tagged} tags")


def check_glossary_words(corpus, report) -> None:
    """
    A line that teaches a word must name a glossary entry, and say the word
    (FAZ 17). Otherwise the reader has nothing to highlight and the tag is lost.
    The word is matched like the engine does: a form at the start of a word,
    Turkish case folded.
    """
    library = _pilot_library()
    if library is None:
        report.note("glossary check skipped: no pilot library")
        return
    entries = {}
    for entry in library.get("glossary", []):
        if entry.get("id") in entries:
            report.fail(f"glossary entry '{entry.get('id')}' is defined more than once")
        if not str(entry.get("meaning", "")).strip():
            report.fail(f"glossary entry '{entry.get('id')}' has no meaning")
        entries[entry.get("id")] = entry

    def fold(text: str) -> str:
        return text.replace("I", "ı").replace("İ", "i").lower()

    taught = 0
    for name, beat_file in _all_line_files():
        for variant in beat_file.get("variants", []):
            for word in variant.get("words", []):
                taught += 1
                entry = entries.get(word)
                if entry is None:
                    report.fail(f"{name} {variant.get('id')}: word '{word}' is not in the glossary")
                    continue
                forms = [fold(f) for f in (entry.get("forms") or [entry.get("term", "")]) if f]
                text = fold(variant.get("text", ""))
                if not any(re.search(r"(?<![a-zçğıöşüâîû])" + re.escape(f), text) for f in forms):
                    report.fail(f"{name} {variant.get('id')}: teaches '{entry.get('term')}' "
                                f"but does not say it")
    report.note(f"glossary: {len(entries)} words, {taught} taught on lines")


# --- main -------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-v", "--verbose", action="store_true", help="list every variant")
    args = parser.parse_args()

    corpus = load_corpus()
    bindings = binding_extremes()
    report = Report()

    total = sum(len(bf["variants"]) for bf in corpus)
    print(f"v3 beat corpus — {len(corpus)} beats, {total} variants")
    print(f"binding extremes: {bindings[0]['setting.name']!r} / {bindings[-1]['setting.name']!r}")
    print()
    for beat_file in corpus:
        print(f"  {beat_file['beat']:20} {len(beat_file['variants']):3} variants")
        if args.verbose:
            check_lengths([beat_file], bindings, Report(), True)
    print()

    # The gate list is derived, not hand-written. A summary line listing the
    # checks by hand went stale the moment gates were added — it named nine
    # while fourteen ran, which is a check reporting something other than what
    # it did. Same rule we applied to the axis list and the binding walk: never
    # keep a second copy of what the thing actually does.
    gates = [
        lambda: check_lengths(corpus, bindings, report, False),
        lambda: check_suffixes(corpus, report),
        lambda: check_declared_slots(corpus, report),
        lambda: check_collisions(corpus, bindings, report),
        lambda: check_moves(corpus, report),
        lambda: check_banned(corpus, report),
        lambda: check_place_welding(corpus, report),
        lambda: check_length_class_coverage(corpus, report),
        lambda: check_effective_pools(corpus, report),
        lambda: check_modality_claims(corpus, report),
        lambda: check_variants_reachable(corpus, report),
        lambda: check_blueprints_satisfiable(corpus, report),
        lambda: check_bound_pools(corpus, report),
        lambda: check_partitioned_pools(corpus, report),
        lambda: check_family_lines(corpus, report),
        lambda: check_conjunctions(corpus, report),
        lambda: check_deferrals_still_hold(corpus, report),
        lambda: check_interest_vocabulary(corpus, report),
        lambda: check_safety_topics(corpus, report),
        lambda: check_glossary_words(corpus, report),
        lambda: check_series_lines(report),
        lambda: check_bedtime_lines(report),
    ]
    for gate in gates:
        gate()
    ran = [g for g in globals() if g.startswith("check_")]

    for note in report.notes:
        print(f"note: {note}")
    if report.failures:
        print(f"\nFAILED — {len(report.failures)} issue(s):")
        for failure in report.failures:
            print(f"  - {failure}")
        return 1

    print(f"\nPASS — {len(gates)} gates: " + ", ".join(sorted(
        name[len("check_"):].replace("_", " ") for name in ran)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
