# UX kaynak araştırması: uygulama bütünlüğü

7 Kasım 2026 · `main@fb1bf12`. Batuhan'ın isteği: App Store uygulamaları için
profesyonel UX, erişilebilirlik, menü akışı ve yerleşim kaynakları; çünkü uygulama
"yapay zeka yapmış gibi" duruyor, sayfalar düzene oturmamış, bazı sekmeler değişik
açılıyor.

**Kapsam:** araştırma ve kod okuma. Uygulama kodu değişmedi. Simülatör çalıştırılmadı;
görsel yorumlar 23 Ekim görüntülerinden (`docs/butunluk/`), geçişlerle ilgili bulgular
koddan. Yıldız ve tarih bilgileri 7 Kasım'da GitHub API'sinden alındı.

## Sonuç

Token düzeyi büyük ölçüde temiz (`BUTUNLUK_DENETIMI.md`). Dağınıklık hissinin kaynağı
büyük olasılıkla **üç şey**:

1. Dört sekmenin dördü farklı başlık düzeniyle açılıyor.
2. Alt sayfalar için ortak bir kural yok: aynı iş, ekrana göre başka bir yoldan açılıyor.
3. Her bloğun kart olması ve butondaki mor gradient, yapay zeka üretimi arayüzlerde sık
   anılan iki kalıp.

Duolingo aynı sorunu Şubat 2026'da yazdı: her sekme tek başına çalışıyor ama bir aile
gibi durmuyordu. Çözümleri yeni ekran değil, ortak bir başlık sistemi ve daha az kart
oldu. **En yakın örnek bu.**

## Kodda doğrulanan sorunlar

### Sekmeler dört farklı açılıyor

| Sekme | Üst bölge | Sayfa içi gezinme | Kaydırınca saat çubuğu |
|---|---|---|---|
| Ana sayfa | `HomeHeader`: avatar + selam, sayfa başlığı yok | yok | şerit yok (16 Ekim kararı) |
| Günlük | Tam ekran vitrin, güvenli alanın altına giriyor | tek `NavigationStack` burada | `MPStatusBarBackdrop` |
| Kitaplık | Elle `titleBar` + `.padding(.top, lg)` | yok | şerit yok (16 Ekim kararı) |
| Köşem | Kitaplık'ın `titleBar` kopyası | yok | `MPStatusBarBackdrop` |

- `KidHeader` tanımlı, hiçbir yerde çağrılmıyor (`MPNavigationChrome.swift:220`).
- Zemin de farklı: Günlük `backgroundKid`, diğer üçü `backgroundSurface`.
- Seçili sekmeye yeniden dokunma yalnızca Günlük'te karşılık buluyor
  (`tabReselections`), oysa `ContentView.swift:278` bunu genel davranış diye anlatıyor.
- iOS 26 öncesi sekmeler `switch` ile kuruluyor (`ContentView.swift:257`), yani sekme
  değişince görünüm baştan kurulur. Hedef 17.6 olduğu için bu yol canlı. Apple sekmelerin
  gezinme durumunu korumasını bekliyor. Kaydırma konumu ve Günlük'ün açık sayfası bu
  yolda kaybolabilir; cihazda denenmedi.

### Alt sayfa açmanın altı yolu

| Yol | Örnek | Alt çubuk | Çıkış |
|---|---|---|---|
| Gerçek push | Günlük → klasik detay | görünür | Geri + kenardan kaydırma |
| Elle yana kayan katman | Seri (`ContentView.swift:205`) | kapanır | Geri |
| Kök `.overlay` | Yeni kelimelerim, Masal ailem, Kahraman | kapanır | Geri |
| Sistem `.sheet` + `mpSheet` | Kategoriler, Masal eylemleri | kapanır | aşağı çekme |
| Kendi çizimimiz `MPSheet` | Kim okuyacak?, profil, ilgi alanları | kapanır | kapat |
| `fullScreenCover` | Okuyucu, masal yazma, ama aynı zamanda Aile, Kitap yap, Kendi sesin, Paylaş | kapanır | Geri ya da X |

Toplam canlı kullanım: 21 `fullScreenCover`, 15 `.sheet`, 1 `navigationDestination`.
Yani gezinmenin neredeyse tamamı modal.

En görünür tutarsızlıklar:

- **Ebeveyn alt sayfaları aşağıdan açılıp "Geri" diyor.** `ParentRouteView` dört sayfayı
  `fullScreenCover` ile açıyor, başlıkları `MPParentHeader(onBack:)`. Görsel dil "bir
  seviye geri", hareket "modal kapanıyor". Apple sheet rehberi Geri'yi kapatma düğmesi
  olarak tanımlamıyor.
- **Aynı önem, farklı açılış.** Çocuk Günlük'te detaya girince alt çubuk kalıyor,
  Köşem'de Yeni kelimelerim'e girince kalkıyor. Kök katmandaki sayfalar kenardan
  kaydırmayla geri de gidemez (sistem push'u değiller).
- **Üst üste modal.** Örnek: Aile (cover) → davet (sheet) → paylaş (sheet). Ebeveyn kapısı
  altı ayrı yerden sunuluyor; biri de masal eylemleri sheet'inin üstünde. Apple: bir modal
  kapanmadan başkası açılmasın, modal "uygulama içinde uygulama" gibi durmasın.
- **"Masal yaz" alt çubukta bir eylem.** Apple sekme çubuğunu gezinme için tanımlıyor,
  eylem için değil; kodun kendi yorumu da "bir yer değil eylem" diyor. Bu 22 Ekim kararı,
  yanlış değil ama bilinçli bir sapma. Kararı değiştirmeyi önermiyorum, çünkü ürünün ana
  eylemi burası; yalnızca sapma olarak kayda geçsin.

### "Yapay zeka yapmış gibi" kalıpları

| Kalıp (kaynak: Fountain Institute ve benzerleri) | MagicPaper'da |
|---|---|
| Her yerde mor gradient | Birincil buton gradient'li (`MPButtons.swift:72`), Design law'a da aykırı, karar açık |
| Her blok kart | Klasik detayda kart içinde kart (`06_klasik_detay.png`); Günlük'te "her raf kendi kartında" |
| Renk önceliksiz | Lavanta hem zemin, hem seçili, hem seçilmemiş kart (`01_mod_secimi.png`) |
| Her ekranda aynı süs | "Her çocuk ekranında Ragi" kuralı. Duolingo her başlığa illüstrasyonu "tutarlı ama anlamsızsa zoraki" diye eledi |

Mor marka kararıdır, sorun değildir (#6A47B8). Sorun gradient ve lavantanın yayılması.
Bu blog kaynakları çoğunlukla görüş yazısı, araştırma değil; yön verir, kanıt sayılmaz.

## Kaynaklar

### Önce bunlar

| Kaynak | Ne için | Durum |
|---|---|---|
| [Duolingo: core tabs redesign](https://blog.duolingo.com/core-tabs-redesign) | Aynı sorun: başlık boyu amaca göre kademeli, başlık hep aynı yerde, az yazı stili, kart yerine boşluk | Şubat 2026 |
| [HIG: Modality](https://developer.apple.com/design/human-interface-guidelines/modality) | Modal ne zaman, nasıl kapanır, üst üste açılmaz | Birincil |
| [HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) | Çubuk gezinme içindir, görünür kalır, durum korunur | Birincil |
| [HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) | Kapat / Bitti / Geri ayrımı, tek sheet | Birincil |
| [Dimillian/IceCubesApp](https://github.com/Dimillian/IceCubesApp) | App Store'da SwiftUI uygulaması; `Router.swift`'te tek yerden `RouterDestination` + `SheetDestination` | 7.1k★, ekim 2026, **AGPL: kod kopyalanmaz, yalnızca fikir** |

### GitHub: gerçek uygulamalar ve desenler

| Depo | Bakılacak yer | Durum |
|---|---|---|
| [Dimillian/AppRouter](https://github.com/Dimillian/AppRouter) | Sekme + push + sheet için küçük yönlendirici | 472★, ağustos 2025, MIT |
| [Dimillian/Skills](https://github.com/Dimillian/Skills) | `swiftui-ui-patterns`, `swiftui-liquid-glass`, `swiftui-view-refactor` | 4k★, mart 2026, MIT |
| [bitwarden/ios](https://github.com/bitwarden/ios) | `Docs/Architecture.md`: gezinme ve testin yazılı kuralları | 729★, güncel, GPL-3.0 |
| [kickstarter/ios-oss](https://github.com/kickstarter/ios-oss) | Büyük uygulamada bileşen disiplini | 8.7k★, güncel, Apache-2.0 |
| [wikimedia/wikipedia-ios](https://github.com/wikimedia/wikipedia-ios) | Okuma odaklı uygulama, tema ve metin ölçekleme | 3.5k★, güncel, MIT |
| [mozilla-mobile/firefox-ios](https://github.com/mozilla-mobile/firefox-ios) | Tema altyapısı | 13k★, güncel, MPL-2.0 |
| [pointfreeco/swift-navigation](https://github.com/pointfreeco/swift-navigation) | Durumdan modelleme ile gezinme | 2.3k★, eylül 2026, MIT |
| [SwiftfulThinking/SwiftfulRouting](https://github.com/SwiftfulThinking/SwiftfulRouting) | Hazır yönlendirici | 997★, temmuz 2026, MIT |
| [apple/sample-backyard-birds](https://github.com/apple/sample-backyard-birds), [sample-food-truck](https://github.com/apple/sample-food-truck) | Apple'ın örnekleri | 2023, yeni tasarım dilinden önce |
| [dkhamsing/open-source-ios-apps](https://github.com/dkhamsing/open-source-ios-apps) | App Store'daki açık kaynak uygulama listesi | 53k★, güncel, CC0 |

Yazılı tasarım sistemleri: [Skyscanner/backpack-ios](https://github.com/Skyscanner/backpack-ios)
(Apache-2.0), [Orange-OpenSource/ouds-ios](https://github.com/Orange-OpenSource/ouds-ios) (MIT).

**Bulunamadı:** App Store'da olup SwiftUI ile yazılmış, güncel, açık kaynak bir çocuk
kitabı uygulaması. [LLK/scratchjr](https://github.com/LLK/scratchjr) çocuk uygulaması
ama arşivlenmiş ve JavaScript. Çocuk tarafında ölçüt kod değil, yayımlanmış araştırma.

### Erişilebilirlik ve görsel regresyon

| Araç | Ne yapar | Durum |
|---|---|---|
| [`performAccessibilityAudit`](https://developer.apple.com/videos/play/wwdc2023/10035/) | XCUITest içinde otomatik denetim; Dynamic Type'ta [yanlış alarm bildirimi var](https://developer.apple.com/forums/thread/758261) | Xcode 15+, bağımlılık yok |
| [cvs-health/ios-swiftui-accessibility-techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques) | SwiftUI'de iyi / kötü örnekler | 388★, güncel, Apache-2.0 |
| [cashapp/AccessibilitySnapshot](https://github.com/cashapp/AccessibilitySnapshot) | VoiceOver'ın okuyacağını görüntüye yazar | 752★, güncel, Apache-2.0 |
| [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | Ekran görüntüsü regresyon testi | 4.4k★, güncel, MIT |
| [getsentry/SnapshotPreviews](https://github.com/getsentry/SnapshotPreviews) | `#Preview`'lardan otomatik görüntü | 632★, ekim 2026, MIT |

### Çocuk uygulaması

- [NN/g: fiziksel gelişime göre tasarım](https://www.nngroup.com/articles/children-ux-physical-development/)
  (2018): küçük çocuk için en az 2×2 cm hedef, kesin sürükleme zor, daha az gezinme.
  Karşılaştırma için yaklaşık hesap: `tapMin` 48 pt ≈ 8 mm, 2 cm ≈ 120 pt. Tüm düğmeler
  için değil, 3-4 yaş bandının ana eylemleri için ölçüt.
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/):
  1.3 Kids Category (dış bağlantı ve satın alma ebeveyn kapısının arkasında) ve 5.1.4
  (çocuk uygulamasında üçüncü taraf analitik ve reklam olmamalı). Kids Category'ye girmeden
  önce Firebase kullanımı bu metne göre kontrol edilmeli; bu araştırmada bakılmadı.
- [Rebel Girls ekran dökümü](https://screensdesign.com/showcase/rebel-girls): tematik
  raflar, bedtime modu, matematik kapısı. Üçüncü taraf inceleme.
- [Duolingo: shape language](https://blog.duolingo.com/shape-language-duolingos-art-style/):
  maskot ve illüstrasyon tutarlılığı için.
- **Bulunamadı:** Epic, Lingokids, Moshi, Khan Academy Kids için güvenilir tasarım vaka
  yazısı. Bu uygulamaları cihazda açıp ekran akışı çıkarmak gerekiyor.

### Ekran referansı (ücretli olabilir)

[Mobbin](https://mobbin.com/pricing.md) (akışa göre göz atma) ve
[Refero](https://refero.design/pricing). Üçüncü taraf fiyat bilgileri birbirini tutmuyor;
resmî sayfadan bakılmalı.

## Öneri: tek bir gezinme sözleşmesi

**Bu yeni bir tasarım değil, teslimin kendisi.** `design-handoff/docs/SCREENS.md` şu
ekranların hepsini `push` diye tanımlıyor: Kahraman oluşturucu, Masal ailem, Yeni
kelimelerim, Seri masal, Kendi sesin, Aile üyeleri, Masal kitabı, Aileyle paylaş.
`DESIGN_SYSTEM.md` da sekmeler arasında durumun korunmasını istiyor. Uygulama bu noktada
kendi tasarımından sapmış. Aynı belge çocuk dokunma alanını 56 pt diyor, Design law 48;
hangisinin geçerli olduğu karar ister (öneri: çocuk alanında 56, NN/g bulgusuyla da uyumlu).

Design law'a eklenecek taslak. Yeni bir kütüphane gerekmiyor; mevcut `MPAppState`
yönlendirme için yeterli, IceCubes'taki gibi tek yerden enum ile sürer.

| Ne açılıyor | Nasıl | Alt çubuk | Çıkış |
|---|---|---|---|
| Sekme kökü | Tek başlık bileşeni, başlık aynı yerde | görünür | yok |
| Bir seviye derin (detay, liste, Yeni kelimelerim, Masal ailem, Seri, ebeveyn alt sayfaları) | **Push** | görünür | Geri + kenardan kaydırma |
| Kısa, kendi içinde iş (seçim, eylemler, ayar) | Sistem sheet, `mpSheet` | kapalı | aşağı çekme + Kapat |
| Çok adımlı ya da sürükleyici (okuyucu, masal yazma, uyku, ilk açılış, kapı, paywall) | `fullScreenCover` | kapalı | X |

"Geri" yalnızca push'ta, "X" yalnızca modalda.

## Önerilen sıra

1. **Sekme başlığı birliği** (küçük, en görünür): Kitaplık ve Köşem'in kopya `titleBar`'ı
   ortak bileşene, Ana sayfa ve Günlük aynı başlık yerini paylaşır, zemin tekleşir.
   Kararlar: Ana sayfa selamı ve Günlük vitrini istisna mı kalır?
2. **Ebeveyn alt sayfaları push'a** (`ParentRouteView`): dört sayfa, en belirgin
   "Geri ama aşağıdan" çelişkisi.
3. **Çocuk alt sayfaları push'a:** Yeni kelimelerim, Masal ailem, Seri. Her sekmeye
   `NavigationStack`, sekme yeniden dokunma her sekmede çalışır.
4. **Sheet tekleşir:** `MPSheet` ile sistem sheet'i arasında karar, üst üste modallar çözülür.
5. **Görsel sadeleşme:** buton gradient'i (açık karar), kart içinde kart, lavantanın rolü.
6. **Korkuluk:** `performAccessibilityAudit` ve ekran görüntüsü testi; 7. adımdaki VoiceOver
   yürüyüşü bunun yerini tutmaz, ayrıca yapılır.

Her adımdan önce simülatörde açık + koyu, en büyük yazı, SE + Pro Max görüntüsü alınır
(Design law). Duolingo'nun yöntemi de eklenebilir: tasarımı ekran görüntüsünün üstüne
bindirip kendi kendine kontrol.
