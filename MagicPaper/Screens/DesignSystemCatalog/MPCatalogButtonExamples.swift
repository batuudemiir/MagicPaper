#if DEBUG
import SwiftUI

struct MPCatalogButtonExamples: View {
    let onAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            variants
            states
            sizes
            circles
        }
    }

    private var variants: some View {
        MPCatalogSample(title: "MPButton · Varyantlar", note: "primary / secondary / outline / ghost / danger") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPButton(title: "Birincil düğme", fullWidth: true) { onAction("Birincil düğme") }
                MPButton(title: "İkincil düğme", kind: .secondary, fullWidth: true) { onAction("İkincil düğme") }
                MPButton(title: "Giriş sağlayıcısı", kind: .outline, fullWidth: true) { onAction("Giriş sağlayıcısı örneği") }
                MPButton(title: "Şimdi değil", kind: .ghost) { onAction("Ghost düğme") }
                MPButton(title: "Silme örneği", kind: .danger, fullWidth: true) { onAction("Silme örneği; veri silinmedi") }
            }
        }
    }

    private var states: some View {
        MPCatalogSample(title: "MPButton · Durumlar", note: "Devre dışı / yükleniyor / uzun etiket. Yükleme örneği sürekli görünür.") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPButton(title: "Devre dışı", fullWidth: true) {}.disabled(true)
                MPButton(title: "Hazırlanıyor", fullWidth: true, isLoading: true) {}
                MPButton(title: "Birlikte okuyacağımız masalı seçelim", systemImage: "book", fullWidth: true) {
                    onAction("Uzun etiketli düğme")
                }
            }
        }
    }

    private var sizes: some View {
        MPCatalogSample(title: "MPButton · Boyutlar", note: "regular yukarıda; small / auth / hero aşağıda") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPButton(title: "Küçük düğme", kind: .secondary, size: .small) { onAction("Küçük düğme") }
                MPButton(title: "Giriş boyutu", kind: .outline, size: .auth, fullWidth: true) { onAction("Giriş boyutu") }
                MPButton(title: "Kahraman eylemi", size: .hero, fullWidth: true) { onAction("Kahraman eylemi") }
            }
        }
    }

    private var circles: some View {
        MPCatalogSample(title: "MPCircleButton", note: "Geri / kapat / devre dışı. Her eylemin Türkçe etiketi var.") {
            HStack(spacing: MP.S.x6) {
                MPCircleButton(systemImage: "chevron.left", accessibilityLabel: "Geri örneği") { onAction("Geri örneği") }
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat örneği") { onAction("Kapat örneği") }
                MPCircleButton(systemImage: "heart", accessibilityLabel: "Devre dışı favori örneği") {}.disabled(true)
            }
        }
    }
}
#endif
