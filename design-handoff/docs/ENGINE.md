# Masal motoru

Kaynak: "MagicPaper masal motoru şartnamesi" (Claude Docs) ve Masal Motoru Lab v2. Bu klasördeki her şey Lab'deki motorun birebir çıktısıdır.

## Dosyalar

| Yol | Ne işe yarar |
|---|---|
| `engine/reference/engine.js` | Saf JS referans motor. Backend bu davranışı port eder. |
| `engine/reference/run-tests.js` | `node engine/reference/run-tests.js` → 2427 / 2427 geçmeli |
| `engine/catalog.json` | 12 dünya, yan karakterler, yasaklı konular, uzunluk, yaş bantları, tonlar, korku seviyeleri, filtre listeleri, örnek Story Bible, hazır senaryolar |
| `engine/schemas/*.schema.json` | StoryRequest, StoryResponse, StoryJob |
| `engine/prompts/*.example.txt` | Normal senaryo için üretilmiş sistem ve kullanıcı mesajı |
| `engine/fixtures/test-vectors.json` | 2427 test: girdi, ebeveyn kararı, StoryRequest, beklenen ve gerçek sonuç, filtre çıktısı |
| `engine/fixtures/sample-runs.json` | 11 hazır senaryonun tam koşusu (prompt, masal, kontrol listesi) |
| `ios/Models/StoryEngineModels.swift` | Şemaların Codable karşılığı |

## Akış

```
Uygulama → Backend API → 1. İstek filtresi → 2. Onay kuyruğu → Prompt → Yazar model → 3. Kontrol → Kaydet → Okuyucu
              │                 │                   │                                     │
              ▼                 ▼                   ▼                                     ▼ (1 kez yeniden yaz)
          402 / 403            422                 422                                   500
```

1. **Uygulama** seçimleri `StoryRequest`'e çevirir. Uyku modunda `tone = sakin`. Ad kuralı: `^[A-Za-zÇĞİÖŞÜçğıöşü \-]{1,20}$`, uymazsa 400 `invalid_request` (istemcide de doğrula). Model anahtarı uygulamada yoktur.
2. **Backend API**: yıldız 0 ise 402 `no_stars` (YildizBitti). Kilitli dünya ya da `uzun` uzunluk ve plan ücretsiz ise 403 `locked_option`. Geçerse 1 yıldız rezerve edilir, iş açılır.
3. **İstek filtresi** serbest metni (yalnızca `freeText != off` ise) ve karakter adlarını tarar. `HARD` listesi → `uygunsuz` → 422 `input_rejected`, yıldız iade. `SOFT`, enjeksiyon, kişisel veri ve ebeveynin yasakladığı konu → `sınırda`; istek modele "yumuşat" notuyla gider. Telefon, e-posta ve adres maskelenir.
4. **Onay kuyruğu** yalnızca `freeText = approval` ve istek boş değilse bekler (OnayBekleyenler ekranı). Karar: onay, yumuşatarak onay, red. Red → 422 `parent_rejected`, yıldız iade.
5. **Prompt**: sabit sistem promptu + isteğe özel mesaj. Serbest metin `<istek>` etiketi içinde veri olarak gider.
6. **Yazar model** sayfalı JSON döndürür (`StoryResponse`).
7. **Kontrol**: şema, ret alanı, sayfa sayısı, sayfa başı kelime (yaş bandı ±%15), kahraman adı başlıkta ve metinde, yeni kelimeler metinde (kök eşleşmesi), yasaklı kelime yok, ebeveyn konuları yok, mutlu ya da huzurlu son. İlk başarısızlıkta sorunlar prompta eklenip 1 kez yeniden yazılır; ikincide 500 `generation_failed`, yıldız iade.
8. **Kaydet**: yıldız kesinleşir, seri ise Story Bible yeni bölümle güncellenir, uygulamaya SSE ile haber verilir.

## Yaş bantları

| Bant | Sayfa başı kelime | Yeni kelime | Dil kuralı |
|---|---|---|---|
| 3-4 | 25–40 | 1 | Çok kısa, tekrarlı cümleler |
| 5-7 | 40–70 | 1 | Kısa, tek fiilli cümleler |
| 8-10 | 70–110 | 2 | Orta uzunluk, diyalog serbest |
| 11-12 | 100–150 | 3 | Uzun cümle ve betimleme serbest |

Uzunluk: kısa 5, orta 8, uzun 12 sayfa (uzun premium).

## Hata → ekran eşlemesi

| Kod | HTTP | Yıldız | Ekran |
|---|---|---|---|
| invalid_request | 400 | harcanmaz | Yarat 2, alan altı hata |
| no_stars | 402 | harcanmaz | YildizBitti |
| locked_option | 403 | harcanmaz | Kilitli kart, "Büyüğüne sor" |
| input_rejected | 422 | iade | "Bunu bir büyüğüne soralım." |
| parent_rejected | 422 | iade | Aynı nazik mesaj |
| generation_failed | 500 | iade | UretimHata |

## Uygulamadaki yansıması

- **Uretim (Masal yazılıyor)** aşamaları `StoryJobStatus`'a bağlanır: queued → (waiting_approval) → writing → checking → (rewriting) → done.
- **Okuyucu** `pages[].text`, `mood` ve `wordList`'i kullanır. Kelime vurgusu kök eşleşmesiyle yapılır (`stemOf` in engine.js: -mek/-mak düşer, aksi halde son 3 harf, en az 4 harf kalır).
- **Yeni kelimelerim** `wordList`'ten beslenir. **Seri masal** Story Bible'dan.
- Kilitli dünyalar `catalog.json` içinde `locked: true`. Uygulamadaki dünya listesi bu katalogdan gelmeli, kodda sabitlenmemeli.

## Backend için kabul ölçütü

`test-vectors.json` içindeki her vektör için backend aynı `request` ile çağrıldığında `expected.outcome`, `expected.stopAt` ve `expected.code` aynı çıkmalı. Gerçek modelle `rewrite` alanı karşılaştırılmaz.
