# MagicPaper · Kahraman ve dolap stüdyosu

ZIP’i bir klasöre çıkar. **Dolap.html** dosyasını masaüstü tarayıcısında aç. VS Code kullanıyorsan aynı dosyayı yerel önizlemeyle açabilirsin. Dosyaların yan yana bulunması yeterli. Kataloğu veya resimleri uzaktan indirme adımı yoktur.

## Bir dakikalık prova

1. **Kahramanım → Başlangıçlar** içinde bir yüz seç. Başlangıçlar yalnız kimlik alanlarını değiştirir. Üzerindeki kıyafetler sende kalır.
2. **Ten**, **Göz rengi** ve **Saç** ile kahramanını oluştur. Yüz seçimlerinde yakın plan açılır. “Tam boy gör” ile geri dönebilirsin.
3. **Giysiler → Takımlar** içinden “Uzay gezisi”ni giy. **Ayakkabı** sekmesinde kiraz tokalı ayakkabıyı dene. Ayakkabı seçimi tulumu korur.
4. **Aksesuarlar** içinde bir gözlük ve çanta ekle. “Kahramanımı kaydet” ile profil portresini gör. Kaydedilen görünüm aynı tarayıcıda tekrar açılır.

## Pakette çalışan seçimler

| Alan | Seçenekler |
|---|---|
| Yüz | 10 ten tonu, 4 yüz biçimi, 3 göz biçimi, 8 göz rengi, 4 kaş, 3 burun, 3 ifade, sade yüz ve 4 yüz detayı |
| Saç | Saçsız görünüm dahil 8 model ve 8 saç rengi |
| Giysi | 12 üst, 10 alt, 6 tek parça, 6 çift ayakkabı |
| Aksesuar | 6 şapka, 4 başörtüsü, 6 gözlük, 4 çanta. Her yuvada çıkarma seçeneği var. |
| Hızlı seçim | 8 başlangıç yüzü ve 16 kombin. Kombinler mevcut giysileri kullanır. |

Bütün yüzler ve kıyafetler herkese açıktır. Cinsiyet seçimi ve cinsiyete göre filtre yoktur. Bu sürüm insan kahraman editörüdür. Önceki uygulamadaki hayvanlar için mevcut akış sürdürülür.

## Dosyalar

- **referans/Kahramanlar.png** sekiz örnek görünümü, **referans/Dolap-ve-yuz.png** tam boy ve yakın plan ekran tasarımını, **referans/Takimlar.png** 16 giyim kombinini gösterir.
- **assets/** 36 saydam PNG içerir. Diğer giysiler, aksesuarlar, yüz ve beden çözünürlükten bağımsız katmanlar halinde **kahraman.js** içinde çizilir.
- **katalog.json** seçenekleri, kimliklerini, sekmelerini, örnek görünümleri ve kombinleri verir. **katalog.js** tarayıcıdaki eşdeğer kaynaktır.
- **secim.js** görünüm kuralları, **studio.js** etkileşim ve yerel kayıt, **studio.css** yerleşim içindir.
- **01-iOS-Handoff.md** davranışlar, katmanlar ve üretime geçiş kararlarını içerir. **Claude-Code.md** uygulama reposunda kullanılabilir.
- **kontrol.cjs** Node ile bağımsız seçim kurallarını ve dosya bütünlüğünü kontrol eder. Klasörde `node kontrol.cjs` çalıştır.

Web prototipi tek bir yerel görünüm saklar. iOS proje kaydı, hayvan karakterlerine tam boy çizim, eklemli animasyon ve cihaz üstü doğrulama ayrı entegrasyon işleridir. Fontlar uygulamadaki Baloo 2 ve Nunito ailesine bağlanır. Prototip cihazda bu fontlar bulunmadığında yerel yedek font kullanır.
