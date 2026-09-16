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
            beats = []
            for page in blueprint.get("pages", []):
                slot = [b for b in (page.get("beat"), page.get("supportingBeat")) if b]
                if slot:
                    beats.append(slot)
            if beats:
                out.append({"id": blueprint.get("id", path.stem), "beats": beats})
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

    check_lengths(corpus, bindings, report, False)
    check_suffixes(corpus, report)
    check_declared_slots(corpus, report)
    check_collisions(corpus, bindings, report)
    check_moves(corpus, report)
    check_banned(corpus, report)
    check_place_welding(corpus, report)
    check_length_class_coverage(corpus, report)
    check_effective_pools(corpus, report)

    for note in report.notes:
        print(f"note: {note}")
    if report.failures:
        print(f"\nFAILED — {len(report.failures)} issue(s):")
        for failure in report.failures:
            print(f"  - {failure}")
        return 1

    print("\nPASS — word bands, suffixes, declared slots, collisions, moves, "
          "banned constructions, place welding, length-class coverage, effective pools")
    return 0


if __name__ == "__main__":
    sys.exit(main())
