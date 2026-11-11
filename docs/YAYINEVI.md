# Yayınevi: basılı kitap, yıllık, hediye, haftalık ritim (Faz 12)

Vizyon planının üçüncü ayağı (`docs/VIZYON_PLANI.md`): MagicPaper bir çocuk
yayınevidir; masal yazılır, ciltlenir, bazen basılır. Bu belge Faz 12'de
uygulamaya girenleri ve uygulama dışında Batuhan'ı bekleyen işleri tutar.
Ödeme bu fazın dışında; hediye kutusu ve sipariş yalnızca tasarım olarak durur.

## Uygulamada olanlar (11 Kasım 2026)

### Baskıya hazır PDF

Ebeveyn alanı → Masal kitabı → "Baskıya hazır" anahtarı (`MPPrintSpec`).

| Özellik | Değer |
|---|---|
| Kesim boyu | A5, 148 × 210 mm (420 × 595 pt) |
| Taşma payı | 3 mm her kenarda; kâğıt rengi payın sonuna kadar serili |
| Kesim işaretleri | Dört köşede, taşma payının 2 pt dışında, 0,25 pt, kitabın mürekkep rengi |
| PDF kutuları | Her sayfada TrimBox ve BleedBox |
| Güvenli alan | Yazı ve sahne kesim çizgisinden en az 40 pt (14 mm) içeride |
| Sahne çözünürlüğü | 4× çizim, A5 sütunda yaklaşık 300 dpi |
| Yazı | Gömülü font (Nunito, Baloo 2) |
| Renk | RGB. UIKit CMYK yazamaz; dönüşüm basım ortağının ICC profiliyle (ör. FOGRA39) onların tarafında |

Ev için PDF değişmedi (kesim boyu, işaretsiz).

### Yıllık

Aynı ekranda "Yıllık" sekmesi (`MPYearbook`): "Bu yıl İrem'in dünyasında".

- Kapak, bir özet sayfası, ardından yılın bütün biten masalları okunduğu sırayla.
- Özet sayfası Faz 10 hafızasından kurulur. Tek satır sayı ("2026 yılında 12 masal, 4 yer, 5 dost"), sonra gidilen yerler, tanışılan dostlar, ilk ve son masal.
- Karne değil, anı defteri: puan, sıralama, "en çok okuyan" yok.

### Kalkan

"Basılı kitap yakında" sekmesi kalktı. Basılı kitap gerçek olana kadar uygulama onu vaat etmez.

## Uygulama dışında: basılı kitap pilotu (Batuhan)

1. **Basım ortağı:** Türkiye'de dijital baskı yapan tek bir ortak. A5, 170 g mat iç kâğıt, sert kapak ya da amerikan cilt.
2. **Prova:** ortağa bir baskıya hazır PDF gönderilir. Kesim, taşma payı, renk (özellikle mor #6A47B8 ve krem kâğıt) ve fontlar onların ön kontrolünden geçer.
3. **Pilot:** 10 kitap, tanıdık ailelerle. Ölçülecekler: renk sapması, cilt dayanımı, kargo süresi, birim maliyet.
4. **Kapak:** bugünkü PDF kapağı metin kapağıdır. Basılı kitap için kapak sanatı ve sırt (sayfa sayısına göre genişlik) ayrı iş.
5. **Karar:** pilot sonuçları ödeme turuna girer (sipariş, fiyat, KVKK'da adres verisi).

## Hediye kutusu (tasarım, ödeme turuyla)

- **İçerik:** basılı masal kitabı (çocuğun adıyla), Ragi kartpostalı, kutunun içinde bir sonraki masal için "kimler olsun" kartları. Plastik oyuncak yok.
- **Hediye eden:** büyükanne, teyze gibi uzaktaki aile. Çocuğun profiline dokunmaz. Kitap, ebeveynin onayladığı masallardan seçilir.
- **Yapılmayacaklar:** çocuğa satış, uygulama içinde çocuğa görünen bir "hediye iste" düğmesi, sınırlı süreli kutu.

## Haftalık içerik ritmi (Yoto Club deseni)

Uzaktan içerik akışı (`ContentFeed`, FAZ 15) haftalık yayın için hazır. Uygulama güncellemesi gerekmez.

- **Ritim:** her pazartesi bir "Bu haftanın seçkisi" (Masallar vitrini) ve bir yeni klasik. Yayın imzalı akıştan çıkar, `feedVersion` artar.
- **Kurallar:** bildirim yok, geri sayım yok, "kaçırma" yok (CLAUDE.md ilke 7). Geçen haftanın seçkisi kaybolmaz, kitaplıkta kalır.
- **Hat:** haftalık döngü Book Intelligence'tan beslenir (en yeni yayınlar önce). Yayın anahtarı ve deploy Batuhan'da (FAZ 15).
