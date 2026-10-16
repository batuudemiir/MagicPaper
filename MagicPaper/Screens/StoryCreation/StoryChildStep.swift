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
                        ChildTile(profile: profile, isSelected: selectedID == profile.id) {
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                MPAvatar(name: profile.name, color: profile.mpColor, size: 56, ring: isSelected)
                VStack(spacing: MPSpacing.xxs) {
                    Text(profile.name)
                        .mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text("\(profile.age) yaş")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 108)
            .padding(.vertical, MPSpacing.md)
            .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? MPColor.actionPrimary : MPColor.borderKid,
                                  lineWidth: isSelected ? 3 : 1)
            }
            .mpShadow(.control)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.name), \(profile.age) yaşında")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
