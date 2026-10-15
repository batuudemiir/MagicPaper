# Uyku modu v2'ye, akşam serbest (plan, 15 Ekim 2026)

İki karar (Batuhan, 15 Ekim 2026):

1. **Uyku modu lansmanda yok, v2'de çıkar.** Kararan ekran, süre sayacı, sesli
   okuma oturumu, Live Activity ve "Uyku modu" Siri kısayolu v1'de kullanıcıya
   görünmez. Ana sayfanın akşam kartı buna göre şekillenir: uyku modunu açmak
   yerine "Uyku masalı oluştur" penceresi açar.
2. **Akşam yalnız uyku masalı değil.** Uyku saatinde Yarat üç modu da sunar;
   Uyku öncesi yalnızca öne çıkar (ilk sırada, vurgulu).

"Uyku öncesi" **masal modu** v1'de kalır; v2'ye giden yalnızca **uyku modu**
(oynatma ekranı) özelliğidir.

---

## Bugünkü durum (main@2eb0230)

| Yer | Bugün | Dosya |
|---|---|---|
| Ana sayfa akşam kartı | "Uyku masalı zamanı", düğme "Uyku modunu aç" → `openSleepMode()` → uyku modu; uyku masalı yoksa Uyku öncesi akışı | `MPHomeChrome.swift:420-424`, `MPAppState.swift:170-192` |
| Yarat, uyku saatinde | Yalnız `[.bedtime]` (`allowedModes`) | `StoryCreationSteps.swift:33-39`, `StoryCreationFlow.swift:81-83, 300-304`, `HomeView.swift:165-169` |
| Masal sonu "İyi geceler" | `afterReader = .sleep(story)` → uyku modu | `StoryReaderView.swift:190-191`, `MPAppState.swift:155-161` |
| Klasik masal detayı | "Uyku modu" karesi | `ClassicDetailView.swift:129-133` |
| Siri / Kısayollar | `StartSleepModeIntent` "Uyku modu" | `MPAppIntents.swift:23-35, 50-58` |
| Widget / derin bağlantı | `magicpaper://sleep` → `openSleepMode()` | `MPSurfaceLink`, `MPAppState.swift:206-207` |
| Live Activity | Uyku modu oynarken başlar | `MPSleepPlayback.swift`, `MagicPaperWidgets/Sources/SleepLiveActivity.swift` |
| Ebeveyn Güvenlik | "… ve sonrasında yalnızca uyku masalı" | `ParentSafetyView.swift:53-55`, `MPSettingsStore.swift:28` |

---

## V1 — lansman

### A. Uyku modunu bayrağın arkasına al (kod silinmez)

- Yeni `MPFeatures.sleepMode = false` (tek sabit; `CloudIllustrationAccess` gibi).
  `SleepModeView`, `MPSleepPlayback`, `MPSleepActivity` ve testleri olduğu gibi kalır.
- Giriş noktaları bayrağa bağlanır:
  - `openSleepMode()` bayrak kapalıyken uyku masalı penceresini açar (B).
  - `ClassicDetailView`: "Uyku modu" karesi gizlenir (iki kare kalır: Dinle, Listeme ekle).
  - Masal sonu "İyi geceler": uyku modunu açmaz; okuyucu kapanır, Ana sayfaya
    sakin bir "İyi geceler" tostu. Uyku saatinde birincil kalır.
  - `magicpaper://sleep` gelirse `.tonight` gibi davranır (eski widget dokunuşları boşa düşmez).
  - Siri: `StartSleepModeIntent` `AppShortcutsProvider`'dan çıkar (kısayollar
    derleme anında okunur; çalışma anı bayrağı yetmez). Intent tipi v2 için kalır.
  - Live Activity: başlatan tek yer uyku modu, ek iş yok. `MPSleepActivity.endAll()` açılışta kalsın.
- Mağaza metni, ekran görüntüleri ve `marketing/` içinde "uyku modu" geçen yerler v1'den çıkar.

### B. Akşam kartı → "Uyku masalı oluştur" penceresi

- Kart durumu `.bedtime` kalır (gece sahnesi, uyuyan Ragi, "Saat 20.30",
  "Uyku masalı zamanı"). Değişen: alt metin ve düğme.
  - Alt metin: "Kısa, sakin bir masalla günü kapatalım."
  - Düğme: **"Uyku masalı oluştur"** (`moon.fill`).
- Düğme yeni `BedtimeStorySheet`'i açar (alt sayfa, `.medium` detent, `MP.R.sheet`):
  - Başlık: "Bu geceki masal" · tek satır: "Kısa, sakin ve uykuya hazırlayan bir masal."
  - Birincil: **"Uyku masalı oluştur"** → `startStoryCreation(mode: .bedtime)`
    (doğrudan "Masalda kimler olsun?" adımına).
  - Yarım masal varsa ikincil satır: "Kaldığın yerden: <başlık>" → `read(story)`.
  - Ghost: **"Başka bir masal seçeyim"** → `startStoryCreation()` (mod adımı, üç mod).
  - Ragi bu sayfada yok (sahnede zaten uyuyor; ekranda tek maskot).
- Mantık görünümde değil: `MPAppState.openBedtimeSheet()` ve sayfanın seçenekleri
  `MPTonightSource`'tan (yarım masal bilgisi zaten orada).
- **Kendiliğinden açılmaz.** Pencere yalnızca karta dokununca gelir (ilke 7: sakin,
  dürtmeyen). Akşam açılışında otomatik pop-up önerilmez.
- Widget ve "Masal oku" Siri kısayolu uyku saatinde aynı pencereyi açar.

### C. Akşam üç mod serbest, uyku öncesi önde

- `StoryCreationSteps.allowedModes(_:isBedtime:)` artık filtrelemez; yerine
  `orderedModes(_:isBedtime:)` + `emphasizedMode(isBedtime:) -> StoryMode?`:
  uyku saatinde Uyku öncesi ilk sırada ve vurgulu; gündüz bugünkü sıra, vurgu yok.
- Ana sayfa "Bu akşam nasıl bir masal olsun?" şeridi: vurgulu kare
  `HomeModeTile`'ın seçili hâli + "Bu akşam için" etiketi (renk tek başına
  bilgi taşımaz; `accessibilityLabel` "Uyku öncesi, bu akşam için önerilen").
- `StoryModeStep` (Yarat 1): aynı vurgu; diğer iki mod tam seçilebilir.
- "Bana sürpriz yap" uyku saatinde de üç moddan seçer (değişmez). İstenirse
  ağırlık Uyku öncesine kayar — ayrı karar.
- Masal sonu düğme sırası değişmez (uyku saatinde "İyi geceler" birincil).
- 3-4 bandı, seri vb. mevcut mod kuralları aynı kalır; yalnızca saat kuralı gevşer.

### D. Ebeveyn kopyası

- Güvenlik → "Uyku saati" altyazısı: "20.30'dan sonra uyku masalı öne çıkar".
- `MPSettingsStore` ve `MPBedtime` belge yorumları buna göre.
- Uyku saati anahtarı kapalıyken: akşam kartı yok, vurgu yok (bugünkü gibi).

### Testler

- `PastelHomeRulesTests`: `allowedModes … isBedtime: true == [.bedtime]` testi
  yeni kurala çevrilir (uyku saatinde üç mod, Uyku öncesi ilk ve vurgulu;
  bandda Uyku öncesi yoksa vurgu yok).
- `openTonight` / `open(.sleep)` bayrak kapalıyken uyku oturumu açmaz, pencereyi açar.
- `MPAppIntents`: kısayol listesinde uyku modu yok.
- Simülatör: akşam (saat ayarı 20.30 öncesi) açık + koyu, AX5, SE + Pro Max;
  pencere ve vurgulu mod karesi.

### Dokunulan dosyalar (tahmini)

`MPHomeChrome.swift`, `HomeView.swift`, `MPAppState.swift`, `StoryCreationSteps.swift`,
`StoryCreationFlow.swift`, `StoryModeStep.swift`, `ClassicDetailView.swift`,
`StoryReaderView.swift`, `MPAppIntents.swift`, `ParentSafetyView.swift`,
yeni `BedtimeStorySheet.swift`, yeni `MPFeatures.swift`, `PastelHomeRulesTests.swift`.
`MPHomeChrome.swift` paylaşılan dosya: başka oturum açık değişiklik tutuyorsa önce o biter.

---

## V2 — uyku modu

- `MPFeatures.sleepMode = true`; giriş noktaları geri gelir: akşam penceresine
  "Uyku modunda dinle" seçeneği, klasik detayda kare, masal sonu "İyi geceler" →
  uyku modu, Siri kısayolu, Live Activity.
- v2 öncesi açık kalemler (FAZ 17/19 kayıtlarından):
  - Gerçek bir uyku arkı (Uyku öncesi bugün geçici olarak `charge` ailesine bağlı).
  - Live Activity ay simgesi.
  - Uyku modu masal görselleri 1x.
  - Aile sesiyle okuma (FAZ 18) uyku modunda uçtan uca cihazda doğrulanmadı.
  - VoiceOver turu.
- v2 tasarım soruları: süre seçenekleri (10/15/20), kararma eğrisi, beyaz gürültü
  var mı, masal bitince ne olur.

---

## Açık kararlar

1. Pencere yalnız dokununca mı (öneri), yoksa akşam ilk açılışta bir kez de kendiliğinden mi?
2. Uyku saatinde "Bana sürpriz yap" Uyku öncesine ağırlık versin mi?
