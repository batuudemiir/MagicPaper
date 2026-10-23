# Küratörlü olgular: inceleme dosyası

**Tarih:** 23 Ekim 2026 · **Dal:** `faz-21-varyasyon` · **Durum:** **karara bağlandı** (23 Ekim)
**Kural:** bu dosyadaki hiçbir olgu, onaylanmadan canlı havuza girmez.

B turunun iki konusu gerçek bilgi istiyor: "Bilim ve uzay" (öğrenelim) ve "Yeni
ülkeler ve şehirler" (macera). Plan, inşadan önce kaynaklı bir inceleme dosyası
şart koşuyordu. Bu o dosya.

---

## 1. Önce bir sınır: olgular yalnızca 5-6'ya yazılabilir

3-4 bandına olgu yazmak bugün **ölü içerik üretir**, ve sebebi içerik eksikliği
değil yapı:

- Bir olgunun masala girdiği yer, çocuğun bir şeyi anladığı beat'tir
  (`insight`, `succeed`) ve bu beat'ler `unexplained` ailesinin.
- `unexplained` yalnızca öğrenelim modunda, ve 3-4'te öğrenelimin tek ailesi
  `charge` (bakım). 3-4 korpusunun tüzüğü de çıkarımı açıkça yasaklıyor:
  *"tek olay, tek sorun, çıkarım yok."*
- Yani 3-4'te bir olguyu taşıyacak sayfa yok, ve olsa bile o bandın tüzüğüne
  aykırı olurdu.

**Sonuç:** aşağıdaki olgular 5-6 için yazıldı. 3-4'e olgu yazmak, o bandın
tüzüğünü değiştirmeyi gerektirir ve bu ayrı bir karardır (bkz. 23 Ekim kaydı,
3-4 tavanı).

---

## 2. Olguyu neyin taşıyacağı: `CatalogFact` önerisi

Olgu taşıyıcısı olmadan olgu listesi, A turunda temizlediğimiz ölü içeriğin
aynısı olur. Önerilen taşıyıcı, motorda **zaten çalışan** bir deseni kopyalıyor:
sözlük (FAZ 17, "Yeni kelimeler").

Sözlük şöyle çalışıyor: `CatalogGlossaryEntry` kaydı var (id, terim, anlam,
bantlar), bir satır `CatalogVariant.words` ile hangi kaydı öğrettiğini
**bildiriyor**, ve okuyucu kelimeyi sayfada işaretliyor. Hiçbir şey tahmin
etmiyor; bir yazar o kelimenin bu bantta bir cümle açıklamayı hak ettiğine
karar vermiş.

Olgu aynı deseni ister, artı bir şey: **nereden geldiği.**

```swift
public struct CatalogFact: Codable, Sendable, Hashable, Identifiable {
    public let id: ContentID
    /// Olgu, bizim cümlemizle, bu bant için. Kaynak metni DEĞİL.
    public let statement: String
    /// Hangi bantlar için yazıldı. Boş = her bant (bugün kullanılmıyor).
    public let bands: [AgeBand]
    /// Kaynağın adı ve adresi. İkisi birden şart: ad olmadan adres bir gün
    /// ölü bağlantıya döner, adres olmadan ad doğrulanamaz.
    public let sourceName: String
    public let sourceURL: String
    /// Kaynakta doğrulandığı gün (ISO-8601). "Ne zaman doğruydu" sorusunun
    /// cevabı; olgular eskiyor.
    public let verifiedOn: String
    /// İnceleme durumu. `approved` olmayan olgu seçime hiç girmez.
    public let review: Review
    public enum Review: String, Codable, Sendable { case draft, sourceUnverified, approved }
}
```

Ve satır tarafında, `words`'ün tam karşılığı:

```swift
/// Bu satırın öğrettiği olgu(lar). Sözlükteki `words` gibi: satır bildirir,
/// hiçbir şey tahmin etmez.
public let facts: [ContentID]
```

**Neden `explainedBy` değil:** `CatalogObject.explainedBy` zaten var ama başka
bir soruyu cevaplıyor — hangi *mekân özelliği* bu keşfi açıklar (yapısal
açıklama). Olgu ise dünya hakkında bir iddia ve kaynak ister. İkisini aynı
alana koymak, A turunda ayırdığımız eksenleri geri karıştırmak olur.

**Şema denetimi (plan §F):** `CatalogIntegrity`'ye iki kural önerilir —
(1) `facts` ile bildirilen her kimlik tanımlı olmalı (tanımsızsa **error**,
`unknown_interest` gibi), (2) `review != approved` olan bir olguyu bildiren
satır seçime girmemeli ve bu **error** olmalı: onaysız olgu, tutulamayan bir
sözden daha kötüsüdür — yanlış bilgidir.

---

## 3. Bilim ve uzay: NASA Space Place

Hepsi 23 Ekim 2026'da kaynağında okundu. Cümleler bizim; kaynak metni
kopyalanmadı. Hedef bant 5-6.

| # | Olgu (bizim cümlemizle, 5-6) | Kaynak | Doğrulama | Durum |
|---|---|---|---|---|
| F1 | Ay'ın kendi ışığı yoktur. Gördüğümüz ışık, üstüne düşen güneş ışığıdır. | NASA Space Place, "All About the Moon" | 2026-10-23 | onay bekliyor |
| F2 | Ay her gece başka bir şekilde görünür, çünkü aydınlanan yüzünün her gece başka bir kadarını görüyoruz. | NASA Space Place, "All About the Moon" | 2026-10-23 | onay bekliyor |
| F3 | Ay'ın hep aynı yüzünü görürüz, çünkü Ay kendi çevresinde dönerken Dünya'nın çevresinde de aynı hızda dolanır. | NASA Space Place, "All About the Moon" | 2026-10-23 | onay bekliyor |
| F4 | Ay'da neredeyse hiç hava yoktur. Rüzgâr olmadığı için çukurları hiçbir şey düzeltmez; oldukları gibi kalırlar. | NASA Space Place, "All About the Moon" | 2026-10-23 | onay bekliyor |
| F5 | Güneş de bir yıldızdır. Bize en yakın yıldız olduğu için bu kadar büyük ve parlak görünür. | NASA Space Place, "All About the Sun" | 2026-10-23 | onay bekliyor |
| F6 | Güneş'in ışığı bize sekiz dakikadan biraz fazla bir zamanda ulaşır. | NASA Space Place, "All About the Sun" | 2026-10-23 | onay bekliyor |
| F7 | Gökyüzünde kayan yıldız gördüğümüzde aslında bir yıldız düşmez. Gördüğümüz, hızla gelen küçük bir taşın çevresindeki havanın kızarıp parlamasıdır. | NASA Space Place, "What Is a Meteor Shower?" | 2026-10-23 | onay bekliyor |
| F8 | Yer çekimi gözle görülmez ama her şeyi aşağı, Dünya'nın ortasına doğru çeker. Zıpladığımızda yere geri inmemizin sebebi odur. | NASA Space Place, "What Is Gravity?" | 2026-10-23 | onay bekliyor |

**Katalogda olan iki tanesi (23 Ekim 2026).** Sekizi de onaylı, ama katalog
yalnızca bir çocuğa **ulaşabilen** olguyu taşıyor:

| Olgu | Bağlı olduğu keşif |
|---|---|
| F7 (kayan yıldız) | `object_flickering_light_001` — titrek bir ışık |
| F5 (Güneş bir yıldızdır) | `object_star_stone_001` — yıldız taşı |

Diğer altısı burada bekliyor, ve sebebi kendileri değil **konuları**: havuzda
Ay yok, Güneş yok, düşen bir şey yok. Konusu olmayan bir olguyu katalogda
tutmak, A turunda temizlenen ölü içeriğin aynısı olurdu — ve `CatalogIntegrity`
bunu zaten uyarıyor (`fact_reaches_no_discovery`). Keşif yazıldığı gün olgu
katalogda yerini alır; onayı zaten var.

Adresler:
- https://spaceplace.nasa.gov/all-about-the-moon/en/
- https://spaceplace.nasa.gov/all-about-the-sun/en/
- https://spaceplace.nasa.gov/meteor-shower/en/
- https://spaceplace.nasa.gov/what-is-gravity/en/

**Bilerek alınmayanlar ve sebepleri:**

- *Ay'ın nasıl oluştuğu* (Dünya ile Mars büyüklüğünde bir cismin çarpışması):
  kaynak "bilim insanları buna inanıyor" diyor, yani kesinleşmiş değil. Bir
  çocuk masalında "öyle olmuş" diye anlatılamaz, "belki öyle olmuş" ise beş
  yaşındakine anlatılacak bir şey değil.
- *Mesafeler ve büyüklükler* (384 bin kilometre, Güneş Dünya'nın yüz katı
  genişliğinde): sayı beş yaşındaki için bilgi değil ses. Dilde "çok uzak" ve
  "kocaman" bu bantta daha doğru, ve o cümleler olgu kaydına gerek duymuyor.
- *Ay'a ilk ayak basılması (1969)*: tarih olgusu, bilim olgusu değil; ve bu
  bandın masalında tarih taşıyacak bir yer yok.
- *Ay'ın kutuplarındaki buz, yer çekiminin altıda bir olması*: doğru ama bu
  bantta hikâyeye girecek bir yeri yok. Olgu yazmak için değil, masal yazmak
  için olgu seçiyoruz.

---

## 4. Ülkeler ve kültür: UNESCO — **kaynağında doğrulanamadı**

Bunu açıkça yazmam gerekiyor: **UNESCO'nun kendi sitesine buradan
erişilemiyor.** `whc.unesco.org` otomatik isteklere HTTP 403 döndürüyor (hem
ülke listesi hem tek tek kayıt sayfaları denendi, 23 Ekim 2026). Yani
aşağıdaki iki örneğin provenansı **birincil kaynaktan değil**, resmî ama
ikincil bir kaynaktan geliyor.

| # | Olgu (taslak) | Kaynak | Durum |
|---|---|---|---|
| T1 | Göbeklitepe, Şanlıurfa'da. Yaklaşık on bir bin yıl önce yapılmış, yani bilinen en eski büyük taş yapılardan biri. | T.C. Dışişleri Bakanlığı basın duyurusu No: 176, 1 Temmuz 2018 (**ikincil**) | kaynak doğrulaması bekliyor |
| T2 | Göbeklitepe 2018'de UNESCO Dünya Mirası Listesi'ne girdi. | aynı duyuru (**ikincil**) | kaynak doğrulaması bekliyor |

Bir insanın açıp doğrulaması gereken adresler:
- https://whc.unesco.org/en/list/1572/ (Göbeklitepe kaydı)
- https://whc.unesco.org/en/statesparties/tr (Türkiye'nin kayıtları)

**Önerim:** "Yeni ülkeler ve şehirler" konusunu bu turda açmayalım. Bilim
tarafı kaynağında okunmuş sekiz olguyla hazır; kültür tarafı için elimizde
yalnızca ikincil kaynak var ve bir çocuk kitabına "UNESCO şöyle diyor" diye
giren bir cümlenin UNESCO'da okunmuş olması gerekir. Bu, kapsamı küçültme
önerisi değil: yanlış provenansla açılmış bir konu, hiç açılmamış bir konudan
kötüdür.

---

## 5. Yazım kuralları (olgu yazan herkes için)

1. **Kaynak metni kopyalanmaz.** Olgu okunur, kapatılır, kendi cümlemizle
   yazılır. Bu dosyadaki sekiz cümlenin hiçbiri kaynaktan alınmadı.
2. **Bant başına ayrı cümle.** Aynı olgunun 5-6 cümlesi 7-8'e kopyalanmaz;
   yeniden yazılır ya da o bant için yazılmaz.
3. **Sayı, bilgi olduğu yerde.** "Sekiz dakika" bir çocuğun kavrayabileceği
   bir süre; "384.400 kilometre" değil. Kavranmayan sayı olgu değil süstür.
4. **Belirsizlik girmez.** Kaynak "bilim insanları buna inanıyor" diyorsa o
   olgu bu bantta yazılmaz. Masal "belki" diyemez, çocuk onu "öyle" duyar.
5. **Doğrulama tarihi zorunlu.** Olgular eskir; kaydı olmayan olgu bir gün
   sessizce yanlışa döner.
6. **Onaysız olgu seçime girmez**, ve bu kodla zorlanır (bkz. §2 şema
   denetimi) — bir insanın hatırlamasına bırakılmaz.

---

## 6. Karar (23 Ekim 2026)

Batuhan kararı ürünün vizyonuna göre vermemi istedi. Üçü de evet, ve biri bir
kısıtla.

**1. F1-F8 onaylandı.** Sekizi de kaynağında okundu, kendi cümlemizle yazıldı,
belirsizlik taşımıyor ve 5-6'da taşınabilir. `review: approved`.

**Ama bir kısıtla, ve kısıt üründen geliyor.** CLAUDE.md'nin ilk satırı şunu
söylüyor: MagicPaper "önce premium bir çocuk yayıncılığı deneyimi, sonra bir
yapay zekâ ürünü" gibi hissettirmeli — ve "genel amaçlı bir masal üretici
değil". Buradan çıkan kural:

> **Bir masalda en çok bir olgu, ve olgu masalın konusu olamaz.**

Olgu, çocuğun *fark ettiği* şey olur; kitabın *öğrettiği* şey olmaz. İki olgu
taşıyan sayfa bir ders sayfasıdır, kahramanı olan bir ders. Bu kural
`CatalogIntegrity`'de denetlenir (sayfa başına en çok bir `facts` kimliği),
çünkü editoryal bir temenni olarak bırakılırsa ilk sıkışan turda bozulur.

**2. Taşıyıcı önerildiği gibi kurulsun:** `CatalogFact` + `CatalogVariant.facts`,
sözlüğün çalışan deseniyle. Şema denetiminin iki kuralı da **error** seviyesinde
kurulur (tanımsız kimlik; onaysız olguyu bildiren satırın seçime girmesi).

**3. "Yeni ülkeler ve şehirler" ertelendi.** Gerekçe provenans: ikincil kaynağı
birincil gibi göstermek, konuyu hiç açmamaktan kötü. UNESCO kaydı bir insan
tarafından açılıp okunduğunda konu yeniden ele alınır; doğrulanacak adresler
§4'te.

**Değişmeyen kural:** `review: approved` olmayan olgu seçime girmez, ve bu kodla
zorlanır.
