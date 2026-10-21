"""Deterministic language metrics for a page and for a whole book.

Everything here is computed, never judged. Where a metric is lexicon-based
(sound words, direct address) the result says so, because a short word list
undercounts and a reader of the report should know it is a floor.
"""

from __future__ import annotations

import re
from collections import Counter
from statistics import mean

from . import text_metrics as tm
from .stats import median

# Double quotes and guillemets only: a single quote is an apostrophe too often
# (`Ragi'nin`, `don't`) to mark speech reliably.
_QUOTED = re.compile(r"[\"“”«»]([^\"“”«»]+)[\"“”«»]")
# Turkish and much European print marks dialogue with a leading dash.
_DASH_LINE = re.compile(r"^\s*[—–-]\s*(.+)$", re.MULTILINE)

DIRECT_ADDRESS = {
    "en": {"you", "your", "yours", "yourself", "you're", "you'll", "you've"},
    "tr": {"sen", "sana", "seni", "senin", "sende", "senden", "siz", "size", "sizi", "sizin"},
}

SOUND_WORDS = {
    "en": {"splash", "bang", "boom", "crash", "pop", "whoosh", "buzz", "hiss", "moo", "woof",
           "meow", "quack", "knock", "thud", "tick", "tock", "ding", "zoom", "plop", "snap",
           "crunch", "squeak", "splish", "splosh", "squelch", "tap", "thump", "honk", "baa",
           "oink", "ribbit", "tweet", "cock-a-doodle-doo", "clip-clop", "pitter-patter",
           # stretched forms are normalised first (see _sound_key): "WHEEEE" → "whe", "Shhh" → "sh"
           "whe", "whee", "sh", "eek", "hmm", "ker-splash", "kersplash", "toop", "achoo", "kertyschoo",
           "zoom", "swoosh", "thwack", "plonk", "boing", "vroom", "beep", "tsk"},
    "tr": {"şap", "pat", "küt", "cup", "şıp", "vız", "hav", "miyav", "mö", "vak", "tık",
           "çat", "gürül", "şırıl", "hışır", "pıt", "zırr", "fış", "lap", "pof", "tıkır",
           "şıkır", "çıt", "pat pat", "hüüü", "cik", "möö", "meee", "lıkır", "fokur"},
}


_STRETCH = re.compile(r"(\w)\1{2,}")


def _sound_key(token: str) -> str:
    """Collapse letters repeated 3+ times, so 'WHEEEE', 'wheee' and 'whe' match one entry."""
    return _STRETCH.sub(r"\1", token)


def _dialogue_words(text: str) -> int:
    spans = _QUOTED.findall(text) + _DASH_LINE.findall(text)
    return sum(tm.word_count(s) for s in spans)


_QUESTION = re.compile(r"\?+")
_EXCLAMATION = re.compile(r"!+")


def page_metrics(text: str, language: str) -> dict:
    tokens = [tm.lower(w, language) for w in tm.words(text)]
    sentence_list = tm.sentences(text)
    word_total = len(tokens)
    sentence_lengths = [tm.word_count(s) for s in sentence_list]
    address = DIRECT_ADDRESS.get(language, set())
    sounds = SOUND_WORDS.get(language, set())
    return {
        "computed_by": "cli",
        "words": word_total,
        "sentences": len(sentence_list),
        "mean_sentence_words": round(mean(sentence_lengths), 2) if sentence_lengths else 0,
        "longest_sentence": max(sentence_lengths, default=0),
        "dialogue_ratio": round(min(_dialogue_words(text) / word_total, 1.0), 3) if word_total else 0.0,
        # Counted as question marks, not sentences: in `"Who is there?" asked Fox.`
        # the question is inside a sentence that ends with a full stop.
        "questions": len(_QUESTION.findall(text.replace("?!", "?"))),
        "exclamations": len(_EXCLAMATION.findall(text.replace("?!", "?"))),
        "direct_address": sum(1 for t in tokens if t in address),
        "sound_words": sum(1 for t in tokens if t in sounds or _sound_key(t) in sounds),
    }


def _end_rhyme_pairs(lines: list[str], language: str) -> int:
    """Consecutive lines whose last words share a final 2+ letter ending.

    Crude on purpose and labelled as such: it only separates verse from prose.
    """
    endings = []
    for line in lines:
        tokens = tm.words(line)
        endings.append(tm.lower(tokens[-1], language) if tokens else "")
    pairs = 0
    for a, b in zip(endings, endings[1:]):
        if len(a) >= 3 and len(b) >= 3 and a != b and a[-2:] == b[-2:]:
            pairs += 1
    return pairs


def repetition(pages: list[str], language: str, min_size: int = 3, max_size: int = 6) -> dict:
    """Phrases and sentences that recur across pages.

    A phrase counts once per page it appears on: a refrain is something the
    reader meets again on a later page, not a word repeated inside one sentence.
    Shorter n-grams contained in a longer repeated one are dropped.
    """
    page_sets: dict[int, Counter] = {}
    for size in range(min_size, max_size + 1):
        counter: Counter = Counter()
        for page in pages:
            counter.update(set(tm.n_grams(page, size, language)))
        page_sets[size] = counter

    repeated: dict[str, int] = {}
    for size in range(max_size, min_size - 1, -1):
        for gram, count in page_sets[size].items():
            if count < 2:
                continue
            if any(gram in longer and longer_count >= count for longer, longer_count in repeated.items()):
                continue
            repeated[gram] = count

    sentence_counter: Counter = Counter()
    opener_counter: Counter = Counter()
    for page in pages:
        page_sentences = {" ".join(tm.lower(w, language) for w in tm.words(s)) for s in tm.sentences(page)}
        sentence_counter.update(s for s in page_sentences if s)
        for sentence in tm.sentences(page):
            first = tm.first_word(sentence, language)
            if first:
                opener_counter[first] += 1

    # A refrain is a sentence of 3+ words met again on another page; "Zama!" twice is not one.
    refrains = {s: c for s, c in sentence_counter.items() if c >= 2 and len(s.split()) >= 3}
    lines = [line for page in pages for line in page.splitlines() if line.strip()]
    return {
        "repeated_phrases": dict(sorted(repeated.items(), key=lambda kv: (-kv[1], kv[0]))[:25]),
        "refrains": dict(sorted(refrains.items(), key=lambda kv: (-kv[1], kv[0]))),
        "top_sentence_openers": dict(opener_counter.most_common(5)),
        "end_rhyme_pairs": _end_rhyme_pairs(lines, language),
        "end_rhyme_note": "heuristic: consecutive lines sharing a final two letters",
    }


def book_metrics(pages: list[str], language: str) -> dict:
    per_page = [page_metrics(p, language) for p in pages]
    all_text = "\n".join(pages)
    tokens = [tm.lower(w, language) for w in tm.words(all_text)]
    sentence_lengths = [tm.word_count(s) for p in pages for s in tm.sentences(p)]
    word_counts = [m["words"] for m in per_page]
    total = sum(word_counts)
    return {
        "computed_by": "cli",
        "pages": len(pages),
        "total_words": total,
        "words_per_page": {
            "min": min(word_counts, default=0),
            "median": median(word_counts),
            "max": max(word_counts, default=0),
        },
        "mean_sentence_words": round(mean(sentence_lengths), 2) if sentence_lengths else 0,
        "longest_sentence": max(sentence_lengths, default=0),
        "type_token_ratio": round(len(set(tokens)) / len(tokens), 3) if tokens else 0.0,
        "dialogue_ratio": round(sum(m["dialogue_ratio"] * m["words"] for m in per_page) / total, 3) if total else 0.0,
        "questions": sum(m["questions"] for m in per_page),
        "questions_per_page": round(sum(m["questions"] for m in per_page) / len(pages), 2) if pages else 0,
        "direct_address": sum(m["direct_address"] for m in per_page),
        "sound_words": sum(m["sound_words"] for m in per_page),
        "lexicon_note": "direct_address and sound_words are lexicon counts: a floor, not a measure. "
                        "direct_address counts second-person words anywhere, dialogue included — "
                        "it is not narrator-to-reader address",
        "repetition": repetition(pages, language),
    }

