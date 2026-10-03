# MagicPaper — Faz Planı

**23 Eylül 2026** · Grup 2 Dalga 2A yarıda kesildi (oturum limiti) · Bu plan oradan devam eder

**30 Eylül 2026 durumu:** Faz 0 ✅ · Faz 1 ✅ (yalnızca UI'daki ~24 `print` kaldı) · Faz 2.1 ✅ · Faz 3.1 ✅ ·
Faz 4 ✅ · Uygulama testleri 248/0, paket 647/18 (1 Ekim; 23'ten indi). Görselli masal henüz canlı değil —
bugün çocuğa giden metnin tamamı blueprint motorundan geliyor; Gemini/fal.ai yolundaki
Faz 2.2–2.3 işleri görselli masal açılmadan önceki çıkış koşuludur.

Fazlar **bağımlılık sırasına** göre dizildi, önem sırasına göre değil. Her faz bir
öncekinin doğrulanmış çıktısı üzerine kurulu. Faz atlanamaz.

---

## FAZ 0 — Yarım kalan işi gerçek yap ✅ *(30 Eylül'de kapandı)*

**Kapanış notu:** `Screens/`, `MagicPaperTests/`, `DesignSystem/`, `Helpers/`,
`StoryEngineBridge/` senkronize klasör — pbxproj'daki "0 referans" bunlar için target dışı
demek değildi; `PageTurn/` ve yeni testler zaten derleniyordu. Gerçekten dışarıda olan tek
grup `Services/Entitlements/` idi: pbxproj'a eklendi, testleri karantinadan döndü (15/15).
Target dışında dosya kalmadı.

Dört agent mid-edit kesildi ve **13 Swift dosyası diskte var ama Xcode target'ında yok.**

```
Services/Entitlements/     6 dosya   pbxproj: 0 referans
Screens/StoryReader/PageTurn/  6 dosya   pbxproj: 0 referans
MagicPaperTests/ yeni 3 test          pbxproj: 0 referans
Services/Persistence/      2 dosya   eklenmiş
```

Bu kod derlenmiyor, çalışmıyor, testleri koşmuyor. App build'in yeşil olması onlar
hakkında **hiçbir şey kanıtlamıyor.**

**Yapılacaklar**
1. Paket derlemesi ✅ temiz (`CharacterVersionSuccession`, `CharacterCopyVerification` dahil)
2. Her atıl dosya grubunu **tek tek** target'a ekle ve derle — hepsini birden ekleyip
   yüzlerce hatayla karşılaşma
3. Derlenmeyen veya yarım kalan grubu **karantinaya al**, tamamlanana kadar target dışında tut
4. Yeni üç testi target'a ekle ve koştur
5. Paket testlerinde taban çizgisi **23 hata**; artmadığını doğrula

**Kapanış ölçütü:** app build yeşil + paket testleri ≤23 hata + hangi dosyanın neden
target dışında olduğu yazılı.

---

## FAZ 1 — Güvenlik ve çocuk gizliliği

Ürün özelliği değil, borç kapatma. Faz 0'dan bağımsız başlayabilir.

| # | İş | Durum |
|---|---|---|
| 1.1 | Gemini anahtarının log'dan çıkarılması | ✅ **yapıldı** (`AIService:319`) |
| 1.2 | RevenueCat anahtarının log'dan çıkarılması | ✅ **yapıldı** (`MagicPaperApp:71,75,76`) |
| 1.3 | Repodaki `sk_` anahtarının iptali | ⛔ **kullanıcı işi** — kod düzeltmesi git geçmişini temizlemez |
| 1.4 | P1 sınıfı 33 `print()` — çocuk adı/yaşı basanlar | ✅ çocuk adı/yaşı, prompt, başlık, fotoğraf ve görsel URL'leri log'dan çıktı |
| 1.5 | `os.Logger`'a geçiş (bugün 441 `print`, 0 Logger) | ✅ Services + StoryEngineBridge (1 Ekim): 296 satır `Logger`'a, 49 süs satırı düştü; yaş `privacy: .private`. Kalan: Screens/Views'da ~24 `print` (UI oturumlarının dosyaları) |
| 1.6 | `deleteProfile` cascade — çocuğun hikâyeleri silinmiyor | ✅ masallar da siliniyor (`Story.isSolelyOwned`), onay diyaloğu eklendi |
| 1.7 | Firebase silme yolu (kod tabanında hiç yok) | ✅ `deleteUploadedImage` — üretim bitince; Storage kurallarının silmeye izin verdiği **doğrulanmadı** |

**Not:** çocuk fotoğrafı bugün hiç toplanmıyor (`ImagePicker` yalnızca erişilemez test
ekranlarında). Boru hattı **canlı kullanıcı verisi olmadan** temizlenebilir — şimdi ucuz.

---

## FAZ 2 — Çocuğa giden içeriğin doğrulanması

**Bugün hiçbir doğrulama yok.** Sekiz validator yazılı ve test edilmiş, ama
`StoryEngineContainer` hiç inşa edilmediği için hiçbiri erişilebilir değil. Canlı Gemini
çağrısı `safetySettings`, canlı fal.ai çağrısı `enable_safety_checker` göndermiyor.

1. ✅ `ComposedStory.isClean` guard'ını üretim köprüsüne ekle (`OfflineStoryService.compose`, `Failure.defectiveDraft`) — bugün yerine konmamış
   `{{discovery.name}}` sessizce okuyucuya gidebiliyor. **Tek guard, en yüksek getiri.**
2. `StoryEngineContainer`'a tüketici bağla → validator zinciri canlansın
3. Canlı AI çağrılarına safety parametrelerini ekle

Bir çocuk uygulaması için bu faz Faz 3'ten önce gelir.

---

## FAZ 3 — Persistence (D4)

Faz 0 bunu kısmen taşıyor (`Services/Persistence/` yarım hâlde).

1. ✅ *(zaten düzeltilmiş: `LibraryMigration.quarantineOversizedLegacyBlob` kopyalar, doğrular, silmez)* `migrateOldStoriesIfNeeded()` (`SGM:939`) 4 MB üstünde
   `UserDefaults["stories"]`'i **yedeksiz siliyor** — göçün okuyacağı veri yok olabilir
2. `FileStores`'un üç sessizliği: `save` sessizce "başarılı", `load` sessizce atlıyor,
   `FileProtection` hiç yok
3. Göç sırası **zorunlu:** yaz → doğrula → işaretle → beklet → sil.
   5. adım 1. adımdan **önce yazılmalı**
4. `CharacterVersionID` **kopyalanmalı, yeniden inşa edilmemeli** — yoksa çocuğun görsel
   kimliği kalıcı kayar. Bugün pinli kitap yok → risk şu an sıfır, köprü canlanınca yüksek
5. `mp_readDays`/`mp_readSeconds` profil kapsamına alınmalı (çok çocuklu ailede paylaşılıyor)

**K1 çözüldü:** saklanan hikâyeler üretilmiş metni tutuyor, seed'den yeniden üretilmiyor.
Göç sırasında içerik yeniden üretilmeyecek, sadece taşınacak.

---

## FAZ 4 — Tek kanonik üretim yolu (D1 Dalga 0) ✅

`createCustomStory` **kaldırılmıyor** — hâlâ tek illüstrasyonlu yol.

1. ✅ UI dikişi: `StoryEngineBridge/StoryChoiceSource.swift` — `StoryChoiceSource` protokolü,
   `StoryIdeaChoice`/`CompanionChoice`, sağlayıcının adı yalnızca `StoryChoiceSources.current`'ta.
   UI'da `import StoryEngine` kalmadı
2. ✅ `CompanionSymbolTests` + `AgeBandCoverageTests` protokole karşı yeniden yazıldı
3. ✅ Yaş zaten vardı (`ageBand`); zamir maddesi **kapatıldı** — Türkçede zamir cinsiyetsiz
4. ✅ Ölü kod `Retired/`'a taşındı (derlenmez, geri alınabilir)
5. ✅ `TestOfflineTemplateStoryProvider` (+ `TurkishSuffixResolver`) ve `DevStoryTestView`
   `Retired/`'a taşındı. Kalan aday: `FirebaseTestView` + `ImagePicker` (yalnızca kendi preview'ı)

---

## FAZ 5 — Entitlement (monetization)

**Sahip (1 Ekim, kullanıcı kararı):** "Tasarım sistemi altyapısı" oturumu. 5.1 ✅ (Faz 0'da target'a alındı).

Faz 0'da karantinadan çıkarsa devam eder. `isPremium` 19 kullanım / 10 dosya,
çoğu view'da — yani entitlement kararı bugün UI'da veriliyor.

1. `Services/Entitlements/` dosyalarını target'a al ve derle
2. Çağrı yeri taşıma planını uygula (view'lar Faz 6'nın alanı, koordineli)
3. Entitlement kontrolü client durumuna güvenmemeli

---

## FAZ 6 — Ebeveyn deneyimi ve okuyucu

1. `MPStreak` semantiği: reader'ın bıraktığı `markReadingSession(_:)` (bir çevrilmiş
   sayfa **veya** 30 sn) — Faz 0'da target'a girip test edilecek
2. `PageTurn/` 6 dosya — **kapsam dışıydı**, istenmedi. Değerlendir: tut, karantinaya al
   veya sil
3. Merkezi yükleme ve hata yüzeyi yok (`errorMessage` üç ekranda ayrı çiziliyor)
4. 54 `MPIcon` çağrısı 17 ayrı boyut kullanıyor

---

## FAZ 7 — İçerik kapsaması

1. ✅ **`sea+dolphin+shell` matris satırı emekliye ayrıldı** (1 Ekim, kullanıcı kararı).
   `MatrixCoverageTests.retiredSeaRow` olarak negatif örnek kalıyor; içerik katalogda.
   Düzeltme: bu satır 23 hatanın tek kök nedeni **değildi** — yalnızca matris testlerini
   kırıyordu. Kalan paket hatalarının ayrı ayrı incelenmesi gerekiyor (bkz. 7.4).
2. Yaş bantları: uygulama 5-7/8-10/11-12 sunuyor, korpusta yalnızca 3-4 ve 5-6 var.
   `suits(age: 9)` → **0 fikir**
3. `visual_catalog.json` düzeltmesi + golden fixture yenilemesi **tek commit'te**
   (hazır diff: `MagicPaper_Illustration_System.md` §3.4)
4. Kalan 18 paket hatası (1 Ekim): `PilotBlueprintTests` (8), `MatrixCoverageTests.testDiscoveryRecruitment…` (4),
   `OfflineCompositionTests` (4), `OfflineDeterminismTests` (1), `SettingAxisTests` (1). Matris satırıyla ilgisiz;
   çoğu pilot blueprint ve katalog değiştikten sonra eskimiş beklentiler gibi görünüyor — her biri için
   "test mi eskidi, içerik mi bozuldu" ayrımı yapılmalı. Taban çizgisi artık **18**.

---

## FAZ 8 — İllüstrasyon kimliği (D1 Dalga 1)

Faz 2 ve 4 tamamlanmadan başlayamaz.

1. `FalImageProvider`'ı kanonik yap, `VisualSystem` kısıtları prompt'u üretsin
2. Karakter kimliğini görsel zincire bağla → İlke 5 ihlali kapanır
3. Ancak ondan sonra `createCustomStory` + `generateImagesForStory` +
   `AIService` imagePrompt şablonları emekliye ayrılsın

**Bugünkü ihlal:** `FalAIImageGenerator:21` her görsele
`"3d pixar style render, cute, vibrant colors, 8k"` ekliyor; `AIService:99/:828`
çocuğun görünüşünü her sayfada bir dil modeline yazdırıyor.

---

## Sıra bağımlılıkları

```
FAZ 0 ─┬─→ FAZ 1 (bağımsız, paralel olabilir)
       ├─→ FAZ 2 ──→ FAZ 8
       ├─→ FAZ 3 ──→ FAZ 4 ──→ FAZ 8
       ├─→ FAZ 5 ──→ FAZ 6
       └─→ FAZ 7 (bağımsız, ama ürün kararı bekliyor)
```

`StoryGenerationManager.swift` Faz 3 ve Faz 4'te tek sahipli olmalı — asla eşzamanlı
iki agent'a verilmemeli.
