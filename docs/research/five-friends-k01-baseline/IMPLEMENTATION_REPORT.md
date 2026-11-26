# Beş arkadaş K0–K1 ve P56: uygulama kaydı

22 Kasım 2026. Kullanıcının B yaklaşımı ve uygulama başlangıcı onayıyla hazırlanmıştır.

## Uygulanan temel

- Tam katalog ve beat kaynağı, SHA-256 ve `offline-legacy-v1` davranış kimliğiyle tanımlanır. `ContentPackage` şeması 2 kaldı.
- `StoryOrigin` ve `SeriesPlan` exact kaynak metadata'sını taşıyabilir. Eski eksik alanlar okunur; bozuk, explicit null veya ileri sürüm metadata'sı ham değeriyle korunur ve legacy'ye düşürülmez.
- Güvenilir güncel kaynak kullanımdan önce `CatalogHistory` içine atomik, digest isimli snapshot olarak saklanır. Remote aday/active geri çekilmesi geçmiş kaynağı kaldırmaz. Kaydedilmiş kitabın devamı güncel katalogdan değil kendi exact kaynağından yazılır.
- Yeni cihazda aynı kaynak bu build'de paketliyse exact digest eşleşmesiyle kullanılabilir. Aynı semver tek başına kaynak kanıtı değildir. Doğrulanmış eski sürüm eşlemeleri olmadığı için legacy compatibility tablosu boş bırakıldı.
- Aktif serinin açılması/okunmamış silinmiş bölümün geri getirilmesi kayıtlı sayfaları kullanır. Aile kaldırma yeniden yazımı kaynak sürümünü korur; açılmış sayfa ve art pinleri korunur.
- Eski istemcinin metadata'sız aynı seri güncellemesi, ancak kaynak bağımlı plan/sayfa/origin içeriği aynıysa bilinen referansı korur. `StoryPage.==` yalnız kimlik karşılaştırdığı için bu kontrolde **tam encode edilmiş sayfa değeri** kullanıldı; aynı UUID'de değiştirilmiş metin source devralamaz.
- Hesap verileri silinince kaynak cache'i sıfırlanır; sonraki yeni kitap yeniden arşivleme güvencesinden geçer.

## Sabit kimlik seçimi ve geniş doğrulama

Tam havuz taramasında sabit ID isteyen bağlamaların her seferinde bütün adayların trait/red gerekçelerini hesapladığı görüldü. İki private seçim yordamı tek yolda birleştirildi; explicit ID'de yalnız o ID'nin kayıtları denetlenir. Duplicate ID'de ilk uygun kayıt veya ilk kaydın red nedeni korunur. Habitat, güvenlik, konu, casting, nature, family-name ve discovery koşulları değişmedi; unpinned ağırlık/sıralama da değişmedi. Bağımsız incelemede güvenlik veya davranış farkı bulunmadı. PinnedBindingTests ve gerçek eski kitap fixture'ları eklendi.

Bu iyileştirme yeni beşli havuz filtresi, sanat için retry veya gizli kapsam azaltması değildir.

## İçerik başlangıcı ve sanat teslimi

`Content/Pilots/five-friends-56-v1/` üretim bundle'ına alınmamış **editoryal korpus**:

- 9 kurgu, 30 izinli karakter/kurgu eşleşmesi, 15 karakter/mod hücresi.
- 30 tam kitap / 240 sayfa / 1.251 gerçek authored sayfa ve cümle kaynak kaydı.
- Fısıldayan Orman gündüz mekânı ve ayrı Orman Kıyısındaki Oda; aynı beş kanonik kimlik.
- Tam sayfa metin/kaynak sırası/önce-sonra bağlamı, somut eylem aktörü, temporal presence ve çizim sınırları.
- Bağımsız incelemedeki baykuş eylem özeti, kedinin minderine yerleşmesi, Kestane ifadesi ve dil düzeltmeleri giderildi. Sekiz değişmiş sayfa `_v2` kaynak kimliklerini aldı; önceki metin ve SHA'lar `editorial-revisions.json` içinde korunuyor.
- Okunabilir metin: [OKUMA_DOSYASI](../five-friends-pilot/OKUMA_DOSYASI.md).

Bu korpus bir `StoryBeat` runtime paketi değildir. Yeni kimlikler kanonik eski karakterlerin yerini almaz; olay örgüsü sayısı 30 diye sunulmaz. Korpus bütünlük kontrolü 30/240/9/15 ve tüm kaynak/hash/pointer ilişkileri için geçti; kelime bütçesi uyarısı yok. Bu kontrol runtime yaş/çekim, mekanizma kalitesi, seed çeşitliliği veya art kabulünü ispatlamaz.

## Değişmeyen kaynak ve yayın sınırı

Başlangıç manifestindeki 252 mevcut motor içerik dosyasının SHA'ları tekrar denetlendi: **0 değişiklik**. Beşli için üretim seçimi açılmadı. Konuklu meslek, deniz ve uzay ayrı teslimler olarak kaldı. Yeni artwork üretilmedi; hiçbir yeni pose/rule runtime onayı almadı. Push/deploy yapılmadı.

Aynı çalışma ağacındaki başka oturumun seçim portresi/CompanionStep düzenlemesi bu kaynak altyapısı tesliminin sahipliğinde değildir; geri alınmadı veya bu işin kod değişikliği olarak sahiplenilmedi.

## Uyumlulukta açık kalan sınır

Kaynak ref'i olmayan eski origin/plan için bugünkü katalog sürümü eşit diye kaynak atanmaz. Kitap metni ve önceden hazırlanmış bölümler okunabilir kalır; ancak kaynağı kanıtlanamayan yeni devam/yeniden yazım missing/ambiguous sonucu verir. Tarihsel yayın byte'ları ve doğrulanmış eşlemeler olmadan bütün eski yeniden yazımların desteklendiği iddia edilmez. Bu yayın öncesi uyumluluk açığı raporda görünür kalır.

P56 için runtime beat/state bağlama, kişiselleştirme, güvenlik/aile/recall kapsamları, 1.500 ilk-deneme örneklemesi ve tam sanat kapsam kabulü henüz yapılmadı. Pilot ve genel beşli politika bu kapılar ve ürün yayın kararı kapanmadan yayına girmez.

## Doğrulama kaydı

Güncel sonuçlar `verification-summary.json` içindedir. Eski uzun Debug koşuları tamamlanmış sayılmadı; sabit ID iyileştirmesinden sonra Release motor paketi ve ilgili gerçek iOS testleri yeniden başlatıldı. Önceki seçili iOS koşusunda 132 test içinde görülen tek hata, 9–10 öğrenme serisini desteksiz sanan eski beklentiydi; fixture artık desteklenen 9–10'u ve gerçekten desteksiz 11–12'yi ayrı denetler. Bu değişiklik ürün kapsamını değiştirmedi.

Son koşu: tam SwiftPM Release **1.122 test / 2 atlanan / 0 hata**, çıkış 0. Gerçek iOS simülatöründe seçili 13 sınıf **133 test / 1 atlanan / 0 hata**, `TEST SUCCEEDED`. Bu iOS sonucu tüm uygulama/UI test paketi olarak sunulmaz. 252 kaynak hash kontrolünde değişiklik yok; staged diff whitespace kontrolü temiz.
