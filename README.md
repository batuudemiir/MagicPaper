# MagicPaper

> ## 📌 Batuhan için: `irem` dalından notlar
>
> Yalnızca `irem` dalında; `main`'e alırken bu bölümü kaldır. Son güncelleme: 21 Kasım 2026.
>
> 1. **Ana sayfa senin son hâline döndü (21 Kasım, İrem'in kararı).** Okuma köşesi denemesi geri alındı: `HomeView.swift`, `MPHomeChrome.swift`, `MPTheme.swift` main ile birebir aynı; `MPHomeReadingNook.swift` ve üç görsel silindi, prototipte de eski ana sayfa. Main'e alırken ana sayfa için çakışma beklenmez.
> 2. **Paywall son tasarımı uygulandı (İrem'in seçimi, 21 Kasım):** prototipteki "C · Sade ve güven" olduğu gibi: "MagicPaper Premium" + "Ritüel ücretsiz kalır. Premium kitaplığı büyütür.", yan yana Yıllık/Aylık, onay işaretli beş fayda, deneme takvimi (yalnızca mağazada deneme varsa), güven satırı, 3.1.2 metni. Ragi ve "Planları gör" ara adımı kalktı. **Yıllık varsayılan seçili (İrem'in tasarım kararı;** 20 Kasım'da açık bırakmıştın). "%N avantajlı" ve "Ayda ₺X" mağaza fiyatından (`RevenueCatManager.priceAmount`, `localizedPricePerMonth`); ürün yoksa rozet görünmez. Satın alma, geri yükleme ve tek plan mantığın aynen duruyor. Prototipteki A/B/C seçenekleri kaldırıldı.
> 3. **Paywall'un yerleşimi: `docs/PAYWALL_YERLESIM.md`.** Senin `unlock` → kilit penceresi → kapı → Paywall yapın haritalandı (8 yol). İki düzeltme: (a) seri kartı Premium bölüm için sonsuza kadar "yarın" diyordu; artık günü gelince `CardState.locked` → "N. bölüm büyüklerle açılır" → kilit penceresi (`SeriesManager`, `SeriesCard`, `SeriesCopy`, widget'ta açılış günü vaat edilmez: `MPSurfaceSync`). (b) Deneme uygunluğu: `RevenueCatManager.checkTrialOrIntroDiscountEligibility`; uygun olmayan hesaba "7 gün ücretsiz" yazılmaz. **Kararını bekleyen 3 öneri** belgenin sonunda: satın almadan sonra işe kaldığı yerden dönmek, ilk deneyimden sonra ebeveyne tek tanıtım kartı, günlük limit düğmesinin adı.
> 4. **Olası hata: açılış ekranı takılması.** `SplashScreenView` 1,6 sn'de kapanmalı; GitHub'ın iPhone 17 Pro Max simülatöründe ilk açılışta iki turda da (7 ve 10 sn) kapanmadı, SE'de kapandı. Simülatöre özgü olabilir; gerçek cihazda ilk kurulumda bir bak (kapanırken `MPSound.play(.ragi)` çalıyor). Ekran turu için DEBUG'da `-mpDemo` ile açılış ekranı atlanıyor (`MagicPaperApp.showSplash`), Release aynı.
> 5. **Ana sayfa yayın denetimi: `docs/ANA_SAYFA_HAZIRLIK.md`. Onayını isteyen bir yetki değişikliği: günün masalı artık her zaman ücretsiz (A1, İrem'in kararı).** Uygulamayla gelen 12 günlük masalın 9'u vitrin dışındaydı; bu akşamın kartındaki "Masalı oku" 4 günden 3'ünde kilit penceresi açıyordu, yeni yükleyen ailenin ilk dokunuşu dahil. Değişiklik vitrinin tanımında, `EntitlementPolicy`'ye dokunulmadı: `ClassicsLibrary.isInFreeShowcase` günün Original'ini (ana sayfa kartı) ve Masallar'daki "Günün masalı" klasiğini vitrine sayar; `DailyStoryManager.todaysPick` kart, widget ve vitrinin ortak cevabı. Testler `OriginalTalesTests`'te (çalıştırılmadı, Mac gerekiyor). Daha dar istersen (yalnızca ana sayfa kartı) `todaysTale` koşulunu çıkarman yeterli. Kalan maddeleri (canlı veri, saat, büyük yazı, karttaki kapak, ana sayfa modeli) senin tasarımına dokunmadan kodluyorum.
> 6. **Masal dolabım: tam boy kahraman (yeni, 22 Kasım).** İrem'in iki dolap paketi entegre edildi; ayrıntı ve eşleme tablosu `design-handoff/dolap/README.md`. Profil'deki kahraman kartı artık tam boy insan kahraman dolabını açıyor (`HeroStudioView`: 17 seçim yuvası, 16 kombin, 8 başlangıç yüzü, 36 boyalı parça, saç boyası, yakın yüz, geri al, çıkış onayı). Kayıt `HeroLook.figure` içinde, yani çocuk başına kayıt ve `heroes` eşitlemesi değişmeden taşıyor; profil büstü aynı kayıttan kırpılıyor; ten, saç, başörtüsü ve gözlük eski alanlara da yansıyor (görselli kitap aynı çocuğu görsün). Hayvanlar eski dolapta. **Kararını bekleyen:** (a) tam boy dolapta yıldız fiyatı yok (paket öyle istiyor), eklemek ister misin; (b) çizimin kendi paleti `HeroFigurePalette.swift` tasarım yasasının renk kuralı dışında, kapak paleti gibi; (c) kenardan kaydırarak geri çıkış onayı atlayabilir, cihazda bak. Uygulama boyutu +7 MB.

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
