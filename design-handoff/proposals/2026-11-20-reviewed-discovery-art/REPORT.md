# İncelenmiş görsel eşleştirme: gümüş çan

21 Kasım 2026. Kullanıcının onayladığı ilk dar uygulama dilimi.

## Sonuç

Yeni yazılan 5–6 yaş masallarında, elle incelenmiş beş `notice_anomaly` kaynağından biri kanonik `object_bell_001` nesnesini anlatıyorsa, paketlenmiş gümüş çan çizimi sayfaya bağlanır. Sayfaya sonradan eklenen 38 hatırlama satırı da tek tek incelendi; yalnız bu izole nesne çizimi için nötr kabul edildi. Eşleme sözcük aramasıyla değil gerçek motor çıktısının sıralı kaynak parçalarıyla yapılır.

Kaydedilen kitap sayfası görsel dosyasını, sürümünü, SHA-256 özetini ve bağlama kararını taşır. Yeniden açılışta yeni görsel seçilmez. Metin, satır kimliği, seed ve seçim dağılımı değiştirilmedi; eski kitaplara görsel eklenmedi. Çocuk ve Ragi kimliklerine dokunulmadı. Çalışma sırasında API çağrısı yoktur.

## Claude tesliminin alınması

`anlati-provenance` dalındaki `c742ea71080e73527fb29d47600acb0acdf62beb` kaynakları, paylaşılan günlük hariç 206 dosyalık patch olarak uygulandı; Git merge yapılmadı. İçe alınan dosyalar kaynak commit ile karşılaştırıldı. Tek kasıtlı ek fark `StoryPageArt` içinde yeni politika sürümünün kabul edilmesidir.

`StoryPage.provenance`, mapper aktarımı, motor kaynak parçaları, görsel anlam şeması, 193 şablonun otomatik etiketleri ve ilgili testler bu teslimden gelir. `visualReview: auto` etiketleri korunur; tüm havuz elle incelenmiş sayılmaz. App tarafındaki 43 kaynaklık inceleme kaydı `docs/research/2026-11-20-reviewed-bell-source-decisions.json` içindedir.

## Uygulama kuralları

- `ReviewedDiscoveryArtPolicy`: tam manifest özeti, kaynak/template kimliği ve metin özeti; kanonik keşif nesnesi özellikleri; tek beat ve isteğe bağlı tek son hatırlama parçası.
- `ReviewedDiscoveryArtBinder`: motor ve uygulama sayfalarının metni, sayısı ve sırası aynı olmalı. Eksik slot, nakarat, ek beat, bilinmeyen kaynak veya bağlam varsa yeni eşleme yapılmaz. Mevcut görselin üzerine yazılmaz.
- Aile, özel gün ve seri bağlamları bu dilimde kapsam dışıdır. Kaydedilmiş provenance verisinin toleranslı decode sonucu bütün sayfanın kanıtı olarak kullanılmaz.
- Önceki v1 eşleme kuralları korunur. Yeni pin aynı `StoryPageArt` şemasında politika 2 kullanır; bilinmeyen politika 3 reddedilir.
- Çan PNG verisi `.mpart` olarak paketlenir; Xcode PNG optimizasyonunun hash değiştirmesi önlenir. Manifest ve dosya özeti, ImageIO decode ve boyut sınırı doğrulanır.

Manifest SHA-256: `5a39b3e776a6a0c7cdd70c7f8eb03743a242a58a1fd5045f94e1bee1763d8af4`.
Çizim SHA-256: `135019d641cd0c30077dba84b89485c0ccc247d17369f2699250a17eabff4a4d`.

## Doğrulama

Bağımsız kod incelemesi bloklayıcı bulmadı. Testler koddan önce yazıldı; AGENTS gereği ara RED çalıştırması yapılmadı.

- Motor: native build sistemiyle seçili provenance/visual testleri **11 test, 0 hata**. Log: `/private/tmp/MagicPaper-reviewed-bell-engine-native.log`.
- Uygulama: **96 test, 94 başarılı, 1 atlanan, 1 başarısız**. Log: `/private/tmp/MagicPaper-reviewed-bell-app-pass.log`. Genel çalıştırma `TEST FAILED` sonucuyla bitti.
- Yeni görsel politika testleri **6/6**, sayfa provenance testleri **4/4**, mevcut spot binding **6/6**, asset resolver **6/6** geçti. Gerçek motor çıktısı, hatırlama satırı, kayıt roundtrip ve reader dosya decode yolu doğrulandı.
- Tek başarısızlık `SeriesManagerTests.testAModeNoContinuationServesMayNot`: 9–10 öğrenme devamını unavailable bekliyor, uygulama available döndürüyor (`SeriesTests.swift:218`). İlgili test, SeriesManager, OfflineStoryService ve blueprint kaynakları bu dilimde değiştirilmedi. Ayrı temiz baseline koşusu yapılmadığı için önceki sürümde tekrarlandığı iddia edilmiyor. Bu kapsam dışı varsayım için üretim mantığı veya test beklentisi değiştirilmedi.

İlk doğrulama denemelerinde disk dolması, SwiftPM generated bundle imzası ve kaynak kökündeki altı izlenmeyen ` 2.swift` kopyasının duplicate tanımları derlemeyi durdurdu. Kopyalar silinmedi; `/private/tmp/magicpaper-source-duplicate-quarantine-20261121/` altında kaynak yolu ve SHA manifestiyle korundu. Sonraki derlemede yeni test fixture içindeki eksik `states: []` argümanı düzeltildi. Son koşu üretim kodunu derleyip yukarıdaki test sonuçlarını verdi.

## Sınırlar ve sonraki kapsam

Her masalda görselli sayfa sayısı henüz garanti edilmiyor. Bu dilim diğer yaşları, nesneleri ve anlatı durumlarını onaylamaz. Pencere çizimi adayları paketlenmedi. Sonraki genişleme aynı kaynak incelemesi ve kaynak–konu–durum doğrulamasıyla yapılmalı; otomatik etiketler tek başına yayın izni değildir.

Bu tur telefona kurulum, yeni ekran görüntüsü matrisi, VoiceOver, jest ve çocukla motivasyon değerlendirmesi yapılmadı. Mevcut okuyucunun kompakt/erişilebilirlik boyutlarında isteğe bağlı spot gizleme davranışı sürer; pin bulunması her ekran boyutunda görünür çizim garantisi değildir.

Paylaşılan çalışma alanındaki Originals/Classic ve `ReaderImageLoader.swift` değişiklikleri bu iş tarafından düzenlenmedi ve commit kapsamına alınmadı. Testler mevcut çalışma alanında koştu; bu bağımsız değişikliklerin tamamı için doğrulama iddiası yoktur.
