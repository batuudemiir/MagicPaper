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
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                CreationTitle(title: "Masal kimin için?", subtitle: "Masalın kahramanı o olacak.")
                VStack(spacing: MPSpacing.md) {
                    ForEach(profiles) { profile in
                        CreationChoiceRow(
                            title: profile.name,
                            subtitle: "\(profile.age) yaş",
                            isSelected: selectedID == profile.id,
                            accessibilityLabel: "\(profile.name), \(profile.age) yaşında",
                            action: {
                                MPHaptics.selection()
                                selectedID = profile.id
                            },
                            leading: { MPAvatar(name: profile.name, color: profile.mpColor, size: MPSize.minTouchKid - MPSpacing.xxs) }
                        )
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CreationFooter {
                MPButton(title: "Devam et", fullWidth: true, action: onContinue)
                    .disabled(selectedID == nil)
            }
        }
    }
}
