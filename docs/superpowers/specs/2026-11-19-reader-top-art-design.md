# Onaylanan okuyucu referansına hizalama

19 Kasım 2026. Kullanıcı, nesne çizimlerini üstte daha büyük gösterme önerisini açıkça onayladı; kitap sayfaları, fontlar ve ayarların önceki `reader-concept-61.html` ve eklediği referansla uyumunu kontrol edip kodlamayı istedi. Yeniden onay beklenmiyor. Uygulama planı: `../plans/2026-11-19-reader-reference-alignment.md`.

## Kararlar

- Nötr spot çizimi artık metinden sonra değildir. Üst kontrol açıklığının altında, metinden önce gelir; görüntü kırpılmaz. İstenen yükseklik sayfanın %28’i, kalan metin bütçesinin en çok %45’i. Dar/yatay/AX durumunda isteğe bağlı spot küçülür veya kaldırılır. Kâğıdın kendisi zemin; kart, daire, yapay sahne veya yeni çocuk yok.
- Tam sahne mevcut üstten kenara yayılan davranışını ve iPad sahne spread’ini korur. Görselsiz ve eksik resimli sayfa aynı tipografiyle üstten metin sütunudur.
- Nunito600 gövde zaten referansla eşleşir. Çocuk adı Nunito800 ve tema vurgusudur. 17/19/22/26 boyutları, yaşa göre varsayılan, nefes satırlarının bir kademe büyük boyutu ve Rahat alt sınırı korunur. CSS line-height sayıları SwiftUI lineSpacing olarak kopyalanmaz. Velinin seçtiği boyut sıfırlanmaz.
- Alt kontrol tek cam yüzeyde iki sıra: sayfa/sesli oku; önceki/tutamağı görünen seek/sonraki. Kapat kalıcı, kalp/Aa bir üst grupta. Seçili kalp okuma vurgusunu kullanır. Seek’in ilk/son sayfa tutamak uçları 0/1’dir; longpress/scrub/VoiceOver/bitiş yolları korunur.
- Aa metni minimum 48 punto hedefle kendi iç boyutuna büyüyebilir; AX5’te kırpılmaz. Okuyucunun AX3 üst sınırı kaldırılır. Alt çubuk ve kelime kartı aynı geometri açıklığını kullanır. AX portrede üst kontrol satırı dikey, kompakt yatayda yataydır; yükseklik payı buna göre hesaplanır.
- Aa ayarlarında Yazı→Kâğıt→Daha fazla, canlı örnek ve mevcut dört duraklı slider korunur. Örnek yazı çerçevesiz kâğıt üstünde, kolay okuma sade satır, header kapat, Nunito kâğıt örnekleri ve seçili işareti. Tüm gelişmiş tercihler kalır; sistem görünüş tercihi okuma kâğıdına uyar; ana ayarlar beyaz kalır, canlı örnek seçili kâğıdı gösterir. Satır aralığı zemini açık liladır; sabit dönüş düğmesinin altı opaktır.

## Kaynaklar ve sınırlar

`design-handoff/proposals/2026-11-19-reader-reference-alignment/user-approved-reference.png` kullanıcı referansıdır; resimdeki kız/Ela örnek kurmaca içeriktir, uygulamaya görsel varlık olarak eklenmez. Eski BRIEF’in spot-after-text önerisi son kullanıcı onayıyla geçersizleşmiştir. Kaynak motor, sanat eşleme kuralları, görsel dosyaları, kimlik ve hikâye metinleri değişmez.

Kod incelemesinde scalable Aa’nın 48×48 içine sıkışması bulundu; minimum ölçüyle doğal büyüme sağlandı. Yerel kodda LocalizationManager bulunmadığı için mevcut Türkçe metin/token yaklaşımı sürdürüldü; yeni çerçeve eklenmedi.

## Doğrulama

Plan sonu seçili uygulama testleri, tipografi/geometri regresyonları ve gerçek 5–6 motor çıktısıyla 26 punto/Rahat/nefes satırları + tam chrome ve ayar renderları. Sabit viewport renderı ayrı fiziksel cihaz veya tüm gestür/ses/VoiceOver matrisi kanıtı sayılmaz. Sonuçlar hizalama raporuna kaydedilir.
