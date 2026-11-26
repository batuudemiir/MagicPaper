# İş tanımı: beş arkadaş v3 metinlerini motora işle (Codex, motor hattı)

Batuhan 26 Kasım 2026 00:07'de (İstanbul) 90 kitabın yeni metnini onayladı. Bu iş motor hattına ait. Uygulama hattı yalnız pin güncellemesini yapacak.

## Girdi (bu klasörde)
- `v3/{adventure,learning,bedtime}-{fox,hedgehog,owl,cat,bear}.json`: 15 hücre, 90 kitap. Her kitap `sourceBookID` (payload v2'deki `id` ile birebir), `title` ve 8 sayfalık `pages` taşır. Sayfa sırası ve sayısı v2 ile aynı.
- `tum-kitaplar-once-sonra.md`: her kitabın v2 ve v3 metni yan yana.
- `p56_text_lint.py`: metin denetimi. v3 sonucu: 90/90 geçiyor, aynı iskelette birebir aynı sayfa payı %61'den %30'a indi, 90 başlığın hepsi farklı.

## Neyin değişmediği
- Kitap kimlikleri, mod/arkadaş/iskelet/olay eşlemesi, sayfa sayısı, çocuğun seçimleri (`childAgency`) ve olay zinciri.
- Çocuk adı yalnız izinli biçimlerde: Deniz, Deniz’in, Deniz’e, Deniz’i, Deniz’de, Deniz’den (tipografik ’).

## Neyin değiştiği
- Bütün sayfa metinleri ve başlıklar. Arkadaş artık sesi, huyu ve imza eşyasıyla birçok sayfada aktif (Tarçın turkuaz boyunluk ve koku tahminleri, Kestane hardal yaprak ve top olma, Yıldız gece mavisi/yıldız tüy ve sorular, Simit kırmızı tasma-zil ve şehir karşılaştırması, Böğürtlen bordo çanta, mor lekeli pati ve ninni).
- Bu yüzden sayfa başına `actorIDs`, `semantics`, `causalEvidence`, `artHandoff` ve C3 ContentSafety etiketleri yeniden çıkarılmalı. Eski etiketler metin hash'ine bağlı olduğu için yeni metinle fail-closed olur; bu beklenen davranış.

## İstenen adımlar
1. V1 ve v2 bayt/yol/davranışını koru. Yeni metni ayrı bir korpus ve paket olarak ekle (ör. `Content/Pilots/five-friends-56-voice-v3/` ve `five-friends-56-runtime-v3/`). Tarihsel v1/v2 snapshot'ları replay için kalsın.
2. Kaynakları, sayfa semantiğini, causal evidence'ı ve art handoff'u v3 metinden üret. Kitap başlıklarını `titleTemplate` olarak kullan.
3. C3 ContentSafety incelemesini v3 metin üzerinde baştan yap (tam alıntı ve hash bağlı). Özellikle bak: Böğürtlen'in yediği böğürtlenler yalnız kendi çantasından, orman meyvesi yenmiyor; arkadaş kaybolan eşyayı çocuk yerine bulmuyor.
4. `build_runtime_package.py` ile v3 paketini kur, `P56PinnedSource` için yeni packageVersion ve SHA256'yı yaz.
5. Doğrulama: seçili Release testleri, 90 kitap × 7 ad fixture, N1500 örnekleme ve `python3 p56_text_lint.py <yeni payload.json>` (hedef: 0 başarısız, ortak sayfa ≤ %40).
6. Sonucu `docs/ortak/codex-durum.md`'ye yaz. Uygulama hattı (Claude) etkin paketi ve pini birlikte günceller.

## Açık kalanlar
- `productionEnabled=false`, `artApproved=false` aynen kalır.
- Metinde bulduğun bir süreklilik ya da güvenlik sorunu olursa metni kendin düzeltme; sayfa kimliği ve öneriyle durum dosyasına yaz, metin tarafı düzeltsin.
