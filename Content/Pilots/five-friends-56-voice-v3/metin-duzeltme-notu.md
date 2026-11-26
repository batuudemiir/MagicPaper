# Codex için: METIN_DUZELTME_LISTESI yanıtı

Kaynak: `ff30587` içindeki `docs/research/five-friends-p56-runtime/v3/METIN_DUZELTME_LISTESI.md`.

## Ne değişti
1. **Sayfa bütçesi.** `p56_text_lint.py` artık motorun `TextMetrics` mantığını birebir uyguluyor: kelime bölme, noktalama kırpma, cümle sonu ve küçük harfle devam eden konuşma. Sınırlar: 5-6 yaşta sayfa 18-38 kelime, cümle en fazla 14 kelime.
   - v3 (90 kitap): 177 sayfa uzatıldı. 18 kelimenin altında sayfa kalmadı.
   - Dalga 1 (90 kitap): 548 sayfa uzatıldı (415 farklı metin). 18 kelimenin altında sayfa kalmadı.
   - Uzatmalar sayfanın sonuna eklenen kısa cümleler. Olay akışı ve çocuğun kararı değişmedi.
2. **L3 ayı, nefes tutma şakası kaldırıldı.** `pilot56_book_l3_bear_v1`'in yeni başlığı "Böğürtlen Böğürtlenle Sayıyor". Böğürtlen artık bekleme süresini çantasındaki böğürtlenlerle sayıyor (s3, s5, s7). Nefes tutma hiçbir yerde geçmiyor.
3. **A2 Yıldız, katkı ile childAgency uyumu.** Üç kitapta (v1, event02, event03) Yıldız ilk parçayı pençeleriyle sabit tutuyor, yerleştiren Deniz. Bu, "arkadaşı bir parçayı yerinde tutar" sözleşmesine uyuyor. Görselde kanatla tutma çizilmesin, pençeyle tutma çizilsin.

## Denetim (180 kitap)
- 180/180 lint geçiyor (kural kalıbı, cümle uzunluğu, sayfa bütçesi, isim, mizah).
- Hücre içi 4 kelimelik öbek örtüşmesi en yüksek %17 (kapı %20). v3 ve dalga 1 birlikte ölçüldü.
- Dalga 1'de arkadaşlar arası birebir aynı sayfa payı %37 (kapı %40).
- 180 başlığın hepsi farklı. Deniz ekleri yalnız izinli biçimlerde.

## Senden beklenen
Metinler değiştiği için C3 güvenlik notları ve anlam/sanat etiketleri yeni hash'lere göre yeniden üretilmeli (eski etiketler kapalı kalmalı). Sonra V3 aday paketini yeniden kur ve 1.500 deneme ölçümünü tekrarla. Pin'i Batuhan onaylamadan güncelleme.
