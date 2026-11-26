# V4 Art Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** V4 metinlerini değiştirmeden kaynak izli, çevrimdışı kullanılabilir görsel havuzu hazırlamak.

**Architecture:** Kimlik çizimleri, durumlu nesneler ve sınırlı mekân parçaları ayrı varlıklardır. Tam sayfa kaynak incelemesi görsel kullanım yetkisini belirler; kaydedilen kitap kararı yeniden seçilmez. Mevcut V1–V3 pinleri korunur.

**Tech Stack:** JSON kaynak manifesti, yerleşik ChatGPT imagegen; sonraki uygulama aşamasında mevcut Swift art modelleri.

## 1. Kaynak tabanı — tamamlandı

- [x] Motor dalının V4 payload SHA değerini `c06a5dfc3f586eae5d837926cab915be6b22480c20e11e02c9ea7fd5894990d6` olarak doğrula.
- [x] `design-handoff/proposals/2026-11-26-v4-art-library/inventory.json` içine 90 kitabın 720 sayfasını kaynak metni, template SHA, canonical kimlikler, semantics ve artHandoff ile kaydet.
- [x] Her template SHA değerini UTF-8 metninden yeniden hesapla; 720/720 eşleşmesini doğrula.
- [x] Her mod/arkadaş hücresinde kimliğe göre ilk kitabı seçerek 15 inceleme kitabı tanımla. Runtime seçimlerini değiştirme.

## 2. Beş V4 kimlik çizimi

Files: `design-handoff/proposals/2026-11-26-v4-art-library/assets/`, `GENERATION_RECORD.json`.

- [x] Onaylı marka referansını ve önceki beş tekil karakter çizimini açıp incele.
- [x] Her karakteri ayrı şeffaf PNG olarak imagegen ile üret; onaylı imza ayrıntılarını README tablosundan al. Önceki dosyaların üzerine yazma.
- [ ] Yüz, anatomi, tek gövde, aksesuar, saydam kenar ve beyaz/gece zemini incelemesini yap; reddedilen sürümleri kayıttan silme.
- [x] Tam prompt, kullanılan referans yolları, üretim çıktısı, seçilen dosya SHA ve inceleme sonucunu kaydet. Kimlik pozu, bütün sayfalarda kullanım onayı değildir.

## 3. 15 kitaplık görsel senaryo incelemesi

Files: aynı klasörde `pilot-page-review.json`, `PRODUCTION_QUEUE.md`.

- [x] Manifestteki 15 kitabın 120 sayfasını kitap sırasıyla oku. Her sayfaya mevcut/hatırlanan/hedeflenen konu, eylem, nesne konumu ve ihtiyaç duyulan çizimi yaz.
- [x] Uyku için uyanık-dinleme, dinlenme ve gerçek uyku durumlarını ayır. Çanta askıdaysa takılı karakter çizimi seçme.
- [x] Öğrenmede damla ve yaprak görünümünü olayın önce/sonra durumuna göre ayır; benzer genel nesneyi kanıt yerine kullanma.
- [x] Macerada işaret parçalarının ayrı/birleşmiş/yönlendirilmiş hâllerini ve karakter katkısını ayır.
- [x] Açılış/orta/kapanış için üç anlamlı anı hedefle; kaynak desteklemiyorsa sayfayı metin bırak ve gerekçesini yaz. Metni veya seed’i görsel için değiştirme.
- [x] Tekrarlanabilir çizim ihtiyaçlarını aynı canonical konu + görünür durum + eylem + aksesuar konumu anahtarında birleştir. Pilot üretim sayısını bu listeden hesapla; tüm 90 kitap için genelleme yapma.

## 4. Üretim ve yayın devir paketi

- [ ] Öncelik sırasıyla gerekli pozları, nesne durumlarını ve iki mekân için sınırlı parçaları ayrı görseller üret. Her üretimde marka ve ilgili kimlik referanslarını kullan.
- [ ] `pilot-page-review.json` içinde seçilen asset revision ve tam kaynak/template SHA değerini eşleştir. Görsel incelemesi tamamlanmadan assetRuleApproval açma.
- [ ] Uygulama sahibine kaynak paket SHA, eşleşme listesi, art revision ve eski pinleri koruma koşullarıyla teslim et. Mevcut V4 mapper/binder arayüzünü o dalın güncel kodundan doğrulamadan yeni model alanı ekleme.
- [ ] Yeni runtime eşlemesi için kaynak SHA değişikliği, anı/olumsuzluk, yanlış aksesuar konumu ve eski kitap pinlerinin korunması testlerini uygulama işinde tanımla; kontrolleri AGENTS gereği son doğrulama penceresinde bir kez çalıştır.
- [ ] Tüm 90 kitap için görselli kitap/sayfa sayısını ve açılış/orta/kapanış dağılımını raporla. Görsel garantisi ancak bu ölçümle değerlendirilsin; diğer yaşlara veya sonraki dalgalara genelleme yapma.

## Kabul ölçütleri

Metin ve kaynak kimlikleri aynı; eski kitaplar aynı; üretim API’si gerekmiyor. Her yayınlanan eşleme incelenmiş sayfa ve belirli asset revision taşıyor. Anı nesneleri mevcut sahneye taşınmıyor. Beş arkadaş aynı kimliği koruyor. Eksik görselde metin sayfası okunabilir kalıyor.
