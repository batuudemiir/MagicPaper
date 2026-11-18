# Uygulama illüstrasyon yönü — onay bekleyen öneri

17 Kasım 2026. Kapsam: mevcut sanatın değerlendirmesi ve tek karşılama ekranı konsepti. Uygulama kodu ve Assets kataloğu değiştirilmez.

## İncelenen kaynaklar

AGENTS.md, docs/PROJE_HAFIZASI.md (ana sayfa, çocuk alanı, Ragi ve canlılık kararları), docs/RAGI.md; marketing/social/brand/ART_DIRECTION.md; onaylı referans ve prelaunch-mobile-v1 içindeki üç PNG. Mevcut OnboardingView, StoryModeStep, MPStateView, MPHomeChrome ve Scenes/Brand varlıkları.

## Bulgular

- Karşılama: 160 pt onBook Ragi, ortalanmış vaat, açıklama, Başlayalım ve güven cümlesi. Tek ekran korunur.
- Ana sayfa: homeSceneDay ayrıntılı mavi/yeşil panoramik manzara; sosyal referansın sade mor/lila/turkuaz guaj dilinden ayrılıyor. Ragi ayrı katman; bu mimari korunmalı.
- Mod seçimi: StoryModeStep üç CreationChoiceRow içinde MPIconTile gösteriyor. Scenes/mode-* SVG dosyaları mevcut ama güncel mod seçiminde kullanılmıyor. Eski dosyayı değiştirmek tek başına ekranı değiştirmez.
- Boş durum: MPStateView 200 pt sahnede 190 pt Ragi + elips kullanıyor. Yeni düzen ortak bileşenden yürütülmeli. Ebeveyn alanı resimsiz; mevcut Ragi'nin yanına ikinci Ragi eklenmez.

## Önerilen ölçekler (tasarım hedefi, mevcut ölçü değil)

| Yer | Görsel alan | Yaklaşım |
|---|---|---|
| Karşılama | yaklaşık 300 × 240 pt | Beyazda açık kitap ve küçük masal dünyası; mevcut onBook Ragi ayrı katman |
| Mod satırları | 64–80 pt | Uyku: ay/yastık; öğrenme: filiz/büyüteç; macera: patika/çadır. Her birinde 2–3 büyük biçim. Satır hedefi en az 72 pt, ihtiyaçta büyür. Ragi yalnızca mevcut alt rehberde |
| Çocuk boş durumları | 160–200 pt | Tek mevcut Ragi pozu + en fazla bir anlamlı nesne; başlık, tek cümle ve eylem korunur |
| Küçük ana sayfa sahneleri | 120–180 × 80–120 pt | Metinden ayrı, kırpılabilir sade vinyet; tek Ragi kuralı korunur |
| Ana sayfa panoraması | mevcut kapsayıcı ölçüsü | Sonraki turda aynı kompozisyon görevinde sade guaj; gündüz/gece birlikte ele alınır |

Tüm sayfayı boyamak yerine orta ölçekli vinyet önerilir. Tam ekran sanat seçeneği metin ve seçim alanını daraltır; yalnızca minik süsler ise yeni dili yeterince taşımaz. Arayüz beyaz; açık lila yerel ve ölçülü kullanılır. Krem/bej ana zemin yok. Okuyucunun isteğe bağlı kâğıt temaları kapsam dışı.

## İlk ekran önerisi

393 × 852 pt referans alanda yaklaşık 300 × 240 pt sanat; ardından mevcut başlık, açıklama, 64 pt Başlayalım düğmesi ve mevcut güven cümlesi. Başlık Baloo 2 cover (34), gövde Nunito body (17), güven cümlesi footnote (13). Yazı illüstrasyona gömülmez. Küçük ekran ve büyük metinde sanat küçülür, içerik kayar; eylem kırpılmaz. Üretilen pano kavramsal yerleşimdir; font/metin ve karakterin birebirliği gerçek uygulama katmanlarında doğrulanmalıdır.

Ragi'nin mevcut onBook görseli kimlik referansı; yüz, göz bandı, mor tüy, krem karın/yüz, kuyruk, oranlar ve poz sabit. Nihai entegrasyonda mevcut MascotImage kullanılmalı; üretilmiş Ragi kopyası varlığın yerine geçirilmemeli. Yeni çocuk karakter çizilmedi. Sonraki çocuklu sahnelerde ChildProfile ve Character Bible kimlik kaynağı; sosyal medyadaki örnek kız bütün çocukların sabit kahramanı yapılmaz.

## Üretim ve sonraki adım

Yerleşik ChatGPT image_gen; stil için instagram-art-direction-v1.png ve 03-bugun-nasil-bir-masal.png, kimlik için resmî mascotOnBook.png referansları. Sosyal afiş/telefon portalı kopyalanmaz. Mat guaj, boyalı kâğıt, yumuşak kenar, mor/lila/turkuaz ve küçük mercan vurguları; beyaz negatif alan. Parlak 3B, neon, yoğun parıltı yok.

Onaydan sonra: önce karşılamaya ayrı metinsiz sahne varlığı + mevcut Ragi ile entegrasyon; ardından modlar, boş durumlar, ana sayfa sahneleri. Her aşama ayrı görsel inceleme. Bu turda derleme/test/simülatör çalıştırılmadı; SwiftUI uygulaması yapılmadı.
