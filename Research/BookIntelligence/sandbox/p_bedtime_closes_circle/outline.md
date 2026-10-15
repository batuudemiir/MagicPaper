# Prototip: p_bedtime_closes_circle — uyku çerçevesi (8 sayfa, 5-6)

**Durum:** sandbox taslağı, üretim içeriği değil. Kitaplardan metin alınmadı; tüm satırlar özgün.
Gerçek çocuk verisi yok. **Örnek bağlama:** `{{child.name}}` = Ela · `{{companion.name}}` = Pıtırcık (kirpi) · aile: `charge` (VI-1 iskeleti).

## Fikir

Bugünkü uyku masalları dışarıda açılıyor (`notice_anomaly` bahçede/ormanda) ve çoğu `warm_close` varyantı
"eve yürürken" bitiyor. Kitaplardaki daire *yer eşleşmesi* değil, *yatak çerçevesi*: masal yatakta/pencerede
başlar, macera dışarıda olur, son sayfa aynı yatağa/pencereye döner. Öneri: yeni slot yok; yalnızca
bedtime için bir s.1 çerçeve cümlesi ve bedtime etiketli bir `warm_close` alt kümesi.

Yoğunluk motorun 0-3 ölçeğinde (`EmotionalArc.swift`). Tepe en geç s.5 (5/8 = %62, "üçte iki" sınırının altında).

| s. | beat (VI-1'den) | duygu → yoğunluk | yer | taslak satır (özgün) |
|---|---|---|---|---|
| 1 | notice_anomaly + **çerçeve** | ease → 0 | **yatak, pencere** | Ela yorganını çenesine çekti. Pencereden bahçe görünüyordu; çitin dibinde küçük bir ışık kıpırdadı. |
| 2 | examine | curiosity → 1 | bahçe | Terlikleriyle bahçeye çıktı. Işık değil, çiy tutmuş minik bir dikendi bu. |
| 3 | meet_companion | tenderness → 1 | bahçe | Dikenlerin altından iki kara göz baktı. Pıtırcık yuvasının yolunu bulamıyordu. |
| 4 | take_charge | duty → 1 | bahçe | "Ben sana yol gösteririm," dedi Ela, sesini alçaltarak. |
| 5 | tend | effort → 2 (**tepe**) | çit dibi | Yapraklar ıslaktı, çimenler ayak bileklerini gıdıklıyordu. Ela fenerini yere doğru tuttu, adım adım ilerlediler. |
| 6 | patient_wait | patience → 2→**1'e indirilir** (öneri: `tenderness`) | yuva önü | Pıtırcık yuvanın kapısında durdu, kokladı, bekledi. Ela da bekledi. |
| 7 | restore | relief → 0 | yuva | Sonunda içeri süzüldü. Yuvadan uykulu, minik bir hışırtı geldi. |
| 8 | warm_close (bedtime alt kümesi) | calm → 0 | **aynı yatak, aynı pencere** | Ela yine yorganının altındaydı. Pencereden çitin dibine baktı; ışık yoktu artık, yalnızca uykulu, sessiz bahçe. Gözleri kapandı. |

Yoğunluk dizisi: 0,1,1,1,2,1,0,0 — tepe s.5, son iki sayfa en düşük. Bugünkü VI-1 dizisi 0,1,1,1,2,2,0,0 (son tepe s.6, %75).

## İçerik tarafında gerekenler (karar verilirse)

- `beat_notice_anomaly` için bedtime etiketli 3-5 çerçeve varyantı (yatak/pencere → dışarıda bir işaret).
- `beat_warm_close` için 4-6 yeni bedtime varyantı + mevcut 5 yatak/oda varyantının etiketlenmesi; varyant s.1'deki nesneye (pencere, yorgan, ışık) geri dönmeli. Bu, s.1 ile s.8 arasında bir eşleşme alanı ister (`frame: window|bed|blanket`) — motor sahibinin kararı.
- VI-1'de s.6 duygusu `patience` (2) yerine `tenderness` (1): tepe s.5'e çekilir. Bu bir blueprint değişikliği, story-engine ile.
