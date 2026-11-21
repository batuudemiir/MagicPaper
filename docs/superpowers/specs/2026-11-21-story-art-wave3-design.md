# Guaj nesne havuzu: üçüncü genişleme

Kullanıcının görsel havuzunu genişletmeye devam talebi uygulanır. Kaynak izine dayalı offline yaklaşım ve onaylı çizim dili korunur. Yeni konu kümesi: object_ball_001, object_jump_rope_001, object_kite_001, object_flute_001, object_mirror_001, object_ribbon_001.

## Görsel ve anlam sınırı

Tek kırmızı yuvarlak top; tek uzun atlama ipi, bir mavi ve bir sarı sap; renkli kurdele kuyruklu kâğıt uçurtma; tahta flüt; hiçbir kişi/sahne yansıtmayan küçük el aynası; yay yerine uzun kırmızı ipek kurdele. Hepsi tek somut, sağlam, durağan nesne ve saydam zemin. Yeni sahne, çocuk veya Ragi kimliği yok. Görseller yerleşik image_gen ile onaylı referanslar eklenerek üretilir, gözle incelenir ve PNG byte'ları mpart olarak paketlenir.

## Yayın sözleşmesi

14→20 kanonik konu. Yeni wave3 manifesti, önceki 14 girdiyi ve 20 notice / dört paired destek / üç blueprint / 38 recall kaydını aynen taşır. Nesne adları, betimleri ve trait'leri kanonik fingerprint ile sabitlenir. Yeni çizim revizyonu ve dosya SHA'sı ayrı açık kayıttır. Yeni nesneler aynı incelenmiş varlık cümleleriyle çelişmez; eylem veya sahne için yetki vermez.

Bağlayıcı, kaynak doğrulaması, v1 önceliği, küçük yaşta yalnız üç spor blueprint'inin sayfa1 notice→meet biçimi ve kayıt şeması değişmez. Yeni manifestin SHA/reviewID/sayım kaydı eklenir. Eski üç manifest ve asset dosyaları okunabilir kalır; bozuk yeni manifestte sessiz fallback yok. Yalnız loader'ın mevcut sürüm/sayım doğrulamasını daha anlaşılır yapmak için dosya içinde kapalı bir revision tablosu kullanılabilir; yetki genişletilemez.

## Gerçek seçim koşulları

Top, atlama ipi ve uçurtmanın habitat'ı village; küçük yaş spor biçiminde Köy Çayırı (setting_village_green_001) açık ve hava koşullu olduğu için uygun örnek. Kurdele impliesNeed taşıdığı için bu üç spor blueprint'inde seçilemez; küçük yaşa zorlanmaz. Flüt/mirror trait olarak uygun olabilir; uygun gerçek büyük yaş örnekleriyle doğrulanır. compatibleThemes metadata'sı composer'ın doğrudan seçim koruması değildir; yanlış tema yasağı iddia edilmez. Her nesnenin her yaşta veya her masalda çıkması garanti değildir.

## Kabul

Testler koddan önce yazılır, AGENTS gereği yalnız finalde çalıştırılır. Altı yeni nesne için gerçek compose→map→metin eşitliği→pin→kaydet/decode kanıtı, küçük yaş oyuncak örnekleri, önceki14manifest load uyumu ve 20 reader decode gerekir. Mevcut olumsuz kaynak/paired/corruption testleri korunur. Bu tur motor/metin/seed/seçim/reader UI değişikliği yok; dolayısıyla motor testleri önceki 44/0 sonucundan sonra sebepsiz tekrarlanmaz. Seçili app testleri finalde çalışır; gerçek failure varsa ilgili düzeltme/tekrar raporlanır.
