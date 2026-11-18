# Motor ve havuz genişletme planı (H0-H5)

17 Kasım 2026. Batuhan: "motor engineyi ve havuzu genişletmeliyiz, sonra diğer işlere bakarız". `docs/EVREN_PLANI.md`'nin E7-E8'i bu planın arkasına kaldı.

## Bugünkü havuz (main@69d9649, katalog JSON'undan sayıldı)

Standart arklı blueprint sayısı, bant ve moda göre. Parantez içi: en korumacı ayarda (`ContentSafety.level == .calm`, gergin sayfalı blueprint düşer) kalan.

| Bant | Macera | Öğrenme | Uyku | Seri devamı |
|---|---|---|---|---|
| 3-4 | **0** | 2 (2) | 2 | 4 |
| 5-6 | 4 (**2**) | 12 (12) | 3 | 4 |
| 7-8 | 2 (2) | 2 (2) | 2 | **0** |
| 9-10 | 2 (2) | 2 (2) | 2 | **0** |

Sonuçlar:

- Konu çipi en az 3 farklı mekanizma ister (`CatalogStoryTopic.minimumMechanisms`). Varsayılan ayar en korumacı olduğu için **bugün hiçbir bantta macera konusu görünmüyor**; "Gökyüzü ve uzay" de dahil (E5'te bulundu).
- 3-4 yaşta macera modu hiç yok.
- 7-10 yaşta her mod iki blueprint'le dönüyor: aynı iki olay örgüsü sırayla gelir.
- 7-10 yaşta biten masal devam ettirilemez.
- 5-6 dışındaki bantlarda öğrenme modunun konuları (Meslekler, Sporlar, Hayvanlar, Bilim, Tarih) aynı kapıya takılıyor.

## Hedef

Her bantta, en korumacı ayarda: macera ≥ 4, öğrenme ≥ 4, uyku ≥ 3 blueprint ve en az 3 mekanizma; her bantta seri devamı. Motor değişikliği yalnızca içeriğin istediği kadar.

## Fazlar

| Faz | Amaç | Büyüklük |
|---|---|---|
| H0 | Kapsam raporu: bant × mod × güvenlik × konu matrisi, test olarak | K |
| H1 | Sakin macera, her bantta (3-4 sıfırdan) | B (içerik) |
| H2 | Öğrenme 3-4 ve 7-10 | B (içerik) |
| H2b | Meslekler 7-10 (ayrı faz, karar: Batuhan 18 Kasım 2026) | O (içerik) |
| H3 | Uyku çeşitliliği 3-4 ve 7-10 | O (içerik) |
| H4 | Seri devamı 7-8 ve 9-10 | O |
| H5 | Cümle tekrarı ölçümü, ince satır havuzlarını kalınlaştırma | O |

### H0: Kapsam raporu

Motor paketinde saf bir rapor (`CoverageReport`): her bant, mod, güvenlik seviyesi ve konu için kurulabilen blueprint, mekanizma ve konu görünürlüğü. Testte iki iş: matrisi yazdırır (insan okur), ve hedefleri **taban** olarak kilitler: bir içerik değişikliği bir hücreyi düşürürse test kırılır. Hedefe henüz ulaşmamış hücreler bugünkü değerde kilitlenir, her faz kendi hücresini hedefe çeker.

**Uygulanan (17 Kasım 2026).** `StoryEngine/Sources/StoryEngine/Offline/CoverageReport.swift`: her bant × mod × ayar (en korumacı, süzgeçsiz) için `BlueprintSelector.admissible` + `OfflineContentBinder` ile kurulabilen blueprint'ler, mekanizmalar (`CatalogBlueprint.mechanismKey`; konu kapısı da artık bunu sayıyor, tek tanım), `availableTopics`'in teklif ettiği konular ve seri devamı var mı (`SeriesPlanner.continuations`). `CoverageReportTests` matrisi yazdırır ve en korumacı ayardaki tabanları kilitler; H0 tabanları bugünkü tablo. Testler henüz koşulmadı: ilk koşuda yazdırılan tablo bu belgeye geçirilmeli.

### H1: Sakin macera

Gergin sayfası olmayan (`unease`, `hesitation` yok) macera blueprint'leri. Merak, keşif, yardım, bulmak; korku ve kaybolma yok.

- 3-4: 4 yeni (macera bu bantta sıfırdan; 6 sayfa).
- 5-6: 2 yeni sakin (eşik geçmenin sakin biçimi dahil).
- 7-8 ve 9-10: her birine 2 yeni (eşik ya da yeni bir aile).

Mevcut beat ve satır mimarisiyle; yeni aile gerekirse motorun `NarrativeFamily` sözlüğüne eklenir. Yeni kayıtlar dizilerin sonuna.

**Uygulanan (17 Kasım 2026).** On blueprint, `pilot_library_v1.json`'un sonuna; hepsi `absence` ya da `threshold` ailesinde, hiçbirinde `unease`/`hesitation` sayfası yok. Yeni aile ya da beat gerekmedi: mekanizma `editorialName`'den sayıldığı için (H0, `mechanismKey`) aynı ailede farklı çözüm beat'i farklı bir olay örgüsü sayılıyor.

| Kimlik | Bant | Aile | Olay örgüsü |
|---|---|---|---|
| `bp_adventure_lookingtogether_age3_001` | 3-4 | absence | Bir iz görür, arkadaşıyla aramayı sürdürür, bulur (`persist`). |
| `bp_adventure_lookingback_age3_001` | 3-4 | absence | Bir iz görür, geldikleri yola dönüp bakar, orada bulur (`retrace`). |
| `bp_adventure_together_age3_001` | 3-4 | threshold | Yeni bir yerin girişinde durur, arkadaşıyla el ele geçer (`cooperative_effort`). |
| `bp_adventure_asking_age3_001` | 3-4 | absence | Bir iz görür, yolu birine sorar, cevapla bulur (`ask_for_help`). |
| `bp_threshold_together_003` | 5-6 | threshold | Sakin eşik: ilk deneme yetmez, arkadaşıyla birlikte geçer. |
| `bp_absence_asking_003` | 5-6 | absence | İzin kime ait olduğunu sorarak bulur. |
| `bp_absence_signs_age7_001` | 7-8 | absence | Bir tahminde bulunur, işaretleri okuyarak düzeltir ve bulur (`insight`). |
| `bp_threshold_together_age7_001` | 7-8 | threshold | Eşiği arkadaşıyla birlikte geçer. |
| `bp_absence_signs_age9_001` | 9-10 | absence | İşaretleri okuyarak bulur (10 sayfa). |
| `bp_threshold_together_age9_001` | 9-10 | threshold | Eşiği arkadaşıyla birlikte geçer (10 sayfa). |

Satırlar: 64 yeni varyant (`move: "h1_…"`), 3-4'te yedi yeni beat dosyası (`obstacle_raises`, `first_attempt`, `persist`, `retrace`, `cooperative_effort`, `ask_for_help`, `succeed`), 7-8 ve 9-10'da birer `cooperative_effort` dosyası; var olan dosyalara yalnızca sona ekleme. Yeni satırlar var olan masallara rol (`castRoles`), uzunluk sınıfı, `afterClosing`, `afterBeat` ve `conflictKinds` kapılarıyla karışmıyor.

Beklenen tablo (Python yaklaşığı; ilk test koşusunda `CoverageReportTests`'in yazdırdığıyla değiştirilecek). Blueprint / mekanizma, en korumacı ve süzgeçsiz:

| Bant | Macera | Öğrenme | Uyku | Seri devamı (macera) |
|---|---|---|---|---|
| 3-4 | **4/4** (4/4) | 2/2 (2/2) | 2/2 | yok |
| 5-6 | **4/4** (6/6) | 12+ (aynı) | 3/3 | var |
| 7-8 | **4/4** (4/4) | 2/2 | 2/2 | yok |
| 9-10 | **4/4** (4/4) | 2/2 | 2/2 | yok |

En korumacı ayarda görünen macera konuları, dört bantta da: Denizin altı, Gökyüzü ve uzay, Vahşi doğa, Hazine avı (Yeni bir ülke ve Yeni bir şehir henüz yok). Öğrenme konuları yalnızca 5-6'da (Meslekler, Hayvanlar, Bilim). `CoverageReportTests` macera tabanlarını hedefe çekti (≥4 blueprint, ≥3 mekanizma).

Yan etkiler: ilgi kelimeleri beşten ona çıktı (Uzay, Müzik, Robotlar, Bilim, Gökyüzü eklendi; sınırlayan bant 3-4'tü). 3-4 korpusunun dosya notu "aşılacak engel yok" diyor; plan bu bandı maceraya açtığı için yeni 3-4 satırlarında engel küçük, içsel ve arkadaşla aşılıyor. Not dosyalarda değişmedi (yalnızca ekleme kuralı); Batuhan'ın okuması gerekiyor.

### H2: Öğrenme 3-4 ve 7-10

**Uygulanan (18 Kasım 2026).** Batuhan'ın üç kararıyla (18 Kasım):

1. **3-4'te yaş kuralı gevşedi.** `NarrativeFamily.minimumAge` `unexplained` ve `misreading` için 5'ten 4'e indi, ve `CatalogIntegrity.checkAgeFit` artık bandın **üst** ucuna bakıyor (alt uca baksaydı taban 4'e inse de 3-4 kapalı kalırdı). Gerekçe yorumu dürüstçe güncellendi: bu bir ürün kararı, kanıt değişmedi; 4 yaş yanlış inanç kavrayışının oturmaya başladığı aralığın alt ucu. Bu yüzden 3-4 sürümleri en basit biçimde: tek bir somut sanı ("Bunu bir kuş bırakmış!"), tek bir görünür düzeltme (yakından bakmak), iç dünyayı anlatan uzun cümle yok.
2. **İki NASA olgusu 7-8 ve 9-10'a açıldı:** `fact_sun_is_a_star` ve `fact_shooting_star_is_not_a_star`'ın `bands` alanı `["5-6", "7-8", "9-10"]`. Mevcut kaydın değişmesi; "yalnızca sona ekleme" kuralının onaylı istisnası. Yeni olgu yazılmadı.
3. **Meslekler 7-10 bu turda yok** (H2b, aşağıda).

Yedi blueprint, `pilot_library_v1.json`'un sonuna; hiçbirinde `unease`/`hesitation` sayfası yok, yeni aile ya da beat yok.

| Kimlik | Bant | Aile | Olay örgüsü |
|---|---|---|---|
| `bp_unexplained_howitworks_age3_001` | 3-4 | unexplained | Bir şey kendi kendine oluyor; çocuk tahmin eder, izler, ne zaman olduğunu görür (`insight`). |
| `bp_misreading_closerlook_age3_001` | 3-4 | misreading | "Bunu bir kuş bırakmış!"; yakından bakınca öyle değil (`reveal_truth`). |
| `bp_appeal_together_age3_001` | 3-4 | appeal | Küçük biri yardım ister; tek başına olmaz, birlikte olur (`cooperative_effort` → `restore`). |
| `bp_appeal_together_age7_001` | 7-8 | appeal | Biri yardım ister, iki beceri gerekir, işi bölüşürler. |
| `bp_charge_tending_age7_001` | 7-8 | charge | Bakmak ve beklemek (`take_charge`, `tend`, `patient_wait`). |
| `bp_appeal_together_age9_001` | 9-10 | appeal | 7-8'in 10 sayfalık hâli. |
| `bp_charge_tending_age9_001` | 9-10 | charge | Bakmak ve beklemek; sayfa 5'te bakılan kişi ne istediğini gösterir (`companion_offers`). |

Satırlar: 90 yeni varyant (`move: "h2_…"`). Yeni dosyalar: 3-4'te `form_belief`, `belief_fails`, `reveal_truth`, `insight`; 7-8 ve 9-10'da `take_charge`, `tend`, `patient_wait`. Var olan dosyalara yalnızca sona ekleme (ve gereken yerde `lengthClasses`'a yeni bir sınıf: 3-4 `restore` `solo`, 7-8 ve 9-10 `meet_companion` `solo`, 9-10 `companion_offers` `solo`). Yeni satırlar var olan masallara rol, uzunluk sınıfı ve `afterBeat` kapılarıyla karışmıyor; 7-8 ve 9-10'da `warm_close`'a bu yüzden satır eklenmedi.

7-8 ve 9-10'un `needsCare` satırları (tanışma, yardım isteği) var olan korpusta "kaybettim" üzerine yazılı; `appeal` masalları bu yüzden kaybolan bir şeyi birlikte bulmaya yaslanıyor. Batuhan'ın okuması gerekiyor.

Beklenen tablo (Python yaklaşığı, en korumacı ve süzgeçsiz aynı; ilk test koşusunda `CoverageReportTests`'in yazdırdığıyla değiştirilecek):

| Bant | Öğrenme (blueprint/mekanizma) | Öğrenme konuları |
|---|---|---|
| 3-4 | **5/5** (önce 2/2) | Hayvanlar (önce yok) |
| 5-6 | 13/10 (değişmedi) | Meslekler, Hayvanlar, Bilim |
| 7-8 | **4/4** (önce 2/2) | Hayvanlar (önce yok) |
| 9-10 | **4/4** (önce 2/2) | Hayvanlar (önce yok) |

`CoverageReportTests` öğrenme tabanlarını hedefe çekti (≥4 blueprint, ≥3 mekanizma). Bilim 7-10'da hâlâ görünmüyor: yalnızca iki keşif `science` taşıyor (`object_flickering_light_001`, `object_star_stone_001`) ve üç mekanizmaya ulaşmıyor; açılan NASA olguları bu yüzden bugün yalnızca bilim konusu seçilmeden gelen masallarda görünür.

### H2b: Meslekler 7-10 (ayrı faz)

Karar: Batuhan, 18 Kasım 2026. Meslekler konusu blueprint'in `jobs` etiketini ve insan yol arkadaşını istiyor (`topic_learning_jobs`: `companion: jobs`, `plot: jobs`). Üç insan yol arkadaşı var (fırıncı, postacı, öğretmen), hepsi köyde; mekân olarak yalnızca Minik Köy ve Pazar Yeri. Faz: 7-8 ve 9-10'a her birine en az üç `jobs` blueprint'i (üç ayrı mekanizma) ve o bandın satır dosyalarında insan yol arkadaşına uyan satırlar (`natureRequire: person`, gerekiyorsa `occupationRequire`). Meslek olguları (`fact_baker_rests_the_dough` vb.) 5-6'da; 7-10'a açılmaları ayrı bir onay ister.

**Sporlar:** hiç içerik yok. `topic_learning_sports` `companion: sports` ve `discovery: sports` istiyor; katalogda bu etiketi taşıyan tek kayıt yok, hiçbir bantta görünmüyor. Ayrı bir içerik kararı gerektiriyor.

### H3: Uyku çeşitliliği

**Uygulanan (18 Kasım 2026).** Yedi uyku blueprint'i, `pilot_library_v1.json`'un sonuna; hepsi `charge`/`bedtime`, iki yatak odasında. Yeni mekân, aile ya da beat yok.

| Kimlik | Bant | Mekanizma (`editorialName`) | İmza sayfası |
|---|---|---|---|
| `bp_bedtime_listening_age3_001` | 3-4 | listeningSounds (3-4) | s.4 `examine` + `tend` |
| `bp_bedtime_countingday_age3_001` | 3-4 | countingTheDay (3-4) | s.4 `companion_offers` + `tend` |
| `bp_bedtime_listening_001` | 5-6 | listeningSounds | s.5 `examine`, s.6 `tend` + `patient_wait` |
| `bp_bedtime_listening_age7_001` | 7-8 | listeningSounds (7-8) | s.5 `examine`, s.6 `tend` + `patient_wait` |
| `bp_bedtime_countingday_age7_001` | 7-8 | countingTheDay (7-8) | s.5 `companion_offers`, s.6 `tend` + `patient_wait` |
| `bp_bedtime_moontalk_age9_001` | 9-10 | moonTalk (9-10) | s.8 `approach` |
| `bp_bedtime_countingday_age9_001` | 9-10 | countingTheDay (9-10) | s.10 `warm_close` + `self_recognize` |

Satırlar: 43 yeni varyant (`move: "h3_…"`), yedi yeni uyku beat dosyası, beş dosyaya `paired` sınıfıyla sona ekleme. Ayrıntı `docs/UYKU_ARKI.md` ve `docs/MagicPaper_Content_Library.md` §18.

Bilerek yapılmayan:
- **Yeni mekân yok.** İki oda yetti; yeni bir dinlenme yeri var olan uyku masallarının yer seçimini (ve sabit seed'li testleri) kaydırırdı. Çeşitlilik mekanizmadan geliyor.
- **Nakarat (`refrain`) yok.** Motor destekliyor, ama `x_refrain_bedtime` deneyi açık ve gönderilen blueprint'te nakarat test ile yasak. Tekrar satırların içinde yazıldı. Deneyi kapatıp nakaratı açmak ayrı bir karar.
- **7-10 uyku devamı yok** (H4). "Devam ettir" `SeriesPlanner.isAvailable` ile gizli kalıyor. 3-4 ve 5-6'da yeni blueprint'ler aynı odalarda ve aynı keşifle açıldığı için var olan uyku devamları (`bp_cont_bedtime_staying`, `settling`) değişmeden bağlanıyor.

Beklenen tablo (Python yaklaşığı, en korumacı ayar; ilk test koşusunda `CoverageReportTests`'in yazdırdığıyla değiştirilecek):

| Bant | Uyku (blueprint/mekanizma) | Seri devamı |
|---|---|---|
| 3-4 | **4/4** (önce 2/2) | var |
| 5-6 | **4/4** (önce 3/3) | var |
| 7-8 | **4/4** (önce 2/2) | yok (H4) |
| 9-10 | **4/4** (önce 2/2) | yok (H4) |

`CoverageReportTests` uyku tabanlarını hedefe çekti (≥4 blueprint, ≥3 mekanizma).

### H4: Seri devamı 7-10 (ve 3-4 macera/öğrenme)

Bugün devam blueprint'leri (`series.continuations`) yalnızca 3-4 ve 5-6'da. 7-8 ve 9-10'da hiç yok: bu bantlarda sevilen masalda "Devam ettir" `SeriesPlanner.isAvailable` ile gizli. 3-4'te düz arkın iki devamı (`bp_cont_waiting_age3_001`, `bp_cont_homeward_age3_001`) yalnızca `bedtime` modunu taşıyor; H1 ve H2 ile gelen 3-4 macera ve öğrenme masalları devam edemiyor.

Hedef (her hücrede en az iki mekanizma, çünkü planlayıcı bölümleri A-B-A-B dolaştırır):

| Bant | Düz ark (bedtime, learning, adventure) | Uyku arkı (bedtime) |
|---|---|---|
| 3-4 | +2 yeni, yalnız `learning` + `adventure` (var olan iki kayıt değişmez) | var |
| 5-6 | var | var |
| 7-8 | +2 yeni (`stayingWith`, `takingItHome` karşılığı), 8 sayfa | +2 yeni (`bedtimeStayingWith`, `bedtimeSettling` karşılığı) |
| 9-10 | +2 yeni, 10 sayfa | +2 yeni |

Toplam 10 devam blueprint'i, `series.continuations` dizisinin sonuna. Satırlar `templates/series/` altında bant önekli yeni beat dosyalarında (`beat_series_age7_*`, `beat_series_age9_*`), 3-4 için var olan `age3` dosyalarına yalnızca sona ekleme; macera ve öğrenme tonunda, uyku sözcüğü yok.

Kurallar:
- Hiçbir devamda `unease`/`hesitation` sayfası yok; en korumacı ayarda da seri açılır.
- Hatıra (`{{keepsake.name}}`) her bölümde hatırlanır, yeniden bulunmaz; keşif her bölümde yeni (planlayıcı bunu zaten sağlar, satırlar buna göre yazılır).
- 7-10'da cümle uzunluğu ve kelime düzeyi o bandın var olan v3-age7 / v3-age9 satırlarıyla aynı.
- Yaş kuralı: `ageRange` bandın kendisi; `CatalogIntegrity` ve `NarrativeFamily.minimumAge` değişmez.
- `CoverageReportTests`: 7-8 ve 9-10'da seri devamı "var" olarak kilitlenir (dört mod-ark hücresi), 3-4'te macera ve öğrenme için de.

Dokunulmayan: `SeriesPlanner` mantığı, plan şeması (`SeriesPlan.currentSchemaVersion` 1 kalır), uygulama tarafı. Var olan devam kayıtları değişmez.

**Uygulanan (18 Kasım 2026).** On devam blueprint'i `series.continuations`'ın sonuna; hiçbirinde `unease`/`hesitation` yok, var olan kayıtlara dokunulmadı.

| Kimlik | Bant | Ark / modlar | Bölüm |
|---|---|---|---|
| `bp_cont_lookingagain_age3_001` | 3-4 | düz / learning, adventure | Yeni bir şey görülür, ilk bakışta bulunmaz, aramayı sürdürüp bulurlar (`persist`). |
| `bp_cont_askingagain_age3_001` | 3-4 | düz / learning, adventure | Yeni bir şey görülür, tek başına çözülmez, dosta sorulur (`ask_for_help`). |
| `bp_cont_waiting_age7_001` | 7-8 | düz / üç mod | Yeni bir küçük şeye bakılır ve beklenir (`stayingWith`). |
| `bp_cont_homeward_age7_001` | 7-8 | düz / üç mod | Evinden uzak düşmüş bir şey yerine götürülür (`takingItHome`). |
| `bp_cont_bedtime_staying_age7_001` | 7-8 | uyku / bedtime | Dost yine pencerede; pencere önündeki küçük şeye bakılır, çocuk uyur. |
| `bp_cont_bedtime_settling_age7_001` | 7-8 | uyku / bedtime | Küçük bir misafire odada yer açılır, çocuk uyur. |
| `bp_cont_waiting_age9_001` | 9-10 | düz / üç mod | `stayingWith`, 10 sayfa; s.8'de dost bildiğini paylaşır. |
| `bp_cont_homeward_age9_001` | 9-10 | düz / üç mod | `takingItHome`, 10 sayfa. |
| `bp_cont_bedtime_staying_age9_001` | 9-10 | uyku / bedtime | Uyku arkında bekleyen çocuk, 10 sayfa. |
| `bp_cont_bedtime_settling_age9_001` | 9-10 | uyku / bedtime | Uyku arkında yer açan çocuk, 10 sayfa. |

Satırlar: 196 yeni satır (`move: "h4_…"`).
- 7-8 ve 9-10 düz ark: `templates/series/beat_series_age7_*` (11 dosya) ve `beat_series_age9_*` (12 dosya).
- 7-8 ve 9-10 uyku arkı: var olan uyku seri dosyalarının düzeniyle `templates/bedtime/beat_bedtime_series_age7_*` ve `_age9_*` (yedişer dosya). Uyku seri satırları 21 Ekim'den beri `bedtime/` altında; plan `series/` diyordu, düzen korundu.
- Seri katmanında satırı olmayan beat'ler bandın tek seferlik satırlarına düşer (planlayıcının bugünkü davranışı): düz arkta `examine`, `approach` (9-10), 3-4'te `obstacle_raises`, `persist`, `ask_for_help`, `succeed`; uyku arkında `take_charge`, `tend`, `patient_wait`, `let_go`, `restore`, `examine` ve 9-10 `companion_offers`.
- 3-4: var olan beş `age3` dosyasına yalnızca sona ekleme. Yeni satırlar var olan 3-4 devamlarına uzunluk sınıfı (`revisit`, `notice_anomaly`, `first_attempt` için `paired`, `commit` için `solo`) ve `afterClosing: ["succeed"]` (`warm_close`) ile karışmıyor.
- `revisit` ve `warm_close` (seri aile anları) her yeni dosyada dört ilişkinin her biri için iki satır taşıyor.

Beklenen kapsam (Python yaklaşığı): her bant × mod hücresinde seri devamı "var". `CoverageReportTests` bunu kilitliyor; `SeriesPlannerTests`'te "devamı olmayan kesit" listesi boşaldı ve "devamı olmayan mod" sınaması yatak odasında açılan bir masalın öğrenme moduna taşındı.

Açık: 3-4 macera ve öğrenme bölümlerinin son sayfası var olan `age3` `warm_close` satırlarını da çekebilir; bunlardan biri ("… Uyudu.") uyku diliyle bitiyor. Ayırmak var olan kayda kapı eklemeyi gerektirir, yapılmadı. 3-4'te s.4 (`persist`, `ask_for_help`) yalnızca `paired` satır buluyor; sayfa kısa kalır.

### H2b uygulama planı (19 Kasım 2026, "tümünü yap")

- 7-8 ve 9-10'a üçer `jobs` blueprint'i, üç ayrı mekanizma (`editorialName` " - " sonrası), `learning` modunda, gergin sayfa yok. Mekân Minik Köy ve Pazar Yeri; yol arkadaşı fırıncı, postacı, öğretmen.
- Satırlar o bandın v3-age7 / v3-age9 dosyalarına, sona ekleme; insan yol arkadaşı kapısıyla (`natureRequire: person`, gerekirse `occupationRequire`).
- Meslek olguları 7-10'a açılır (NASA olgularında olduğu gibi `ageRange` genişletmesi, metin değişmez). Bu, plandaki "ayrı onay" maddesidir; "tümünü yap" ile açıldı, Batuhan okuyunca geri alınabilir.
- Hedef: 7-8 ve 9-10'da en korumacı ayarda Meslekler konusu görünür. `CoverageReportTests` bunu kilitler.

**Uygulanan (19 Kasım 2026).** Altı `jobs` blueprint'i (`learning`, `nature: person`, gergin sayfa yok): 7-8 ve 9-10'a üçer, mekanizmalar `seekingKnowledge` (çocuk işini bilene sorar, `ask_for_help`), `patientObservation` (iş zamanını bekler, `companion_offers` + `patient_wait`), `helpingAtWork` (bulunan bir şeyin sahibini birlikte ararlar, `appeal`, `cooperative_effort`). 67 satır (`move: "h2b_…"`): 7-8 ve 9-10'a birer yeni `ask_for_help` dosyası, var olan dosyalara sona ekleme. Zanaat satırları yalnızca `ask_for_help`'te ve `occupationRequire` + `natureRequire: person` ile mesleğine bağlı, her meslekte dörder (`JobsTopicTests` kuralı); öbür sayfalardaki insan satırları mesleksiz (`natureRequire: person`); insanla tanışma satırları `natureRequire: person` ve `solo` sınıfında, böylece eski `paired` tanışma satırları (yol arkadaşının çocuğa yaklaştığı) insana gitmiyor. Üç meslek olgusu `bands` 5-10'a açıldı. Python yaklaşığı: 7-8 ve 9-10'da Meslekler görünür; iki meslek şekli bilim keşfini de bağladığı için Bilim de bu iki bantta üç mekanizmaya ulaştı.

### Sporlar (19 Kasım 2026, "tümünü yap")

İlke 7 (yarış ve sıralama yok) burada da geçerli: spor **hareket oyunu** olarak yazılır. Kazanan, kaybeden, skor, rekor, "en hızlı" yok. Bedenin ne yaptığını keşfetmek, birlikte denemek, bir şeyi ilk kez becermek.

- İçerik, sona ekleme: en az iki `sports` etiketli yol arkadaşı (biri insan: ör. yüzme ya da jimnastik öğretmeni; biri hayvan: ör. zıplamayı seven bir keçi) ve en az üç `sports` etiketli keşif nesnesi (top, atlama ipi, uçurtma gibi). Var olan kayıtlara etiket eklenmez.
- Mekân: var olan açık alanlar (bahçe, çayır, park benzeri) kullanılır; gerekirse bir yeni mekân.
- Blueprint: dört bantta da `learning` modunda en az üç `sports` blueprint'i, üç ayrı mekanizma (konu kapısı ≥3). Gergin sayfa yok.
- Spor olguları gerekirse `facts`'e: doğru, sade, kaynaklı (ör. "Kalp koşarken daha hızlı atar"). "hızlı" kelimesi yalnızca olgu içinde, masal anlatısında hız övülmez.
- Hedef: dört bantta en korumacı ayarda Sporlar konusu görünür; `CoverageReportTests` kilitler.

**Uygulanan (19 Kasım 2026).** Köy Çayırı (yeni mekân), Beden Öğretmeni Defne (`coach`, insan) ve keçi Zıpzıp, üç nesne (top, atlama ipi, kâğıt uçurtma), her banta üç `sports` blueprint'i (`learning`, gergin sayfa yok), 83 satır, sona ekleme. Defne dördüncü meslek olduğu için zanaat beat'lerinde dörder satırı var ve editoryal bir olgu (`fact_coach_shows_slowly`, 5-10) aldı; `JobsTopicTests`'teki iki "tam 3" "en az 3" oldu. `CoverageReportTests` Sporlar'ı dört bantta kilitler. Python yaklaşığı: dört bantta görünür; testler plan sonunda.

### H5: Tekrar ölçümü ve ince havuzlar

Derleme yapılamadığı için ölçüm Python yaklaşığıyla: her bant × beat × ark için kapılardan (bant, ark, rol, uzunluk sınıfı, `afterClosing`, `afterBeat`, aile ilişkisi) geçen satır sayısı. Rapor `docs/HAVUZ_RAPORU.md`'ye yazılır (tablo + en ince 20 havuz).

- Bir masalın bir sayfasını dolduran havuz 3 satırın altındaysa, en az 4'e çıkarılır (sona ekleme).
- Aynı bandda iki ayrı beat dosyasında birebir aynı cümle varsa raporlanır, silinmez.
- Bilinen kusurlar raporda listelenir, değiştirilmez: 7-8 `a7_na_02`'deki "hemen", 3-4 `swc3_fam_sib_03`'teki "hemen", ad yuvasından sonra "de/da" bağlacı olan iki eski satır. Bunlar mevcut kayıt; Batuhan karar verir.
- Motorun içindeki ölçüm (`CoverageReport`'a satır sayısı) derleme açılınca eklenir.

## Kurallar

- Mevcut kayıtlar değişmez, yalnızca sona ekleme. Sabit seed'li altın testler kırılırsa neden yazılır ve fikstür güncellenir (kayıtlı masallar metni saklar).
- Bütün yeni metin taslaktır, Batuhan okur. Dil kuralları CLAUDE.md'de.
- Testler plan sonunda bir kez; her faz derlenir.
