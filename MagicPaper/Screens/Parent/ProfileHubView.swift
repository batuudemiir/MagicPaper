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
                    // Arayüz kademesi (`KidLevel`): yaştan türer, ebeveyn değiştirir.
                    ParentToggleRow(systemImage: "book", tone: .sky, title: "Kendi okuyor",
                                    subtitle: "Açıkken ekranlar yazıyla, kapalıyken resimle seçilir.",
                                    isOn: Binding(
                                        get: { liveProfile.effectiveReadsAlone },
                                        set: { profileManager.setReadsAlone($0, for: profile.id) }))
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: FamilyCharacterCopy.profileRowSymbol, tone: .pink,
                                    title: FamilyCharacterCopy.profileRowTitle,
                                    subtitle: FamilyCharacterCopy.profileRowDescription) {
                        app.router.parentRoute = .familyCharacters(profile.id)
                    }
                    MPRowDivider(area: .parent)
                    ParentRowButton(systemImage: "calendar", tone: .peach, title: SpecialDayCopy.rowTitle,
                                    subtitle: SpecialDayCopy.rowSubtitle) {
                        app.router.parentRoute = .specialDays(profile.id)
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
                        app.unlock(.pdfBook) {
                            profileManager.switchProfile(to: profile)
                            app.router.parentRoute = .bookExport
                        }
                    }
                }

                collectionSection
                badgesSection

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

    /// Sayfa profilin bir kopyasıyla açılır; anahtar güncel değeri göstersin.
    private var liveProfile: UserProfile {
        profileManager.profiles.first { $0.id == profile.id } ?? profile
    }

    /// Yıldız ve çıkartmalar (Faz 9): ebeveyn ekonominin ne yaptığını görür.
    /// Salt okunur; değiştirme yok.
    private var collectionSection: some View {
        let stories = StoryGenerationManager.shared.stories
        let earned = MPStars.score(for: profile, stories: stories)
        let wallet = MPStarWalletStore().wallet(for: profile.id)
        let stickers = MPStickerAlbum.stickers(for: profile, stories: stories).count
        let level = MPStarLevel.current(score: earned)
        return ParentSection(title: "Yıldız ve çıkartmalar",
                             subtitle: "Yıldızlar yalnızca okuyarak kazanılır, parayla alınamaz, kaybolmaz. Harcamak puanı düşürmez.") {
            MPListRow(systemImage: "star", tone: .yellow, title: "Yıldız puanı: \(earned)",
                      subtitle: "\(wallet.spent) harcandı, \(wallet.balance(earned: earned)) kumbarada") { EmptyView() }
            MPRowDivider(area: .parent)
            MPListRow(systemImage: "star.circle", tone: .yellow,
                      title: level.map { "Yıldız katı: \($0.title)" } ?? "Yıldız katı yok",
                      subtitle: level.map { "\(MPStarLevel.all.count) kattan \($0.tier). kat" }
                        ?? "İlk kat \(MPStarLevel.all[0].threshold) yıldızda açılır") { EmptyView() }
            MPRowDivider(area: .parent)
            MPListRow(systemImage: "book.closed", tone: .lav, title: "\(stickers) çıkartma",
                      subtitle: "Her biten masal albüme bir çıkartma bırakır") { EmptyView() }
            ForEach(Array(wallet.purchases.reversed().prefix(5).enumerated()), id: \.offset) { _, purchase in
                MPRowDivider(area: .parent)
                MPListRow(systemImage: "sparkles", tone: .gray,
                          title: (MPDecor.item(purchase.itemID)?.title ?? "Süs") + " raf",
                          subtitle: "\(purchase.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR")))) · \(purchase.price) yıldız") { EmptyView() }
            }
        }
    }

    /// Rozetler (rozet planı R5): kazanılanlar tarih sırasıyla, en yenisi önce.
    /// Salt okunur; ebeveyn alanında Ragi ve boş durum görseli yok (`MPListRow`).
    private var badgesSection: some View {
        let ledger = MPBadgeStore().ledger(for: profile, stories: StoryGenerationManager.shared.stories)
        let earned = ledger.earned
            .compactMap { id, date in MPBadgeCatalog.badge(id).map { ($0, date) } }
            .sorted { ($0.1, $1.0.id) > ($1.1, $0.0.id) }
        let shown = earned.prefix(10)
        return ParentSection(title: "Rozetler",
                             subtitle: "\(MPBadgeCatalog.all.count) rozetten \(earned.count) tanesi kazanıldı. Rozetler yalnızca okuyarak gelir ve kaybolmaz.") {
            if shown.isEmpty {
                MPListRow(systemImage: "rosette", tone: .gray, title: "Henüz rozet yok",
                          subtitle: "İlk masal bitince ilk rozet gelir") { EmptyView() }
            }
            ForEach(Array(shown.enumerated()), id: \.offset) { index, item in
                if index > 0 { MPRowDivider(area: .parent) }
                MPListRow(systemImage: item.0.icon, tone: item.0.tone, title: item.0.title,
                          subtitle: ProfileHubView.badgeSubtitle(item.0, date: item.1)) { EmptyView() }
            }
            if earned.count > shown.count {
                MPRowDivider(area: .parent)
                MPListRow(systemImage: "ellipsis", tone: .gray,
                          title: "\(earned.count - shown.count) rozet daha",
                          subtitle: "Hepsi çocuğun Profil sayfasında, Rozetlerim'de") { EmptyView() }
            }
        }
    }

    static func badgeSubtitle(_ badge: MPBadge, date: Date) -> String {
        let day = date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
        return "\(badge.family.title) · \(day)"
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
