# Günlük · ücretsiz masallar — yazım brief'i (FAZ 20)

MagicPaper Kids'in "Günlük" bölümü: kamu malı dünya klasikleri, Anadolu masalları ve doğu fablları. Her çocuk aynı metni okur. Kişiselleştirme yok, çocuğun adı geçmez. Ebeveyn çocuğa sesli okur, ya da okuyucunun sesli okuma özelliği okur.

## Çıktı biçimi

Her masal ayrı bir JSON dosyası: `Content/Classics/tales/<slug>.json`. UTF-8, 2 boşluk girinti.

```json
{
  "slug": "rapunzel",
  "title": "Rapunzel",
  "origin": "grimm",
  "byline": "Grimm",
  "ageMin": 5,
  "ageMax": 7,
  "minutes": 9,
  "summary": "Kulede yaşayan uzun saçlı kız, bir gün kendi yolunu bulur.",
  "shelves": ["klasikler"],
  "attribution": "Grimm Kardeşler, 1812.",
  "series": null,
  "episode": null,
  "soft": { "pages": ["…", "…"] },
  "classic": null
}
```

Alanlar:
- `origin`: grimm | perrault | andersen | aesop | anadolu | dogu | modern
- `shelves`: klasikler | anadolu | fabllar | uyku | hayvanlar. Bölümlerde `[]`.
- `series` ve `episode`: serinin slug'ı ve 1'den başlayan sıra. Tek masalda null.
- `classic`: yalnızca listede "klasik anlatım: evet" yazan masallarda. Diğerlerinde null.
- `minutes`: yumuşak anlatımın kelime sayısı / 40, yukarı yuvarla. Listedeki hedef süreye yakın olmalı (±2 dk).

Seri dosyası: `Content/Classics/series/<slug>.json`:

```json
{ "slug": "keloglan", "title": "Keloğlan Masalları", "byline": "Anadolu", "ageMin": 5, "ageMax": 8,
  "summary": "…", "shelves": ["anadolu"], "attribution": "Anadolu sözlü halk anlatısı.",
  "bookTitle": "1. Kitap", "unitName": "masal" }
```

## Sayfalar

- Bir sayfa 40-80 kelime. Yaş bandı 3-4 için 25-45 kelime.
- Sayfa içinde paragraflar boş satırla ayrılır (`\n\n`). Bir sayfada en çok 3 paragraf.
- Sayfa sayısı süreden çıkar: 9 dk ≈ 360 kelime ≈ 6-8 sayfa.
- İlk sayfa okuru masala hemen sokar. Son sayfa sıcak ve sakin bir kapanış.

## Dil ve ton

- Türkçe, cümle düzeninde. Masal dili ("Evvel zaman içinde", "Bir varmış bir yokmuş") yerinde ve ölçülü.
- Yaş bandına uygun cümle uzunluğu: 3-6 yaş için kısa cümleler, 7-10 yaş için daha uzun cümleler kullanılabilir.
- Uzun tire (—) yok. Emoji yok. Ünlem ölçülü.
- Diyalog tırnakla: "Rapunzel, Rapunzel, saçlarını sarkıt!"
- Okumak isteyen bir ebeveynin sesli okurken takılmayacağı ritim. Okumadan önce bir kez yüksek sesle okuyormuş gibi kontrol et.
- Kamu malı kaynağı yeniden anlat, kopyalama. Telifli modern çevirilerden (ör. yayınevi baskıları) cümle alma. Grimm, Perrault, Ezop, Margery Williams (1922) ve halk anlatısı kamu malı. Disney gibi modern uyarlamalara özgü öğeleri (isimler, şarkılar, sahneler) kullanma.

## Güvenlik (çok önemli)

**Yumuşak anlatım** (her masalda, varsayılan, 3-7 yaşa uygun):
- Ölüm, kan, işkence, yamyamlık, göz oyma, ayak kesme, fırında yanma, kurdun karnının yarılması yok.
- Kötü karakterler pişman olur, uzaklaşır ya da kaçar. Cezalandırma sahnesi yok.
- Korku kısa sürer ve hemen güvenle çözülür.
- Ebeveynin ölümü yerine "uzakta", ya da hiç değinme.

**Klasik anlatım** (yalnızca işaretli masallarda, 6 yaş ve üstü, "Grimm metnine yakın"):
- Kaynağa daha sadık. Kurt büyükanneyi yutar, avcı kurtarır. Cadı fırına itilir ama ayrıntı ve acı anlatılmaz.
- Yine de kan, şiddet ayrıntısı ve gereksiz korku yok.

**Hepsinde:**
- Cinsiyet, ten rengi ya da beden üzerinden alay yok.
- Keloğlan'ın kelliği alay konusu değil.
- Karagöz'de kaba söz, dayak ve müstehcen şaka yok. Kelime oyunu ve yanlış anlama komikliği var.
- Nasreddin Hoca fıkralarında içki, din tartışması ve cezalandırma içeren fıkraları seçme.
- Kelile ve Dimne'de öldürmeyle biten fabllar yok. Bunların yerine akıl ve dostluk fabllarını seç.

## Listeler

### A · Dünya klasikleri (14 masal, tek)

| slug | başlık | origin | byline | yaş | süre | raflar | klasik anlatım |
|---|---|---|---|---|---|---|---|
| rapunzel | Rapunzel | grimm | Grimm | 5-7 | 9 | klasikler | evet |
| kirmizi-baslikli-kiz | Kırmızı Başlıklı Kız | grimm | Grimm | 3-7 | 8 | klasikler, hayvanlar | evet |
| pamuk-prenses | Pamuk Prenses | grimm | Grimm | 5-8 | 12 | klasikler | evet |
| kulkedisi | Külkedisi | grimm | Grimm | 5-8 | 9 | klasikler | hayır |
| hansel-ile-gretel | Hansel ile Gretel | grimm | Grimm | 5-8 | 10 | klasikler | evet |
| kurbaga-prens | Kurbağa Prens | grimm | Grimm | 4-7 | 6 | klasikler, hayvanlar | hayır |
| uyuyan-guzel | Uyuyan Güzel | grimm | Grimm | 4-7 | 7 | klasikler, uyku | hayır |
| alti-kugu | Altı Kuğu | grimm | Grimm | 6-9 | 9 | klasikler | hayır |
| pamuk-ile-gul | Pamuk ile Gül | grimm | Grimm | 5-8 | 8 | klasikler, hayvanlar | hayır |
| rumpelstiltskin | Rumpelstiltskin | grimm | Grimm | 6-9 | 7 | klasikler | evet |
| kaz-cobani-kiz | Kaz Çobanı Kız | grimm | Grimm | 6-9 | 9 | klasikler, hayvanlar | hayır |
| ormandaki-ev | Ormandaki Ev | grimm | Grimm | 5-8 | 8 | klasikler, hayvanlar | hayır |
| tavsan-ile-kaplumbaga | Tavşan ile Kaplumbağa | aesop | Ezop | 3-6 | 4 | fabllar, hayvanlar | hayır |
| kadife-tavsan | Kadife Tavşan | modern | M. Williams | 4-8 | 11 | klasikler, uyku, hayvanlar | hayır |

Attribution örnekleri: "Grimm Kardeşler, 1812.", "Ezop, MÖ 6. yüzyıl.", "Margery Williams, 1922."

### B · Anadolu (2 tek masal + 3 seri)

| slug | başlık | byline | yaş | süre | raflar |
|---|---|---|---|---|---|
| uc-turunclar | Üç Turunçlar | Anadolu | 6-9 | 11 | anadolu |
| billur-kosk | Billur Köşk | Anadolu | 6-9 | 9 | anadolu |

**Seri `keloglan`**: "Keloğlan Masalları", byline "Anadolu", yaş 5-8, unitName "masal", bookTitle "1. Kitap". Seri özeti: "Saçı yok ama aklı çok. Keloğlan her masalda bir derdi zekâsı ve iyi kalbiyle çözer." Attribution: "Anadolu sözlü halk anlatısı."

Bölümler (her biri 7-11 dk; özet tek satır):
1. Keloğlan ile Dev Anası (Dev anasının sütünü içen Keloğlan, onu kendine ana edinir.)
2. Keloğlan ve Sihirli Değnek (Pazardan aldığı değnek söz dinlemez.)
3. Keloğlan ile Padişahın Kızı (Üç soruya üç zekice cevap.)
4. Keloğlan ve Kırk Haramiler (Ormanda kaybolan kervanın izinde.)
5. Keloğlan ile Altın Elma (Her gece kaybolan altın elmanın sırrı.)
6. Keloğlan Pazara Gidiyor (Tek ineği satarken başına gelenler.)

**Seri `dede-korkut-bamsi-beyrek`**: "Dede Korkut: Bamsı Beyrek", byline "Destan", yaş 7-10, unitName "bölüm", bookTitle "Bamsı Beyrek boyu", raflar anadolu. Attribution: "Dede Korkut Kitabı, 15-16. yüzyıl." 4 bölüm, her biri 8-10 dk, savaş sahneleri anlatılmaz, sadakat, dostluk ve kavuşma öne çıkar.

**Seri `karagoz-ile-hacivat`**: "Karagöz ile Hacivat", byline "Gölge oyunu", yaş 6-10, unitName "oyun", bookTitle "Perde perde", raflar anadolu. Attribution: "Geleneksel Türk gölge oyunu." 8 kısa oyun (4-6 dk). Hacivat'ın süslü sözleri, Karagöz'ün yanlış anlamaları. Diyalog ağırlıklı.

### C · Fıkralar ve fabllar (2 seri)

**Seri `nasreddin-hoca`**: "Nasreddin Hoca", byline "Fıkra", yaş 5-10, unitName "fıkra", bookTitle "Fıkralar", raflar anadolu. Attribution: "Nasreddin Hoca fıkraları, halk anlatısı." 12 fıkra, her biri 2-3 dk (1-3 sayfa). Örnek: Ye kürküm ye, Göle maya çalmak, Kazan doğurdu, Eşeğe ters binmek, Parayı veren düdüğü çalar, Ağaçtaki kavuk, Hoca'nın ay'ı kuyudan kurtarması, Dünyanın ortası.

**Seri `kelile-ve-dimne`**: "Kelile ve Dimne", byline "Doğu fablları", yaş 5-9, unitName "fabl", bookTitle "Hayvanların dilinden", raflar anadolu, fabllar, hayvanlar. Attribution: "Beydebâ, Kelile ve Dimne, 3. yüzyıl." 10 fabl, her biri 3-5 dk. Dostluk, akıl ve sabır fabllarını seç: Kaplumbağa ile iki ördek, Güvercin ile fare (ağdan kurtuluş), Tavşan ile fil gölü, Maymun ile kaplumbağa (dostluk sınavı), Karga, fare, kaplumbağa ve ceylan (dört dost). Ölümle biten fabl yok.

## Kontrol listesi (her dosya için)

- JSON geçerli: `python3 -m json.tool` ile kontrol et.
- Her sayfa dolu ve sayfa uzunluğu kurala uygun.
- `minutes` kelime sayısıyla tutarlı.
- Uzun tire yok: `grep -c "—"` 0 dönmeli.
- Yumuşak anlatımda güvenlik listesindeki hiçbir öğe yok.
