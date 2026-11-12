# MagicPaper Original: kendi masallarımız ve düzenli yazan ajan

Tarih: 12 Kasım 2026 · Karar: Batuhan · Durum: tasarım onaylandı, plan bekliyor

## Amaç

Masallar sekmesinde (kodda `GunlukView`) "MagicPaper Original" adında bir marka rafı açmak. Raf, MagicPaper'ın kendi yazdığı, ortak bir dünyada geçen masallarla dolar. Bir ajan haftada iki masal yazar, kapağını çizdirir ve onaya koyar. Batuhan okur, onaylar; masal App Store güncellemesi olmadan imzalı akışla uygulamaya ulaşır.

## Kararlar (12 Kasım 2026, Batuhan)

| Konu | Karar |
|---|---|
| Yayın yolu | Uzaktan, güncellemesiz: mevcut imzalı akış (`feed.json`, FAZ 15) genişler |
| Onay | İnsan onayı zorunlu. Ajan yayımlamaz, yalnız taslak bırakır |
| Sıklık | Haftada 2 masal: pazartesi ve perşembe 09:00 (Mac'te zamanlanmış görev) |
| Kapak | Ajan (Claude) SVG olarak kendisi çizer, `Tools/render_cover.py` JPEG'e çevirir; Batuhan onaylar. Görsel üretim servisi yok (12 Kasım: Gemini kaldırıldı). Klasiklerde kamu malı plakalar kuralı geçerli |
| Dünya | Ortak bir dünya, 4-6 tekrar eden karakter. İlk tur ajan üç dünya önerir, Batuhan seçer |

Seçilmeyen yollar: `DailyStory`'ye kapak adresi eklemek (metin tek parça kalır, Günün masalı seçimine karışır) ve ayrı imzalı `originals.json` (yayın ve doğrulama kodunun ikinci kopyası).

## 1. Masallar sekmesinde marka

- Yeni raf: `ClassicShelf.orijinal`. Başlık "MagicPaper Original", alt satır "Yalnızca burada okunan masallar". Kategoriler listesinde de görünür.
- Masallar ana sayfasında bölüm `GunlukSection` (`MPSectionHeader` üstüne kurulu) ile, "Tümü ›" raf ekranına push eder (`.shelf(.orijinal)`). Bölümün yeri: vitrinin hemen altı.
- Kapak kartı mevcut `ClassicShelfCard`. Kartın meta satırı "Original · N dk". Ayrı bir rozet bileşeni açılmaz; marka adı bölüm başlığında ve detayda yazar.
- Detay ve okuyucu klasiklerinkidir (`soft.pages`). Detayın kaynak satırı (`attribution`) "MagicPaper Original", kapak notu (`coverCredit`) "Kapak: MagicPaper".
- Kapağı cihaza inmemiş ya da özeti tutmayan masal gösterilmez (Rapunzel kuralı). Raf boşsa bölüm hiç çizilmez.
- Original masallar Günün masalı seçimine (`TodaysStoryPicker`) girmez. `featuredID` ile vitrine elle konabilir (sonraki iş, bu kapsamda değil).
- Okundu bilgisi mevcut `ClassicProgressStore`'da, masalın `id`'siyle.

## 2. Dünya kitabı

Dosya: `Content/Originals/WORLD.md`. Markanın kanonu; ajan her turda önce bunu okur.

İçerik:
- Mekân: adı, haritası (birkaç yer adı), mevsim ve gün döngüsü.
- Karakterler (4-6): ad, tür, yaş hissi, görünüş (kapakta değişmeyecek ayrıntılar), konuşma biçimi, sevdiği ve korktuğu şey.
- Ton: üç mod (uyku, öğrenme, macera) bu dünyada nasıl duyulur.
- Kapak stil kılavuzu: teknik (ör. guaj, kâğıt dokusu), palet, ışık, kadraj, yasaklar (yazı yok, fotoğraf gerçekçiliği yok, neon ve parlak 3B yok). Kapak isteğinin sabit gövdesi buradan alınır.
- Ragi bu dünyanın karakteri değildir; Ragi uygulamanın maskotu olarak kalır.

İlk tur: `WORLD.md` yoksa ajan masal yazmaz. `Content/Originals/world-proposals.md` dosyasına üç dünya önerisi yazar: her biri için bir paragraf, karakter listesi ve örnek bir ilk sayfa. Batuhan birini seçip `WORLD.md`'ye dönüştürülmesini onaylayınca düzenli yazım başlar.

## 3. İçerik biçimi ve onay akışı

```
Content/Originals/
  WORLD.md
  world-proposals.md        (yalnız ilk tur)
  drafts/<slug>/
    tale.json
    cover.jpg
    review.md
  published/<slug>/
    tale.json
    cover.jpg
```

`tale.json`, klasiklerin biçimine yakın (`Content/Classics/WRITING_BRIEF.md`):

```json
{
  "id": "UUID",
  "slug": "fener-bekcisinin-sesi",
  "title": "…",
  "mode": "bedtime",
  "ageMin": 3,
  "ageMax": 6,
  "minutes": 6,
  "summary": "Tek cümle.",
  "characters": ["…"],
  "pages": ["…", "…"],
  "publishDate": "2026-11-17"
}
```

- `mode`: `bedtime` | `learning` | `adventure`.
- `characters`: `WORLD.md`'deki adlar; bilinmeyen ad doğrulamada hata.
- Sayfa kuralları ve süre hesabı brief'teki gibi: sayfa 40-80 kelime (3-4 bandında 25-45), `minutes` = kelime / 40 yukarı yuvarlanır.
- `review.md`: öz denetim sonuçları, kapak isteğinin sahne kısmı, mod ve yaş seçiminin gerekçesi, varsa önceki tura göre ne değişti. Batuhan'ın notları için en altta "Notlar" başlığı.

Akış:
1. Ajan taslağı `drafts/<slug>/`'a yazar.
2. Batuhan `review.md`'yi ve masalı okur.
   - Beğenirse: `swift run content-publisher originals approve <slug>` → klasör `published/`'a taşınır, `review.md` taşınmaz (git geçmişinde kalır).
   - Beğenmezse: "Notlar"a yazar. Ajan sonraki turda yeni masaldan önce notlu taslağı ele alır (metin ya da kapak yeniden).
   - Hiç istemezse: klasörü siler.
3. `swift run content-publisher publish --deploy` (mevcut komut) `published/` altındakileri akışa koyar.

## 4. Akış ve uygulama

Yayıncı (`Scripts/ContentPublisher`):
- `FeedFile`'a `originals: [OriginalFile]`. Her kayıt `tale.json`'un alanları + `cover: { path, sha256 }`.
- Kapak `hosting/public/content/originals/<slug>.jpg`'e kopyalanır. Kapak 1500 px yüksekliği aşmaz, JPEG.
- İmza `feed.json`'un tamamını kapsar, dolayısıyla kapak özetlerini de.
- `originals check [<slug>]`: alanlar, sayfa ve kelime sınırları, süre, karakter adları, dil kuralları (CLAUDE.md "Dil" grep'inin karşılığı ve uzun tire), kapağın varlığı ve boyutu. Ajan da Batuhan da aynı komutu çalıştırır; `publish` de bunu çağırır ve hata varsa yayımlamaz.
- `originals approve <slug>`: önce `check`, sonra taşıma.
- `FeedFile.schemaVersion` artmaz: eski uygulamalar `originals` anahtarını tanımaz ve yok sayar (Codable varsayılanı; testle sabitlenir).

Uygulama:
- `ContentFeed`'e isteğe bağlı `originals`. Model: `OriginalTale` (Gunluk modeli yanında), `ClassicTale`'e çevrilebilir (`origin: .orijinal`, `shelves: [.orijinal]` + moddan türeyen raf: `bedtime` → `.uyku`).
- `RemoteContentService` akışı aldıktan sonra kapakları indirir, SHA-256 doğrular, `Application Support/Originals/<slug>.jpg`'e yazar. Özeti tutmayan dosya silinir ve masal gizli kalır. Akıştan çıkan masalın kapağı da silinir.
- `ClassicsLibrary` Original rafını `RemoteContentStore`'dan okur; mevcut `originals` (günlük akış kapakları) aynen kalır.
- Kapak `UIImage(contentsOfFile:)` ile; asset kataloğu değil.
- Uzaktan içerik anahtarı boşsa (`MPContentSigningKey`) raf hiç görünmez.

## 5. Ajan

Dosya: `.claude/agents/original-writer.md`. Yazma izni yalnız `Content/Originals/drafts/`, `Content/Originals/world-proposals.md` ve değişiklik günlüğündeki kendi kaydı.

Bir tur:
1. `git status`: dal `main` değilse ya da `Content/Originals/` kirliyse durur, günlüğe sebebi yazar.
2. `WORLD.md` yoksa ilk tura (bölüm 2) geçer.
3. Notlu taslak varsa onu düzeltir; yoksa yeni masal.
4. Yayınlanmış ve taslaktaki masalları okur. Seçim: son dört masalda en az kullanılan mod ve yaş bandı (3-4 / 5-6 / 7-8 / 9-10), son sekiz masalda geçmeyen konu, karakterlerde dönüşüm.
5. Yazar. Kurallar: `WRITING_BRIEF.md`'nin dil ve güvenlik bölümleri, CLAUDE.md "Dil", dünya kitabı. Kişiselleştirme yok, çocuğun adı yok.
6. Öz denetim: yüksek sesle okuma ritmi, `originals check <slug>`.
7. Kapak: ajan `cover.svg`'yi WORLD.md'nin kapak stiline göre elle yazar, `python3 Tools/render_cover.py <slug>` ile `cover.jpg`'ye çevirir (qlmanage + sips, ağ yok). Kılavuz `Content/Originals/COVER_GUIDE.md`. Ajan kapağa ve 176 px hâline bakar (Read), tutmuyorsa en çok üç kez düzeltir, sonra `review.md`'ye not düşer.
8. Değişiklik günlüğüne kayıt, yalnız kendi dosyalarını commit'ler (`git add -p`), push yok.
9. Bildirim: "Onay bekleyen masal: <başlık>".

Ajan asla: `published/`'a yazmaz, `approve` ya da `publish` çalıştırmaz, uygulama kodunu, klasikleri ya da motoru değiştirmez.

## 6. Zamanlama

- Yerel zamanlanmış görev (scheduled-tasks): pazartesi ve perşembe 09:00, çalışma klasörü `MagicPaper/`, istem "original-writer ajanıyla bir tur".
- Mac kapalı ya da uykudaysa tur atlanır, telafi edilmez.
- Onay bekleyen taslak üçe ulaşırsa ajan yeni masal yazmaz, yalnızca hatırlatma bildirimi gönderir. Böylece okunmamış yığın birikmez.

## 7. Hata durumları

| Durum | Davranış |
|---|---|
| SVG çizilemedi (qlmanage çıktı vermedi) | Masal kapaksız taslak olarak kalır, `review.md`'ye yazılır; `check` kapaksız masalı onaylatmaz |
| `check` hatası | Ajan düzeltir; üç denemede geçmezse taslak "Notlar"da sebebiyle kalır |
| Kapak indirilemedi ya da özet tutmadı | Masal o cihazda görünmez, sonraki çekişte tekrar denenir |
| Akış imzası tutmadı | Bugünkü davranış: akış alınmaz |

## 8. Test

- PublisherKit: `OriginalFile` doğrulaması (sınırlar, karakter adları, dil kuralları), `approve` taşıması, imzanın kapak özetini kapsaması, `originals` içermeyen eski akışın aynı baytlarla imzalanması.
- Uygulama: `originals`'lı ve `originals`'sız akışın çözülmesi; eski akış modeli `originals`'ı yok sayar; özeti tutmayan kapakta masal gizlenir; `OriginalTale` → `ClassicTale` çevirisi.
- Ekran: simülatörde açık + koyu, en büyük Dynamic Type, iPhone SE + Pro Max; tasarım yasası grep'leri boş.
- Ajan: elle bir kuru tur (dünya önerisi), sonra bir masal turu.
- Testler ve simülatör yalnızca plan sonunda bir kez (Batuhan tercihi).

## Kapsam dışı

Kişiselleştirme, sesli anlatım, Original seriler, vitrine otomatik koyma, tam otomatik yayın, kapakların sonradan illüstratörle değiştirilmesi için bir araç (bugün `cover.jpg`'yi elle değiştirmek yeterli).
