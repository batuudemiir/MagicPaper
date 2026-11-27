# Ana sayfa: yayına hazırlık denetimi

Hazırlayan: İrem (Claude ile), 21 Kasım 2026. Dal: `irem`.

**Tasarım: Batuhan'ın main'deki son ana sayfası** (`HomeHeaderScene` + bu akşamın kartı +
"Yeni bir masal yaz" karoları + devam eden seri). Okuma köşesi denemesi geri alındı (21 Kasım).
Kapsam: `Views/HomeView.swift`, `DesignSystem/Pastel/MPHomeChrome.swift`, ana sayfanın okuduğu
servisler (`MPTonightSource`, `MPTonight`, `DailyStoryManager`, `EntitlementPolicy`,
`MPAppState.openTonight` / `startStoryCreation`) ve gerçek uygulamanın ekran turu (`f600ed0`).

Amaç: A, B ve C kapanınca ana sayfa yayına hazır olur. Görünüş değişmez; düzeltmeler davranış,
veri ve erişilebilirlik içindir.

## A. Yayını engelleyenler

| # | Sorun | Kanıt | Öneri |
|---|---|---|---|
| A1 ✅ | **Günün masalı ücretsiz kullanıcıda kilide çarpıyor.** *Yapıldı (21 Kasım): `ClassicsLibrary.isInFreeShowcase` günün Original'ini ve günün klasiğini vitrine sayar; `DailyStoryManager.todaysPick` kart, widget ve vitrinin ortak cevabı; testler `OriginalTalesTests`.* Bu akşamın kartındaki "Masalı oku" çoğu gün kilit penceresini açıyor. | `openTonight` → `readOriginal` → `unlock(.classicLibrary, .classic(inShowcase:))`. Vitrin yalnızca haftanın seçkisi ve Uyku vakti rafı. Uygulamayla gelen 12 günlük masalın yalnızca 3'ü vitrinde: **4 günden 3'ünde** yeni yükleyen ailenin ilk dokunuşu kilit. Paywall da "Ritüel ücretsiz kalır" diyor. | Günün masalı her zaman ücretsiz: `readOriginal` günün masalı için `inShowcase: true` sorar (karar `EntitlementPolicy`'de kalır). **Batuhan'ın kararı.** |
| A2 ✅ | **Ücretsiz günlük hak bitince kartın düğmesi yine kilide gidiyor.** *Yapıldı (21 Kasım): `TonightState.readToday(canWrite:)`, `MPAppState.canWriteNewStoryToday`; hak yoksa kart "Bu akşam kitaplığından bir masal okuyalım" · "Kitaplığına bak", `openTonight` Kitaplık sekmesini açar.* "Bugün okudun" durumunda düğme "Yeni masal yaz"; o gün masal yazıldıysa kilit penceresi. | `HomeHeroCard` hakkı bilmiyor; `startStoryCreation` → `.unlimitedTextStories`. | Hak bittiyse kart "Yarın yeni bir masal yazabiliriz" der, düğme kitaplıktan bir masal açar. Karolar kilit penceresine gidebilir (o pencere sakin); kartın tek birincil düğmesi gitmez. |
| A3 ✅ | **Ana sayfa canlı veriyi izlemiyor.** *Yapıldı (21 Kasım): `HomeFeedStore` masal listesi, profil, okuma günü, günün masalı, seri, abonelik, ayarlar ve rozet defterini (`.mpFamilyDataChanged`) dinler; 80 ms içinde gelenleri tek hesapta toplar, sonuç aynıysa yayınlamaz.* | Gözlenen: masal listesi, profil, okuma günü. Gözlenmeyen: `DailyStoryManager` (gün dönünce günün masalı), `SeriesManager` (seri kartı çıkar/kaybolur), abonelik durumu. Yıldız sayısı yalnızca masal listesi değişince hesaplanıyor: sabah yıldızı ve klasik okuma sonrası eski kalır. Başka bir şey yeniden çizdirirse tesadüfen düzeliyor. | Tek bir ana sayfa modeli (C1) bu kaynakları izler, bir kez hesaplar. |
| A4 ✅ | **Saat ilerleyince sayfa değişmiyor.** *Yapıldı (21 Kasım): `HomeFeed.nextChange` (yatma saati, 05.00, gece yarısı, selam saatleri 05/11/17/22, ücretsiz hakkın açıldığı an) anında yenilenir; saat elle değişince ve uygulama öne gelince de. Gün dönünce günün masalı ve seri yeniden seçilir.* Uygulama açıkken yatma saati gelirse kart "Uyku masalı zamanı"na, sahne geceye geçmez; selam aynı kalır. | Görünüm zamanı yalnızca çizilirken okuyor. Widget aynı kuralı `MPTonight.nextChange` ile zamanlıyor, ana sayfa zamanlamıyor. | Model `nextChange` anında ve uygulama öne gelince yeniden hesaplar. |
| A5 ✅ | **En büyük yazıda birincil düğme ekran dışında.** *Yapıldı (21 Kasım): erişilebilirlik boyutlarında `HomeHeaderScene(compact:)` 120 pt'lik bant (Ragi küçülerek bantta), başlık bandın altında kâğıtta; selam düşer (rozet notu kalır), yıldız/gün kartın altına iner, kartta kapak düşer. Normal boyutlar aynı. Pro Max'te doğrulandı (`4d0d569`); SE'de açıklama cümlesi düğmeyi hâlâ itiyordu, 22 Kasım'da uyku ve "bugün okudun"da en büyük yazıda düşürüldü.* | SE + en büyük yazı (`f600ed0` turu): sahne sabit 300 pt, başlık kartı ekranı dolduruyor, "Okumaya devam et" görünmüyor. Yasa: kıvrımda başlık + kahraman alan. | Erişilebilirlik boyutlarında sahne kısalır; kartın düğmesi ilk ekranda kalır. |
| A7 | **Uyku saatinde hak bitmişse "Uyku masalı yaz" yine kilide gidiyor.** (21 Kasım, A2 sırasında bulundu.) | Kart "Uyku masalı yaz" → `BedtimeStorySheet` → uyku masalı seçeneği → `startStoryCreation(mode: .bedtime)` → `.unlimitedTextStories`. | Hak yoksa pencerede yazma seçeneği yerine yarım masal, bir uyku masalı (vitrin) ya da kitaplık. |
| A6 ✅ | **Kartta kapak çoğu zaman yok.** *Yapıldı (21 Kasım): `HomeFeed.cover`: yarım masalda Kitaplık kapağı (+ ilerleme halkası), günün masalında boyalı Original kapağı ya da kategorinin renginde başlık kapağı; uyku ve "bugün okudun"da yok. `HomeHeroCard(art:)` metnin solunda. Eşleşmeyen eski `tonightCover` silindi.* Okumayan çocuk (okul öncesi kademe) masalı yalnızca kapaktan tanır. | `tonightCover` yalnızca günün masalı bir klasikse; günün Original'i ve yarım masal kapaksız (kodun kendi notu). Kapak ayrıca `showsScene: false` olduğu için hiç çizilmiyor: sahne başlığa taşınınca kapak düştü. | Kartta küçük kapak: yarım masal, günün masalı ve klasik için. `MPTonight.Resume` kimliği taşıyor; kapak oradan bulunur. |

## B. Görsel ve erişilebilirlik

| # | Sorun | Öneri |
|---|---|---|
| B1 | VoiceOver'da kartın düğmesi yalnızca "Masalı oku" diyor; hangi masal olduğu söylenmiyor. | Etikete masalın adı. |
| B2 | Sahnedeki Ragi gece de dokununca zıplıyor; yasa: zıplama yalnızca gündüz masal sonu ve dokununca. Dokununca serbest, ama uyku saatinde sessiz kalmalı. | Gece dokunuşu tepkisiz ya da yalnızca göz kırpma. |
| B3 | Gündüz "Bu akşamın masalı" yazıyor. | 17.00'den önce "Bugünün masalı". |

## C. Mimari

| # | Sorun | Öneri |
|---|---|---|
| C1 ◐ | **Alan mantığı görünümde** *Kısmen (21 Kasım): selam, bu akşamın durumu, gece, yıldız, gün, seri kartı ve kapak `HomeFeed`'te (`Screens/Home/`), 16 test `HomeFeedTests`. Kalan: mod süzme.* (AGENTS.md ilke 3): bu akşamın durumu, kapak, gece, yıldız, mod süzme ve düğme kararı `HomeView` içinde; test edilemiyor. | Saf bir `HomeFeed` modeli (girdiler → ekranın bütün kararları) + birim testleri. Görünüm yalnızca çizer. Widget'ın `MPTonight`'ı aynen kalır. |
| C2 ✅ | **Aynı hesap bir çizimde birkaç kez.** *Yapıldı: `MPTonightSource.current`, seri kartı ve kapak veri değişince bir kez (`HomeFeedStore`); her çizimdeki `UIImage` yüklemesi kalktı.* `MPTonightSource.current` (kitaplık süzgeci + yarım masal seçimi) `tonightState`, `isNight` ve `tonightCover` için ayrı ayrı; `tonightCover` her çizimde `UIImage(named:)` yüklüyor; `SeriesManager.cardState` gövdede. | Modelde bir kez, veri değişince. |
| C3 | `MPTonight.unread` kapağı başlık eşitliğiyle buluyor (`tale.title == title`). | Kimlikle. |
| C4 | `HomeHeroCard`'ın `showsScene` yolu artık kullanılmıyor (sahne başlıkta); kart içindeki sahne kodu ölü. | Temizlik, görünüş değişmeden. |

## Plan

1. **Kod (İrem + Claude):** A2–A6, B1–B3, C1–C4. Ana sayfanın davranışı için birim testleri. Görünüş Batuhan'ınki kalır.
2. **A1 yapıldı** (İrem'in kararı, Batuhan'ın onayına).
3. **Doğrulama:** `[ekran]` turu (SE + Pro Max, normal + en büyük yazı); Batuhan cihazda gün dönümü, yatma saati ve satın alma sonrası.
