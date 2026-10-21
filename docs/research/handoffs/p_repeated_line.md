# İş paketi: p_repeated_line

**Durum:** done · **Sahibi:** story-engine (birlikte: content-library) · **Tür:** experiment · **Hedef:** `writing_guidance`

## Ne yapılacak

Distinguish deliberate refrains (a line the listener can join, changed once at the end) from accidental repetition before treating all repetition as a defect.

- Bugün: repetition is measured as a defect to avoid (PROSE_PRODUCTION_GUIDE.md)
- Neden: Strongest proposal: 3 of 5 books, all three agents in favour, safety pass, M cost, fully reversible. Build a declared-refrain field (validators subtract it; accidental repeats stay defects) and 1-2 refrain sibling blueprints for bedtime 3-4/5-6. They can be built and validated offline now; they reach children only after your approval AND privacy-safety's loop conditions (consented, aggregated usage via FAZ 16).
- Ürün sahibinin notu: Deney onaylandı
- Kanıt: iddia `c_repeated_line`, tartışma [exchange/p_repeated_line.md](../exchange/p_repeated_line.md)

## Dokunacağı yerler

- Alanlar: StoryTemplate.maximumRepeatedNGrams, RepetitionValidator, validate_beat_corpus.check_collisions, validate_beat_corpus.check_moves, CatalogBlueprint.refrain(new)
- Dosyalar: StoryEngine/Sources/StoryEngine/Services/Validators/DeterministicValidators.swift, StoryEngine/Sources/StoryEngine/Domain/StoryTemplate.swift, StoryEngine/Sources/StoryEngine/Content/CatalogBlueprint.swift, StoryEngine/Sources/StoryEngine/Content/CatalogIntegrity.swift, StoryEngine/Tools/validate_beat_corpus.py, StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift
- Testler: RepetitionValidator: declared refrain allowed, undeclared repeat still flagged; composer places refrain on declared pages only; final-use variant differs; corpus validator whitelists refrain n-grams only
- Maliyet: M

## Güvenlik koşulları

**pass**: Pass as flagged experiment or guidance. Refrains must pass existing validators, must not be blame, shaming or prohibition lines aimed at the child, and must not name a Masal ailem relative in a negative role.

## Bitti sayılması için

- Variant arms are built and validated offline; they reach children only after `ba experiment preflight` is ready and the product owner marks the experiment live.
- Works on its own branch or worktree, never on main; nothing is merged without the product owner.
- Existing tests stay green and new behaviour has tests.
- A Değişiklik günlüğü entry is added (CLAUDE.md).
- `ba exchange handoff p_repeated_line --status done --note <branch@commit>` is recorded.

## Geçmiş

- 2026-10-14 · waiting · human: approved
- 2026-10-14 · done · story-engine: refrain-deneyi@104b3c3: RefrainSpec + 2 kardeş blueprint (Content/Experiments, uygulamayla gelmez), deneyler x_refrain_bedtime_56/_34 kayıtlı. Yayın adımları Batuhan'da: paket aracı, şema sürümü, preflight, live.
