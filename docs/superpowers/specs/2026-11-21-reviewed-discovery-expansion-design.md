# İncelenmiş nesne çizimlerinin kapsamını genişletme

Kullanıcının kaynak izine dayalı offline görsel havuzunu büyütme onayı ve 21 Kasım devam talebi uygulanır. Yeni UI veya anlatı yaklaşımı önerilmez.

## Kapsam

Çan yanında önceki v1 kurallarıyla zaten kullanılan on sabit çizim: yırtık harita, tek eldiven, eski fener, altın anahtar, mavi kristal, renkli tüy, deniz kabuğu, büyüteç, sağlam ip, kâğıt fener. Aynı beş 5–6 notice kaynağı ve 38 hatırlama satırı bu izole çizimler için yeniden okundu. Tam kararlar ve kanonik nesne özetleri research/2026-11-21-reviewed-discovery-expansion-decisions.json içinde. Boş yuva ve açık müzik kutusu dahil değildir.

## Tasarım

Mevcut politika 2, kaynak ve hatırlama listelerini paylaşan on bir açık subject/asset/fingerprint girdisine genişletilir. Yetkilendirme tek sonuçta asset ve kanıt döndürür; nesne doğrulamasıyla çizim seçimi ayrılamaz. Manifest sabit SHA ile, her asset dosyası digest ve ImageIO ile doğrulanır. Eski çan manifesti/pin dosyaları korunur. Kaydedilen art şeması ve politika sürümü değişmez.

StorySpotBinder önce mevcut v1 yolunu çalıştırır; sonra reviewed binder yalnız hâlâ görselsiz sayfalara bakar. Böylece eski geçerli v1 fixture aynı politika ve pin ile kalır. Yeni na_any ve uygun hatırlama sayfaları politika 2 alabilir. Kaynak sırası/tamlığı, metin/sayfa eşitliği, origin/kanonik nesne ve tek notice beat korumaları aynen kalır. Aile/özel gün/seri/nakarat/ek beat kapsam dışıdır. Mevcut görselin üzerine yazılmaz.

## Korunan sınırlar

Motor metinleri, seçim/seed dağılımı, kimlikler ve eski kitaplar değişmez. Runtime API yok. Auto etiketler reviewed yapılmaz. Yaşa göre görsel sayısı ve her masalda çizim henüz garanti değildir. Reader yerleşimi ve diğer oturumun Originals/Classic/ReaderImageLoader işleri değişmez.

## Kabul

On bir konu × beş kaynak ve 38 recall kombinasyonları; kanonik değişiklik, çapraz nesne, bilinmeyen/eksik/bozuk/sırası değişmiş parçalar; manifest/dosya bozulması; dışarıda kalan iki nesne; eski pin roundtrip ve reader decode doğrulanır. Gerçek composer çıktısıyla yeni on konunun map/save sonucu sınanır; test araması bounded olmalı. Ara test koşusu yapılmaz; final kontrol AGENTS gereği bir kez, gerçek hata varsa ilgili tekrar yapılır. Önceki seri uygunluğu hatası ayrı raporlanır.
