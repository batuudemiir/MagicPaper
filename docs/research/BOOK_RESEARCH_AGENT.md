# Children's Book Intelligence Agent — kullanım

2026-10-08 · MVP (Faz 1-9'un ilk dilimi). Mimari: [BOOK_INTELLIGENCE_ARCHITECTURE.md](BOOK_INTELLIGENCE_ARCHITECTURE.md) ·
yöntem ve kurallar: [RESEARCH_METHOD.md](RESEARCH_METHOD.md) · kaynaklar ve koşulları: [SOURCES.md](SOURCES.md).

## Hangi kaynaktan ne gelir

| Kaynak | Komut | Sayfa sınırı | Resim | Metin |
|---|---|---|---|---|
| Project Gutenberg | `ingest gutenberg <id>` | yeniden kurulmuş | yok | baskının düz metni |
| Internet Archive (≤ 1930, ödünç dışı) | `ingest ia <identifier>` | **orijinal tarama** | **var** (`images`) | OCR |
| Book Dash (CC BY 4.0, güncel) | `ingest bookdash <slug>` ×2 | **yayıncı düzeni** | **her sayfa** | analist transkripsiyonu |
| African Storybook, StoryWeaver | elle: `ingest file` | yayıncı düzeni | not olarak | analist transkripsiyonu |

Sayfa çevirme analizi yalnızca Internet Archive, Book Dash ve elle eklenen sayfa yapılı kitaplarda yapılır.

İki parça var:

- **`book-agent` CLI** (`Research/BookIntelligence/book_agent.py`, Python 3 stdlib, bağımlılık yok):
  mekanik olan her şey — yasal kaynaktan alma, telif kuralı, sayfalama, metrikler,
  tekilleştirme, doğrulama, güven hesabı, karşılaştırma, boşluklar, raporlar.
- **`book-research` ajanı** (`.claude/agents/book-research.md`): okuma ve yargı — beat, duygu,
  sayfa çevirme, karakter, mizah, tekrar. Şemaya yazar; CLI kabul etmezse kayıt geçersizdir.

Araç uygulamaya ve motora hiçbir şey yazmaz. Yalnızca `Research/BookIntelligence/data/`,
`Research/BookIntelligence/cache/` (git dışı) ve `docs/research/` altına yazar.

---

## Hızlı başlangıç

Aşağıdaki komutlar `MagicPaper/` klasöründen çalışır. Kısaltma:

```bash
alias book-agent="python3 Research/BookIntelligence/book_agent.py"
```

Bir araştırma oturumu:

```bash
book-agent status
book-agent gaps
book-agent run start --goal "5-6 pilot: sayfa yapısı gerçek 5 kitap" --strategy "Gutenberg resimli kitaplar"
book-agent discover --source ia --query 'title:(peter rabbit) AND creator:(potter)'
book-agent ingest ia the-tale-of-peter-rabbit_202609 --age-band 5-6 --age-basis analyst
book-agent images w_tale_of_peter_rabbit_potter --pages 1-6       # ajan resimlere bakar
book-agent analyze w_tale_of_peter_rabbit_potter
#   → ajan data/pages/… ve data/analyses/… dosyalarındaki yargı alanlarını doldurur
book-agent analyze w_tale_of_peter_rabbit_potter          # metrikleri yeniler, eksikleri listeler
book-agent analyze w_tale_of_peter_rabbit_potter --complete --analyst book-research
book-agent validate
book-agent compare --age 5-6 --write
book-agent insights
book-agent deep-dive w_tale_of_peter_rabbit_potter --write
book-agent run finish --summary "…"
book-agent report
```

Claude Code'da: *"book-research ajanıyla bu haftanın kitabını incele"* ya da
*"book-research ajanıyla 5-6 macera boşluğunu kapat"*.

---

## Komutlar

| Komut | Ne yapar | Ağ |
|---|---|---|
| `status [--json]` | Eser/baskı/kaynak sayıları, analiz durumları, açık koşu | yok |
| `gaps [--json]` | Araştırma planına göre eksikler + önerilen sorgular | yok |
| `run start --goal … --strategy …` / `run finish --summary …` | Araştırma koşusu açar/kapatır; kapanışta rapor yazar | yok |
| `discover --source gutenberg\|ia\|bookdash --query …` | Gutenberg kataloğu (30 günde bir indirilir), IA arama API'si (≤ 1930, ödünç dışı), Book Dash kitap listesi (`--query '*'`) | evet |
| `ingest gutenberg <id>` | RDF'ten hak + künye, metni indirir, sayfalar, tekilleştirir | evet |
| `ingest ia <identifier>` | Uygunluk kapısı (yıl, koleksiyon, kısıt), sayfa başına OCR | evet |
| `ingest bookdash <slug>` | 1. çağrı: sayfa görüntüleri + transkripsiyon dosyası. 2. çağrı: transkripsiyonu alır | evet |
| `images <work> [--pages 1-4]` | Sayfa görüntülerinin yerel yolları (IA yaprakları istenince indirilir) | IA için |
| `ingest file <yol> --rights … --boundary …` | Elle edinilmiş sayfa dosyası (tarama, CC kitap) + kaynak bilgisi | yok |
| `work add --title … --creator "Ad:rol" --lang …` | Tam metni okunamayan eser (yalnızca künye ve kanıt) | yok |
| `work reject <id> --reason …` | Eseri gerekçesiyle korpustan çıkarır (kayıt kalır) | yok |
| `source add --id … --url … --kind … --tier …` | İnceleme, ödül listesi, kütüphane kaydı — gövdesi saklanmaz | yok |
| `analyze <work> [--version] [--pages N]` | Taslak açar ya da hesaplanan alanları yeniler | yok |
| `analyze <work> --complete --analyst …` | Eksik yargı varsa reddeder; yoksa tamamlar | yok |
| `metrics [work]` | Tüm analizlerin metriklerini yeniden hesaplar | yok |
| `validate` | Şema + hak + referans kontrolü; hata varsa çıkış kodu 1 | yok |
| `compare [--age] [--lang] [--write]` | Kitaplar arası dağılımlar → `docs/research/patterns/` | yok |
| `insights` | Güveni yeniden hesaplar → `FINDINGS.md`, `MAGICPAPER_STORY_INSIGHTS.md` | yok |
| `deep-dive <work> [--write]` | Haftanın kitabı raporu → `docs/research/deep-dives/` | yok |
| `report [--run]` | Koşu raporu → `docs/research/reports/`, `BOOK_CORPUS.md` | yok |
| `review` | Belirsiz tekilleştirme eşleşmeleri | yok |
| `exchange open --all` | Her MagicPaper önerisi için tartışma dosyası açar | yok |
| `exchange post / impact / prototype / safety` | Ajanların turları ve kendi bölümleri ([protokol](EXCHANGE_PROTOCOL.md)) | yok |
| `exchange recommend` | book-research'ün tavsiyesi (story-engine + privacy-safety konuştuktan sonra) | yok |
| `exchange digest` | Ürün sahibine tek sayfa: `EXCHANGE_DIGEST.md` | yok |
| `exchange decide` | **Yalnızca ürün sahibi**: approved / rejected / parked | yok |
| `exchange handoffs` / `exchange handoff <öneri> --agent … --status …` | Onaylanan önerilerin iş paketleri ve durumları → `docs/research/HANDOFFS.md` | yok |
| `exchange lessons` | Geçmiş kararlardan dersler (ajan yeni öneriden önce okur) | yok |
| `experiment create / preflight / mark / show / list` | Onaylı öneriyi kardeş blueprint ile deneme; tahmin önceden yazılır | yok |
| `usage import <dosya>` | Sunucunun toplu sonuç belgesi (yalnızca toplamlar, mahremiyet eşiği zorunlu) | yok |
| `evaluate` | Canlı deneyleri içe aktarılmış kullanıma göre değerlendirir | yok |
| `calibration` | Ajanın tahmin isabeti ve Brier puanı | yok |
| `cycle` | Haftalık döngü: gelen kutusu → metrikler → deneyler → güven → kalibrasyon → boşluklar → özet → haftalık sayfa | yok |

Belirsiz bir eşleşmede (`aynı başlık, farklı yazar` gibi) ingest durur ve çifti
`data/review/dedup.json`'a yazar. Karar insanın: `--work <id>` ya da `--new-work` ile tekrar çalıştır.

---

## Elle sayfa dosyası

Gerçek sayfa sınırları için (tarama, sayfa yapılı CC kitap):

```
# yorumlar ilk işaretten önce
=== page 1 ===
Metin…
[illustration: resimde ne var — yalnızca resimde olan bilgi]
=== spread 2-3 ===
…
```

```bash
book-agent ingest file kitap.pages.txt --url https://… --rights open_license \
  --license "CC BY 4.0" --attribution "Yazar, Çizer, Platform" \
  --title "…" --creator "Ad Soyad" --creator "Ad Soyad:illustrator" \
  --lang en --boundary original_scan --age-band 5-6 --age-basis publisher
```

`publisher_preview`, `metadata_only`, `commentary` haklarıyla metin alınmaz. Böyle bir kitap
`work add` + `source add` ile kaydedilir ve `analyze <work> --pages N` ile **notlardan,
metinsiz** analiz edilir; sonuç her zaman `partial` olarak işaretlenir.

---

## Book Dash: iki adım

```bash
book-agent ingest bookdash mud
#   → cache/images/e_bookdash_mud/p01.jpg … ve cache/transcribe/e_bookdash_mud.pages.txt
#   ajan her görüntüyü açar, sayfadaki kelimeleri aynen yazar; kelimesiz sayfaya [no text]
book-agent ingest bookdash mud --age-band 5-6 --age-basis publisher
```

Kapak ve künye sayfaları da sayfa olarak gelir; `[no text]` ile işaretlenir ve analizde belirtilir.

## Kendini geliştirme

Ajan üç yoldan iyileşir; her biri haftalık sayfada "Ajanlardan gelen sorular" ve "Ajan kendini nasıl geliştirdi" bölümlerinde görünür (`bookintel/learning.py`).

- **Diğer ajanların soruları** (`data/requests/`): story-engine, content-library, privacy-safety, reader, parent-ux, ui-agent, illustration-system ya da ürün sahibi soru sorar; araştırma ajanı bir sonraki koşuda önce bunları cevaplar. Cevap iddia ve kitap gösterir, kanıt gücü (iddianın güven düzeyi) cevaba yazılır.
  `ba request ask --agent reader --question "…" --why "…"` · `ba request list` · `ba request take|answer|decline|show <id>`
- **Kör yeniden okuma** (`data/rechecks/`): her koşuda tamamlanmış bir kitap, ilk analizine bakılmadan yeniden okunur; iki okumanın uyuşması alan başına ajanın tutarlılığıdır. 20+ sayfada %60'ın altında kalan bir alan güvenilmez sayılır ve o alana dayanan iddialar (`judgment_fields`) LOW'u geçemez.
  `ba recheck pick` · `ba recheck start <work>` · `ba recheck score <work>` · `ba recheck reliability`
- **Yöntem kuralları** (`data/method/rules.json`): başka bir ajanın yakaladığı ve araştırma ajanının kabul ettiği her hata bir kurala dönüşür. `note` kuralları her oturumda okunur; `forbid` ve `require_when` kuralları `validate` tarafından denetlenir. Kurallar sürümlenir, gerekçesiz kaldırılmaz, uygulamayı değil yalnızca araştırma yöntemini değiştirir.
  `ba method show` · `ba method add --kind … --text … --evidence <öneri>/<tur>` · `ba method retire <id> --text …` · `ba method check`

Sınır: kör okumayı CLI zorlayamaz; ajanın ilk analizi açmaması talimatla sağlanır. Tutarlılık doğruluk değildir; doğruluğu yalnızca çocuklardan gelen deney sonuçları ölçer.

## Dosyalar

```
Research/BookIntelligence/
  book_agent.py            CLI
  bookintel/               paket (adapters/ ağa çıkan tek yer)
  bookintel/vocab/         kapalı sözlükler, motor eşlemesi, araştırma planı
  data/                    bilgi tabanı (git'te): works, editions, sources, analyses,
                           pages, claims, runs, review, index (üretilmiş)
  cache/                   indirilen ham metin, katalog (git dışı)
  tests/                   84 test, uydurma fikstür kitaplar, kayıtlı yanıtlar, ağ yok

docs/research/
  BOOK_CORPUS.md  FINDINGS.md  MAGICPAPER_STORY_INSIGHTS.md   (üretilmiş bloklar)
  patterns/<yaş>_<dil>.md  deep-dives/<work>.md  reports/<run>.md
```

Üretilmiş belgelerde yalnızca `<!-- bookintel:generated:start/end -->` arası yeniden yazılır;
etrafına yazılan yorum korunur.

---

## Testler

```bash
python3 -m unittest discover -s Research/BookIntelligence/tests -t Research/BookIntelligence/tests
```

Testler ağa çıkmaz (soket açılırsa test düşer). Gutenberg yanıtları `tests/fixtures/` altında
kayıtlı; fikstür kitaplar testler için uyduruldu, gerçek kitap değil.

---

## Bilinen sınırlar (MVP)

- Otomatik kaynaklar: Project Gutenberg, Internet Archive, Book Dash. African Storybook ve StoryWeaver
  için otomatik yol yok (gerekçe: [SOURCES.md](SOURCES.md)); elle eklenir.
- IA metni OCR'dır: hatalı kelime olabilir; analist sayfa görüntüsüyle karşılaştırır. Resim yaprakları
  metin sayfasına konumla bağlanır (önceki metin sayfasına); analist bakarak doğrular.
- Book Dash listesi yalnızca `bookdash.org/books/` sayfasındaki kitapları görür (2026-10-08: 48).
- Gutenberg düz metninde sayfa yok; `[Illustration]` işaretlerinden yeniden kurulur
  (`reconstructed`). Bu sayfalarla sayfa çevirme analizi yapılmaz. Başlık sayfası ilk "sayfa"
  olarak gelebilir; analist bunu `change` alanında belirtir.
- Türkçe tam metin yok denecek kadar az; Türkçe korpus önce künye ağırlıklı başlayacak (D8).
- Ses kelimesi ve doğrudan hitap sayıları kısa kelime listelerine dayanır: alt sınırdır.
- Yakın-kopya denetimi (`overlap`) ve gömme/kümeleme yok (Faz 7 ve sonrası).
