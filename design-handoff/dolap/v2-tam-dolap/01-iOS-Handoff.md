# Uygulamaya aktarım

## Bir çocuk aradığını nasıl bulur?

**Kahramanım** insanın görünüşünü, **Giysiler** giyilen parçaları, **Aksesuarlar** son dokunuşları taşır. Üst düzeyde üç sabit bölüm vardır. Her birinde ikinci sıra yatay kayar. Yalnız ürün rafı dikey kayar. Seçili nesnenin adını ve tikini göster. Göz rengi gibi küçük bir detayda portreye yaklaş, ayakkabı ve etek seçiminde ayakları kadraja geri al. Çocuk yakın planı elle değiştirebilir. Ekran düzeyinde tek bir mor birincil eylem vardır.

## Durum sözleşmesi

| Kullanıcı hareketi | Beklenen sonuç |
|---|---|
| Farklı başlangıç yüzüne dokunur | Yüz, ten, saç ve göz alanları değişir. Giysiler ve takılı aksesuarlar korunur. Tek geri alma ile eski kimlik geri gelir. |
| Hazır kombine dokunur | Üst, alt, tek parça ve ayakkabı birlikte seçilir. Kimlik, gözlük, başlık ve çanta korunur. |
| Elbise veya tulum seçer | Üst ve alt kayıtta saklı kalır. Sahne tek parçayı gösterir. “Üst ve alta dön” önceki ikiliyi geri getirir. |
| Tek parça üzerinde başka ayakkabı seçer | Yalnız ayakkabı değişir. Üst veya alt seçerse iki parçalı giyime geçer. |
| Başörtüsü takar | Başlık yuvası güncellenir. Saç modeli ve rengi korunur, çizimi örtülür. Gözlük yüzün önünde kalır. |
| Başörtüsüyle saç değiştirir | Seçim saklanır. Kısa metin saçın örtünün altında kalacağını açıklar. Başlık çıkarıldığında son seçim görünür. |
| Şapka takar | Büyük topuzun şapka tepesinden çıkmasını önlemek için saçın üst kısmı maskelenir. |
| Peş peşe dener | Son tercih etkin olur. Geri al yalnız bir adım geri döner. Hareketi Azalt seçiliyse prova hareketi kapanır. |
| Kaydetmeden çıkar | Değişmiş taslakta çıkış onayı görünür. İptal önceki kaydı korur. |
| Kayıt başarısız olur | Prova ekranda kalır, erişilebilir durum mesajı ve yeniden deneme sunulur. |
| Profiline döner | Portre aynı yüz, saç, başörtüsü ve gözlük seçimini kullanır. |
 
## Çizim ve animasyon

Ortak koordinat alanı 240 × 360 birimdir. Tam boy ve yakın plan iki ayrı kamera kadrajıdır. Her parçanın konumu kahraman.js içindedir. Örnek göz merkezleri (105, 100) ve (135, 100), ayakkabı tabanı y=338. Katman sırası beden → ayakkabı → alt → üst veya tek parça → çanta → yüz → saç → başlık → gözlük şeklindedir. Başörtüsü saç katmanını kapatır. El ve kol konumu modele özeldir. Yeni türlerde aynı piksel noktalarını körlemesine kullanma.

Kıyafetler, saçlar ve şapkalar için saydam guaj çizimler üretildi. Gözler, kaşlar, ten ve diğer kişisel detaylar bağımsız değişir. Bu sürümde prova hareketi bütün kahramana uygulanır. El sallamak veya kumaşı hareketlendirmek için kollar, eller ve giysi kolları ayrıca çizilerek aynı eklem düzenine bağlanmalıdır. Saç ve başlık kayıttan bağımsız tek bir resme dönüştürülmemelidir.

## Uygulama kalitesi

- Markanın mevcut başlık ve gövde fontlarını, eylem moru #6A47B8, alt kenar #3A2458, metin #2E1E3E ve lavanta #EFE6F7 renklerini kullan.
- Native görünümde güvenli alanları koru. En küçük desteklenen telefonda kaydet düğmesi son ürünü kapatmasın. Büyük metinde iki veya tek sütuna geç. Renk kartlarının adını, seçili durumunu ve erişilebilirlik etiketini oku.
- Kaydı profil kimliği ve şema sürümüyle sakla. Bilinmeyen seçimlerde yalnız ilgili yuvayı varsayılana döndür. Eski kahramanı tam boy karşılığı olmadan otomatik dönüştürme. İnsan ve hayvan kayıtlarını ayrı tut.
- Küçük resimleri ürüne veya etkilenen görünüm alanlarına göre önbelleğe al. Native katmanda boyalı PNG’leri alfa kanalıyla paketle. SVG bileşenlerini kullanılan görsel motorunda karşılaştır. Renk filtresi desteklenmezse aynı saç görselinden önceden renklendirilmiş varyant üret.
- Özellikle başörtüsü + gözlük, koyu ten + koyu iris, kıvırcık saç + şapka ve tek parça + çizme eşleşmelerini gerçek cihazda kontrol et. Kayıt sonrası ikinci çocuk profiline geçip geri dön.
- Çocukla kısa bir denemede “Kahramanının gözünü yeşil yap”, “Ayakkabısını değiştir”, “Bir önceki saça dön” görevlerini ver. İlk dokunduğu yeri izle. Menü başlıklarını bu gözleme göre düzelt.
