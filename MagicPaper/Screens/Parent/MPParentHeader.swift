import SwiftUI

/// Ebeveyn modundaki her sayfanın üst satırı.
///
/// Mod anahtarı çocuk ana sayfasındakiyle aynı yükseklikte ve aynı köşede:
/// mod değişince parmağın altındaki kontrol kımıldamaz, geri dönmek için
/// aranacak bir şey olmaz.
struct MPParentHeader: View {
    @EnvironmentObject private var app: MPAppState

    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x1) {
            HStack(spacing: MP.S.x3) {
                Text(title)
                    .font(MP.F.displayLG())
                    .mpTightTracking(32)
                    .foregroundStyle(MP.C.textTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                MPModeSwitch(isParent: true) { parent in
                    if !parent { app.enterChildMode() }
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
}
