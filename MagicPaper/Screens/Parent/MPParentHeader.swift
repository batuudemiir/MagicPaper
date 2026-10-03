import SwiftUI

/// Ebeveyn modundaki her sayfanın üst satırı.
///
/// Mod anahtarı çocuk ana sayfasındakiyle aynı yükseklikte ve aynı köşede:
/// mod değişince parmağın altındaki kontrol kımıldamaz, geri dönmek için
/// aranacak bir şey olmaz.
struct MPParentHeader: View {
    @EnvironmentObject private var app: MPAppState

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x1) {
            // Erişilebilirlik boyutlarında anahtar başlığın üstüne çıkar:
            // aynı satırda "Çocuklar" bile "Çocuk…" diye kesiliyordu.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: MP.S.x2) {
                    modeSwitch
                    titleText
                }
            } else {
                HStack(spacing: MP.S.x3) {
                    titleText
                    Spacer(minLength: 0)
                    modeSwitch
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(MP.F.bodySM())
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.vertical, MP.S.x1)
    }

    private var titleText: some View {
        Text(title)
            .font(MP.F.displayLG())
            .mpTightTracking(32)
            .foregroundStyle(MP.C.textTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityAddTraits(.isHeader)
    }

    private var modeSwitch: some View {
        MPModeSwitch(isParent: true) { parent in
            if !parent { app.enterChildMode() }
        }
    }
}
