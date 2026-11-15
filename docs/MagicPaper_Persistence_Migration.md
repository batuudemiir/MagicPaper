# MagicPaper — D4: Kalıcılık Göçü

**Tarih:** 2026-09-22 · **Rol:** library-memory · **Dalga:** Grup 2 / 2A
**Önkoşul:** K1 kapandı (`docs/MagicPaper_Wave0_Stabilization.md` §1) — saklanan hikâyeler
üretilmiş metni tutuyor, seed'den yeniden üretilmiyor. Göç **taşıyor**, yeniden üretmiyor.

---

## 1. Bu turda ne yapıldı

| Adım | Durum |
|---|---|
| `migrateOldStoriesIfNeeded()` yedeksiz silme kolu | ✅ **kapatıldı** — artık hiçbir şey silmiyor |
| `stories.undecodable.*` sınırsız yedekler | ✅ **sınırlandı** (3) |
| `FileStores` üç sessizliği | ✅ kapatıldı |
| `FileProtection` | ✅ `.completeUnlessOpen`, üç yazma noktasında |
| Göç: yaz → doğrula → işaretle | ✅ uygulandı ve koşuyor |
| Göç: beklet (gölge kopya) | ✅ uygulandı |
| Göç: sil (emeklilik) | ✅ **yazıldı**, kapılı — §6 |
| E1 (15 Kasım 2026): kesişim, disk doğruluk kaynağı | ✅ kapı açık, emeklilik kesişimden 14 gün sonra; §4 ve §6 |
| Test | ✅ `MagicPaperTests/LibraryMigrationTests.swift` |
| StoryMemory / seri alanları | tasarım yazıldı (§7), **kod eklenmedi** |

---

## 2. Kapatılan kol — neden birinci işti

`SGM:939`:

```swift
if oldSize > 4_000_000 {
    UserDefaults.standard.removeObject(forKey: "stories")   // yedek yok
    stories = []
}
```

Dört megabaytı geçen her kütüphane, bir açılışta, kopyası alınmadan siliniyordu.
Gerekçe "muhtemelen görsel gömülü eski format" idi; bu doğru bile olsa silinen şey bir
çocuğun bütün rafı. Ve tam olarak bu göçün okuyacağı veri.

Yeni davranış (`LibraryMigration.quarantineOversizedLegacyBlob`): yığın
`Documents/MPLibrary/Quarantine/` altına **kopyalanır**, kopya bayt bayt geri okunur,
**anahtar yerinde bırakılır**. Anahtar ancak §6'daki emeklilik yolundan kalkabilir.
Aşırı büyük bir `UserDefaults` girdisi bir performans sorunudur; okunmadan silinmesi bir
veri kaybı sorunudur, ikisi takas edilmez.

İkinci kusur aynı kalıbın aynası: `stories.undecodable.*` yedekleri vardı ama ikinci
yarısı — okuma, temizleme, bildirme — hiç yazılmamıştı. Sınırsız büyüyen yedekler, hem de
boyutu zaten sorun olan deponun içinde. `StoryGenerationManager.pruneUndecodableBackups`
en yeni üçünü tutuyor; zaman damgası **sayı olarak** karşılaştırılıyor (dize sıralamasında
`"999999999" > "1000000000"`).

---

## 3. FileStores — üç sessizlik

`MagicPaper/StoryEngineBridge/FileStores.swift`:

| Önce | Sonra |
|---|---|
| `save`: `guard let url … else { return }` — Documents erişilemezse **sessizce başarılı** | `throw Failure.documentsUnavailable`; tüm çağıranlar zaten `throws` |
| `load`: iki kat `try?` — var ama bozuk dosya `nil` döner | `nil` **yalnızca dosya yoksa**; bozuksa `throw` |
| `loadAll`: çözümlenemeyen dosya sessizce atlanır | `loadAllReportingFailures()` atladıklarını adlandırır; `lastLoadFailures` saklanır ve loglanır |

`load`'un `nil`'i en çok `FileCharacterStore`'da önemliydi: eksik profil yeni bir
`CharacterVersion` ile cevaplanıyor ve `CharacterVersionID` taze bir UUID. Tek bir
okunamayan dosya çocuğun görsel kimliğini kalıcı olarak kaydırırdı (Wave0 §5, madde 12).

`loadAll` hâlâ `throw` etmiyor — bir bozuk masal çocuğun bütün rafını gizlememeli. Ama
artık **atladığını söylüyor**, çünkü göç bir okuyucu değil: göremediği bir dosyanın
üzerine "başarılı" yazardı.

**FileProtection.** Üç yazma noktası da çıplak `write(to:)` idi, yani
`.completeUntilFirstUserAuthentication`: cihaz açıldıktan sonra kilitliyken de okunabilir.
Bu dosyalarda adıyla bir çocuk, masal metni ve görünüşünden kurulmuş prompt'lar var
(İlke 10). Seçilen sınıf `.completeUnlessOpen`:

- `.complete` olmaz — ekran kilitlendikten sonra da süren üretim ve görsel indirme
  yazmaları başarısız olurdu;
- `.completeUnlessOpen` açık dosyanın kilit boyunca kullanılmasına izin verir, kilitliyken
  soğuk açılışı reddeder. Buradaki iş için doğru olan özellik bu.

Koruma bayrağı **yazmadan sonra** atanıyor: atomik değiştirme yeni bir inode kurar ve
öncekinin korumasını düşürür.

---

## 4. Göç — zorunlu sıra

```
yaz → doğrula → işaretle → beklet → sil
```

`MagicPaper/Services/Persistence/LibraryMigration.swift`.

**1. yaz** — `UserDefaults["stories"]` → `Documents/MPLibrary/Stories/<uuid>.json`,
kayıt başına bir dosya. Favoriler ve onaylar `Flags/favorites.json`, `Flags/approvals.json`.
Bu adım **işaretlenmiyor**: id ile anahtarlı, dolayısıyla tekrarlanabilir. Yarıda kesilen
bir koşu bir sonraki açılışta basitçe tekrar edilir.

**2. doğrula** — diskten geri okunur ve **kaynakla** karşılaştırılır, yazdığımızı
sandığımız şeyle değil. Karşılaştırma id üzerinden değil **bayt** üzerinden:
`Story: Equatable` yalnızca id'ye bakıyor (liste diff'i için, kasıtlı), yani sayfalarını
kaybetmiş bir masal yine eşit çıkardı.

**3. işaretle** — `UserDefaults["mp_libraryMigration"]`'a tek bir küçük kayıt:
faz, `verifiedAt`, son hata, karantinaya alınan dosyalar. `synchronize()` ile hemen
indiriliyor — bütün güvenlik savı bu işaretin geri okunmadan önce diskte olmasına dayanıyor.
İşaret **kasıtlı olarak** `UserDefaults`'ta kalıyor: göç edilen şeyin içinde yaşayan bir
göç işareti, tam ihtiyaç duyulduğu anda okunamaz olurdu.

**4. beklet** — 14 gün. Bu pencerede **eski kopya canlı olan**, diskteki gölge.
`reconcile()` her açılışta ve her `saveStories()` sonrasında diski eskiye eşitler —
**silmeler dahil**. Yalnızca eklemeleri kopyalamak, "tüm veriyi sil" diyen bir ebeveynin
çocuğunun masallarını diskte bırakırdı.

**5. sil** — `retireLegacyIfDue()`. **Bu turda yazıldı** (§6'daki kapıyla birlikte),
sonraki tura bırakılmadı. E1'den beri yalnızca `diskAuthoritative`'den, `cutoverAt`'ten
14 gün sonra ve disk hatasız okunuyorsa koşuyor; kesişimin kendisi son bir eşitleme ve
bayt bayt doğrulamayla işaretleniyor (§6). Hiçbir şey yalnızca bir işaretin gücüyle
silinmiyor.

### Faz makinesi

| Faz | Anlam | Okuma kaynağı | Yazma |
|---|---|---|---|
| `pending` | Hiçbir şey doğrulanmadı | UserDefaults | UserDefaults |
| `verified` | Her kayıt kopyalandı ve sağlam geri okundu | UserDefaults (disk gölge) | UserDefaults, sonra gölge eşitlenir |
| `diskAuthoritative` | Kesişim yapıldı (E1); eski yığın dondurulmuş yedek | Disk | Yalnızca disk, yalnızca değişen dosya |
| `legacyRetired` | Eski anahtarlar gitti | Disk | Yalnızca disk |

Sıra: `pending → verified → diskAuthoritative → legacyRetired`, her geçiş ayrı bir
açılışta. `State.cutoverAt` kesişim anıdır; emeklilik oradan sayılır.

İşaretin çözümü (E1) hoşgörülü: eksik alan varsayılanını alır (E1 öncesi kayıtta
`cutoverAt` yok), bu sürümün tanımadığı bir evre `diskAuthoritative` okunur, hiç
çözülemeyen bir işaret de `diskAuthoritative` (ama `cutoverAt` yok, yani emeklilik hiç
olmaz) okunur. Hiçbiri `pending`'e düşmez: kesişimden sonra `pending` donmuş yığını
canlı dosyaların üstüne kopyalayan tek evredir.

`run()` her açılışta çağrılabilir, idempotent. Hiçbir hata `run()`'dan dışarı çıkmıyor:
başarısız bir göç eski depoyu bulduğu gibi bırakıyor, nedeni kaydediyor ve uygulama eski
yolda çalışmaya devam ediyor. Yapmaması gereken tek şey bir kütüphaneyi **yarı taşımak**.

### Tarih kodlaması

Dosya deposu ISO-8601 **kullanmıyor**, Foundation varsayılanını kullanıyor. Eski yığın düz
bir `JSONEncoder` ile yazılmıştı, yani tarihleri tam hassasiyetli referans-tarihi
double'ları; ISO-8601 saniyeye yuvarlar. Kaynağından bir saniye şaşan kopya kopya değildir,
ve ana sayfanın "kaldığın yer" kartını sıralayan alan `lastReadAt`.

---

## 5. Kapsam — ne taşındı, ne taşınmadı

| Anahtar | Karar |
|---|---|
| `stories` | ✅ taşındı |
| `mp_favoriteStoryIDs` | ✅ taşındı (`Flags/favorites.json`, sürümlü) |
| `mp_approvedStoryIDs` | ✅ taşındı (`Flags/approvals.json`, sürümlü) |
| `user_profiles` | ❌ **character-system'in alanı.** Arayüz hazır: `LibraryFileStore` kök enjekte edilebilir ve `FlagList`/kayıt düzeni aynı kalıbı taşıyor. Bu agent taşımadı. |
| `current_profile_id` | UserDefaults'ta **kalır** — tercih, domain kaydı değil |
| onboarding bayrağı, UI tercihleri | UserDefaults'ta **kalır** |
| `mp_readDays`, `mp_readSeconds` | bu turun kapsamı dışında (Streak H2, parent-ux + reader) |

Bayrak listeleri ilk yazıştan itibaren **sürümlü** (`{version, ids}`). Eski biçim ne
olduğunu söyleyecek yeri olmayan çıplak bir `[String]`'di; her iki listenin de sıradaki
ihtiyacı — profil kapsamı (Streak H2) — sürüm olmadan göç edecek bir yer bulamazdı.

### CharacterVersionID tuzağı

Göç **kopyalıyor**, yeniden inşa etmiyor. Hiçbir yerde `CharacterVersion`,
`CharacterVersionID` veya `CharacterAsset` yeniden kurulmuyor; `Story` kayıtları
bayt bayt taşınıyor. `Story` bugün karakter sürümüne referans taşımıyor, dolayısıyla
bu turda kaydırılacak görsel kimlik yok — ama kalıp şimdiden doğru kurulmuş olsun diye
doğrulama bayt karşılaştırması yapıyor.

---

## 6. Kesişim ve emeklilik (E1, 15 Kasım 2026)

`LibraryMigration.readPathIsAuthoritative = true` (testi:
`testTheShippedBuildCutsOverToDisk`).

### Kapının önkoşulları, ikisi de kapandı

1. **"Tüm verileri sil"** artık `LocalDataEraser` üzerinden `LibraryPersistence.eraseAll()`
   çağırıyor; dosya deposu (kenara konan bozuk dosyalar dahil) siliniyor. Göç işareti
   kalıyor: kesişmiş bir kütüphane silindikten sonra da diske yazıyor.
2. **Favoriler** `LibraryShelf` üstünden yazılıyor: kesişimden önce bugünkü gibi
   `UserDefaults["mp_favoriteStoryIDs"]`, sonra `Flags/favorites.json`. **Onaylar**:
   masal onayı 14 Kasım 2026'da kalktı, `mp_approvedStoryIDs`'e yazan kod yok (yalnızca
   `LocalDataEraser` siliyor). Liste olduğu gibi taşınıyor, okunmuyor.

### Kesişim

`verified` evresinde, kapı açıkken, açılışta: son bir eşitleme (`sync`) ve kaynağa karşı
bayt bayt `verify`. İkisi de geçerse `diskAuthoritative` ve `cutoverAt` işaretlenir.
Geçmezse (örneğin diskte adı masal kimliği olmayan, çözülemeyen bir dosya) neden
`lastFailure`'a yazılır ve eski yol aynen sürer. Kesişim doğrulamayla aynı açılışta
olmaz.

### Kesişimden sonra

- **Okuma** diskten: `readAllStories()`, `createdAt` azalan, eşitlikte kimlik
  (`LibraryFileStore.shelfOrder`).
- **Yazma** yalnızca diske: değişen masal yazılır (SHA-256 özeti eşleşirse yazılmaz,
  okunan dosyaların özeti yüklemede alınır), raftan çıkan masalın dosyası silinir.
  Silme "rafta bilinen ama artık olmayan" kimliklerdir; "diskte olup rafta olmayan"
  değil, çünkü o küme bozuk ve okunamayan dosyaları da içerir.
- **Eski yığın** bir daha yazılmaz; dondurulmuş yedek. `sync` kesişimden sonra çalışmayı
  reddeder (`testTheLegacySyncNeverRunsAfterCutover`).
- **Bozuk dosya** (okunuyor ama çözülmüyor): rafta görünmez, `DamagedStories/`
  klasörüne taşınır (üstüne yazılmaz, silinmez, budanmaz), adı `quarantinedFiles`'a
  eklenir. Taşınamazsa yerinde kalır ve o oturumda ne yazılır ne silinir. Log'a yalnızca
  dosya adı yazılır.
- **Okunamayan dosya** (kilitli cihaz: `.completeUnlessOpen` kilitliyken soğuk okumayı
  reddeder, arka plan yenilemesi uygulamayı o sırada açabilir): bozuk sayılmaz, yerinde
  kalır, dokunulmaz; cihaz açılınca (`protectedDataDidBecomeAvailable`) rafa eklenir.
- Raf bozuk ya da okunamayan dosya yüzünden boşsa **örnek masal konmaz**.
- **Depo kurulamazsa** (Documents yok): eski yedek varsa raf ondan gösterilir, o oturumda
  hiçbir şey kaydedilmez, evre değişmez.
- `StoryGenerationManager`'ın dış API'si aynı; karar `LibraryShelf`'te
  (`Services/Persistence/LibraryShelf.swift`).

### Emeklilik

`cutoverAt`'ten `graceInterval` (14 gün) sonra, açılışta, disk hatasız okunuyorsa: her
masal dosyası çözülüyor, `DamagedStories/` boş (donmuş yedek o masalın tek sağlam kopyası
olabilir) ve iki bayrak listesi okunuyor. Bayat yığına karşı `verify` **yapılmaz**:
kesişimden sonra silinen bir masal o doğrulamayı sonsuza dek düşürürdü. `verified`
evresinden emeklilik yok.

### Bilinen sınırlar

- Favori listesi kesişimden sonra okunamazsa (bozuk ya da kilitli) o oturumda donmuş
  eski liste gösterilir ve dosyanın üstüne yazılmaz; okunur hâle gelince ilk dokunuşta
  diskteki liste alınır.
- "Tüm verileri sil" `MPFavorites`'in bellekteki listesini boşaltmıyor (E1 öncesinden
  kalan durum); silmeden sonraki ilk favori dokunuşu eski kimlikleri de yazar. Masal
  verisi değil, yalnızca kimlik listesi.

---

## 7. StoryMemory ve seri temeli — tasarım, kod değil

Bu tur kalıcılık turu. `Story`'ye `seriesID`/`sequenceNumber` **eklenmedi**. Aşağısı
sonraki turun sözleşmesi.

### Neden şimdi eklenmedi

Bir alan eklemek ucuz, yanlış alan eklemek pahalı: `Story` saklanmış bir kayıt, ve
`stories` yığını hâlâ tek parça. Şema bu turda oynarken göç doğrulaması kendi kendini
kovalardı. Göç yerleştikten sonra kayıt başına bir dosya, alan eklemeyi önemsizleştiriyor.

### Hedef domain

```
StorySeries        id, title, childProfileID, createdAt
  └─ Story         + seriesID: StorySeriesID?
                   + sequenceNumber: Int?          (1'den başlar, seri içinde tekil)
                   + previousStoryID: UUID?        (türetilebilir; saklanır çünkü
                                                    bir masal serisinden çıkarılabilir)
StoryMemory        seri kapsamında, hikâyeler arası süreklilik defteri
  ├─ characters         çocuk + yoldaşlar; CharacterID'ye bağlanır, adı tekrar yazmaz
  ├─ worlds             ziyaret edilmiş setting'ler (`worldID` bugün `StoryOrigin`'de var)
  ├─ objects            bulunan/verilen nesneler (`discoveryID`)
  ├─ events             olan bitenin özeti, sayfa metni değil
  ├─ relationships      kim kimi tanıyor, nasıl
  └─ unresolvedThreads  açık kalan sorular — 2. hikâyenin yem kutusu
```

### Üç kural

1. **StoryMemory türetilmiş, kanonik değil.** Kanonik olan `Story.pages[].text` ve
   `StoryOrigin`. Hafıza yeniden kurulabilir olmalı; olmazsa ikinci bir doğruluk kaynağı
   yaratmış oluruz — bu projede defalarca canımızı yakan şey.
2. **Çocuğun kimliği hafızada yaşamaz.** Child Profile + Character Bible kanonik
   (İlke 5). `StoryMemory.characters` `CharacterID` tutar, görünüş tutmaz. Story 1 → 2 → 3
   boyunca çocuğun aynı karakter kalmasını sağlayan şey hafıza değil, `CharacterVersionID`
   sürekliliği — ve o da **kopyalanır, yeniden inşa edilmez**.
3. **Seri isteğe bağlı.** `seriesID: nil` tek başına duran bir masal. Mevcut bütün
   kayıtlar böyle çözümlenir; geriye dönük göç gerekmez.

### Açılış sırası

1. `StorySeries` + `Story.seriesID`/`sequenceNumber` (saf ekleme, `nil` varsayılan)
2. `StoryMemory` **türetici** — saklanan hikâyelerden okuyup hafıza kurar, hiçbir şey yazmaz
3. Hafızayı `OfflineStoryIntent`'e besle — burası "aynı çocuk" vaadinin gerçekten
   karşılandığı yer
4. Kalıcılık: `Documents/MPLibrary/Series/<uuid>.json`, aynı yaz-doğrula-işaretle kalıbı

### FAZ 13'te ne yapıldı (6 Ekim 2026)

Yukarıdaki tasarımdan farklı olarak, ürün kararlarına göre:

- **Alanlar `StoryOrigin`'de**, `Story`'de değil: `seriesID: String?`, `seriesEpisode: Int?` (2…5). İlk masal serinin üyesidir ama bu alanları taşımaz; seri onu `firstStoryID` ile tanır. Eski kayıtlar `nil` çözer (`testAStoryWrittenBeforeFaz13StillOpens`).
- **Depo:** `Documents/StoryEngine/Series/<çocukUUID>.json` (`StorySeriesStore`), çocuk başına bir dosya, `FamilyCharacterStore` kalıbı: atomik yazma, `.completeUnlessOpen`, kayıplı okuma. Bölüm metni bu dosyada durur (asıl kaynak); açılan bölüm kitaplığa `Story` olarak kopyalanır.
- **`StoryMemory` türetici yok.** Seri, ilk masalın kökeninden bir `SeriesAnchor` kurar (ortam, yol arkadaşı, hatıra); bölümler arası tutarlılık plandan gelir.
- **`unresolvedThreads` yok, olmayacak:** her bölüm kapalı ve sakin biter (karar 6 Ekim 2026, `CalmEnding`).
- Profil silme ve "Tüm verileri sil" seri dosyalarını da siler.

### FAZ 14: okuma kaydı ve olay kuyruğu (6 Ekim 2026)

- **`Documents/StoryEngine/Usage/<çocukUUID>.json`** (`StoryUsageStore`): masal başına kaç kez bitirildiği, kaç oturum, en ileri sayfa, son oturum bitti mi. Cihazdan çıkmaz; motor bundan öğrenir (`UsageLearner`, son 30 masal). Hiç kullanılmayan `read_history_<UUID>` anahtarının yerini aldı; anahtar artık yazılmıyor, profil silme eski cihazlarda hâlâ temizliyor.
- **`Documents/StoryEngine/ReadingEvents/queue.json`** (`ReadingEventQueue`): gönderilmeyi bekleyen anonim `ReadingEvent`'ler, en fazla 500. Her kaydın yanında yerel profil kimliği durur, yalnızca profil silinince o çocuğun olaylarını bulmak için; gönderilecek yük (`outbound()`) yalnızca olaylardır. Gönderim FAZ 16'da.
- **`mp_shareUsageData`** (UserDefaults, varsayılan açık): kapatmak kuyruğu siler ve yeni olay yazılmaz. Yerel kayıt anahtardan bağımsızdır.
- Profil silme ve "Tüm verileri sil" ikisini de siler.

---

## 8. Dosya düzeni

```
Documents/MPLibrary/
  Stories/<uuid>.json      kayıt başına bir masal
  Flags/favorites.json     {version, ids}
  Flags/approvals.json     {version, ids}
  Quarantine/              kurtarılan yığınlar, en yeni 3 tutulur
  DamagedStories/          çözülemeyen masal dosyaları (E1), budanmaz
```

`Documents/StoryEngine/` (motorun `FileStores`'u) ayrı kalıyor ve ayrı kalmalı: oradaki
`StoryEngine.Story` motorun kaydı, burdaki `Story` çocuğun kütüphanesinin kendisi. İkisi
arasındaki köprü henüz canlı değil (Wave0 §4); bir göçün içinde icat edilecek en son şey o.

---

## 9. Test

`MagicPaper/MagicPaperTests/LibraryMigrationTests.swift` — boş durum, dolu durum,
yarıda kesilen göç, bozuk kaynak, bozuk hedef dosyası, idempotanlık, gölge eşitleme,
silme yayılımı, emeklilik kapısı, yedek sınırı, tam silme.

`MagicPaper/MagicPaperTests/LibraryCutoverTests.swift` (E1): kesişim, kapı kapalıyken
kesişim yok, okunamayan diskte kesişim ertelenir, işaretin eski ve bilinmeyen
biçimleri, diskten okuma sırası, kesişimden sonra eski yığının değişmemesi, tek masal
tek dosya, silme, `StoryGenerationManager` üstünden sayfa çevirme, bozuk dosyanın
kenara konması ve kaybolmaması, kilitli dosya, emeklilik, depo yokken açılış, favoriler.
