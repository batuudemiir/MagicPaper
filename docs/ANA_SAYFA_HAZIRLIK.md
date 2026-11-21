# Ana sayfa: yayına hazırlık denetimi

Hazırlayan: İrem (Claude ile), 21 Kasım 2026. Dal: `irem`. Kapsam: `Views/HomeView.swift`,
`DesignSystem/Pastel/MPHomeReadingNook.swift`, `MPHomeChrome.swift`, ana sayfanın okuduğu
servisler (`MPTonightSource`, `MPTonight`, `DailyStoryManager`, `EntitlementPolicy`,
`MPAppState.openTonight` / `startStoryCreation`) ve gerçek uygulamanın son ekran turu (`069b67a`).

Amaç: bu listenin A, B ve C bölümleri kapanınca ana sayfa yayına hazır olur.

## A. Yayını engelleyenler

| # | Sorun | Kanıt | Öneri |
|---|---|---|---|
| A1 | **Günün masalı ücretsiz kullanıcıda kilide çarpıyor.** Ana sayfanın tek birincil düğmesi ("Masalı oku") çoğu gün kilit penceresini açıyor. | `openTonight` → `readOriginal` → `unlock(.classicLibrary, .classic(inShowcase:))`. Vitrin yalnızca haftanın seçkisi ve Uyku vakti rafı. Uygulamayla gelen 12 günlük masalın yalnızca 3'ü vitrinde: **4 günden 3'ünde** yeni yükleyen ailenin ilk dokunuşu kilit. Paywall da "Ritüel ücretsiz kalır" diyor. | Günün masalı her zaman ücretsiz: `readOriginal` günün masalı için `inShowcase: true` sorar (karar `EntitlementPolicy`'de kalır). **Batuhan'ın kararı.** |
| A2 | **Ücretsiz günlük hak bitince birincil düğme yine kilide gidiyor.** "Bugün okudun" durumunda düğme "Yeni masal yaz"; o gün masal yazılmışsa kilit penceresi. Dünya karoları da aynı. | `HomeTonightInvite` hakkı bilmiyor; `startStoryCreation` → `.unlimitedTextStories`. | Hak bittiyse davet "Yarın yeni bir masal yazabiliriz" der, birincil düğme kitaplıktan bir masal açar. Karolar sakin kalır (kilit penceresi zaten sakin), ama birincil düğme asla kilide gitmez. |
| A3 | **Ana sayfa canlı veriyi izlemiyor.** Yalnızca masal listesi ve profil değişince yenileniyor. | `MPStreak`, `DailyStoryManager`, `SeriesManager`, `ClassicProgressStore`, abonelik durumu gözlenmiyor; başka bir şey yeniden çizdirirse tesadüfen düzeliyor. Raf önbelleği klasik okununca yenilenmiyor ("Henüz okunmadı" kalır). Satın almadan sonra düğmeler eski kalabilir. | Tek bir ana sayfa modeli (C1) bu kaynakları izler ve bir kez hesaplar. |
| A4 | **Saat ilerleyince sayfa değişmiyor.** Uygulama açıkken yatma saati gelirse davet "Uyku masalı zamanı"na geçmez, selam değişmez. | Görünüm zamanı yalnızca çizilirken okuyor. Widget aynı kuralı `MPTonight.nextChange` ile zamanlıyor, ana sayfa zamanlamıyor. | Model `nextChange` anında ve uygulama öne gelince yeniden hesaplar. |
| A5 | **Okul öncesi kademe yarım.** Batuhan'ın 14 Kasım kararı (okumayan çocukta sayfa = ad, bu akşamın masalı, büyük karolar) yeni ana sayfada yalnızca selamda uygulanıyor. | Okumayan çocuğa "Masal adı veya konu" arama kutusu, yazılı raf durumları gösteriliyor. Davette masalın **kapağı yok**: okumayan çocuk masalı tanıyamıyor. | Küçük kademede "Masal bul" yok, karolar büyük, davette kapak. Kapak iki kademede de iyi olur. |
| A6 | **En büyük yazıda birincil düğme ekran dışında.** | SE + en büyük yazı ekran görüntüsü: sahne yüksekliğin %46'sı, başlık iki ekran sürüyor, düğme görünmüyor. | Erişilebilirlik boyutlarında sahne küçülür (ya da gizlenir), düğme ilk ekranda kalır. |

## B. Görsel kalite

| # | Sorun | Kanıt | Öneri |
|---|---|---|---|
| B1 | **Görseller düşük çözünürlüklü.** | Okuma köşesi 852 px, tek ölçek; Pro Max'te ~1320 px gerekir (1,5 kat büyütülüp yumuşuyor). Dünya karoları 141 px yüksek, ekranda ~80 pt; @3x için 240 px gerekir. | GPT'den: sahne en az 1320 px genişlik, karolar en az 3 kat. (Tasarım işi, İrem.) |
| B2 | **Sahne her saatte gece.** Sabah "Günaydın" + ay ışığı. | Tek görsel. Eski gündüz/gece sahneleri yalnızca ölü koddaydı. | Gündüz ve akşam sürümü; uyku saatinde akşam. |
| B3 | **Ragi resmin içinde boyalı.** Dokununca tepki yok; `MascotImage` kuralının dışında (README madde 1b). | | Ragi'siz sahne + üstüne `MascotImage(.reading)`: kural ve kukla hareketi birlikte çözülür. Görsel gerekiyor. |
| B4 | **Uyku öncesi karosunun çizimi yok,** diğer ikisi resimli. | `StoryMode.homeWorldArt` bedtime için `nil`. | Üçüncü çizim. |
| B5 | **Karolar eşit boyda değil.** | `LazyVGrid` satırı eşitlemez; `maxHeight: .infinity` işe yaramıyor, ad iki satıra kırılınca karolar farklı boy olur. | `Grid` ya da `HStack` + eşit yükseklik. |

## C. Mimari

| # | Sorun | Öneri |
|---|---|---|
| C1 | **Alan mantığı görünümde** (AGENTS.md ilke 3): bu akşamın durumu, raf seçimi, editoryal öneri, mod süzme ve düğme kararı `HomeView` içinde, test edilemiyor. | Saf bir `HomeFeed` modeli (girdiler → ekranın bütün kararları) + birim testleri. Görünüm yalnızca çizer. Widget'ın kullandığı `MPTonight` aynen kalır. |
| C2 | **Pahalı hesaplar her çizimde.** `MPTonightSource.current` (kitaplık süzgeci + yarım masal seçimi) bir çizimde üç kez; editoryal öneri ve `SeriesManager.cardState` gövdede. | Modelde bir kez, veri değişince. |
| C3 | Raf, davetteki kitabı **başlıkla** dışlıyor. | Kimlikle (`Resume.storyID`). |
| C4 | **Ölü kod ve yanıltıcı dosya.** `MPHomeChrome.swift`'teki `HomeHeroCard`, `WaveBottom`, `CloudShape`, `HomeStatLine` artık ana sayfada yok; `HomeSky`, `HomeSceneMascot`, `HomeModeTile` başka ekranlarda kullanılıyor. `homeSceneDay/Night` görselleri (~900 KB) yalnızca ölü `HomeHeroCard`'da. | Kullanılmayanı sil, kullanılanı ait olduğu yere taşı. Snapshot testi `HomeHeroCard` yerine `HomeTonightInvite`'ı çeker. B2 gündüz sahnesi için `homeSceneDay` yeniden kullanılabilir mi, önce ona bakılır. |
| C5 | Ölçekte olmayan boyutlar: `HomePickRow` kapağı `minTouchHero * 1.75`, karo görseli `minTouchHero + md`. | `MPSize`'a adlı ölçü. |

## D. Küçük UX ayrıntıları

- D1. Gündüz "Bu akşamın masalı" yazıyor; 17.00'den önce "Bugünün masalı".
- D2. Devam durumunda ilerleme yalnızca "Sayfa 3 / 5"; kapağın üstünde ilerleme izi (Kitaplık'taki gibi) daha okunur.
- D3. VoiceOver'da birincil düğme yalnızca "Masalı oku" diyor; hangi masal olduğu söylenmiyor.
- D4. "Tümünü gör" titreşimsiz, diğer bağlantılarla tutarsız.

## Plan

1. **Kod, şimdi (İrem + Claude):** C1–C5, A2–A6, B5, D1–D4. Ana sayfanın davranışı için birim testleri.
2. **Batuhan'ın kararı:** A1 (günün masalı ücretsiz). Kod tek satır; karar onun.
3. **Görsel (İrem, GPT):** B1–B4: @3x sahne, gündüz/akşam sürümleri, Ragi'siz sahne, Uyku öncesi karosu.
4. **Doğrulama:** `[ekran]` turu (SE + Pro Max, normal + en büyük yazı), Batuhan cihazda: gün dönümü, yatma saati, satın alma sonrası.
