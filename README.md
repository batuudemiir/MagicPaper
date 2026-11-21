# MagicPaper

> ## 📌 Batuhan için: `irem` dalından notlar
>
> Yalnızca `irem` dalında; `main`'e alırken bu bölümü kaldır. Son güncelleme: 21 Kasım 2026.
>
> 1. **Ana sayfa "Okuma köşesi" (İrem'in tasarım kararı).** 19 Kasım'da onayladığın tam genişlik sahneli başlığın (`HomeHeaderScene`) yerine GPT tasarımı: "İyi geceler, İrem" + avatar, pencere önünde okuyan Ragi sahnesi, "Bu akşam" daveti, "Başka bir dünya seç" (resimli karolar), "Kitaplığından" (Kitaplık modeliyle en çok iki kitap), "Masal bul" (Masallar'da arama + tek Original öneri). Kod: `Views/HomeView.swift`, `DesignSystem/Pastel/MPHomeReadingNook.swift`, üç yeni görsel (`Scenes/homeReadingNook`, `homeWorldLearning`, `homeWorldAdventure`), `MP.C.homePaper`.
>    Kurallarla çakışan, onayını isteyen noktalar: (a) sekme başlığında avatar (7 Kasım "avatar yok" kuralının yerine), (b) Ragi bir sahne görselinin içinde, `MascotImage` değil; çizim GPT'den, illüstratör işi değil, (c) yıldız/gün satırı ana sayfadan kalktı (Profil'de duruyor).
> 2. **Alt çubuk bilerek değişmedi.** GPT tasarımında "Masal yaz" dairesi yok, yazma girişi sayfanın içinde. Senin 13 Kasım kararın (`KidTabBar` + daire) korunuyor; kaldırmak istersen ayrı iş.
> 3. **Paywall son tasarımı uygulandı (İrem'in seçimi, 21 Kasım):** prototipteki "C · Sade ve güven" olduğu gibi: "MagicPaper Premium" + "Ritüel ücretsiz kalır. Premium kitaplığı büyütür.", yan yana Yıllık/Aylık, onay işaretli beş fayda, deneme takvimi (yalnızca mağazada deneme varsa), güven satırı, 3.1.2 metni. Ragi ve "Planları gör" ara adımı kalktı. **Yıllık varsayılan seçili (İrem'in tasarım kararı;** 20 Kasım'da açık bırakmıştın). "%N avantajlı" ve "Ayda ₺X" mağaza fiyatından (`RevenueCatManager.priceAmount`, `localizedPricePerMonth`); ürün yoksa rozet görünmez. Satın alma, geri yükleme ve tek plan mantığın aynen duruyor. Prototipteki A/B/C seçenekleri kaldırıldı.
> 4. **Paywall'un yerleşimi: `docs/PAYWALL_YERLESIM.md`.** Senin `unlock` → kilit penceresi → kapı → Paywall yapın haritalandı (8 yol). İki düzeltme: (a) seri kartı Premium bölüm için sonsuza kadar "yarın" diyordu; artık günü gelince `CardState.locked` → "N. bölüm büyüklerle açılır" → kilit penceresi (`SeriesManager`, `SeriesCard`, `SeriesCopy`, widget'ta açılış günü vaat edilmez: `MPSurfaceSync`). (b) Deneme uygunluğu: `RevenueCatManager.checkTrialOrIntroDiscountEligibility`; uygun olmayan hesaba "7 gün ücretsiz" yazılmaz. **Kararını bekleyen 3 öneri** belgenin sonunda: satın almadan sonra işe kaldığı yerden dönmek, ilk deneyimden sonra ebeveyne tek tanıtım kartı, günlük limit düğmesinin adı.

Kişiselleştirilmiş çocuk masalları için iOS uygulaması. Çocuk, masallarda tekrar eden bir karakter olur.
Metin masallar cihazda, internetsiz bir masal motoruyla yazılır (LLM yok).

## Yapı

| Klasör | İçerik |
|---|---|
| `MagicPaper/` | Uygulama (SwiftUI). `Screens/`, `Views/`, `DesignSystem/`, `Services/`, `StoryEngineBridge/` |
| `StoryEngine/` | Yerel Swift paketi: StoryEngine, CharacterEngine, VisualSystem ve masal korpusu |
| `MagicPaperTests/` | Uygulama testleri |
| `AssetCatalog/`, `Assets/`, `Tools/`, `Scripts/` | Görsel varlıklar ve içerik araçları |
| `ci_scripts/`, `.github/` | Xcode Cloud ve GitHub Actions |
| `docs/` | Belgeler — başlangıç noktası `docs/README.md` |
| `marketing/`, `promo/` | Tanıtım videoları |

Yasal sayfalar: `PRIVACY_POLICY.md`, `TERMS_OF_SERVICE.md`, `privacy.html`, `privacy_policy.html`,
`terms_of_service.html`, `accessibility.html`.

## Çalıştırma

1. `Secrets.xcconfig.template`'i `MagicPaper/Secrets.xcconfig` olarak kopyalayın, anahtarları girin (git'e girmez).
2. Firebase'in `GoogleService-Info.plist` dosyasını `MagicPaper/` altına koyun (git'e girmez).
3. `MagicPaper.xcodeproj`'u açıp `MagicPaper` şemasını çalıştırın.

Testler:

```bash
xcodebuild test -project MagicPaper.xcodeproj -scheme MagicPaper -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

```bash
cd StoryEngine && swift test
```

Proje kuralları ve tasarım yasası: `AGENTS.md`. Yol haritası: `docs/MagicPaper_Faz_Plani_Ekim.md`.
