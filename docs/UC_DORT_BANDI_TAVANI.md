# 3-4 bandının tavanı: iki mekanizma, ve bu bir eksiklik değil

**Tarih:** 23 Ekim 2026 · **Dal:** `faz-21-varyasyon` · **Durum:** karara bağlandı

## Bulgu

3-4 bandı iki olay örgüsü mekanizması taşıyor (`lookingAfter`, `lettingGo`) ve
**üçüncüsü yapısal olarak imkânsız.**

Sebep tek bir yerde kesişen iki kural:

1. **Bandın editoryal tüzüğü** (3-4 korpusunun kendi `editorialNote`'u):
   *"tek olay, tek sorun, çıkarım yok... geriye dönüş yok, yanlış inanç yok,
   aşılacak engel yok."*
2. **Beat durum modeli** (`StoryBeat.requires`): çözümü getiren her beat
   (`solutionKnown` üreten) çocuğun bir eylemidir, ve neredeyse hepsi ya
   `obstacleNamed` ya `beliefFormed` ister.

İkisi birlikte uygulandığında ayakta kalan beat sayısı: **iki.**
`patient_wait` (yalnızca `attemptMade` ister) ve `let_go` (`committed ∧
attemptMade ∧ needKnown`). Diğer on üçü engel ya da yanlış inanç istiyor, yani
bu bandın tüzüğüne giremiyor.

## Karar

**Bandın tüzüğü değişmeyecek, konu kapısı da indirilmeyecek. 3-4 bandı
bilerek konusuz kalıyor.**

Üç gerekçe, üçü de üründen:

**1. Tüzük doğru yazılmış.** *"Bu bant 5-6'nın kısaltılmışı DEĞİL"* cümlesi bir
sınırlama değil bir tanım. Üç yaşındaki bir çocuğun masalında aşılacak bir
engel ve yanlış bir inanç olmaması, eksiklik değil o yaşın masalının ne olduğu.
Tüzüğü gevşetip üçüncü mekanizmayı açmak, 3-4'ü 5-6'nın kısaltılmışına
çevirirdi — tüzüğün önlemek için yazıldığı şeye.

**2. Konu kapısını 3-4 için ikiye indirmek, kapının anlamını bozar.** Kapı
(`CatalogStoryTopic.minimumMechanisms = 3`) bir konunun "aynı masalın dekoru
değişmiş hâli" olmasını engellemek için var. Bandına göre esneyen bir eşik,
eşik değil tercihtir; ve ilk sıkışan turda yine inerdi.

**3. Alt kategori bu bantta ürünün istediği şey de değil.** CLAUDE.md'nin
ebeveyn ilkesi şunu söylüyor: *"Ebeveyne, MagicPaper'ın zaten bildiği bir şey
sorulmaz"* ve sadelik bir sütun. Üç yaşındaki bir çocuk için masal yazdıran
ebeveyne alt kategori menüsü açmak, iki şekli olan bir havuza üç şeklik vaat
koymaktır. İki mekanizma o yaş için sağlıklı bir repertuar: kitap araştırması
3-4 kitaplarının 60-166 kelime ve tek olay olduğunu söylüyor (kanıt LOW).

**Yani:** 3-4'te mod seçilir (uyku öncesi, öğrenelim), konu seçilmez. Bu
kendiliğinden böyle oluyordu; karar onu kaza olmaktan çıkarıp ürün kararı
yapıyor.

## Bu kararın değiştirebileceği tek şey

Beat dağarcığına, engel ve yanlış inanç istemeyen **yeni bir çözüm beat'i**
eklenirse 3-4 üçüncü mekanizmaya kavuşur ve konu kapısı kendiliğinden açılır.
O beat'in ne olduğu gerçek bir soru: üç yaşındaki bir çocuğun masalında
"çözüm", beklemek ve bırakmak dışında ne olabilir? Kitap araştırmasının
listesindeki şekiller (sayma-eksilme, tekrarlanan istek, keşif yürüyüşü) bu
soruya aday cevaplar, ama her biri yeni bir beat ve yeni bir durum tanımı
demek — yani ayrı bir tur, ayrı bir karar.

Bugünkü karar: o turu açmıyoruz, ve 3-4'ün iki mekanizmasını eksik saymıyoruz.
