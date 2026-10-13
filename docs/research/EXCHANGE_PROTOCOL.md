# Fikir alışverişi protokolü (Exchange)

2026-10-08 · Karar: **tek insan onay noktası.** Araştırma, ajanlar arası tartışma, prototip,
test ve deney hazırlığı otomatik; çocuğa ulaşan her değişiklik (deneyin yayına açılması,
kalıcı kural) ürün sahibinin kararını bekler.

## Döngü

```
book-research  ──öneri──▶  EXCHANGE  ──karar (insan)──▶  sahibi olan ajan uygular
 (kitap okur)               story-engine: motor etkisi        (story-engine / content-library,
      ▲                     content-library: Türkçe prototip    kendi fazı ve testleriyle)
      │                     privacy-safety: güvenlik kararı              │
      │                     reviewer: (isteğe bağlı) inceleme            ▼
      └──── dersler (lessons) + kullanım verisi (FAZ 14/16) ◀──── deney sonuçları
```

## Kim neyi yazar

Her ajan yalnızca kendi dosyasını yazar; böylece ajanlar paralel çalışır, kimse ötekini ezmez.

| Parça | Yazan | Komut |
|---|---|---|
| Öneri + durum + tavsiye (`thread.json`) | book-research | `exchange open`, `exchange recommend` |
| Tartışma turları (`turns/`) | herkes (insan hariç) | `exchange post` |
| Motor etkisi (`impact.json`) | story-engine | `exchange impact` |
| Prototip (`prototype.json` + `Research/BookIntelligence/sandbox/`) | content-library | `exchange prototype` |
| Güvenlik (`safety.json`) | privacy-safety | `exchange safety` |
| Karar (`decision.json`) | **yalnızca ürün sahibi** | `exchange decide` |

## Kurallar (kodda zorunlu)

- Tavsiye yazılmadan önce **story-engine** ve **privacy-safety** en az bir kez konuşmuş olmalı.
- `experiment` tavsiyesi için motor etkisi kaydı ve güvenlikten **pass** gerekir.
- Güvenlik **block** dediyse yalnızca `park`, `decline` ya da `research_more` önerilebilir.
- Prototipler yalnızca `Research/BookIntelligence/sandbox/` altında. Üretim içeriğine, motora, kataloğa dokunulmaz.
- Kanıt referansı bir iddia, eser, repo dosyası ya da URL olmalı; uydurma referans doğrulamadan geçmez.
- Karar verilmiş öneri donar. Yeniden açmak için yeni öneri gerekir.
- Ajanlar `exchange decide` çalıştırmaz. Bu, ajan tanımlarında yasak ve `decision.json` yalnızca insan kapısından geçer.

## Tutumlar (stance)

`proposal` · `support` · `concern` · `object` · `question` · `answer` · `prototype` · `revision`

İyi bir tur: tek bir noktayı söyler, kanıt gösterir (`--evidence`), gerekirse bir tura cevap verir (`--reply-to`).

## Tavsiye türleri

| Tavsiye | Anlamı |
|---|---|
| `experiment` | Bayrak arkasında deney kolu olarak denensin (kullanım verisiyle ölçülür) |
| `adopt_guidance` | İçerik hattına yazım rehberi olarak girsin (kod değişmez) |
| `research_more` | Kanıt yetersiz; araştırma görevi açılsın |
| `park` | Şimdilik bekle |
| `decline` | Uygulanmasın |

## Kendini geliştirme

- `exchange lessons`: hangi hedefe yapılan öneriler kabul/ret aldı, kim neye itiraz etti.
  book-research yeni öneri yazmadan önce bunu okur; reddedilen bir öneriyi aynı kanıtla tekrar getirmez.
- Kullanım verisi (FAZ 14 olayları, FAZ 16 sonrası toplu) iddialara `child_response` kanıtı olarak girdiğinde
  güven seviyeleri değişir ve "çocuk ilgisi" sezgisel puanları gerçek sonuçlarla kalibre edilir (sonraki faz).

## Deney ve geri dönüş (13 Ekim 2026)

Onaylanan bir `experiment` önerisi motoru değiştirmeden denenir:

1. **Kayıt ve tahmin.** book-research deneyi veri gelmeden önce tahminiyle kaydeder (yön, en küçük anlamlı fark,
   kendine verdiği olasılık). Tahmin sonradan değiştirilemez:
   `ba experiment create x_<ad> --proposal p_… --control <blueprint> --variant <blueprint> --age-band 5-6 --mode adventure --direction better --min-effect 0.03 --confidence 0.7 --rationale "…"`
2. **Ön kontrol.** `ba experiment preflight x_<ad> --package <paket.json>` şunları ister: senin onayın,
   güvenlikten `pass`, aynı yaş bandı/sayfa sayısı/aile, modun o aileye hizmet etmesi; uyku öncesi yalnızca
   öneri uykuya özgüyse. Hepsi tamamsa durum `ready` olur.
3. **Yayın (insan).** Varyant, FAZ 15 uzaktan paketiyle çıkar. Kol, okuma olaylarındaki `blueprintID`'den
   anlaşılır; yeni veri alanı yok, çocuğa ya da cihaza atama yok. Paket yayınlanınca
   `ba experiment mark x_<ad> --status live`; geri çekilince `--status stopped`.
4. **Toplama (sunucu).** `aggregateOutcomes` (firebase/functions, her pazartesi 04:00) son 28 günü
   blueprint × bant × mod hücrelerine toplar. Bir hücre ancak en az 50 okuma ve en az 7 farklı gün içerirse
   yazılır. Olaylarda kişi kimliği olmadığı için privacy-safety'nin "kişi başına gün" eşiği okuma + gün
   yayılımı olarak uygulandı. Uyku öncesinde ölçüt tekrar okumadır, bitirmemek başarısızlık değildir.
5. **Geri dönüş.** Dışa aktarılan toplam belge `Research/BookIntelligence/inbox/usage/` klasörüne konur.
   `ba cycle` belgeyi içe aktarır; satır, kimlik ya da eşiğin altında hücre taşıyan dosyayı bütünüyle reddeder.
   Canlı deneyler, yayından sonra başlayan dönemlerle değerlendirilir. Kol başına en az 200 okuma ve
   P ≥ 0.95 gerekir. Sonuç iddiaya `child_response` kanıtı olarak eklenir; aleyhte bir sonuç iddianın
   güvenini LOW'a indirir.
6. **Kendini ölçme.** `ba calibration` tahminlerin isabetini ve Brier puanını tutar; aşırı ya da eksik
   güveni söyler. Ajan bir sonraki tahmininde bunu dikkate alır.
7. **Ritim.** "MagicPaper öğrenme döngüsü" zamanlanmış görevi her pazartesi 10:10'da çalışır:
   `cycle`, en çok 2 yeni kitap, gerekirse ajan turu, haftalık sayfa (`docs/research/weekly/<tarih>.md`).
   Uygulama kapalıysa görev, uygulama açıldığında çalışır.

## Ürün sahibi için

```bash
python3 Research/BookIntelligence/book_agent.py exchange digest
```

`docs/research/EXCHANGE_DIGEST.md`: yalnızca ilk bölüm senin kararını bekler. Her öneri için tam tartışma
`docs/research/exchange/<öneri>.md` içinde. Karar:

```bash
python3 Research/BookIntelligence/book_agent.py exchange decide p_repeated_line --verdict approved --note "…"
```
