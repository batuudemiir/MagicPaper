"""Word and sentence counting — a port of StoryEngine's TextMetrics.swift.

Same rules on purpose: a finding like "median 28 words per page" is only
comparable to MagicPaper's 18-38 band if both sides count words the same way.
tests/test_text_metrics.py carries the Swift behaviour as cases.
"""

from __future__ import annotations

import unicodedata

TERMINATORS = {".", "!", "?", "…"}
CLOSERS = {'"', "”", "'", "’", ")", "]", "»"}


def _is_punctuation(character: str) -> bool:
    return unicodedata.category(character).startswith("P")


def _trim_punctuation(token: str) -> str:
    start, end = 0, len(token)
    while start < end and _is_punctuation(token[start]):
        start += 1
    while end > start and _is_punctuation(token[end - 1]):
        end -= 1
    return token[start:end]


def words(text: str) -> list[str]:
    """Whitespace tokens with leading/trailing punctuation removed.

    Inner punctuation stays, so Turkish `Ragi'nin` is one word, as in the engine.
    """
    return [w for w in (_trim_punctuation(t) for t in text.split()) if w]


def word_count(text: str) -> int:
    return len(words(text))


def sentences(text: str) -> list[str]:
    """Split into sentences; a lowercase word after the terminator continues it.

    `"Stop!" said Peter.` is one sentence, exactly as in TextMetrics.swift.
    """
    result: list[str] = []
    current: list[str] = []
    index, count = 0, len(text)
    while index < count:
        character = text[index]
        current.append(character)
        index += 1
        if character not in TERMINATORS:
            continue
        while index < count and (text[index] in TERMINATORS or text[index] in CLOSERS):
            current.append(text[index])
            index += 1
        lookahead = index
        while lookahead < count and text[lookahead].isspace():
            lookahead += 1
        if lookahead < count and text[lookahead].islower():
            continue
        trimmed = "".join(current).strip()
        if trimmed:
            result.append(trimmed)
        current = []
    trailing = "".join(current).strip()
    if trailing:
        result.append(trailing)
    return result


def longest_sentence_word_count(text: str) -> int:
    return max((word_count(s) for s in sentences(text)), default=0)


def lower(token: str, language: str = "en") -> str:
    """Lowercase with Turkish dotted/dotless i handled when the text is Turkish."""
    if language == "tr":
        token = token.replace("I", "ı").replace("İ", "i")
    return token.lower()


def n_grams(text: str, size: int, language: str = "en") -> list[str]:
    if size <= 0:
        return []
    tokens = [lower(w, language) for w in words(text)]
    if len(tokens) < size:
        return []
    return [" ".join(tokens[i:i + size]) for i in range(len(tokens) - size + 1)]


def first_word(sentence: str, language: str = "en") -> str | None:
    tokens = words(sentence)
    return lower(tokens[0], language) if tokens else None
