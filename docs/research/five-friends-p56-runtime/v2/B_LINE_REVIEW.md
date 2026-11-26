# B hattı hedefli karşı inceleme

25 Kasım 2026. İncelenen uç: `beaf0543f1c493312a4c4c2ee3e352c2ce1cd678`. Salt okunur inceleme; uygulama kodu değiştirilmedi. Bu kayıt B hattının tamamına kabul değildir. Claude'un 119/0 sonucu kendi kanıtıdır; bu tur uygulama testi veya simülatör çalıştırılmadı.

## Birleşmeden önce düzeltmeler

1. **HIGH — P56StoryMapper.swift:12–13,29.** Sayfa provenance aktarılmıyor, origin'den yeniden kurulabileceği varsayılıyor. V2 aynı structure/companion için üç olay taşır; özgün isteğin güvenlik ve sürpriz seçim kapsamı origin'de yoktur. Kaynak paketi kayıpsa yeniden kurmak zaten mümkün değildir. Tam `P56PageProvenance` değerlerini mevcut `StoryPage.provenance` üzerinden ayrı optional P56 zarfında kalıcılaştır. Legacy 16 hex source hash alanlarına SHA256 veya sahte beat_line türü yazma. Kaydet/aç roundtrip, legacy decode, v1/v2 trace ve kaynak olmadan kayıtlı sayfaların okunması testleri gerekir. Bu talep 811d0cf durum kaydında da var; henüz uygulanmamış.

2. **MEDIUM — StoryGenerationManager.swift:330; P56CompositionPathTests.testComposeFailureFallsBackWithSameInputs.** Catch, reason=composeFailed yazıyor fakat route=decision.route ile P56'yı koruyor; ardından legacy gerçekten yazıyor. Son karar ve log birbirini tutmuyor; test de yanlış route'u sabitliyor. Catch kararını `.legacy/.composeFailed` yap, testi gerçek fallback rotasını doğrulayacak şekilde güncelle. İstersen denenen rota ayrı isimli tanı alanında tutulabilir; final route anlamını değiştirme.

## V2 entegrasyon gereklilikleri

B2 şu an v1 bundle/resource ve SnapshotStore sürüm guard'ını kullanıyor. Bu, v1 tabanlı teslimde beklenen durumdur; v2'ye geçişte etkin `P56PinnedSource.packageVersion` ve SHA birlikte kullanılmalı, v2 byte'ları aynen paketlenmeli, arşiv hem v1 hem v2'yi tanımalıdır. V1 snapshot güncel v2'ye yönlendirilmemeli. Varsayılan `.mostProtective` ile gerçek v2 yazım testi ve bayrak açık simülatör kontrolü eklenmeli; nil safety fixture testi tek başına bu kapıyı karşılamaz.

## Diğer değerlendirmeler ve yanıtlar

- Writer gerçek çocuk kimliğini yalnız compose'a, router anonim destek isteğini geçiriyor; family/topic/occasion simgeleri ve safety aktarımı sözleşmeyle uyumlu. Sayısal seed ve FNV-1a dönüşümü deterministik; nil seed rastgele seçilip origin'de sayısal sonuç olarak tutuluyor.
- SettingID sayfaların ortak mekânından, fingerprint sıralı rendered digest'lerden alınıyor; kabul. Fingerprint kaynak kimliği yerine geçmez.
- Debug-only bayrak ve başarısız kaynakta legacy yeni istek yolu korunmuş. Kaydedilmiş P56'nın historical legacy resolver'da unsupported kalması doğru.
- Prewarm ana iş parçacığı dışında yüklemeyi başlatır ama `source()` aynı kilidi yükleme boyunca tuttuğu için erken seçim yine bekler. V2 11 MB olduğundan v1 Debug 1–2 sn gözleminden v2 Release sonucu çıkarılamaz. Cold/warm yükleme, hash/decode/doğrulama ve ana iş parçacığı beklemesi ayrı ölçülmeli. Release ölçümü olmadan doğrulamayı yayın aşamasına taşımayı kabul etmiyorum. Yüklemede pin, desteklenen şema, exact kaynak/ref ve güvenlik incelemesi bütünlüğü korunmalı. İyileştirme gerekirse önce tekrar decode/hash ve paylaşılmış cache maliyeti incelensin.
- Arka plan arşiv yazımı `try?` ile sonucu yok sayıyor. Kayıtlı sayfalar okunur ama arşivin kalacağı garanti edilemez. V2 geçişinde yüklemenin başarı durumuyla arşivlemenin başarı durumunu ayır; çocuk verisi taşımayan neden kodu ve arşiv yazma hatası testi ekle. Başarısız arşive rağmen başarılı kaynak kaydı varmış iddiası verme.
- Kullanılmayan P56InternalService, tüketici ve test aramasıyla gerçekten kullanılmıyorsa Claude sahipliğinde ayrı küçük temizlikle kaldırılabilir; bu birleşme için zorunlu değil.
- Beşlinin ekrandaki kısa açıklaması şimdilik aynı kimliğin katalog kopyasından gelsin. Yeni kopya gerekecekse authoring personality alanını UI metnine çevirmek yerine yerelleştirilebilir uygulama sunum verisi kullanılsın.
- B6 P56 kitaplarını recall havuzundan çıkarıyor. Mevcut legacy kitaplardan gelen nonnil `context.recall` ise writer tarafından aktarılmıyor; router da bunu taşımıyor. Otomatik recall'ın pilotta bilinçli olarak devre dışı bırakılması mı yoksa `recall` unsupported ile legacy'ye yönlendirilmesi mi istendiği karşılıklı sözleşmede açıklaştırılmalı. Konu/aile gibi parametreleri contexts içinde gizlice kodlamayacağız.

Sonuç: hedefli incelemede iki düzeltme; v2 geçiş kapıları ve recall sözleşme sorusu açık. B hattı birleşmesi henüz kabul edilmedi. Motor C2/C3 455aef9 karşı incelemesi ayrıca bekleniyor. Üretim kapalı.
