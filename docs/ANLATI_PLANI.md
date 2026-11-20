# Anlatı planı (A0-A8): havuzu büyütmek, masal modelini genişletmek

20 Kasım 2026. Kaynak: main@33e9759 üzerinde yapılan iki ölçüm (aşağıda). `HAVUZ_PLANI.md` (H0-H5) ve `EVREN_PLANI.md` (E1-E8) bitti ya da sürüyor; bu plan onların arkasından gelir ve onların yerine geçmez.

İki yön var:

- **Küçük yaş (3-4, 5-6): görsel betim.** Bu çocuk masalı dinler ve resme bakar. İleride sayfa görseli, sayfadaki anahtar sözcüklerden seçilecek. Metin bu yüzden somut, görülebilir şeyleri adlandırmalı ve her sayfa "burada ne görünüyor" sorusuna denetlenebilir bir cevap taşımalı.
- **Büyük yaş (7-8, 9-10): olay örgüsü.** Bu çocuk okur ve masalın iskeletini tanır. Tekrar en çok olay örgüsünde hissediliyor; çeşitlilik cümleden değil, olayların gidişinden gelmeli.

## Ölçüm: bugün nerede duruyoruz

**Sayım** (her yasal bağlama için sayfa havuzlarının çarpımı; Masal ailem, özel gün, seri ve çocuğun adı hariç):

| Yaş | Olay örgüsü (uyku / öğrenme / macera) | İçerik kurgusu | Metin varyasyonu (üst sınır) |
|---|---|---|---|
| 3-4 | 4 / 8 / 4 | 6.938 | ≈ 5,7 milyar |
| 5-6 | 4 / 16 / 6 | 9.973 | ≈ 111 trilyon |
| 7-8 | 4 / 10 / 4 | 5.647 | ≈ 118 trilyon |
| 9-10 | 4 / 10 / 4 | 5.647 | ≈ 25 trilyon |

**Okuma simülasyonu** (yaş başına 3 çocuk × 100 masal; modlar sırayla, konu "Fark etmez"; motora uygulamadaki gibi son 4 masalın kökeni ve satırları, son 12 başlık verildi):

| | 3-4 | 5-6 | 7-8 | 9-10 |
|---|---|---|---|---|
| İlk olay örgüsü tekrarı (kaçıncı masal) | 7-8 | 7-13 | 7-12 | 6-10 |
| Satırların yarısı tanıdık olan ilk masal | 7-8 | 10-13 | 10 | 11-14 |
| Daha önce okunmuş satır, 4-10. masal | %31 | %17 | %22 | %19 |
| 11-25. masal | %59 | %45 | %51 | %53 |
| 26-50. masal | %78 | %66 | %74 | %76 |
| 51-100. masal | %89 | %81 | %87 | %90 |
| Birebir aynı masal | 0 | 0 | 0 | 0 |

**Sonuç.** Trilyonlar gerçek çeşitlilik değil. Tekrarı üç şey getiriyor:

1. **Olay örgüsü az.** Uyku öncesi her yaşta 4; 7-10 macera 4. Modlar dönüşümlü okununca dördüncü uyku masalından sonra tekrar başlıyor.
2. **Satır soğuması kısa.** Motor yalnızca son 4 masalın satırlarını geri itiyor (`SelectionScoring.cooldownWindow`); 5. masaldan önceki satır yeniden serbest.
3. **Sayfa havuzu dar.** Bir hücrede (beat × bant × rol × uzunluk × koşullar) çoğu zaman 4-10 satır var. Aynı olay örgüsü 3-4 kez okununca sayfa biter.

## Hedefler (A8'de aynı simülasyonla ölçülür)

| | Bugün (9-10) | Hedef |
|---|---|---|
| İlk olay örgüsü tekrarı | 6-10. masal | ≥ 20. masal (her yaşta) |
| Satırların yarısı tanıdık | 11-14. masal | ≥ 30. masal |
| 51-100. masalda tanıdık satır | %81-90 | ≤ %60 |
| 3-4'te 4-10. masalda tanıdık satır | %31 | ≤ %15 |
| Görsel anahtarı olan sayfa (3-6 yaş) | 0 | %100 |

## Kararlar

- **Tüzükler kalır.** 3-4: tek olay, tek sorun, çıkarım yok. 7-10: kimse çocuğu övmez, yol arkadaşı yardım eder ama çözmez. Sakin UX: tehlike, korku, geri sayım yok; büyük yaşta da "düğüm" bir engeldir, tehdit değil.
- **Görsel API'siz ve önceden çizilmiş (karar: 20 Kasım 2026, Batuhan).** Sayfa görseli, bir kez çizilip uygulamaya gömülen görsellerden motorun kararıyla seçilir; masal başına görsel üretimi yok. Sayfa resmi katmanlıdır: arka plan ve tek odak (yol arkadaşı ya da nesne, hâliyle); tek tam sahne değil. **Çocuk figürü yok** (karar: Batuhan, 20 Kasım 2026: avatar sistemiyle olmadı); resim masalın öğelerinden kurulur. **İş bölümü:** çizimleri Batuhan ChatGPT ile yaptırır; geri kalan her şey kodda. Motor *ne* gösterileceğine karar verir (anahtar, hâl, poz); uygulama anahtarı çizime çevirir. Motor paketi görsel dosyalarını bilmez.
- **Anahtar metinden aranmaz, veriden gelir.** Görseli seçen, sayfanın bağladığı kayıtlar (mekân, yol arkadaşı, keşif) ve satırın bildirdiği anahtarlardır. Metindeki kelime yalnızca yazım denetimidir. Anahtar sözlüğü kapalı ve denetlidir: serbest metin değil, kimlikli kelimeler.
- **Saklanan metin kayıttır** (K1). Yeni satırlar ve yeni seçim kuralları eski masalları değiştirmez; seed kayması kullanıcıyı etkilemez.
- **Önce ölçüm.** Her faz simülasyonu yeniden koşar ve DEMO_CHANGELOG'a önce/sonra sayısını yazar.
- **Yapılmayacaklar:** LLM ile metin, sayfa başına üretilen görsel, dallanan anlatı, çocuğun seçim yaptığı "kendi maceranı seç".

## Fazlar

Her faz ayrı dalda (`anlati-N-ad`), DEMO_CHANGELOG kaydı ve commit ile biter. Testler plan sonunda bir kez tam koşulur; ara fazlarda yalnızca ölçüm testi koşulur.

| Faz | Amaç | Yaş | Büyüklük | Bağımlılık |
|---|---|---|---|---|
| A0 | Okuma simülasyonu kalıcı rapor | hepsi | K | yok |
| A1 | Satır soğuması ayrı pencere | hepsi | K | A0 |
| A2 | Görsel anahtar sistemi: sözlük, kayıt ve satır anahtarları | hepsi, 3-6 önce | O | yok |
| A2g | Sayfa görsel planı (motor) | hepsi | O (motor) | A2 |
| A9 | Görsel katalog ve okuyucuda birleştirme (uygulama), pilot dünya | 3-6 önce | B (çizim) | A2g |
| A3 | Görsel betim katmanı (`sceneDetails`) | 3-6 | B (içerik) | A2 |
| A4 | Küçük yaş sayfa havuzları | 3-6 | B (içerik) | A2 |
| A5 | Olay örgüsü modeli: düğüm ve tohum-hasat | 7-10 | O (motor) | A0 |
| A6 | Yeni olay örgüleri | hepsi, önce 7-10 macera ve uyku | B (içerik) | A5 |
| A7 | Dünya satırlarını ara sayfalara yaymak | hepsi | O (içerik) | yok |
| A8 | Ölçüm ve kabul | hepsi | K | hepsi |

A1, A2 ve A5 paralel yürüyebilir (dosyaları ayrı). A3 ve A4 aynı beat dosyalarına dokunduğu için ardışık. A9'un çizim işi A2g biter bitmez İrem'le paralel başlar; kod tarafı çizimler gelmeden yer tutucuyla çalışır.

### A0: Okuma simülasyonu kalıcı rapor

**Bugün.** Simülasyon geçici bir testti (20 Kasım), commit'lenmedi.

**Yapılacak.** `ReadingSequenceReport` (motor, saf): yaş, mod dağılımı ve masal sayısı alır; uygulamanın geçmiş penceresini kullanır; yukarıdaki tabloyu döndürür. `ReadingSequenceTests` raporu bugünkü değerlerle sabitler (eşitlik değil, eşik: bir içerik turu sayıyı kötüleştirirse kırılır). Mod dağılımı iki biçimde: dönüşümlü ve "akşamları uyku öncesi ağırlıklı" (%60 uyku).

**Kabul.** Rapor 4 yaş × 2 dağılım × 100 masal; bir dakikanın altında.

### A1: Satır soğuması ayrı pencere

**Bugün.** Köken ve satır aynı pencereyi paylaşıyor: son 4 masal.

**Yapılacak.** İki pencere: köken (olay örgüsü, mekân, arkadaş, keşif) 4 kalır; satır penceresi 12-20 masal (A0 ile seçilir). `StoryOrigin.variantIDs` zaten saklanıyor; köprüde `recent.prefix(4)` yerine satırlar için ayrı `prefix`. Ağırlık yaşla azalır (en yeni satır en soğuk).

**Kabul.** Motor davranışı geçmiş yokken bit bit aynı. A0'da "yarısı tanıdık" eşiği ileri kayar. Beklenti: havuz büyümeden de birkaç masal kazanç; asıl kazanç A4 ile.

### A2: Görsel anahtar sistemi

**Amaç.** Her sayfa "burada ne görünüyor" sorusuna kimlikli anahtarlarla cevap versin; görsel bu anahtarlardan seçilsin. Örnek: masalın keşfi yırtık harita ise sayfa `vk_torn_map` anahtarını taşır ve okuyucu yırtık harita çizimini koyar.

**Önerinin değerlendirmesi (20 Kasım 2026).** Batuhan'ın önerisi: sayfadaki "yırtık harita" kelimesi görülünce hazır yırtık harita görseli o sayfaya gelsin, offline, motor yapsın. Özü doğru ve plan onu benimsiyor. İki noktada değişiyor:

1. *Anahtar metinden aranmaz.* Türkçe çekim ("haritayı", "haritanın", "haritada") ve yanlış eşleşme ("haritada olmayan bir şey" satırı bir harita göstermemeli) metin aramasını kırılgan yapar. Motor zaten sayfanın neyi bağladığını biliyor (`object_torn_map_001`); anahtar oradan gelir. Metin taraması yalnızca yazım denetimi: satırda sözlükteki bir kelime geçiyorsa satır o anahtarı bildirmek zorunda (ve tersi).
2. *Sayfa başına tek nesne görseli tekrara düşer.* Keşif sekiz sayfanın altısında geçer; her sayfada ve o keşfi kullanan her masalda aynı görsel çıkardı. Bunun yerine katmanlı sayfa resmi (A2g): arka plan (mekân) ve sayfanın rolüne göre seçilen tek odak, kendi hâliyle (nesne `found` / `close` / `whole`, yol arkadaşı `greet` / `together` / `glad`). Çocuk figürü yok.

**Model.**

- **Sözlük** `visual_vocabulary.json` (motor kaynağı): kimlik, Türkçe ad ve çekim kökü, İngilizce çizim adı, tür (`place`, `being`, `object`, `action`, `light`, `weather`), izinli hâller (ör. yırtık harita: `found`, `held`, `piece`), yaş uygunluğu. Başlangıç: bütün kayıtların anahtarı (~115) + satırlardan çıkan ~150 ek kelime (güvercin, fener, merdiven…).
- **Kayıt anahtarı:** mekân, yol arkadaşı ve keşif birer `visualKey` taşır (zorunlu; yoksa bütünlük denetimi hata verir). Mekân ayrıca arka plan anahtarı ve zaman/ışık bilgisi taşır.
- **Satır anahtarı:** satır, yalnızca kendisinin adlandırdığı ek şeyleri `visualKeys` ile bildirir (`{{discovery.name}}` kayıttan gelir, satıra yazılmaz). İsteğe bağlı `visualState` keşfin bu sayfadaki hâlini söyler ("haritanın öbür yarısını buldu" → `piece`).
- **Doğrulayıcı (yazım denetimi):** satırın metni sözlüğün Türkçe köklerine göre taranır (`TurkishGrammar` çekim eşlemesi); geçen sözlük kelimesi anahtarda yoksa hata, anahtarda olup metinde geçmeyen hata. Bu, Batuhan'ın "metinde görünce" fikrinin güvenli yeri: çalışırken değil, yazarken.
- **Mevcut satırlar:** ~2.200 satıra anahtar betikle önerilir, elle onaylanır.

**Kabul.** Her kayıtta anahtar; sözlük dışı anahtar yok; doğrulayıcı bütün korpusta temiz; eski masallar değişmez.

### A2g: Sayfa görsel planı (motor)

**Amaç.** Motor her sayfa için ne çizileceğine karar versin; karar masalla birlikte saklansın (K1: saklanan masal kayıttır, görseli de değişmez).

**Model.** `ComposedPage.picture`:

- `background`: mekân anahtarı + zaman (`day`, `evening`, `night`; uyku arkında her zaman akşam/gece)
- `focus`: tek anahtar + hâl
- `focus` yol arkadaşıysa hâli poz: `greet`, `together`, `glad` (sayfa rolünden)
- `extras`: en çok iki küçük anahtar (satırın bildirdikleri), yalnızca 3-6 yaşta

**Odak seçimi** (deterministik, sayfa rolüne göre):

| Sayfa rolü / beat | Odak |
|---|---|
| `hook` (`notice_anomaly`) | keşif, `found` |
| `discovery` (`examine`, `approach`) | keşif, `close` |
| `companion` (`meet_companion`) | yol arkadaşı, `greet` |
| `problem`, `attempt`, `challenge` | satırın `visualState`'i varsa keşif, yoksa satır anahtarı, yoksa yol arkadaşı `together` |
| `resolution` | keşif, `close` ya da `whole` |
| `emotional_ending`, `bedtime_transition` | arka plan akşam + yol arkadaşı `glad` |

Aynı odak art arda iki sayfada aynı hâlde gelmez; gelecekse ikinci sayfa geniş sahneye döner.

**Kayıt.** Uygulama `StoryPage.picture`'ı saklar; mevcut `imagePrompt` (`visualScene`) dokunulmadan kalır.

**Kabul.** Her sayfada bir plan; odak seçimi testle sabit; eski masallarda plan yok ve okuyucu bugünkü gibi davranır.

### A3: Görsel betim katmanı (`sceneDetails`), 3-6 yaş

**Amaç.** Küçük çocuğun sayfası, olayın yanında bir de "gördüğü şeyi" söylesin: renk, biçim, boyut, ses. Aynı olay farklı ayrıntıyla okunur; çeşitlilik kendiliğinden artar ve her betim görsele anahtar verir.

**Model.**

- Yeni içerik türü `sceneDetails`: mekâna, yol arkadaşına ya da keşfe bağlı kısa betim cümleleri. Her biri `visualKeys`, bant (3-4 / 5-6), zaman (sabah, akşam, fark etmez) ve isteğe bağlı mekân özelliği taşır. Örnek (Saat Kuleli Meydan, 3-4): "Güvercinler taşların üstünde yürüyordu."
- **Kompozitör:** 3-4 ve 5-6'da belirli rollere (`hook`, `discovery`, `companion`, `emotional_ending`) sayfa bütçesi izin veriyorsa bir betim ekler. 3-4'te sayfa başına en çok bir, masal başına 2-3; 5-6'da masal başına 3-4. Betim olay cümlesinin önüne ya da arkasına (sayfa rolüne göre) konur.
- **Soğuma:** betim de A1 satır penceresine girer.
- Uyku öncesinde betim yalnızca sakin tür (ışık, ses, yumuşak doku); hareketli betim yok.

**İçerik.** Mekân başına 8-12, yol arkadaşı başına 4-6, keşif başına 2-3 betim, iki bant için: kabaca 900-1.100 kısa cümle. 3-4 cümlesi ≤ 8 kelime, tek görülen şey; soyut ad yok.

**Kabul.** 3-4 sayfa bütçesi (10-24 kelime) aşılmaz; A0'da 3-4'ün "4-10. masalda tanıdık satır" oranı yarıya iner.

### A4: Küçük yaş sayfa havuzları

**Amaç.** En sık okunan hücreleri doldurmak.

- A0'ın hücre dökümüyle (sayfa × bağlama türü × okunma sıklığı) en sık düşülen 30 hücre seçilir; her biri ≥ 12 satıra çıkar.
- Önce 3-4 ve 5-6 uyku öncesi (dört olay örgüsü, en sık tekrar), sonra öğrenme.
- Yeni satırlar A2 kurallarıyla yazılır: somut, `visualKeys` taşıyan.

**İçerik.** Kabaca 500-700 satır.

### A5: Olay örgüsü modeli, 7-10 yaş

**Amaç.** Yeni blueprint yazmadan olay örgüsünü çoğaltmak. Bugün bir blueprint tek bir gidiş; iki yeni yapı onu birkaç gidişe böler.

**1. Düğüm yuvası (`complication`).** Blueprint, çözümden önce isteğe bağlı bir "düğüm" sayfası bildirir: `complicationSlot` ve hangi düğüm türlerini kabul ettiği. Düğüm türleri bir katalogdur, her biri kendi beat'leri ve durum koşulu ile:

- yanlış yol (dönüp başka yol denenir)
- eksik parça (bir şey tamamlanmadan olmaz)
- hava ya da saat değişir (plan yeniden kurulur)
- yol arkadaşı farklı düşünür (iki fikir birleşir)
- ikinci bir ipucu ilkini yalanlar (yalnızca 9-10)

Tehdit ve tehlike yok; düğüm her zaman çocuğun düşünerek çözdüğü bir engeldir. Seçici düğümü olay örgüsü kimliğine katar: dört macera blueprint'i × 3-4 düğüm = 12-16 farklı gidiş.

**2. Tohum ve hasat (`plant` / `payoff`).** Erken bir sayfa bir ayrıntı eker (keşfin bir özelliği, yol arkadaşının bir sözü), çözüm sayfası onu kullanır. Durum modeline iki olgu: `detailPlanted(kind)`, `detailPaidOff(kind)`. Doğrulayıcı: ekilen hasat edilmeli, ekilmeyen hasat edilemez. Bu, büyük çocuğun "aa, o şey işe yaradı" anını verir ve aynı olay örgüsünde çözümü değiştirir.

**3. Olay örgüsü kimliği.** `mechanismKey` + düğüm türü + tohum türü. Soğuma ve A0 ölçümü bu kimliğe bakar; aynı blueprint farklı düğümle "farklı olay örgüsü" sayılır, ama aynı düğüm üst üste gelmez.

**Kapsam dışı.** 3-6 yaş (tüzük: tek olay); dallanan anlatı.

**Kabul.** 7-10'da düğümsüz masallar bit bit aynı; her düğüm türü her uygun blueprint'te en az bir bağlamada kuruluyor; bütçe (7-8: 8 sayfa, 9-10: 10 sayfa) korunuyor (düğüm yeni sayfa değil, bir orta sayfanın yerine geçer).

### A6: Yeni olay örgüleri

Öncelik ölçümden: en sık tekrar eden yerler.

| Mod | Yaş | Bugün | Ek | Not |
|---|---|---|---|---|
| Uyku öncesi | her yaş | 4 | +3 | Uyku arkının içinde (ses dinlemek, günü saymak, ayı yollamak gibi); A3 betimleri en çok burada işe yarar |
| Macera | 7-8, 9-10 | 4 | +4 | Ör. harita çizmek, bir mesajı yerine ulaştırmak, kayıp bir sesi bulmak, bir yeri birine tanıtmak |
| Macera | 3-4 | 4 | +2 | Tek olay: birlikte bulmak, birlikte götürmek |
| Öğrenme | 3-4 | 8 | +2 | 3-4 Meslekler (bugün sıfır mekanizma) ve Bilim ve uzay (bir mekanizma) için |

Her yeni şekil kendi bandının bütün beat'lerinde ≥ 4 satırlık hücreyle gelir (`BoundPoolTests`).

**İçerik.** Kabaca 25 blueprint, 600-900 satır.

### A7: Dünya satırlarını ara sayfalara yaymak

Bugün dünya satırları (`settingTags`) yalnızca sayfa 1 ve kapanışta. `meet_companion` ve keşif sayfalarına (`examine`) her dünya için bant başına 3-4 satır: masal ortasında da şehirde ya da kalede olduğu hissedilsin. Gökyüzü ve uzay, Sporlar ve Denizin altı da aynı muameleyi alır.

**İçerik.** Kabaca 300-400 satır.

### A9: Görsel katalog ve okuyucuda birleştirme (uygulama)

**Amaç.** Anahtarı çizime çevirmek. Mevcut yapıların üstüne: `art_kits.json`'un "spot" yuvaları (şeffaf zeminli küçük sahne), ve `scene_library.json` (avatar katmanı kullanılmaz). Paralel sistem kurulmaz.

**Model.**

- `visual_assets.json` (uygulama): anahtar → hâl → görsel adları (her hâlde 1-3 çeşit, deterministik seçim), üslup seti, durum (`ready` / `pending`). Asset catalog ad alanı `Visual/`.
- **Birleştirici** (`PagePictureView`, okuyucu): arka plan + odak + en çok iki ek; çocuk figürü yok. Odak arka planın alt ortasına oturur; metin alanına taşmaz. Mevcut `StorySceneView`'in katman ve ayak noktası düzeni kullanılır, avatar katmanı kullanılmaz.
- **Yedek:** çizimi olmayan anahtar dünyanın `Storybook` motiflerine düşer (bugünkü sanat seti davranışı); hiçbir sayfa boş çerçeve göstermez.
- **Erişilebilirlik:** her görselin Türkçe tarifi sözlükten (`altText`); süs katmanları gizli.

**Çizim.** Batuhan ChatGPT ile, bir kez, tek üslupta (stil sayfası referans, aynı üslup cümlesi); liste ve istemler `docs/art/GORSEL_PILOT_LISTESI.md`. Fotoğraf değil, illüstrasyon. Masal başına görsel üretimi yok; çizimler uygulamayla gelir.

**Pilot.** 5-6 macera, Fısıldayan Orman. Motorla ölçüldü: bu dünyada 13 yol arkadaşı ve 15 nesne bağlanıyor. Kademe 1: 2 arka plan + 6 arkadaş × 3 poz + 6 nesne (9 görsel) = 29; kademe 2: 42; toplam 71. Pilot okuyucuda görülür, sonra dünya dünya genişler.

**Tam kapsam (kabaca).** Birleşik katalogda 36 mekân × 2 zaman, 34 yol arkadaşı × 3 poz, 43 keşif × 2-3 hâl, ~150 ek kelime: 400-450 çizim. Uygulama boyutu için çizimler vektör ya da sıkıştırılmış PNG; gerekirse dünya paketleri uzaktan içerik (FAZ 15) ile.

**Kabul.** Pilot dünyada her sayfa görselli, yedeğe düşen sayfa yok; VoiceOver tarifi okuyor; görselsiz eski masallar bugünkü gibi.

### A8: Ölçüm ve kabul

A0 raporu yeniden koşulur; hedef tablosu karşılanmıyorsa eksik kalan hücreler listelenir. Tam motor testi, `BoundPoolTests` ve uygulama testleri bir kez koşulur.

## İçerik bütçesi (kabaca)

| Faz | Satır / kayıt |
|---|---|
| A2 | ~265 sözlük kelimesi (~115 kayıt + ~150 ek); mevcut ~2.200 satıra anahtar (betik + elle denetim) |
| A9 | Pilot 71 çizim (kademe 1: 29); tam kapsam 400-450 çizim (Batuhan, ChatGPT) |
| A3 | 900-1.100 betim cümlesi |
| A4 | 500-700 satır |
| A6 | ~25 blueprint, 600-900 satır |
| A7 | 300-400 satır |

Toplam yeni metin 2.300-3.100 satır: bugünkü havuzun (2.227) aşağı yukarı iki katı. Yazı hızı yol haritasının sınırlayıcısıdır; sıra ölçümün gösterdiği tekrar sıklığına göre.

## Batuhan'ın kararı gereken sorular

1. ~~Görsel yolu~~ **Karara bağlandı (20 Kasım 2026, Batuhan):** önceden çizilmiş, API'siz görseller; sayfa resmi katmanlı (arka plan + tek odak ve hâli), çocuk figürü yok; çizimleri Batuhan ChatGPT ile yaptırır.
2. **3-4 betim yoğunluğu:** sayfa başına en çok bir betim yeterli mi, yoksa bazı sayfalar yalnızca betimden mi oluşabilir ("resme bak" sayfası)?
3. **Düğüm türleri:** listedeki beş tür kabul mü? Özellikle "ikinci ipucu ilkini yalanlar" 9-10 için uygun mu?
4. **Uyku öncesi ağırlığı:** A0'ın ikinci dağılımı (%60 uyku) gerçek kullanıma yakın mı? Analitikte mod dağılımı varsa o kullanılır.
5. **23 Ekim 3-4 tavanı kararı:** H2 ile 3-4 öğrenme sekiz şekle çıktı; A6'nın 3-4 eklemeleri (Meslekler, Bilim ve uzay) bu kararın yeniden açılması demek.

## Riskler

| Risk | Önlem |
|---|---|
| Betim katmanı 3-4 sayfa bütçesini aşar | Kompozitör bütçeye göre ekler; doğrulayıcı bütçeyi zaten denetliyor |
| Anahtarlar metinle ayrışır | A2 doğrulayıcısı: metinde geçen sözlük kelimesi anahtarda olmalı, tersi de |
| Düğüm masalı gerginleştirir | Düğüm katalogu sakin tüzükle yazılır; en korumacı güvenlik ayarında gergin düğümler kapanır (`ContentSafety`) |
| Yeni satırlar eski hücre testlerini kırar | Yalnızca sona ekleme; `BoundPoolTests`, `ProseCooldownTests`, kapsam testleri her fazda |
| Görsel metinle çelişir ("harita ikiye yırtılmıştı" ama görselde bütün) | Hâl satırdan (`visualState`) gelir; doğrulayıcı keşfi değiştiren satırın hâl bildirmesini ister |
| Çizim üslubu dağılır | Tek üslup seti ve `docs/art/` kuralları; pilot onaylanmadan genişleme yok |
| Uygulama boyutu büyür | Sıkıştırma; dünya paketleri uzaktan içerikle |
| Ölçüm uzun sürer | A0 raporu ince; `BoundPoolTests` yalnızca plan sonunda |
| İçerik maliyeti | Fazlar bağımsız; A1 ve A5 içerik yazmadan kazanç getirir |
