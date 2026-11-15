# Masal evreni planı (E1-E8)

15 Kasım 2026. Kaynak: `main@e9deb03` üzerinde yapılan vizyon ve mimari denetimi (Batuhan'ın "Product Vision, Architecture & Strategic Project Audit" isteği). `docs/VIZYON_PLANI.md`'nin (Faz 7-14) yerine geçmez; onun "Masal dünyası" ayağının mühendislik sırasıdır.

## Denetimin sonucu

Vizyonun çoğu kodda var, önerilenden daha küçük ve daha uygun biçimde:

| Vizyondaki sistem | Koddaki karşılığı |
|---|---|
| Story Memory | `StoryMemory` (hatırlama cümlesi), `StoryMapView`, `MPYearbook`; hepsi biten masalların `StoryOrigin`'inden türetilir |
| Preference Memory | `UserProfile.interests`, `SelectionScoring` (ilgi ×3, 4 masallık soğuma), `UsageLearner` (0.6-1.8) |
| Karakter sürekliliği | `CatalogCompanion`, `FamilyCharacter` (Masal ailem), `SeriesAnchor` |
| Story Orchestrator | `StoryGenerationManager.createStory` |
| Print pipeline | `MPStoryPDF`, `MPPrintSpec`, `BookExportView` |
| Sync, yetki | `StoryEngineBridge/Account/*`, `Services/Entitlements/*` |

Açık olan dört dikiş ve bir içerik sorunu:

1. Kitaplığın doğruluk kaynağı hâlâ tek bir `UserDefaults["stories"]` yığını; dosya deposu gölge.
2. Masal bağlamı `createStory` içinde satır arası toplanıyor; hatırlama cümlesi motorun dışında, sayfa 1'e sonradan ekleniyor.
3. Çocuğun iki ayrı kimliği var: `HeroLook` ve `AvatarSpec`.
4. `EntitlementPolicy.decide` hiçbir yerden çağrılmıyor; paywall Release'te kapalı olan görselli masalı satıyor.
5. İçerik: 8 mekân, 8 yol arkadaşı, 8 nesne, 36 blueprint (3-4: 4, 5-6: 20, 7-8: 6, 9-10: 6).

## Kararlar

- **Hafıza türetilir, saklanmaz.** Ayrı bir hafıza deposu, olay tablosu ya da ilişki grafiği açılmaz; kaynak biten masalların `StoryOrigin`'idir. Masal silinince hafızası da gider.
- **Yeni paket yok.** Tek yeni soyutlama `StoryContextBuilder` (köprüde, saf).
- **Yeni orkestratör yok.** `createStory` orkestratördür; motordaki eski `StoryOrchestrator` (bulut işi) dokunulmadan kalır.
- **"Dünya" tek kavram olur:** katalogda mekânları gruplayan bir kayıt. Ev dünyası / bağımsız dünya o kaydın bir alanıdır.
- **Aile anısı serbest metin değildir.** "Özel günler": yazılmış blueprint'ler (ilk okul günü, yeni kardeş, doğum günü, düşen diş), doğrulanmış alanlarla. "Serbest metin yok" kuralı kalır.
- **Saklanan metin kayıttır.** Seed tanı içindir; ilgi ve geçmiş saklanmadığı için yeniden kurmak aynı kitabı garanti etmez.
- **Yapılmayacaklar:** Universe Engine, karakter grafiği, genel hafıza deposu, LLM ile masal, dallanan anlatı, sohbet, sayfa başına üretilen görsel, uygulama içi baskı siparişi.

## Fazlar

Her faz ayrı worktree ve dalda (`evren-N-ad`), bir `DEMO_CHANGELOG.md` kaydı ve commit ile biter. Testler plan sonunda bir kez koşulur; ara fazlarda test yazılır, koşulmaz.

| Faz | Amaç | Büyüklük | Bağımlılık |
|---|---|---|---|
| E1 | Dosya deposu doğruluk kaynağı | K-O | yok |
| E2 | `StoryContextBuilder` dikişi | K | E1 |
| E3 | Hatırlama motorun içinde, kademeli | O | E2 |
| E4 | Tek kahraman kimliği | O | yok |
| E5 | Dünyalar içerik paketi olarak | B (içerik) | E2 |
| E6 | Özel günler | O | E2, E5 |
| E7 | Yetkiler canlı, dürüst paywall | O | ödeme turu kararı |
| E8 | Yıllık ve basılı kitap pilotu | O | E3 |

E1 ve E2 ardışık. E3, E4, E5 paralel yürüyebilir (dosyaları ayrı).

### E1: Dosya deposu doğruluk kaynağı

**Bugün.** `LibraryMigration` yaz → doğrula → işaretle → beklet adımlarını yapıyor; `readPathIsAuthoritative = false`. `saveStories()` her çağrıda bütün kitaplığı kodlayıp `UserDefaults`'a yazıyor, sonra gölgeyi eşitliyor. Kapının iki önkoşulundan biri kapanmış (`LocalDataEraser` → `LibraryPersistence.eraseAll()`), biri açık (`MPFavorites` doğrudan `UserDefaults`'a yazıyor).

**Tasarım.**

- Yeni evre: `Phase.diskAuthoritative`, `State.cutoverAt`. Sıra: `pending → verified → diskAuthoritative → legacyRetired`.
- Geçiş (`verified → diskAuthoritative`), açılışta, `cutoverEnabled` iken: son bir `reconcile()` + `verify(against:)`; ikisi de geçerse işaretlenir. Geçmezse eski yol aynen sürer.
- `diskAuthoritative`'de okuma diskten: `readAllStories()`, `createdAt` azalan, eşitlikte kimlik. Yazma yalnızca diske: değişen masal yazılır, silinen silinir. Eski yığına bir daha yazılmaz; dondurulmuş yedek olarak durur.
- Emeklilik: `cutoverAt`'ten 14 gün sonra, disk hatasız okunuyorsa eski anahtarlar silinir. Bayat yığına karşı doğrulama yapılmaz (kesişimden sonra silinen masal doğrulamayı sonsuza dek düşürürdü).
- Bozuk dosya: o masal rafta görünmez, dosya karantinaya taşınır, üstüne yazılmaz, silinmez. Diğer masallar açılır.
- Depo kurulamazsa (`diskAuthoritative` iken): eski yedek varsa raf ondan gösterilir, o oturumda kayıt yapılmaz, evre değişmez.
- Favoriler: `MPFavorites` depo üstünden yazar (`FlagList.favorites`); kesişimden önce bugünkü gibi `UserDefaults`.
- Örnek masallar, sync (`applySyncedStory`, `applySyncedProgress`), `resetAfterErase` aynı API'yle çalışır.

**Kapsam dışı.** `Story` modelinde değişiklik; `user_profiles`, seri, Masal ailem, rozet depoları; performans için arka plan kuyruğu; `StoryEngineBridge/FileStores.swift`.

**Kabul.** Kesişimden sonra tek masalın ilerlemesi değişince tek dosya yazılır; `UserDefaults["stories"]` değişmez. Bozuk bir dosya rafı düşürmez ve kaybolmaz. Kesişim öncesi davranış bit bit aynı. Yeni testler: geçiş, diskten okuma sırası, bozuk dosya, emeklilik, favoriler, depo yokken açılış.

### E2: `StoryContextBuilder`

`createStory`'nin topladığı her şey (ilgiler, son 4 köken, kullanım, son 12 başlık, Masal ailem, güvenlik, bant, hatırlama adayı) tek bir saf tipe taşınır: `StoryEngineBridge/StoryContextBuilder.swift`, çıktısı `StoryContext`. `OfflineStoryService.compose` onu alır. Davranış değişmez; altın test aynı girdiye aynı masalı ister.

### E3: Hatırlama motorun içinde

Bugünkü üç sabit cümle, sekiz yol arkadaşıyla birkaç masalda her açılışa yerleşir. Hatırlama kataloğa satır havuzu olarak girer (`familyMoments` deseni): kademe (bir kez tanıştı, dost, eski dost), soğuma (`SelectionScoring.cooled`), en çok üç masalda bir. Doğrulayıcılardan ve parmak izinden geçer. `StoryMemory.remember` kalkar; eski masallar değişmez.

### E4: Tek kahraman kimliği

Tür, ten, saç ve yüz tek kayıtta; büst (`HeroAvatarView`) ve sahne figürü (`AvatarKit`) ondan çizilir. Kozmetik ayrı katman. Karar gerekiyor: hayvan kahramanın sahnede karşılığı (çizilir mi, görselli kitap çocuk türü mü ister). `HeroLook` ve yıldız cüzdanı `SyncCollection`'a girer.

### E5: Dünyalar

Katalogda `worlds` kaydı mekânları gruplar. Seçim "Masalda kimler olsun?" adımında, konu çiplerinin yanında, isteğe bağlı; yeni adım yok. `StoryTheme.isPremium` ve `MP.World.isPremium` tek yere iner. İlk paketler: uzay, dinozorlar (`MP.World`'ün zaten söz verdiği). Asıl iş yazı: her dünya mekân, yol arkadaşı, nesne ve dört bantta satır ister.

### E6: Özel günler

Ebeveyn odasında "Özel günler" satırı, çarpma kapısıyla. Dört blueprint. Kayıt yapılandırılmış alanlardır, ad `FamilyNameValidator`'dan geçer, tek tek silinir, kendi blueprint'i dışında kullanılmaz, log'a girmez.

### E7: Yetkiler

Masal yazma `EntitlementPolicy.decide`'dan geçer. Eski masallar, kahraman, hafıza ve harita her zaman açık. Paywall yalnızca gerçekten açık olanı satar. Ödeme turu kararına bağlı; `docs/YAYIN.md`.

### E8: Yayınevi

`MPYearbook` + `MPStoryPDF` ile yıllık; tek basım ortağıyla on kitap, sipariş elle.

## Riskler

| Risk | Önlem |
|---|---|
| Kesişimde veri kaybı | Dondurulmuş yedek 14 gün; bozuk dosya karantinada; depo yoksa kayıt yok |
| Paralel oturum aynı dosyaya dokunur | `StoryGenerationManager.swift` ve `Models/Story.swift` tek sahipli; her faz kendi worktree'sinde |
| Sıraya duyarlı katalog dizileri | Yalnızca sona ekleme; test |
| İçerik maliyeti | Yol haritasının sınırlayıcısı; dünya sayısı yazı hızına göre |
