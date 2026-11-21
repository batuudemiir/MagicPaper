# Statik görsel havuzu — ilk genişleme çizimleri

20 Kasım2026. Kullanıcının devam talebiyle, Claude’un engine/provenance/visualKeys sahipliğine dokunmadan üç yeni aday çizim hazırlandı. Built-in image_gen kullanıldı; runtime API veya CLI kullanılmadı. Onaylı guaj referansı her üretime verildi. Bu set runtime manifest değildir ve görselli sayfa garantisi sağlamaz.

| Dosya | Kanonik konu | Kullanım koşulu |
|---|---|---|
| silver-bell-v1.png | object_bell_001 | Küçük gümüş çanın gerçekten görüldüğü/mevcut olduğu anlam. Kaynağı belirsiz ses için otomatik kullanılamaz. |
| blue-curtain-window-v1.png | setting_blue_curtain_room_001 | Mavi perdenin yarı aralık ve bahçe manzarasının uygun olduğu pencere detayı. Her oda veya uyku sayfasına genel dekor olarak bağlanmaz. |
| moon-window-v3.png | setting_moon_window_room_001 | Hilalin görünür olduğu gece pencere detayı. Farklı ay evresi/kapalı perde/gündüz içeriğine otomatik uygulanmaz. |

Çan önceliği gerçek telefonda bildirilen eksik keşif konusundan geliyor. Pencere detayları kişi, yatak sayısı, aile yapısı veya kişiselleştirilmiş çocuk görünüşü iddia etmeden mekân bankasını büyütür. Gözle incelemede ilk ay penceresinde desteklenmeyen tepe/ağaç ve dış hale görüldü. İlk düzeltme manzarayı kaldırdı ama haleyi korudu; iki taslak elendi, üretime/paketlemeye alınmadı. Son aday kompakt, halesiz ve manzarasız üretildi. Kaynak generated çıktıları silinmedi.

## Prompt seti

Her promptun temel girdisi `marketing/social/brand/references/instagram-art-direction-v1.png`; yalnız mat guaj doku/biçim/palet referansı. Reklam yazısı, logo veya insan kimliği alınmadı. Saydam zemin istendi.

- **Çan:** one isolated small SILVER BELL; rounded dome, simple ring handle, visible rounded clapper, stationary three-quarter view; matte cool-lilac silver/pewter with restrained turquoise reflection and plum shadow. No ribbon, face, sound lines, ground, magic, text or invented owner. Canonical subject only establishes small silver bell.
- **Mavi perde:** one compact square window, two half-open blue curtains, lilac frame, minimal indistinct garden foliage inside panes; no recognizable trees/flowers, no sun/moon/weather, no full room/bed/people/animals/toys. At least20% transparent margin, no halo/wallpatch/drop shadow, matte gouache.
- **Ay penceresi son sürüm:** one wide lilac window without curtains/rod; four dark-purple night panes and one small pale crescent moon; rectangular softly rounded frame and short sill. No plants/garden/hills/clouds/stars/full room/bed/characters. Center60%canvas, clean silhouette against transparent margins, no glow/wallpatch/shadow. Approved brand reference plus clean-silhouette blue-curtain candidate as composition reference.

Bunlar son üretim talimatlarının anlamsal kaydıdır; araç çağrısındaki daha uzun negatif/kompozisyon ayrıntıları sohbet tool kaydında bulunur. Görsel dosyaları düzenlenmedi veya Python ile rötuşlanmadı; yalnız çıktılar kopyalandı ve PIL ile mod/alfa/ölçü okundu.

## Doğrulama ve entegrasyon sınırı

`candidates.json` exact SHA256, boyut, RGBA/alfa extrema, nontransparent bounds ve generated kaynak dosya adlarını taşır. Üçünde de alpha0–255 mevcut, dosyalar gözle incelendi. Alt açıklamalar taslaktır; semantic binding onayı değildir. Claude’un visualKey adlarını çoğaltmamak için `visualKeys:null`; motor şeması/commit’i geldikten sonra canonical konu+durum→visualKey→asset/revision eşlemesi tamamlanacak.

Uygulama `StoryPage.art` kullanmaya devam edecek; ikinci picture modeli yok. Bu tur StorySpotBinder/StorySpotCatalog, Models/Story.swift, OfflineStoryMapper, ComposedPage, içerik metinleri, seçim dağılımı ve telefondaki build değişmedi. Build/test/simülatör çalıştırılmadı; bu tur yalnız raster üretim ve dosya incelemesidir. Eski kitaplar yeniden üretilmedi, telefondaki çan kitabı otomatik resimlenmedi.
