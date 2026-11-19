# Offline okuma ritmi pilotu

Başlangıç19 Kasım2026. Kullanıcı mevcut havuzla/API olmadan okuyucu sunumunu geliştirmeyi onayladı. Önceki kurmaca Ela/harita sahneleri üretime eklenmedi. Araştırma: `docs/research/2026-11-19-okuma-hevesi-arastirmasi.md`; spec/plan: `docs/superpowers/{specs,plans}/2026-11-19-offline-reader-rhythm*.md`.

## Uygulanan kapsam

- Yeni offline masallarda mevcut authored rol/refrain, optional StoryPageReading sürüm1 ile kayıt ve seri sayfalarında taşınır. Range/piksel değeri saklanmaz; eski masallara geri doldurma yapılmaz.
- 7–10 paragraf düzeni, özgün paragraf içindeki cümleleri en fazla ikişerli gruplar. Açılış ilk cümleyi, sakin sonuç son cümleyi ayırır.
- 3–6 nefes birimleri korunur. Sakin son ve doğrulanmış authored refrain öncesinde isteğe bağlı ek nefes uygulanır.
- Ek boşluk ancak ölçülen anlatının tamamı alana sığıyorsa kullanılır. Uzun metin kayar; yazı küçültülmez. AX, kompakt yükseklik, sahneli sayfa ve geçersiz/eksik metadata mevcut düzeni kullanır.
- Kaynak paragraf ve UTF16 koordinatları korunur; bloklara ses vurgusu yerel olarak taşınır. Tam kaynak kapsaması doğrulanamazsa bütün sayfa eski düzene döner.
- Görsel binder/asset/pin/dosya/karakter kimliği/katalog değişmedi. Nötr görsel yalnız mevcut incelenmiş eşlemesinde kalır; görselsiz sayfaya harita veya karakter eklenmez.

## İnceleme

Plan ve UI brifi bağımsız uzmanlarla yazıldı. Spec incelemesinde bloklayıcı bulunmadı. Kod incelemesinde çok cümleli authored refrain’in küçük yaş nefes birimlerini birleştirebildiği bulundu; yalnız paragraf düzeninde birleştirecek şekilde düzeltildi, nefes düzeninde ilk suffix biriminden önce bir boşluk ve özgün cümle sayısı korunur. Regresyon testi eklendi; yeniden inceleme onaylandı.

Yeni testler mapper’daki dört yaş bandı metin invariant’ını, metadata’sız/gelecek/bozuk kayıtları, reader aktarımını, seri roundtrip/unlock’u, rol gruplarını, tam byte/UTF16 kapsamasını, emoji/ZWJ/combining karakter sınırlarını, authored suffix önceliğini ve ses konumlarını kapsar.

## Nihai doğrulama

Uygulama XCTest/render matrisi çalıştırılmadı; kullanıcı talebiyle gerçek cihaza build/kurulum önceliklendirildi. Ara testler çalıştırılmadı: AGENTS.md’nin yalnız plan sonunda test kuralı nedeniyle testler önce yazıldı ama RED yürütmesi yapılmış gibi sunulmaz. İlk final oturumu ve `/tmp/magicpaper-membership-*` önbellekleri ortam değişiminde kayboldu; bu koşudan başarı iddiası yok. Yeni genel simülatör build-for-testing log’u `/private/tmp/MagicPaper-offline-reader-rhythm-build.log`.

`OfflineReaderRhythmRenderingTests` gerçek offline motor metnini aynı sayfanın metadata’sız eski sunumuyla karşılaştırır;4 büyük yaş anlatı anı, küçük yaş sonuç, gece, AX5, kompakt yükseklik ve mevcut incelenmiş harita açılışı için çıktı hazırlanmıştır. `StorySpotReaderRenderingTests` mevcut kâğıt/ayar/spot matrisini korur. Testlerin varlığı, çalıştıkları anlamına gelmez; çekirdek ve gerçek cihaz sonuçları aşağıda ayrı kaydedilir.

Bunlar tek simülatörde sabit viewport ve no-op callback renderlarıdır; tam cihaz/gestür/ses/VoiceOver kabulü veya çocuklarda okuma hevesinin arttığının kanıtı değildir. Yeni AI/API çağrısı, runtime resim üretimi, ek telemetri ve yeni içerik yok. Ailelerle nitel gözlem bu teknik pilotun dışında kalır.


### Çekirdek doğrulaması · 20 Kasım

Tam uygulama bağımlılıkları yeniden indirilirken, gerçek `ReaderText.swift`, `ReaderReadingRhythm.swift` ve `StoryPageReading.swift` kaynaklarının kopyaları bağımlılıksız macOS SwiftPM harness’ında derlendi. `ReaderPageComposition` enum tanımı gerçek kaynak dosyasından aynen alındı; XCTest dosyasında yalnız testable module adı değiştirildi. SwiftUI/layout/model entegrasyonunun yerini almaz.

İlk11 testte2 assertion, Foundation’ın emoji içi UTF16 aralığını toleranslı dönüştürmesi nedeniyle başarısız oldu. Üretim helper’ı iki uçta gerçek Character-sınırı offset üyeliği arayacak şekilde düzeltildi; testler zayıflatılmadı, combining ve ZWJ iç sınırları eklendi. Son koşu **12 test,0 hata**, exit0 (`/private/tmp/MagicPaper-rhythm-core-check-final.log`). Bağımsız yeniden kod incelemesi onaylandı. Değişen12 Swift dosyasında frontend parse ve diff kontrolü temiz. Bu sonuçlar app/simülatör test başarısı değildir.


### Cihaz doğrulamasına geçiş

Kullanıcı20 Kasım’da kendi telefonunda denemeyi önerdi ve açıkça telefona build istedi. Eşleştirilmiş iPhone16 hedefi doğrulandı; otomatik testler kişisel cihazın veri konteynerinde çalıştırılmayacak. Paketler, aynı Package.resolved revision’larıyla yeniden hazırlandı. Firebase ve snapshot-testing sığ görev kopyalarının SHA’ları; protobuf/abseil alt depolarının ise gitlink commit’leri doğrulandı. Alt depoların yeniden tam geçmiş indirmemesi için yalnız derleme komutunun ortamında görev içi yerel Git aynaları kullanıldı; genel Git ayarı, paket sürümü veya dependency kaynak metni değiştirilmedi.

Cihaz build log’u: `/private/tmp/MagicPaper-offline-reader-rhythm-device-build.log`. **BUILD SUCCEEDED**, exit0; iPhone16 için Debug derleme ve Apple geliştirme imzası başarılı. `devicectl device install app` exit0 ile kuruldu; `device process launch` exit0 ve “Launched application” sonucu ile açıldı. Yerel kurulum/açılış logları sırasıyla `/private/tmp/MagicPaper-offline-reader-rhythm-device-install.log` ve `...-device-launch.log`. Uygulama silinmedi; mevcut kurulumun üzerine yükleme yapıldı. Simülatör test/render matrisinin çalıştığı iddia edilmez.


### Teslim ve kabul sınırı

Kaynak, metadata, ses koordinatı ve derleme kontrolleri tamam;12 çekirdek testi hatasız, cihaz uygulaması derlenip yüklenip açıldı. Bu, tüm uygulama XCTest hedeflerinin geçtiği veya okuyucunun gerçek cihazda görsel/etkileşim kabulünün tamamlandığı anlamına gelmez. Bu turda yeni sabit viewport görüntüsü üretilmedi; mevcut test kaynağı sonraki test penceresi için hazır. Kullanıcı telefonda **yeni** masal oluşturarak metin grupları, son sayfanın nefesi, kelime yardımı ve sesli okumayı deneyebilir. Eski kitaplarda metadata yoktur, eski düzen korunur. Nitel çocuk gözlemi ve motivasyon etkisi ölçülmedi.
