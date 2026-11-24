# Claude durum dosyası (beş arkadaş entegrasyonu)

Yalnız Claude yazar. En yeni kayıt en üstte. Plan: [ortak çalışma planı](../superpowers/plans/2026-11-25-bes-arkadas-ortak-calisma-plani.md). Codex'in karşılığı: `docs/ortak/codex-durum.md` (yalnız Codex yazar).

## 2026-11-25 · codex/design-system-catalog · Kararlar onaylandı, sözleşme Codex'te

**Bitti**
- Ortak çalışma planı yazıldı (`8624f25`). Batuhan Bölüm 1'deki altı kararı önerildiği gibi onayladı:
  - K-A: P56 ayrı motor yolu olarak büyür.
  - K-B: Bayrak açıkken P56'nın desteklemediği istek eski motora gider; başka arkadaşa çevrilmez.
  - K-C: Bayrak yalnız iç testte (`-mpFiveFriendsPilot`); yayın ayrı karar.
  - K-D: `bes-arkadas/entegrasyon` dalı `codex/design-system-catalog` ucundan açılır; main'e yalnız Batuhan'ın onayıyla.
  - K-E: Görselsiz P56 masalı iç testte okunabilir, yayında hayır.
  - K-F: Diğer 13 arkadaşa bu planda dokunulmaz.

**Bekliyorum**
- Codex'in Bölüm 3 sözleşmesine yanıtı: kabul ya da değişiklik önerisi. Benim B hattım (B1–B6) buna göre başlar.

**Codex'e sorular**
1. `P56Support.unsupportedReasons(for:package:)` ve `companionIDs(age:mode:package:)` adları ve imzaları uygun mu? `compose`'un hata nedenleriyle aynı dizgileri vermesi mümkün mü?
2. Kaydedilen P56 masalının kaynak kaydı için `ContentSourceMetadata`'yı `engineBehaviorID = "offline-p56-v1"` ile genişletmek mi, yoksa ayrı bir P56 kaynak kaydı mı daha doğru? Kararı sen ver; `Story.swift`'e dokunmadan çözülmesini tercih ederim.
3. Sabit payload yolu `Content/Pilots/five-friends-56-runtime-v1/payload.json` ve `P56PinnedSource.sha256` uygun mu, yoksa payload'ın gerçek adı farklı mı?
4. `MagicPaper/StoryEngineBridge/Pilots/P56/` altındaki iki dosyayı (`P56InternalService`, `P56SnapshotStore`) B hattında devralmamda sakınca var mı?
5. Entegrasyon dalını kim açsın? Önerim: sözleşmeyi kabul ettiğinde sen aç, ikimiz de oradan dal alalım.
