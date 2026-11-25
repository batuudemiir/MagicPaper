# P56 v3 uygulama planı

Onaylı girdi: bes-arkadas-metin-v3/metin-entegrasyon-is-tanimi.md; metin 26 Kasım onaylıdır. Yeni tasarım kararı değil, mevcut exact-source paketleme sözleşmesinin ayrı v3 teslimidir. Root motor worktree'de, uygulama Claude'da. v1/v2 paketleri ve davranışı değişmez. Uygulama pini değişmez.

1. Onaylı 15 dosyayı değişmez girdi olarak yeni voice-v3 korpusuna al; 90 kitap kimliğini v2 ile eşleştir, giriş byte/hash manifestini kaydet.
2. Content-library uzmanı tüm sayfaların yeni eylem/aktör/prop/zaman/causal alıntılarını çıkarır. Privacy-safety uzmanı tüm 720 sayfa ve 90 başlığı baştan okur; berry provenance, çocuk çözümü ve güvenlik dahil. Sahte reviewed/atomic/art onayı yok.
3. Yeni corpus builder her sayfanın full-page kaynağını yeni kimlik/SHA ile bağlar; eski sayfa metadata'sını taşımaz. V3 payload ayrı, tek korpus, schema2; 90 kitap/720 sayfa/15 hücre/30 çift/3 olay korunur.
4. Ayrı v3 loader/test önce yazılır; v2 validator gevşetilmez. Kaynak, başlık, safety, lineage ve temporal trace doğrulanır. V3 tarihi metadata referansı tanınır; v1/v2 aynı kalır.
5. Son kapıda tek seçili Release koşusu: 90×7 fixture, N1500 ilk deneme, exact-source ve tarihsel regresyonlar. Verilen lint tüm paket üzerinde; ortak sayfa ≤%40 ayrıca assert edilir. Metin sorunu varsa sayfa kimliğiyle raporla; düzeltme yok, retry/reseed yok, guard gevşetme yok.
6. V3 tamamen geçerse engine etkin sürüm/SHA sabitini hazırla; uygulama etkin paketini Claude değiştirir. Eksik veya başarısız metinde aktif pin v2 kalır, aday v3 inceleme çıktısı ve engeller teslim edilir.
7. Tam kaynak/önce-sonra/somut poz-eylem görsel handoff, durum belgesi, günlük ve yalnız sahip olunan dosyalar commit. Karşılıklı kabul olmadan entegrasyon yok; yayın/art kapalı.

Başlangıç incelemesi: 171 sayfa whitespace kelime sayımında mevcut 18–38 dışında görünüyor; kesin sayı Swift TextMetrics ile son kapıda doğrulanacak. A3 olaylarının sayfa sırası frozen typed trace ile çelişebilir. Bunlar etiketi uydurularak kapatılmayacak.
