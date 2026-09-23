# MagicPaper — Faz Planı

**23 Eylül 2026** · Grup 2 Dalga 2A yarıda kesildi (oturum limiti) · Bu plan oradan devam eder

Fazlar **bağımlılık sırasına** göre dizildi, önem sırasına göre değil. Her faz bir
öncekinin doğrulanmış çıktısı üzerine kurulu. Faz atlanamaz.

---

## FAZ 0 — Yarım kalan işi gerçek yap *(şu an burada)*

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
| 1.4 | P1 sınıfı 33 `print()` — çocuk adı/yaşı basanlar | açık, `SGM:347`/`:444` dahil |
| 1.5 | `os.Logger`'a geçiş (bugün 441 `print`, 0 Logger) | açık |
| 1.6 | `deleteProfile` cascade — çocuğun hikâyeleri silinmiyor | açık |
| 1.7 | Firebase silme yolu (kod tabanında hiç yok) | açık |

**Not:** çocuk fotoğrafı bugün hiç toplanmıyor (`ImagePicker` yalnızca erişilemez test
ekranlarında). Boru hattı **canlı kullanıcı verisi olmadan** temizlenebilir — şimdi ucuz.

---

## FAZ 2 — Çocuğa giden içeriğin doğrulanması

**Bugün hiçbir doğrulama yok.** Sekiz validator yazılı ve test edilmiş, ama
`StoryEngineContainer` hiç inşa edilmediği için hiçbiri erişilebilir değil. Canlı Gemini
çağrısı `safetySettings`, canlı fal.ai çağrısı `enable_safety_checker` göndermiyor.

1. `ComposedStory.isClean` guard'ını üretim köprüsüne ekle — bugün yerine konmamış
   `{{discovery.name}}` sessizce okuyucuya gidebiliyor. **Tek guard, en yüksek getiri.**
2. `StoryEngineContainer`'a tüketici bağla → validator zinciri canlansın
3. Canlı AI çağrılarına safety parametrelerini ekle

Bir çocuk uygulaması için bu faz Faz 3'ten önce gelir.

---

## FAZ 3 — Persistence (D4)

Faz 0 bunu kısmen taşıyor (`Services/Persistence/` yarım hâlde).

1. ⚠️ **ÖNCE:** `migrateOldStoriesIfNeeded()` (`SGM:939`) 4 MB üstünde
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

## FAZ 4 — Tek kanonik üretim yolu (D1 Dalga 0)

`createCustomStory` **kaldırılmıyor** — hâlâ tek illüstrasyonlu yol.

1. UI dikişi: `StoryCreationFlow`/`StoryIdeaStep`/`CompanionStep` bugün `import StoryEngine`
   yapıp `OfflineStoryService`'i adıyla çağırıyor — UI provider'ı biliyor, D1'e aykırı
2. `CompanionSymbolTests` + `AgeBandCoverageTests` protokole karşı **yeniden yazılacak**, silinmeyecek
3. `OfflineStoryIntent`'e yaş ve zamir ekle — bugün yalnızca `childName: String`
4. Ölü kod: `FalImageGenerator`, `FalImageService`, `FalAITestView` (üçü de 0 referans)
5. `TestOfflineTemplateStoryProvider` + `DevStoryTestView`'ı üretimden çıkar
   (test mock'ları korunacak); `SGM:1322`'deki sabit geliştirici yolu da böylece gider

---

## FAZ 5 — Entitlement (monetization)

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

1. **`sea+dolphin+shell` matris satırı** hiçbir blueprint'e oturmuyor — 15 kırık testin
   tek kök nedeni. İki blueprint tek trait uzağında ama ikisi de anlatısal zorlama olur.
   **Ürün kararı gerekiyor:** su ailesi için blueprint mi, satır emekliliği mi?
2. Yaş bantları: uygulama 5-7/8-10/11-12 sunuyor, korpusta yalnızca 3-4 ve 5-6 var.
   `suits(age: 9)` → **0 fikir**
3. `visual_catalog.json` düzeltmesi + golden fixture yenilemesi **tek commit'te**
   (hazır diff: `MagicPaper_Illustration_System.md` §3.4)

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
