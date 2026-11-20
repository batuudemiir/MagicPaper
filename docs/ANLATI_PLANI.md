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
- **Görsel betim, anahtar sözlüğü ve çizim üç ayrı şeydir.** Bu plan metni ve anahtarları hazırlar; çizimi (B2 sahne kütüphanesi ya da başka bir yol) seçmez. Anahtar sözlüğü kapalı ve denetlidir: serbest metin değil, kimlikli kelimeler.
- **Saklanan metin kayıttır** (K1). Yeni satırlar ve yeni seçim kuralları eski masalları değiştirmez; seed kayması kullanıcıyı etkilemez.
- **Önce ölçüm.** Her faz simülasyonu yeniden koşar ve DEMO_CHANGELOG'a önce/sonra sayısını yazar.
- **Yapılmayacaklar:** LLM ile metin, sayfa başına üretilen görsel, dallanan anlatı, çocuğun seçim yaptığı "kendi maceranı seç".

## Fazlar

Her faz ayrı dalda (`anlati-N-ad`), DEMO_CHANGELOG kaydı ve commit ile biter. Testler plan sonunda bir kez tam koşulur; ara fazlarda yalnızca ölçüm testi koşulur.

| Faz | Amaç | Yaş | Büyüklük | Bağımlılık |
|---|---|---|---|---|
| A0 | Okuma simülasyonu kalıcı rapor | hepsi | K | yok |
| A1 | Satır soğuması ayrı pencere | hepsi | K | A0 |
| A2 | Görsel anahtar sözlüğü ve `visualKeys` | 3-6 önce | O | yok |
| A3 | Görsel betim katmanı (`sceneDetails`) | 3-6 | B (içerik) | A2 |
| A4 | Küçük yaş sayfa havuzları | 3-6 | B (içerik) | A2 |
| A5 | Olay örgüsü modeli: düğüm ve tohum-hasat | 7-10 | O (motor) | A0 |
| A6 | Yeni olay örgüleri | hepsi, önce 7-10 macera ve uyku | B (içerik) | A5 |
| A7 | Dünya satırlarını ara sayfalara yaymak | hepsi | O (içerik) | yok |
| A8 | Ölçüm ve kabul | hepsi | K | hepsi |

A1, A2 ve A5 paralel yürüyebilir (dosyaları ayrı). A3 ve A4 aynı beat dosyalarına dokunduğu için ardışık.

### A0: Okuma simülasyonu kalıcı rapor

**Bugün.** Simülasyon geçici bir testti (20 Kasım), commit'lenmedi.

**Yapılacak.** `ReadingSequenceReport` (motor, saf): yaş, mod dağılımı ve masal sayısı alır; uygulamanın geçmiş penceresini kullanır; yukarıdaki tabloyu döndürür. `ReadingSequenceTests` raporu bugünkü değerlerle sabitler (eşitlik değil, eşik: bir içerik turu sayıyı kötüleştirirse kırılır). Mod dağılımı iki biçimde: dönüşümlü ve "akşamları uyku öncesi ağırlıklı" (%60 uyku).

**Kabul.** Rapor 4 yaş × 2 dağılım × 100 masal; bir dakikanın altında.

### A1: Satır soğuması ayrı pencere

**Bugün.** Köken ve satır aynı pencereyi paylaşıyor: son 4 masal.

**Yapılacak.** İki pencere: köken (olay örgüsü, mekân, arkadaş, keşif) 4 kalır; satır penceresi 12-20 masal (A0 ile seçilir). `StoryOrigin.variantIDs` zaten saklanıyor; köprüde `recent.prefix(4)` yerine satırlar için ayrı `prefix`. Ağırlık yaşla azalır (en yeni satır en soğuk).

**Kabul.** Motor davranışı geçmiş yokken bit bit aynı. A0'da "yarısı tanıdık" eşiği ileri kayar. Beklenti: havuz büyümeden de birkaç masal kazanç; asıl kazanç A4 ile.

### A2: Görsel anahtar sözlüğü ve `visualKeys`

**Amaç.** Her sayfa "burada ne görünüyor" sorusuna kimlikli kelimelerle cevap versin; ileride görsel bu anahtarlardan seçilsin.

**Model.**

- **Sözlük** `visual_vocabulary.json`: kimlik, Türkçe ad, İngilizce çizim adı, tür (yer, canlı, nesne, eylem, ışık/zaman, hava), yaş uygunluğu. Örnek: `vk_pigeon` "güvercin" / "pigeon", canlı. Başlangıç ~250 kelime; mekân etiketleri ve B2 sahne kütüphanesinin `settingTags`, `beats`, `emotions` alanlarıyla eşleşir.
- **Kayıtlar:** mekân, yol arkadaşı ve nesne `visualKeys` taşır (Saat Kuleli Meydan: `vk_clock_tower`, `vk_pigeon`, `vk_cobblestone`).
- **Satır:** `visualKeys` taşır (yalnızca satırın kendi adlandırdığı şeyler). Yer tutucu (`{{setting.name}}`) anahtarını kayıttan alır.
- **Motor:** `ComposedPage.visualKeys` = satırların anahtarları + adlandırılan kayıtların anahtarları, sıralı ve tekilleştirilmiş. Uygulama bunu `StoryPage`'e yazar (henüz kullanmaz).
- **Doğrulayıcı:** satırda geçen ve sözlükte karşılığı olan kelime anahtarda da olmalı (Türkçe kök eşlemesi `TurkishGrammar` ile); anahtarda olup metinde geçmeyen kelime hata.

**Kapsam dışı.** Çizim seçimi, görsel üretimi, okuyucuda gösterim.

**Kabul.** 3-6 yaşın her sayfasında en az bir anahtar; sözlük dışı anahtar yok; eski masallar değişmez.

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

### A8: Ölçüm ve kabul

A0 raporu yeniden koşulur; hedef tablosu karşılanmıyorsa eksik kalan hücreler listelenir. Tam motor testi, `BoundPoolTests` ve uygulama testleri bir kez koşulur.

## İçerik bütçesi (kabaca)

| Faz | Satır / kayıt |
|---|---|
| A2 | ~250 sözlük kelimesi; mevcut ~2.200 satıra anahtar (betik + elle denetim) |
| A3 | 900-1.100 betim cümlesi |
| A4 | 500-700 satır |
| A6 | ~25 blueprint, 600-900 satır |
| A7 | 300-400 satır |

Toplam yeni metin 2.300-3.100 satır: bugünkü havuzun (2.227) aşağı yukarı iki katı. Yazı hızı yol haritasının sınırlayıcısıdır; sıra ölçümün gösterdiği tekrar sıklığına göre.

## Batuhan'ın kararı gereken sorular

1. **Görsel yolu:** anahtarlar B2 sahne kütüphanesine mi (hazır sahne + avatar + yerleştirilen nesneler), başka bir görsel sisteme mi bağlanacak? A2 ikisine de uyar ama sözlüğün İngilizce adları buna göre yazılır.
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
| Ölçüm uzun sürer | A0 raporu ince; `BoundPoolTests` yalnızca plan sonunda |
| İçerik maliyeti | Fazlar bağımsız; A1 ve A5 içerik yazmadan kazanç getirir |
