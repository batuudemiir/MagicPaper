# Guaj nesne havuzu: üçüncü genişleme

21 Kasım 2026. Altı yeni nesne uygulamaya eklendi ve seçili testlerle doğrulandı.

## Görsel kapsam

Kırmızı top, mavi/sarı saplı atlama ipi, renkli kurdele kuyruklu kâğıt uçurtma, tahta flüt, kişi/sahne yansıtmayan el aynası ve uzun kırmızı ipek kurdele. Onaylı marka yönü ve önceki guaj nesne çizimi referansları her üretime eklendi. Hepsi tek, somut, durağan nesne ve gerçek saydam zemin; sahne/çocuk/Ragi kimliği yok. Tam istemler, referanslar, dosya boyutları, alfa aralıkları ve SHA'lar GENERATION_RECORD.json içinde.

Kurdele v1'de kopuk dış boya izleri görüldü; üretim aracının düzenleme işleviyle v2 temizlendi. V1 yalnız taslak kaydı olarak tutuldu; runtime'da revision2 seçildi. Diğer beşinin revision1'i kullanıldı. PNG'ler assets/ altında; aynı byte'lar mpart olarak paketlendi.

## Kaynak sözleşmesi

Havuz 14→20. Önceki 14 girdi, 20 notice, dört paired destek, üç blueprint ve 38 recall aynen korunuyor; kaynak izin listesi bu tur genişlemiyor. Yeni altı nesne, aynı incelenmiş varlık cümleleri için ayrı kanonik nesne/dosya özetiyle onaylandı. `docs/research/2026-11-21-story-art-wave3-decisions.json` literal özellikleri ve sınırları kaydeder.

Kaynak sırası/tamlığı, gerçek blueprint/sayfa/companion, canonical nesne, metin ve beat eşitliği korumaları değişmez. Eski manifestler ve kaydedilmiş pinler yaşar. Yeni manifest bozuksa sessiz fallback yok. Eski v1 eşleme önceliği sürer. Kayıt şeması/politika sürümü değişmez; eski kitaplar yeniden bağlanmaz.

Top/ip/uçurtma village habitat'ı ister; küçük yaş spor biçiminde Köy Çayırı uygun adaydır. Kurdele impliesNeed nedeniyle bu üç spor blueprint'inde seçilemez; küçük yaşa zorlanmaz. Tema metadata'sı composer seçiminin doğrudan koruması değildir; gerçek seçim/trait/habitat kuralları korunur. Her nesne/yaş/mod ve her masal için görsel garantisi yok.

## Doğrulama sınırı

Final seçili uygulama koşusu **TEST SUCCEEDED**, çıkış 0: **91 test, 90 başarılı, 1 skip, 0 hata**. Motor/metin/seed/seçim/reader UI bu tur değiştirilmedi; önceki temiz44/0motor koşusu sebepsiz tekrarlanmayacak. Seçili uygulama testleri iki incelemeden sonra tek koşuda geçti; log `/private/tmp/MagicPaper-wave3-app-tests.log`. Atlanan mevcut offline mapping fixture, tilkinin seçilebilir olduğu durumda ret koşulunun bulunmadığını bildirir. Telefona kurulum ve yeni UI/VoiceOver matrisi yapılmadı. Önceki metric/seri bulguları bu kapsamda çözülmüş sayılmaz.

## Kod ve kaynak incelemesi

Spec uyumluluğu ve bağımsız kod kalite incelemesi engelleyici bulgu bulmadı. Kapalı SHA→edition tablosu, eski üç manifestin reviewID/sayımlarını korurken wave3 için 20 girdi / 20 kaynak / 4 destek / 3 blueprint doğrulaması ekler. Authorization, ImageIO ve binder kodları değiştirilmedi. Yeni gerçek fixture testleri önce yazıldı; AGENTS gereği ara RED çalıştırması yapılmadı.

Test öncesinde disk alanı 449 MiB'ye düştü. Aynı çalışma kapsamında önceki cihaz derlemesine ait yeniden oluşturulabilir `/private/tmp/magicpaper-offline-rhythm-device-build/Build` çıktıları ve daha önce başarısız olmuş varsayılan SwiftPM derlemesinin `StoryEngine/.build/out` önbelleği temizlendi. Kaynak dosyaları, paket indirmeleri, aktif simülatör cache'i ve önceki native test cache'i bu temizlik kapsamına alınmadı. Temizlikten sonra 3.6 GiB boşluk gözlendi; kesin fark başka disk etkinliklerinden ayrıştırılmadı.

## Gerçek örnekler ve final kanıtları

Altı yeni konu için composer→mapper→değişmeyen metin→dosya çözümleme→kaydet/decode zinciri geçti. Test ekleri xcresult'tan çıkarıldı; `real-composer-fixtures.json` tam yaş/blueprint/seed/sayfa/beat/variant bilgilerini taşır. Bunlar elle kurgulanmış örnekler değildir. 3–4 yaşta üç oyuncak Köy Çayırı'nda, kurdele 5–6, flüt 7–8 ve ayna 9–10 örnekleriyle doğrulandı.

Politika testleri 17/17, kaynak izi 4/4, resolver 6/6, binding 6/6, reader mapping 29/29, context 9/9; offline mapping 20 test/1 skip. Yirmi çizimin tamamı ReaderImageLoader üzerinden açıldı. Eski 14 manifesti, daha eski 11 manifesti ve çan proof uyumu; mevcut v1 önceliği; bozuk manifest/eksik dosya/yanlış kaynak kontrolleri geçti.

Bu tur motor, metin ve seçim dosyalarında değişiklik yok; motorun önceki 44/0 sonucu yeniden koşulmuş gibi sunulmuyor. Telefon kurulumu, yeni ekran görüntüsü matrisi, VoiceOver ve tam uygulama test takımı bu doğrulamanın kapsamında değil. Önceki seri uygunluğu ve seed içeren tekrar ölçümü bulguları açık. Her kitapta veya her yaş/modda tüm 20 konunun görüneceği garanti edilmez.
