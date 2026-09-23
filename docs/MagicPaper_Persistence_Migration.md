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
sonraki tura bırakılmadı. Emeklilikten hemen önce doğrulama bir kez daha koşuyor: hiçbir
şey yalnızca bir işaretin gücüyle silinmiyor.

### Faz makinesi

| Faz | Anlam | Okuma kaynağı |
|---|---|---|
| `pending` | Hiçbir şey doğrulanmadı | UserDefaults |
| `verified` | Her kayıt kopyalandı ve sağlam geri okundu | UserDefaults (disk gölge) |
| `legacyRetired` | Eski anahtarlar gitti | Disk |

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

## 6. ⚠️ Emeklilik neden kapılı — açık dikişler

`LibraryMigration.readPathIsAuthoritative = false`.

Okuma yolu bu turda **diske taşınmadı**, dolayısıyla eski anahtarlar hâlâ canlı kopya ve
onları silmek kütüphaneyi göç ettirmek değil silmek olurdu. İki dikiş kapanmadan
`true` olamaz ve **ikisi de bu agent'ın dosyası değil**:

1. **`SettingsView.clearAll()` (`Views/SettingsView.swift:459`)** — parent-ux'in alanı.
   "Tüm veriyi sil" bugün yalnızca `UserDefaults` anahtarlarını kaldırıyor. Okuma yolu
   diske geçtiğinde bu akışın `LibraryPersistence.eraseAll()` çağırması **zorunlu**,
   aksi hâlde silindiği söylenen masallar diskte kalır. Tek satır; API hazır.
   *Bu tur için hafifletme:* `reconcile()` her açılışta diski eskiye eşitlediği için
   silme bir sonraki açılışta gölgeye de geçiyor — test edilmiş
   (`testErasingTheLegacyStoreErasesTheShadowOnTheNextRun`).
2. **Favori / onay yazıcıları** — `Screens/MPStoryExtras.swift` (`MPFavorites`) ve
   `Screens/MPSettingsStore.swift` (`approvedStoryIDs`) doğrudan `UserDefaults`'a yazıyor.
   Bu turda **dokunulmadı** (paylaşılan dosya kuralı; parent-ux 2B'de bu ekranların
   sahibi). Gölge kopya açılışta ve her `saveStories()` sonrasında yakınsıyor; okuma yolu
   taşınmadan önce bu iki yazıcının depoya yönlendirilmesi gerekiyor.

Kapı bir zevk meselesi değil, eksik bir önkoşul. Testi var:
`testTheShippedBuildKeepsTheLegacyStore`.

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

---

## 8. Dosya düzeni

```
Documents/MPLibrary/
  Stories/<uuid>.json      kayıt başına bir masal
  Flags/favorites.json     {version, ids}
  Flags/approvals.json     {version, ids}
  Quarantine/              kurtarılan yığınlar, en yeni 3 tutulur
```

`Documents/StoryEngine/` (motorun `FileStores`'u) ayrı kalıyor ve ayrı kalmalı: oradaki
`StoryEngine.Story` motorun kaydı, burdaki `Story` çocuğun kütüphanesinin kendisi. İkisi
arasındaki köprü henüz canlı değil (Wave0 §4); bir göçün içinde icat edilecek en son şey o.

---

## 9. Test

`MagicPaper/MagicPaperTests/LibraryMigrationTests.swift` — boş durum, dolu durum,
yarıda kesilen göç, bozuk kaynak, bozuk hedef dosyası, idempotanlık, gölge eşitleme,
silme yayılımı, emeklilik kapısı, yedek sınırı, tam silme.
