# Kitap boyunca görsel anlatım: başlangıç ölçümü

Altı kurgu × 100 sabit seed. Bu, üretim sıklığı veya tüm katalog garantisi değildir.
Kaynak etiketleri inceleme adayıdır; çizimle uyumluluk onayı değildir.

| Kurgu | Başarılı | Hata | Temiz olmayan | Pinli sayfa | Açılış | Orta | Son |
|---|---:|---:|---:|---:|---:|---:|---:|
| blueprint_threshold_crossing_001 | 100 | 0 | 0 | 44 | 44 | 0 | 0 |
| bp_threshold_joining_002 | 100 | 0 | 0 | 51 | 51 | 0 | 0 |
| blueprint_absence_looking_001 | 100 | 0 | 0 | 9 | 9 | 0 | 0 |
| bp_absence_retracing_002 | 100 | 0 | 0 | 38 | 38 | 0 | 0 |
| bp_threshold_together_003 | 100 | 0 | 0 | 36 | 36 | 0 | 0 |
| bp_absence_asking_003 | 100 | 0 | 0 | 43 | 43 | 0 | 0 |

## Ham özet

```json
{
  "closing": 1200,
  "errors": 0,
  "middle": 2400,
  "opening": 1200,
  "pages": 4800,
  "pinnedByPosition": {
    "opening": 221
  },
  "pinnedPages": 221,
  "presentEvidencePages": 2158,
  "storiesByPinnedPageCount": {
    "0": 379,
    "1": 221
  },
  "successes": 600,
  "uncleanSuccesses": 0,
  "unpinnedPages": 4579
}
```

## Sınırlar

- Açılış sayfa1–2, orta3–6, sonuç7–8 olarak sayıldı.
- Seçim geçmişi ve hatırlama olmadan, sabit sentetik Deniz profili kullanıldı.
- Metin, sayfa başına pin ve provenance kaydet/aç eşitliği XCTest ile sınanır.
- Pin, dosya/yerleşim cihazda görüldü anlamına gelmez.
- Eksik pin nedeni politika içinde ayrıntılı açılmıyorsa rapor bunu açıkça belirtir.
- Tam uygulama paketi, telefon ve yeni UI matrisi bu ölçümün parçası değildir.
