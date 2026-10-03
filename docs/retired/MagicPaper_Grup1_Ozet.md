# MagicPaper — Grup 1 Özeti

**18 Eylül 2026** · 7 agent paralel · Entegrasyon tamamlandı · Grup 2 başlatılmadı

Bu dosya, sekiz ayrı dokümanın tek sayfalık özeti. Detay için her bölümün sonundaki
kaynağa bak.

---

## 1. Nerede duruyoruz

| | Sonuç |
|---|---|
| App build | ✅ **BUILD SUCCEEDED** |
| Paket testleri | ⚠️ **761 test, 38 hata / 24 distinct** |
| Değişen dosya | 33 (kod 10 · içerik 3 · test 4 · doküman 8 + arşiv) |
| Satır | +1391 / −745, artı 662 satır yeni test |

**Test komutu:** düz `swift test` bu repoda codesign hatasıyla düşüyor.
```bash
cd MagicPaper/StoryEngine && xattr -cr Sources Tests .build && swift test --build-system native
```

---

## 2. En önemli keşif

**Motor doğru kurulmuş, ama üretimde çalışmıyor.**

StoryEngine paketi (4 target, 761 test) Xcode'a bağlı ve hikâye metnini gerçekten
üretiyor. Ama paketin *diğer yarısı* — orchestrator, 8 validator, karakter kimliği,
görsel stil sistemi — `StoryEngineContainer` üzerinden erişiliyor ve **o container hiç
inşa edilmiyor**. Tek referansı kendi dosyası.

Pratik sonucu üç yerde görünüyor:

- **Çocuğun kimliği bugün bir `String`.** Canlı akışta `CharacterProfile` hiç
  yaratılmıyor. `OfflineStoryIntent` yalnızca `childName` taşıyor.
- **Çocuğa giden içeriğin önünde hiçbir doğrulama yok.** 8 validator da yazılmış ve
  test edilmiş, hiçbiri erişilebilir değil. Canlı Gemini çağrısı `safetySettings`,
  canlı fal.ai çağrısı `enable_safety_checker` göndermiyor.
- **İllüstrasyonlar VisualSystem'e hiç uğramıyor.**

---

## 3. Acil — kod işi değil, senin işin

### 3.1 RevenueCat secret key repoda ve git geçmişinde
`REVENUECAT_API_KEY_FIX.md` içinde 32 karakterlik gerçek `sk_` anahtarı, üç satırda.
Commit `4101e29`'da mevcut. `.gitignore` markdown'ı kapsamıyor.
→ **Anahtarı RevenueCat panelinden iptal et.** Dosyadan silmek yetmez.

### 3.2 Gemini API anahtarı cihaz loguna basılıyor
`AIService.swift:314` endpoint'i `?key=\(apiKey)` ile kuruyor, `:319` `print` ediyor.
Repoda 5 `#if DEBUG` var, hiçbiri log sarmıyor → **release'de de basılıyor.**
→ **Anahtarı döndür.**

---

## 4. Çocuk güvenliği ve gizlilik

| # | Bulgu | Yer |
|---|---|---|
| 1 | Güvenlik doğrulama hattı tamamen ölü | §2 |
| 2 | Ad ve yaş doğrudan loga: `print("🎬 Child: \(childName), Age: \(age)")` | `SGM:347`, `:444` — `:347` canlı yolda |
| 3 | `deleteProfile` o çocuğun hikâyelerini silmiyor (`Story.childProfileID` var, cascade yok) | `ProfileManager` |
| 4 | Firebase silme yolu hiç yok — yüklenen görsel kalıcı | tüm kod tabanı |
| 5 | `PRIVACY_POLICY.md` 30 günlük otomatik silme yazıyor, bunu yapan kod yok | — |
| 6 | Hiçbir yerde `FileProtection` yok, üç yazma noktası da çıplak `write(to:)` | — |
| 7 | `stories.undecodable.*` yedekleri sınırsız, hiç temizlenmiyor | `SGM` |

**441 `print()`** (app 430 + paket 11), `os.Logger` **0**.
Sınıflandırma: P0 anahtar sızdıran 3 · P1 çocuk verisi 33 · P2 türetilmiş 44 ·
P3 operasyonel 156 · güvenli 205. Dosya:satır listesi hazır, Grup 2 iş emri olarak sıralı.

**Hafifletici:** çocuk fotoğrafı bugün hiç toplanmıyor. `ImagePicker` yalnızca erişilemez
test ekranlarında; `createCustomStory` çocuğun yüzünü değil `MPAvatarRenderer` harf
avatarını gönderiyor. Yani fotoğraf boru hattı **canlı kullanıcı verisi olmadan**
temizlenebilir — şimdi ucuz, sonra pahalı.

→ `docs/MagicPaper_Privacy_Architecture.md` (699 satır)

---

## 5. Tasarım dili ihlali — üretimde

`FalAIImageGenerator.swift:21` her görsele sabit ekliyor:

> `3d pixar style render, cute, vibrant colors, 8k`

Bu, CLAUDE.md İlke 9'un "Avoid" listesinin tam ortası. Ayrıca `AIService.swift:99` ve
`:828` çocuğun görünüşünü **her sayfada bir dil modeline** yazdırıyor — İlke 5'in
doğrudan ihlali.

Motor tarafı temiz: `PromptConstraintCompiler` görünüş cümlelerini yalnızca
`identity.descriptors`'tan üretiyor.

**İyi haber:** D1 ile `createCustomStory` gidince bu ihlallerin ikisi de kendiliğinden
kapanıyor.

→ `docs/MagicPaper_Illustration_System.md` (515 satır)

---

## 6. Tamamlanan iş

### D3 — Schema 2 kanonik ✅
- `pilot_library_v1.json`: 6 → **15 blueprint**, hepsi `schemaVersion: 2`
- **RETIRE 12** — v2 blueprint'lerinin on ikisi de aynı yayın kopyasıydı ve
  `isBeatAuthored == false` olduğu için `BlueprintSelector` onları **hiç seçemiyordu.**
  Anlatı kaybı yok; `docs/retired/` altında geri alma talimatıyla duruyorlar.
- **MERGE 5 · KEEP 1 · YENİ 9.** Pilot id'leri korundu. `storyIdeas` (4) korundu.
- Schema 2 dışı üretim blueprint'i: **0**

### Determinizm ✅
İki gerçek kusur bulunup düzeltildi: `DeterministicValidators` ham `Dictionary`,
`CatalogBlueprint` ham `Set.intersection` üzerinde yürüyordu.

Altındaki tespit önemli: **Swift `Hashable`'ı süreç başına tohumluyor.** Mevcut
`testSameIntentProducesTheSameBook` bu kaymayı hiçbir zaman yakalayamazdı. Yeni 7 test
üç ayrı süreçte koşturup sonuçları literal sabitliyor.

### Tasarım sistemi ✅
20 ham hex token'a taşındı. Değişmez kural: ham `Color(hex:)` yalnızca `MP.Palette`
içinde. Yol üstünde gerçek bir hata düzeltildi — avatar paleti üç yerde farklıydı
(8 / 6 / 6 renk), aynı çocuk hangi bileşenin çizdiğine göre farklı renk alabiliyordu.

### Karakter motoru ✅
Toleranslı çözümleme eklendi (`init(from:)` varsayılanları, `encode` değişmedi → geriye
dönük uyumlu). 24 yeni test (42 → 66).

---

## 7. Senin kararını bekleyen üç şey

### K1 — Seed drift ⚠️ Grup 2'nin önkoşulu
5 MERGE blueprint'in `requires`/`forbids`'i değişti → seçim havuzu değişti. Sabit bir
seed artık deniz+yunus yerine orman+tavşan çözüyor, başlık değişiyor.

**Cevaplanması gereken:** `UserDefaults["stories"]` blob'u üretilmiş **metni** mi
saklıyor, yoksa yalnızca **seed**'i mi? Metni saklıyorsa mevcut kullanıcılar etkilenmez.
Seed'i saklıyorsa kitapları değişir. **Doğrulanmadı. D4 bundan önce başlamamalı.**

### K2 — Raporlanmadan silinen üç dosya
Oturum başındaki envanterde vardı, şimdi yok, hiçbir agent sildiğini söylemedi:

```
PremiumComponents.swift    874 satır
TextStoryLibraryView.swift 244
TextStoryViewerView.swift  281
```

Üçü de `git show HEAD:<yol>` ile kurtarılabilir. Üçü de bağımsız olarak ölü kod tespit
edilmişti, build silindikten sonra da yeşil. Silme muhtemelen doğru ama onaysız.
→ Kalsın mı, geri mi alınsın?

### ~~K3 — CLAUDE.md İlke 7~~ ✅ ÇÖZÜLDÜ
`MPStreak`: **RETAINED — okuma sürekliliği mekanizması.** İlke 7 yeniden yazıldı,
`.claude/agents/parent-ux.md` güncellendi, mimari denetim
`docs/MagicPaper_Streak_System.md` içinde belgelendi.
Bulunan gerçek hata: `SettingsView:462` "tüm veriyi sil" `mp_readSeconds`'i bırakıyor.

---

## 8. 38 kırık testin kovaları

| Kova | Adet | Sahip |
|---|---|---|
| Bayat sabitleme (sayım / fingerprint) | ~11 | story-engine |
| Seed drift | 3 | **K1 kararı** |
| Motor / içerik uyuşmazlığı | ~10 | story-engine + content-library |

İki hata **üretim kaynağından** geliyor, testten değil: `BlueprintSelector.swift:119`,
`OfflineSelection.swift:181`. Bunlar bayat pin değil, gerçek uyuşmazlık.

Bilinen iki sebep:
- `BlueprintSelector.admissible` `requires.thresholdKind`'ı denetlemiyor (motor açığı)
- `setting_coral_sea_001` sahipsiz kaldı — 14 blueprint'in hepsi setting'e kısıt koyuyor,
  mercan denizi sadece `hasWater + isOpen` bildiriyor. Ölçüldü: `canConceal` eklemek
  38 → 35 yapıyor.

---

## 9. Grup 2 önkoşulları

1. **K1 kararı** — seed drift, D4'ten önce
2. **38 testin sıfırlanması** — kırmızı ağaç üzerine ameliyat yapılırsa hata atfı imkânsız
3. **K2 kararı** — silinen üç dosya
4. **Anahtar döndürme** (§3)
5. **`TestPlan.xctestplan`** paketin 761 testini içermiyor — Xcode/CI bunları hiç koşmuyor
6. **`.build` izolasyonu** — bu turda agent'lar aynı dizini paylaşıp birbirinin
   mid-edit hâlini test etti, hayalet kırmızı gördü. Grup 2'de `--scratch-path` ile ayır.

### Sahiplik (çakışmasız)

| Agent | Alan |
|---|---|
| story-engine | `StoryGenerationManager.swift` **tek sahip**, D1 adım 1-5 |
| character-system | `CharacterEngine/` + `ProfileManager` devri |
| parent-ux | onboarding, home, akış |
| reader | `Screens/StoryReader/` |
| library-memory | D4 persistence — `StoryGenerationManager`'ı **D1'den sonra** devralır |
| monetization | entitlement soyutlaması (`isPremium` 19 kullanım / 10 dosya) |

**D1 tek adımda yapılamaz.** `createCustomStory` kaldırılırsa illüstrasyonlu masal
üretme tamamen kaybolur; ikamesi (`MPAppState:79-85`'te niyet olarak yazılı) henüz yok.
Dalga 0 (bugün güvenli: ölü kod silme, `isClean` guard, test planı, UI dikişi)
Dalga 1'den (illüstrasyon ikamesine bağlı) ayrılmalı.

---

## 10. Ayrıca bilinmesi gerekenler

- **Yaş hikâye üretimine hiç girmiyor.** `BlueprintSelector` yaşa göre filtrelemiyor.
  Uygulama 5-7 / 8-10 / 11-12 sunuyor, korpusta yalnızca 3-4 ve 5-6 var.
  Ölçüldü: `suits(age: 9)` → **0 fikir**.
- **`ComposedStory.isClean` üretimde hiç çağrılmıyor** — 10 test dosyasında assert
  ediliyor, sıfır üretim tüketicisi. Yerine konmamış `{{discovery.name}}` okuyucuya
  gidebiliyor. Düzeltmesi bridge'de tek guard.
- **`CharacterVersionID` taze UUID** — D4 migration'ı sürümleri kopyalamalı, yeniden
  inşa etmemeli; aksi hâlde çocuğun görsel kimliği kalıcı kayar. Bugün pinli kitap yok,
  yani risk **bugün sıfır, köprü canlanınca yüksek.**
- **`migrateOldStoriesIfNeeded()` (SGM:939)** 4 MB üstünde `UserDefaults["stories"]`'i
  **yedeksiz siliyor.** D4'ten önce kapatılmalı.
- **`FalImageGenerator`, `FalImageService`, `FalAITestView`** — üçü de ölü, bugün
  silinebilir, hiçbir şeyi beklemiyor.
- **Eski `docs/ARCHITECTURE_AUDIT.md` eskimiş** — merkezi iddiası ("paket Xcode'a bağlı
  değil") artık yanlış. Yerini `docs/MagicPaper_Architecture.md` aldı.

---

## Kaynaklar

| Satır | Dosya |
|---|---|
| 272 | `docs/MagicPaper_MultiAgent_Status.md` — tam entegrasyon raporu |
| 825 | `docs/MagicPaper_Architecture.md` — tek doğru mimari referans |
| 699 | `docs/MagicPaper_Privacy_Architecture.md` |
| 515 | `docs/MagicPaper_Illustration_System.md` |
| 466 | `docs/MagicPaper_Character_System.md` |
| 435 | `docs/MagicPaper_Story_Engine_Plan.md` |
| 408 | `docs/MagicPaper_Content_Library.md` |
| 250 | `docs/MagicPaper_Design_System.md` |
| 165 | `docs/MagicPaper_Streak_System.md` — MPStreak denetimi, 10 soru, 6 bulgu |
| — | `docs/retired/retired_blueprints_2026-09-18.json` |
