# Metinleri değiştirmeden görsel kapsamı

20 Kasım2026 · Karar önerisi ve kaynak denetimi. Uygulanmış özellik, onaylı üretim spec’i veya kanıtlanmış kapsama garantisi değildir.

## Kullanıcının kararları

- Her yeni masalda görselli anlatı sayfaları bulunmalı; kapak sayılmaz.
- Yaşa göre yoğunluk değişsin, küçüklerde daha fazla olsun.
- **Metinler aynı kalacak.** Görsel için cümle ekleme, mevcut cümleyi düzeltme veya olay örgüsünü değiştirme onaylanmadı.
- Görseller önceden hazırlanacak; cihazda masal üretimi sırasında görsel API’si kullanılmayacak.
- Mevcut çocuk/Ragi/arkadaş kimlikleri korunacak. Beyaz/açık lila okuyucu, onaylı mat guaj dili ve son dikey ortalama kararı devam edecek.

Önerilen yoğunluk hedefi3–6 için3,7–10 için2 ayrı resimli anlatı sayfasıdır. Kullanıcı yaşa göre farkı seçti; bu kesin adetler henüz onaylı veya bütün katalogda kanıtlanmış değildir. Aynı dosyayı sayıyı doldurmak için tekrar etmek bu hedefin anlamlı karşılığı sayılmaz.

## Yapılan iş ve çalışma listesi

- [x] Güncel repo, önceki semantik havuz tasarımı ve telefon geri bildirimi incelendi.
- [x] Mimari ve içerik envanteri ayrı uzmanlarla salt okunur değerlendirildi.
- [x] Sayfa sayısı/yaş ve metin değişikliği tercihleri soruldu; yukarıdaki kararlar alındı.
- [x] Üç yaklaşım ve somut öneri hazırlandı; ham aday listesi CSV’ye çıkarıldı.
- [ ] Karma havuz tasarımının ve garanti tanımının kullanıcı tarafından değerlendirilmesi.
- [ ] Onaylanan tasarımın spec olarak yazılması, gözden geçirilmesi ve uygulama planı.
- [ ] Mevcut kaynaklara görsel anlam açıklamaları, kapsama doğrulayıcısı ve kesin asset listesi.
- [ ] Çizim üretimi, bağlayıcı/okuyucu entegrasyonu ve nihai test/cihaz kabulü.

Bu tur metinsel tasarım/audit turudur; uygulama kodu, katalog metni, görsel ve telefon build’i değişmedi. Görsel kompozisyon kararlarına geçildiğinde brainstorming görsel eşlikçisi ayrıca teklif edilebilir. Test/build/simülatör çalıştırılmadı; aşağıdaki statik kaynak sayımları test başarısı veya tam ulaşılabilirlik kanıtı değildir.

## 1. Mevcut kapsamın somut fotoğrafı

Birleşen dört kanonik içerik belgesinde28 mekân,33 keşif konusu,26 arkadaş ve52 blueprint kaydı var. Blueprint sayısı36 normal +8 seri devamı +8 özel gündür; önceki36 sayımı yalnız üst düzey normal kayıtları kapsıyordu. Bunların her birinin her mod/yaşta seçilebilir olduğu iddia edilmiyor.

Kaynaklar: `StoryEngine/Sources/StoryEngine/Resources/templates/offline/v2/shared_content_library_v2.json`, `Resources/blueprints/{pilot_library_v1,recall_lines_v1,occasion_library_v1}.json`. Üretim loader bu sırayla içerikleri birleştirir. Statik aday envanteri: [87 satırlı CSV](2026-11-20-art-coverage-candidates.csv). Kaynak SHA/commit kaydı: [snapshot](2026-11-20-art-coverage-source-snapshot.json); proofStatus=NOT_CERTIFIED, tam kapsama sertifikası değildir.

CSV yalnız mevcut `story-art-v1` spot manifest’ine göre durum gösterir; uygulamanın diğer B2/kapak/avatar çizimlerinin yokluğunu iddia etmez. Mevcut12 spot çizimin10 konusu aktif;340 kural yalnız incelenmiş `na_neutral_01/02` açılışlarına aittir. Bir dosyanın paketli olması tüm hikâyelerde kullanılabildiği anlamına gelmez.

Telefonda bildirilen çan örneği bunu gösterdi: `object_bell_001` için manifestte çizim yok; hatırlamalı `na_any_01` yolu mevcut kurala uymuyor. Bu, yeni metin ritmi veya resim yükleyici arızası değildir.

## 2. Önceki mekân önerisinin düzeltilmesi

Her ilk sayfaya seçilen mekânın resmini koymak yeterli veya doğru değildir:

- `na_any_01` keşif nesnesini anabilir, mekânı söylemez.
- Küçük yaşta `na3_05` ve `na3_fam_sib_02` evin penceresindedir; seçilen orman/uzay ortamını o an varmış gibi çizmek desteklenmez.
- `na_fam_fr_02` ve `na_fam_im_01` seçilen yere **gitme** durumundadır; varışla aynı şey değildir.
- Bazı seri ve özel gün satırları geçmişi veya bir buluşmayı anlatır.

Bu istisnalar yalnız **ilk sayfaya otomatik mekân resmi** varsayımını çürütür. Bütün kitapta hiç çizilebilir an bulunmadığını veya metni değiştirmeden garanti vermenin imkânsız olduğunu kanıtlamaz. Daha önce düşünülen ek mekân cümlesi önerisi, kullanıcının metni koruma kararıyla geri çekildi.

Arkadaşlar önemli bir ek imkândır: standart3–4 kurgu kaynaklarında tanışma/yardım ve iyileşme sayfalarında arkadaş açıkça yer alabilir. Fakat yorgun/uyuyan arkadaş ile iyileşmiş arkadaş için aynı gülümseyen portre uygun olmayabilir. Kullanıcının Masal ailem karakterinin yerine rastgele katalog hayvanı konamaz. Arkadaş havuzu kimlik ve durum sözleşmesine uymalıdır.

Ses gibi soyut konularda görünmeyen bir çan, kuş veya lamba icat edilmeyecek. Kaynağı belirsiz ses, ancak bu pasajı anlamlı biçimde desteklediği editörce kabul edilen soyut bir çizimle temsil edilebilir; rastgele nota/ışık süsü otomatik kapsama sayılmaz.

## 3. Üç yaklaşım

| Yaklaşım | Ne korunur / kazanılır? | Sınır |
|---|---|---|
| **A · Karma görsel havuzu + bütün-kitap anlam eşlemesi — önerilen** | Metinler, seçim çeşitliliği, seed davranışı ve kişiselleştirme korunur. Nesne, mekân, arkadaş/durum ve açık bağlam çizimleri birlikte kullanılır. | Kapsama haritası tamamlanmadan evrensel asgari sayı ilan edilemez. |
| B · Yalnız sanatın desteklediği mevcut birleşimleri seçmek | Cümleler değişmeden sert kota kurmak kolaylaşabilir. | Hikâye/varyant seçimini daraltır. Bu, metni korumakla aynı ürün kararı değildir; kullanıcıdan ayrıca onay gelmeden uygulanmaz. |
| C · Her sayfaya tematik/dekoratif resim eklemek | Grafik görünmesi kolay sağlanır. | Olayla ilgili illüstrasyon garantisi değildir. Aynı genel kitap/yıldız deseniyle sayıyı doldurmak önerilmiyor. |

A yaklaşımında ilk amaç, her üretilebilir kitabın en az bir anlamlı sayfasının kapsandığını **kanıtlamak**; aynı tabloda küçük yaş3/büyük yaş2 hedefindeki açıkları da çıkarmaktır. Daha yüksek sayı için doğrulama tamamlanınca o sayı garantiye dönüşür. Bu, mevcut uygulamada bir sayfalık garantinin bile hazır olduğu iddiası değildir.

## 4. Önerilen tasarım: metne dokunmayan görsel açıklamalar

### İçerik/engine

Mevcut authored varyantlara metni değiştirmeyen açıklamalar eklenir: hangi varlık, hangi zaman/presence ve hangi durumda anlatılıyor? Görülen nesne, hatırlanan yer, gidilecek mekân, kayıp nesne ve hayal edilen durum ayrılır. Açıklama gerçekten seçilen kaynak varyantına bağlıdır; kelime araması veya yalnız sayfa numarası kanıt sayılmaz.

Mevcut `ComposedPage` kaynak zinciri bu anlam verisini taşıyabilir. Recall/family/occasion ekleri birleşince aynı kanıt korunmalı ve **son sayfanın tamamı** çizimle çelişki bakımından değerlendirilmelidir. `RecallLines.appendingRecall` bugün sayfayı yeniden kurarken authored fingerprint’i aktarmıyor; bunu yalnız eski hash’i kopyalayarak çözmek yeni ek cümleleri görmezden gelir. Kanıt, eklenen ve korunan kaynakları açıkça kapsamalı.

Metinlerin byte düzeyinde ve aynı girdilerde seçilen varyantların değişmediği ayrı regresyon şartıdır. Görsel bulmak için yeniden seed denemek, varyant değiştirmek, konuyu başka nesneye çevirmek veya görünmez biçimde mevcut seçenekleri filtrelemek yok.

### Çizim havuzu

- **Mekân:**28 kanonik kimlik için uyumluluk haritası adayı. Bir çizimin birden fazla kimliğe uygunluğu ayrıca onaylanır; habitat benzerliği tek başına yeterli değildir.
- **Keşif/nesne:**33 konu;32’si görülebilir bir özne, biri yalnız duyulan sestir. Mevcut10 aktif çizim yalnız ilk dar kapsamı sağlar. Yeni nesnelerde şekil/malzeme/durum metne uyar; çan burada gümüş ve küçüktür.
- **Arkadaş/durum:**26 katalog arkadaşı için mevcut kanonik referanslar denetlenir. Referansı olmayan arkadaşlarda önce merkezi Character Bible kimlik kartı hazırlanıp onaylanır. Yeni portre/poz üretimi ancak kimlik ve duygusal durum uyumuyla yapılır; Masal ailem ve çocuk görünüşü bağımsız uydurulmaz.
- **Açık bağlam:**Pencere/yol gibi ek detaylar yalnız mevcut metnin gerçekten kurduğu bağlama göre; genel bir “yol” her yolculuğun kanıtı değildir.

Bu sayılar toplanıp “87 yeni çizim gerekir” denemez. CSV87 içerik kaydıdır; onaylı tekrar kullanım, birden çok durum/poz, mevcut diğer kaynaklar ve ulaşılabilirlik sonucu nihai üretim adedini belirler. Önce eşleme gereksinimi, sonra kesin üretim listesi çıkarılmalı.

### Bağlama/kayıt

`OfflineStoryMapper`/`StorySpotBinder` bağlantı noktası korunur; bağlayıcı yalnız ilk sayfayı değil bütün anlatı sayfalarını değerlendirir. Önce uygunluk, sonra farklı anlatı anları ve kompozisyon seçilir. Seçilen assetID/revision/digest/altText/semantik kanıt kitapla saklanır; okuyucu açılışta yeniden seçim yapmaz. Eski pin dosyaları korunur.

Seri hazırlanırken tüm yeni bölümler aynı sözleşmeden geçer; kilit açarken yeniden eşleme yapılmaz. Eski kitap/önceden hazırlanmış seri bölümlerini değiştirmek bu öneriye dahil değildir; gerekirse ayrı, açık migration kararı gerekir.

### Okuyucu

Mevcut spot düzeni AX ve dar yükseklikte çizimi sıfırlıyor. “Görselli sayfa var” demek için veride pin bulunması yetmez: garantiye dahil çizim erişilebilir/dar düzende metinle birlikte kaydırılabilir alanda görünmelidir. Okunabilirlik/font tercihi korunur, metin küçültülmez. Normal düzende üst çizim ve kullanılabilir alanda dikey ortalı metin kararı devam eder.

## 5. Kapsama nasıl kanıtlanacak?

1. Normal/seri/özel gün blueprint’leri, yaş/mod/safety/trait/habitat kuralları ve selector fallback’leriyle tüm geçerli anlam birleşimleri çıkarılır.
2. Her authored satırın desteklediği görsel gerçekler/durumlar ve uyumlu onaylı asset’ler işaretlenir; bütün son sayfa çelişkileri hesaba katılır.
3. Her üretilebilir kitabın kaç **ayrı anlatı sayfasının** anlamlı çizim taşıdığı bulunur. Sadece yüzlerce seed örneğinin başarı oranı evrensel kanıt sayılmaz.
4. Açık birleşimler somut karşıörnek olarak gösterilir. Soyut analiz fazla tutucuysa gerçek composer ile ulaşılabilirliği sınanır; tek sayfa istisnası bütün kitap karşıörneği sayılmaz.
5. Açıklar metinleri/dağılımı değiştirmeden, uygun yeni çizim/durum/referans ve açıklamalarla kapatılır. Kapatılamayan örnek gizlenmez; garanti o sonuca göre kullanıcıyla yeniden değerlendirilir.
6. Kaynak PNG’nin hash’i ve gerçek image decode, mapping/JSON/series pin roundtrip ve normal/AX/dar reader gösterimi doğrulanır.

Kapsama sertifikası en az şunları taşımalı: katalog+sanat sürümü, yaş/mod hücresi, kapsanan kaynak sınıfları, en kötü resimli anlatı sayfası, farklı art/anlatı anı sayısı, açık karşıörnekler ve kaynak digest’leri. Erişilemeyen bir mod/yaş hücresi “başarılı” diye sayılmaz. Örneğin mevcut normal3–4 blueprint envanterinde adventure kaydı yok; gerçek selector davranışı ayrıca ele alınmalı.

## 6. Havuz büyüdüğünde

Yeni içerik paketi, uygulamanın yerel sanat sözleşmesiyle birlikte doğrulanmalı. Bilinmeyen yeni kimliğe genel orman/yıldız resmi atanmaz. Mevcut `CatalogSourceResolver` staged paketi değerlendirmeden promote ediyor; kabul sırası, uyumsuz paket etkinleştirilmeden önce görsel kapsamı denetleyecek şekilde tasarlanmalı. Yeni uzaktan içerik sistemi kurulmaz; mevcut imza/digest/integrity/policy hattına bu kontrol eklenir.

Geçerli kaynakları olan kurulumdaki yazarlık garantisi ile tüm resim baytlarının fiziksel olarak bozulduğu kurulum farklıdır. Kaydedilmiş kitabın metin olarak okunabilir kalması korunur; eksik/bozuk resim durumunda yanlış bir çizim uydurularak başarı sayılmaz.

## Sonraki somut iş paketi

Bu karma havuz yaklaşımı kabul edilirse uygulama sırası: **(1)** salt okunur semantik kapsama matrisi ve açıkların listesi, **(2)** kesin çizim/durum/referans üretim listesi, **(3)** görsel açıklama/provenance ve binder entegrasyonu, **(4)** reader erişilebilir gösterimi ve katalog kabul kontrolü, **(5)** bütünleşik test ve iPhone kabulü. Çizimler onaylı guaj referanslarıyla önceden hazırlanır; runtime API kullanılmaz.

Henüz kod ve çizim üretimine geçilmedi. Metin koruma kararı nedeniyle önce bu revize tasarımın ve garanti tanımının değerlendirilmesi gerekiyor; onaylanan tasarım daha sonra spec ve uygulama planına dönüştürülecek.
