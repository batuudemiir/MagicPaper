# Kitap boyunca görsel anlatım: başlangıç ölçümü

Altı kurgu × 100 sabit seed. Bu, üretim sıklığı veya tüm katalog garantisi değildir.
Kaynak etiketleri inceleme adayıdır; çizimle uyumluluk onayı değildir.

| Kurgu | Başarılı | Hata | Temiz olmayan | Pinli sayfa | Açılış | Orta | Son |
|---|---:|---:|---:|---:|---:|---:|---:|
| blueprint_threshold_crossing_001 | 100 | 0 | 0 | 52 | 44 | 7 | 1 |
| bp_threshold_joining_002 | 100 | 0 | 0 | 52 | 52 | 0 | 0 |
| blueprint_absence_looking_001 | 100 | 0 | 0 | 15 | 15 | 0 | 0 |
| bp_absence_retracing_002 | 100 | 0 | 0 | 44 | 44 | 0 | 0 |
| bp_threshold_together_003 | 100 | 0 | 0 | 39 | 36 | 2 | 1 |
| bp_absence_asking_003 | 100 | 0 | 0 | 49 | 49 | 0 | 0 |

## Ham özet

```json
{
  "closing": 1200,
  "errors": 0,
  "middle": 2400,
  "opening": 1200,
  "pages": 4800,
  "pinnedByPosition": {
    "closing": 2,
    "middle": 9,
    "opening": 240
  },
  "pinnedPages": 251,
  "presentEvidencePages": 2158,
  "storiesByPinnedPageCount": {
    "0": 356,
    "1": 238,
    "2": 5,
    "3": 1
  },
  "successes": 600,
  "uncleanSuccesses": 0,
  "unpinnedPages": 4549
}
```

## Sınırlar

- Açılış sayfa1–2, orta3–6, sonuç7–8 olarak sayıldı.
- Seçim geçmişi ve hatırlama olmadan, sabit sentetik Deniz profili kullanıldı.
- Metin, sayfa başına pin ve provenance kaydet/aç eşitliği XCTest ile sınanır.
- Pin, dosya/yerleşim cihazda görüldü anlamına gelmez.
- Eksik pin nedeni politika içinde ayrıntılı açılmıyorsa rapor bunu açıkça belirtir.
- Tam uygulama paketi, telefon ve yeni UI matrisi bu ölçümün parçası değildir.
