# İncelenmiş nesne çizimi kapsamı — 21 Kasım 2026

## Hedef ve kapsam

Çan için kurulan kaynak izi bağlamasını, aynı çizim kütüphanesindeki on nesneye genişletmek: yırtık harita, tek eldiven, eski fener, altın anahtar, mavi kristal, renkli tüy, deniz kabuğu, büyüteç, sağlam ip, kâğıt fener. On bir konu için aynı beş 5–6 yaş notice kaynağı ve isteğe bağlı tek son hatırlama satırı desteklenir. Hatırlama listesi 38 exact kaynaktır.

Bu çizimler önceden yerleşik görsel oluşturma aracıyla onaylı guaj referanslarından hazırlanmış ve paketlenmişti. Yeni çizim veya ağ çağrısı eklenmez. Kaynak cümleleri ve kanonik nesne tanımları tekrar okundu; on çizim tek tek açıldı. Durum kararları, asset sürümleri ve fingerprint kayıtları `docs/research/2026-11-21-reviewed-discovery-expansion-decisions.json` içinde.

Boş yuva ve kapağı açık müzik kutusu dahil edilmez; generic varlık cümlesi bu ek durumları kanıtlamaz. Tüm otomatik etiketler elle incelenmiş sayılmaz. İnceleme yalnız açık kaynak ve çizim revizyonlarının eşleşmesini kapsar.

## Davranış

Mevcut v1 kuralları önceliklidir; zaten desteklenen kitap sayfası aynı v1 pinini alır. Reviewed bağlayıcı kalan görselsiz uygun sayfalara bakar. Yetkilendirme doğru kanonik nesneyi, asset kaydını ve kaynak kanıtını birlikte taşır. Tam kaynak sırası, sayfa metni, origin kimlikleri ve dosya özetleri doğrulanır. Eski çan manifesti ve dosyası korunur; kayıtlı politika 1/2 pinleri için şema değişmez.

Metin, satır kimlikleri, seed ve seçim dağılımı değişmez. Eski kitaplara geriye dönük görsel atanmaz. Aile, seri, özel gün, nakarat ve çoklu beat sayfaları bu genişlemeye dahil değildir. Reader düzeni ve karakter kimlikleri değişmez.

## Doğrulama durumu

Spec uyumluluğu ve bağımsız kod kalite incelemesi engelleyici bulgu bulmadı. Eski `StorySpotBindingTests` içinde artık desteklenen hatırlama sayfalarını görselsiz bekleyen varsayım, yeni kapsamla uyumlu testlerle değiştirildi; on gerçek nesne fixture testi v1 önceliğini ve yeni recalled politika 2 sonucunu bağımsız olarak zorunlu tutar. İlk Xcode denemesi SwiftPM/Clang kullanıcı önbelleği sandbox erişiminde, testler başlamadan durdu (`/private/tmp/MagicPaper-reviewed-expansion-tests.log`). Önbellek erişimiyle tekrar edilen final çalıştırma **TEST SUCCEEDED**, çıkış kodu 0: **76 test, 75 başarılı, 1 atlanan, 0 hata**. Log: `/private/tmp/MagicPaper-reviewed-expansion-final.log`. Atlanan mevcut test, tilkinin o fixture içinde seçilebilir olduğu durumda sınanacak ret koşulu bulunmadığını bildirir. Önceki 21 Kasım çalışmasında seri uygunluğu testi 9–10 öğrenme devamını unavailable beklerken uygulama available döndürmüştü. Bu tur seri mantığına veya bu test beklentisine dokunulmaz; genel testlerin tamamının yeşil olduğu iddia edilmeyecek.

## Kalan sınır

Bu çalışma on yeni nesne resmi eklemekten ziyade, paketli çizimlerin kaynak açısından desteklediği sayfaları genişletir. Desteklenen yaş bandı hâlâ 5–6'dır. Her kitapta çizim veya yaşa göre asgari resimli sayfa sayısı henüz garanti değildir. Diğer yaşlar, sonraki anlatı beat'leri ve mekân çizimleri ayrıca kaynak/durum incelemesi ister. Bu tur telefona kurulum ve kullanıcıyla fiziksel cihaz incelemesi kapsamı yoktur.

## Final kanıtları

- Genişletilmiş politika: **11/11 test**, on bir nesne × beş kaynak × 38 hatırlama kombinasyonları ve olumsuz kontroller dahil.
- Sayfa provenance: **4/4**; asset resolver: **6/6**; spot binding: **6/6**.
- Reader mapping: **29/29**; offline mapping: **20 test, 19 başarılı, 1 skip**.
- On yeni nesne için gerçek composer çıktısı → v1 önceliği / hatırlamalı politika 2 → app mapper → kaydet/decode zinciri geçti; metin eşitliği korundu. Tüm 11 çizim gerçek ReaderImageLoader üzerinden açıldı.
- Manifest/kayıt uyumu ve 11 dosya özeti ayrıca doğrulandı; `resource-verification.json`. Manifest SHA: `28b285072990b172843f39c88d7b4275472a36b49d38ff0dc40b8877f6771f4c`.
- Motorun izlenen dosyalarında değişiklik yok; motor testleri bu tur yeniden koşulmadı. Önceki seri uygunluğu başarısızlığı bu seçili koşuya dahil edilmedi ve çözülmüş sayılmıyor. Tam uygulama test takımı veya yeni görsel ekran matrisi koşulmadı; telefona kurulum yapılmadı.

Başka oturumun Originals çalışması doğrulama öncesinde `bf84712` ile commit edildi. Bu işin commit kapsamı yalnız beş bridge/test Swift dosyası, yeni yayın manifesti ve kendi araştırma/teslim/hafıza kayıtlarıdır.
