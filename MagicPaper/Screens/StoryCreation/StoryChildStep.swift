import SwiftUI

/// Yarat 0: bu masal hangi çocuk için? (karar: 16 Ekim 2026)
///
/// Akış bugüne kadar aktif profili kullanıyordu — doğru bir varsayım ama tek
/// çocuklu bir ev için doğru. İki çocuklu evde ebeveyn, masalı yazdırmadan
/// önce Köşem'e gidip çocuğu değiştirmek zorundaydı; ve değiştirmeyi unutursa
/// masal yanlış çocuğun adıyla, yanlış yaş bandında yazılıyordu. İkincisi
/// sessiz bir hata: masal gayet iyi görünür, yalnızca yanlış çocuğundur.
///
/// Adım yalnızca seçilecek bir şey varken görünür
/// (`StoryCreationSteps.showsChildStep`).
///
/// Seçim **akışa özeldir**: aktif profili değiştirmez. Büyük kardeşine masal
/// yazdırmak, uygulamanın geri kalanını büyük kardeşe çevirmemeli.
struct StoryChildStep: View {

    let profiles: [UserProfile]
    /// Masal yazılmış yaş bantları (C turu). Bantı yazılmamış bir çocuk
    /// listeden **çıkarılmaz**: profil onun, ve kaybolması bir hata gibi
    /// görünür. Kartında durumu yazar, seçilince açıklama ekranı açılır.
    var authoredBands: [AgeBand] = []
    @Binding var selectedID: UUID?
    let onContinue: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.lg) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Masal kimin için?")
                        .mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Masalın kahramanı o olacak.")
                        .mpText(.body).foregroundStyle(MPColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: MPSpacing.md),
                                    GridItem(.flexible(), spacing: MPSpacing.md)],
                          spacing: MPSpacing.lg) {
                    ForEach(profiles) { profile in
                        ChildTile(profile: profile,
                                  isSelected: selectedID == profile.id,
                                  isSupported: StoryCreationSteps.supportsAge(
                                      profile.age, authored: authoredBands)) {
                            MPHaptics.selection()
                            selectedID = profile.id
                        }
                    }
                }
                .padding(.top, MPSpacing.sm)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Devam et", fullWidth: true, action: onContinue)
                .disabled(selectedID == nil)
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
        }
    }
}

/// Çocuk kartı: mod kartlarıyla aynı ölçü ve aynı seçim dili, ortasında
/// avatar. `WorldTile` kullanılmadı çünkü o bir simge çiziyor; buradaki görsel
/// çocuğun kendi rengi ve baş harfi, yani kartın konusu simge değil kişi.
private struct ChildTile: View {
    let profile: UserProfile
    let isSelected: Bool
    /// Bu yaş için masal yazılmış mı. Kart devre dışı bırakılmıyor: durumu
    /// söylemek, kartı kapatıp sebebini saklamaktan iyidir.
    var isSupported: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                MPAvatar(name: profile.name, color: profile.mpColor, size: 56, ring: isSelected)
                VStack(spacing: MPSpacing.xxs) {
                    Text(profile.name)
                        .mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(isSupported ? "\(profile.age) yaş" : "\(profile.age) yaş · hazırlanıyor")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 108)
            .padding(.vertical, MPSpacing.md)
            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? MPColor.actionPrimary : MPColor.borderKid,
                                  lineWidth: isSelected ? 3 : 1)
            }
            .mpShadow(.control)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSupported
                            ? "\(profile.name), \(profile.age) yaşında"
                            : "\(profile.name), \(profile.age) yaşında, bu yaş için masallar hazırlanıyor")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
