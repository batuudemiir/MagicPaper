# Story Mode, yaş bandı ve çocuk başına okuma defteri

Ürün kararları: 2026-09-23, güncelleme 2026-10-03, FAZ 10 2026-10-04 (`MagicPaper_Faz_Plani_Ekim.md`). Bu belge o kararların
koddaki karşılığını anlatır. Çelişkide Ekim faz planı geçerlidir.

## Kararlar

| Konu | Karar |
|---|---|
| Modlar | Uyku öncesi (`bedtime`), Yeni şeyler öğrenelim (`learning`), Maceraya çıkalım (`adventure`). Ekran sırası bu; kod sırası (`StoryMode.allCases`: learning, adventure, bedtime) sürprizin eşitlik bozması için sabit |
| Eski ad | 3 Ekim 2026'ya kadar `learning` `growth` adıyla kaydedildi. Kayıtlar yeniden yazılmaz; `StoryMode(storedID:)` ve `StoryOrigin.mode` `"growth"`'u `learning` olarak çözer. Kayıttan mod okurken `StoryMode(rawValue:)` kullanılmaz |
| Bana Sürpriz Yap | Mod **değil**. `StorySelectionStrategy.surprise`: MagicPaper kurulabilir modlardan birini seçer. Kart yalnızca bantta en az iki mod kurulabiliyorsa görünür. Sürpriz masal tek seferliktir; `origin.selectionStrategy` bunu kaydeder ve seri (Faz 13) yalnızca `direct` masaldan açılır |
| Oluşturma | Mod → "Masalda kimler olsun?" (katalog yol arkadaşları + isteğe bağlı bir Masal ailem karakteri, Faz 11). Akışta serbest metin yok; "Yeni karakter" yalnızca ebeveyn modunda. Ana sayfadaki mod kartları akışı doğrudan ikinci adımdan açar; dünya seçimi yok |
| Uzunluk | Yaş bandından: `AgeBand.pageCount` (3-4 → 6, 5-6 → 8, 7-8 → 8, 9-10 → 10), kelime bütçesinin yanında, kodda. Bandını tutmayan blueprint bütünlük hatasıdır (`page_count_off_band`). Akışta uzunluk seçimi yok |
| Ton | Ayrı bir alan yok. Ton modun anlatı ailelerinden gelir: Uyku öncesi yalnızca sakin, bakım üzerine kurulu aileleri (`charge`) kabul ettiği için sakindir. Tonu değiştirmek `storyModes` aile listesini değiştirmektir. Akışta ton seçimi yok |
| Fikir kartları / alt seçenek | `StoryIdeaStep` `StoryIdeaStepAccess` bayrağının arkasında, her build'de kapalı; yalnızca Ayarlar > Geliştirici (DEBUG) açar. Alt seçeneğin yeri: `OfflineStoryIntent.subOption` ve `StoryOrigin.subOptionID`, bugün hep `nil`, motor okumaz |
| Yaş | Tek çözümleyici: `AgeBandResolver` → 3-4, 5-6, 7-8, 9-10. 11-12 yaşındaki eski profiller 9-10'a oturur; profilde yaş seçimi 3-10 |
| Rozet | Sakin kilometre taşı rozetlerine izin var (karar: 3 Ekim 2026, `CLAUDE.md` §7): yalnızca okumayla kazanılır, kaybolmaz, geri sayım ve karşılaştırma yok, push ile duyurulmaz. Uygulama Faz 17. Puan, kupa, hedef yok |
| Günlük sekmesi | Süreklilik, bugün, son hikâyeler, bu ay |
| Metin masal | Yalnızca cihazdaki offline motor (`OfflineStoryService`). Bulut metin yolu Faz 9'da kaldırıldı |
| Okuma defteri | Çocuk başına. Aile sahipliktir, çocuk deneyim |

## Akış

```
ParentIntent (StoryModeStep ya da ana sayfa mod kartı)
 ├─ doğrudan mod ──────────────┐
 └─ Bana sürpriz yap           │
      StoryModeResolver         │  son 3 hikâyenin modu, en yeni en ağır
      (recentModes, seed) ──────┤
                                ▼
                       StoryMode (3'ten biri)
                                │
             StoryIdeaStep (bayrak arkasında, varsayılan kapalı)
                                │
                          CompanionStep ("Masalda kimler olsun?")
                                │  + isteğe bağlı Masal ailem karakteri (sürpriz kadroyu seçmez)
 OfflineStoryIntent(mode, ageBand = AgeBandResolver + servedBand, subOption = nil, family,
                    interests = profilin sunulan ilgi alanları, recent = son 4 masalın içeriği)
                                │
 BlueprintSelector: blueprint.ageRange == ageBand
                    ve blueprint.family ∈ StoryModeProfile.families
                    sıra: fikir yakınlığı grubu → grup içinde SelectionScoring (ilgi ×3, cooldown)
 OfflineContentBinder: ortam / yol arkadaşı / keşif de SelectionScoring ile sıralanır
                                │
 OfflineStoryComposer → OfflineStoryMapper
                                │
 Story.origin: modeID, selectionStrategy, ageBand, subOptionID, familyCharacterID, familyRelation
```

## Nerede ne var

| Parça | Dosya |
|---|---|
| `StoryMode`, `StorySelectionStrategy`, `StoryModeProfile`, `StoryModeResolver` | `StoryEngine/Sources/StoryEngine/Offline/StoryMode.swift` |
| `AgeBandResolver` | `StoryEngine/Sources/StoryEngine/Content/AgeBandResolver.swift` |
| Mod → aile eşlemesi (**içerik**) | `pilot_library_v1.json` → `storyModes` |
| Mod bütünlük denetimi | `CatalogIntegrity.checkStoryModes` (bant bazlı: `mode_unavailable_in_band`, `band_without_content` uyarıları) |
| `availableModes`, `modeCoverage`, `storyIdeas(mode:)` | `BlueprintSelector` |
| Uygulama kapısı | `OfflineStoryService`: `servedBand`, `availableModes`, `storyIdeas(forAge:mode:)`, `resolveMode`, `compose(mode:age:)` |
| Ekranlar | `StoryModeStep`, `StoryIdeaStep`, `CompanionStep`, `StoryCreationFlow`; kararları `StoryCreationSteps`; ana sayfa `HomeView.modeCards` |
| Geçmiş | `StoryGenerationManager.recentModes(for:)` |
| Okuma defteri | `MPStreak.activate(profileID:)`, `ContentView` aktif profile bağlar |

## Yeni bir mod eklemek

1. `StoryMode`'a vaka ekle (ürün kararı: kapalı küme).
2. Katalogda `storyModes` altına profilini yaz. Bütünlük denetimi, hiçbir bantta blueprint'e ulaşmayan modu hata, bir bantta ulaşmayanı uyarı sayar.
3. `StoryMode+Presentation` (`StoryModeStep.swift`) içinde başlık, söz, ikon, renk ve `displayOrder`.
4. Bir vakayı yeniden adlandırırsan eski adı `StoryMode.legacyAliases`'a ekle.

Selector, resolver, mapper ve kayıt değişmez.

## Mod × bant (4 Ekim 2026, `ModeBandCoverageTests`)

| Bant | Sunulan | Sayfa | Uyku öncesi | Yeni şeyler öğrenelim | Maceraya çıkalım | Sürpriz kartı |
|---|---|---|---|---|---|---|
| 3-4 | 3-4 | 6 | ✓ 1 | ✗ | ✗ | gizli |
| 5-6 | 5-6 | 8 | ✓ 2 | ✓ 8 | ✓ 4 | görünür |
| 7-8 | 5-6 | 8 | ✓ | ✓ | ✓ | görünür |
| 9-10 | 5-6 | 8 | ✓ | ✓ | ✓ | görünür |

İçerik eksikleri: 3-4 için bir `appeal` (öğrenelim) ve bir `threshold`/`absence` (macera) blueprint'i; uyku arkı; 7-8 ve 9-10 içeriği.

## Bilinen boşluklar

- **Uyku öncesinin gerçek bir arkı yok.** Geçici olarak `charge` ailesine bağlı (5-6 için 2, 3-4 için 1 blueprint). Profilin `editorialNote`'u bunu söylüyor. Uyku arkı yazıldığında eşleme değişmeli.
- **3-4 bandında yalnızca Uyku öncesi kurulabilir**, çünkü o bantta tek blueprint `charge` ailesinden. Kurulamayan mod ekranda gösterilmez.
- **7-8 ve 9-10 bantlarının içeriği yok.** `AgeBandResolver.servedBand` en yakın, eşitlikte küçük banttan sunar. Bu bir geçici çözüm.
- Masal ailem karakteri yalnızca açılışta ve kapanışta (`familyMoments`); masalın ortasında yok (içerik hattı, FAZ 13'ten önce).

## Okuma defteri geçişi

Eski, cihaz geneli `mp_readDays` / `mp_readSeconds`, ilk etkinleşen çocuğa (geçiş anında seçili olan) **kopyalanır**. Eski anahtarlar silinmez. İkinci bir çocuk eski geçmişi almaz. `mp_streakLegacyAssignedTo` bunun bir kez olduğunu kaydeder. Profil silinince o çocuğun defteri de silinir.

## Masal ailem (FAZ 11)

| Parça | Dosya |
|---|---|
| Model, depo, ad kuralları, sayaç | `StoryEngineBridge/FamilyCharacter.swift`, `FamilyCharacterStore.swift`, `FamilyNameValidator.swift`, `FamilyCharacterAppearances.swift` |
| Motor tipi | `StoryEngine/Sources/StoryEngine/Offline/FamilyCast.swift` (`FamilyRelationKind`, `FamilyCast`, `CatalogFamilyAnimalKind`) |
| Seçim | `BlueprintSelector.admissible` (gerekçeli ön eleme), `availableFamilyRelations`, `familyCoverage` |
| Satır seçimi | `OfflineStoryComposer.pool`: aile anında yalnızca o ilişki türünün satırı (düşmeyen filtre); başka yerde aile satırı yok |
| İçerik | Katalogda `familyMoments` (bugün `notice_anomaly`, `warm_close`) ve `familyAnimalKinds` (7 tür); varyantta `familyRelations` |
| Ekranlar | `Screens/FamilyCharacters/` (metinler tek dosyada: `FamilyCharacterCopy`), `CompanionStep`, profil sayfası satırı |

Kurallar:
- Ailesiz masal değişmez. Aile satırları havuza girmez; tohum ve fingerprint'e aile bilgisi yalnızca karakter varsa eklenir.
- İlişki türünün satırı olmayan blueprint o karakterle seçilmez ve gerekçe yazılır. O mod ve bantta hiçbir blueprint taşıyamıyorsa çip soluk görünür.
- Masal ailem karakteriyle aynı adı taşıyan yol arkadaşı bağlanmaz.
- Ad yalnızca masal metnine girer. Kökende kimlik ve ilişki türü tutulur, ad tutulmaz.

## İlgi alanları ve cooldown (FAZ 12)

| Parça | Dosya |
|---|---|
| Sözlük ve etiket tipleri | `StoryEngine/.../Content/InterestVocabulary.swift` (`InterestTag`, `CatalogInterest`) |
| Ulaşım ve sunulan kelimeler | `StoryEngine/.../Offline/InterestCoverage.swift` (`interestCoverage`, `availableInterests`) |
| Puanlama | `StoryEngine/.../Offline/SelectionScoring.swift` |
| Profil alanı ve kurallar | `UserProfile.interests` (`Services/ProfileManager.swift`), `StoryEngineBridge/ChildInterests.swift` |
| Köprü | `StoryChoiceSource.interestChoices`, `OfflineStoryService.compose(interests:recent:)`, `StoryGenerationManager.recentOrigins` |
| Ekranlar | `Screens/Interests/` (metinler tek dosyada: `InterestCopy`), `ProfileCreationView`, `ParentChildrenView` |

Kurallar:
- **Ağırlık, filtre değil.** İlgi eşleşmesi ağırlığı ×3 yapar; son 4 masalda kullanılan içerik doğrusal soğur
  (en yeni ×0,1, dördüncü ×0,775). Hiçbir şey havuzdan çıkmaz; sunulamayan ilgi alanı masalı değiştirmez.
- **Cooldown herkese** (karar 4 Ekim): ilgi alanı seçmemiş çocukta da aynı ortam üst üste en fazla 2 kez gelir.
- **Eski masal aynı kalır:** ağırlıklar eşitse (ilgi alanı ve geçmiş yok, ya da herkes eşleşiyor) sıra eski
  tohumlu döndürmedir; saklanmış tohum aynı kitabı kurar.
- **Seçilen eksen ağırlıktan etkilenmez** (çocuğun seçtiği yol arkadaşı, aile karakteri).
- Geçmiş kayıtlı masalların `StoryOrigin`'inden okunur; `read_history_<UUID>` artık okunmuyor.
- Sunulan kelime 4'ten azsa (`ChildInterests.minimumOfferedToShow`) "Neleri sever?" ve ebeveyn bölümü gizli;
  kayıtlı seçimler durur ve puanlamaya girer. Bugün 2 kelime var, ekranlar gizli.
- Çocuk başına en fazla 3 seçim, hiç seçmemek geçerli. Katalogdan kalkan kelime profilde saklı kalır,
  gösterilmez ve motora gitmez; düzenleme onu silmez.
- Kabul testi: `InterestScoringTests.testAnInterestRaisesItsShareWithoutCollapsingOntoIt` (3 sabit tohum seti × 20 ardışık masal).