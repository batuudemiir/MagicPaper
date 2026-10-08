import SwiftUI

/// 43 · Üretim başarısız (`UretimHata`).
///
/// Bir cümle ve bir yol: ayrıntı log'a gider, ebeveyne değil (§29). Suçlamaz.
/// Teslimdeki "Yıldızın geri verildi" satırı yok: yıldız yok.
struct StoryCreationFailureView: View {

    let onRetry: () -> Void
    let onClose: () -> Void
    /// `StoryFailureReason(error).message`: güvenlik ayarının elediği masal
    /// için ayrı, sakin bir cümle.
    var message: String = "Bir şeyler yolunda gitmedi ama sorun sende değil. Tekrar deneyelim mi?"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat", action: onClose)
                Spacer()
            }
            .padding(.top, MPSpacing.sm)

            MPStateView(mascot: .surprised, tone: .pink, title: "Masal biraz takılı kaldı",
                        message: message) {
                MPButton(title: "Tekrar dene", systemImage: "arrow.counterclockwise", fullWidth: true, action: onRetry)
                    .padding(.horizontal, MPSpacing.xl)
                MPButton(title: "Ana sayfaya dön", kind: .ghost, action: onClose)
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
    }
}

#Preview("43 · Üretim başarısız") {
    StoryCreationFailureView(onRetry: {}, onClose: {})
        .background(MPColor.backgroundKid)
}
