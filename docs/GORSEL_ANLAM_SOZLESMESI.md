# Görsel anlam ve sayfa kaynak izi: motor sözleşmesi

**Tarih:** 20 Kasım 2026 · **Dal:** `anlati-provenance` · **Taraflar:** motor ve içerik (Claude), görsel havuzu, bağlayıcı ve okuyucu (ChatGPT; `Tools/story_art_coverage_audit.py`, `StorySpotBinder`, `story-art-v1.json`)

## Kararlar (Batuhan, ChatGPT ile, 20 Kasım 2026)

1. Görsel anlam içerik satırlarında durur. Motor içeriği satırın neyi anlattığının kaynağıdır; uygulamanın sanat kataloğu bu anlamı hangi çizimin karşılayacağını bilir. Satırda dosya adı, çizim kimliği ya da görünüş tarifi yoktur.
2. Sayfa kaynak izi motor tarafından yazılır, sıralı parçalar olarak saklanır; kaynak kimliği metinden geri tahmin edilmez.
3. Görsel kararı mevcut `StoryPage.art` alanında saklanır; `StoryPage.picture` yoktur.
4. Eski kitaplar yeniden üretilmez. Kaynak izi olmayan sayfaya otomatik resim atanmaz.
5. Üç kimlik ayrıdır: kayıt kimliği (`object_torn_map_001`, anlatılan kanonik konu) → görsel anlam (konu + varlık + anlatı durumu) → çizim (`assetID` + `revision`).
6. Resimli sayfa sayısı sabit numaralarla değil, anlamca uygun sayfalardan ve yaşa göre yoğunlukla belirlenir; aynı resim tekrarlanarak kota doldurulmaz.

## Satır: `visual` ve `visualReview`

```json
{ "id": "...", "visual": [{"subject": "discovery", "presence": "present", "states": ["held"]}],
  "visualReview": "auto", "text": "..." }
```

| Alan | Değerler | Anlam |
|---|---|---|
| `subject` | `discovery`, `companion`, `setting` | Bağlanan içerikteki rol; motor kayıt kimliğine çevirir |
| `presence` | `present`, `remembered`, `intended` | Sahnede / hatırlanıyor ya da anlatılıyor / aranıyor ya da hedefleniyor |
| `states` | kapalı sözlük (`VisualMention.allowedStates`) | Anlatı durumu, görünüş değil |
| `visualReview` | `auto`, `reviewed` | Betikle önerildi / elle incelendi |

**Anlatı durumları.** `discovery`: found, held, examined, whole, piece, emitting, opened, given, returned, missing. `companion`: arriving, greeting, helping, together, worried, glad, resting, asleep. `setting`: day, evening, night, wide. Yeni durum önce sözlüğe eklenir; bütünlük denetimi sözlük dışını hata sayar.

**Üç hâl ayrıdır:**

- `visual` yok: satıra bakılmadı.
- `visual: []`: bakıldı, görünen öğe yok.
- `visual` dolu: listelenen öğeler.

**`auto` ile `reviewed` farkı:** `auto` liste eksiksiz değildir. Listede olan büyük olasılıkla doğru; listede olmayan bir öğenin sahnede olmadığı varsayılmamalı (zamirli anmalar, ör. "onu iki eliyle taşıdı", öneriye girmez). `reviewed` liste eksiksizdir.

**Bugünkü durum.** 2.721 satırdan 1.622'si `auto` etiketli (yer tutucu taşıyanlar), 1.099'u etiketsiz. Henüz `reviewed` satır yok. Öneri kuralı: yer tutucunun geçtiği cümle; konu yalın ya da tamlama ekliyse sahnede; belirtme/yönelme/ayrılma ekiyle ve en çok dört kelime sonra "hatırla/düşün/özle" geliyorsa `remembered`, "ara/bulmak/istedi/git" geliyorsa `intended`. Rastgele 30 satırlık örnekte 29 doğru.

**Elle inceleme sırası (öneri):** sayfa 1 (`notice_anomaly`), keşif sayfaları (`examine`, `approach`), çözüm (`succeed`, `restore`), kapanış (`warm_close`); yani bağlayıcının en çok kullanacağı sayfalar.

## Sayfa: `ComposedPage.provenance` → `StoryPage.provenance`

```
StoryPage.provenance?:
  schemaVersion: 1
  parts[]:            # sayfanın kuruluş sırasıyla
    sourceKind        # beat_line | refrain | recall
    sourceID          # satır kimliği; nakaratta "<blueprintID>#refrain.line" / "#refrain.finalLine"
    sourceTextDigest  # yazar metninin özeti (doldurulmamış hâli): çocuğun adına bağlı değil
    templateID?, beat?          # yalnızca beat_line
    contexts[]        # family, occasion, series, world (tür değil bağlam; sıralı)
    visual?[]         # {subject, subjectID (kayıt kimliği), presence, states}
    visualReview?     # auto | reviewed
```

- Nakarat için satır kimliği uydurulmaz; kimlik olay örgüsü + alan, sürüm izi metin özeti.
- Hatırlama satırı sayfa kurulduktan sonra en sona eklenir ve kendi parçasını alır. Yazar parmak izi (`authoredSourceFingerprint`) bu durumda bilerek düşer (`StorySpotProvenanceTests`); kaynak izi kalır.
- Olgu cümlesi masal düzeyinde kalır (`Story.fact`).
- Masal düzeyindeki düz `StoryOrigin.variantIDs` (satır soğuması için) değişmedi.
- Uygulama tarafında çözümleme hoşgörülüdür: tanınmayan tür okunur, bozuk parça atlanır.

## Değişmeyenler

Masal metni, seçim, seed ve parmak izleri bit bit aynı (`OfflineDeterminismTests`). Satır kimlikleri değiştirilmez; içerik yalnızca sona eklenir.
