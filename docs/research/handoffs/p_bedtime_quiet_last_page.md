# İş paketi: p_bedtime_quiet_last_page

**Durum:** waiting · **Sahibi:** reader · **Tür:** adopt_guidance · **Hedef:** `reader.page_turn`

## Ne yapılacak

In bedtime mode only: let the last story page stand alone as a quiet moment (no auto-advance, narration ends softly), and make the ending leaf calm: no celebration animation and no reading counts on that screen; keep today's ending for adventure and learning.

- Bugün: After the last page StoryReaderView stops narration and goes straight to StoryEndingLeaf: Ragi waving, 'Masal bitti!', reading counts and a 400 ms celebration, the same in every mode.
- Neden: Two required voices heard and both support (reader owns the target, privacy-safety pass with conditions). 5 of 5 bedtime books end quieter than their average; none of 21 books has a celebration after the story. A UX target cannot be an experiment, and the change is small, reversible and display-only (StoryEndingLeaf, gate story.mode == bedtime or clock). Evidence LOW, so adopt as guidance for the bedtime ending, not as a rule for other modes.
- Ürün sahibinin notu: Uyku bitişi sakin; rozet tek satır
- Kanıt: iddia `c_bedtime_quiet_last_page`, tartışma [exchange/p_bedtime_quiet_last_page.md](../exchange/p_bedtime_quiet_last_page.md)

## Dokunacağı yerler

- Alanlar: StoryEndingLeaf bedtime variant: gate = story.mode == .bedtime || MPBedtime clock; no spring/scale on Ragi (fade only); streak + new-word tiles hidden; fresh badge as one quiet line; İyi geceler primary
- Dosyalar: MagicPaper/Screens/StoryReader/StoryEndingLeaf.swift
- Testler: new StoryEndingLeafBedtimeTests (gate logic as a pure helper: mode bedtime, mode nil + clock, adventure at night); existing StoryReaderModelTests unchanged
- Maliyet: S

## Güvenlik koşulları

**pass**: Display-only: earning/recording of reading, streak, star and badges unchanged in bedtime; new badges remain in Benim köşem, no compensating push or banner; no new analytics event, data field or log; no haptic/celebration on the bedtime leaf; one explicit bedtime trigger (story mode vs MPBedtime time window) chosen by the owner.

## Bitti sayılması için

- Design brief or screen change follows the design law in CLAUDE.md (tokens, accessibility, light + dark, largest Dynamic Type).
- Works on its own branch or worktree, never on main; nothing is merged without the product owner.
- Existing tests stay green and new behaviour has tests.
- A Değişiklik günlüğü entry is added (CLAUDE.md).
- `ba exchange handoff p_bedtime_quiet_last_page --status done --note <branch@commit>` is recorded.

## Geçmiş

- 2026-10-20 · waiting · human: approved
