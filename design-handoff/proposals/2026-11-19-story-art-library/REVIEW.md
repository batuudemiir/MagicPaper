# Görsel ve mimari inceleme

19 Kasım 2026. Üretim onayı yerine geçmez. Yerleşik image_gen, onaylı referans ve gerçek saydam arka plan isteği kullanıldı. Üretilen resimler araç çıktılarında gözle incelendi; ilk altı ayrıca içerik uzmanı tarafından kaynak tanımlarıyla karşılaştırıldı.

## İlk altı

- Harita v1: sağ kenarı yırtık fakat yarım pafta hissi yetersiz. Seçilecek v2’de yaklaşık yarım pafta ve yırtıkta kesilen çizgi isteniyor. Dağ/nehir gibi somut ayrıntılar ayrıca sınır yaratır.
- Yuva: boş, sağlam; küçük dallar, lila yaprak/mercan süs ayrıntıları. Yumurta/yavru veya ağaca geri koyma sonucu yok. Saydam tek nesne zeminde olduğunu tek başına kanıtlamaz.
- Eldiven: tek, mercan örgü ve mor manşet. Başka renk/doku belirten metinde kullanılmaz. Katalogdaki genel eldivenin mitten yorumu da editoryal onay bekler.
- Anahtar: tek altın anahtar, kapı/kilit/açma eylemi yok.
- Müzik kutusu: açık kapak, görünür silindir ve krank. Yalnız bu görsel durumu destekler; kapalı/saklı içeriği gösteren metne uymaz. Eksik ezgi resimden doğrulanamaz.
- Kâğıt fener: renkli kâğıt kıvrımları, iç ışık ve askı halkası. Sönmüş/yırtılmış durumlar ayrı resim gerektirir. Askının sahneye bağlanması ayrıca ele alınır.

Tümünde ortak mat guaj, yumuşak biçim ve onaylı yardımcı palet korunuyor. Çocuk/Ragi/yeni karakter, marka yazısı ve afiş yerleşimi yok. Harita/müzik kutusunda beyaz boya kenarları görülebilir; alfa saçaklanması mı yoksa boya dokusu mu olduğu gerçek beyaz/gece okuyucu kâğıdında cihazda değerlendirilmelidir. Bu turda kâğıt üstü kompozit veya simülatör kontrolü yapılmadı.

## Mimari çapraz inceleme

Motor uzmanı tasarım/ilk envanteri kaynakla karşılaştırdı; olgusal bloklayıcı bulgu yok. Nötr spot bağlaması B2 guard’ının tümünün dışında olmalı (bayrak + kit + library + drawable avatar). B2 Release false / DEBUG default true. ReaderImageLoader yalnız Stories yerel dosyalarını çözüyor; bundled/asset katalog adı desteği varsayılmıyor. Tamamlanan kitaplar kayıtlı resmi gösterebilir; opensAsTextOnly okunabilir, tamamlanmamış kayıtların sanatını bastırır.

Örnek blueprint/varyant ilişkileri çalışan composer çıktısı değil, incelenmesi gereken aday kanıtlardır. Trait sayıları gerçek kapsama değildir. Ham envanter 33 nesne; her kayda durum/gerekçe yazıldı. Sonraki entegrasyon fazında seçilmiş bütün sayfanın, destek beat/recall/aile cümleleriyle birlikte incelenmesi gerekir.

## Destek altılısı

Araç çıktılarında gözle incelendi: deniz kabuğu boş, mavi kristal gerçekten mavi ve içi aydınlık, eski fener taşınabilir camlı fener (deniz/kâğıt feneri değil), büyüteç tek nesne, tüy tek ve renkli, ip kalın ve iki ucu görünür. Konu dışında çocuk/hayvan/eylem eklenmedi. Kristal ve eski fener yalnız ışıklı durumlara; ip yalnız sağlam ve gevşek sarılmış duruma adaydır. Büyütecin renkli camının arkasında sahne varmış gibi kompozit yapılmaz. Tam sayfa/variant uygunluk ve gece kâğıdı kenarları henüz doğrulanmadı.

## Harita revizyonu

v2–v4 uzun dikey paftalarda istenmeyen yarı saydam hale verdi; seçilmedi ve çalışma klasörüne final olarak taşınmadı. v5 yeni üretim: belirgin üçgen yarım pafta, kesik rota ve orman çizimi, dış alanda belirgin hale yok. Yarım olma okuması güçlendi; fakat araç orman/tepe çizimi ekledi. Bu nedenle genel her harita yerine bu görsel özelliklerle çelişmeyen metne adaydır. v1 yalnız karşılaştırma/tarihçe için korunur; manifest v5’i seçer. Tüm revizyon promptları ve kaynak yolları kaydedildi.
