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
> 6. **Profil avatarı (İrem'in kararı, 23 Kasım; tam boy dolap iptal edildi ve geri alındı).** Profil'deki kimlik kartına dokununca "Profilini düzenle" penceresi zıplayarak açılıyor (`ProfileAvatarPicker`, `Screens/Hero/ProfileAvatar.swift`): Ragi'nin 15 pozu, Tarçın'ın 3 ve Kestane'nin 3 yüzü (`Assets.xcassets/Avatars`, pozlardan kare yüz kırpımı). Seçim `HeroLook.avatar`'da: çocuk başına, `heroes` eşitlemesiyle; `HeroAvatarView` avatar varsa büst yerine onu çiziyor, masal görsellerindeki çocuk kimliği değişmedi. "Kahramanını giydir / Dolabı aç" satırı kalktı; eski dolap Büyükler için > kahraman ve Masal ailem'den açılmaya devam ediyor. **Kararını bekleyen:** (a) pencere sistem sheet'i değil kendi çizdiğimiz katman (yasa: kısa iş yalnızca `mpSheet`); İrem oyun dilinde zıplayan pencere istedi; (b) Profil'de Ragi'nin sözü varken avatar da Ragi olabiliyor ("ekranda tek Ragi"); (c) Kestane senin notunda "nihai çizim değil", listeden çıkarmak tek satır. Ayrıca ana sayfa manzaraları yeni (GPT, alt kenarı #FFF8EE kâğıda boyalı), koddaki geçiş kalktı.
> 7. **Ana sayfa yeni düzen (İrem'in kararı, 23 Kasım).** Referans: alışkanlık uygulaması ekranı; prototip `design-preview/app/home.js`, uygulama `Views/HomeView.swift` + `DesignSystem/Pastel/MPHomeBoard.swift`. Üstte mordan beyaza inen başlık (`MP.C.homeSky`, paletin mor600/400/100/50'si), solda menü, sağda bildirim ve arama (`MPCircleButton`), "Merhaba, <ad>", el sallayan Ragi, üç bilgi kartı (yıldız, okuma günü, masallar); ortada koyu mor bu akşamın kartı (`HomeTonightBoard`, Ragi'nin ayakları kartın alt çizgisinde, 5 parçalı ilerleme, ikincil düğme); altta "Yeni bir masal yaz" + artı ve mod liste satırları (`HomeModeRow`); seri kartı aynen. Gece/gündüz sahnesi kalktı (`HomeHeaderScene` artık kullanılmıyor). Veri katmanı (`HomeFeedStore`) aynı, `HomeFeed.stories` eklendi. **Kararını bekleyen:** (a) başlıktaki gradient (yasa: arayüz yüzeyinde yok); (b) ekranda iki Ragi (başlık ve kart; yasa: ekran başına bir); (c) menü artık var (madde 8); bildirim yeni rozet varsa marka noktası gösterip Profil'i açıyor, arama Masallar'da aramayı açıyor.
> 8. **Menü ve "Okuma yolculuğum" (İrem'in kararı, 23 Kasım).** Ana sayfadaki menü düğmesi sistem sheet'i açar (`KidMenuSheet`, `MPSheetRoute.menu`): Okuma yolculuğum, Rozetlerim, Çıkartma albümüm, Yeni kelimelerim, Masal haritam, Masal ailem, Kitaplık renklerim (hepsi var olan sayfalar) ve "Büyükler için". Yeni sayfa `ReadingJourneyView` (`MPKidRoute.journey`, model `ReadingJourney`, test `ReadingJourneyTests`): tracker referansından, ilke 7'ye göre (okunmayan gün boş daire, baskı dili yok, yıldız katında ilerleme yok). Veri `MPStreak.daysThisWeek` (yeni) ve `minutesThisWeekByDay`. Yeni Ragi pozu `Mascot.cheer` (`Brand/mascotCheer`, kukla gözleri ölçüldü). Ortak satır `HomeListRow` (mod satırı da onu kullanıyor). **Bakman gereken:** yolculuk sayfasının başlığı `MPTopBar` değil, ana sayfanın mor göğünde kendi satırı (geri `MPCircleButton`); kural "çocuk alt sayfalarında MPTopBar" diyor.

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
