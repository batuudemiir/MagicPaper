# MagicPaper — Okuyucu (Storybook Reader)

**Durum:** AKTİF · **Dalga:** Grup 2 / 2A · **Sahip:** reader
**Kapsam:** `Screens/StoryReader/**`, `Screens/MPStreak.swift`, `Views/DailyStoriesView.swift`

---

## 1. Okuyucu nedir

Bir PDF görüntüleyici, bir web sayfası, bir karusel ya da bir sohbet ekranı değil.
**Bir çocuk kitabı.** Kapak → sayfa → sayfa → kapanış. Sayfalar çevrilir, kaldığı
yerden açılır, favorilenir.

```
StoryReaderView            kitabın etrafındaki her şey: ortam, yaşam döngüsü,
                           erişilebilirlik, okuma bütçesi, seri
 ├─ ReaderPaper            kesintisiz kâğıt zemin
 ├─ StoryReaderContainer   UIKit sayfa denetleyicisi (kıvrım jesti)
 │   └─ StoryLeafView      yaprak: kapak | sayfa | kapanış
 │       ├─ StoryCover
 │       ├─ StoryPageView
 │       └─ StoryEndingLeaf
 ├─ ReaderChrome           kapat / favori / sesli okuma / ayarlar
 └─ ReaderTimeUpLeaf       günlük bütçe bitti

StoryReaderModel           bütün sayfa mantığı, SwiftUI'sız, test edilebilir
MPStreak                   okuma günleri ve okuma süresi defteri
```

Ayrı bir okuma yüzeyi daha var: `DailyStoryReaderView` (Günlük masal). Tek parça
metin, sayfası yok. Aynı tema ve punto kurallarını kullanır.

---

## 2. Okuma oturumu — günü işaretleyen olay

### Sorun

`markReadToday()` `StoryReaderView.open()`'ın **ilk satırıydı**. Yani kaydedilen
olay `StoryOpened`'dı: masalı açıp iki saniye sonra kapatan biri günü işaretliyordu.
Aynı şey `DailyStoriesView`'de `.onAppear` içinde tekrarlanıyordu.

Ürünün kastettiği olay `StoryReadingSessionCompleted`. Streak dokümanının kendi
cümlesi: *"Bir gün sayılmalıdır çünkü aile gerçekten birlikte bir hikâye okudu."*

### Kural

`MPReadingSession` (bkz. `Screens/MPStreak.swift`):

> **bir sayfa ilerleme VEYA 30 saniye ön planda okuma**

İki ölçüt, çünkü tek başına hiçbiri yetmiyor:

| Ölçüt | Neden | Ne zaman gerçekleşir |
|---|---|---|
| `pagesTurned >= 1` | Bir sayfayı çevirmek, o sayfanın okunduğunu söyleyen tek doğal hareket. Kitap biçimli içeriğin kendi kanıtı. | **Anında** — çevirme tamamlandığı an |
| `secondsRead >= 30` | Günlük masalın çevrilecek sayfası yok; ölçülebilecek tek şey zaman. | Oturum kapanışında (çıkış, arka plan, bütçe bitişi) |

### 30 saniye neden

Yanlışlıkla açılan bir masal ilk on saniyede kapanır — kapak görülür, "bu değilmiş"
denir, geri dönülür. Sesli okunan tek bir MagicPaper sayfası ise 30–60 saniye sürer.
30 saniye bu ikisi arasındaki en geniş boşlukta duruyor: her kazara açılışın
üstünde, gerçekten okunan tek bir sayfanın altında.

Eşik bir **hedef değil, gürültü filtresi**. Bir aileye "yeterince okumadınız"
diyen bir sayı değil; "bu bir açılış kazasıydı" diyen bir sayı. Yükseltilmemeli.

### Süre neyin süresi

Ön plandaki süre. `scenePhase != .active` olduğunda sayaç durur
(`pauseReading`/`commitReading`), geri dönüldüğünde kaldığı yerden devam eder.
Parçalar `sessionSeconds`'ta toplanır, yani ekran kilitlenip açılan bir oturum
bölünmez; cebe konmuş bir telefon ise saymaz.

Bu aynı zamanda "okuyucuyu açık unutmak" senaryosunun sınırı: uygulama arka plana
düştüğü anda sayaç durduğu için, unutulmuş bir okuyucu otomatik kilide kadar sayar,
sonrasını saymaz.

### `markOpened` ile karıştırılmamalı

`StoryGenerationManager.markOpened(storyId:)` `open()` içinde **kalıyor**. O ayrı
bir defter: "en son hangi masal açıldı", kaldığı yerden devam edebilmek için.
İki farklı soru, iki farklı defter.

---

## 3. `MPStreak` — okuma sürekliliği defteri

**MPStreak kalır.** Oyunlaştırma değil; okuma sürekliliği ve ailece hikâye ritüeli
(CLAUDE.md İlke 7, `MagicPaper_Streak_System.md` §1). Puan, rozet, liderlik
tablosu, ödül ekonomisi eklenmez. Dil kaydı sıcak kalır.

### Bu turda kapatılanlar

| Bulgu | Durum | Nasıl |
|---|---|---|
| **H3** açmak = okumak | ✅ kapandı | `markReadToday()` artık `private`; tek giriş `markReadingSession(_:)`. Her iki çağrı yeri de yeni anlama taşındı. |
| **H4** sınırsız büyüme | ✅ kapandı | 400 günlük pencere; açılışta ve her yazmada budanıyor. |
| **H5** `objectWillChange` sırası | ✅ kapandı | `addReadingTime` bildirimi artık değişimden **önce** gönderiyor. |
| **H6** gece yarısı | ✅ kapandı | `daySlices(endingAt:seconds:)` oturumu takvim günlerine bölüyor. |
| **H1** sıfırlama `mp_readSeconds`'i bırakıyor | ✅ zaten kapalı | `SettingsView.swift:465` anahtarı içeriyor (parent-ux). |
| **H2** profile bağlı değil | ⛔ yapılmadı | library-memory'nin D4 persistence göçüyle kesişiyor. Bkz. §6. |

### 400 gün neden

`mp_readDays` ve `mp_readSeconds` hiç budanmıyordu. Beş yıl okuyan bir aile
`UserDefaults`'ta ~1800 girişlik iki koleksiyon taşıyacaktı ve `addReadingTime`
her çağrıda sözlüğün tamamını okuyup geri yazdığı için bu maliyet her oturum
kapanışında ödenecekti.

400 gün, çünkü:

- Ekranların hiçbiri bundan uzağa bakmıyor. En uzun pencere `currentStreak`, o da
  kesintiye kadar geriye yürüyor.
- 13 ay, "geçen yıl bugün" türü bir geri dönüşe yer bırakacak kadar geniş.
- Budama bir **kota değil**: pencere, kesintisiz bir seriyi taşıyabilecek uzunlukta
  seçildi. Kimse budama yüzünden serisini kaybetmez
  (`testThePruningWindowDoesNotTruncateALongLiveStreak`).

Karşılaştırma `"yyyy-MM-dd"` dizgileri üzerinde yapılıyor — bu biçimde sözlük
sırası tarih sırasıyla aynı, yani binlerce girişi `Date`'e çevirmeye gerek yok.

### Gece yarısı bölünmesi

Oturumun bittiği an ve süresi bilinir; başlangıcı ikisinden çıkar. Aradaki her gün
sınırında dilim kapanır. 23:50'de başlayıp 00:20'de biten 30 dakikalık bir masal,
dünün defterine 10 dakika, bugünün defterine 20 dakika yazar.

Bu yalnızca doğruluk meselesi değil: **günlük okuma bütçesi** bu deftere bakıyor.
Bölünme olmadan, gece yarısını aşan bir masal ertesi günün payından yarım saat
çalıyordu.

Bölünme toplamı korur — hiçbir saniye kaybolmaz, hiçbiri iki kez sayılmaz
(`testSplittingPreservesTheTotal`).

### Korunan: `.missed` / `.upcoming`

`weekStates` dört durum döndürüyor ve bu ayrım **korunur**. Koddaki gerekçe doğru:
çocuğa henüz gelmemiş dört günü "kaçırdın" diye göstermek, alışkanlık kurmaya
çalışan bir ekranın yapabileceği en ters şey. Test:
`testFutureDaysAreUpcomingNotMissed`.

### Enjekte edilebilirlik

`MPStreak.init(defaults:calendar:now:)` — depo, takvim ve saat verilebilir.
Uygulamada tek örnek `MPStreak.shared`. Bu, gün sınırı ve saat dilimi kurallarının
gerçekten test edilebilmesi için gerekliydi; davranış değişmedi.

---

## 4. Kapak — başlık bandı kararı

**Soru** (`MagicPaper_Illustration_System.md` §5.5/1): `StoryCover` başlığı
illüstrasyonun altına koyuyor. Üretilecek illüstrasyonun `textSafeArea`'sı alt
bant mı olmalı, yoksa düzen "illüstrasyon altta, başlık üstte"ye mi dönmeli?

**Karar: başlık ALTTA kalır. `textSafeArea` = ALT bant.**

`SafeArea(x: 0.06, y: 0.76, width: 0.88, height: 0.20)` — kaynak:
`StoryCover.Cover.textSafeBand`.

### Neden başlık altta kalır

Düzen: illüstrasyon üstte (yaklaşık üst %56) → yay başlık → marka satırı → künye.
Başlık, kitabın tipografisine girişin ilk cümlesi. Resmin üstüne konduğunda kapak
bir **afişe**, resim de başlığın arka planına dönüşür. Aşağıda durduğunda resim
resim olarak, başlık da bir levha yazısı olarak okunur — resimli baskılarda plaka
altyazısı gibi. `MPArcText`'in yayı da bu okumayı destekliyor.

### Başlık resmin içine girmiyorsa neden bant ayrılıyor

1. **Kırpma.** `artwork` görseli `scaledToFill` + `clipped` ile
   `width × min(width·1.32, height·0.56)` çerçevesine oturtuyor; bu çerçeve cihaza
   göre 3:4 civarında oynuyor. Merkezden kırpma, alt kenara yakın duran bir yüzü ya
   da odak nesnesini kesebilir. Alt bandın boş tutulması, kırpmanın hiçbir cihazda
   bir şeyin başını kesmemesini sağlar.
2. **Bitişiklik.** Kalabalık bir alt kenarın hemen altına oturan yay başlık, resimle
   yarışır.

Yani bant "buraya yazı gelecek" demiyor — **"burası sakin kalsın"** diyor.
Detaysız, yüzsüz, düşük kontrastlı bir zemin. Bu ayrım önemli: illüstrasyon üretimi
tarafında bandın içine metin çizdirmeye çalışmak yanlış olur.

### §5.5'in diğer iki sorusu

2. **`MPArcText` illüstrasyonlu kapakta kalır mı?** Evet. Kart yüzüyle
   (`StoryCoverFace`) aynı tipografik imza; rafta ve okuyucuda aynı kitap.
3. **`StoryCoverFace` illüstrasyona döner mi?** Hayır — illustration-system'in
   kendi cevabına katılıyoruz: kart yüzü tipografik kalır. Raf, aynı görselden beş
   tane değil, beş farklı kitap sırtı gibi okunmalı.

### Kapak V1 = 3:4

`AspectRatio` enum'una **2:3 eklenmedi**. Gerekçe iki katlı: enum sağlayıcı
tarafında exhaustive `switch`lerle tüketiliyor (`FalImageProvider`, reader'a
salt-okuma) ve buradaki çerçeve zaten 3:4'e oturuyor. Kapak V1 `portrait` (3:4)
ile çıkar.

---

## 5. Gelecek uyumluluğu

Okuyucu mimarisi şunları **ileride** taşıyabilmeli; bu turda **hiçbiri
uygulanmadı** ve açıkça istenmedikçe uygulanmamalı:

- **Anlatım (narration).** `MPSpeech` bugün sayfa metnini seslendiriyor ve
  `pageChanged()` üzerinden sayfaya bağlı. Gerçek anlatım (üretilmiş ses, sayfa
  başına zaman damgası) aynı kancaya oturur: yaprak değişimi tek olay.
- **Ortam sesi (ambient).** Yaprak değil masal ömrü boyunca yaşayan bir katman;
  `StoryReaderView`'ın yaşam döngüsü (`open` / `closeDown` / `pauseReading` /
  `resumeReading`) bu katmanın doğal sahibi.
- **Birlikte okuma (read together).** `StoryReaderModel` SwiftUI'sız ve tek gerçek
  durum sahibi; `go(toLeaf:)` ve `syncFromPageController(leafIndex:)` uzaktan
  sürülebilir bir yüzeye zaten en yakın nokta.

Okuma oturumu tanımının bu üçüyle ilişkisi: anlatım açıkken de ölçüt aynı kalır
(sayfa ilerlemesi veya süre). Anlatımın kendisi bir "okuma kanıtı" olarak
eklenirse, `MPReadingSession`'a yeni bir alan gelir — kural tek yerde durduğu için
değişiklik tek yerde olur.

---

## 6. Devir / açık talepler

**library-memory (D4 persistence göçü) için — H2.**
`mp_readDays` ve `mp_readSeconds` **cihaz genelinde**, profile bağlı değil.
Çok çocuklu ailede bir çocuğun okuması diğerinin gününü de işaretliyor; ebeveyn
panelindeki süre çocuklar arasında paylaşılıyor. `ProfileManager` diğer profil
verilerini `mp_avatarColor_<UUID>` / `read_history_<UUID>` deseniyle bağlıyor;
streak bu desene uymuyor.

Bu tur **kasten yapılmadı**: profil kapsamına alma D4 ile aynı göç kararını
gerektiriyor ve `ProfileManager` reader'ın alanı değil.

`MPStreak` artık `init(defaults:calendar:now:)` ile enjekte edilebilir olduğu için
profil başına örnek ya da profil öneki veren bir depo, göç sırasında ek refactor
gerektirmez.

**parent-ux (2B) için.** `ParentPanelView` ve `HomeView` `MPStreak`'in okuduğu
değerleri gösteriyor; API yüzeyi değişmedi (`currentStreak`, `readToday`,
`thisWeek`, `weekStates`, `minutesToday`, `minutesThisWeek`). Yalnızca
`markReadToday()` `private` oldu — dışarıdan çağrılmıyordu.

---

## 7. Testler

`MagicPaperTests/ReadingStreakTests.swift` — sabit saat dilimi (Europe/Istanbul),
enjekte edilmiş saat, izole `UserDefaults` suite'i.

| Alan | Test |
|---|---|
| H3 | `testOpeningAndLeavingImmediatelyDoesNotMarkTheDay`, `testOneTurnedPageMarksTheDay`, `testDurationAloneMustReachTheThreshold`, `testThresholdSitsBetweenAMisTapAndASinglePage`, `testMarkingTwiceInOneDayIsIdempotent`, `testARejectedSessionWritesNothing`, `testStreakCountsConsecutiveDaysAndResetsOnAGap` |
| H6 | `testASessionCrossingMidnightIsSplitAcrossBothDays`, `testASessionWithinOneDayStaysWhole`, `testSplittingPreservesTheTotal`, `testTodayBudgetOnlySeesTodaysSlice` |
| H5 | `testObjectWillChangeFiresBeforeTheValueChanges` |
| H4 | `testOldEntriesArePrunedOnLoad`, `testThePruningWindowDoesNotTruncateALongLiveStreak`, `testTheLedgerStaysBounded` |
| Korunan | `testFutureDaysAreUpcomingNotMissed`, `testWeeklyMinutesSumTheWeek` |

Mevcut okuyucu testleri (`ReaderProgressTests`, `StoryReaderModelTests`,
`ContinueReadingTests`, `ReaderStoryMappingTests`) değişmedi.
