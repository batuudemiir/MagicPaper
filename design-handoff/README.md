# MagicPaper Kids · Claude Code handoff paketi

Demo canvas v21'in tamamı, gerçek SwiftUI uygulamasına aktarılmak üzere paketlendi.

## Nasıl kullanılır

1. Klasörü uygulama reposunun köküne `design-handoff/` adıyla koy.
2. Claude Code'u repoda aç ve şunu yaz:
   > `design-handoff/CLAUDE.md` dosyasını oku ve `docs/IMPLEMENTATION_PLAN.md` içindeki Faz 0'dan başla.
3. Her fazdan sonra ekranı PNG ile yan yana kontrol et, planda kutuyu işaretle.

## İçinde ne var

| Klasör | İçerik |
|---|---|
| `screens/` | 45 ekran + 15 durum görüntüsü (@2x, Nunito ile) |
| `docs/SCREENS.md` | Her ekran: görüntü, rota, sunum, amaç, veri, gezinme, ekrandaki metinler |
| `docs/DESIGN_SYSTEM.md` | Renk, tipografi, boşluk, köşe, gölge, hareket, bileşenler, erişilebilirlik |
| `docs/BRAND_AND_MASCOT.md` | Logo, ikon, 14 maskot ve hangisinin nerede kullanıldığı |
| `docs/NAVIGATION.md` | Akış şeması ve tüm geçişler |
| `docs/ICONS.md` | Lucide → SF Symbol eşlemesi |
| `docs/ENGINE.md` + `engine/` | Masal motoru: katalog, şemalar, prompt örnekleri, 2427 test vektörü, çalışan referans motor |
| `docs/IMPLEMENTATION_PLAN.md` | Fazlara bölünmüş, ekran başına iş listesi |
| `ios/` | Asset catalog (80 renk, 20 görsel), tasarım sistemi Swift dosyaları, modeller, rotalar |
| `assets/` | Marka PNG'leri, Nunito fontları, Lucide SVG'leri |
| `reference/` | Ekranların kaynak HTML'i ve demo değişiklik günlüğü |

## Bilmen gerekenler

- Swift dosyaları derleyici olmadan yazıldı. İlk adım projeye ekleyip derlemek ve hataları düzeltmek (Faz 0).
- Maskot görselleri tek çözünürlük. Yayından önce tasarımcıdan @2x/@3x ya da vektör çıktı gerekiyor; asset adları aynı kalırsa kod değişmez.
- Ana sayfa Uyku kartında başlık maskota hafifçe değiyor; uygulamada başlığa sağdan boşluk ver.
- Referans motoru denemek için: `node engine/reference/run-tests.js` (2427 / 2427 geçiyor).
