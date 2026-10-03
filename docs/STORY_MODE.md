# Story Mode, yaş bandı ve çocuk başına okuma defteri

Ürün kararları: 2026-09-23, güncelleme 2026-10-03 (`MagicPaper_Faz_Plani_Ekim.md`). Bu belge o kararların
koddaki karşılığını anlatır. Çelişkide Ekim faz planı geçerlidir.

## Kararlar

| Konu | Karar |
|---|---|
| Modlar | Uyku öncesi (`bedtime`), Yeni şeyler öğrenelim (`learning`), Maceraya çıkalım (`adventure`). Kodda `learning` bugün hâlâ `growth`; yeniden adlandırma ve eski masalların geriye dönük çözmesi Faz 10 |
| Bana Sürpriz Yap | Mod **değil**. `StorySelectionStrategy.surprise`: MagicPaper üç moddan birini seçer |
| Oluşturma | Mod → "Masalda kimler olsun?" (katalog yol arkadaşları + Masal ailem, Faz 11). Serbest metin yok. Uzunluk yaş bandından, ton moddan |
| Fikir kartları / alt seçenek | Şimdi yok. `StoryIdeaStep` Faz 10'da varsayılan kapalı bir bayrağın arkasına alınır; alt seçeneğin yeri olarak kalır |
| Yaş | Tek çözümleyici: `AgeBandResolver` → 3-4, 5-6, 7-8, 9-10. 11-12 yaşındaki profile en yakın bant (9-10) sunulur; profilde yaş seçimi 3-10 ile sınırlanır (Faz 10) |
| Rozet | Sakin kilometre taşı rozetlerine izin var (karar: 3 Ekim 2026, `CLAUDE.md` §7): yalnızca okumayla kazanılır, kaybolmaz, geri sayım ve karşılaştırma yok, push ile duyurulmaz. Uygulama Faz 17. Puan, kupa, hedef yok |
| Günlük sekmesi | Süreklilik, bugün, son hikâyeler, bu ay |
| Metin masal | Yalnızca cihazdaki offline motor (`OfflineStoryService`). Bulut metin yolu Faz 9'da kaldırıldı |
| Okuma defteri | Çocuk başına. Aile sahipliktir, çocuk deneyim |

## Akış

```
ParentIntent (StoryModeStep)   [mod adları kodda: bedtime / growth / adventure]
 ├─ doğrudan mod ──────────────┐
 └─ Bana sürpriz yap           │
      StoryModeResolver         │  son 3 hikâyenin modu, en yeni en ağır
      (recentModes, seed) ──────┤
                                ▼
                       StoryMode (3'ten biri)
                                │
             StoryIdeaStep (bugün isteğe bağlı; Faz 10'da bayrakla kapanır)
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

- **Uyku öncesinin gerçek bir arkı yok.** Geçici olarak `charge` ailesine bağlı (5-6 için 2, 3-4 için 1 blueprint). Profilin `editorialNote`'u bunu söylüyor. Uyku arkı yazıldığında eşleme değişmeli.
- **3-4 bandında yalnızca Uyku öncesi kurulabilir**, çünkü o bantta tek blueprint `charge` ailesinden. Kurulamayan mod ekranda gösterilmez.
- **7-8 ve 9-10 bantlarının içeriği yok.** `AgeBandResolver.servedBand` en yakın, eşitlikte küçük banttan sunar. Bu bir geçici çözüm.
- Mod henüz sayfa sayısını, kelime bütçesini ya da dekorasyon yoğunluğunu etkilemiyor. Hepsi `StoryModeProfile`'a veri olarak eklenebilir.
- Arkadaş adımı (`CompanionStep`) Faz 11'de "Masalda kimler olsun?" adımına dönüşür (katalog yol arkadaşları + Masal ailem).

## Okuma defteri geçişi

Eski, cihaz geneli `mp_readDays` / `mp_readSeconds`, ilk etkinleşen çocuğa (geçiş anında seçili olan) **kopyalanır**. Eski anahtarlar silinmez. İkinci bir çocuk eski geçmişi almaz. `mp_streakLegacyAssignedTo` bunun bir kez olduğunu kaydeder. Profil silinince o çocuğun defteri de silinir.
