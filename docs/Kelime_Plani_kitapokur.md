# Kelime planı: masaldaki cümle + nadir kelime raporu

21 Ekim 2026 · durum: **plan, kod yok**

Kaynak fikir: [ka1nsha/kitapokur](https://github.com/ka1nsha/kitapokur) (İngilizce PDF'lerden
kelime öğreten ev sunucusu okuyucusu). Repo'da LICENSE yok: kod "tüm hakları saklı" sayılır,
**kopyalanmaz**. Aldığımız şey yaklaşım ve eşik fikirleri; kod sıfırdan, Türkçeye ve bizim
yapımıza göre yazılır.

Almadıklarımız: FSRS flashcard, puanlı gramer testi, seri/istatistik ekranı (ilke 7),
Google'ın anahtarsız çeviri uç noktası (gizlilik, maliyet), Tatoeba örnek cümleleri
(çocuğa uygunluğu denetlenmemiş).

---

## Adım 0 · Önkoşullar (iki iş için de)

- [ ] **Disk.** 21 Ekim'de boş alan 136 MB; Bash çıktı dosyası bile yazamıyor. En az ~5 GB
      açılmadan derleme/test yok. (Bkz. FAZ 9 notu: yeni DerivedData açma.)
- [ ] **Sevk edilen katalogda sözlük kelimesi var mı?** `GlossaryTests` başındaki not
      "shipped corpus teaches no words yet (the draft waits for review)" diyor. Katalog
      JSON'larında `words` / sözlük girdisi sayılır.
  - Varsa: sıra **A → B**.
  - Yoksa: A canlıda hiçbir şey göstermez (Yeni kelimelerim boş). Sıra **B → A**; B'nin
    raporu sözlük taslağını doldurmanın aracı olur.
- [ ] Katalog metninin hangi dosyalardan birleştiği (`pilot_library_v1.json` + `Content/…`)
      `ContentCatalogLoader`'ın `mergedSources` listesinden doğrulanır; B bu listeyi okur.

---

## A · "Yeni kelimelerim" kartında masaldaki cümle

### Ne katar
Kelime tanımı, çocuğun yaşadığı sahneye bağlanır: "fener" kartının altında
*"Ragi feneri yakıp mağaraya girdi."* Ebeveyne "hatırlıyor musun?" sorusunu verir
(aile ritüeli, aile anıları). Puan, test, sayaç eklemez.

### kitapokur'dan aldığımız
- Kelime, ilk geçtiği **cümleyle** birlikte gösterilir.
- Cümle bölme kuralı: `. ! ? …` (ardından kapanan tırnak/parantez olabilir) **ve** sonraki
  karakter büyük harf, rakam, açılan tırnak ya da tire ise böl.
- Uzun cümle sınırı: kelime sınırında kes, sonuna " …" koy. Onların 700 karakteri bize
  fazla; **140 karakter** (kartta en fazla 3 satır) ile başlanır.
- Birden fazla geçişte kısa olan tercih edilir (onlarda 260 karakter üstü uzun sayılır).

### Bizim yapımız (inceleme sonucu)
- `StoryPage.text` saklanıyor; `StoryWord.surface` kelimenin sayfadaki asıl yazılışı
  (`Models/Story.swift:239`). **Göç gerekmez**: cümle, saklanan metinden kesilir.
- FAZ 17 öncesi sayfalarda `words == nil`; bunlar zaten toplanmıyor.
- Sözlük kelimesi seçimi `MPVocabulary.collectedWords` (`Screens/MPVocabulary.swift:109`).

### Değişiklikler
1. **`MPVocabulary`** (alan mantığı, görünümde değil):
   - `CollectedWord`'e `sentence: String?` eklenir.
   - Yeni saf fonksiyon `static func sentence(containing surface: String, in text: String) -> String?`:
     metni cümlelere böler, `surface`'i `tr_TR` büyük/küçük harf katlamasıyla arar
     (`ReaderWords.attributed` ile aynı arama), bulunan cümleyi kırpar. Bulunamazsa `nil`.
   - `collectedWords` en erken geçişin sayfasından cümleyi doldurur.
2. **`NewWordsView`**: anlamın altına cümle; `surface` cümle içinde kalın (renk tek başına
   bilgi taşımaz). Font `MP.F.body*`, renk `MP.C.textBody`/`textSecondary`, boşluk `MP.S`.
   `sentence == nil` ise satır hiç çizilmez. Dinle düğmesi: "kelime. anlam. cümle".
   - Not: `NewWordsView` eski `MPSpacing`/`mpText` token'larını kullanıyor; dosyanın geri
     kalanı bu işte düzeltilmez (CLAUDE.md: eski ihlal ayrı turda), yalnız yeni satır yasaya uyar.
3. **Erişilebilirlik**: kartın birleşik etiketine cümle eklenir ("Masalda: …").
4. **Okuyucu kartına (`ReaderWordCard`) eklenmez**: çocuk cümleyi zaten sayfada görüyor.

### Testler (`MagicPaperTests`, önce yazılır)
- Kelime ortadaki cümlede → yalnız o cümle.
- Son cümle noktasız biter → yine bulunur.
- Diyalog: `— Bak, fener! dedi Ragi.` → tirede bölünmez, cümle bütün kalır.
- `İ/ı` katlaması: "Işık" ↔ "ışık" bulunur, "İşık" bulunmaz.
- 140 karakter üstü → kelime sınırında kesilir, " …" ile biter, `surface` kesilen kısımda kalmaz.
- `surface` metinde yok → `nil`.
- Çocuğun adı cümlede geçebilir: cihazda kalır, hiçbir yere loglanmaz (ilke 10).

### Doğrulama
CLAUDE.md doğrulama grep'leri boş; simülatörde açık + koyu, en büyük Dynamic Type,
iPhone SE + Pro Max ekran görüntüsü.

**Tahmin:** yarım gün.

---

## B · Yaş bandına göre nadir kelime raporu (içerik aracı)

### Ne katar
Bugün 3-4 yaş masalına ağır bir kelimenin girmediğini yalnız yazarın dikkati garanti ediyor.
Rapor, her bandın metnindeki **nadir ve açıklamasız** kelimeleri tek listede gösterir; yazar ya
sadeleştirir ya da sözlüğe ekler. "Yeni kelimeye yazar karar verir" ilkesi
(`Glossary.swift`) korunur: araç öneri verir, karar yazarındır. Uygulamaya girmez, çalışma
anı maliyeti sıfır, LLM yok.

### kitapokur'dan aldığımız (Türkçeye uyarlanmış)
| kitapokur | bizde |
|---|---|
| PDF metni, tire birleştirme, NFKC | Katalog JSON satırları; NFKC; `{{slot}}` yer tutucuları ve yapışık ekleri silinir |
| `simplemma` ile kök (`lang="en"`) | `simplemma` `lang="tr"` |
| Kök şüpheliyse: kökün Zipf'i < kelimenin Zipf'i − 1,5 → reddet, ek kuralları dene | Aynı kontrol; Türkçe ek adayları (`-lar/-ler`, iyelik, hâl, `-ıyor`, `-dı`, `-mış`…) uzundan kısaya soyulur, Zipf eşiğini geçen ilk aday alınır, yoksa kelimenin kendisi |
| `wordfreq.zipf_frequency(w, "en")` | `zipf_frequency(w, "tr")` |
| Aday: kök ≥ 3 harf, 0 < Zipf < 5,0 | Aynı |
| Özel ad: cümle ortasında büyük harfle geçip hiç küçük harfle geçmeyen | Aynı + katalogdaki karakter/arkadaş adları listesi doğrudan elenir |
| Seviye eşikleri A2 5,0 · B1 4,5 · B2 4,0 · C1 3,5 | **Başlangıç** eşikleri: 3-4 → 4,5 · 5-6 → 4,0 · 7-8 → 3,5 · 9-10 → 3,0. İlk çalıştırmada bir yazarla kalibre edilir |
| Örnek cümle: ilk geçiş, 260 üstüyse daha kısası | Aynı mantık (A ile ortak kural) |
| `lru_cache` | Aynı (bir koşu birkaç bin kelime) |

### Çıktı
`Tools/nadir_kelime_raporu.py` → `docs/research/nadir_kelimeler_<tarih>.md` (+ aynı veri CSV):

Her bant için, Zipf'e göre artan sırada:
`kök · Zipf · geçiş sayısı · geçtiği blueprint/variant kimlikleri · örnek cümle · sözlükte mi?`

İki ek bölüm:
- **Gereksiz açıklama**: sözlükte olup o bant için çok yaygın olan kelimeler (Zipf ≥ bant eşiği + 1).
- **Bant dışı açıklama**: `bands` alanı bu bandı içermeyen ama bu bandın metninde geçen girdiler.

### Sonraki adım (bu planın dışında, karar gerekir)
- `Content/kelime_izinleri.json`: yazarın "bu kelime bu bantta kalsın" dediği kökler; rapor bunları göstermez.
- Rapor kararlı hale gelince `CatalogIntegrity` yanına bir uyarı testi
  (önce uyarı, kırmızı değil). FAZ 15 uzaktan içerik yayınından önce çalışır.

### Bağımlılıklar
`wordfreq` (Apache 2.0; veri CC-BY-SA 4.0) ve `simplemma` (MIT). Yalnızca geliştirici
makinesinde, `Tools/` altında; uygulamaya ve içerik paketine **girmez**. Kurulum disk
alanı ister (Adım 0).

### Testler
`Tools/test_nadir_kelime_raporu.py` (stdlib `unittest`):
- `{{child_name}}'nin feneri` → slot silinir, "feneri" kalır.
- "ağacın" → "ağaç" (Zipf kontrolüyle), "kafeneri" → "fener" **değil**.
- Katalog adı ("Ragi") ve cümle ortası büyük harfli özel ad elenir.
- Bant eşiği: aynı kelime 3-4'te listede, 9-10'da değil.
- Sözlükte olan kelime "açıklamasız" listesine girmez.

**Tahmin:** 1–2 gün (kalibrasyon dahil).

---

## Sahiplik

- A: `Screens/MPVocabulary.swift`, `Screens/KidCorner/NewWordsView.swift`, yeni test dosyası.
  Paylaşılan dosya değil; çakışma için çalışmadan önce `git status` ve dal kontrolü
  (paralel oturumlar aynı checkout'ta dal değiştirebiliyor).
- B: yalnız `Tools/` ve `docs/research/`. Motor ve katalog dosyalarına dokunmaz.

## Bitti tanımı
Testler yeşil, doğrulama grep'leri boş, (A için) ekran görüntüleri alındı,
`DEMO_CHANGELOG.md` kaydı yazıldı.
