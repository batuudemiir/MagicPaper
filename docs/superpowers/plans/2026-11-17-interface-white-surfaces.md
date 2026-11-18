# White interface surfaces implementation plan

Goal: Remove cream from application chrome while preserving optional reader papers and story artwork.
Architecture: Change the shared semantic color assets consumed by MPColor and MP.C; keep handoff tokens and generated color comments synchronized. Reader colors remain independent.
Tech stack: SwiftUI, Xcode asset catalogs, JSON design tokens.

- [ ] Set backgroundKid to #FFFFFF and backgroundSunken to #F6F3FC.
- [ ] Replace beige interface borders and disabled controls with purple-tinted neutrals: borderKid #E3DDED, borderKidInput #E8E2F1, borderKidDivider #EEE9F5, borderDashed #BEB4CE, actionDisabled #DCD7E5.
- [ ] Synchronize application and handoff asset catalogs, tokens.json, MPColor comments, and obsolete cream surface comments.
- [ ] Update brand documentation and change log. Preserve reader palettes, artwork, parent backgrounds, brand purple, and existing unrelated edits.
- [ ] Validate JSON, matching asset values, reader invariance, contrast and git diff; run one final build. Record simulator limitations honestly.
