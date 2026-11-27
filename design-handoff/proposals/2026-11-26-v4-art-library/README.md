# V4 görsel havuzu — kaynak envanteri

26 Kasım 2026. Kullanıcı karakterlerin V4 imza ayrıntılarını ve karma görsel havuzu yönünü onayladı. Bu onay, her sayfanın görsel eşleşmesini yayınlama onayı değildir.

90 kitap / 720 sayfa / 5 arkadaş / 25 keşif. Üç modda 30’ar kitap vardır. `inventory.json` tam sayfa metni, template ve kaynak SHA, mevcut semantik açıklamalar ve görsel devir notlarını korur. 720 template SHA yeniden hesaplanarak doğrulandı. Kaynak uygulama checkout’u değil, kaydı manifestte bulunan motor dalındaki pinli V4 paketidir.

## Onaylanan kimlik güncellemeleri

- Tarçın: turkuaz boyunluk; doğal dört ayaklı tilki.
- Kestane: dikenlerinde hardal sarısı yaprak.
- Yıldız: gece mavisi tüyler ve göğüste yıldız biçimli tüy.
- Simit: kırmızı tasma, çan ve kıvrık kuyruk; şehri ziyaretçi kimliği korunur.
- Böğürtlen: bordo çanta ve böğürtlen lekeli mor pati. Çantanın konumu sayfa metnine göre değişir.

## Kullanım sınırı

`propMentions` yalnız sözcüksel adaydır. Anı, benzetme, olumsuzluk, niyet ve mevcut nesne ayrılmadan çizim bağlanmaz. `artHandoff` ile semantics yayın onayı sayılmaz. Bütün sayfalar pending-manual-page-review durumundadır; yeni runtime kuralı yoktur. Çocuk görünüşü uydurulmaz. Eski görseller ve kaydedilmiş kitaplar korunur.

15 pilot kitap, her mod/arkadaş hücresinin kitap kimliğine göre ilk kitabıdır. Bu seçim yalnız inceleme içindir; masal üretim dağılımını değiştirmez. Pilot başına üç anlamlı görsel an hedeflenir; henüz garanti değildir.

## Sonraki teslimler

Önce beş ayrı V4 kimlik çizimi; sonra pilotların sayfa bazında poz, nesne durumu ve mekân gereksinimleri. Uyku modunda dinleme/dinlenme/uyuma; öğrenmede bakış açısı ve damla-yaprak durumları; macerada hareket, mendil ve ahşap işaret parçaları ayrılır. Kesin üretim adedi bu incelemeden sonra çıkarılır.

Uygulama/motor/metin değiştirilmedi. Build, test ve simülatör çalıştırılmadı; envanterin sayıları ve template SHA bütünlüğü veri kontrolüyle doğrulandı.
