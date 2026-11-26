# Beş arkadaş K0–K1 ayrıntılı uygulama planı

**Tarih:** 22 Kasım 2026 · **Durum:** yalnız plan; kodlama başlamadı.

**Amaç:** Kabul edilen B yaklaşımına kaynak sürümünü koruyan temel hazırlamak; yeni beşli politikasını pilot doğrulanana kadar üretimde kapalı tutmak.

**Mimari:** Tam katalog/korpus snapshot'ını içerik sürümü ve SHA-256 ile tanımlarız. Yeni masal için seçilen kaynak, tarihsel kitap/seri için gereken kaynaktan ayrıdır. K1 yalnız bu altyapıyı ve kayıt uyumluluğunu ekler; kadro filtresi, profil seçimi, yeni masal metni veya konuk casting'i eklemez.

**Teknoloji:** Swift / StoryEngine, mevcut ContentPackage ve loader, uygulama köprüsü, JSON Codable kayıtları ve paketli kaynaklar. Uygulama zamanı metin/görsel API'si yok.

**İcra kuralı:** İleride uygulama yetkisi gelirse görevler sırayla yürütülür; repo kuralı gereği testler/simülatör son doğrulama oturumunda toplu çalıştırılır. Şimdi yalnız belge ve kanıt dosyaları yazıldı. Bu belge uygulamayı başlatma talimatı değildir.

## 1. Kabul edilmiş ürün kararları

- **B seçildi:** Tarçın, Kestane, Yıldız, Simit ve Böğürtlen ana kadro; gerektiğinde ayrı konuk/uzman.
- Beşinin üç modda kişiliğine uygun repertuvarı olacak; bütün mevcut şablonlar hepsine açılmayacak.
- Eski kimlikler, kitaplar, hazırlanmış seri bölümleri ve pinli görseller korunacak.
- İlk yeni içerik pilotu: 5–6 yaş, tek ortak dünya, beş arkadaş × üç mod. Dünya ve içerik ayrıntıları [pilot önerisinde](2026-11-22-bes-arkadas-56-pilot-kapsami.md).
- Yeni politika pilot kanıtı oluşmadan **yayına girmez**. Pilot başarısı, genel katalogdaki konu/dünya kapsamının otomatik onayı değildir.
- Konuklu meslek, deniz ve uzay ayrı teslimlerdir. Ragi marka rehberi / kitap bazında Originals konuğu olarak ayrı kalır.

Önceki [geçiş raporu](2026-11-22-bes-arkadas-gecis-plani.md) keşif belgesidir; bu karar kaydı yaklaşım onayının güncel kaynağıdır. Kodlama yetkisi verilmedi.

## 2. K0–K1 kapsam sınırı

| K0–K1'e dahil | Sonraki teslimlere ait |
|---|---|
| Kabul kaydı, değişmezler, kaynak ve örnek manifesti | Beşliyi yeni masalda fiilen filtrelemek |
| Kaynak snapshot kimliği/deposu, exact çözümleme | Yeni anlatı profilleri, ziyaret habitatı ve konuk modeli |
| Origin/SeriesPlan için optional kaynak referansı | Pilot blueprint/proza/sanat dosyaları |
| Yeni seri planlama / yeniden yazımda kaynak sürümünü kullanmak | “Kim gelsin?” ekranı ve `.prefix(3)` değişikliği |
| Eksik/belirsiz kaynakta açık sonuç, veri koruma | Meslek/deniz/uzay paketlerini üretime almak |
| Legacy kitap/seri/art ve sync kabul senaryoları | Tüm yaş ve konular için beşli yayını |

K1 üretimde kaynak koruması amacıyla ayrı teslim edilebilir; bu, beşli politikasının yayınlanması değildir. Pilot paketi bundle'a veya uzaktan dağıtım feed'ine bu teslim sırasında girmez.

## 3. Mevcut kodda değişmesi gereken bağlantılar

| Gerçek dosya / davranış | K1 gereği |
|---|---|
| `MagicPaper/StoryEngineBridge/OfflineStoryService.swift`: özel init, tek güncel cached catalog | Enjekte edilebilir kaynak repository'si; üretim singleton API'sini koru; güncel cache'i tarihsel cache ile karıştırma |
| `.../RemoteContent/CatalogSourceResolver.swift`: `promoteStaged`, bozuk/eski aktif paketi silme | Mevcut source sonucu yanında exact source ref; güvenilir kaynak kullanılırken tarihsel kopyası korunur |
| `.../RemoteContent/RemoteContentService.swift`: feed paketi geri çekince active/staged siler | Aktif seçimden çıkarma ile tarihsel snapshot silmeyi ayır; bozuk/güvensiz paketi arşivleyip meşrulaştırma |
| `.../RemoteContent/RemoteContentStore.swift`: feed+active+staged; backup dışı dizin | Geçmiş kaynak deposu ayrı yaşam döngüsü; cache temizliği/remote rollback bu depoyu silmez |
| `StoryEngine/Sources/StoryEngine/Content/ContentPackage.swift`: full source set, şema 2 | Snapshot için aynı loader yolu; yeni yorumlayıcı/ikinci merge algoritması yok |
| `MagicPaper/Models/Story.swift`: `StoryOrigin.catalogVersion` | Optional exact ref, eski origin çözülmeye devam eder; mevcut metin/art alanlarına dokunma |
| `.../OfflineStoryMapper.swift` ve `MagicPaper/Services/StoryGenerationManager.swift` | Compose'da kullanılan exact ref'i map/saklama çağrısına kayıpsız geçir; güncel ref'i sonradan sorup yanlış kaynağı yazma |
| `StoryEngine/.../Offline/Series/SeriesPlan.swift`: `catalogVersion` var, otomatik kaynak çözümü yok | Optional source ref; `.withoutFamily()` bunu korur; composer'a sağlanan kaynakla tutarlılık kontrolü |
| `.../SeriesManager.swift`: eligibility güncel katalogda, 2–5 başta yazılır | Uygunluk ve planlama aynı exact kaynağı görür; unlock'ta compose yok; aile silinmesinde eski ref kullanılır |
| `.../Account/SyncModel.swift`: stories presenceOnly, series lastWriterWins | Yeni metadata'nın sync round-trip'i; older-client eksik alanı bilinen ref'i sessizce düşürmesin |

`...` uygulama dosyalarında `MagicPaper/StoryEngineBridge`, motor dosyalarında `StoryEngine/Sources/StoryEngine` köküdür. Görevlerde kesin yollar kullanılmıştır.

## 4. Veri ve çözümleme sözleşmesi

### 4.1 Yeni tipler — tasarım adları, henüz kodda yok

**`ContentSourceReference`** (motorun doğrulanmış Codable veri tipi): `schemaVersion: 1`, `catalogVersion`, `packageSchemaVersion: 2`, `payloadSHA256` (64 küçük hex), `engineBehaviorID: offline-legacy-v1`. Dosya yolu, URL, çocuk/aile adı taşımaz. Digest saklanan **tam ContentPackage payload byte'larının** SHA-256'sıdır; tek pilot_library veya yalnızca versiyon etiketinin özeti değildir.

`engineBehaviorID` kaynağın hangi kompozisyon kurallarıyla yorumlandığını söyler; payload digest algoritma sürümü değildir. K1 mevcut composer davranışını bu kimlikle kaydeder. Sonraki profil/sert filtre teslimi eski davranışı koruyan sürüm yolu ve legacy fixture kabulünü sağlamalı; bilinmeyen behavior ID desteklenmiş sayılmaz. Kaynak arşivi geçmiş çalıştırılabilir binary arşivi değildir; gelecek engine değişimi exact kaynak buldu diye bit-bit yeniden yazımı otomatik garanti etmez. Parse cache digest ile, compose yeteneği kontrolü ref içindeki behavior ID ile yapılır.

**`ContentSourceMetadata`** (motorun küçük wire zarfı, yeni): known reference / unsupported schema / malformed raw durumları. Hem `SeriesPlan` hem app origin aynı alan biçimini kullanır. Bozuk ref bütün `SeriesPlan` decoder'ını düşürmemeli; ham alan kayıpsız korunur, compose blocked olur. App `StoredContentSource` bunu app sonucuna çeviren küçük adaptördür, ikinci JSON sözleşmesi değildir.

**`CatalogSnapshot`** (app içi sonuç): doğrulanmış payload, ref, loader sonucu ve kaynak güven kanıtı. İçerik/hikâye/profil politikasını yeniden yorumlamaz. Aynı referans için aynı kaynağı döndürür.

**`HistoricalCatalogResolution`** sonucu:

| Sonuç | Anlam / izin |
|---|---|
| exact | Ref digest'i ve payload şeması/sürümü doğrulanmış; source yüklenebilir |
| verifiedLegacy | Ref'i olmayan eski kayıt için yayımlanmış uyumluluk manifesti kaynağı tekil ve kanıtlı seçmiş |
| missing | İstenen digest yerel/bundled kaynaklarda yok; otomatik güncel katalog kullanımı yasak |
| ambiguous | Semver eşit ama birden fazla olası payload; tahmin yok |
| unsupported | Kayıt ref veya payload şeması bu app'in yeteneğini aşıyor |
| corrupt | Digest/şema/sürüm/loader kanıtı tutarsız; kullanma ve kayıtları yeniden yazma |

`ContentSourceReference` optional **varlık** açısından geriye uyumludur. Alan mevcut ama bozuk/tanınmayan ise onu “alan yok, legacy”ye indirme. Opaque metadata'yı koruyan decode/encode veya mevcut raw-record koruma yöntemiyle kitap sayfaları okunabilir kalır; o kaynakla yeniden compose engellenir. Bu işte genel amaçlı JSON refaktörü yapılmaz; yalnız bu küçük metadata alanı için yerel koruma tipi tanımlanır.

### 4.2 Snapshot oluşturma ve saklama

- Bundle kaynağı mevcut `ContentPackage.bundledSources()` + `ContentPackage.build` yoluyla tam payload'a çevrilir; elde edilen byte'lar bir kere hash'lenir ve saklanır. Dosya sıralaması ve loader precedence manifestte yazılıdır. SHA hesaplandıktan sonra payload parse→reencode edilerek yeniden kaydedilmez.
- Güvenilir remote kaynakta feed'in onayladığı **orijinal package Data** korunur. Kaynak byte'ları, feed/signature doğrulaması, sürüm ve paket şeması birlikte denetlenir. Digest tek başına yayıncı güveni değildir.
- İç içe belge/dosya adı tekrarları, beklenmeyen kütüphane sırası ve eksik beat dosyaları snapshot freeze aşamasında reddedilir; mevcut loader semantiği değişmez.
- Yerel önerilen depo: app Application Support altında **`CatalogHistory`**, payload adı digest'ten türeyen `.mpcatalog`, yanında index/trust manifesti. `RemoteContentStore.eraseAll`/paket geri çekme bu dizine dokunmaz. Çocuk özel verisi içermez.
- Güncel kaynağın ilk kullanımı öncesinde kalıcı snapshot yazılır ve tekrar doğrulanır. Yeni kitabı/seriyi referansla saklamadan önce bu işlem başarıyla bitmeli. Yazma başarısızlığında ref'li yeni kitap kaydetme; mevcut kitaplara dokunmadan açık hata ver.
- Atomik geçici yaz→digest/loader kontrolü→adlandırma→index güncellemesi. Aynı digest tekrar yazımı idempotent; yarım kalan dosya kullanılmaz. Dosya sistemi kökünden çıkabilen adlar kabul edilmez.
- İlk sürümde geçmiş payload'ları otomatik budama yok. Boyut sayıyla raporlanır. Açık/bitmiş seri ve kitap kaynakları cache eviction'a tabi tutulmaz; hesabı silme/cihaz verisini silme mevcut kapsamıyla uyumlu temizler. Kaynakların kişisel veri olmadığı gerçeği aile kayıtlarını silmeme bahanesi olmaz.
- Restore/yeni cihaz: bundled tarihsel kaynaklar ve taşınan ref'ler offline okunmayı sağlar; arşiv backup kararı açık olmalı. Öneri: devam için gerekli CatalogHistory dosyaları backup'a dahil; public payload içinde kişisel veri yok. Uygulama başka cihazda kaynağı bulamazsa kayıtlı sayfaları okuyabilir, yeniden üretimde güncel kaynağa düşemez. Sonraki imzalı tarihsel paket dağıtımı ayrı operasyon olabilir; runtime metin/görsel API'si değildir.

### 4.3 Eski 2.1.0 kaydında digest yoksa

Mevcut HEAD veya semver eşitliği tarihsel kaynağı kanıtlamaz. Aynı `2.1.0` etiketi altında beat değişiklikleri var. İlk geçişte tüm eski origin'lere bugünkü digest topluca yazılmayacak.

K0'da bilinen dağıtılmış bundle/paket snapshot'ları, imzalı yayın kayıtları ve sentetik legacy fixture'ları toplanır. K1'in **`legacy-source-compatibility-v1`** manifesti, yalnız doğrulanmış eşlemeleri taşır. Kayıtta adayları ayıracak kanıt yoksa (ör. sadece semver ve seed) sonuç ambiguous kalır. Fingerprint tek başına kanıt sayılmaz; geçmiş girdiler eksik olduğunda yeniden compose ederek ispat uydurulmaz.

Bu durumda mevcut kitap ve önceden yazılmış seri bölümleri aynen okunur. **Yeni devam planlama veya aile silinmesiyle yeniden yazım** için doğru kaynak bulunamadığı açıkça belirtilir. Kaynağı bulunamayan eski kitapların devam edebilirliğini korumak yayın öncesi giderilecek uyumluluk açığıdır; sessiz ikame veya “bütün geçmiş kaynaklar çözüldü” iddiası yok. K1 kabul raporu unresolved kayıt türlerini ayrı listeler.

### 4.4 Yeni seçim, devam ve okuma ayrımı

1. **Yeni legacy masal (K1):** launch'ta seçilmiş source ref'ini kullan; mevcut kadro ve metin davranışı değişmez.
2. **Kaydedilmiş kitap/seriyi oku:** katalog resolver çağırma; kaydedilmiş sayfa/metin/provenance/art'ı kullan.
3. **Kitabı ilk kez devam ettir:** origin exact/verifiedLegacy kaynağını çöz; eligibility ve planlama aynı sonucu kullanır. Güncel ebeveyn güvenliğiyle plan oluşturulur; kaynak aynı olduğu için eski arkadaşı beşli filtresinden geçmez.
4. **Aktif seri bölümünü aç:** kayıtlı bölüm kopyalanır; kaynak seçimi/seed/çizim eşleme tekrarlanmaz.
5. **Aile karakterini kaldır:** planın exact kaynağı ve plan.safety ile yalnız açılmamış bölümler ailesiz yazılır. `.withoutFamily()` source ref'i korur. Kaynak yoksa mevcut sakin kapanış/veri koruma kuralı uygulanır; açılmış bölümler ve art pinleri kalır. Sadece kaynak güncellemesi kendiliğinden seriyi kapatmaz.
6. **Yeni paket/rollback:** yeni masalın güncel kaynağı değişebilir; eski ref digest'i diğer pakete yönlendirilmez.

## 5. Kesin dosya haritası

Yeni dosya adları bu planın önerilen uygulama hedefleridir; bu tur oluşturulmadılar.

| Kesin yol | Yapılacak iş / sahip |
|---|---|
| `StoryEngine/Sources/StoryEngine/Content/ContentSourceReference.swift` (yeni) | Ref veri tipi, biçim/doğrulama ve behavior kimliği; motor sahibi |
| `StoryEngine/Sources/StoryEngine/Content/ContentSourceMetadata.swift` (yeni) | Origin/plan ortak kayıpsız wire zarfı; tanınmayan/bozuk alan bütün planı düşürmez |
| `MagicPaper/StoryEngineBridge/CatalogHistory/CatalogSnapshotStore.swift` (yeni) | Atomik payload/index saklama; app altyapı sahibi |
| `MagicPaper/StoryEngineBridge/CatalogHistory/HistoricalCatalogResolver.swift` (yeni) | Exact/legacy sonuçları, cached loaded snapshots; app altyapı sahibi |
| `MagicPaper/StoryEngineBridge/CatalogHistory/LegacyCatalogCompatibility.swift` (yeni) | İmzalı/bundled uyumluluk manifesti okuma ve tekillik kararı |
| `MagicPaper/StoryEngineBridge/CatalogHistory/StoredContentSource.swift` (yeni) | App origin metadata'sının known/unsupported/malformed durumunu kayıpsız koruma |
| `MagicPaper/StoryEngineBridge/CatalogHistoryResources/` (yeni) | Doğrulanmış tarihsel `.mpcatalog` payload'lar + uyumluluk manifesti; resource target üyeliği doğrulanır |
| `MagicPaper/StoryEngineBridge/RemoteContent/CatalogSourceResolver.swift` | Güncel seçimin snapshot/ref sonucunu döndür; tarihsel resolver'dan ayrı tut |
| `MagicPaper/StoryEngineBridge/RemoteContent/RemoteContentService.swift` | Active kaldırma/rollback ile history yaşam döngüsünü ayır |
| `MagicPaper/Models/Story.swift` | `StoryOrigin` optional metadata; diğer origin/art alanlarını koru; pbxproj'a yeni model dosyası ekleme yok |
| `StoryEngine/Sources/StoryEngine/Offline/Series/SeriesPlan.swift` | Optional ContentSourceMetadata içinde typed ref, `.withoutFamily`, source/behavior mismatch guard; eski decoder uyumu |
| `MagicPaper/StoryEngineBridge/OfflineStoryService.swift` | Kaynak repository dependency injection; compose ref aktarımı; historical plan/compose |
| `MagicPaper/StoryEngineBridge/OfflineStoryMapper.swift` | Compose source metadata'sını origin'e aynen geçir |
| `MagicPaper/Services/StoryGenerationManager.swift` | Yeni compose→map çağrısında aynı ref'i taşı |
| `MagicPaper/StoryEngineBridge/SeriesManager.swift` | Exact-source eligibility/start/family removal; mevcut unlock davranışını koru |
| `MagicPaper/StoryEngineBridge/Account/FamilyLocalStore.swift` | Kaynak metadata'sını sync payload'ında koruma; missing-old-client merge kararı |
| `MagicPaper/StoryEngineBridge/Account/LocalDataEraser.swift` | Yeni history dizininin veri silme yaşam döngüsü |

`RemoteContentStore` içeriğini genel amaçlı arşiv deposuna çevirmiyoruz. Yeni kaynak deposu ayrı bileşen; küçük ortak değişiklikler tek dosya sahibiyle yapılır. `StoryEngineBridge` senkronize gruptur; yeni resources için bundle üyeliği ayrıca son build kontrolünde doğrulanır.

## 6. Sıralı görevler

### K0.1 — Karar ve yayın kilidi

**Belgeler:** bu dosya; `2026-11-22-bes-arkadas-56-pilot-kapsami.md`; önceki geçiş raporunun güncel karar bağlantısı.

- [ ] B kararı, beş kimlik, üç mod, eski kayıt koruması ve üç ayrı konuk teslimini sürümlü karar kaydında sabitle.
- [ ] Pilot durumlarını `planned → authored → source-reviewed → validated → product-accepted` olarak kaydet; bunların hiçbirini otomatik `production-enabled` sayma.
- [ ] Üretim beşli seçim politikası kapalı; sadece geliştirici/test pilot repository'siyle açıkça seçilebilecek. Remote flags pilotu kendiliğinden açamaz.
- [ ] Mevcut Release üretim yolunun legacy kaldığına ilişkin kabul senaryosunu yaz: pilot payload projede bulunmasa bile kaynak arşivleme çalışır.

**Çıkış:** kapsam ve yayın koşulları tek anlamlı. **Bu tur karar/plana işlendi; uygulama kutuları açık.**

### K0.2 — Kaynak ve başlangıç örneklerini dondur

**Oluşturulacak uygulama zamanı kanıtları:** `docs/research/five-friends-k01-baseline/manifest.json`, `legacy-book-fixtures.json`, `legacy-series-fixtures.json`; yalnız sentetik veriler.

- [ ] Uygulamaya geçilen HEAD + kirli üretim dosyalarının hash'lerini ve gerçek launch kaynak türünü kaydet. Bu turki HEAD ile sonraki uygulama HEAD'ini karıştırma.
- [ ] Bundle full source set, source sırası, dosya adları, byte SHA'ları, paket şeması ve katalog sürümünü manifestte sabitle.
- [ ] Bilinen yayımlanmış paket/bundle sürümlerini ve aynı semver altındaki farklı digest'leri ayrı satırlarla kaydet. Bulunmayan tarihsel byte'lar `unresolved` olarak görünür.
- [ ] Sentetik örnekler: origin'siz eski kitap; `growth` alias'lı kitap; tam provenance ve pinli kitap; provenance'sız kitap; beşli dışında Pamuk/Köpük arkadaşı; aileli/ailesiz açık seri; bitmiş seri; açılmış ve kilitli bölümlerin karışımı; source metadata'sı ileri sürüm/bozuk kayıt.
- [ ] Her örnekte UUID/tarih/metin/provenance/art için beklenen değişmezleri yaz. JSON anahtar sırası değil alan değeri eşitliği; metin ve asset payload için byte eşitliği ölçülür.
- [ ] Bilinen eski seri uygunluğu ve motor test kusurlarını adıyla başlangıç tabanına al; başarısız eski testleri yeni teslimin başarısı sayma.

**Çıkış:** son doğrulamada karşılaştırılacak değişmez fixture ve kaynak listesi. Gerçek aile kütüphanesi rapora kopyalanmaz.

### K1.1 — Kaynak kimliği ve API sınırı

**Create:** `ContentSourceReference.swift`, `ContentSourceMetadata.swift`; **Test:** `StoryEngine/Tests/StoryEngineTests/ContentSourceReferenceTests.swift` (yeni).

- [ ] Ref alanlarını §4.1'e göre tanımla; boş/yanlış uzunlukta/hex olmayan digest'i reddet; bilinmeyen şemayı desteklenmiş sayma.
- [ ] `catalogVersion` ve payload'ın loader sonrası versiyonu eşit olmalı; paket şeması payload ile eşleşmeli.
- [ ] `ContentPackage` byte hash'i app CryptoKit katmanında hesaplanır; `StableHash` fingerprint'i SHA yerine kullanılmaz. Motor tipinin Apple SDK'larına bağımlılığı artmaz.
- [ ] Ref mevcut ama desteklenmiyorsa ayrı sonuç üret; optional alanın yokluğuyla eşitleme.

**Kabul örnekleri:** geçerli referans round-trip; digest tek byte değişimi reddi; aynı semver/farklı digest ayrı identity; şema 99 unsupported; behavior kimliği bilinmiyorsa unsupported; ref'i olmayan eski plan decode; malformed ref taşıyan planın sayfalarının kaybolmaması.

### K1.2 — Snapshot depolama ve güven

**Create:** `CatalogSnapshotStore.swift`; **Test:** `MagicPaperTests/CatalogSnapshotStoreTests.swift` (yeni). **Touch:** `CatalogSourceResolver.swift`, gerektiğinde küçük `RemoteContentStore` arayüzü.

- [ ] Tam payload'ın idempotent atomik yazımı ve doğrulanmış okumasını ekle; testte temp dizin ve hata enjekte edilebilir dosya erişimi kullan.
- [ ] Trusted bundle ile feed/signature doğrulanmış remote giriş yollarını ayrı tanımla. Aday/staged dosya, sadece dosyada bulundu diye trusted geçmiş olamaz.
- [ ] Yazma sırasında çökme/boş alan yokluğu/bozuk index için son iyi snapshot'ı koru; yeni referansla kitap kaydını engelle.
- [ ] Güncel kaynak kullanımından önce history güvencesi; promote/rollback/feed geri çekmede history tutulur. Yeni dizin, remote cache temizliğinden bağımsızdır.
- [ ] `LocalDataEraser` yeni yolu bilir; loglarda yalnız olay ve sayım vardır, çocuk adı/metni yok.

**Kabul örnekleri:** yinelenen write tek payload; temp dosyası sonrası kesinti; yanlış SHA; yeni paket promote; feed katalog referansını kaldırır; remote cache erase; history hâlâ exact eski kaynağı verir. Account erase aile kayıtlarıyla birlikte hedef dizini temizler.

### K1.3 — Tarihsel resolver ve eski referans belirsizliği

**Create:** `HistoricalCatalogResolver.swift`, `LegacyCatalogCompatibility.swift`, doğrulanmış `CatalogHistoryResources`; **Test:** `MagicPaperTests/HistoricalCatalogResolverTests.swift` (yeni).

- [ ] Exact çözümde yalnız istenen SHA payload'ını seç; digest tutmazsa eşit semver alternatifini deneme; engineBehaviorID desteklenmiyorsa kaynağı bulmuş olsan da compose izni verme.
- [ ] Payload'ı mevcut `ContentCatalogLoader.load(package:)` ile yükle; app update'te eski kaynağı doğrulamak için `RemoteCatalogPolicy.notNewer` kuralını kullanma. “Yeni katalog olsun mu?” ile “tarihsel kaynak okunur mu?” farklı sorudur.
- [ ] Ref'siz legacy isteklerde yalnız doğrulanmış manifesti kullan. Manifestte iki aday ve ayırt edici kanıt yoksa ambiguous; hiç kaynak yoksa missing.
- [ ] Supported package şeması 2 K1'de korunur; yeni guest/profile kaynak anlamı henüz gelmedi. Gelecek şemalar için unsupported sonucu hazır; şema 3'ü şimdi boşuna açma.
- [ ] Cache anahtarı digest olsun; güncel katalog cache'inden tarihsel isteğe cevap verme.

**Kabul örnekleri:** aynı sürümlü farklı iki payload; stale manifest; tam kaynak setinden eksik dosya; eski schema unsupported; remote newer aktifken eski exact istek; current resolver hiç çağrılmadan tarihsel çözüm.

### K1.4 — Kalıcı modeller ve compose→map kaynağı

**Modify:** `Story.swift`, `SeriesPlan.swift`, `OfflineStoryMapper.swift`, `StoryGenerationManager.swift`. **Create:** `StoredContentSource.swift`. **Tests:** `MagicPaperTests/OfflineStoryMappingTests.swift`, `MagicPaperTests/StoredContentSourceTests.swift` (yeni), `StoryEngine/Tests/StoryEngineTests/SeriesPlannerTests.swift`.

- [ ] `StoryOrigin` ve `SeriesPlan` için ortak ContentSourceMetadata zarfında optional content source referansı ekle; schema eksik eski kayıtları okuyabilen decoder korunsun. Planın `.withoutFamily()` kopyası referansı taşır.
- [ ] App tarafında malformed/unknown metadata'nın varlığını ve ham değerini sakla; sadece bu alan bozuk diye tüm kitap/seri listeden düşmesin. Kaynağı çözülemeyen kayıtta rewrite reddedilir.
- [ ] `OfflineStoryService.compose` sonucunun kaynak ref'i ile map çağrısı aynı nesneden gelsin; asenkron UI hazırlığında güncel paket değişse bile ikinci lookup yok.
- [ ] Existing art/provenance/source fingerprint/variantIDs alanları aynen korunur; K1 metadata'sı metin seçimine veya eski art fingerprint hesabına katılmaz.
- [ ] Kayıtlı eski kitapları açılışta toplu yeniden encode/backfill etme. İlk yeni kayıttan itibaren exact ref sakla; doğrulanmış eski bağlam çözümü sidecar'da tutulabilir, kitabın sayfasını değiştirmez.

**Kabul örnekleri:** legacy kitap alan eşitliği; unknown ref decode/encode ham alan korunumu; provenance partCount/tam sıra; pinned digest korunumu; paket değişimi arasında compose-map eşit kaynak; ref metadata'sız yeni kitabı istemeden kaydetmeme.

### K1.5 — Servis ve seri yollarını exact kaynağa bağla

**Modify:** `OfflineStoryService.swift`, `SeriesManager.swift`, `SeriesPlan.swift`. **Test:** `MagicPaperTests/HistoricalSeriesTests.swift` (yeni), `MagicPaperTests/SeriesTests.swift`.

- [ ] Servisin private init'ini test dependency injection'ına aç; singleton aynı üretim default'uyla çalışsın. Yeni repository'de current ve historical sorguları ayrı fonksiyonlardır.
- [ ] Series eligibility origin'den source çözer; start aynı ref'i yeniden doğrular. Arada kaynak erişimi kaybolursa start açık başarısız olur, güncel kaynağa düşmez.
- [ ] `planSeries(from:)` exact source + o anki güvenlik ayarı; oluşturduğu plan/bölüm origin'leri aynı ref'i saklar. History/cast policy yeni ana seçim filtresi uygulanmaz.
- [ ] `composeSeries(plan:)` plan kaynağı + plan.safety; yanlış kaynak açık source mismatch. Ref'siz legacy planda verifiedLegacy çözümünden başka yol yok.
- [ ] Aktif seri unlock ve silinmiş okunmamış bölümün kütüphaneye geri konması kayıtlı pages/origin'i kullanır; resolver/composer çağrı sayısı **0** olur.
- [ ] Aile silinmesinde sadece kilitli bölümleri aynı kaynaktan yeniden yaz; açık bölümler field/byte eşit. Rewrite başarısızlığında mevcut sakin kapanış politikası, açılmış kayıt koruması ve açıklanabilir sonuç korunur.

**Kabul örnekleri:** aktif kaynak B iken kaynak A/Pamuk serisi; açılış gününde aynı art; aile kaldırma; kaynak missing/ambiguous; plan ref'i ile verilen katalog mismatch; sürpriz/özel gün/tek aktif seri/günlük açılma/abonelik kuralları regresyonu.

### K1.6 — Sync, yeniden kurulum ve koruma raporu

**Modify:** `Account/FamilyLocalStore.swift`, gerektiğinde küçük `SyncModel` adaptörü; **Test:** `MagicPaperTests/AccountSyncTests.swift` ve `MagicPaperTests/HistoricalSeriesTests.swift`.

- [ ] Yeni origin/plan referanslarının hesap sync'i ve restore'da aynen taşındığını doğrula; stories `presenceOnly` kuralını gevşetme.
- [ ] Eski istemci metadata'sız aynı seri güncellemesi yollarsa, yerelde bilinen exact ref ancak anchor/plan ve kaynak bağımlı kayıtların eşitliği doğrulandığında korunur. Çelişen yeni ref'ler körlemesine birleştirilmez; açık conflict/missing sonucu.
- [ ] Kaynak arşivi bulunmayan yeni cihaz saved pages'i yine okuyabilir; devam/rewrite resolver sonucu missing olur. Şebekeye çıkıp seed değiştirerek düzeltme yok.
- [ ] Eski istemcilerin yeni pilot profil/konuk metadatasını yorumlayamayacağı sürüm geçişi sonraki pilot yayın tesliminde minimum yetenek kuralıyla ele alınır. K1, eski uygulamanın yeni politikayı doğru compose edebildiği iddiasında bulunmaz.
- [ ] Rapor: toplam sentetik fixture, exact/verifiedLegacy/unresolved sayısı, eski kitap/aktif bölüm değer farkı, eski art byte farkı, beklenen source-rejection örnekleri. “Devam korunuyor” iddiası unresolved listesini gizleyemez.

### K1.7 — Tek toplu doğrulama ve teslim

K0–K1 altyapı işi bittikten sonra yürütülecek; bu plan turunda çalıştırılmadı.

- [ ] Motor tam paketi: `swift test --package-path StoryEngine`.
- [ ] Uygulama: önce `xcrun simctl list devices available`; seçilen cihazın UDID'sini görev raporuna yaz. Sonra `xcodebuild -project MagicPaper.xcodeproj -scheme MagicPaper -destination "platform=iOS Simulator,id=$K01_SIMULATOR_UDID" -derivedDataPath /private/tmp/magicpaper-k01-derived -resultBundlePath /private/tmp/magicpaper-k01-tests.xcresult test`. `K01_SIMULATOR_UDID` gerçek listeden atanır; hayalî cihaz adı kullanılmaz.
- [ ] Yeni sınıflar + `ContentPackageTests`, `CatalogLoadingTests`, `CatalogMergeTests`, `OfflineDeterminismTests`, `SeriesPlannerTests`, app mapping/remote/series/memory/sync/art testleri sonuçlarını raporla. Tam koşu kırmızıysa geçer deme; eski/yeni hataları fixture baseline ile ayır.
- [ ] Alan/byte karşılaştırması: legacy books text/provenance/art **0 fark**; unlock composer/resolver **0 çağrı**; tekil current+historical cache collision **0**; yeni kayıt exact ref saklama **%100**.
- [ ] K1 üretim seçiminde kadro/seed/metin değişimi **0**. Source metadata haricinde compose→map metin ve eski art kararı aynı kalır.
- [ ] DEMO_CHANGELOG kaydı, değişen dosya listesi, unresolved tarihsel kaynak listesi, schema/version sözleşmesi ve rollback prosedürü teslim edilir. Commit yalnız bu işin dosyalarıyla yapılır; mevcut kirli günlükte diğer oturumun değişiklikleri stage edilmez.

**K1 kabulü:** kaynak koruma altyapısı çalışır; yeni beşli politika kapalı; eski kayıtlar okunur ve hazırlanmış bölümler aynen açılır. Tarihsel yeniden yazım yalnız exact/verifiedLegacy çözümünde yapılır. Kaynağı kanıtlanamayan geçmiş tür varsa bunun çözüm/yayın etkisi açık raporlanır; “tüm eski devamlar korundu” denmez.

## 7. Sonraki teslimler ve bağımlılıklar

| Teslim | Giriş | Çıkış / yayın sınırı |
|---|---|---|
| P56 — konuksuz ortak dünya pilotu | K1 kabulü + [içerik önerisi](2026-11-22-bes-arkadas-56-pilot-kapsami.md) | 15 hücre, yeni kaynaklar, tam sayfa sanat kanıtı, ölçüm; üretim anahtarını kendiliğinden açmaz |
| G-Meslek | P56 profil/casting temelinin kabulü; ayrı expert yuvası tasarımı | 5–6 tek meslek/tek uzman pilotu; occupation/fact/topic uyumu; eski jobs blueprint'leri değişmez |
| G-Deniz | P56 + ayrı deniz ürün kararı | Ana arkadaşın kıyı/sualtı varlığı açık; yunus konuğu gerçek rolünde; ayıya yüzme/taşıma ikamesi yok |
| G-Uzay | P56 + ulaşım/yaşam ortamı/aksesuar kararı | Vakum/uzay davranışı, kimlik varyantı ve gerçek uzay konusu; Yıldız'ın uçuşu uzay yeteneği sayılmaz |
| Genel beşli yayını | P56 teknik+editoryal+sanat kabulü ve açık ürün yayını kararı | Diğer yaş/konu kapsamı ayrıca raporlanır. Eksik dünya sessizce “Fark etmez” havuzundan düşürülmez |

Meslek/deniz/uzay teslimlerinin hiçbiri K0–K1'e saklı kapsam olarak eklenmez. İlk pilotta konuk alanı yoktur; B'nin konuk hakkı daha sonraki bağımsız şema ve içerik teslimidir.

## 8. Bu planın doğrulama kanıtları

Kaynak incelemesinin yeniden üretilebilir girdi hash'leri ve gerçek legacy tam sayfa sanat örnekleri [görsel ekip kanıt paketinde](../../research/2026-11-22-bes-arkadas-56-gorsel-kaynaklar.json). Mevcut önceki statik matris ayrıca [ilk envanterde](../../research/2026-11-22-five-friends-evidence.json). Bu tur yalnız belge/kaynak bağlantıları ve hash'ler kontrol edildi; K1 testleri geçmiş gibi gösterilmedi.
