# Offline masal görsel havuzu · 19 Kasım 2026

Kaynak kodunun statik incelemesi; aşağıdaki adaylar çalışan motorla örneklenmiş veya üretim eşlemesi onaylanmış sayılmaz. İlk çizimler konu taslaklarıdır. Her nesne mevcut metin kataloğunda bulunur.

## Katalog durumu

Pilot kütüphane + shared v2: 36 blueprint (20: 5–6, 4: 3–4, 6’şar: 7–8 ve 9–10), 33 nesne kaydı, 26 yol arkadaşı kaydı, 28 mekân kaydı. Bunlar ham kayıt sayılarıdır; eksik trait içeren eski kayıtlar her seçimde uygun değildir. Eski belge girişindeki 15 blueprint tablosu güncel değildir.

| İlk set | Katalog kimliği | Kaynak | Aday metin kanıtı | Görsel sınırı |
|---|---|---|---|---|
| Yırtık harita | object_torn_map_001 | pilot_library_v1.json | blueprint_unexplained_reading_001, p1 / notice_anomaly / na_neutral_01 | Yarısı eksik; çözülmüş rota ve okunur yazı yok |
| Düşmüş yuva | object_fallen_nest_001 | pilot_library_v1.json | bp_charge_tending_001, p1 / na_neutral_01 | Sağlam, boş; yumurta/yavru ve ağaca geri koyma yok |
| Tek eldiven | object_dropped_mitten_001 | pilot_library_v1.json | blueprint_appeal_together_001, p1 / na_neutral_02 | Tek küçük eldiven; sahip/çift/kavuşma yok |
| Altın anahtar | object_key_001 | shared_content_library_v2.json | bp_absence_retracing_002, p1 / na_neutral_01 | Altın; kilit/kapı/açma eylemi yok |
| Eski müzik kutusu | object_music_box_001 | shared_content_library_v2.json | blueprint_unexplained_reading_001, p1 / na_neutral_01 | Küçük ahşap kutu; balerin/nota/ışık yok |
| Kâğıt fener | object_paper_lantern_001 | shared_content_library_v2.json | bp_absence_retracing_002, p1 / na_neutral_01 | Asılabilir renkli kâğıt fener, yumuşak iç ışık |

Dosya kökü: `StoryEngine/Sources/StoryEngine/Resources/`. Pilot `blueprints/` altında; shared v2 `templates/offline/v2/` altında. Varyant kanıtı `templates/v3/beat_notice_anomaly.json` içindedir. Sayfadaki diğer beat’ler, mekân, bant ve gerçek seçilebilirlik ayrıca denetlenmelidir.

## Sıradaki setler

1. Parlak deniz kabuğu (pilot ve shared kayıtları otomatik birleştirilmez), mavi kristal; görsel durumları ayrı tutulur.
2. Kestane, Pamuk, Tarçın: önce kanonik karakter referansları ve tür/renk/oran çizelgesi. Mevcut Kestane denemesi kanonik onay değildir. İlk nesne setinde yeni karakter yok.
3. Gerçek mekân ayrıntıları: seçilen setting kimliğiyle sınırlı; genel orman sahnesi bütün masallara dağıtılmaz.
4. Eylem/durum setleri: ancak actor/target/state sözleşmesi yazıldıktan sonra. Solan→iyileşen fide, onarılmış yuva, bulunan sahip bugün güvenli eşleşme değildir.
5. Uzay nesneleri: kaynakta editoryal taslak notu var; içerik onayı sonrası.

Deniz feneri mevcut kaynaklarda bulunamadı. Eski el feneri ile kâğıt fener farklıdır; bu isteğin örneğinden yeni bir hikâye nesnesi çıkarılmadı.

## Tekrar kullanım potansiyeli

Yalnız discovery-trait statik ön filtresi: harita 19/36, anahtar 11/36, yuva/kristal 10/36, eldiven/müzik kutusu/kâğıt fener 8/36 blueprint ile uyumlu görünüyor. Mekân/habitat/cast/mode/template/variant sonrası gerçek kapsama daha az olabilir. Bunlar çalışma zamanı kapsama yüzdesi değildir.

Önceki pilot: 24 kitap/192 sayfa; 48 resim eşlemesi. isClean 24/24 olmasına rağmen 6/24 fide anlatısında ışık dili, tüm p7 sonuçlarında Kestane hedefi vardı. Ad değişince 12/12 tohum çiftinde varyant değişti. Kaynak: `../2026-11-18-offline-art-pilot/REPORT.md`.

## Destek seti (7–12)

Bu nesneler shared v2 kataloğunda tanımlı; sayfa/variant izin listeleri bu turda hazırlanmadı. Şimdilik yalnız resim havuzu taslaklarıdır.

| Konu | Katalog kimliği | Durum/sınır |
|---|---|---|
| Deniz kabuğu | object_shell_001 | Boş kabuk; pilot kabuk kimliğine kendiliğinden bağlanmaz |
| Mavi kristal | object_crystal_001 | Mavi, parlayan taş; kaybolma/açı varyantı ayrıca incelenir |
| Eski el feneri | object_lantern_001 | Taşınabilir fener, hafif iç ışık; deniz feneri değil |
| Büyüteç | object_magnifying_glass_001 | Tek cam nesne; inceleme eylemi/öznesi yok |
| Renkli tüy | object_feather_001 | Tek yumuşak kuş tüyü; tür/sahip tahmini yok |
| Sağlam ip | object_rope_001 | Kalın ip, iki sağlam uç; düğüm/bağlama sonucu yok |

Tüm 33 nesnenin kaynak, durum ve ertelenme gerekçesi `subject-inventory.json` içindedir. 12/33 hazırlanmış çizim sayısıdır; masal/sayfa kapsaması değildir.
