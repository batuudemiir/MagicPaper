# Metni koruyan karma görsel havuzu — kaynak ve ilk anchor denetimi

20 Kasım 2026 · `a7685ca` kaynak yenilemesi · **İlk faz: kaynak çıkarımı tamamlandı; editoryal anlam denetimi kısmi. NOT_CERTIFIED.**

Kullanıcının metin ve seçim çeşitliliğini koruma kararı geçerlidir. Bu çalışma uygulama içeriğini değiştirmez ve her masala resim garantisi vermez. Tam kanıt için bütün kitap birleşimleri, sayfa ekleri ve gerçek çizimlerin uygunluğu ayrıca değerlendirilmelidir.

## Kaynak yenilemesi

`a7685ca` sonrasında eski 2.043 kayda göre 973 kayıt eklendi; kayıt silinmedi. Önceden mevcut 60 kaynak dosyası değişti, 65 yeni kaynak dosyası eklendi: toplam 125 kaynak hash farkı. Değişen eski dosyalarda 830 önceki kayıt bulunuyordu. Aynı pointer’daki önceki metinlerden **hiçbiri değişmedi**; kaynak bağlamı/metadata değişmesi yine de eski incelemeyi geçersiz kıldı. Önceki 51 anchor incelemesinin 49’u unresolved yapıldı, yalnız 2’si korundu.

Koruma koşulu bütün kaynak dosyasının SHA-256 değeri, kayıt pointer’ı, variant ID ve metnin değişmemesidir. Yeni satırlara yeni editoryal anlam hükmü verilmedi. Engine visualKeys şeması yorumlanmadı ve engine dosyaları düzenlenmedi.

## Kesin kapsam

[JSON denetimi](2026-11-20-art-anchor-audit.json) 238 kaynak dosyasından **3.016 authored metin kaydı** çıkarır: dört kanonik katalog belgesinde 295, 234 `beat_*.json` dosyasında 2.721. Bunlar normal, uyku, seri, özel gün ve recall satırlarını içerir. Özel gün katmanında 32 varyant; recall belgesinde 38 satır vardır. Dört katalogda mevcut `refrain` anahtarı bulunmadı; çalışan motorun refrain desteği var diye yazılmamış satır icat edilmedi.

**Güncel kaynak SHA sözleşmesiyle 2 anchor incelemesi korundu; 3.014 kayıt unresolved. Onaylı art binding: 0.** Tamamının çıkarılması, tamamının anlam incelemesinin tamamlandığı anlamına gelmez. JSON içindeki aday varlıklar ve sözcük ipuçları otomatik, tutucu indekslerdir; kesin anlam veya eşleme değildir.

Her kayıt exact `variantID`, kaynak yolu, JSON pointer, tam metin ve metin SHA-256 içerir. Dosya SHA-256 değerleri ayrıca kayıtlıdır. Aynı ID farklı yerde olabileceğinden anahtar kaynak yolu + pointer'dır. `templateID`, beat dosyalarında kaynak dosya adıdır; engine'in türettiği runtime template ID olduğu iddia edilmez. Yaş bandı belirtilmemiş 247 eski/recall kaydı varsayımla bir yaşa atanmadı.

**Kaynak toplamı runtime havuzu değildir.** `ContentCatalogLoader.assemble` corpus'un kapsadığı `realizesBeat` kayıtlarında eski library template'lerini kaldırır. Ham scaffolding satırları korunarak envantere alındı; runtime uygunluğu tüm satırlarda `not_evaluated`. Dosyada bulunmak, seçilebilir olmak demek değildir.

## Yaş, ark ve seri ayrımı

| Yaş | Standart tek | Standart seri | Uyku tek | Uyku seri |
|---|---:|---:|---:|---:|
| 3–4 | 259 | 116 | 116 | 86 |
| 5–6 | 613 | 90 | 112 | 109 |
| 7–8 | 401 | 70 | 105 | 53 |
| 9–10 | 365 | 73 | 148 | 53 |
| Belirtilmemiş | 247 | 0 | 0 | 0 |

Tablo authored metin kayıtlarını sayar; özel gün satırları ilgili uyku hücrelerinde yer alır. Seri satırının yokluğu olası fallback davranışını kanıtlamaz. JSON her kaydı template/beat/yaş/ark/seri/occasion bazında filtrelemeye uygundur.

## Önceki okumadan bulgular — güncel onay değildir

Aşağıdaki bulgular tarihsel inceleme notlarıdır. Yenilemede kaynak dosyası SHA’sı değişen kayıtların eski anlam incelemesi korunmadı; güncel durum yalnız JSON `editorialStatus` alanından okunmalıdır. Bunlar Claude’un engine visualKeys/provenance işinin yerine geçmez.

- `na_neutral_01/02`: seçilmiş mekâna varış/mevcudiyet ve keşfin yakınında durması açık. Yine de her keşif görünür nesne değildir; kaynak kayıt ve çizim durumu ayrıca kontrol edilir.
- `na_any_01–03`: keşif mevcut, mekân metinde açık değil. Bunlar mekân bulunmadığını değil, bu cümleden mekân mevcudiyeti çıkarılamayacağını gösterir.
- `na_fam_fr_02`, `na_fam_im_01`: seçilmiş yere gitme yolu. Varış çizimi otomatik uygun değildir.
- `na3_05`, `na3_fam_sib_02`: ev penceresi. Seçilen orman/uzay ortamı çocuğun o an bulunduğu yer değildir.
- Standart 7–8 ve 9–10 notice-anomaly açılışları tek tek okundu; seçilen mekân mevcut. Bunların family/companion/nesne durumları henüz onaylanmadı.
- `sr_03`, `sr3_03`: keepsake hatırlanır; elde duran fiziksel nesne gibi çizilemez. Hatırlanan nesneyi açıkça hatıra olarak çizmek ayrı editoryal karardır.
- `mc3_01` + `ra3_02`: arkadaş fiziksel olarak mevcut ve yardım ister. `rs3_03` aynı arkadaşın gözlerini açıp iyi olduğunu söyler; yorgun ve iyileşmiş çizimler aynı durum değildir.
- `na3_02`: yalnız ses; kaynağı görünür kılacak hayvan/çan icat edilemez.

Bu ilk inceleme, yalnız ilk sayfa/mekân yaklaşımını sınırlar. Bütün kitapta anchor yokluğunu kanıtlamaz. Arkadaş/durum çizimleri başka sayfaları kapsayabilir.

## Öncelikli çizim konuları — üretim emri veya kesin asgari sayı değildir

| Öncelik | Konu ve gerekli durum | Sınır / sonraki inceleme |
|---|---|---|
| P0 | 2 yatak odasının pencere/perde detayı | Çocuk görünüşü ve yatak sayısı sabitlenmeden mekân ayrıntısı. Ay penceresi / mavi perde kimliği korunur; bütün açılışların tek tek onayı gerekli. |
| P0 | Kanonik arkadaş kimlikleri: mevcut, dinlenen/yorgun, gözleri açılmış/rahatlamış | 26 kimliği tek genel hayvana indirgemeyin; her türde aynı yüz/duruş uygun değildir. Masal ailem kimliği yerine katalog hayvanı geçmez. |
| P1 | Görünür keşiflerin nötr başlangıç durumları | Mevcut 10 aktif konu korunur; 33 discovery kaydını otomatik 33 görünür nesne saymayın. |
| P1 | Ev penceresi ve adı konmamış yol detayı | Yalnız gerçek bağlamı açıkça anlatan satırlarda; seçilen destinasyonun yerine geçmez. |
| P2 | 28 seçilmiş mekân için kimlik eşlemeleri | Reachability ve sayfa mevcudiyeti henüz kanıtlanmadı; 28 yeni çizim zorunluluğu değildir. |
| Review | Kaynağı bilinmeyen ses / titrek ışık | Soyut çizimin anlatıyı anlamlı desteklemesi editörce onaylanmalı; dekoratif işaret kota doldurmaz. |

Bilinen nesne durum açıkları: açık müzik kutusunun kapağı, boş yuvanın boşluğu, haritanın eksik yarısı ve orman çevresi, solmuş/iyileşmiş fide, ayak izinin türü, eski/yırtık/yıldız haritası ayrımı. Bunlar birbirinin yerine kullanılmaz. Shared ve pilot deniz kabukları kimlik olarak ayrıdır; görsel paylaşımı ayrıca onay ister.

## Kalan iş

1. Önce production loader'ın gerçekten tuttuğu template'leri çıkar; eski scaffold ile runtime corpus'u ayır.
2. Kalan 3.014 kaydı tek tek değerlendir: mevcut/hatırlanan/hedef/eksik/hayal edilen varlık, bağlam, görünürlük ve durum. Aday sözcük bayrakları yeterli değildir.
3. Referansları önceki sayfa ile çöz; supporting beat, recall, family, occasion ve refrain eklerini son sayfa düzeyinde denetle.
4. Çizim subject/revision/state uygunluğunu bağla; mevcut 12 asset'in paketli olması onay değildir.
5. Tüm erişilebilir kitap birleşimlerinde en düşük ayrı resimli anlatı sayfasını hesapla; yalnız seed örnekleriyle evrensel garanti çıkarma.
6. Küçük yaş üç / büyük yaş iki hedefinde açıkları somut örneklerle raporla. Aynı dosyanın tekrarını farklı anlamlı sahne gibi sayma.

## Doğrulama ve değişiklik kapsamı

Yalnız bu Markdown ve eşlik eden JSON oluşturuldu. Kaynak çıkarımı Python ile yapıldı; uygulama testleri/build/simülatör çalıştırılmadı. Uygulama kodu, katalog metinleri, seçimler ve görsel dosyalar değişmedi. SHA/pointer kaydı sonradan bağımsız kaynak doğrulamasına olanak verir; çalışan kapsam sertifikası değildir.
