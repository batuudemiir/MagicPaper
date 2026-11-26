# Beş arkadaş × üç mod: 5–6 yaş pilot içerik önerisi

**Tarih:** 22 Kasım 2026 · **Durum:** B yaklaşımı kabul edildi; aşağıdaki dünya/kurgu kapsamı öneridir. Yeni metin, blueprint, karakter profili ve asset yazılmadı.

**Bağımlılık:** [K0–K1 kaynak koruma planı](2026-11-22-bes-arkadas-k0-k1-uygulama-plani.md). Pilot doğrulanmadan yeni politika üretime açılmaz. Konuklu meslek, deniz ve uzay bu pilotun kapsamına girmez.

## 1. Ortak dünya: Fısıldayan Orman

Öneri: **tek anlatı dünyası, iki ayrı mekân**. Aynı setting kaydını üç moda zorlamıyoruz.

| Mod | Mekân | Kaynak ve yeni içerik ihtiyacı |
|---|---|---|
| Öğrenme / macera | Fısıldayan Orman; `setting_whispering_forest_001` | Pilot için bu exact kimlik sabitlenir. Aynı görünen ada sahip `setting_forest_001` ile eşitlenmez: biri span, diğeri opening threshold bildiriyor |
| Uyku | Aynı dünyanın orman kıyısındaki odası | Yeni pilot mekân önerisi: **Orman Kıyısındaki Oda**. Henüz kanonik ID atanmadı, içerik yok. `isRestingPlace` taşır; ilk/son sayfa aynı odayı söyler. Açık orman yatağa çevrilmez; mevcut iki oda tarihsel olarak yeniden adlandırılmaz |

Dünya önerisini üç nedenle seçtim: Tarçın/Kestane/Yıldız/Böğürtlen için mevcut forest bağı var; ormanda iz/ses/bakış açısı türü farklı olaylar yazılabilir; önceki sanat örneklerinde gerçek orman bağlamları var. **Simit için bugün forest yok.** Pilot sürümünde şehirden ziyarete gelen aynı Simit olarak yeni tanışma/metin/profil yazılır. Eski city-cat kaydına orman habitatı ekleme yok; Simit “hep burada yaşamış” denmez.

Mevcut ortak dünya otomatik model alanı değildir: gündüz ve odanın aynı pilot dünyaya ait olduğu yeni pilot manifestinde açıkça ilişkilendirilir. Eski kitapların `worldID`/kapak seçimi veya oda habitatı topluca değiştirilmez. Yeni mekân/profil ayrı pilot snapshot'ında kalır; loader'ın beat replacement düzeni yüzünden aynı bundle'a fazladan JSON koyup izolasyon var sanılmaz.

“Tek dünya”yı “tek settingID” olarak yorumlamak istenirse mevcut uyku arkıyla çatışır. Bu öneri tek dünyayı, gündüz dış mekânı ve gece odasıyla tutarlı küçük bir coğrafya olarak kullanır.

## 2. Pilotun kapsam sınırı

- 5–6 yaş; mevcut bant sayfa sayısı **8**; yaşın kelime bütçesi ve çocuk eylemliliği kuralları korunur.
- Her kitapta bir ana arkadaş; aynı kitapta beşli takımın tamamı yok. Yeni seçim politikası yalnız ayrı internal pilot repository'sinde denenir.
- Üç mod; mod içi konu seçimi başlangıçta `nil`. Pilot “Meslekler”, “Sporlar”, “Denizin altı” veya “Uzay” vaadi vermez. Mevcut üretim bu yüzden konu kaybetmez; production legacy kalır.
- İlk temiz içerik ölçümü konuksuz, ailesiz, özel günsüz, bağımsız kitap. Family/safety/recall uyumluluğu aşağıdaki ayrı kontrollerde görünür; bu bağlamlara hazır denmez.
- Yeni uyku metinlerinde her arkadaş çaresiz küçük konuk olmak zorunda değildir. R ve karaktere uygun N içerikleri ayrılır; fiziksel boyut/anatomi gözetilir. Böğürtlen pencere pervazına sığdırılmaz.
- `canFly` / `canCarry` / gerçek anatomi sert sınırdır. Yıldız'ı uçmayan sayarak, Böğürtlen'i taşıyamaz sayarak eski yasaklı şablona sokma yok. Yeni kurgular yetenek bulunsa da çocuğun çözümünü gerekli kılmalı.
- `hasLocalKnowledge` bilgisi yeni kurguda “bu olayı çözmenin cevabını biliyor” anlamına gelmez. Eski blueprint yasağı yerinde kaldırılmaz; pilotta somut yeni olay ve çocuğun bilip arkadaşın bilemediği bilgi yazılır.
- Gündüz forest keşif havuzu: yalnız gerçek mekân/konu koşulunu taşıyan kayıtlar. `object_ball_001` ve spor nesnelerinin habitatı village; ormanda spor oyunu elde etmek için sessizce taşınmazlar.

## 3. Repertuvar hedefi: 9 kurgu tasarımı, 30 uygun eşleşme

**Bu sayılar üretim tahmini değil, önerilen pilot kapsamıdır.** Üç ayrı yapısal mekanizma/mod; her karakter her modda iki mekanizmaya katılır. Böylece 15 hücre tek bir masalın beş isimli kopyası olmaz. Yeni kurgu kimlikleri içerik yazımı sırasında atanacak; aşağıdaki U/L/A kodları **plan etiketidir, runtime sourceID değildir**.

| Plan etiketi | Mod / mekanizma | Çocuğun somut eylemi ve neden farklı olduğu | Arkadaşlar |
|---|---|---|---|
| U1 | Uyku: sesleri tanıyıp yavaşlamak | Odanın sakin seslerini ayırt eder; her sesi tanıdık bir şeye bağlayıp dinlenmeye alan açar. Karanlıkta tehdit/gizem yok | Tarçın, Yıldız, Böğürtlen |
| U2 | Uyku: kendi dinlenme yerini hazırlamak | Uygun rahatlığı dener, arkadaşın seçimini dinler, hazırladığı yeri arkadaşın kullanmasına izin verir. Ninniyle uyutmanın isim değişimi değil | Kestane, Simit, Böğürtlen |
| U3 | Uyku: günü bir ayrıntıyla kapatmak | Günün küçük bir anını seçer, paylaşır ve anlatmayı bırakıp dinlenir. Bir bilmece/yarın kancası değil | Tarçın, Kestane, Yıldız, Simit |
| L1 | Öğrenme: iki gözlemle sesin kaynağını anlamak | İlk tahminini iki somut gözlemle denetler; arkadaş tek gözlem sunar, çıkarımı çocuk yapar | Tarçın, Yıldız, Simit |
| L2 | Öğrenme: bakış açılarını birleştirmek | Aynı izi/şekli iki yönden gözlemler; ikisinin de kısmen gördüğünü birleştirir | Kestane, Yıldız, Böğürtlen |
| L3 | Öğrenme: bekleyerek farkı görmek | Küçük, gözle görülebilen değişimi tekrar gözler; aceleyle çekip/düzeltip sonucu zorlamaz. Yanlış inançla yüzleşme yerine sabır deneyi | Tarçın, Kestane, Simit, Böğürtlen |
| A1 | Macera: küçük adımla eşiği geçmek | Güvenli açıklığı kendi adımlarıyla geçer; arkadaş taşımak/uçurmak yerine yanında olur | Tarçın, Kestane, Simit |
| A2 | Macera: iki farklı katkıyla yolu tamamlamak | İki parçası olan bir düzeni/işareti çocuğun kararıyla birleştirir; tek kişinin gücü/uçuşu doğru sırayı seçemez | Tarçın, Yıldız, Böğürtlen |
| A3 | Macera: kendi geçtiği yolu yeniden okumak | Daha önce çocuğun gördüğü ayrıntıya geri döner; yerel rehberin bilmesi gerekmeyen yeni bir kaybı çözer | Kestane, Yıldız, Simit, Böğürtlen |

U1/U2/U3 için `charge + bedtime` çerçevesi ve erken yumuşak doruk korunur; mevcut kaynakların N/`canCarry` koşulları yeni tasarıma kopyalanmaz. **Önceki rapora ek açıklama:** Böğürtlen'in bugünkü uyku boşluğunda N eksikliğinin yanında blueprint'in `forbids.canCarry` koşulu da var. N eklemek tek başına çözüm değildir.

U3'ün yeni 5–6 repertuvarı mevcut 7–10 “günü sayma” metninin yaş etiketini değiştirerek yapılmaz. U1'in gece sesleriyle L1'in bilimsel çıkarım kurgusu aynı şey değildir: U1'de anlaması gereken gizem/yanlış inanç/gerilim yok; L1'de çocuk neden-sonucu iki gözlemle bulur. İkisi ölçümde aynı yapısal eylem dizisine dönüşürse farklı mekanizma sayılmayacak ve içerik yeniden tasarlanacak.

### 3.1 Beş arkadaş × üç mod × rol/katkı matrisi

G = guide; R = reassuring; H = hesitant; N = needsCare. Roller yeni içerik için öneridir, mevcut şablonlara açılım yetkisi değildir.

| Karakter | Uyku (iki mekanizma) | Öğrenme (iki mekanizma) | Macera (iki mekanizma) |
|---|---|---|---|
| Tarçın | U1 R: dinler; U3 R: çocuğa anlatma alanı açar | L1 G/R: tek ipucu; L3 R: beklemeyi paylaşır | A1 R: acele ettirmez; A2 G/R: çocuğun sırasına uyar |
| Kestane | U2 N/R: rahat yerini seçer; U3 R: küçük bir an paylaşır | L2 H/R: farklı yönden bakmayı önerir; L3 R: gözlemi sürdürür | A1 H: küçük adımı kendisi de dener; A3 R: çocuğun hatırlamasına eşlik eder |
| Yıldız | U1 R: az sözle bir sesi tanır; U3 R: sessizce dinler | L1 G/R: gözlem yapar, cevabı söylemez; L2 R: ikinci görüş açısını sunar | A2 G/R: çocuğun planına gözlem; A3 R: yerel bilgi yerine çocuğun gördüğü ayrıntı |
| Simit | U2 N/R: hareketten dinlenmeye geçer; U3 R: günün bir anını seçer | L1 G/R: merak edip dener; L3 R: beklemek için küçük bir yöntem bulur | A1 R: güvenli küçük adım; A3 G/R: yavaşlayıp geriye bakar |
| Böğürtlen | U1 R: sakin destek; U2 N/R: uygun geniş yerde dinlenir | L2 R: diğer bakışı dinler; L3 R: zorlamadan sabır | A2 R: sabitleme/denge, çözüm çocukta; A3 G/R: çocuğun seçtiği yoldan döner |

Her eşleşme için ayrı kişilik hareketi ve çocuğun sonucu belirleyen eylemi yazılır. Bir karakterin tek kitapta G ve R arasında rastgele değişmesi yok; alternatif rollerden biri kitap başında sabitlenir. Duygu değişimi mümkündür.

## 4. İçerik sahibine somut yazım brifi

### 4.1 İki katman

1. **Kurgu katmanı:** dokuz şeklin sebep-sonuç, engel, çözüm ve kapanışı; sekiz sayfanın beat/state planı. Aynı `mechanismKey`'in yeni ID almış kopyası artış sayılmaz.
2. **Karakter katmanı:** seçilmiş uygun iki şekil/mod için diyalog ve somut eylem; kanonik kişilik, anatomi ve bilgi kapsamı. İsim değiştiren genel satır havuzu tek başına bu katmanı karşılamaz.

### 4.2 Sekiz sayfalık işlevler

| Sayfa | Uyku | Öğrenme | Macera | Görsel ekibe gereken |
|---|---|---|---|---|
| 1 | Aynı odanın akşam düzeni | Somut merak uyandıran şey | Güvenli hedef/iz | setting + varsa gerçekten present nesne; adsız ses nesne değildir |
| 2 | Küçük uyku ihtiyacı/ritüel | İlk gözlem | Yaklaşma/ilk iz | Bulunan şey mi, aranan mı? presence ayrımı |
| 3 | Arkadaşın rolü/rahatlık tercihi | Arkadaşın tek katkısı | Arkadaşın desteği | Kanonik arkadaş, anatomik eylem, eşlik eden bütün beat'ler |
| 4 | Çocuğun sakin hazırlığı | Tahmin veya iki bakış | Tereddüt/karar/engel | Hazırlık gerçek taşıma/çekme diye çizilmez |
| 5 | Yumuşak merak/gülümseme doruğu | Deneme veya gözlem | İlk küçük deneme | Eylemi yapan çocuk mu arkadaş mı? Nesne kimde? |
| 6 | Tempo düşer, çocuk alan açar | Çocuğun çıkarımı/beklemesi | Çocuğun çözüm hamlesi | Somut çözüm eylemi; genel “helping” yeterli değil |
| 7 | Rahatlama | Yeni anlayış/sonuç | Hedefe ulaşma/onarım | sleeping/resting/whole/piece gibi gerçek durum |
| 8 | İlk oda, yoğunluk 0, kapalı son | Sakin kişisel sonuç | Sakin dönüş/sonuç | Tam kapanış + nakarat/recall parçaları dahil; geleceğe kanca yok |

Bu tablo **geçmiş bir compiler çıktısı veya onaylanmış beat dizisi değildir**. Özellikle U3 için `committed`, `attemptMade`, `solutionKnown`, `resolved` üretim/tüketim sırası `StoryBeat` sözleşmesiyle kurulmalı. R rolünü desteklemek için sahte `needKnown` veya arkadaşın söylemediği bakım ihtiyacı eklenmez. Gerekli beat modeli desteklenmiyorsa içerik/motor tasarımı açığı raporlanır; eski validator gevşetilmez.

Uyku eğrisi mevcut 5–6 ark sınırlarını taşır: erken ve yumuşak doruk, son sayfa 0, CalmEnding, ilk/son oda aynı. Ninni/uyku pozu için yorgunluk ile gerçek uyku ayrılır. Gündüz metnine uyku satırları karışmaz.

### 4.3 Kaynak/nesne sınırları

- `object_faint_sound_001` ince ses: görünür nesne değil. Ses için çan resmi bağlamak bu kaydı `object_bell_001`'e dönüştürür; yapılamaz.
- `object_bell_001` gümüş çan: görünür/audible ama `isUnexplained` bildirmiyor. L1'e seçilecekse yeni kurgu bu gerçek niteliklerle tasarlanmalı; sırf blueprint açılsın diye trait eklenmez.
- `object_footprints_001` orman izleri; `object_torn_map_001` harita: farklı `presence/state` ve çözüm gerektirir. A3'te iz hangi varlığa ait belirsizse arkadaşın izi diye çizilmez.
- `object_wilting_seedling_001` garden/forest'ta; L3 için bakım/bekleme adayıdır. “Bir gecede fide büyüdü” gibi doğrulanmamış biyoloji yazılmaz; küçük yaşa somut, doğru bir gözlenebilir değişim seçilir.
- Uyku için ihtiyaç duyulan yeni materyal/nesne varsa yeni kaynak tasarımı olarak kayda girer. Generic keşfi başka nesne diye çizmek veya küçük bir nesneyi ayının içine sığdığı yatağa dönüştürmek yok.

## 5. İçerik teslim dosyaları — ileride oluşturulacak

| Dosya / teslim | Sorumluluk ve kabul |
|---|---|
| Ayrı pilot paket manifesti | Age 5–6, tek dünya, iki setting, beş kanonik ID, dokuz tasarım, otuz izinli character/shape eşleşmesi; production repository'den ayrı |
| Yeni blueprint kimlikleri | Eski blueprint'e alias yok; yeni verse/ref tanımı; bütün sekiz sayfanın beat/state ve kelime bütçesi denetlenmiş |
| Yeni/uygun satır kaynakları | Her satır ID/text digest; reuse varsa aynı metin+ID ve tam uygunluk kanıtı; değişmiş metin yeni ID |
| Karakter profilleri | Simit'in ziyaret bağlamı; yerel bilginin kapsamı; fiziksel yetenekler; her kitap için sabit rol; eski canonical kayıtlar korunur |
| Visual anlam incelemesi | present/remembered/intended, states, görünür bütün özneler; `reviewed` eksiksiz liste; anatomy/action kanıtı ayrı |
| Tam kitap örnekleri | Otuz izinli eşleşmeden en az birer temiz sekiz sayfalık sentetik kitap; her sayfada sıralı tam provenance, source SHA ve bağlam |
| Art handoff güncellemesi | Şimdiki legacy örnek paketinden ayrı **pilot-authored** kanıt seti; gerçek yeni kaynaklar yokken uydurulmuş sourceID kullanılmaz |

Satır/çizim adedi şimdiden tahminlenmez. Dokuz tasarım × sekiz sayfanın proza yuvaları ve supporting beat'ler kesinleşince gerçek satır ihtiyaç listesi çıkar. Çeşitlilik kapısı için havuz hücresinde gereken varyantlar `BoundPoolTests` ve gerçek okunma örnekleriyle planlanır.

## 6. Pilot ölçüm ve yayın kapısı

### 6.1 Kontrol ve ölçüm katmanları

- **L:** dondurulmuş legacy kaynak. Orman/oda sabit; beşli × üç mod denenir. Eski kaynakta olmayan Simit/orman, uyku/Böğürtlen gibi hücreler “kurulamadı” kalır; başka mekâna düşürülmez.
- **F:** yalnız beşli filtresinin kayıplarını teşhis eden kol; yayın adayı değildir.
- **N:** yazılacak yeni pilot paketi. N metni L ile aynı olmak zorunda değildir; kaydedilmiş L kitapları K1 değişmezlerine uyar.
- Karakter seçilmemiş/sürpriz testlerinde de internal pilotun beşlisi kullanılır. Production varsayılanı legacy kalır.

**Örnekleme önerisi:** 15 hücre × 100 sabit ilk-deneme seed = **1.500 istek/kol**. İstek başına tek seed; hatalar ve sıfır art paydada. Otuz izinli shape/character eşleşmesi ayrıca deterministik sınır girdileriyle tek tek doğrulanır; bu zorlanmış örnekler rastgele dağılım ölçümüne karıştırılmaz. İsim değişimi mekanizma artışı sayılmaz.

A0 devamlı okuma deneyi ayrı: aynı 5–6 sentetik profilde 3 × 100, dönüşümlü ve açıkça belirtilmiş %60 uyku dağılımı. Mevcut cleanDraftAttempts=3 tarihsel metrik olarak raporlanabilir; **birinci deneme** sonucu daima ayrı ve ana ölçüdür. Art elde etmek için retry/reseed/variant filtresi yok.

### 6.2 Pilotun “doğrulandı” sayılması için

1. **15/15 hücre:** en az iki yapısal olarak ayrı, kişiliğe uygun mekanizma; otuz eşleşmede tam kitap kurulabilirlik. Her arkadaş tüm dokuz şekle zorlanmaz.
2. **1.500 ilk-deneme girdisi:** temiz metin, eksiksiz slot/çekim, doğru yaş/arc; başarısız girdiler raporda. Hata varsa pilot yayın kabulü yok; seed değiştirerek örnek listesi temizlenmez.
3. **Kişilik/anatomi:** en az otuz tam kitap editoryal incelemesi; çocuğun çözüm eylemi, bilgi/rol tutarlılığı, çizim-metni çelişkisi için sıfır kabul edilmiş ihlal.
4. **Çeşitlilik:** mod başına üç gerçek mekanizma; isimler çıkarılmış yapısal imza, `move` dizileri, çözüm/engel/sonuç farkları; ilk mekanizma tekrarı ve satır tekrar pencereleri açıkça ölçülür. Sadece `distinctSetups` artışı kabul gerekçesi değildir.
5. **Görsel:** bütün 1.500 istek için zero-art/books-with-art/pages-with-art, açılış/orta/son, tekrar, eksik kaynak ve politika red sebepleri raporlanır. İçerik ile art'ın bağımsız başarısızlıkları ayrılır. Minimum çizim kotası burada icat edilmez; “her masal görselli” vaadi yok. Görsel kapsamın ürün için yeterliliği bu rapor üstünden ayrıca kabul edilir; metin başarısı görsel kabul yerine geçmez.
6. **Bağlam kontrolleri:** güvenliğe göre elenen satırlar, aynı isimli Masal ailem, farklı family ilişkileri, recall ekli tam sayfa, özel gün ve seri istekleri ayrı matriste. Pilot bu içerikleri yazmadıysa açık `unsupported-in-pilot` sonucu; aile/recall sessizce atılarak başarı sayılmaz. Production bu yüzden değişmez.
7. **K1 uyumluluğu:** eski kitaplar ve hazırlanmış seri bölümleri/pinler değişmez; pilot kaynağı geçse bile eski hikâyeyi yeni profile yönlendirme yok.
8. **Release kapısı:** validation raporu + içerik sorumlusu incelemesi + görsel kapsam kabulü + açık ürün yayın kararı. Bunlar olmadan yeni beşli politika kapalı kalır. Eski app yetenekleri, diğer yaş/konu kayıpları ve source migration raporu genel yayın öncesi ayrıca kapanır.

9. **Uygulama yayın kapısı (kod düzeltmeleri, 26 Kasım 2026):**
   - **Senkronda bilinmeyen alan:** `StoryPageProvenance.p56`'yı bilmeyen eski uygulama sürümü kaydı okur ama yeniden yazarken bu alanı düşürür (sayfa metni ve `origin.contentSource` kalır, sayfa düzeyindeki iz kaybolur). Yayından önce ya senkron bilinmeyen alanları koruyacak, ya da P56 masalını eski sürüm yeniden yazamayacak (en düşük sürüm kapısı). Pilotta bayrak yalnız Debug'da olduğu için risk düşük; genel yayında kapanmadan geçilmez.
   - **Paket boyutu:** 12 MB P56 payload'ı pilot süresince Release'ten çıkarıldı (`EXCLUDED_SOURCE_FILE_NAMES`, uygulama hedefinin Release ayarı). Yayında sıkıştırılmış gelir; SHA açılmış baytlar üzerinde kalır. Release soğuk/sıcak yükleme ölçümü bu kapıda yapılır.

**Pilot doğrulaması genel yayın izni değildir.** Doğrulanmış 5–6 pilot, 3–4/7–10 veya bütün dünyaları kanıtlamaz. Ayrı app/internal test akışı ile değerlendirilir; kullanıcıya sessizce daha dar “Fark etmez” havuzu sunulmaz.

## 7. Konuklu ayrı teslimler

| Teslim | İlk kapsam önerisi | Bağımsız kabul koşulu |
|---|---|---|
| **G-Meslek** | 5–6, bir yerleşim mekânı, tek uzman; ör. `companion_baker_001` kendi kimliğiyle expert | Çocuk+beşliden biri uzmana gider; jobs companion şartı yeni şemada doğru yuvaya taşınır; uzman occupation/fact doğru; üç karakterli sayfa bütçesi; Masal ailem eklenirse ayrı kalabalık/uygunluk kontrolü |
| **G-Deniz** | Önce kıyı ve sualtı iddiasını ayrı seç; deniz canlısı konuğu kendi kimliğiyle | Beşli nerede/neyi görüyor açık; “Denizin altı” vaadi varsa gerçek sualtı bağlamı, biyoloji ve görsel ortam onayı; ayı yunusun eylemini üstlenmez |
| **G-Uzay** | Yolculuk/araç/koruyucu ortam kararı sonrası tek uzay mekânı ve tek yerel konuk | Uzayda varlık/ulaşım açık; Simit Ayçörek'e dönüştürülmez; aksesuar kimlik varyantı ve kaynak durumları; Yıldız'ın uçuşuna dayanarak uzay solunumu varsayılmaz |

Her teslim kendi yeni şema gerekçesi, source snapshot'ı, konu eşiği/yaş matrisi, tam kitap ve sanat handoff'uyla gelir. Meslek modelinin kaynak izine yeni özne rolü eklemesi gerekiyorsa `PageProvenance` sözleşmesi sürümlenir; `expert`i `companion` gibi göstermeyiz. Bunlar şimdi kodlanmıyor.

## 8. Görsel ekibe teslim

[Kaynak ve eylem brifi](2026-11-22-bes-arkadas-56-gorsel-teslim.md) ve [tam sayfa JSON kanıtı](../../research/2026-11-22-bes-arkadas-56-gorsel-kaynaklar.json). Paket mevcut gerçek kaynakların tam kitap/sayfa bağlamını verir; yeni pilotun henüz yazılmamış kaynaklarını varmış gibi göstermez. Yeni pilot yazımı sonrası aynı yapı gerçek pilot kaynaklarıyla doldurulmadan eylem çizimine runtime onayı verilmez.
