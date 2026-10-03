# Story Mode, yaş bandı ve çocuk başına okuma defteri

Ürün kararları: 2026-09-23. Bu belge o kararların koddaki karşılığını anlatır.

## Kararlar

| Konu | Karar |
|---|---|
| Modlar | Gelişelim (`growth`), Maceraya Çıkalım (`adventure`), Uyku Zamanı (`bedtime`) |
| Bana Sürpriz Yap | Mod **değil**. `StorySelectionStrategy.surprise`: MagicPaper üç moddan birini seçer |
| Fikir kartları | Moddan sonra **isteğe bağlı** ikinci adım; "Bana bırak" geçer |
| Yaş | Tek çözümleyici: `AgeBandResolver` → 3-4, 5-6, 7-8, 9-10. MVP bandı 5-6 |
| Günlük sekmesi | Rozet ve kupa hedefleri yok. Süreklilik, bugün, son hikâyeler, bu ay |
| Okuma defteri | Çocuk başına. Aile sahipliktir, çocuk deneyim |

## Akış

```
ParentIntent (StoryModeStep)
 ├─ doğrudan mod ──────────────┐
 └─ Bana sürpriz yap           │
      StoryModeResolver         │  son 3 hikâyenin modu, en yeni en ağır
      (recentModes, seed) ──────┤
                                ▼
                       StoryMode (3'ten biri)
                                │
             StoryIdeaStep (isteğe bağlı; mod için fikir yoksa atlanır)
                                │
                          CompanionStep
                                │
 OfflineStoryIntent(mode, ageBand = AgeBandResolver + servedBand)
                                │
 BlueprintSelector: blueprint.ageRange == ageBand
                    ve blueprint.family ∈ StoryModeProfile.families
                                │
 OfflineStoryComposer → OfflineStoryMapper
                                │
 Story.origin: modeID, selectionStrategy, ageBand
```

## Nerede ne var

| Parça | Dosya |
|---|---|
| `StoryMode`, `StorySelectionStrategy`, `StoryModeProfile`, `StoryModeResolver` | `StoryEngine/Sources/StoryEngine/Offline/StoryMode.swift` |
| `AgeBandResolver` | `StoryEngine/Sources/StoryEngine/Content/AgeBandResolver.swift` |
| Mod → aile eşlemesi (**içerik**) | `pilot_library_v1.json` → `storyModes` |
| Mod bütünlük denetimi | `CatalogIntegrity.checkStoryModes` |
| `availableModes`, `storyIdeas(mode:)` | `BlueprintSelector` |
| Uygulama kapısı | `OfflineStoryService`: `servedBand`, `availableModes`, `storyIdeas(forAge:mode:)`, `resolveMode`, `compose(mode:age:)` |
| Ekranlar | `StoryModeStep`, `StoryIdeaStep`, `CompanionStep`, `StoryCreationFlow` |
| Geçmiş | `StoryGenerationManager.recentModes(for:)` |
| Okuma defteri | `MPStreak.activate(profileID:)`, `ContentView` aktif profile bağlar |

## Yeni bir mod eklemek

1. `StoryMode`'a vaka ekle (ürün kararı: kapalı küme).
2. Katalogda `storyModes` altına profilini yaz. Bütünlük denetimi, blueprint'e ulaşmayan modu hata sayar.
3. `StoryMode+Presentation` (`StoryModeStep.swift`) içinde başlık, söz, ikon, renk.

Selector, resolver, mapper ve kayıt değişmez.

## Bilinen boşluklar

- **Uyku Zamanı'nın gerçek bir arkı yok.** Geçici olarak `charge` ailesine bağlı (5-6 için 2, 3-4 için 1 blueprint). Profilin `editorialNote`'u bunu söylüyor. Uyku arkı yazıldığında eşleme değişmeli.
- **3-4 bandında yalnızca Uyku Zamanı kurulabilir**, çünkü o bantta tek blueprint `charge` ailesinden. Kurulamayan mod ekranda gösterilmez.
- **7-8 ve 9-10 bantlarının içeriği yok.** `AgeBandResolver.servedBand` en yakın, eşitlikte küçük banttan sunar. Bu bir geçici çözüm.
- Mod henüz sayfa sayısını, kelime bütçesini ya da dekorasyon yoğunluğunu etkilemiyor. Hepsi `StoryModeProfile`'a veri olarak eklenebilir.
- Arkadaş adımı olduğu gibi duruyor. Kaldırmak ayrı bir ürün kararı.

## Okuma defteri geçişi

Eski, cihaz geneli `mp_readDays` / `mp_readSeconds`, ilk etkinleşen çocuğa (geçiş anında seçili olan) **kopyalanır**. Eski anahtarlar silinmez. İkinci bir çocuk eski geçmişi almaz. `mp_streakLegacyAssignedTo` bunun bir kez olduğunu kaydeder. Profil silinince o çocuğun defteri de silinir.
