# İş paketi: p_companion_mirrors_feeling

**Durum:** done · **Sahibi:** content-library · **Tür:** adopt_guidance · **Hedef:** `writing_guidance`

## Ne yapılacak

Hypothesis: a companion can amplify feeling silently, through the picture; relevant to companion illustration briefs.

- Bugün: catalog companions speak and act in text
- Neden: Text form only, as writing guidance: a short silent 'mirror' line for the companion on hesitate/succeed pages, so the child, not the companion, resolves the tension. The illustration half is parked until illustrated stories are live and the image safety gate binds companion emotion to the page ceiling.
- Ürün sahibinin notu: Yalnızca metin hali, yazım rehberine
- Kanıt: iddia `c_companion_mirrors_feeling`, tartışma [exchange/p_companion_mirrors_feeling.md](../exchange/p_companion_mirrors_feeling.md)

## Güvenlik koşulları

**concerns**: Conditions: (1) only once illustrated stories are live behind their own flag; (2) companion's drawn emotion bound to the page EmotionalState, never above the ceiling (2) and never above the parent's ContentSafety level; (3) passes the blocking image/illustration validation; (4) no child photo or likeness data used to create mirrored expressions.

## Bitti sayılması için

- The guidance is written into the content line's writing rules; corpus validators still pass.
- Works on its own branch or worktree, never on main; nothing is merged without the product owner.
- Existing tests stay green and new behaviour has tests.
- A Değişiklik günlüğü entry is added (CLAUDE.md).
- `ba exchange handoff p_companion_mirrors_feeling --status done --note <branch@commit>` is recorded.

## Geçmiş

- 2026-10-14 · waiting · human: approved
- 2026-10-14 · done · content-library: kitap-rehberi@e6e6bc5 (docs/MagicPaper_Content_Library.md §14; main'e birleştirilmedi)
