# MagicPaper: Çocuğun okumak isteyeceği sayfalar

19 Kasım 2026 · Araştırma ve karar seçenekleri · Henüz onaylı tasarım veya uygulama planı değildir.

Kullanıcı hedefi: çocuk sayfaya baktığında hikâyeye girmek ve devamını okumak istesin. Kullanıcının kapsam tercihi: **3–6 yaşta birlikte okuma ile 7–10 yaşta bağımsız okumaya ayrı öneriler.** Yaş, okuma becerisinin kesin karşılığı olarak kullanılmamalı.

## Çalışma adımları ve sınır

- [x] Proje hafızası, son okuyucu commit’i f444129, gerçek renderlar ve aktif offline model incelendi.
- [x] Bu aşama metinsel araştırmadır; görsel karşılaştırma sorularına geçildiğinde brainstorming görsel eşlikçisi ayrıca teklif edilecek.
- [x] Okuma bağlamı soruldu; kullanıcı iki gruba ayrı öneriler istedi.
- [x] Bilimsel bulgular, fiziksel kitap teknikleri ve dijital örnekler karşılaştırıldı; üç yaklaşım çıkarıldı.
- [ ] Seçilen yaklaşımın görsel tasarımını bölüm bölüm sunmak ve onay almak.
- [ ] Onaylanan tasarımı ayrı spec olarak yazıp commit’lemek.
- [ ] Spec’i belirsizlik, çelişki, kapsam ve eksik kararlar açısından gözden geçirmek.
- [ ] Kullanıcının yazılı spec incelemesini almak.
- [ ] Ardından writing-plans ile uygulama planı hazırlamak.

Bu görevde kod, motor, asset veya mevcut masal değişmedi; yeni görüntü üretilmedi. Kaynaklar yayınevleri/yazarlar, ürünlerin kendi belgeleri ve özgün araştırmalardan seçildi. Kitap örneklerinde yayınevi tanıtımı ve erişilen öğretmen/yazar materyalleri kullanıldı; kitapların tamamı sayfa sayfa okunmuş gibi değerlendirilmedi. PRH Look Inside okuyucusu metin aracında açılmadı; Book Dash e-kitap indirme bağlantısı zaman aşımına uğradı. Bunlardan iç sayfa ölçüsü çıkarılmadı. Uygulama örnekleri ilgili şirketin beyan ettiği özelliklerdir; ürünlerin etkililiğine dair bağımsız deney sayılmaz.

## 1. Mevcut okuyucunun güçlü yanı ve eksik kalan şey

Mevcut sayfa okunaklı: beyaz/lila yönü, Nunito gövde, mor ad vurgusu, büyük dokunma alanları, isteğe bağlı kâğıtlar ve görselsiz fallback var. Son değişiklik nesneyi üstte büyüttü. Fakat bu, hikâyenin görsel olarak anlatılmasıyla aynı şey değil.

Tasarım değerlendirmem: yırtık haritanın tek başına üstte durması bir nesneyi tanıtıyor; **o anın merakını, karakterin ne hissettiğini ve sonraki sayfanın vaadini henüz taşımıyor.** Aynı üst-görsel/alt-metin örgüsünün tekrar etmesi kitabı bir dizi benzer uygulama ekranına dönüştürebilir. Bunun çocukları sıktığı ölçülmedi; kullanıcı geri bildirimiyle uyumlu bir tasarım hipotezidir.

Sabit viewport renderlarında SE’de 26 punto/nefes düzeninde metnin devamı kaydırma gerektiriyor. Bu erişilebilirlik için gerekli olabilir; ancak her sıradan sayfada kaydırma ile sayfa çevirmenin birlikte gerekmesi anlatının temposunu zayıflatabilir. Çözüm fontu küçültmek değil; normal okuma koşulunda sayfa başına anlatı yükünü ve görsel payını birlikte denemek. Büyük yazıda kaydırma korunmalı.

## 2. Araştırmalar ne söylüyor?

### Hikâyeye hizmet eden görsel, ilgisiz süsten ayrılmalı

Eng ve arkadaşlarının 2020 çalışmasında 1–2. sınıftan60 çocuk, ilgisiz ayrıntıları çıkarılmış resimlerle daha iyi anladı; ikinci60 çocukluk deney de ana bulguyu destekledi. Bu, bütün illüstrasyonları kaldırma gerekçesi değil. MagicPaper için çıkarımım: haritayı, duyguyu ve olayın önemli ayrıntısını göster; aynı sayfaya olaydan bağımsız yıldızlar, maskotlar ve dekoratif nesneler yığma. Çalışma Türkiye’de veya MagicPaper üzerinde yapılmadı; bütün3–10 yaşlara doğrudan genellenmez. [Özgün çalışma](https://www.nature.com/articles/s41539-020-00073-5)

### Animasyonun ve etkileşimin faydası koşullu

Takacs, Swart ve Bus’un43 çalışma/2.147 çocuk meta-analizinde teknoloji destekli anlatıların anlama ve ifade edici kelime bilgisine küçük ortalama katkıları vardı. Bazı multimedya özellikleri yararlı, hotspot/oyun gibi etkileşimler ise dikkat dağıtıcıydı. “Animasyon iyidir” veya “dokunma kötüdür” şeklinde mutlak kural çıkarılamaz. Önerim: ilk pilotta statik kompozisyonun değerini ölç; hareketi ayrı bir değişken olarak sonra dene. [Meta-analiz](https://pubmed.ncbi.nlm.nih.gov/26640299/)

2024 tarihli göz izleme araştırması da animasyonda **anlatıyla ilişkiyi** inceliyor. Sonuçları, hareket edecek öğeyi hikâyedeki önemli bilgiye göre seçmek gerektiğini destekliyor. Bir yaprağın sürekli kıpırdaması ile anlatılan nesnenin hareketinin açıklanması aynı tasarım kararı değil. [Özgün çalışma](https://pmc.ncbi.nlm.nih.gov/articles/PMC11651708/)

### Ekran, kitap sayfasını aynen taşıyarak avantaj kazanmaz

Furenes, Kucirkova ve Bus2021’de39 çalışma/1.812 çocuk üzerinden1–8 yaşta kâğıt ve ekranı karşılaştırdı. Yalnız dijitalleştirilmiş kitaplarda anlama kâğıt lehineydi; hikâyeyle uyumlu dijital desteklerde sonuç farklılaşabiliyordu. Sözlük, kelime öğrenmesine yardımcı olurken hikâye anlamasına aynı faydayı sağlamıyordu. Yetişkin desteği de önemliydi. Bu nedenle fiziksel kitabın geniş çift sayfasını telefona küçültmek yerine, onun merak ve ritim tekniklerini mobil alana uyarlamalıyız. [Meta-analiz](https://journals.sagepub.com/doi/10.3102/0034654321998074)

### Kişiselleştirme bir fırsat; tek başına kalite garantisi değil

2014’te18 okul öncesi çocukla yapılan deneyde, kişiselleştirilmiş bölümlerdeki hedef kelimeler sonraki ölçümlerde daha iyi öğrenildi. Küçük örneklemli, tekrar okumalı bu çalışma, çocuğun adını mor yazmanın tek başına aynı sonucu vereceğini kanıtlamaz. Bizim için hipotez: adın yanında çocuğun hikâyede anlaşılır bir amacı, kararı ve sonucu olması sahiplenmeyi güçlendirebilir. [Özgün çalışma](https://journals.sagepub.com/doi/10.1177/0142723714534221)

### Okuma hevesi, anlama ve dikkat farklı sonuçlar

National Literacy Trust’ın2025 raporu5–18 yaş grubundaki114.970 yanıta dayanıyor. Okuma zevki üzerine geniş bağlam sağlar; bir arayüz kararının etkisini veya Türkiye’deki çocukların davranışını kanıtlamaz. Bizim pilotumuz, “görseli beğendi”, “devam etmek istedi” ve “hikâyeyi anladı”yı ayrı ölçmeli. [Araştırma raporu](https://literacytrust.org.uk/research-services/research-reports/children-and-young-peoples-reading-in-2025/)

## 3. Fiziksel kitaplardan alınabilecek teknikler

| Teknik | Kaynak/örnek ve erişim | MagicPaper’a aktarılabilecek ilke |
|---|---|---|
| Sayfa dönüşünü meraka bağlama | British Council’ın resimli kitap pedagojisi; aşağıda bağlantı | Bir sorunun/olayın cevabını sonraki sayfada verme; sırf devam ettirmek için her sayfayı yapay soruyla bitirmeme |
| Tekrar + küçük değişim | *I Want My Hat Back*, yayınevi özeti/yazar ve öğretmen kaynakları | Tanınan bir ifade ya da motif geri gelirken olayın değişmesi; çocuk tekrarın parçasını söyleyebilir |
| Resim ve metnin farklı işler yapması | Aynı kitapta diyalog ve görsel mizah; yayınevi açıklaması | Resim yalnız metindeki ismi göstermek yerine ince bir anlam/duygu taşıyabilir; bu ilişki editörce yazılmalı |
| Basit eylemle katılım | *Press Here*, Chronicle Books ürün açıklaması | Bazen bakma, tahmin veya sözlü katılım yeterlidir; her katılım için sensör/mini oyun gerekmez |
| Sesin ve sözün oyun olması | *The Book with No Pictures*, PRH açıklaması | Görselsiz sayfa da ses, ritim ve ifade ile canlı olabilir; gövdenin tamamını rengârenk yapmadan seçilmiş ses sözcüğü vurgulanabilir |
| Okurun karakterden önce fark etmesi | *Sam and Dave Dig a Hole*, yazar sayfası | Görsel ipucu ikinci anlam katmanı kurabilir; ancak mevcut doğru-eşleme sistemi böyle ipuçlarını otomatik olarak uydurmamalı |
| Küçük motiften duygusal gelişim | *The Dot*, yaratıcının açıklaması | Tek bir görsel motif kitap boyunca anlam kazanabilir; aynı dosyayı her sayfaya koymakla eşdeğer değil |

Bu örneklerin çizim stillerini kopyalamak yerine anlatı görevlerini almalıyız. Özellikle Klassen türü görsel ironi, yanlışlıkla yapılmış metin/resim çelişkisiyle karıştırılmamalı: bilinçli ipucu, doğru zamanlama ve editör kontrolü gerektirir.

Kaynaklar: [British Council](https://www.teachingenglish.org.uk/picture-books-all), [Candlewick: I Want My Hat Back](https://www.candlewick.com/9780763655983/i-want-my-hat-back/), [Chronicle: Press Here](https://www.chroniclebooks.com/products/press-here.html), [PRH: The Book with No Pictures](https://sites.prh.com/the-book-with-no-pictures), [Mac Barnett](https://mac-barnett.squarespace.com/), [Peter H. Reynolds: The Dot](https://www.peterhreynolds.com/shop/p/the-dot).

### Uygulanabilecek sayfa dili

- **Sahne kuran açılış:** neredeyiz ve neye dikkat edeceğiz? Onaylı ortam/karakter görseli varsa daha büyük alan; yoksa dürüst nesne kompozisyonu.
- **Yakın plan keşif:** tek nesne önemliyse ölçeği ve yerleşimiyle odak kurmak. Harita her zaman eşit boyutlu bir üst simge olmak zorunda değil.
- **Konuşma anı:** metindeki gerçek diyaloğun nefesini ve paragraf ayrımını kullanmak; yeni konuşma veya bilinmeyen konuşmacı icat etmemek.
- **Sessiz/duygusal an:** az öğeli ve ferah sayfa; boşluğu otomatik olarak doldurmamak.
- **Sonuç:** önce kurulmuş bir motifi anlamlı biçimde geri getirmek. Nesnenin durumu değişmişse eski dosyayı kullanmamak.

Bunlar önerilen editoryal görevlerdir, henüz kodlanacak beş kesin şablon değildir. White space’in miktarı kadar **o sayfanın niye sessiz olduğu** önemlidir. World Bank’ın yazar/çizer rehberi de resim, metin ve sayfa dönüşünün birlikte planlanmasını vurguluyor; basılı kitaptaki punto tabloları doğrudan iPhone punto standardı olarak alınmamalı. [Rehber](https://www.earlylearningresourcenetwork.org/system/files/resourcefiles/Read-Home-Writers-and-Illustrators-Guide-World-Bank.pdf)

## 4. Dijital örnekler: neyi almalıyız?

| Örnek | Resmî belgede görülen yaklaşım | Bizim için değer / sınır |
|---|---|---|
| Khan Academy Kids | Kitaplar bölümünde dinle/kendin oku; eğitim bölümünde soru ve ders etkinlikleri ayrımı | Serbest hikâye ile öğretim görevini ayırma fikri güçlü. Her masal sayfasına test sorusu eklemek zorunda değiliz. |
| Google Read Along | İstenince satır/kelime desteği, sesli okumaya geri bildirim; yıldız/rozet de var | İhtiyaç anında yardım ilkesini değerlendirebiliriz. Sürekli mikrofon, puan ve ödül ekonomisini mevcut offline masala taşımak ayrı kapsamdır. |
| Vooks | Şirketin açıklamasına göre sakin animasyon, kontrollü anlatım ve vurgulanan metin | Anlatılan ayrıntıya dikkat çekme bakımından referans. Video benzeri otomatik akış, çocuğun kendi temposuyla sayfa çevirmesinin yerini almamalı. Pazarlama iddiası deneysel kanıt değildir. |
| Book Dash | Kitapların tasarım/çizim kaynaklarını da paylaşan açık içerik yaklaşımı | Yasal tam-kitap incelemeleri ve sayfa dizisi denetimleri için iyi araştırma havuzu; MagicPaper’ın karakterleri yerine bu karakterleri aktarma önerisi değil. |

Kaynaklar: [Khan Academy ürün rehberi](https://khankids.zendesk.com/hc/en-us/articles/4409036780955-Learn-more-about-the-books-in-the-Khan-Academy-Kids-app), [Google Read Along yardım](https://support.google.com/readalong/answer/12291548?co=GENIE.Platform%3DDesktop&hl=en), [Vooks ürün açıklaması](https://info.vooks.com/vooks-faq), [Book Dash kaynak ve atıf kuralları](https://bookdash.org/re-using-the-book-dash-content/).

## 5. İki okuma bağlamına ayrı öneriler

| Karar | 3–6: ebeveynle birlikte | 7–10: bağımsız okuma |
|---|---|---|
| Sayfanın ilk daveti | Anlaşılır eylem/duygu ya da keşfedilecek nesne | İlgi çekici olay, kısa ulaşılabilir metin parçası ve gerektiğinde görsel ipucu |
| Resmin işi | Anlatılanı somutlaştırma, beraber konuşulacak ayrıntı | Yer/motif/olayın zor kısmını açıklama; bebeksi sürekli maskot kullanmama |
| Tipografi | Nefes grupları, ifadeli ama sınırlı vurgu | Tutarlı satır boyu ve kısa paragraflar; diyaloğun kolay ayırt edilmesi |
| Katılım | İsteğe bağlı sözlü tahmin, tekrar edilen sözü birlikte söyleme | İstenince kelime desteği, ipucu fark etme; zorunlu ara test yok |
| Ritim | Keşif → eylem → duraklama fark edilir | Bölüm ilerlemesi ve görsel aralıklar; her sayfada büyük resim şart değil |
| Başarı işareti | Çocuğun resme/hikâyeye dönmesi ve devam istemesi | Kendi isteğiyle okuma/yeniden açma, anlaşılmayan yerde yardım kullanabilme |

Bu ayrım varsayılan bir tasarım hipotezidir. Okuma güçlüğü, ana dil ve kişisel tercihler yaş kalıbına zorlanmamalı; velinin yazı/tema tercihleri korunmalı. Uyku modunda sürpriz yoğunluğu ve hareket daha da sakin tutulmalı.

## 6. MagicPaper mimarisiyle gerçek uyum

**Aktif offline hat:** `ComposedPage` zaten `role`, `beats`, `emotion`, `variantIDs`, `refrain` ve authored fingerprint taşır. `BlueprintPageSlot` sayfa rolü/beat/duyguyu bilir. `OfflineStoryMapper.appPage` şu anda uygulamaya metin, authored visualScene→imagePrompt ve kelime verisini aktarır; bütün bu semantiği bir okuyucu yerleşim sözleşmesi olarak saklamaz.

`StorySpotBinder` yalnız incelenmiş ilk `hook`/`notice_anomaly` sayfasını bağlar; mevcut340 katı kural bütün kitabı resimlemez. Paketli12 çizimin10 konusu aktiftir. Boş yuva/açık müzik kutusu için runtime kuralı yoktur. Bu nedenle “artık sayfalara değişen resimler koyabiliriz” demek bugünkü kapsamı abartır.

Paketin diğer alanındaki `Domain/StoryPage` ve `VisualSystem/PageLayoutRule` yapılarında layout/typography alanları bulunması, aktif offline→app okuyucunun bunları kullandığı anlamına gelmez. Yeni tasarım kararı bunların hazır çalıştığı varsayımıyla verilmemeli.

**Gelecekte değerlendirilecek sınır:** yazılmış sayfa rolü + doğrulanmış görsel durumu + cihazın metin bütçesi, sunumu birlikte seçebilir. Bu bir mimari öneridir; bu araştırmada alan/API/schema eklenmedi. İstenen bilgi eksikse mevcut sakin metin/spot düzeni kalmalı. Okuyucu isim/kelime arayarak sahne tahmin etmemeli.

Serilerde nesne/karakter durumları ve kayıtlı pinler korunmalı; kilit açılırken yeniden sanat seçilmemeli. Çocuğun kimliği Character Bible’dan; Ragi mevcut kanonik referansından gelmeli. Ragi’nin açıklama yapması anlatının parçası değilse her sayfaya eklenmemeli. Onaylı mat guaj, beyaz/açık lila, mor-turkuaz-mercan dili korunur; isteğe bağlı kâğıt temaları ayrı kalır.

Yerel kaynaklar: `MagicPaper/StoryEngineBridge/{OfflineStoryMapper,StorySpotBinder}.swift`, `StoryEngine/Sources/StoryEngine/Offline/OfflineStoryComposer.swift`, `StoryEngine/Sources/StoryEngine/Content/CatalogBlueprint.swift`, `MagicPaper/Screens/StoryReader/{ReaderText,StoryPageView,ReaderPageComposition}.swift`, `docs/research/2026-11-19-story-spot-fixtures.json`.

## 7. Üç yaklaşım ve önerim

| Yaklaşım | Ne değişir? | Kazanç | Bedel / risk |
|---|---|---|---|
| **A — Hikâye ritmine göre sayfa tasarımı (ilk önerim)** | Seçilmiş sayfalarda keşif/yakın plan, konuşma, sakin an ve sonuç için farklı editoryal düzen; aynı temiz font ailesi | Mevcut havuzla denenebilir; sayfa dizisi tekdüzelikten çıkar | Sunum semantiği ve metin bütçesi gözden geçirilmeli; yalnız nesne havuzu karakter eylemini anlatamaz |
| B — Baştan sona resimli kitap | Olay ve karakter durumuna özel, sürekliliği doğrulanmış sahne dizileri | Özellikle birlikte okumada daha zengin anlatı potansiyeli | Çok daha fazla asset, Character Bible ve durum/sahne doğrulaması; tüm kombinasyonları kapsama maliyeti |
| C — Katılımlı dijital anlatı | Seçilmiş olayda tahmin, dokunma veya hikâyeye bağlı kısa hareket | Çocuk hikâyeye katılabilir | Dikkat/uyku akışı/erişilebilirlik ve üretim maliyeti; iyi tasarlanmazsa okumanın önüne geçer |

Önerim **A’yı mevcut düzenle karşılaştırmak**, B için yalnız bir küçük kitabın sahne dizisini ayrıca değerlendirmek, C’yi ilk deneyin dışında tutmak. Üçünü birden eklersek neyin hevesi artırdığını anlayamayız. Bu tercih kullanıcı onayı değildir.

### Gerçek masaldaki kritik örnek

Mevcut fixture: `Deniz’in Büyük Arayışı`, `story-art-audit-23`, yaş5–6; açılışta Deniz ormana gider, durur ve yırtık haritayı fark eder. Şu an harita metinden önce görünüyor. Bu nesne tanıtımı için doğru olabilir; fakat amaç haritanın bulunmasını sürpriz yapmaksa sonucu önceden gösterir.

İki alternatif denenebilir: (1) Aynı metin ve mevcut haritayla, yerleşim/ölçek/nefes farkını karşılaştırmak; (2) metni editör onayıyla yeniden sayfalayıp keşfi sonraki yaprakta açığa çıkarmak. İkinci seçenek **salt UI değişikliği değildir**: sayfa sayısı, sesli okuma aralıkları, pinler ve kaydedilmiş masal sözleşmesi etkilenir. İlk pilotta bu iki etki karıştırılmamalı. Kaynakta olmayan “haritanın arkasındaki anahtar” gibi yeni ipucu veya olay eklenmemeli.

## 8. Kodlamadan önce yapılabilecek pilot

1. Her bağlam için mevcut katalogdan bir uygun masal seç; sadece5–6 fixture’ını7–10 için yeterli kabul etme. Yeni metin üretim sistemi gerekmez.
2. Aynı masalın mevcut sürümü ve A yaklaşımıyla tasarlanmış4 temsilî sayfasını göster: açılış/keşif, deneme, duygusal an, sonuç. Eksik asset varsa onu açıkça göster; uydurma çocukla kapatma.
3. İlk karşılaştırmada metin, font tercihi ve hikâye sonucu aynı kalsın. Ayrı bir editoryal deneyde sayfa dönüşü merakı denenebilir.
4. Sonra küçük nitel oturumlar: grup başına6–8 çocuk/aile başlangıç önerisi, istatistiksel yeterlilik iddiası değil. Aynı hikâyeyi ikinci kez okuma etkisini azaltmak için eşleştirilmiş hikâyeler ve karşı dengelenmiş sıra kullan; hangi çocuğun hangisini önce gördüğünü kaydet.
5. Birlikte okumada çocuğa sessizce okumayı dayatma; ebeveynin yardım ihtiyacını da gözle.7–10’da başarıyı yaş yerine gerçek okuma rahatlığıyla yorumla.

| Ölçü | Bakılacak davranış | Yanlış yorum |
|---|---|---|
| Başlama isteği | Çocuğun gönüllü olarak hikâyeye yönelmesi | İlk animasyona bakması = okumak istemesi |
| Devam isteği | Kendiliğinden sonraki kısmı istemesi, ebeveynin dürtme ihtiyacı | Daha hızlı sayfa çevirmesi = daha iyi okuma |
| Anlama | Sonrasında doğal biçimde olayın ne olduğunu anlatabilmesi | Test düğmesine doğru basması = hikâyeye bağlanması |
| Yeniden seçme | Oturum sonunda tekrar bakmak istediği sürüm | Sırf yenilik etkisini kalıcı alışkanlık saymak |
| Okuma yükü | Kelime yardımı/kaydırma/denetim karışıklığı | Uzun ekran süresi = başarı |

Pilotun karar ölçütü: yeni düzen daha çok gönüllü devam/yeniden seçme işareti verirken anlama ve okuma rahatlığını zayıflatmamalı. İlk küçük örneklemde yüzdelik ürün vaadi veya kesin başarı eşiği ilan edilmemeli. Gözlem notlarında gerçek çocuk isimleri yerine katılımcı kodu yeterli; ses/video kaydı ve yeni analitik zorunlu değil.

## 9. Şimdilik yapmamamız gerekenler

- Her sayfayı aynı şablonda daha büyük bir nesneyle doldurmak.
- Hikâyeden bağımsız sürekli hareket, konfeti, ödül ve tıklanacak süsler eklemek.
- Her sayfada soru sorarak birlikte okumayı sınava dönüştürmek.
- Görsel/mekân/karakter durumunu yalnız kelime eşleşmesiyle tahmin etmek.
- Fontu rastgele değiştirmek, bütün metni renklemek veya sorunları küçük yazıyla çözmek.
- Büyük yazı kullanan çocuğun okunabilirliğini görsele feda etmek.
- Tamamı incelenmemiş yayınevi örneklerinden kesin iç sayfa oranları veya gelişim iddiası üretmek.

Sonraki karar, A/B/C’den hangisinin ilk görsel denemeye dönüşeceğidir. Bu araştırma bir seçenek ve kanıt havuzudur; mevcut okuyucunun yeniden yazılması için onay sayılmaz.
