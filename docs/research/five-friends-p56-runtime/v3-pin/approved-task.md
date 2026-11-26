# İş tanımı: P56 etkin pinini v2'den v3'e geçir (uygulama hattı)

Onay: Batuhan, 26 Kasım 2026 00:57 (İstanbul), "geçir".

Kaynak: `codex/bes-arkadas/codex-motor` @ `708dfc0` (rapor: `docs/research/five-friends-p56-runtime/v3/REPORT.md`, durum: `docs/ortak/codex-durum.md`).
- Paket: `Content/Pilots/five-friends-56-runtime-v3/payload.json`
- SHA256: `855870c8462f167b4031058897c2ddfc8c5f513802ad057758c86e3ff5316c3c`
- `ff30587` adayının SHA'sı (`3abe00cd…`) KULLANILMAZ.

Codex'in koşulları (codex-durum.md, 708dfc0):
1. Etkin sürüm ve SHA birlikte: `P56PinnedSource.packageVersion = five-friends-56-runtime-v3` + yukarıdaki SHA256; uygulama bundle'ına v3 payload'ın byte'ları aynen kopyalanır (byte eşitliği ve SHA kontrolü).
2. SnapshotStore v3'ü tanır; v1 ve v2 arşivleri korunur, eski kayıtlar kaynaksız okunmaya devam eder.
3. Motorda tarihsel v2 SHA ve v2 test referansları etkin pinden ayrılır (v1SHA256 gibi ayrı tarihsel sabit).
4. v1/v2 dosya yolları ve byte'ları değişmez. `productionEnabled=false`, `artApproved=false` kalır. Bayrak Debug'da `-mpFiveFriendsPilot YES`.
5. Varsayılan `mostProtective` politikayla gerçek v3 yazma/kaydetme/açma ve bayrak açık/kapalı simülatör kapısı.

Kapsam dışı: Dalga 1 ve Dalga 2 metinleri (ayrı korpus işi), görsel bağlama, main/entegrasyon'a push.
Bitince `docs/ortak/claude-durum.md`'ye SHA, test sonuçları ve dokunulan dosyaları yaz.
