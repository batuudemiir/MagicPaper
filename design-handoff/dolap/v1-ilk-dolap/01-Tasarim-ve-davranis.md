# Dolap · iOS tasarım ve davranış teslimi

## Ekranın işi

Paylaşılan mevcut ekranda çocuk yüzünü görüyor, “Kıyafet” sekmesine dokunduğunda ise pantolon veya ayakkabının nasıl duracağını görebileceği alan yok. “Kaydet” ilk seçenek sırasını kesiyor ve altta geniş bir boşluk kalıyor. Yeni akışta çocuk üstte kendini, altta seçebileceği nesneleri görür. Ürüne ilk girişte daha önce kaydedilen görünüm açılır. Yeni profilde tarafsız bir başlangıç takımı gösterilir.

## Yerleşim

| Bileşen | Önerilen ölçü ve davranış |
|---|---|
| Sunum | Profil içinden tam ekran düzenleyici. Alt gezinme ve masal yazma kısayolu profil ekranına dönünce geri gelir. Sistem geri hareketi ile geri düğmesi aynı çıkış akışını izler. |
| Üst çubuk | Güvenli alanın altında 56 pt civarı. Geri, “Masal dolabım”, var olan yıldız bakiyesi. Yıldız göstergesi salt bilgi. |
| Kahraman | Yumuşak krem bir prova nişinde tek tam boy figür. Ayaklar sabit bir zemine basar. Portrede düzenleyici yüksekliğinin yaklaşık %40–45’i. Şapkanın tepesi için boşluk bırak. |
| Seçim | Başlangıç sürümünde Takımlar / Şapkalar / Gözlükler. Tek sırada ad ve görsel. Başlık 22–24 pt Baloo 2, kart adı 14 pt civarı Nunito. |
| Kartlar | Yatay kenarlarda 20 pt, aralarda 8 pt. Seçimde 2 pt mor kontur ve tik. Doku, silüet ve kısa Türkçe ad birlikte kullanılır. |
| Eylem | Ekran altında sabit tek düğme “Kahramanımı kaydet”. En az 50 pt yükseklik ve markanın 3 pt koyu alt kenarı. Alttaki içerik kendi alanında kayar. |
| Dar ekran / büyük yazı | Önizleme kısalır, karakter tümüyle görünür. Kart adları büyüyünce iki sütuna, gerekirse tek sütuna geçilir. En büyük yazıda başlık ve seçimler birlikte kayabilir. |
| Renkler | Eylem #6A47B8, metin #2E1E3E, düğme altı #3A2458, seçili açık yüzey #EFE6F7. Çocuk ekranı beyaz, niş sıcak kâğıt tonu. |

## Katalog genişlediğinde

Üst seviyede üç aile göster: **Kahramanım / Giysiler / Aksesuarlar**. Çocuk “Giysiler”e dokununca Takım, Üst, Alt, Ayakkabı filtreleri açılır. “Aksesuarlar” içinde Şapka, Gözlük, Çanta ve Elde taşınanlar bulunur. “Kahramanım” içinde Çocuk ve Hayvan arkadaş ayrımı vardır. İnsan için ten, saç, saç rengi, yüz ve başörtüsü burada bulunur. Çocuk görünümünü isimden veya cinsiyetten tahmin etme. Ragi’nin rengi ve resmî kostümü sabittir, hayvan dolabından ayrı tutulur.

“Takım” üretimde bir önayardır. Örneğin orman takımı üstü, altı ve ayakkabıyı birlikte seçer. Çocuk sonra yalnız botu değiştirebilir. Takım seçimi gözlüğü, başörtüsünü, teni ve yüzü değiştirmez. Full-body tek resimli demoda setler tek parça olarak gösterilir.

İnsan ve hayvanların göz hizaları, kulakları ve ayakları farklıdır. Her tür için onaylı kalıplar kullan. Uyumlu parçası üretilmemiş ürün ilgili türün listesinde görünmez. Birinden diğerine geçip dönünce her kahramanın son taslağı geri gelir. Başörtüsünde saç örtme maskesi kullan. Gözlüğün konumu göz hizasından alınır; şapka ile başörtüsü çakışıyorsa başörtüsünü koru ve yalnız uyumlu şapkaları göster.

## Kullanım durumları

| Durum | Kullanıcının gördüğü ve sistemin yaptığı |
|---|---|
| İlk açılış / geri geliş | Kaydedilmiş görünüm hemen çizilir. Türü ve donanımı bulunan eski avatar kendi seçimleriyle açılır. Eksik yeni yuvalar boş başlar. |
| Dokunma | Parça o anda prova edilir. Önizleme sabit, ilgili kart tikli kalır. “Gözlüksüz” ve “Şapkasız” da normal seçeneklerdir. |
| Peş peşe dokunma | Son seçim kazanır. Geç yüklenen eski görsel yeni parçayı örtemez. Seçim başına bir kez kısa geri bildirim. |
| Geri / kapat | Değişiklik yoksa kapat. Değişiklik varsa “Denemeye devam et” ve “Kaydetmeden çık” sun. |
| Kaydet | Aktif çocuk profiline tüm görünümü tek işlemde kaydet. Profil büstünü aynı kayıttan üret. İkinci dokunma çift kayıt oluşturmaz. |
| Kayıt hatası | Dolap ve taslak açık kalır. “Kaydedemedik. Tekrar deneyelim mi?” ve yeniden deneme sunulur. |
| Görsel yüklenmedi | Son geçerli görünüm kalır. Kullanılamayan kartta “Tekrar yükle” seçeneği ver. Eksik katmanlı görünümle kayda izin verme. |
| Çevrimdışı | Cihazdaki sahip olunan parçalarla giydirme ve yerel kayıt çalışır. Eşitleme varsa bağlantı dönünce aktif profil ve kayıt sürümü kontrol edilir. |
| Yıldızla açılan parçalar eklenirse | İlk rafta sahip olunan parçalar yer alır. Kilitli parçayı denemek yıldız harcatmaz. Açma ayrı, açık fiyatlı bir eylemdir. Kimlik seçenekleri, başörtüsü ve temel gözlük daima erişilebilir. |
| Erişilebilirlik | Her kartın adı ve seçim durumu seslendirilir. Simge ve işaret renge eşlik eder. Hareketi Azalt açıkken parça doğrudan değişir. Tüm etkileşimlerin hedef alanı en az 44 × 44 pt. |

## Teslimi kabul ederken

- Küçük bir telefonda seçenek listesinin son satırına kadar kaydır. Kaydet düğmesi hiçbir karta binmemeli.
- Aynı çocukta üç takımın her birine iki şapkayı ve iki gözlüğü takıp çıkar. Gözlük iki gözün merkezinde, şapka saç çizgisinde kalmalı.
- İki çocuk profili arasında geçiş yap. Birinin gözlüğü diğerine taşınmamalı. Eski profil kaydıyla başlatmayı da dene.
- Büyük metin ve VoiceOver ile bir parçayı seç, önce vazgeç, sonra tekrar açıp kaydet. İki akışta profil sonucunu karşılaştır.
- Çocukla denemede önce hiç ipucu vermeden “Kahramanına bere takar mısın?” de. Sonra “Şimdi çıkaralım” de. Yardım istediği adımı gözle.
