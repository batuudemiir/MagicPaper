# Beş arkadaş 5–6 · kapsamlı metin incelemesi

22 Kasım 2026. Bağımsız editoryal okuma: 30 kitabın sekizer tam sayfası, toplam 240 sayfa. İnceleme sonrası aynı içerik sorumlusu aşağıdaki dar düzeltme turunu uyguladı; düzeltilmiş paketin son doğrulaması ana ajan sorumluluğundadır. Bu belge genel yayın, görsel kabul veya runtime onayı değildir.

## Tam okuma kapsamı

Kitap kimliği kalıbı `pilot56_book_<etiket>_<hayvan>_v1`:

| Etiket | Tam okunan kitaplar |
|---|---|
| U1 | fox, owl, bear |
| U2 | hedgehog, cat, bear |
| U3 | fox, hedgehog, owl, cat |
| L1 | fox, owl, cat |
| L2 | hedgehog, owl, bear |
| L3 | fox, hedgehog, cat, bear |
| A1 | fox, hedgehog, cat |
| A2 | fox, owl, bear |
| A3 | hedgehog, owl, cat, bear |

## Metin ve kişilik bulguları

Dokuz nedensel mekanizma tam metinlerde ayırt ediliyor. U1 tanıdık seslerden dinlenmeye geçiyor; L1 tahmini gözlemle denetliyor. U2 dinlenme yerini hazırlıyor; U3 bir gündüz anını seçip kapatıyor. A1 kendi temposunda ilerleme, A2 parçaları birleştirme, A3 kendi gördüğü ayrıntıyla kaybı bulma olarak ayrılıyor. Bu okuma, rastgele örnekleme veya tekrar penceresi ölçümü yerine geçmez.

Çocuğun gözleme, seçme, hazırlama, birleştirme, hatırlama ve yürüme eylemleri sonucu belirliyor. Arkadaş çocuğu taşıyarak çözümü üstlenmiyor. Açık anatomi ihlali bulunmadı: ayının ölçeği, kirpinin kendi adımları, Simit’in şehirden ziyaret kimliği ve Yıldız’ın uçabilmesi korunuyor. Uyku kitapları aynı odada kapanıyor; açık gözle dinlenme ve göz kapama gerçek uykuya dalma diye yorumlanmıyor.

## On bir kaynak metni düzeltmesi

`Content/Pilots/five-friends-56-v1/editorial-revisions.json` eski/yeni metni, kaynak kimliğini ve UTF-8 SHA-256 değerlerini saklar.

Önceki sekiz düzeltme: A2 owl p7 katkının gözlem olduğunun doğrulanması; A3 owl p3 yazım; U2 cat p6 minder sürekliliği; U3 fox/hedgehog/owl/cat p1 oda ekinin yazımı; U3 hedgehog p5 sürekli kaygılı kişilik iddiasının kaldırılması. Bunlar tam okumada mevcut halleriyle görüldü.

Bu turun üç düzeltmesi: U1 fox p1 “Tarçın de” → “Tarçın da”; U1 owl p1 “Yıldız de” → “Yıldız da”; U2 bear p7 ikinci kez yatağa dönmek yerine yatağında rahat olma. Üçü de yeni v2 sayfa kaynaklarıdır. Metadata değişikliği yüzünden başka metin kaynaklarına yeni kimlik verilmedi.

## Anlam metadatası düzeltmeleri ve sınırlar

Metadata revizyon 2, 240 sayfanın eski/yeni anlam kayıtlarını ayrı izler. Çok özneli sayfalardaki hatalı tek `actorSubjectID`, `actorSubjectIDs` dizisine dönüştürüldü. Örneğin A3 owl p5 uçuşta baykuşu; U2 bear p5 bez açma eyleminde çocuğu da içerir. Bunlar tam sayfa bağlam kayıtlarıdır: `atomicActionMappingApproved=false`; tek tek yürütülebilir eylemler veya onaylı görsel pozlar değildir. Negatif eylemler, koşullar ve anılar tam metinden ayrıca ayrılmalıdır.

U2 nesne açıklamaları her kitabın kendi türüne uygun malzemelerle sınırlandı. A3 owl p3 mevcut alçak tünek kökü, aranan ve hatırlanan çatallı kökten ayrı kimlik aldı. A3 p8 arama kökü, açıklığa dönüşten sonra `off-scene` olarak kaydedildi. Çizim katmanı bu iç editoryal sözlüğü sessizce runtime şeması kabul edemez.

## Açık kalan işler

Özellikle U3 p2/p7 ve L3 p8 anlatının içine giren üretim kısıtı açıklamaları, çocuk kitabı sesini zayıflatıyor. Bu turda yaygın edebi cilalama yapılmadı. Metinlerin kişilik/anatomi açısından okunması, yayıma hazır edebi kalite iddiası değildir.

Deniz kişiselleştirmesi yalın/ilgi/yönelme biçimlerini açık yuvalarla ele almalı; global değiştirme yeterli değildir. Üretilmiş kişisel metnin provenance ve hash değerleri sentetik kaynaktan ayrılmalıdır. U3 anı özneleri mevcut odada ikinci çocuk/arkadaş oluşturmaz.

Runtime beat/state uyarlaması, yaş bütçesi, güvenlik, bağlam reddi, 1.500 ilk-deneme, görsel kapsam ve ürün yayın kararı ayrı kabul adımlarıdır. Bu düzeltme turunda test, build, simülatör veya çizim üretimi çalıştırılmadı. Bağımsız son editoryal kabul bayrakları açılmadı.

## 25 Kasım son doğrulama düzeltmesi

Gerçek motor koşusu L2/Böğürtlen p6 cümlesinde 16 kelime buldu (5–6 sınırı14). Cümle anlamı korunarak ikiye bölündü, `pilot56_source_l2_bear_p06_v2` yeni metin/SHA aldı. Önceki metin/hash ledger’da; toplam12metin revizyonu ve1252kaynak (ek cümle segmenti). Bu dar düzeltme bütün metinlerin son editoryal kabulü değildir.
