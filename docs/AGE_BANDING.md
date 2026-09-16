# Yaşa göre masal: araştırma ve motorda karşılığı

2026-09-16. Kaynaklar en altta.

Bu belge iki iş yapar: yayıncılık ve gelişim psikolojisi tarafında yerleşmiş
olanı toplar, ve her bulgunun **motorda hangi alana** karşılık geldiğini söyler.
Karşılığı olmayan bulgu buraya yazılmaz — ilginç ama uygulanamaz bilgi, bir
sonraki kişinin uygulanabilir sandığı bilgidir.

---

## 1. Uzunluk: yerleşik sayılar

| Tür | Yaş | Toplam kelime |
|---|---|---|
| Board book | 0-3 | ≤ 100 |
| Erken resimli kitap | 0-3 | ≤ 400 |
| **Resimli kitap** | **3-7** | **≤ 600** |
| Erken okur | 5-7 | ≤ 1.500 |
| Bölüm kitabı | 7-9 | 4.000-15.000 |

Sektörde 600'e yaklaşan resimli kitap zaten uzun sayılıyor; 1.000'e yaklaşan
reddediliyor.

**Bugün nerede duruyoruz.** 8 sayfa × 18-38 kelime = **144-304 kelime**. Resimli
kitap bandının alt yarısı. 5-6 için doğru yerde, ve önemli bir sebeple: bu
metin sesli okunuyor, sessiz okunmuyor. Sesli okumada sayfa başına düşen süre
sayfanın kendisi kadar önemli.

---

## 2. Cümle uzunluğu — ve bu literatürdeki en kolay hata

Gelişim literatüründe en çok alıntılanan ölçü **MLU** (ortalama sözce uzunluğu):
4-5 yaş için sözcük cinsinden ~4,5-5; 5-6 arasında artıyor, 6-7 arasında
artmıyor.

**MLU çocuğun ÜRETTİĞİdir, anladığı değil.** Anlama üretmeyi belirgin biçimde
önden götürür — bir masalın okunduğu çocuk, kendi kuramayacağı cümleleri rahatça
takip eder. MLU'yu tavan sanıp cümleleri beş kelimeye indirmek, metni çocuk için
uygun değil **tatsız** yapar. Doğru kullanım: MLU bir **taban** göstergesi,
tavan değil.

Bugünkü korpusun 14 kelimelik cümle sınırı bu yüzden MLU'nun üç katı ve doğru
olan bu. Yaş bandı değiştiğinde değişmesi gereken de bu sınır.

---

## 3. Yapı: başlangıç, orta, son

Resimli kitap kısalığına rağmen üçünü de taşımak zorunda. Bugünkü sekiz beat'lik
yay bunu zaten yapıyor. Araştırmanın eklediği şey **hangi yapının hangi yaşta
tutulabildiği**:

- 3-6 arasında öykü yapısı **kademeli olarak tamamlanıyor**; 5 yaş civarı
  sözdizimsel uzunlukta kritik eşik.
- Anlama iki katmanlı: birinci katman kelime ve dilbilgisi; **ikinci katman
  çıkarım, önbilgiyle bütünleştirme ve öykü yapısı bilgisi.**

İkinci katman bu motor için doğrudan bir şey söylüyor ve bugüne kadar
söylenmemişti.

### Ailelerin bilişsel maliyeti aynı değil

| Aile | Ne yapıyor | Gereken |
|---|---|---|
| III Appeal | biri yardım istiyor, çocuk yardım ediyor | doğrusal zincir |
| VI Charge | bir şeye zamanla bakmak | süre kavramı |
| II Threshold | çocuğun kendi korkusu | iç durum ↔ dış durum ayrımı |
| IV Absence | eksik olanı aramak | yokluk üzerine akıl yürütme |
| I Unexplained | iki gözlemden bir çıkarım | **çıkarım** |
| V Misreading | yanlış bir inancı tutup sonra çürütmek | **inancın yanlış olabileceğini kavramak** |

Sondaki ikisi ikinci katman işi. Özellikle V: bir inancı tutmak, sonra onun
yanlış olduğunu görmek — bu, yanlış-inanç kavrayışının ta kendisi ve dört
yaşından önce güvenilir biçimde oturmuyor.

**Motordaki karşılığı:** `NarrativeFamily.minimumAge`. Uydurma bir sayı değil,
çözüm mekanizmasından türetiliyor ki iki kaynak olmasın.

---

## 4. Motorda ne değişti

| Bulgu | Alan |
|---|---|
| Bant başına toplam kelime | `AgeBand.pageBudget`, `AgeBand.pageCount` |
| Cümle uzunluğu tavanı | `AgeBand.maxSentenceWords` |
| Ailelerin bilişsel maliyeti | `NarrativeFamily.minimumAge` |
| Yaşına uymayan blueprint | `catalog_integrity: blueprint_below_family_age` |

`AgeBand` zaten vardı ve yalnızca "5-6" metnini taşıyordu; artık o bandın ne
demek olduğunu da taşıyor.

---

## 5. Bunun uygulamaya bugünkü etkisi

Uygulama dört bant sunuyor (3-4, 5-7, 8-10, 11-12), içeriğin tamamı `5-6`.
Yaş süzgeci bu yüzden kapalı — tek bantlı bir katalogda süzmek yalnızca
çıkarabilir, ekleyemez (`AgeBandCoverageTests`, ikinci bant yazıldığı an alarm
veriyor).

Bu belge o ikinci bandın **neye göre** yazılacağını söylüyor. Yazılana kadar
değişen bir şey yok; yazıldığında süzgeç geri açılıyor ve `minimumAge` kendi
işini yapıyor.

---

## Kaynaklar

- [Mary Kole Editorial — Children's Book Length Guidelines](https://www.marykole.com/childrens-book-length)
- [Bookfox — What's the Perfect Length for a Children's Picture Book?](https://thejohnfox.com/2023/08/whats-the-perfect-length-for-a-childrens-picture-book/)
- [Write for Kids — Children's Book Word Count by Age Group](https://writeforkids.online/childrens-book-word-counts-by-age-group/)
- [ASHA / JSLHR — Age-Related Progressions in Story Structure in Young Children's Narratives](https://pubs.asha.org/doi/10.1044/2016_JSLHR-L-15-0275)
- [Li, R. (2023) — Learning-skill stories completion: 3-6 yaş anlatı gelişimi](https://journals.sagepub.com/doi/abs/10.1177/25138502231194097)
- [MLU norm tablosu — Mean Length of Utterance Levels, 3-9 yaş (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC2849178/)
- [Narrative comprehension bileşenleri (PMC)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8391907/)
