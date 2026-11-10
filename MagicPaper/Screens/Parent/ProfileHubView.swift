import SwiftUI

/// Çocuk profil sayfası (Faz 7, 11 Kasım 2026). Ayarlar > Çocuk profilleri'nden
/// itilir; önceden sheet'ti ve sheet → push → sheet zinciri kuruyordu. Bir çocukla
/// ilgili her şey burada: ad ve yaş, Kahraman, Masal ailem, ilgi alanları,
/// masalları, kitap yapma, silme.
struct ProfileHubView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared

    /// Silme onayı açıkken profille birlikte gidecek masal sayısı.
    @State private var pendingDeletionStoryCount: Int?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: profile.name, subtitle: "\(profile.mpAgeRange.shortLabel) yaş",
                               onBack: { app.router.parentRoute = nil })

                ParentSection(title: "Profil") {
                    ParentRowButton(systemImage: "pencil", title: "Ad, renk ve yaş") {
                        app.router.openProfileEdit(profile.id)
                    }
                    if IllustratedBookAccess.isEnabled() {
                        MPRowDivider(area: .parent)
                        ParentRowButton(systemImage: "sparkles", tone: .sky, title: "Kahraman",
                                        subtitle: "Görselli masallarda görünecek kahraman") {
                            app.router.parentRoute = .bookCharacter(profile.id)
                        }
                    }
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: FamilyCharacterCopy.profileRowSymbol, tone: .pink,
                                    title: FamilyCharacterCopy.profileRowTitle,
                                    subtitle: FamilyCharacterCopy.profileRowDescription) {
                        app.router.parentRoute = .familyCharacters(profile.id)
                    }
                    if ChildInterests.isShown(StoryChoiceSources.current.interestChoices()) {
                        MPRowDivider(area: .parent)
                        ParentRowButton(systemImage: InterestCopy.rowSymbol, tone: .green,
                                        title: InterestCopy.sectionTitle) {
                            app.router.sheet = .interests(profile.id)
                        }
                    }
                }

                ParentSection(title: "Masallar") {
                    ParentRowButton(systemImage: "bookmark", tone: .sky, title: "Bu çocuğun masalları") {
                        profileManager.switchProfile(to: profile)
                        app.router.enterChildMode()
                        app.router.tab = .library
                    }
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: "book.closed", tone: .lav, title: "Kitap yap",
                                    subtitle: "Masallardan basılabilir bir PDF") {
                        profileManager.switchProfile(to: profile)
                        app.router.parentRoute = .bookExport
                    }
                }

                if profileManager.profiles.count > 1 {
                    MPGroupedList(area: .parent) {
                        // Silme masalları da götürür ve geri alınamaz: satır sorar, onay siler.
                        ParentRowButton(systemImage: "trash", title: "Profili sil", isDestructive: true) {
                            pendingDeletionStoryCount = profileManager.storiesDeleted(with: profile).count
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .confirmationDialog(
            "Profili sil",
            isPresented: Binding(
                get: { pendingDeletionStoryCount != nil },
                set: { if !$0 { pendingDeletionStoryCount = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(deleteButtonTitle, role: .destructive, action: deleteProfile)
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(deletionMessage)
        }
    }

    private var deleteButtonTitle: String {
        (pendingDeletionStoryCount ?? 0) > 0 ? "Profili ve masalları sil" : "Profili sil"
    }

    private var deletionMessage: String {
        let count = pendingDeletionStoryCount ?? 0
        if count > 0 {
            return "\(profile.name) profili ve bu profile ait \(count) masal kalıcı olarak silinecek. Bu işlem geri alınamaz."
        }
        return "\(profile.name) profili kalıcı olarak silinecek. Bu işlem geri alınamaz."
    }

    private func deleteProfile() {
        pendingDeletionStoryCount = nil
        switch profileManager.deleteProfile(profile) {
        case .success:
            app.router.parentRoute = nil
            app.showToast("Profil silindi", symbol: "trash", tone: .danger)
        case .failure(.lastProfile):
            app.showToast("Son profil silinemez", symbol: "exclamationmark.triangle", tone: .danger)
        }
    }
}
