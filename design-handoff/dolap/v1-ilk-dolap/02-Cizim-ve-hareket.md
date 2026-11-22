# Çizim ve hareket üretimi

## Görsel karar

Bu görünümün çekiciliği için asıl yatırım çocuğun yüzü, saç tutamları, kumaş ve silüet. Örnek çizimlerde dengeli büyük baş, sakin gülümseme, guaj dokusu ve renkli yumuşak kenar kullanıldı. Referans artındaki üçüncü düğme ya da arka plan süsü yerine çocuğun kendi seçimini okuyabileceği temiz bir sahne ayır. Her giysiye bir tanınır detay ver: orman pelerininin yaprak kopçası, pijamanın hilalleri, ressamın cebindeki iki fırça.

## Uygulama için ilk yol

PNG parçaları aynı koordinat uzayında üst üste göster. Görünümdeki çizgi ve dokuyu sanat dosyaları sağlar. Kod seçim, yerleşim ve hareketi yönetir. Çalışan örnekte her tam boy görsel 512 × 1024 px. Şapka ve gözlük ayrı alfa kanallı resimlerdir. Aynı figürü birçok kez yeniden üretip kıyafet değiştikçe yüzü rastgele değiştirmek, kişisel kahraman hissini zayıflatır. Yeni üretimlerde model sayfasını ve onaylı yüzü kilitle.

Prototipin önizleme koordinatları: orijin resmin sol üstü, taban yaklaşık y=1000. Şapkayı alt orta noktasından yaklaşık (251,118) noktasına bağla. Gözlük merkezini yaklaşık (251,166) noktasına oturt. Tek bir ölçek katsayısını hem karaktere hem aksesuarlara uygula. Oturumu başka bir çocuğun yüzüne veya hayvan türüne genişletirken her yüz için yeni bağlantı noktası tanımla.

## Ayrı üst, alt ve kol hareketi için çizim siparişi

| Teslim | Üretim talimatı |
|---|---|
| Ana kaynak | Katmanlı çizim dosyası, önden nötr poz, açık kollar, sabit taban çizgisi ve göz hattı. Çocuk için yaşa uygun düz iç takım. Örneklerin merkezleri ve ölçeği eşleşmeli. |
| Arka–ön sırası | Arka saç / arka pelerin ve çanta / arka kol / kapalı temel beden / alt / ayakkabı / üst / ön kol ve el / baş ve yüz / ön saç veya örtü / şapka / gözlük. Elde taşınan nesnede sap parmakların arkasından geçer. |
| Hareketli parçalar | Baş, gövde, sağ-sol üst kol, ön kol, el, ön saç, göz açık-kapalı, ağız ve hareket edecek kumaş ayrı katmanda. Eklemlerin arkasındaki kumaşı da boya. |
| Her giysi | Aynı bazın üstüne çiz. Hareket eden kollar için gövde ve kolları ayrı dışa aktar. Saç–bere, gözlük–burun, örtü–yaka kesişimleri için maske üret. |
| Profil portresi | Son görünümden baş ve omzu kırp. Gözlük ve şapka bu türetilmiş portreye dahil olur. |
| Teslim kontrolü | Saydam PNG, sRGB, temiz alfa, koyu ve açık zeminde kenar testi. Aynı kaynak koordinatında boşluklu dışa aktar veya kırpılmış her resmin ofsetini kaydet. |

## Hareket reçetesi

İlk sürüm için ekstra animasyon servisi gerekmiyor. Prototip seçim anında bütün kahramana 320 ms süren küçük bir yana eğilme uygular. Ayağı yere bağlı gösteren dönüş merkezi kullanılır. Tek hareket çalışır, peş peşe dokunuşlar birikmez. Hareketi Azalt tercihinde anında son pozu göster.

İkinci aşamada göz kırpma için gözün iki çizimini yaklaşık 100–140 ms boyunca değiştir. Selamlama istenirse elin ve kıyafet kolunun aynı omuz–dirsek–bilek bağlantılarını izlediği bir 2B iskelet kur. Bir animatöre verilecek deneme: tek çocuk, tek uzun kollu giysi, tek selam döngüsü. Pelerin ve gözlük birlikte doğru kalıyorsa kataloğa genişlet. Rive veya Spine gibi bir araç bu aşamada değerlendirilebilir. İskelet, ağırlıklar, deformasyon ve dışa aktarılmış animasyon dosyası ayrı üretim işidir. Bu pakette etkileşim hareketi ve çizimler bulunur, düzenlenebilir rig teslimi ayrı aşamadır.
