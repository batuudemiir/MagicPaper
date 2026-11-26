# Beş arkadaş: mimari ve içerik geçiş planı

**Tarih:** 22 Kasım 2026 · **Durum:** karar ve uygulama öncesi inceleme taslağı.

> **Sonraki karar:** Kullanıcı B yaklaşımını, üç modda kişiliğe uygun repertuvarı ve pilot doğrulanmadan yayın yapılmamasını kabul etti. Güncel ayrıntılı teslim: [K0–K1 uygulama planı](2026-11-22-bes-arkadas-k0-k1-uygulama-plani.md), [5–6 pilot kapsamı](2026-11-22-bes-arkadas-56-pilot-kapsami.md) ve [görsel ekip brifi](2026-11-22-bes-arkadas-56-gorsel-teslim.md). Bu eski rapordaki yaklaşım onayı soruları tarihsel öneridir; kodlama henüz başlamadı.

**Amaç:** Yeni kişiselleştirilmiş offline masalların ana arkadaşlarını Tarçın, Kestane, Yıldız, Simit ve Böğürtlen etrafında toplamak; mevcut kitapları, serileri, kimlikleri ve sabitlenmiş görselleri korumak.

**Mimari öneri:** Sürümlü ana kadro politikası + aynı kanonik kimliklere bağlı sürümlü anlatı profilleri + gerektiğinde ayrı konuk/uzman rolü. Motor anlamı ve kaynak izini taşır; çizim seçimi uygulamada kalır. Bu belge uygulama yetkisi değildir.

**Teknoloji:** Swift offline StoryEngine paketi, JSON içerik kütüphaneleri, uygulama köprüsü, SwiftUI seçim ekranı, paketli sanat ve mevcut kalıcı Story/Series modelleri.

**Bu tur:** salt okunur kaynak incelemesi, statik kayıt uygunluğu hesabı, önceki gerçek composer→mapper ölçümünün incelenmesi. Üretim kodu, içerik JSON'u, karakter dosyaları, görsel dosyaları ve kayıtlı kitaplar değiştirilmedi. Yeni runtime ölçümü, test veya simülatör koşusu yapılmadı. Kanıt: [kaynak özeti ve 60 hücre](../../research/2026-11-22-five-friends-evidence.json).

## 1. Karar özeti

Öneri **B: sürümlü beş ana arkadaş + ayrı konuk rolü**. Önce eski üretim davranışını saklayacak katalog sürümü çözümlemesi kurulur; sonra yeni anlatı profilleri ve içerik hazırlanır. Arayüz, güvenlik ve konu kapılarının kabul ettiği beşliyi kanonik çizimleriyle gösterir. Beşinin her modda bir repertuvarı olması hedeflenir; her birinin her blueprint'e ya da her dünyaya uyması şart değildir.

Üç ayrı iş paketi vardır:

1. **Mimari/uyumluluk:** yeni masal seçimi ile eski kitabın devamını ayırmak, profil/kadro sürümü saklamak.
2. **İçerik yeniden tasarımı:** uyku katılımı, uzmanla karşılaşma, dünya ziyareti, kişilik sesi ve gerçek olay örgüsü çeşitliliği. Mevcut satırların yalnız adlarını değiştirerek yapılamaz.
3. **Sanat/arayüz:** tanınabilir beş seçim resmi, kaynakla doğrulanmış duygu/eylem çizimleri ve uygulama bağlayıcısının genişlemesi.

Ragi bu politikanın üyesi değildir. Marka rehberi olarak mevcut kullanımını sürdürür; Originals'taki konukluğu kitap bazında editoryal karardır. Bu plan Ragi için altıncı offline seçim kartı veya yeni çizim istemez.

Kullanıcının bu sohbetteki kadro ve tanışma görseli onayı esastır. `characters.json` ve tanışma HTML'indeki “taslak/onay bekliyor” ibareleri eski durumu anlatıyor; bu tur değiştirilmedi. Bu onay, ayrı poz dosyalarının runtime bağlama onayı anlamına gelmez.

## 2. Mevcut mimari ve gerçek boşluklar

### 2.1 Etkin üretim yolu

`StoryChoiceSources.current` → `OfflineStoryService` → `BlueprintSelector` → `OfflineContentBinder` → `OfflineStoryComposer` → `OfflineStoryMapper` → `StorySpotBinder` ve alt bağlayıcılar → saklanan `Story`.

- `ContentCatalogLoader` zorunlu `shared_content_library_v2.json` üstüne `pilot_library_v1`, recall ve occasion kütüphanelerini yükler. Beat korpusu, kapsadığı beat'lerin kütüphane şablonlarını **değiştirir**; ham JSON sayımı etkin satır havuzu değildir.
- `CatalogSourceResolver`, doğrulanmış indirilen tam içerik paketini seçebilir. Offline yazma, bütün içeriğin mutlaka sadece ilk app bundle'ından gelmesi demek değildir. Bu kaynak seçimi eski sürümleri arşivleyip plan sürümüne göre çözmez.
- `BlueprintSelector.companionCandidates` her aday için binder'a sorar; yalnız trait kesişimiyle seçim yapmaz. Fakat binder başarısı bütün sayfaların proza/state/bütçe bakımından kurulmasını tek başına kanıtlamaz.
- Katalogda fiziksel yetenek (`CompanionTrait`), masaldaki rol (`CompanionRole`), varlık türü (`CompanionNature`), habitat, ilgi, güvenlik konusu ve meslek ayrı eksenlerdir. Bir anlatı rolü masal başında seçilir; sayfa sayfa karakter değiştirilmez.
- Mevcut dört rol: `guide`, `reassuring`, `hesitant`, `needsCare`. Yeni bir rol enum'u zorunlu değil; “gözlemci”, “oyun başlatan”, “destek olan” ayrımları önce mevcut roller altında yazılmış anlatı hareketleriyle ifade edilebilir.
- `StoryEngine/README.md` genel sağlayıcılı eski boru hattını da anlatıyor. Canlı metin üretim yolunu açıklamak için tek başına doğruluk kaynağı sayılmadı.

### 2.2 Güncel kaynak envanteri

Bu checkout'taki iki ana kütüphanede, kimlik bazında birleştirilmiş **34 arkadaş, 36 mekân, 43 keşif, 78 ana blueprint** var. Bunlar ham kayıt sayılarıdır; 78'e seri/özel gün alt kataloglarını ekleyip aynı kapsam gibi göstermiyoruz. Arkadaşların 29'u trait bildiriyor; kalan beşi tarihsel/etiketlenmemiş kayıttır ve trait temelli seçime bu hâliyle girmez.

Beat dosyaları: **2.721 satır = 1.396 auto + 268 reviewed + 1.057 etiketsiz**. Görsel sözleşmesinin ilk teslimindeki 1.622/0/1.099 sayıları tarihsel tabandır; bugün diye kullanılmamalı. `reviewed` içerik anlam incelemesidir; asset uyumluluğu onayı değildir.

Tam kimlik/trait/habitat/rol listesi kanıt JSON'undadır. İşlevsel dağılım:

| Mevcut grup | Kimlikler / kişiler | Karşıladığı alan ve geçiş riski |
|---|---|---|
| Onaylı ana beşli | Tarçın, Kestane, Yıldız, Simit, Böğürtlen | Orman/bahçe/dağ ve yalnız Simit için kasaba; uyku rolünde yalnız Kestane/Yıldız |
| Deniz | Köpük `companion_dolphin_pilot_001`, Pofuduk `companion_penguin_001`, Yavaş `companion_turtle_001` | `sea`, yüzme/taşıma, çekingenlik/bakım/rehberlik; beşlide deniz habitatı yok |
| Uzay | Vida `companion_robot_sky_001`, Ayçörek `companion_space_cat_001` | `sky`; uzay uyumlu beden/aksesuar ve özel dünya satırları; beşlide sky yok |
| Meslek/uzman | Fırıncı Nazlı, Postacı Remzi, Öğretmen Suna, Beden Öğretmeni Defne | `person`, `occupation`, `jobs`, meslek olguları; hayvanı uzmana çevirmek yanlış |
| Spor | Defne + keçi Zıpzıp `companion_goat_001` | `village` ve `sports`; ana beşlide sports etiketi veya village habitatı yok |
| Şehir | Simit + Pıtpıt `companion_city_dog_001` | `town`; Simit kalır, çekingen küçük köpek seçeneği kalkar |
| Ülke | Lolo `companion_llama_001`, Fındık `companion_marmot_001` | `faraway`; beşli için ziyaret bağlamı yazılmamış |
| Tarih | Taşbaş `companion_tortoise_001`, Gugu `companion_dove_001` | `oldstone`; yerel bilgi, uçuş, bakım; beşlide habitatı yok |
| Diğer etkin eski hayvanlar | sincap Fındık, Pırıltı, kurbağa Zıpzıp, Pati, Cesur, Cıvıl, Pamuk | Küçüklük, uçuş, hızlılık, taşıma, düz anlamanın farklı birleşimleri |
| Fantastik eski arkadaşlar | Kıvılcım `companion_dragon_001`, Zip `companion_robot_001` | Uçma/taşıma veya `isLiteralMinded`; beşliye bu yetenekleri ekleyerek taklit edilemez |
| Etiketsiz eski kayıtlar | Kıpır, Yonca, Bilge, Dikenli, Mavi | Sırasıyla `companion_fox_001`, `rabbit_001`, `owl_001`, `hedgehog_001`, `dolphin_001`; silinmez/ana beşliye yönlendirilmez |

Yaş uygunluğu mevcut sistemde büyük ölçüde blueprint ve satır bandından gelir; “her arkadaş için dört yaşta ayrı kanonik kimlik” yoktur. Mod da hayvan türünden değil blueprint ailesi ve arkından gelir.

### 2.3 Basit beşli filtresinin somut kayıpları

- **Uyku:** dört bantta da Tarçın, Simit, Böğürtlen `needsCare` taşımadığı için mevcut uyku yapısına giremez. Sakin kişilik tek başına uyku uygunluğu değildir. Üçüne topluca `needsCare` eklemek, “minik arkadaş pencereye gelmiş ve uyuyamıyor” satırlarını otomatik olarak doğru kılmaz; özellikle büyük ayı anatomisi/boyutu incelenmeli.
- **Meslekler:** en az dokuz mevcut ana blueprint `requires.nature = person` ister ve beşliyle karşılanamaz. 5–6: `bp_jobs_askingwhoknows_001`, `bp_jobs_craftspatience_002`, `bp_jobs_twohalves_003`; 7–8 ve 9–10: `bp_jobs_askingwhoknows_age7/age9_001`, `bp_jobs_craftspatience_age7/age9_001`, `bp_jobs_helpingatwork_age7/age9_001` (gerçek kimlikler kanıt JSON'unda). Ayrıca konu `companion: jobs` + `plot: jobs` ister.
- **Sporlar:** konu companion'da `sports`, discovery'de `sports` istiyor. Bir kediye yalnız spor etiketi vermek, köy çayırında oynanan satırları şehirde geçerli kılmaz.
- **Deniz, gökyüzü, ülke, tarih:** beşli mevcut habitatlarıyla bu dünya seçimlerini taşımaz. Blueprint'ler başka dünyalarda hâlâ kurulabilse de o konu/habitat kesiti kaybolur; bu kayıp toplam blueprint sayısında görünmez.
- **Olay örgüsü kaybı:** beşlide `isLiteralMinded` yok; bu trait'e dayanan satırlar için başka bir anlatı hareketi gerekir. Tarçın/Yıldız'ın `hasLocalKnowledge` niteliği bazı `unexplained` ve `absence` kurgularında yasaklıdır; her şeyi bilen rehber olmaları çeşitliliği azaltır. Yıldız'ın uçması ve Böğürtlen'in taşıyabilmesi bazı eşik kurgularında bilerek yasaklanır. Bu yasaklar kaldırılmamalı.
- **Ekran:** `drawable` SF Symbol adına göre tekilleştiriyor; motor havuzunu daraltmıyor. Kirpi varsayılan patiyle, tilki köpekle aynı simgeyi paylaşabilir. `CompanionStep.shown = 3` **bütün yaşlarda** uygulanıyor. Adaylar kimlik sırasına göre sıralanıyor; yorumdaki “best first” sıralama garantisi değil.

## 3. Yaklaşımlar ve öneri

| Yaklaşım | Kazanç | Bedel / sonuç |
|---|---|---|
| A — sadece yeni ana seçim havuzunu beşe indir | En küçük yazılım değişikliği; eski kimlikler kalabilir | Uyku üç arkadaşı kaybeder; meslek/spor ve çok sayıda dünya kesiti daralır. Açık ürün kapsam azaltmasıyla ancak geçici yayın olabilir; önerilmiyor |
| **B — beş ana arkadaş + ayrı konuk/uzman, sürümlü anlatı profilleri** | Karakter devamlılığı korunur; uzmanlık/biyoloji doğru kişide kalır; dünyalar içerik yazarak genişler | Gerçek bir casting genişlemesi ve yeni satırlar ister. Çocuk+ana arkadaş+uzman+Masal ailem yükü yaşa göre sınırlanmalı |
| C — yeni offline içerikte yalnız beş karakter, konuk da yok | En kapalı, kolay tanınan evren | Meslek/deniz gibi vaatleri yeniden tasarlamak veya açıkça kaldırmak gerekir. Hayvanlara meslek ve sualtı yeteneği atamak ayrı ürün kararıdır; kapsamı en büyük seçenek |

B'de **yeni ana arkadaş** her zaman beşliden gelir; seçim yapılmayınca ve sürprizde de aynı politika uygulanır. Eski katalog arkadaşları yeni ana havuza geri sızmaz. Eski kitap devamı ise yeni ana seçim sayılmaz; kitabın tarihsel arkadaşını sürdürür. Deniz canlısı/uzman gibi bir konuk, eski kimliğiyle ve ayrı rolüyle kalabilir. Bu konuk kararı uygulama öncesinde açıkça onaylanmalı.

B'nin ilk yayını konuk sistemi bitmeden yapılacaksa, kaybolan konu/habitat hücreleri tek tek yayın kapsamı kararı olarak sunulur. “Fark etmez” seçeneğinde onları sessizce dışlamak veya başka konuya çevirmek kabul edilmez. Hedef, mevcut konu vaatlerini karşılayan yeni içerik hazır olana kadar geçişi yayınlamamaktır.

## 4. Kişilik, yetenek ve anlatı profili

**Aynı kanonik kimlik korunur.** Hayvan tipi, görünüş ve isim başka eski karakterden kopyalanmaz. Önerilen anlatı profilinde değişmez kişilik sınırları, fiziksel yetenekler, bu masaldaki rol, bilgi kapsamı ve dünya deneyimi ayrı durur. Profiller içerik sürümüyle seçilir; eski katalog kaydı yerinde yeniden yazılmaz.

| Karakter | Değişmez ses ve katkı | Çeşitlilik sağlayan roller/hareketler | Yazılmaması gereken |
|---|---|---|---|
| Tarçın | Sakin, acele ettirmeyen; birlikte keşif | Rehber, güven veren; bazen bilmediğini söyleyen yol arkadaşı; kısa bir öneri, bekleyip alan açma | Her dünyayı önceden bilmek, cevabı çocuk yerine vermek |
| Kestane | Çekingen, anlayışlı; küçük adımlarla cesaret | Çekinen, güven veren, bakım alan; bazen ilk küçük adımı kendisinin önermesi | Her masalda korkan/çaresiz olmak; çekingenliğin alay konusu olması |
| Yıldız | Sabırlı, az konuşan gözlemci | Rehber, güven veren, dinlenmeye ihtiyaç duyan; bakış açısı sunma, sessiz ipucu | Uzun dersler, her olguyu bilmek, düşünme yerine uçup çözmek |
| Simit | Meraklı, hareketli; kıvrık kuyruk | Rehber, güven veren; yeni bir deneme başlatma; uykuya geçerken yavaşlama | Sürekli tehlikeye koşmak, aynı yanlışlığı durmadan yapmak |
| Böğürtlen | Sakin, güçlü, destekleyici | Güven veren/rehber; nesneyi sabitlemek, sıra paylaşmak, yardım kabul etmek | Her engeli taşımak, çocuğu fiziksel olarak bütün zorluklardan geçirmek |

“Bu defa bilmediği yere geldi” kanonik bilgi kaybı değildir. Ancak mevcut `hasLocalKnowledge` kalıcı trait'ini tüm hikâyelerden silmek de doğru çözüm değildir. Öneri: yeni profil sürümünde **yerel bilginin bu bağlamda geçerli olması** açıkça ifade edilir; eski profile aynı kurallar uygulanmaz. `canCarry` gibi fiziksel yetenekler profile göre keyfî kapatılmaz: o yeteneği yasaklayan blueprint uygun değildir ya da engel gerçekten yeniden yazılır.

Mevcut proza havuzunda `capabilityRequire`/`capabilityForbid` eşleşmesi havuz boşalınca gevşeyebiliyor (`OfflineStoryComposer.pool`, `narrow`). Bütün beşliyi yeni kişilik etiketleriyle işaretleyip aynı yumuşak filtreyi kullanmak tutarlılık sağlamaz. Yeni profillerde kişilik/kimlik/anatomi sınırları **sert**; anlatım tercihi, uzunluk tercihi gibi ikincil seçimler ayrı olmalı. Yeni sistemde gerçek uçuş/taşıma şartını gevşetmeme geçişin zorunlu koşuludur; legacy davranışı kendi sürümünde korunur.

Bir masalın rolü sabittir; rol içindeki duygu değişebilir. Kestane'nin sonunda cesaretlenmesi, rolün sayfa ortasında “her şeyi bilen rehber”e dönmesi değildir. Her yazılmış yeni hareketin setup → engel → çocuğun eylemi → sonuç zinciri incelenir.

## 5. Yaş × mod × karakter × rol matrisi

### 5.1 Bugünkü kaynaklardan statik aday üst sınırı

Aşağıdaki 60 hücre, canlı Swift motorunun başarısı değildir. Salt okunur statik hesap, band/mod/arc + trait/forbid + nature/casting + ortak habitat + threshold + keşfin mekânda zaten açıklanmaması koşullarını birlikte taradı. Her hücre **aday ana blueprint sayısı : mümkün rol** biçiminde. Proza, durum, güvenlik ayarı, konu, Masal ailem, özel gün ve seri koşulları bu sayılarda yok; uygulamanın sunduğu liste diye okunmamalı. Sıfır hücre bu kayıt koşullarında gerçek boşluğu gösterir; pozitif hücre tam masal garantisi değildir. Ayrıntılı blueprint kimlikleri kanıt JSON'unda.

G = guide; R = reassuring; H = hesitant; N = needsCare.

| Yaş / mod | Tarçın | Kestane | Yıldız | Simit | Böğürtlen |
|---|---|---|---|---|---|
| 3-4 / uyku | 0 : — | 4 : N | 4 : N | 0 : — | 0 : — |
| 3-4 / öğrenme | 4 : G/R | 4 : H/N/R | 4 : G/N | 2 : G/R | 2 : G/R |
| 3-4 / macera | 1 : G/R | 4 : H/R | 1 : G/R | 4 : G/R | 4 : G/R |
| 5-6 / uyku | 0 : — | 4 : N | 4 : N | 0 : — | 0 : — |
| 5-6 / öğrenme | 5 : G/R | 9 : H/N/R | 4 : G/N/R | 4 : G/R | 4 : G/R |
| 5-6 / macera | 3 : G/R | 6 : H/N/R | 2 : G/R | 4 : G/R | 5 : G/R |
| 7-8 / uyku | 0 : — | 4 : N | 4 : N | 0 : — | 0 : — |
| 7-8 / öğrenme | 4 : G/R | 3 : H/N/R | 2 : G/N | 2 : G/R | 2 : G/R |
| 7-8 / macera | 1 : G/R | 4 : H/N/R | 1 : G/R | 3 : G/R | 4 : G/R |
| 9-10 / uyku | 0 : — | 4 : N | 4 : N | 0 : — | 0 : — |
| 9-10 / öğrenme | 4 : G/R | 3 : H/N/R | 2 : G/N | 2 : G/R | 2 : G/R |
| 9-10 / macera | 1 : G/R | 4 : H/N/R | 1 : G/R | 3 : G/R | 4 : G/R |

### 5.2 Yeni profil için hedef uygunluk (öneri, henüz içerik yok)

G/R/H/N mevcut rollerin anlatı anlamıdır; yeni rol enum'u önerilmiyor. `N*` yalnız ihtiyaç kabul etme/yorulma gibi karaktere uygun yeni metinle; eski “minik, korkmuş” satırlarına topluca açma değildir. Her hücre en az bir tam masal ve uygun konu kapsamı gerektirir.

| Yaş / mod | Tarçın | Kestane | Yıldız | Simit | Böğürtlen |
|---|---|---|---|---|---|
| 3–4 uyku | R, N* | R, N | R, N | R, N* | R, N* |
| 3–4 öğrenme | G/R | R/H/N | G/R | G/R | R/G |
| 3–4 macera | G/R | H/R | G/R | G/R | R/G |
| 5–6 uyku | R, N* | R, N | R, N | R, N* | R, N* |
| 5–6 öğrenme | G/R | H/R/N | G/R/N | G/R | R/G |
| 5–6 macera | G/R | H/R | G/R | G/R | R/G |
| 7–8 uyku | R, N* | R, N | R, N | R, N* | R, N* |
| 7–8 öğrenme | G/R | H/R/N | G/R/N | G/R | R/G |
| 7–8 macera | G/R | H/R | G/R | G/R | R/G |
| 9–10 uyku | R, N* | R, N | R, N | R, N* | R, N* |
| 9–10 öğrenme | G/R | H/R/N | G/R/N | G/R | R/G |
| 9–10 macera | G/R | H/R | G/R | G/R | R/G |

- 3–4: tek olay/tek sorun; H, korku/gerilim yayı değil küçük bir tereddüt olabilir. N, çaresizlik veya tehdit değildir. Uzman konuk aynı sayfada kalabalık yaratıyorsa bu bant için tek konuklu yapı zorlanmaz; ayrı basit şekil yazılır.
- 5–6: somut deneme, görülen eylem ve kısa diyalog; arkadaş soruyu sorabilir, sonucu çocuk bulur.
- 7–8: iki gözlemi birleştirme ve farklı öneriler; arkadaşın katkısı çocuğun çözümünü devralmaz.
- 9–10: yeniden planlama ve tohum-hasat ancak yaş tüzüğü ve A5 ürün kararlarıyla; yeni karmaşıklık beşliye geçişin kendiliğinden parçası değildir.
- Uyku için R rolünü destekleyen **yeni blueprint/satırlar** gerekir; mevcut uyku blueprint'lerinin N şartı yerinde sessizce değiştirilmez. Böylece her arkadaşın uyku masalı olabilir; hepsinin sürekli uyuyamayan “bakım alan” olması gerekmez.

## 6. Dünyaların sınırları ve konu sözleri

| Dünya/konu | Bugünkü durum | İçerik uyarlaması / yeni yapı / ürün kararı |
|---|---|---|
| Orman, bahçe, dağ | Tarçın/Kestane/Yıldız/Böğürtlen farklı alt kümelerde; Simit yalnız town | Simit için “ziyaret” profili ve yeni dünya-tanışma satırları; Kestane'ye otomatik dağ habitatı eklenmez |
| Şehir | Simit doğrudan karşılar; diğer dördü town değil | Diğerleri ziyaretçidir. `mc_guide_01/02/04` gibi “burada doğmuş/her gün geçer” satırları kullanılamaz; yeni ziyaretçi tanışması |
| Deniz/sualtı | Beşlide sea/canSwim yok | Kıyı masalı “Denizin altı” sözünü karşılamaz. Deniz canlısı konuk + beşlinin nasıl gözlemlediğini anlatan ayrı yapı veya açıkça onaylı sualtı ulaşım evreni gerekir. Yunusun yüzüp taşıması ayıya aktarılamaz |
| Gökyüzü ve uzay | Beşlide sky yok; Yıldız'ın uçması uzayda yaşayabildiği anlamına gelmez | Gözlemevi/planetaryum “uzaya çıktık” değildir. Ziyaret aracı/kask/yaşam ortamı kararı, yeni proza ve buna özel görsel kimlik varyantları; Ayçörek çizimini Simit diye kullanma yok |
| Ülke/tarih | faraway/oldstone arkadaşları kullanılıyor | Ziyaretçi beşli + yerel konuğun bilgisi; eski kişinin yaşam öyküsünü beşliye kopyalama yok. Tarih olguları ve adlandırma ayrıca editoryal denetim ister |
| Meslekler | Ana companion aynı zamanda meslek sahibi insan | B'de çocuk+ana arkadaş uzmana gider; `expert` ayrı yuva. Eski person/occupation koşulu yeni expert yuvasına ait yeni blueprint/satırlarda tanımlanır; eskileri topluca yeniden yorumlama yok |
| Sporlar | sports companion ve köy çayırı | Simit gibi hareketli karaktere uygun oyun yazılır; mekanı, spor eylemini ve öğrenilen beceriyi gerçekten anlatmadan sports etiketi eklenmez |

Yeni konuk yuvası `Masal ailem` olarak taklit edilmez; aile ilişkisi ve kullanıcının özel karakteri başka şeydir. İlk konuk sürümü tek konukla sınırlı önerilir. Aynı kitapta beşlinin tamamını yazdırmak bu kararın şartı değildir; mevcut tek ana arkadaş yapısı korunur.

Konu kapısı: `CatalogStoryTopic.minimumMechanisms = 3` korunur. Kapsaması düşen konu için eşik indirilmez. 3–4'ün eski “bilerek konusuz” kararı ile son spor/öğrenme eklemeleri arasında tarihsel fark var; gerçek `availableTopics` sonucu ölçülmeden bütün bantlar konusuz veya bütün konular açık ilan edilmez. Tüzüğü genişletmek ayrı ürün kararıdır.

## 7. Eski kitaplar, aktif seriler, bellek ve sürümleme

### 7.1 Birbirinden ayrı sürümler

Önerilen `castPolicyVersion` ve `narrativeProfileVersion` adları yeni tasarım alanlarıdır; mevcut alanlar sanılmamalı. Saklama ayrımı:

| Katman | Bugün | Önerilen geçiş |
|---|---|---|
| Kanonik kimlik | ContentID | Değişmez; alias, redirect veya silme yok |
| Katalog | `catalog.version`, `StoryOrigin.catalogVersion`, `SeriesPlan.catalogVersion` | Eski tam katalog + korpus snapshot'ını sürüm/digest ile çöz; yeni yayının bağımsız içerik sürümü olsun |
| Ana kadro politikası | Ayrı alan yok | Yeni masalda açık politika sürümü; eksik eski kayıtta legacy davranış, yeni beşli varsayımı yok |
| Anlatı profili | Trait/rol/habitat kanonik kayıtta | Aynı ContentID için sürümlü profil; eski plan kendi profil/katalog sürümünü kullanır |
| Konuk rolü | Yok; meslek sahibi ana companion | Yeni şema/yetenek sürümü; eski companion alanını geriye dönük yeniden yorumlama yok |
| Kaynak izi | `ComposedPage.provenance` → `StoryPage.provenance` | Sıra, parça sayısı, digest, bağlam ve anlam kaybolmaz |
| Görsel | `StoryPage.art` + dosya/digest/revision/policy | Eski pinler ve eski dosya byte'ları korunur; yeni profil için yeni uyumluluk incelemesi |

Katalog numarası tek başına snapshot deposu değildir. Bugün `planSeries` ve `composeSeries` **güncel** `catalog()` çağırıyor; mevcut `catalogVersion` alanı otomatik eski sürüm seçimi yapmıyor. Bu boşluk kapanmadan katalog kaydını genişletmek seri devamını değiştirebilir.

`ContentPackage.currentSchemaVersion = 2`; konuk veya zorunlu profil anlamı eski app tarafından düşürülebiliyorsa paket yetenek şeması yükseltilmeli. Hem indirme hem loader şema eşitliği kapıları ve imzalı paket yayıncısı aynı değişimi almalı. Veriyle taşınan katalog paketi runtime metin/görsel API'si değildir; yeni kitap offline yazılır. Eski app yeni şemayı yorumlamaz, kendi desteklediği içeriğe devam eder.

### 7.2 Kayıt türüne göre davranış

- **Kayıtlı kitap:** metin, adlar, `origin`, sayfa sırası, provenance ve art yeniden yazılmaz. Kaynak izi olmayan sayfaya geriye dönük otomatik çizim yok. Kitap yeniden açıldığında yeni havuzdan seçim yapılmaz.
- **Aktif seri:** bölüm 2–5 başta yazılıp `SeriesEpisode.pages/origin` içinde saklanır. Gün açılınca yeniden compose edilmez; eski arkadaşıyla açılır. Beşlide olmayan eski arkadaş da devam eder.
- **Eski kitabı sonradan devam ettirme:** `SeriesAnchor` eski `companionID/settingID/keepsakeID` ile ve kitabın kaynak katalog sürümüyle çözülür. Yeni ana kadro filtresi uygulanmaz; ebeveynin o anda geçerli güvenlik tercihleriyle seri planlaması kuralı korunur. Gerekli kaynak sürümü bulunamazsa arkadaş değiştirilmez; açık uygunluk sonucu verilir.
- **Aile karakteri silinince:** mevcut davranış yalnız açılmamış bölümleri ailesiz yeniden yazar; açılandakiler değişmez. Yeniden yazım planın kaynak katalog/profil sürümüyle yapılmalı. Kaynak yoksa mevcut sakin kapanış davranışı kullanılır, beşliyle ikame edilmez. Art yalnız gerçekten yeniden yazılan bölümlerde yeniden değerlendirilir.
- **Hatırlama:** `StoryContextBuilder.recallHistory` bitmiş bağımsız masalları kimlikle sayar; seri bölümleri hariçtir. Beşlinin kimlikleri aynı kaldığından tanışıklık sürer. Pamuk→Kestane, Ayçörek→Simit veya Mavi→başka karakter aktarımı yapılmaz. Eski yer kayıtları hatırlama ve harita için kalır.
- **İstatistik/öğrenme:** okuma geçmişi silinmez; aynı kanonik karakterin tanışıklığı birleşik kalır, yeni profil ölçümü ayrı boyut olur. Eski konuğu yeni ana karaktere göre ağırlıklandırma yok. Çocuk adı/özel aile metni rapora yazılmaz.
- **Geri alma:** yeni politika yalnız yeni masallar için kapatılabilir; daha önce yazılmış yeni sürüm kitap/seri okunabilir kalır. Geri alma, yeni sürümün kaynaklarını veya pin dosyalarını silmek değildir.

`WholeBookArtPolicy.companionFingerprint` kişilik, açıklama, visualDescription, trait ve habitatı da içeriyor. “Yalnız açıklamayı düzeltmek” bile yeni kitapta eski Tarçın kuralını eşleştirmeyebilir. Aynı kanonik kimlik = aynı eski fingerprint değildir; her yeni profil için sanat onayı yeniden değerlendirilmeli, eski kitap pini aynen çözülmeli.

## 8. “Kim gelsin?” ve Masal ailem

Önerilen ekran: mevcut tek seçimli tam genişlik satırları korunur; geçerli beşli aynı ekranda dikey kaydırmayla erişilebilir olur. Her satırda kanonik kimliğe bağlı onaylı tanınabilir portre, isim ve kısa kişilik cümlesi bulunur. İlk üçe kalıcı kesme kaldırılır. Küçük yaşta beşlinin tümünün ilk viewport'a sıkıştırılması gerekmez; dokunma alanı ve tanınabilirlik korunur.

- `CompanionChoice` ekranın ihtiyacı kadar sunum kimliği taşır; görünüş dosyasının motor JSON'una eklenmesi gerekmez. App sanat kaydı ContentID→seçim portresi eşler. Seçim portresi, hikâye içi herhangi bir eyleme onay sayılmaz.
- `drawable` tür/simge çakışmasına göre beşliyi elemez. Yeni portreler geldiğinde kanonik kimlikle doğrulanan kartlar sunulur; dosya eksikliği yüzünden ana arkadaşı sessizce listeden çıkarmak yayın çözümü değildir. Beş seçim portresi yayın bağımlılığıdır.
- Ekran ve compose aynı kadro/profil sürümünü, yaş, mod, konu, özel gün, Masal ailem ve güvenlik bağlamını kullanır. Mevcut companionChoices arayüzünde occasion yok; özel gün çipi blueprint'i kilitliyorsa seçimle uyum ayrıca taşınmalı. Gerekli bağlam için yeni bir ortak uygunluk isteği önerilir, view içinde ikinci kural seti değil.
- Sunulabilen aday “en az bir tam temiz kitap kurulabilir” anlamına gelmeli. Çalışmayan kart, başka arkadaşa veya konuya dönüştürülmez. Aile/konu/özel gün/güvenlik değişince geçersiz seçim görünür biçimde temizlenir; yalnız familyID değişimini izlemek yetmez.
- `onChoose(nil)` ve “Bana sürpriz yap” da beşli politikasına gider. UI'da beş kart gösterip nil seçimde eski 29'lu havuzdan seçmek hatadır.
- İsim çakışması kuralı korunur: aile üyesi de Tarçın adındaysa aynı masalda ikinci Tarçın verilmez; aile adı değiştirilmez. Bu bağlamda beşten az kart kalabilir. Kullanıcıya “her koşulda beş seçenek” vaadi verilmez.
- `FamilyCast`, ilişki türleri, evcil hayvan sözlüğü ve aile güvenlik kapısı ana beşliye indirgenmez. Masal ailem çocuğun ayrı, özel kadrosudur. Aile fotoğrafı/adı görsel eşleme konusu yapılmaz.
- Güvenlik tercihleri, yaş bandı, nature/occupation ve konu filtreleri sert kalır. Kestane'nin çekingenliği fear etiketi gerektiren her satırı kullanma izni değildir. İçerik uygunluğu en korumacı ayarda ayrıca ölçülür.
- Arayüz kabulünde Türkçe VoiceOver etiketi (isim + tür/özellik + seçili durumu), ≥64 pt çocuk birincil hedefi, uygun satır dokunma alanı, Dynamic Type ve azaltılmış hareket kuralları uygulanır. Beşlinin dizilişi moda göre kimlik kaybettirecek biçimde sürekli karıştırılmaz.

## 9. Hikâye çeşitliliğini büyütmek

Çeşitlilik ölçüsü karakter sayısı veya isim çarpımı olmayacak. Mevcut `CatalogBlueprint.mechanismKey`, varyant `move`, conflict/state ve yaş/ark bütçeleri temel alınır.

1. **Olay örgüsü:** uyku için yalnız “dostu uyutmak” yerine sessiz sesi dinlemek, günü bir ayrıntıyla kapatmak gibi yeni bakım/ritüel şekilleri. A6 örnekleri tasarım önerisidir; bu tur yeni metin yazılmadı.
2. **Engel:** zaman/bekleme, eksik parça, iki önerinin birleşmesi gibi farklı engel yapıları; kişilik farkı yalnız aynı engeli başka cümleyle anlatmamalı. A5 düğümleri 7–10 kapsamıdır, 3–4'e taşınmaz.
3. **Çözüm:** bakış açısını değiştirmek, birlikte sıraya koymak, sormak, beklemek, denemek; çocuğun eylemi sonucu belirler. Böğürtlen geldi diye her çözüm taşıma olmaz.
4. **Diyalog:** Tarçın'ın alan açması, Kestane'nin küçük önerisi, Yıldız'ın az sözle gözlem sunması, Simit'in deneme sorusu, Böğürtlen'in destek istemesi farklı hareketlerdir. Birbirine çevrilebilir beş selamlama yeni mekanizma sayılmaz.
5. **Sonuç:** maddi onarım, yeni anlayış, duygusal rahatlama ve ilişki değişimi ayrı ölçülür. Sonucun erken ayrıntıya dayanması A5 tohum-hasat planıyla uyumlu olabilir; henüz mevcut özellik gibi sunulmaz.
6. **Görsel betim:** A3/A4 için mekân/nesne/eylem somutluğu, sayfa bütçesi içinde; görsel elde etmek için bütün metinleri nötrleştirmek veya aynı pozu sürekli kullandırmak yok.

A1 satır penceresi zaten **20**; yeniden yapılacak iş değildir. Soğuma içerik yaratmaz. `distinctSetups` ve `casts` yan ölçüdür: karakter kimliği çıkarılmış yapısal imza ayrıca raporlanır. Aynı olay örgüsü ve eylem dizisinin yalnız başka adla yazılması artış sayılmaz.

## 10. Görsel sözleşme ve ilk üretim sırası

### 10.1 Bağlama koşulları

`subject + subjectID + presence + states` ve **sıralı, eksiksiz tam sayfa kaynak izi** → uygulamanın onaylı sanat kuralı → `StoryPage.art` kalıcı kararı. Kaynakta dosya adı yok; runtime API, kelime araması, gizli yeniden seed, görünmez havuz daraltma yok. Aynı kitapta aynı asset'i tekrarlayıp kota doldurma yok.

`remembered` veya `intended` bir arkadaşın o anda sahnede olduğu anlamına gelmez. “Uyuyor” ile “dinleniyor”, “kaygılı” ile “meraklı”, “yardıma hazır” ile “ip çekiyor” farklıdır. `helping` geniş durumu tek başına bütün eylem görsellerine izin vermemeli; somut eylem için kaynak inceleme kanıtı gerekir. Kapalı durum sözlüğüne yeni fiil eklemek gerekirse motor/içerik sahibiyle şema kararı verilir; dosya adından otomatik durum türetilmez.

`WholeBookArtBinder` bugün altı 5–6 macera blueprint'ine, sekiz sayfalı ve ailesiz/özel günsüz/serisiz kitaplara kısıtlı. Dolayısıyla yeni karakter pozu eklemek uyku/3–4/7–10/aile/seri kapsamını kendiliğinden açmaz. Konuk eklenince tüm kaynak parçaları ve görünür varlıklar yeniden değerlendirilir; bütün kitabın tek bir arkadaş resmine indirgenmesi yok.

### 10.2 Önce var olan Tarçın çizimlerini doğru sınıflandır

Kimlik ve önceki üç poz ayrı; `whole-book-art-v3.json` içinde Tarçın'ın greeting/together/glad çizimleri için dar onaylı kurallar mevcut. Yeni sekiz dosyanın **tamamı** `GENERATION_RECORD.json` içinde `review-draft-not-runtime-approved`. Walking, curious, worried, farewell, trotting, resting, asleep, help-ready için kimlik, alfa/zemin ve semantik inceleme bitmeden runtime kaydı açılmaz.

Bazı generation kayıtlarında prompt `undefined...` ile başlıyor. Bu geçmiş üretim kaydıdır; otomatik reddetme veya kabul nedeni değildir fakat yeniden üretim için tam referanslı istem geri kurulmalı. Dosya varlığı ve alfa min/max, zemin temizliği veya görsel kalite doğrulaması değildir. Bu tur PNG'lerin yeni görsel onayını yapmadım.

### 10.3 Kaynak temelli ilk görsel iş listesi

Aşağıdaki satırlar gerçek yazılmış kaynaklardır; yeni örnek masal değildir. **P0:** seçim tanınabilirliği; **P1:** mevcut kaynakla açık eylem/duygu eşleşmesi; **P2:** yeni içerik/profil veya dünya kararı sonrasında. Her satır bir ihtiyaç sınıfıdır; “5×N çizim” hesabı ve her sınıf için üretim adedi verilmez. Kaynakların dosya/JSON pointer/kimlik/metin/visual bilgileri kanıt JSON'unda da saklıdır.

| Öncelik | Karakter | Poz/duygu/somut eylem | Gerçek kaynak | Sınır / sonraki adım |
|---|---|---|---|---|
| P0 | Beşinin her biri | İsimle eşleşen tanınabilir seçim portresi | `characters.json`; `CompanionStep.candidates`, `shown=3`; `StoryChoiceSource.drawable` | Onaylı takım kimliğinden türetilen tekil portreler; takım HTML'inden otomatik kesip onaylı runtime görsel sayma yok |
| P1 | Tarçın | Açık gözlü, sakin karşılama ve yerde duran rehber | `templates/v3/beat_meet_companion.json:15` `mc_guide_01`; aynı dosya `mc_guide_02`; `mc_calm_01` | Mevcut greeting/together kurallarını yeniden çizmek yerine kapsam kanıtını incele; “buralıyım/her gün geçerim” ziyaret dünyasına uymaz |
| P1 | Kestane | Hafif tereddüt, kıpırdamadan bekleme, başını kaldırma | `templates/v3/beat_meet_companion.json:175` `mc_care_03` | `needsCare` bağlamı; titremeyi büyük korkuya çevirmeme. Auto greeting etiketi gerçek eylemi tam anlatmıyor |
| P1 | Yıldız | Kanatla süzülüp yere konma; dikkatli, açık gözlü bakış | `templates/v3/beat_meet_companion.json:57` `mc_guide_03`, `canFly` | Yalnız Yıldız'ın uçuşuna uygun; diğer dört karaktere aynı satır/çizim atanmaz. Tam sayfa bağlamı ayrıca incelenir |
| P1 | Simit | Yol üzerinde durup çocuğa/ileriye bakma; merak | `templates/v3/beat_meet_companion.json` `mc_guide_02`; `beat_companion_offers.json` `co_p_07` | Tür ve kıvrık kuyruk kimliği korunur; “şuraya bak” mutlaka insan eliyle işaret etmek değildir |
| P1 | Böğürtlen | Sakin birlikte durma, destekleyici bakış | `templates/v3/beat_meet_companion.json` `mc_calm_01`; `beat_restore.json:13` `rs_coop_01` | `rs_coop_01` iş birliği/başarma bildirir; taşıma/çekme yöntemini söylemez. Güç pozu için tek başına kanıt değildir |
| P1 | Kestane, Yıldız | Uyanık, yorgun; esneme ve gözleri açık dinlenme | `templates/bedtime/beat_bedtime_meet_companion.json:32` `bt_mc_02` | Şu anki N rolü için kaynak adayı; uyuyan poz kullanılamaz; binder'ın uyku kapsamı ayrıca açılmalı |
| P1 | Kestane, Yıldız | Gerçekten uyuma; türe uygun kapanış | `templates/bedtime/beat_bedtime_restore.json:91` `bt_rs_p_one_more_yawn`; `:105` `bt_rs_p_curls_up` | Kirpi kıvrılabilir; baykuşu tilki gibi kıvırma yok. Kaynakta uygun anatomi ayrımı yeni metin gerektirebilir; yanlış pozu genelleme |
| P2 | Tarçın, Simit, Böğürtlen | Uyanık dinlenme / uykuya geçiş / uyuma ayrı | Aynı `bt_mc_02`, `bt_rs_p_curls_up` + `beat_bedtime_let_go.json:55` `bt_lg_blanket_corner` | Bugün N rolüne kapalılar; bu kaynaklar doğrudan kullanım yetkisi değil içerik açığı kanıtı. Yeni profile uygun kaynak yayımlandıktan sonra çizim listesi kesinleşir; Tarçın'ın resting/asleep taslakları inceleme adayı |
| P2 | Simit, gerektiğinde Tarçın | Hafif oyun koşusu; davete dönme | `templates/v3/beat_receive_appeal.json:172` `s56_ra_03` | Spor konu/village boşluğu önce kapanmalı; mevcut Tarçın trotting dosyası bu satır için onay değildir |
| P2 | Uygun ana arkadaş | Önden yürüyüp dönerek kontrol etme | `templates/series/beat_series_first_attempt.json:13` `sfa_01` | Taşıyan çocuk, yol gösteren arkadaş. Arkadaşın taşıma çizimi bu cümleyi karşılamaz. Seri kaynak izli sanat kapsamı ayrı iş |
| P2 | Uygun ana arkadaş | Verileni alma / küçük nesneyle etkileşim | `templates/v3/beat_restore.json` `rs_give_01` | Nesne, boyut, anatomik tutuş ve sayfadaki tüm kaynaklar belirlenmeden genel “alma” çizimi üretme |

**Öncelikli olmayanlar:** Tarçın farewell için bu incelemede açık bir ayrılma kaynak satırı doğrulanmadı; üretim önceliği verilmiyor. İp çekme, ağır nesne taşıma, yüzme, uzay ekipmanı için de tabloda doğrudan uyumlu kanıt yok. Bir çizim kaynağa dayanmalı; yeni içerik bu eylemleri gerçekten yazarsa yeniden sıralanır. `rs_coop_01` veya “yardım etti” sözü bu boşluğu kapatmaz.

`bt_wc_01/02/03` kapanışlarında arkadaş adı geçmeden nefes/uyuyan dost anılıyor. Sadece setting gösteren auto listesi eksiksiz sayılmaz; bu satırlarda zamirli/adsız özne incelemesi yapılmadan arkadaş art'ı atanmaz.

## 11. Önce/sonra ölçümü ve başarısız örnekler

### 11.1 Bugün eldeki ölçümün sınırı

Bu tur yeni runtime deneyi koşulmadı. `design-handoff/proposals/2026-11-21-whole-book-art/baseline.json`, `after.json`, `VALIDATION.md` önceki gerçek Swift composer→mapper pilotunun kanıtlarıdır: **altı 5–6 macera blueprint'i × 100 seed**, beşliyle sınırlı değil.

| Metrik | Önceki politika | Politika 3 sonucu |
|---|---:|---:|
| Temiz başarılı masal | 600 | 600 |
| Toplam sayfa | 4.800 | 4.800 |
| En az bir pinli kitap | 221 (%36,8) | 244 (%40,7) |
| Hiç pin olmayan kitap | 379 (%63,2) | 356 (%59,3) |
| Pinli sayfa | 221 (%4,60) | 251 (%5,23) |
| Orta / son pinleri | 0 / 0 | 9 / 2 |

Bunlar beşli geçişinin önce/sonrası değildir. Aynı 600 örnekteki iyileşme yalnız mevcut sanat politikasına aittir. `presentEvidencePages = 2.158` aday anlam sayısı; “2.158 sayfa çizilebilir” sertifikası değildir.

Gerçek çizimsiz örnek: `after.json`, seed **whole-book-art-v1-016**, `bp_threshold_joining_002`, Tarçın, `setting_festival_meadow_001`, `object_flickering_light_001`; temiz sekiz sayfa ve **0 pin**. Sayfa 3 kaynakları `mc_calm_01 → co_p_07`, sayfa 8 `wc_p_succeed_04 → cf_p_02`. Rapordaki neden `mapper_produced_no_pin; policy_rejection_reason_not_exposed`; etiketsiz kaynaklar da var. Kesin binder red sebebi kayıtlı değilken “çizim yoktu” diye tek neden uydurulmaz. Tarçın seçmek bu örneği görselli yapmıyor.

Diğer başarısız/uygunsuz örnekler:

- Tarçın + herhangi bir yaş + bedtime: mevcut cast rolü N değil; statik boşluk. Yeni rastgele seed çözmez.
- Böğürtlen + Denizin altı: habitat/yüzme ve konu sözü uyuşmuyor; yunus yerine ayı ikamesi yapılamaz.
- Simit + `bp_jobs_craftspatience_002`: blueprint insan/meslek sahibi gerektiriyor; yalnız etiket değişimi çözmez.
- Yıldız'ın `mc_guide_03` inişi için Tarçın curious pozu: kanatlı eylemle anatomi çelişir.
- `bt_mc_02` uyanık/esneyen arkadaş için asleep pozu: kimlik doğru olsa da anlatı durumu yanlış.
- Daha önceki kayıtlarda 9–10 learning seri uygunluğu testi başarısızlığı var (`testAModeNoContinuationServesMayNot`); son sanat seçili koşuları bunun çözüldüğünü kanıtlamıyor. Yayın ölçümünde ayrı baseline kusuru olarak yeniden doğrulanmalı.

### 11.2 Geçiş uygulamasında kurulacak karşılaştırma

**Üç kol:** L = dondurulmuş legacy katalog; F = yalnız beşli filtresinin kayıplarını gösteren teşhis kolu (yayınlanmaz); N = yeni sürümlü profil + yeni içerik. Aynı tohum manifesti, yaş/mod/konu/family/safety/occasion girdileri; her deneme kaydı tutulur. Başarısızlıkları paydadan çıkarma yok. L ve N'nin aynı metni vermesi beklenmez; saklanmış legacy kitapların değişmemesi beklenir.

İki ayrı çalışma:

1. **Yapısal erişilebilirlik:** tüm 4 yaş × 3 mod × 5 arkadaş × sunulan konular × family ilişki durumları × güvenlik profilleri × özel gün kesitleri. Blueprint başına ortak setting/discovery bağlaması ve her beat/rol/uzunluk/state havuzu denetlenir. “Konu katalogda var” ile “bu arkadaşa sunulabiliyor” ayrı sütunlar.
2. **Okuma dizisi:** A0 düzeniyle 3 sentetik çocuk × 100 masal × dört bant; dönüşümlü modlar ve açıkça belirtilmiş %60 uyku dağılımı. İkincisi analitik gerçek kabul edilmez. Sabit seed'in **ilk denemesi** ana ölçüm; mevcut raporun 3 temiz taslak denemesi ayrı sütunda. Hiçbir yeniden deneme sanat elde etmek için kullanılmaz.

Mevcut `ReadingSequenceReport` temiz taslak ararken üç seed deniyor, `fingerprint` ile exactDuplicates sayıyor, distinctSetups içine karakteri katıyor. Bu ölçüm tek başına yeni kadronun gerçek çeşitliliğini doğrulamaz. Yeni rapor bunları tarihsel seri olarak korur ve ek ölçüler verir:

| Ölçü | Tanım / kabul yaklaşımı |
|---|---|
| Yapısal çeşitlilik | mekanizma + çatışma/engel + çözüm + varsa onaylı düğüm/tohum/sonuç; karakter/isim/mekân dekoru çıkarılmış |
| Diyalog çeşitliliği | `move` dizileri; beş farklı ismin aynı cümlesi tek hareket |
| Gerçek metin tekrarı | Render edilmiş tam metin SHA + ayrıca karakter/çocuk adları normalize edilmiş yapısal metin özeti; fingerprint/seed tek başına yeterli değil |
| Tekrarın gelişi | İlk mekanizma tekrarı; yarısı tanıdık ilk kitap; 4–10, 11–25, 26–50, 51–100 satır tekrar oranı; nakaratlı/nakaratsız ayrı |
| Uygunluk | Sunulan kartta temiz tam masal kurulması; başarısız/pinned-israrlı girdiler ve nedenleri, tüm denemeler paydada |
| Kişilik | Her rol/yaş/mod kesitinden tam kitap editoryal örneği; çözümü çocuk mu yapıyor, aynı arkadaşın sesi tutarlı mı? |
| Görsel | Pinli kitap/tüm istek, pinli sayfa/tüm beklenen sayfa, hiç pin yok, açılış/orta/son, eşsiz çizim, tekrar ve çelişki sayısı |
| Görsel red nedenleri | incomplete provenance / remembered-only / intended-only / meaning unreviewed / no approved asset / no exact full-page rule / policy out of scope / asset digest failure; mevcut belirsiz redler ayrı kalır |
| Uyumluluk | Eski kitap metin/provenance/art ve pin byte'larında 0 fark; aktif seri unlock'ta 0 yeniden seçim; eski kimliklerde 0 yönlendirme |

Yeni rapor **hem politika kapsamını hem bütün eski ürün vaatlerini** paydada tutar. Kapanan bir konu tabloda “yayın kapsamı dışında — açık ürün kararı” olarak görünür; yok sayılmaz. Aynı seed dağılımı karakterlerin sayısı değişince farklı örnekler verdiği için salt örneklenen arkadaş/mekân sayısına regresyon eşiği konmaz; yapısal erişilebilirlik ayrıca ölçülür.

ANLATI A8'in uzun vadeli hedefleri (ilk tekrar ≥20, yarısı tanıdık ≥30, 51–100 ≤%60) korunabilir; geçiş bitmiş gibi gerçekleşti denmez. A1 sonrası test tabanı ve legacy L yeniden ölçülür. İlk geçiş kabulü: onaylı konu kesitlerinde sıfır yeni uygunluk boşluğu, sıfır kişilik/anatomi/görsel çelişki, legacy eşitlikleri, mekanizma kaybının açıklanması ve onaylanması. Kesin çizim kotası/“her masal görselli” vaadi ancak bütün hedef kesitlerde ölçüm kanıtıyla verilebilir.

## 12. Dosya ve sorumluluk sınırları

Bu tablo gelecekteki uygulama sahipliğidir; bu tur bu dosyalar değiştirilmedi. Önce mevcut aktif sahip teyit edilir; ortak dosyalara tek yazar atanır. Önceki hafızadaki Claude/motor ve ChatGPT/sanat ayrımı korunur; tablo yeni paralel çalışma başlatmaz.

| Sahip | Mevcut temas noktaları | Sorumluluk / sınır |
|---|---|---|
| Motor | `StoryEngine/.../Content/CatalogRecords.swift`, `ContentTraits.swift`, `CatalogBlueprint.swift`, `CatalogTemplate.swift`; `Offline/OfflineSelection.swift`, `BlueprintSelector.swift`, `OfflineStoryComposer.swift`, `Series/SeriesPlan.swift`, `PageProvenance.swift` | Sürümlü anlatı profili, kadro politikası girdisi, sert uygunluk, konuk modeli ve kaynak izi; görsel dosya seçmez |
| İçerik | `Resources/blueprints/pilot_library_v1.json`, `templates/offline/v2/shared_content_library_v2.json`, `templates/v3/beat_*.json`, `templates/bedtime/`, `templates/series/`, yaş korpusları ve recall/occasion kaynakları | Yeni sürümde yeni blueprint/satır kimlikleri, kişilik sesi, dünya bağlamı, görsel anlam incelemesi; eski metin/kimlik yerinde değiştirilmez |
| İçerik dağıtımı/uyumluluk | `Content/ContentCatalogLoader.swift`, `ContentPackage.swift`; `MagicPaper/StoryEngineBridge/RemoteContent/CatalogSourceResolver.swift`, `RemoteContentStore.swift` | Kaynak sürümü/digest çözümü, eski snapshot saklama, yetenek şeması ve yayıncı uyumu; tek “güncel katalog” varsayımını giderme |
| Oluşturma köprüsü | `OfflineStoryService.swift`, `StoryChoiceSource.swift`, `StoryContextBuilder.swift` | UI/compose/sürpriz için aynı bağlam ve yeni ana kadro politikası; tarihsel devamı ayrı çözümleme |
| Oluşturma ekranı | `Screens/StoryCreation/CompanionStep.swift` ve onu çağıran akış | Üçlü kesmeyi kaldırma, beş tanınabilir satır, bağlam değişiminde seçim geçerliliği; trait/habitat kurallarını view'a yazmama |
| Model/mapper — tek ortak sahip | `MagicPaper/Models/Story.swift`, `StoryEngineBridge/OfflineStoryMapper.swift`, `StorySeries.swift`, `SeriesManager.swift` | Yeni optional sürüm alanları, eski decode/encode ve provenance/art korunması; kaynak izi mevcut motor sahibiyle birlikte sözleşmeli |
| Sanat/bağlayıcı | `StorySpotCatalog.swift`, `StorySpotBinder.swift`, `ReviewedDiscoveryArtPolicy/Binder.swift`, `WholeBookArtPolicy/Binder.swift`, `StoryArtResources/*.json/.mpart`, `Tools/story_art_coverage_audit.py` | Seçim portresi kaydı, yeni kaynaklara exact onay, asset/revision/digest; metin/seed/havuz seçimini değiştirmeme |
| Görsel üretim | Onaylı beşli proposal'ı ve Tarçın poz kütüphanesi | Kimlik/poz/zemin incelemesi; çizim varlığıyla runtime onayını ayırma |
| Originals / marka | `Screens/Gunluk/Model/OriginalTales.swift`, `Content/Originals/`, `Scripts/ContentPublisher/Sources/PublisherKit/Originals.swift`, Ragi tasarım sistemi | Kitap bazında Ragi konukluğu ve yayın kimliği; offline ana havuz listesine bağlamama |

Yeni profil/politika/snapshot bileşenleri küçük ayrı dosyalarda tutulmalı; adlar uygulama tasarımında kesinleştirilir. Yukarıdaki `...` motor paketinin `Sources/StoryEngine/` kökünü ifade eder; içerik yaş dosyalarının kesin listesi kanıt JSON'undaki SHA envanteridir. Büyük ortak dosyaları topluca yeniden düzenleme bu plana dahil değildir.

## 13. Aşamalı uygulama ve bağımlılıklar

Bu bir mimari/içerik geçiş planıdır; onaylanmamış yeni şemalar için bu tur uygulama kodu üretilmez. Ayrıntılı kod görevleri yaklaşım ve ürün kararları sonrasında yazılacak. Repo kuralı uyarınca test/simülatör planın son doğrulama kapısında bir kez toplu çalıştırılır; ara adımlar kod/kaynak incelemesiyle ilerler.

### K0 — Yaklaşım ve yayın kapsamını sabitle

- [ ] B veya diğer yaklaşım kararı; konuk/uzman hakkı, dünya ziyaret kuralları, kapsam dışı kalacak hücreler yazılı olsun.
- [ ] Kullanıcının beşli/tanışma görseli onayı ile dosyalardaki eski status metninin farkını karar kaydında düzelt (bu tur üretim proposal'ına dokunulmadı).
- [ ] L/F/N kıyas seed ve girdi manifestini, mevcut bilinen hataları ve kaynak SHA'larını dondur.
- **Çıkış:** yeni içerik yazımı için açık kapsam ve değişmez legacy referansı.

### K1 — Legacy kaynak çözümü ve sürüm sözleşmesi

- [ ] Eski katalog+beat snapshot'larını sürüm/digest ile erişilir kıl; aynı 2.1.0 etiketini taşıyan farklı byte kümelerini digest ile ayır.
- [ ] Yeni optional politika/profil alanlarını ve gerekiyorsa konuk şemasını tasarla; eski eksik alanı legacy say.
- [ ] Eski kitaptan yeni seri planlama, aile silinmesi ve geri alma yollarını kaynak sürümüne bağla.
- **Bağımlılık:** K0; **çıkış:** eski metin/kimlik/pinleri yeniden yorumlamayan geçiş temeli. Yeni kadro henüz yayınlanmaz.

### K2 — Beşlinin anlatı profilleri ve yeni içerik

- [ ] Önce uyku üç karakter boşluğu, sonra meslek/uzman modeli, sonra şehir/orman ziyaretleri; deniz/uzay kararı bunlardan ayrı.
- [ ] Yeni blueprint, proza ve gerekiyorsa yeni template kimlikleriyle içerik sürümü yayımla; eski satırları yerinde düzenleme. Corpus'un beat bazında replacement davranışını yeni/legacy katmanlarda açıkça ayır; farklı isimli JSON eklemek tek başına izolasyon sağlamaz.
- [ ] Her hedef hücrede rol/duygu/anatomi, child agency, aile/özel gün ve konu anlamını elle incele; beşlinin kişilik sesini doğrula.
- [ ] Visual anlamı bütün parçalar için tamamla; auto etiketleri topluca reviewed yapma. Yeni eylem durumları gerekirse kapalı sözlük kararı ver.
- **Bağımlılık:** K1 + dünya/konuk kararları; **çıkış:** hedef matrisi karşılayan içerik ve yayımlanabilirlik envanteri.

### K3 — Ana arkadaş politikası ve seçim akışı

- [ ] Yeni bağımsız masal, nil arkadaş ve sürpriz aynı beşli politikasıyla çözülür; legacy devam yolu ayrıdır.
- [ ] Kimlik tabanlı beş seçim portresini bağla; simge tekilleştirmesi ve `.prefix(3)` yeni politikada kaldırılır.
- [ ] Konu/family/safety/occasion bağlamı değişince bütün uygunluk yeniden değerlendirilir; çalışmayan seçim başka arkadaşa dönüştürülmez.
- **Bağımlılık:** K2 + P0 portreler; **çıkış:** görülen kartın verdiği sözü tutan akış.

### K4 — Kaynak temelli sanat kapsamı

- [ ] P1 kaynaklarını tam sayfa halinde incele; uygun hazır Tarçın asset'lerini yeniden kullan, yeni taslakları ayrı onayla.
- [ ] K2 yeni kaynaklarından P2 listesini yeniden çıkar; karakter/eylem listesi ancak bu kaynaklarla genişlesin.
- [ ] Art bağlayıcı kapsamını yaş/ark/aile/seri bağlamı bazında ayrı onayla. Mevcut hardcoded sürüm/SHA kapılarını kontrollü yeni politika sürümüyle genişlet; eski pin doğrulamasını gevşetme.
- **Bağımlılık:** K2; seçim portresi hazırlığı K2 metinlerinden bağımsız olabilir; **çıkış:** desteklenen kaynak→art kanıtı ve açık kapsam dışı listesi.

### K5 — Tek toplu doğrulama ve ürün incelemesi

- [ ] Legacy snapshot kitap/seri decode→encode, açılma, aile silinmesi, eski kitaptan devam, beşli dışında eski arkadaş ve recall kabul senaryoları.
- [ ] Motor: `BoundPoolTests`, `ModeBandCoverageTests`, `MatrixCoverageTests`, `ContentSafetyTests`, `SeriesPlannerTests`, `RecallLineTests`, `StorySpotProvenanceTests`, `ReadingSequenceTests` ve ilgili determinism/profil/konuk yeni testleri.
- [ ] Uygulama: `CompanionSymbolTests` yeni portre sözleşmesi, `OfflineStoryMappingTests`, `SeriesTests`, `StoryMemoryTests`, `StorySpotBindingTests`, `WholeBookArtCoverageTests`, asset resolver testleri. Eski simge testini sadece silme; yeni kimlik/portre/erişim iddiasını sınasın.
- [ ] L/F/N yapısal ve okuma ölçümleri + gerçek composer→mapper sanat raporu; ilk deneme ve bütün başarısız girdiler dahil. “0 pin” örnekler saklanır.
- [ ] Swift paketi için `swift test --package-path StoryEngine`; uygulama testleri mevcut proje scheme/destination'ı doğrulanarak aynı son kontrol oturumunda. Hata varsa eski taban/yeni regresyon ayrımı rapora yazılır; kırmızı koşu başarılı ilan edilmez.
- [ ] Değişen seçim ekranında açık/koyu, en büyük Dynamic Type, SE/Pro Max ve VoiceOver kontrolü; tam kitap örneklerinde sanat/metin uyumu. Gerçek çocuk verisiyle otomatik rapor yok.
- **Bağımlılık:** K1–K4; **çıkış:** yayın kapsamı, ölçüm farkları, kalan eksikler ve ürün kabulü. Tamamlanan işler DEMO_CHANGELOG'a ayrı kayıtlarla yazılır.

### K6 — Sürümlü yayın

- [ ] İçerik/yetenek şeması ve sanat kaynaklarıyla uyumlu app sürümü birlikte hazırlanır; eski app paket kabul sınırı korunur.
- [ ] Kadro değişimi görünür ürün geçişi olarak anlatılır; hangi dünya/konu kapsamının hazır olduğu açık olur.
- [ ] Yeni kayıtların sürüm alanları saklanır, legacy kaynak ve asset'ler korunur. Geri alma yalnız gelecekteki yeni seçim politikasını değiştirir.
- **Çıkış:** onaylı yayın. Bu plan yayın/push/deploy yapmadı.

## 14. Uygulama öncesi karar listesi

1. **Önerim:** beşli tek ana arkadaş havuzu; uzman/deniz canlısı gibi karakterler ayrı konuk olabilir. Bunu ürün kuralı yapalım mı? Konuk istemezsek Meslekler ve sualtı için C'nin yeniden tasarım/kapsam kararları gerekir.
2. **Önerim:** diğer dünyalara ziyaret, otomatik habitat genişletmesiyle değil yazılmış bağlamla olur. Uzay/sualtı yolculuğu için araç ve görsel varyant dili ayrıca kararlaştırılsın; kuş uçuşu uzay yeteneği sayılmasın.
3. **Önerim:** beşlinin hepsi üç modda repertuvar kazanır; hepsini tüm mevcut blueprint'lere açmayız. Uyku için R ve karaktere uygun N içerikleri ayrı yazılır.
4. **Önerim:** aynı ekranda kaydırılabilir beş tanınabilir satır; tek seçim korunur. Aile/güvenlik/konu nedeniyle elenen varsa nedeni uygunluk kaydında görünür; gizli ilk üç kesmesi kalkar.
5. **Önerim:** önce mevcut konu vaatlerini koruyan içerik tamamlanır, sonra kadro politikası yayınlanır. Daha erken dar yayın istenirse kaybolan her hücre açık ürün kapsamı kararı olarak onaylanır.

Beşli, isimler ve tanışma görseli yeniden onaya sunulmuyor. Bu kararlar onların motor, içerik ve yayın davranışına nasıl taşınacağı içindir.

## 15. Kaynaklar ve doğrulama dürüstlüğü

- Repo talimatları: `AGENTS.md`; hafıza: `docs/PROJE_HAFIZASI.md` içindeki faz21-varyasyon, uyku-arki ve semantik-gorsel-havuzu bölümleri.
- Anlatı hedefi ve güncel A1/A2 durumu: `docs/ANLATI_PLANI.md`; bağlayıcı sözleşmesi: `docs/GORSEL_ANLAM_SOZLESMESI.md`. Sözleşmeyle kaldırılmış picture/vk tasarımları öneriye geri alınmadı.
- Karakter kimlikleri ve sınırlar: `design-handoff/proposals/2026-11-22-magicpaper-characters/characters.json` ve tanışma HTML'i; runtime olmayan Tarçın taslakları: `2026-11-22-tarcin-pose-library/README.txt`, `GENERATION_RECORD.json`.
- Gerçek sanat pilotu: `design-handoff/proposals/2026-11-21-whole-book-art/{baseline,after}.json`, `VALIDATION.md`.
- Güncel kaynak hash'leri, 34 arkadaş envanteri, 60 statik hücre, dokuz doğrudan boş blueprint ve çizim kaynak satırları: `docs/research/2026-11-22-five-friends-evidence.json`.

Statik aday hesabı gerçek Swift uygunluk algoritmasının yerine önerilmedi; sadece bu incelemenin açıkça sınırlı teşhisidir. Bu tur test çalıştırılmadı ve yeni planın kapsama/kalite artışı ölçülmüş gibi sunulmadı. Son kontrol belge referanslarının, kaynak kimliklerinin, envanter hash'lerinin ve değişiklik kapsamının doğrulanmasıdır.

## Ek A. Bütün mevcut arkadaşların yaş/mod adaylığı

Bu tablo da §5.1 ile aynı statik üst sınırdır; konu, aile, güvenlik ve proza denetimi yapılmadan ekranda sunulabilirlik değildir. Ö = öğrenme, M = macera, U = uyku. Trait’siz kayıtlar boş görünür; bu durum eski kitapta bulunamayacakları anlamına gelmez. İsim tekrarlarını kimlik ayırır.

| Karakter / kanonik kimlik | 3–4 | 5–6 | 7–8 | 9–10 |
|---|---|---|---|---|
| Kıpır · `companion_fox_001` | — | — | — | — |
| Yonca · `companion_rabbit_001` | — | — | — | — |
| Bilge · `companion_owl_001` | — | — | — | — |
| Dikenli · `companion_hedgehog_001` | — | — | — | — |
| Kıvılcım · `companion_dragon_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Fındık · `companion_squirrel_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Böğürtlen · `companion_bear_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Pofuduk · `companion_penguin_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Yavaş · `companion_turtle_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Mavi · `companion_dolphin_001` | — | — | — | — |
| Pırıltı · `companion_firefly_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Zip · `companion_robot_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Zıpzıp · `companion_frog_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Pati · `companion_cat_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Cesur · `companion_dog_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Cıvıl · `companion_sparrow_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Tarçın · `companion_fox_pilot_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Kestane · `companion_hedgehog_pilot_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Yıldız · `companion_owl_pilot_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Köpük · `companion_dolphin_pilot_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Pamuk · `companion_rabbit_pilot_001` | Ö/M/U | Ö/M/U | Ö/M/U | Ö/M/U |
| Fırıncı Nazlı · `companion_baker_001` | — | Ö | Ö | Ö |
| Postacı Remzi · `companion_postman_001` | — | Ö | Ö | Ö |
| Öğretmen Suna · `companion_teacher_001` | — | Ö | Ö | Ö |
| Vida · `companion_robot_sky_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Ayçörek · `companion_space_cat_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Beden Öğretmeni Defne · `companion_coach_001` | — | Ö | Ö | Ö |
| Zıpzıp · `companion_goat_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Simit · `companion_city_cat_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Pıtpıt · `companion_city_dog_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Lolo · `companion_llama_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Fındık · `companion_marmot_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Taşbaş · `companion_tortoise_001` | Ö/M | Ö/M | Ö/M | Ö/M |
| Gugu · `companion_dove_001` | Ö/M | Ö/M | Ö/M | Ö/M |
