import SwiftUI

/// 38 · Abonelik bitti (`AbonelikBitti`): ücretli plan sona erdi, ne kalır,
/// ne kilitlenir. Hiçbir masal silinmez. Ebeveyn alanında, Özet'teki karttan
/// açılır; görülünce kart kapanır. Tasarımdaki yıldız ve ses kaydı satırları
/// yok (yıldız yok, ses kaydı FAZ 18).
struct SubscriptionExpiredView: View {
    let onRenew: () -> Void
    let onClose: () -> Void

    private let kept = ["Kitaplıktaki tüm masallar", "Cihazda yazılan yeni masallar", "Seriler ve Masal ailem"]
    private let locked = ["Görselli masal hakkı", "Yazdırılabilir PDF masal kitabı"]

    var body: some View {
        VStack(spacing: 0) {
            ParentHeader(title: "Abonelik", onBack: onClose)
                .padding(.horizontal, MPSpacing.screenH)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    MPIcon("crown", size: 40, weight: .semibold)
                        .foregroundStyle(MPWorldTone.yellow.deep)
                        .frame(width: 96, height: 96)
                        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.hero, style: .continuous))
                        .rotationEffect(.degrees(-5))
                        .mpShadow(.card)
                        .padding(MPSpacing.xxxl)
                        .background(MPWorldTone.yellow.soft, in: Ellipse())
                        .accessibilityHidden(true)

                    VStack(spacing: MPSpacing.sm) {
                        Text("Premium süren doldu").mpText(.title1).foregroundStyle(MPColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text("Hiçbir masal silinmedi. Ücretsiz planda şunlar devam ediyor:")
                            .mpText(.body).foregroundStyle(MPColor.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    MPCard(area: .parent, padding: MPSpacing.lg) {
                        VStack(alignment: .leading, spacing: MPSpacing.md) {
                            ForEach(kept, id: \.self) { row($0, kept: true) }
                            ForEach(locked, id: \.self) { row($0, kept: false) }
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.vertical, MPSpacing.lg)
            }

            VStack(spacing: MPSpacing.xs) {
                MPButton(title: "Premium'u yenile", systemImage: "crown", fullWidth: true, action: onRenew)
                    .padding(.horizontal, MPSpacing.xxxl)
                MPButton(title: "Ücretsiz devam et", kind: .ghost, action: onClose)
            }
            .padding(.vertical, MPSpacing.md)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
    }

    private func row(_ text: String, kept: Bool) -> some View {
        HStack(spacing: MPSpacing.md) {
            MPIcon(kept ? "checkmark" : "lock", size: 16, weight: .bold)
                .foregroundStyle(kept ? MPColor.statusSuccess : MPColor.textSecondary)
                .frame(width: 32, height: 32)
                .background(kept ? MPColor.statusSuccessSoft : MPColor.backgroundSunken, in: Circle())
                .accessibilityHidden(true)
            Text(text).mpText(.bodyStrong)
                .foregroundStyle(kept ? MPColor.textPrimary : MPColor.textSecondary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(kept ? "\(text), devam ediyor" : "\(text), kilitli")
    }
}
