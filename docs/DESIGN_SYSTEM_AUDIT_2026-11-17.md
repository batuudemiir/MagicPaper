# MagicPaper tasarım sistemi denetimi

Tarih: 17 Kasım 2026. Kaynak: yerel `main`. Kapsam: 273 Swift dosyasında statik tarama; DesignSystem içindeki 27 Swift dosyasının envanteri; düğme, dairesel düğme, çip, segment, anahtar, metin alanı, onay kutusu ve boş/hata durumu üzerinde odaklı inceleme (8 bileşen). Tam ekran veya erişilebilirlik kabul testi değildir.

## Sonuç

6 bulgu grubu: 3 erişilebilirlik riski, 1 token mimarisi tutarsızlığı, 1 token kullanım borcu, 1 belge eskimesi. Görsel ve cihaz doğrulaması yapılmadığından 100 üzerinden puan verilmedi.

## Öncelikli bulgular

| Öncelik | Kaynak | Bulgu | Öneri |
|---|---|---|---|
| P1 | `MagicPaper/DesignSystem/Pastel/MPControls.swift:71`, `MPLayout.swift:54` | Segment seçenekleri minimum 40 pt; ortak 48 pt dokunma tabanı sağlanmıyor. Büyük yazıda büyüyebilmesi varsayılan boyutu düzeltmez. Okuma ayarları ve çocuk gardırobu dahil canlı tüketicileri var. | Seçenek hedefini en az `MP.S.tapMin` yap; bitişik hedeflerin çakışmadığını doğrula. |
| P1 | `MagicPaper/DesignSystem/Pastel/MPControls.swift:132` | MPTextField özel fontla büyürken alan yüksekliği 52 pt sabit. En büyük Dynamic Type için kesilme riski var; simülatörde doğrulanmadı. | Sabit `height` yerine içerikle büyüyen `minHeight` ve dikey token boşluğu kullan. |
| P1 | `MagicPaper/DesignSystem/Pastel/MPControls.swift:64,88` | Segment ve anahtar doğrudan `withAnimation(MPMotion.spring)` kullanıyor; yerel Reduce Motion kontrolü yok. | `withAnimation(MP.M.gated(MP.M.spring))` kullan; hareket azaltıldığında durum değişimi korunmalı. |
| P2 | `MagicPaper/DesignSystem/MPTheme.swift:20`, `Pastel/MPLayout.swift:6,80`, `Pastel/MPTypography.swift:70`, `Pastel/MPColor.swift:6` | “Tek kaynak MPTheme” sözleşmesi uygulamayla örtüşmüyor. MP.C asset tabanlı MPColor'a yönleniyor; boşluk, hareket ve font tanımları ayrı ailelerde. Bunlar tamamen bağımsız iki sistem değil; köprülerle bağlı, sahipliği belirsiz bir yapı. | Her kategori için gerçek kaynak ve izinli tüketici API'sini belgele; sonra mevcut değerleri koruyan alias geçişi planla. |
| P2 | `MagicPaper/DesignSystem/MPSurfaces.swift:101,102,119`, `Pastel/MPButtons.swift:30,38`, `Pastel/MPControls.swift:27` | Paylaşılan bileşenlerde çıplak boşluk/ikon ölçüleri sürüyor. `.padding` taraması bunların yalnızca bir bölümünü yakalıyor; HStack/VStack spacing ve koşullu değerleri kapsamıyor. | Önce ortak bileşenlerde semantik token kullan; çizim geometrisini arayüz boşluğundan ayır. |
| P2 | `docs/MagicPaper_Design_System.md:1` | Eylül envanteri MPInput/MPSwitch/MPEmptyState gibi eski adları ve “hata durumu yok” bilgisini taşıyor. Güncel ortak boş/hata bileşeni MPStateView. | Tarihsel envanteri açıkça etiketle; güncel API, varyant ve durum tablosunu ekle. |

## Adlandırma ve token kapsamı

| Kategori | Mevcut kaynaklar | Tarama / değerlendirme |
|---|---|---|
| Renk | MP.Palette, MP.C, MPColor, Colors asset kataloğu | Hex eşleşmeleri kapak sanatı da içerdiğinden doğrudan ihlal sayısı değildir. Kapak paleti istisnası korunarak ayrı değerlendirilmelidir. |
| Boşluk | MP.S, MPSpacing, MPSize | 7 satır doğrudan sayısal `.padding(...)`: 3 ortak toast yüzeyinde, 4 Preview dosyalarında. Koşullu padding ve stack spacing bu ölçüme dahil değil. |
| Tipografi | MP.F, MPTextStyle, Font.mp | MPTheme dışında 9 `.custom` satırı: 3 merkezi MPTypography tanımı, 6 avatar/kapak/yay metni çizimi. Bu 6 satırın dekoratif ölçeklenme ihtiyacı ayrı ele alınmalı; otomatik olarak gövde fontuna çevrilmemeli. |
| Gölge | MP.Sh, MPShadow | 6 noktalı `.shadow(` eşleşmesi: 1 merkezi uygulama, 2 kapak sanatı, 3 Preview. Farklı yazılmış merkezî `return shadow(...)` bu sayımda yok. |
| Hareket | MP.M, MPMotion | Kontrollerde iki doğrudan spring çağrısı; Reduce Motion geçidi uygulanmıyor. |
| Font sabit boyut overload'u | Font.custom fixedSize | `fixedSize:` eşleşmesi 0. Bu sonuç View.fixedSize(horizontal:vertical:) kullanımını yasaklamaz. |

Ölçümler yorum satırları hariç metin taramasıdır. AST, target üyeliği veya çalışma zamanı görünürlüğü ölçümü değildir; Preview ve yardımcı kod dahil olabilir. Token tanımı sayısını kullanıcıya görünen ihlal sayısı gibi sunmak doğru değildir.

## Bileşen kapsamı

| Bileşen | Varyant / durum | Açık konu |
|---|---|---|
| MPButton | primary, secondary, outline, ghost, danger; regular/small/auth/hero; loading/disabled | Etiket korunuyor, yüklemede etkileşim kapanıyor; simge ve padding token borcu var. |
| MPCircleButton | dolgu, tint, bordered, boyut | Varsayılan görsel 42 pt; contentShape genişletiliyor. Gerçek 48 pt hedef ve komşu çakışması cihazda ölçülmeli. |
| MPChip | solid/dashed; selected trait; ayarlanabilir yükseklik | Varsayılan 38, çocuk token'ı 44. Kullanım bağlamı ve hedef alanı ayrıca doğrulanmalı. |
| MPSegmented | seçili durum; erişilebilir yazıda dikey düzen | 40 pt hedef ve Reduce Motion eksikleri. |
| MPSwitchStyle | açık/kapalı; toggle trait ve Türkçe değer | Reduce Motion geçidi eksik. |
| MPTextField | label/helper/error | Büyüyen metin için sabit yükseklik riski; label ve hata duyurusu VoiceOver ile doğrulanmalı. |
| MPCheckbox | selected trait | Minimum hedef yüksekliği tanımlı değil; uzun etiket yüksekliği duruma bağlı. VoiceOver durum anlatımı cihazda doğrulanmalı. |
| MPStateView | maskot, ton, başlık, mesaj, extra/actions | Ortak boş/hata yüzeyi mevcut; eski envanterde eksik. |

## Uygulama sırası ve doğrulama

1. Ortak kontrollerin hedef alanı, büyüyen metin ve hareket azaltma eksiklerini düzelt.
2. Gerçek token sahipliği tablosunu ve güncel bileşen belgelerini tamamla; değerleri değiştirmeden geçiş yolu tanımla.
3. Paylaşılan bileşenlerdeki token dışı ölçüleri temizle, ardından tüketici ekranlarına ilerle.

Bu tur uygulama kodu değiştirilmedi. Build, test, simülatör, VoiceOver ve kontrast ölçümü çalıştırılmadı. Sonraki kod turunda açık/koyu tema, en büyük Dynamic Type, küçük/büyük iPhone ve Reduce Motion matrisi tek kapanış doğrulamasında yapılmalı.
