import SwiftUI

/// 44 · İnternet yok (`InternetYok`), tek bileşen.
///
/// Masallar cihazda yazılır ve okunur; bağlantı yalnızca giriş, ebeveyn onayı
/// ve hesap eşitlemesi için gerekir (FAZ 17 kararı). Bu yüzden bu bildirim
/// yalnızca o ekranlarda görünür; masal yazarken ya da okurken hiç görünmez.
/// Maskot isteğe bağlı: ebeveyn alanında maskot yok.
struct MPOfflineNotice: View {
    var title: String = AccountCopy.offlineTitle
    var message: String = AccountCopy.offlineNotice
    var showsMascot: Bool = true
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: MPSpacing.md) {
            if showsMascot {
                MascotImage(mascot: .thinking, width: 64)
                    .accessibilityHidden(true)
            } else {
                MPIcon("wifi.slash", size: 20, weight: .semibold)
                    .foregroundStyle(MPColor.textSecondary)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                Text(message).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let onRetry {
                    MPButton(title: AccountCopy.retry, kind: .soft, size: .small, action: onRetry)
                        .padding(.top, MPSpacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MPSpacing.lg)
        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.card))
        .mpShadow(.card)
        .accessibilityElement(children: .contain)
    }
}
