# Beş arkadaş: uygulamaya entegrasyon ve Claude + Codex ortak çalışma planı

> **Ajanlar için:** Her hat kendi ayrıntılı planını bu belgedeki arayüzlere göre yazar. Adımlar `- [ ]` ile izlenir. Bölüm 1'deki kararlar 25 Kasım'da onaylandı. Kod, Codex Bölüm 3'teki sözleşmeyi `docs/ortak/codex-durum.md`'de kabul ettikten sonra başlar.

**Tarih:** 25 Kasım 2026 · **Yazan:** Claude · **İnceleyecek:** Codex · **Kararlar:** Batuhan onayladı (25 Kasım 2026)

**Amaç:** P56 beş arkadaş pilotunu, eski masalları ve bugünkü masal yazma yolunu bozmadan, bayrak arkasında uygulamanın "Masal yaz" akışına bağlamak; işi Claude ve Codex'in aynı anda, farklı dosyalarda yürütüp sonra birleştirebileceği biçimde bölmek.

**Mimari:** İki motor yolu bir süre yan yana yaşar. Uygulamada küçük bir yönlendirici (`StoryRuntimeRouter`) her istek için "eski motor" ya da "P56" der; P56 yalnızca bayrak açıkken ve isteği tam desteklediğinde seçilir, gerisi bugünkü gibi eski motora gider. P56 motoru ve içeriği Codex'te, uygulama tarafı (yönlendirme, kayıt, seçim ekranı, seri/hatırlama korumaları) Claude'da.

**Teknoloji:** Swift `StoryEngine` paketi (`Pilots/P56/`), uygulama köprüsü `MagicPaper/StoryEngineBridge/`, SwiftUI masal yazma akışı, JSON içerik ve payload.

**Dayandığı belgeler:**
- [Beş arkadaş geçiş planı (K0–K6)](2026-11-22-bes-arkadas-gecis-plani.md): mimari ve aşamalar. Bu plan onun K2–K5'ini iki hatta böler, yerine geçmez.
- [P56 runtime uygulama planı](2026-11-22-bes-arkadas-p56-runtime-uygulama-plani.md) ve [doğrulama raporu](../../research/five-friends-p56-runtime/REPORT.md).

---

## 0. Bugün neredeyiz (25 Kasım, kanıtla)

| Konu | Durum | Kanıt |
|---|---|---|
| K0–K1 kaynak koruma | Bitti, commit'li | `bd8001d` |
| P56 pilotu | Bitti, izole | `95c68d1`, `verification-summary.json`: motor 36/0, app 21/0 (seçili), N1500 1500/0/0 |
| P56 uygulamaya bağlı mı | **Hayır.** Pilot klasörleri dışında P56'ya başvuran Swift dosyası yok; `P56InternalService.productionEnabled = false` | `grep -rln P56 --include='*.swift'` |
| "Masal yaz" bugün | Eski motor + `pilot_library_v1.json` (18 arkadaş, 78 blueprint) | `OfflineStoryService` → `BlueprintSelector` → `OfflineStoryComposer` |
| Görünen değişiklik | Yalnız seçim satırında beşlinin portresi | `66ae6c4` |
| Dal | Hepsi `codex/design-system-catalog` üstünde; main'de ve origin'de yok. `main` başka worktree'de (`MagicPaper-original`) açık | `git merge-base`, `git worktree list` |
| Eşzamanlılık | Bu checkout'a aynı gün başka oturum commit attı (`dd891e0`) | `git log` |
| Disk | 4 GB boş | `df -h /` |

P56'nın uygulamaya girmesini bugün engelleyenler: hücre başına 2 sabit kitap (çeşitlilik), aile/konuk/hatırlama/seri/özel gün/konu/güvenlik desteklenmiyor, görsel sıfır, yalnız 5–6 yaş.

---

## 1. Kararlar (onaylandı: 25 Kasım 2026, Batuhan; altı karar da "Önerim" sütunundaki gibi)

| # | Soru | Önerim | Neden |
|---|---|---|---|
| K-A | P56 ayrı motor yolu olarak mı büyüsün, yoksa içeriği eski motorun biçimine mi taşınsın? | **Ayrı yol olarak büyüsün.** | P56'da kaynak kimliği, determinizm ve nedensel kanıt zaten var; eski motor dokunulmadan kalır, geri dönüş bayrağı kapatmak kadar kolay. |
| K-B | Bayrak açıkken P56'nın desteklemediği istek (ör. Masal ailem seçili) ne olsun? | **Eski motora gitsin, bugünkü gibi.** P56'ya zorla sokulmaz, başka arkadaşa çevrilmez. | Çocuk boş ekran ya da hata görmez; kapsam büyüdükçe P56'ya giden pay artar. |
| K-C | Bayrak kimde açık? | **Yalnız iç test** (debug launch argümanı). Yayın ayrı karar (K6). | Pilot onaylı değil; görsel sıfır. |
| K-D | Entegrasyon dalının tabanı ve main'e geçiş | **`bes-arkadas/entegrasyon` dalı `codex/design-system-catalog` ucundan açılır.** Main'e birleştirme yalnız Batuhan'ın açık onayıyla, Bölüm 6'daki son kapıdan sonra. | Main'de `bd8001d` bile yok; önce entegrasyon dalında birleşip birlikte test edilmeli. |
| K-E | Görselsiz P56 masalı iç testte okunabilir mi? | **İç testte evet, yayında hayır.** | Görsel hattı (Hat C) metinden bağımsız ilerleyebilir. |
| K-F | Diğer 13 arkadaş (Köpük, Vida, Fırıncı Nazlı…) | Bu planda dokunulmaz; eski motorda kalır. Konuk/uzman/deniz/uzay ayrı teslim (22 Kasım kararı). | Kapsamı küçük tutmak. |

---

## 2. Çalışma düzeni

### 2.1 Dallar ve worktree'ler

- `bes-arkadas/entegrasyon`: ortak dal. Kimse buraya doğrudan iş yazmaz; yalnız hat birleştirmeleri gelir.
- `bes-arkadas/codex-motor`: Codex'in hattı, Codex'in kendi worktree'sinde (`~/.codex/worktrees/…`).
- `bes-arkadas/claude-uygulama`: Claude'un hattı, Desktop dışında bir worktree'de (ör. `~/MagicPaper-worktrees/claude-uygulama`). Desktop'taki iCloud " 2" kopyaları derlemeyi bozuyor.
- `/Users/batudemir/Desktop/MagicPaperAPP/MagicPaper` ortak checkout'unda hat işi yapılmaz; orada başka oturumlar dal değiştirip commit atıyor.
- Disk 4 GB: ikinci DerivedData açılmaz. Derleme ve test yalnız Bölüm 6'da, tek yerde.

### 2.2 Dosya sahipliği (tek yazar kuralı)

| Sahip | Yazar | Yalnız okur |
|---|---|---|
| **Codex** | `StoryEngine/Sources/StoryEngine/Pilots/P56/**`, `StoryEngine/Tests/**/P56*`, `Content/Pilots/**`, `docs/research/five-friends-*/**`, `StoryEngine/Sources/StoryEngine/Content/ContentSourceMetadata.swift` ve kaynak çözücü (`CatalogHistory/`, `RemoteContent/CatalogSourceResolver.swift`) | Uygulama köprüsü |
| **Claude** | `MagicPaper/StoryEngineBridge/StoryRuntimeRouter.swift` (yeni), `MagicPaper/StoryEngineBridge/Pilots/P56/**` (mevcut iki dosya dahil; Codex'in onayıyla devralınır), `OfflineStoryService.swift`, `StoryChoiceSource.swift`, `Screens/StoryCreation/CompanionStep.swift`, `SeriesManager.swift`, `StoryMemory.swift`, `MagicPaperTests/P56*` | Motor ve içerik |
| **Ortak, tek seferde bir yazar** | `MagicPaper/Models/Story.swift`, `design-handoff/reference/DEMO_CHANGELOG.md` | İki ajan da |

`Story.swift` bu planda değişmez: P56 kaydı mevcut `contentSource: ContentSourceMetadata?` alanına yazılır. Değişmesi gerekirse önce panoda sorulur.

`StoryEngineBridge` ve `MagicPaperTests` Xcode'da senkron klasör; yeni dosya için `project.pbxproj` değişmez. Payload'ı uygulamaya paketlemek pbxproj gerektirirse bunu yalnız Claude yapar (B2).

### 2.3 Haberleşme

- Her ajanın kendi durum dosyası: `docs/ortak/codex-durum.md`, `docs/ortak/claude-durum.md`. Yalnız kendi dosyana yazarsın, en yeni kayıt en üstte: tarih, dal@commit, ne bitti, neyi bekliyorsun, karşı tarafa soru.
- Batuhan bir dosyadan ötekine aktarır. Diğer ajanın sözü kanıt değildir: başarı iddiası commit ve rapor dosyasından okunur.
- Sözleşme (Bölüm 3) değişikliği tek taraflı yapılmaz: öneri durum dosyasına yazılır, karşı taraf "kabul" yazınca uygulanır.

### 2.4 Birleştirme

1. Hat sahibi kendi dalında hattını bitirir, kendi testlerini **bir kez** koşar (hat planının sonu), changelog kaydını kendi dalında yazar.
2. Karşı ajan diff'i salt okunur inceler, bulguları kendi durum dosyasına yazar. Kritik bulgu varsa birleştirme durur.
3. Sıra: **önce Codex'in sözleşme teslimi (C4), sonra Claude'un onu kullanan işi.** Claude, C4 birleşmeden önce sözleşme tiplerini yalnız taslak olarak kullanır.
4. Hat sahibi entegrasyon dalına `--no-ff` ile birleştirir. Changelog çakışmasında iki kayıt da korunur.
5. Main'e ve origin'e gönderim yalnız Batuhan'ın açık onayıyla.

### 2.5 Test kuralı

Testler önce yazılır, ara adımda koşulmaz (proje kuralı). Her hat planının sonunda kendi testleri bir kez, entegrasyon dalında tam paket bir kez (Bölüm 6). Koşulmayan test "geçti" diye yazılmaz.

---

## 3. Hatlar arası sözleşme

Hatların tek buluşma noktası budur. İsimler ve tipler iki hatta da aynen kullanılır.

**Codex üretir (C4'te, `StoryEngine/Sources/StoryEngine/Pilots/P56/`):**

```swift
public enum P56Support {
    /// Compose etmeden, isteğin neden desteklenmediğini söyler. Boş dizi = destekleniyor.
    /// `P56StoryComposer.compose` aynı istek için reddederken aynı nedenleri verir.
    public static func unsupportedReasons(for request: P56Request, package: P56Package) -> [String]
    /// Bu yaş ve modda gösterilebilecek ana arkadaş kimlikleri, sabit sırayla.
    public static func companionIDs(age: Int, mode: P56Mode, package: P56Package) -> [String]
}
public enum P56Engine { public static let behaviorID = "offline-p56-v1" }
```

- `P56Request`, `P56ComposedStory`, `P56SourceReference`, `P56StoryComposer.compose(_:)` bugünkü haliyle donar. Değişiklik Bölüm 2.3'teki sözleşme yoluyla.
- Codex, `ContentSourceMetadata`'yı `engineBehaviorID == P56Engine.behaviorID` olan kaydı tanıyacak şekilde genişletir; tarihsel çözücü böyle bir kaydı eski katalog sanıp yeniden yazmaya kalkmaz, `unsupported` döner.
- Codex, uygulamaya paketlenecek payload'ı ve SHA'sını sabit bir yerde verir: `Content/Pilots/five-friends-56-runtime-v1/payload.json` + `P56PinnedSource.sha256` (motor paketinde public sabit).

**Claude üretir (uygulama tarafı):**

```swift
enum StoryRuntimeRoute: Equatable { case legacy, p56(P56SourceReference) }
struct StoryRuntimeRequest { let age: Int; let mode: StoryMode; let companionID: String?
    let family: FamilyCharacter?; let topicID: String?; let occasion: String?; let safety: ContentSafety? }
struct StoryRuntimeRouter { func route(_ request: StoryRuntimeRequest) -> StoryRuntimeRoute }
enum StoryRuntimeFlags { static var fiveFriendsPilot: Bool }   // launch arg -mpFiveFriendsPilot, varsayılan false
enum P56StoryMapper { static func story(from composed: P56ComposedStory, profileID: UUID) -> Story }
```

---

## 4. Hat A: Codex (motor, içerik, P56 kapıları)

Codex her görev için kendi ayrıntılı TDD planını yazar. Burada teslim ve kabul şartı var.

- [ ] **C1. P56'nın açık doğrulama kapıları.** L/F legacy tanı kolları ve A0. Kabul: sonuçlar `REPORT.md` ve `verification-summary.json`'da; ilk deneme ve başarısız girdiler dahil.
- [ ] **C2. Çeşitlilik.** Hücre başına sabit 2 kitap sorunu. Hedef kitap sayısını Codex Batuhan'la yazar. Kabul: N1500 yeniden koşulur, tekrar oranı önce/sonra yan yana raporlanır.
- [ ] **C3. Destek kapsamı, bu sırayla:** (1) `ContentSafety` (güvenlik, ilk sırada), (2) konu (19 Kasım kararıyla konu adımı her yaşta var), (3) Masal ailem. Hatırlama, seri ve özel gün sonraki tur. Her biri için ya desteklenir ya `unsupportedReasons` açıkça söyler; sessizce düşürme yok.
- [ ] **C4. Sözleşme teslimi** (Bölüm 3): `P56Support`, `P56Engine.behaviorID`, `ContentSourceMetadata` tanıması, sabitlenmiş payload + SHA. Testler: `unsupportedReasons` ile `compose` aynı nedenleri verir; bozuk payload yüklenmez, güncele geri düşmez; legacy kayıtların çözümü değişmez (252 dosya, 0 değişim).
- [ ] **C5. Diğer yaş bantları** (3–4, 7–8, 9–10). C2 ve C3 kabul edilmeden başlamaz.

## 5. Hat B: Claude (uygulama entegrasyonu)

Claude bu görevler için `docs/superpowers/plans/` altında ayrıntılı TDD planı yazar. Hepsi `StoryRuntimeFlags.fiveFriendsPilot == false` iken bugünkü davranışı birebir korur.

### B1. P56 masalını kalıcı `Story`'ye çevirme

**Dosyalar:** Yeni `MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryMapper.swift`, test `MagicPaperTests/P56StoryMapperTests.swift`
**Kullanır:** `P56ComposedStory`, `P56Engine.behaviorID`. **Üretir:** `P56StoryMapper.story(from:profileID:) -> Story`.

- [ ] Testler: 8 sayfa, sayfa metinleri birebir aynı; `contentSource` P56 davranış kimliğini ve `payloadSHA256`'yı taşır; sayfalarda görsel anahtarı yok (görsel onaysız); çocuğun adı ve kimliği kayıtta bulunur ama log'a yazılmaz; kaydedilip geri okunan P56 masalı aynı kalır; eski bir `Story` JSON'u aynen decode/encode olur.
- [ ] Uygulama, testler, commit.

### B2. Paketlenmiş payload'ı yükleme

**Dosyalar:** Yeni `MagicPaper/StoryEngineBridge/Pilots/P56/P56BundledSource.swift`, test `MagicPaperTests/P56BundledSourceTests.swift`; gerekirse payload'ın kaynak olarak eklenmesi.
**Kullanır:** C4 payload + `P56PinnedSource.sha256`, mevcut `P56SnapshotStore`. **Üretir:** `P56BundledSource.load() throws -> P56SourceReference`.

- [ ] Testler: doğru payload yüklenir; bir byte değişirse hata verir, eski motora sessizce düşmez (yönlendirici bunu "legacy" ve nedenle karşılar); payload yoksa hata.
- [ ] Uygulama, testler, commit.

### B3. Yönlendirici

**Dosyalar:** Yeni `MagicPaper/StoryEngineBridge/StoryRuntimeRouter.swift`, test `MagicPaperTests/StoryRuntimeRouterTests.swift`
**Kullanır:** `P56Support.unsupportedReasons`, `P56BundledSource`. **Üretir:** Bölüm 3'teki `StoryRuntimeRouter`, `StoryRuntimeFlags`.

- [ ] Testler: bayrak kapalı → her istek `legacy`; bayrak açık + 5–6 yaş + desteklenen istek → `p56`; bayrak açık + Masal ailem seçili → `legacy`; bayrak açık + 3–4 yaş → `legacy`; payload bozuk → `legacy`; aynı istek iki kez aynı yönü verir.
- [ ] Uygulama, testler, commit.

### B4. Masal yazma yoluna bağlama

**Dosyalar:** `MagicPaper/StoryEngineBridge/OfflineStoryService.swift` (`compose` girişi, satır ~379 ve ~468: başa tek dal), test `MagicPaperTests/P56CompositionPathTests.swift`
**Kullanır:** B1–B3, `P56InternalService`.

- [ ] Testler: bayrak kapalıyken eski yol çıktısı değişmez (aynı tohum, aynı metin); `p56` yönünde masal P56'dan yazılır ve B1 ile kaydedilir; P56 `compose` reddederse eski yola düşülür ve neden kaydedilir (çocuk verisi olmadan).
- [ ] Uygulama, testler, commit.

### B5. "Masalda kimler olsun?" ekranı

**Dosyalar:** `MagicPaper/StoryEngineBridge/StoryChoiceSource.swift`, `MagicPaper/Screens/StoryCreation/CompanionStep.swift`, test `MagicPaperTests/CompanionStepChoicesTests.swift`
**Kullanır:** `P56Support.companionIDs`, mevcut `CompanionPortraitCatalog`.

- [ ] Testler: bayrak kapalı → liste bugünküyle aynı (ilk 3 kesmesi dahil); P56 yönünde beşin hepsi portreleriyle, sabit sırada; Masal ailem seçilince liste eski yola döner; seçili arkadaş yeni listede yoksa seçim temizlenir, başka arkadaşa çevrilmez.
- [ ] Simülatör kontrolü Bölüm 6'da (açık/koyu, en büyük Dynamic Type, SE/Pro Max, VoiceOver etiketi).
- [ ] Uygulama, testler, commit.

### B6. Seri ve hatırlama korumaları

**Dosyalar:** `MagicPaper/StoryEngineBridge/SeriesManager.swift`, `MagicPaper/StoryEngineBridge/StoryMemory.swift`, test `MagicPaperTests/P56GuardTests.swift`

- [ ] Testler: P56 masalına "devam et" önerilmez (P56 seriyi desteklemiyor); P56 masalı hatırlama girdisine girmez; rozet ve yıldız normal sayılır (masal okundu).
- [ ] Uygulama, testler, commit.

## 6. Hat C: görsel ve Hat D: son kapı

**Hat C (görsel, K4):** Batuhan `art-handoff.json`'dan ChatGPT ile çizer. Uygulamadaki bağlayıcı işi ayrı plan olur; sahibi K-A kararından sonra seçilir. A ve B hatlarını beklemez, onlar da onu beklemez.

**Hat D (son kapı, entegrasyon dalında, tek seferde):**
- [ ] `swift test --package-path StoryEngine` tam paket (1122+ test), uygulama testleri tam paket. Kırmızı varsa eski taban/yeni regresyon ayrımı yazılır.
- [ ] N1500 entegrasyon dalında yeniden; legacy 252 dosya 0 değişim.
- [ ] Simülatör: bayrak kapalı ve açık, CLAUDE.md doğrulama grep'leri ve ekran görüntüleri.
- [ ] Her hattın changelog kaydı entegrasyon dalında.
- [ ] Batuhan'a özet: neyin hazır olduğu, neyin olmadığı, yayın için açık kapılar (editoryal, görsel, çeşitlilik kabulü, yayın kararı).

---

## 7. Gözden kaçabilecek durumlar

1. **Bayrak kapalıyken davranış değişmesi.** B4 ve B5 testleri aynı tohumla eski çıktının birebir korunduğunu doğrular.
2. **Kaydedilmiş P56 masalının sonradan açılması.** Payload güncellense bile eski masal kendi kaydedilmiş sayfalarıyla açılır; B1 kaydet-geri oku testi ve C4 çözücü testi.
3. **Seçim ekranı ile yazılan masalın tutarsızlığı.** Ekran beşliyi gösterir ama masal eski motordan gelir. B3 ve B5 aynı `unsupportedReasons`'ı kullanır; B5'teki Masal ailem testi.
4. **Senkron ve eski uygulama sürümü.** Eski istemci P56 kaydını görürse bozmaz; `bd8001d`'deki sync koruması C4 testinde P56 kaydıyla da denenir.
5. **Gizlilik.** Yönlendirici ve geri düşme nedenleri log'a yazılırken çocuğun adı ve kimliği yazılmaz; B1 ve B4 testleri.

## 8. Bu planın yapmadıkları

- Kod, içerik ya da test değişmedi; test koşulmadı.
- 13 eski arkadaşın akıbeti, konuk/uzman modeli, deniz/uzay, yayın tarihi bu planın dışında.
- Bölüm 1'deki kararlar onaylandı; kod Codex'in sözleşme kabulünü bekler.
