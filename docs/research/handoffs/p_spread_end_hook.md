# İş paketi: p_spread_end_hook

**Durum:** done · **Sahibi:** content-library (birlikte: story-engine) · **Tür:** adopt_guidance · **Hedef:** `writing_guidance`

## Ne yapılacak

Hypothesis for page-based stories: end some pages on a question or an open 'says...' and answer it after the turn.

- Bugün: page-end lines are not specified
- Neden: As writing guidance only, via the generic-hook route (no engine change): adventure and learning, mid-story, never bedtime / last page / episode end, never danger questions. Specific question-answer pairs wait until the corpus supports cross-beat linking.
- Ürün sahibinin notu: Yazım rehberine girsin
- Kanıt: iddia `c_spread_end_hook`, tartışma [exchange/p_spread_end_hook.md](../exchange/p_spread_end_hook.md)

## Dokunacağı yerler

- Alanlar: beat variant pairing (new), CalmEnding
- Dosyalar: StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift, StoryEngine/Tools/validate_beat_corpus.py
- Testler: a page-end question variant is only selectable when the next page's chosen variant answers it
- Maliyet: M

## Güvenlik koşulları

**concerns**: Conditions: within-story only, never on the last page or episode ends; excluded from bedtime mode (or confined to its first half); hook questions not about danger or the unknown; page emotion stays within ceiling 2 and the parent's ContentSafety level.

## Bitti sayılması için

- The guidance is written into the content line's writing rules; corpus validators still pass.
- Works on its own branch or worktree, never on main; nothing is merged without the product owner.
- Existing tests stay green and new behaviour has tests.
- A Değişiklik günlüğü entry is added (CLAUDE.md).
- `ba exchange handoff p_spread_end_hook --status done --note <branch@commit>` is recorded.

## Geçmiş

- 2026-10-14 · waiting · human: approved
- 2026-10-14 · done · content-library: kitap-rehberi@e6e6bc5 (docs/MagicPaper_Content_Library.md §14; main'e birleştirilmedi)
