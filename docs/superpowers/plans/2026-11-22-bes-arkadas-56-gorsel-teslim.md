# Beş arkadaş 5–6 pilotu: görsel ekibe kaynak ve eylem teslimi

**Tarih:** 22 Kasım 2026 · **Durum:** üretim hazırlık brifi; yeni görsel üretilmedi, yeni runtime eşleme onayı verilmedi.

**Ana belgeler:** [K0–K1 planı](2026-11-22-bes-arkadas-k0-k1-uygulama-plani.md), [pilot içerik kapsamı](2026-11-22-bes-arkadas-56-pilot-kapsami.md).

**Makinece okunur kanıt:** [kaynak paketi](../../research/2026-11-22-bes-arkadas-56-gorsel-kaynaklar.json).

## 1. Teslimin doğru okunması

Paket iki şeyi ayrı taşır:

1. **Bugün var olan gerçek kaynaklar:** önceki composer→mapper `after.json` çıktısından her ana arkadaş için bir tam kitap, toplam **40 tam sayfa**. Metin, sayfa rolü, beat'ler, sıralı tüm provenance parçaları, mevcut art ve eşleme yokluğu sebepleri aynen alınmıştır. Bunlar sentetik “Deniz” isimli legacy fixture'lardır; gerçek aile verisi değil. Bir yeni seed deneyi yapılmadı.
2. **Yeni pilotun 15 hücresi:** plan etiketleri ve ihtiyaçlar vardır; yeni pilot kaynak satırları henüz yazılmadığı için `authoredPilotSourceIDs` boş ve runtime onayı false'tur. Bu bir eksikliği saklama biçimi değil, yeni metin varmış gibi kaynak kimliği uydurmama kuralıdır. Yeni metinler geldikten sonra tam sayfa kanıtıyla ayrı teslim yapılır.

Beş gerçek kitap seçimi yalnız açıklayıcı örnektir; görsel kapsama oranı bu seçilmiş kitaplardan hesaplanmaz. Tarçın/Kestane/Böğürtlen örnekleri gerçek ormanda, Yıldız örneği çayırda, Simit örneği şehirde geçer. Son ikisi orman pilotuna uygunluk kanıtı değildir.

Kaynak paketindeki **53 authored kayıt** dosya+JSON pointer+dosya SHA+yaş/arc+ham satır bilgisi taşır. Beş tam kitabın **50 provenance parçasının** `sourceID` ve `sourceTextDigest` değerleri güncel authored kaynaklarla doğrulandı: missing 0, digest mismatch 0. Bu mekanik eşitlik, metnin editoryal kabulü veya resmin uyumluluk onayı değildir.

## 2. Kanonik kimlikler

| Ad | Kanonik kimlik | Çizimde korunacak özellik / kişilik |
|---|---|---|
| Tarçın | `companion_fox_pilot_001` | Onaylı tilki kimliği; sakin, güven veren, acele ettirmeyen |
| Kestane | `companion_hedgehog_pilot_001` | Aynı kirpi; anlayışlı, küçük adımlarla cesaretlenen; her sayfada korkmuş değil |
| Yıldız | `companion_owl_pilot_001` | Aynı baykuş; sabırlı, dikkatli gözlem, az söz; uçuş yalnız kaynakta gerçekten varsa |
| Simit | `companion_city_cat_001` | Kıvrık simit kuyruğu; meraklı/hareketli; ormanda yeni ziyaret bağlamı gerekir |
| Böğürtlen | `companion_bear_001` | Aynı sakin/güçlü ayı; beden ölçeği korunur; fiziksel güç her sayfada eylem değildir |

Kullanıcı kadroyu ve tanışma görselini onayladı. Bu onay tekil seçim portresini veya her yeni pozu kendiliğinden runtime uyumlu yapmaz. Eski Kıpır/Bilge/Dikenli/Pati/Ayçörek kimlikleri bu beşlinin çizimlerine redirect edilmez.

## 3. Gerçek tam sayfa örnekleri ve somut ihtiyaçlar

Bütün sayfa metinleri ve kitabın önceki/sonraki sayfaları JSON'da `books[].attempt.pages` altındadır. Aşağıdaki p3 kaynak dizileri **tam sayfanın bütün kaynaklarıdır**; aradan tek bir fiil seçilip diğer parça atlanmaz.

| Karakter / kitap | Tam sayfa kaynak sırası ve bağlam | Somut görünüş/eylem ihtiyacı | Çizilmemesi gereken |
|---|---|---|---|
| Tarçın — `whole-book-art-v1-069`, `bp_threshold_together_003`, `setting_whispering_forest_001` | p3: `mc_calm_03 → co_p_01`; Tarçın çocuğun yanına geçer, ileriye bakar, sonra yolu bildiğini söyler | Uyanık, sakin, çocuğa eşlik ederken ileri bakan yerde duruş; bakış odağı sayfa bağlamına göre | Kaynakta koşma/çekme/taşıma yok. Hiç konuşmama cümlesinden diyaloğa geçiş editoryal incelenmeli; tek parça kaynakla sahne onayı yok |
| Kestane — `whole-book-art-v1-018`, `blueprint_threshold_crossing_001`, aynı orman | p3: `mc_calm_02`; sakin biçimde yanına gelir, acele olmadığını söyler, yanına ilişir | Yumuşak, açık gözlü sakin eşlik; bedeni düşük/rahat, fiziksel korku belirtisi zorunlu değil | Kestane'nin kişiliği çekingen diye kaynakta olmayan ağlama/titreme/kaçma ekleme yok |
| Yıldız — `whole-book-art-v1-009`, `bp_threshold_joining_002`, `setting_festival_meadow_001` | p3: `mc_calm_03 → co_p_12`; yanında ileriye bakar; önceki haftaya ilişkin kısa söz | Açık gözlü dikkatli gözlem, kanatlar doğal kapalı; kısa söz/bakış | Bu sayfada uçuş yok; `mc_guide_03` başka satır diye süzülerek iniş çizimi bağlanamaz. Çayır metni orman kaynak sayılmaz |
| Simit — `whole-book-art-v1-003`, `blueprint_threshold_crossing_001`, `setting_arched_bazaar_001` | p3: `mc_calm_05`; gelir, yanında sakince oturur | Kıvrık kuyruğu okunur, uyanık oturuş ve sakin bekleme | Şehir örneğini orman arka planıyla değiştirme; hareketli kişilik diye koşu pozu bağlama yok |
| Böğürtlen — `whole-book-art-v1-076`, `bp_threshold_together_003`, `setting_whispering_forest_001` | p3: `mc_calm_03 → co_p_05`; yanında ileri bakar ve yardım teklif eder | Beden ölçeğini koruyan, yerde sakin eşlik ve dikkatli bakış | Yardım teklifi = ip çekme veya ağır nesne taşıma değildir; help-ready bile kaynakla ayrıca incelenir |

**Ortak çözüm örneği:** Tarçın ve Böğürtlen kitaplarında p6 `ce_s_07`: çocuk fikrini anlatır; arkadaş dinler ve bir katkı ekler; fikirler birleşir. Bu kaynakta somut çekme/taşıma/sabitleme fiili yoktur. Gerekli çizim şu an **dinleyen/dikkat kesilen arkadaş** olabilir; pilot A2'de sabitleme eylemi isteniyorsa önce yeni kaynakta gerçekten yazılmalı.

**Tam sayfa örneği, Tarçın p3:**

> Tarçın buraya çok gelirdi. Deniz'i görünce hiç şaşırmadı. Sadece yanına geçti ve onunla birlikte ileriye baktı. Hiç konuşmadılar. "Ben burayı bilirim," dedi Tarçın. "Her gün buradan geçerim."

Bu sayfa iki parçadan oluşur. Yalnız `mc_calm_03`'ü inceleyip p3'ün tamamını sessiz bekleyiş diye onaylamak yetersizdir. Aynı satır yeni Simit-orman ziyaretine verilirse “buraya çok gelirdi” iddiası ayrıca yanlışlaşabilir. Tam sayfa bağlamı şartının pratik nedeni budur.

## 4. Uyku ve özel eylem kaynak adayları

Aşağıdakiler tekil **authored satır** kanıtlarıdır; yeni pilotun tam sayfa kanıtı değildir. Kaynak paketi ham metin, pointer ve hash'i verir. Tam sayfa kurulmadan runtime eşleme onayı verilmez.

| Kaynak kimliği | Dosya / pointer | Gerçek anlam ve poz ihtiyacı | İlgili karakter / sınır |
|---|---|---|---|
| `bt_mc_02` | `templates/bedtime/beat_bedtime_meet_companion.json`, `/variants/1` | Esniyor ama gözleri açık; uyanık yorgunluk | Mevcut N rolü için Kestane/Yıldız adayı; yeni beşliye topluca açılmaz. Uyuyan çizim yanlış |
| `bt_lg_blanket_corner` | `templates/bedtime/beat_bedtime_let_go.json`, `/variants/3` | Yorgan köşesinde rahatça kıvrılma; cümle uykuyu bildirmiyor | Türün anatomisi uygun olmalı. Uyanık dinlenme ile uyku ayrılır; büyük ayıyı minik köşeye sığdırma yok |
| `bt_rs_p_curls_up` | `templates/bedtime/beat_bedtime_restore.json`, `/variants/6` | Kıvrılmış ve gerçekten uyumuş, gözler kapalı | Baykuşu tilki gibi kıvırma yok; türe uygun yeni kaynak gerekebilir |
| `bt_rs_p_one_more_yawn` | Aynı dosya, `/variants/5` | Son esneme sonrası uyku | Esneme ve uyuma iki ayrı zaman; sayfada hangi anın odak olduğu incelenir |
| `bt_wc_03` | `templates/bedtime/beat_bedtime_warm_close.json`, `/variants/2` | Adı geçmeden “uyuyan küçük dost” sahnede | Auto görsel listesi yalnız setting bildiriyor; arkadaşın yokluğu varsayılamaz. Tam semantik inceleme gerekli |
| `mc_guide_03` | `templates/v3/beat_meet_companion.json`, `/variants/2` | Kanatla süzülerek iniş | Yıldız uçuşu için kaynak adayı; Tarçın/Simit/Böğürtlen/Kestane'ye atanamaz. Bu teslimde bu satırın kullanıldığı yeni pilot sayfa yok |
| `mc_care_03` | Aynı dosya, `/variants/7` | Hafif titreme, durma ve başını kaldırma | Kestane için olası duygusal poz; “her Kestane sayfası kaygılı” değildir |
| `co_p_07` | `templates/v3/beat_companion_offers.json`, `/variants/6` | Bir yeri gösterme / bakış yönlendirme | İnsansı el/parmak zorunlu değil; four-legged anatomi ve asıl eylem aktörü incelenir |
| `sfa_01` | `templates/series/beat_series_first_attempt.json`, `/variants/0` | **Çocuk** taşıyor; arkadaş önden gidip dönerek bakıyor | Arkadaş yürüyüş/geriye bakış; taşıma pozu yanlış. Yeni pilot bağımsız kitap, seri kapsamı bu satırla açılmaz |
| `s56_ra_03` | `templates/v3/beat_receive_appeal.json`, `/variants/14` | Çayırda koşmuş arkadaş oyun davet ediyor | Orman pilotunda kaynak/wold uyarlaması gerekir; mevcut trotting pozu otomatik onaylı değil |

Pointer'lar kaynak JSON'undan mekanik kontrol edilir; kaynak değişirse bu teslimin hash'i eski kabul edilir ve yeniden inceleme gerekir.

## 5. İlk iş sırası

### P0 — Kaynak yazımından bağımsız seçim tanınabilirliği

Beş kanonik seçim portresi için mevcut onaylı takım kimliğinden tekil görünüş brifi hazırlanabilir. Her portre ContentID ile bağlanır; SF Symbol tür çakışması yeni kadroyu elemez. Bu tur çizim yapılmadı. Portre onayı, sahne/eylem onayı değildir.

### P1 — Var olan kaynaklardan gözlem ve yeniden kullanım incelemesi

- Tarçın: mevcut greeting/together/glad paketli art'ın **dar onaylı kaynak kuralları** incelenir; aynı duruşu gereksiz yeniden çizme.
- Kestane: sakin açık gözlü eşlik; tereddüt pozu ancak ilgili satırda.
- Yıldız: kapalı kanatla dikkatli bakış; ayrı uçuş kaynak incelemesi varsa iniş.
- Simit: kuyruğu tanınan oturuş/bakış; mevcut gerçek şehir sayfası ile yeni orman ziyareti birbirine karıştırılmaz.
- Böğürtlen: boyutu korunan sakin duruş/dinleme; güç eylemi varmış gibi prop eklenmez.

### P2 — Pilot kaynakları yazıldıktan sonra somut eylem talepleri

| Pilot tasarımı | Karakterler | Yeni kaynakta teyit edilecek gerçek eylem |
|---|---|---|
| U1 | Tarçın, Yıldız, Böğürtlen | Uyanık dinleme, açık gözden rahatlamaya geçiş; ses kaynağı görünür mü? |
| U2 | Kestane, Simit, Böğürtlen | Uygun yere yaklaşma, yerleşme, uyanık dinlenme; gerekirse uyuma ayrı. Ayı için geniş zemin, baykuş için dört ayaklı kıvrılma yok |
| U3 | Tarçın, Kestane, Yıldız, Simit | Kısa anlatım/dinleme ve sakin kapanış; hatırlanan gündüz eylemi gece sahnede çizilmez |
| L1 | Tarçın, Yıldız, Simit | Baş/bakış yöneltme, iki ayrı gözlem; genel curious pozu her somut incelemeyi karşılamaz |
| L2 | Kestane, Yıldız, Böğürtlen | Aynı şeye farklı konumdan bakma; kanonik beden/ayak yönü, perspektif |
| L3 | Tarçın, Kestane, Simit, Böğürtlen | Bekleme ve aynı şeyi yeniden gözleme; holding/carrying varsa nesne/aktör kaynakta açık olmalı |
| A1 | Tarçın, Kestane, Simit | Küçük adım, eşlik, güvenli ilerleme; çocuğu taşıma yok |
| A2 | Tarçın, Yıldız, Böğürtlen | Çocuğu dinleme; fiziksel sabitleme ancak yeni satır gerçekten söylüyorsa |
| A3 | Kestane, Yıldız, Simit, Böğürtlen | Geriye dönme/yavaş yürüme/önceki izi gözleme; iz kime ait belirsizse arkadaşa aitmiş gibi çizme yok |

Bu tablo bir çizim adedi taahhüdü değildir. Aynı uygun poz birden çok kaynakta kanıtla kullanılabilir; farklı somut eylemler tek “helping” altında birleştirilemez. Bugün olmayan yeni pilot sourceID'leri bu tabloya eklenmedi.

## 6. Tarçın pozlarının durumu

`2026-11-22-tarcin-pose-library/GENERATION_RECORD.json`: walking, curious, worried, farewell, trotting, resting, asleep, help-ready **review-draft-not-runtime-approved**. Hepsi aynı onay statüsüne yükseltilmez; bazıları zemin/alfa/görsel inceleme gerektirir.

- `resting` açık gözlü uyanık, `asleep` kapalı gözlü uyku; birbirine ikame edilmez.
- `help-ready` yardım hazırlığı; ip çekme/ağır taşıma resmi değildir.
- `curious` = kaynakta görülen her özel eylem değil; boyut, bakış ve prop ilişkisi gerekir.
- `worried` merak yerine kullanılmaz; uyku sahnesine gereksiz endişe eklenmez.
- Farewell için yeni pilotta doğrulanmış ayrılma kaynağı yok; üretim önceliği değil.

PNG'nin bulunması, alfa kanalının olması veya generation prompt'u bir eşleme onayı değildir. Bu plan turunda görsel dosyaları yeniden incelenip onaylanmadı.

## 7. Yeni pilot için zorunlu tam sayfa teslim kaydı

Her **gerçek yazılmış** pilot sayfası için içerik ekibi aşağıdakileri verir; bu form tamamlanmadan action-specific runtime kuralı hazırlanmaz:

| Alan | Gerekli değer |
|---|---|
| Kaynak sürümü | ContentSourceReference / payload SHA; pilot paket sürümü, profil/kadro sürümü |
| Kitap bağlamı | Kanonik companionID, settingID, discoveryID; yaş 5–6; mode/arc; varsa guest/family/occasion/series/recall |
| Sayfa kimliği | Gerçek blueprintID, pageNumber, role, sıralı beat/supportingBeat |
| Tam kaynak izi | partCount, sıralı bütün parts; sourceKind/sourceID/templateID/sourceTextDigest/contexts; atlanan/bozuk parça varsa incomplete |
| Tam metin | Sentetik doldurulmuş sayfa + authored metinler; önceki/sonraki sayfa ve olayın baş/son durumu |
| Anlam | Her konu için canonical subjectID, present/remembered/intended, states; adsız/zamirli bütün anmalar dahil |
| Eylem kanıtı | Eylemin aktörü, ne yapıyor, neye/kimle, nesne durumu ve tutulduğu yer; anatomi/ölçek; belirsizse “çizim kararı yok” |
| Sanat kararı | İçerik anlam onayı, görsel kimlik/poz onayı ve app asset/rule onayı ayrı; assetID/revision/digest ve eski pinleri koruma |

Kayıt `auto` olsa bile tüm sayfa düşünülür; `reviewed` tek başına asset uygunluğunu onaylamaz. `ComposedPage.provenance → StoryPage.provenance` korunur; karar yalnız mevcut `StoryPage.art` içinde kalıcıdır. Runtime kelime araması, API, art için seed/retry veya sessiz içerik daraltma yok.

## 8. Başarısız gerçek örnek ve kabul sınırı

Paket `negativeZeroArtExample` içinde önceki gerçek Tarçın kitabını da taşır: `whole-book-art-v1-016`, `bp_threshold_joining_002`, Şenlik Çayırı, `object_flickering_light_001`, sekiz temiz sayfa, sıfır pin. p3 `mc_calm_01 → co_p_07`; p8 `wc_p_succeed_04 → cf_p_02`. Mevcut rapor ayrıntılı binder reddini açıklamıyor; sırf “asset eksik” diye neden uydurulmaz.

Sonuç: tanınan beşli veya çok sayıda poz, her kitapta art garantisi değildir. Pilot sanat kabulü bütün denemelerin gerçek tam sayfa kapsam raporuna dayanır; bu açıklayıcı legacy paket başarı kanıtı olarak kullanılmaz.
