# Varlık Lisansları — MagicPaper Kids Storybook Decoration System

**Tarih:** 2026-09-16

Bu dosya üretimde kullanılan her dekoratif varlığın kaynağını ve lisansını
kaydeder. Lisansı belirsiz hiçbir varlık `approved` olamaz.

---

## 1. MagicPaper Kids özgün varlıkları (26 adet, 12'si onaylı)

**Lisans:** Proprietary — MagicPaper Kids
**Ticari kullanım:** evet · **Değiştirme:** evet · **Atıf:** gerekmez

Üretim: `Tools/make_decorations.py`. Kaynak kod varlığın kendisidir; yeniden
üretilebilir ve sürümlenebilir.

**Neden özgün üretildi:** §8'in söylediği kaynaklar tarandı ve iki hipotez de
başarısız oldu — gerekçeler §3'te.

Statüler `AssetCatalog/assets.json` içinde. Özet:

| Statü | Adet | Anlamı |
|---|---|---|
| approved | 12 | Sayfada kullanılabilir |
| review_required | 5 | Çalışıyor ama zayıf; sanat yönü kararı bekliyor |
| rejected | 9 | Yanlış okunuyor ya da brief §4'ün yasakladığı "generic vector icon" |

---

## 2. Wikimedia Commons adayları — lisansı doğrulandı, **kullanılmadı**

17 dosya Commons API'sinden `extmetadata` ile doğrulandı (uydurulmadı; her
kayıt `AssetCatalog/external_candidates.json` içinde `LicenseShortName`,
`Artist`, `descriptionUrl` alanlarıyla duruyor).

**Hepsi "Public domain".** Yine de üretime alınmadılar — lisans sebebiyle
değil, **görsel uygunluk sebebiyle**:

| Dosya | Sorun |
|---|---|
| `flower-legends-for-children-0023-*` | Dönem kostümlü tam sahne illüstrasyonu |
| `flower-children-0022-8`, `-1-0090` | Tanınabilir karakter (çiçek-çocuk); §4 karakter sokmayı yasaklıyor |
| `gruelle-fitchers-bird` | Karanlık, tehditkâr figür; tonu yanlış |
| `puss-junior-*` (3) | Beardsley tarzı sert siyah-beyaz karakter sahneleri |
| `anne-henslow-barnard-wallflower` | Altyazılı bilimsel kesit diyagramı |
| `botanical-book-illustration-*` | Japon kitap kapağı taraması |
| `dandelion-*`, `stratus-clouds-*` | Kitap sayfası **fotoğrafı** (metin, sayfa kenarı, koyu zemin) |
| `au-clair-de-la-lune-*` | Nota sayfası |
| `butterfly-meeting` | Renkli iç mekân sahnesi |
| `britannica-jaborandi`, `child-s-picture-book-pg-3`, `butterfly-pair`, `edna-hart-*` | **En umut vericiler.** Motif çıkarımı denendi; çerçeve cetvelleri, `a`/`b`/`c` etiket harfleri ve krem zeminden gelen yarı saydam dikdörtgen sorunları çıktı |

Orijinaller `Assets/Storybook/SourceOriginals/` altında korunuyor — ileride
elle motif çıkarımı yapılmak istenirse diye.

---

## 3. Lisansı belirsiz olduğu için kullanılmayanlar

Altı Commons dosyası `LicenseShortName: "No restrictions"` döndürdü. Bu,
Flickr Commons'ın *"No known copyright restrictions"* etiketi ve **açık bir
kamu malı beyanı değil** — üstelik aynı kayıtlarda `Copyrighted: True` yazıyor.

- `The children's book of stars (1908)` × 4
- `The children's book of birds (1901)` × 2

**Statü: review_required.** 1901/1908 baskıları yaş itibarıyla büyük ihtimalle
kamu malı; ama bunu üstveri beyan etmiyor, dolayısıyla burada beyan edilmiyor.
Karar ürün sahibinin.

---

## 4. Taranan ama kullanılmayan kaynaklar

| Kaynak | Sonuç |
|---|---|
| Commons `Category:Fleurons`, "printer's ornament" aramaları | Gerçek ve bol kamu malı tipografik ornament var, ama register yanlış: 18-19. yy matbaa fleuronları, klasik/yetişkin kitabı dili. §4'ün istediği "çim kümesi, mantar çifti, minik kelebek" değil |
| Kenney (CC0) | Oyun sprite'ı estetiği; ana illüstrasyonun suluboya diliyle çelişiyor |
| SVG Repo | Varlık başına ayrı lisans; modern doodle dili |

---

## Yeni varlık eklerken

1. Kaynağı, yazarı, lisansı ve lisans URL'sini **kaynağından** doğrula.
2. `AssetCatalog/assets.json`'a `status: "candidate"` ile ekle.
3. Geliştirici galerisinde gör.
4. Ancak görsel ve hukuki olarak netse `approved` yap.
5. Atıf gerekiyorsa bu dosyada koru — gizleme.
