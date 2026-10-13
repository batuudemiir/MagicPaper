import SwiftUI

// MARK: - Profil sheet'i — 03-SCREENS.md §8

struct ProfilePickerSheet: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    var body: some View {
        MPSheet(title: "Kim okuyacak?", onClose: { app.sheet = nil }) {
            VStack(spacing: 8) {
                ForEach(profileManager.profiles) { profile in
                    LegacyMPListRow(
                        symbol: "person.crop.circle",
                        iconColor: profile.mpColor,
                        title: profile.name,
                        description: "\(profile.mpAgeRange.shortLabel) yaş · \(count(profile)) masal",
                        action: {
                            profileManager.switchProfile(to: profile)
                            app.sheet = nil
                            app.showToast("\(profile.name) seçildi", symbol: "checkmark")
                        }
                    ) {
                        if profileManager.currentProfile?.id == profile.id {
                            MPIcon("checkmark", size: 20, weight: .bold)
                                .foregroundStyle(MP.C.brand)
                        }
                    }
                }
            }
        } footer: {
            LegacyMPButton(title: "Yeni profil ekle", variant: .outline, icon: "plus", fullWidth: true) {
                app.sheet = nil
                app.showProfileAdd = true
            }
        }
    }

    private func count(_ p: UserProfile) -> Int {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: p) }.count
    }
}

// MARK: - Masalın eylemleri

/// Favori, PDF, paylaş, sil — masal detayının eylemleri (03-SCREENS.md §7).
///
/// Eskiden ayrı bir alt sayfadaydı (`StoryActionsSheet`). Raftan ve
/// kütüphaneden artık masalın kendi sayfası açılıyor; eylemler orada.
struct StoryActionList: View {
    let story: Story
    /// Masal silindikten sonra, bulunduğu yüzeyi kapatmak için.
    let onDeleted: () -> Void

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var favorites = MPFavorites.shared
    @ObservedObject private var series = SeriesManager.shared

    @State private var exportFile: MPExportFile?
    @State private var isExporting = false

    private var isFavorite: Bool { favorites.contains(story.id) }

    var body: some View {
        VStack(spacing: 4) {
            seriesRow

            LegacyMPListRow(
                symbol: "heart",
                iconColor: isFavorite ? MP.C.brand : MP.C.textMuted,
                title: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                action: {
                    let now = favorites.toggle(story.id)
                    app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı",
                                  symbol: "heart.fill")
                }
            ) { EmptyView() }

            LegacyMPListRow(symbol: "printer", title: "Yazdır veya PDF indir",
                      action: { export() }) { EmptyView() }

            LegacyMPListRow(symbol: "square.and.arrow.up", title: "Paylaş",
                      action: { export() }) { EmptyView() }

            LegacyMPListRow(symbol: "trash", title: "Masalı sil", isDanger: true, action: {
                storyManager.deleteStory(id: story.id)
                onDeleted()
                app.showToast("Masal silindi", symbol: "trash", tone: .danger)
            }) { EmptyView() }
        }
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
        }
    }

    /// "Devam ettir" (FAZ 13), ya da başka bir seri sürerken sakin satır.
    @ViewBuilder
    private var seriesRow: some View {
        switch series.endingState(for: story) {
        case .offer:
            LegacyMPListRow(symbol: "sparkles", iconColor: MP.C.brand, title: SeriesCopy.continueButton,
                      description: SeriesCopy.continueHint, action: {
                do {
                    try series.startSeries(from: story)
                    MPHaptics.success()
                    app.showToast(SeriesCopy.startedToast, symbol: "sparkles")
                } catch {
                    app.showToast(SeriesCopy.startFailed, symbol: "xmark")
                }
            }) { EmptyView() }
            .accessibilityHint(SeriesCopy.continueAccessibilityHint)
        case .blocked:
            Text(SeriesCopy.blocked(child: story.childName))
                .font(MP.F.bodySM())
                .foregroundStyle(MP.C.textMuted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, MP.S.x2)
        default:
            EmptyView()
        }
    }

    /// Gerçek PDF üretir ve sistem paylaşım sayfasını açar
    /// (oradan "Yazdır" da seçilebilir).
    private func export() {
        guard !isExporting else { return }
        isExporting = true
        app.showToast("PDF hazırlanıyor", symbol: "printer")

        let snapshot = story
        Task.detached(priority: .userInitiated) {
            let url = await MPStoryPDF.makePDF(for: snapshot)
            await MainActor.run {
                isExporting = false
                if let url {
                    exportFile = MPExportFile(url: url)
                } else {
                    app.showToast("PDF oluşturulamadı", symbol: "xmark", tone: .danger)
                }
            }
        }
    }
}

// MARK: - 24 · Okuma ayarları (`OkumaAyarlari`)

/// Okuyucunun kendi sayfası: tema, yazı boyutu, kim okusun, okuma hızı,
/// sesli okuma. Okuyucu tam ekran sunulduğu için onun içinden `.sheet` ile
/// açılır. "Kim okusun?" yalnızca Kendi sesin (FAZ 18) bayrağı açıkken.
struct ReaderSettingsSheet: View {
    /// Bu masalın ailenin sesiyle kaydı var mı (FAZ 18).
    var hasFamilyVoice = false
    let onClose: () -> Void

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xl) {
                Text("Okuma ayarları").mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                group("Tema") {
                    MPSegmented(options: MP.ReadTheme.allCases.map { ($0, $0.label) },
                                selection: $app.readTheme)
                }

                group("Yazı boyutu") {
                    MPFlowLayout(spacing: MPSpacing.sm) {
                        ForEach(MP.ReadSize.allCases) { size in
                            MPChip(title: size.rawValue, isSelected: app.readSize == size) {
                                app.readSize = size
                                settings.readSize = size
                            }
                        }
                    }
                }

                // "Ailenin sesi" yalnızca bu masalın kaydı varsa (24 · teslim notu).
                if hasFamilyVoice {
                    group("Kim okusun?") {
                        MPSegmented(options: [(false, "Masal anlatıcısı"), (true, "Ailenin sesi")],
                                    selection: $settings.familyVoice)
                    }
                }

                group("Okuma hızı") {
                    MPSegmented(options: MPSpeechRate.allCases.map { ($0, $0.label) },
                                selection: Binding(get: { settings.speechRate },
                                                   set: { settings.speechRate = $0 }))
                }

                MPGroupedList(area: .kid) {
                    MPListRow(systemImage: "speaker.wave.2", tone: .sky, title: "Sesli okuma",
                              subtitle: "Sayfa açılınca kendiliğinden okunur") {
                        Toggle(isOn: $settings.readAloud) { EmptyView() }
                            .toggleStyle(MPSwitchStyle()).fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(settings.readAloud ? "Açık" : "Kapalı")
                    .accessibilityAction { settings.readAloud.toggle() }
                    MPRowDivider(area: .kid)
                    MPListRow(systemImage: "sparkles", tone: .lav, title: "Dokunsal geri bildirim",
                              subtitle: "Sayfa çevrilince hafif bir dokunuş") {
                        Toggle(isOn: $settings.haptics) { EmptyView() }
                            .toggleStyle(MPSwitchStyle()).fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(settings.haptics ? "Açık" : "Kapalı")
                    .accessibilityAction { settings.haptics.toggle() }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.xxl)
            .padding(.bottom, MPSpacing.lg)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MPButton(title: "Okumaya dön", fullWidth: true, action: onClose)
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.md)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(MPRadius.sheet)
        .presentationBackground(MPColor.backgroundKid)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
            content()
        }
    }
}

// MARK: - Profil düzenleme sheet'i — 03-SCREENS.md §8

struct ProfileEditSheet: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared

    /// How many stories go with the profile, counted when the parent asks to
    /// delete — `nil` while no confirmation is showing.
    @State private var pendingDeletionStoryCount: Int?

    var body: some View {
        MPSheet(title: profile.name, onClose: { app.sheet = nil }) {
            VStack(spacing: 4) {
                LegacyMPListRow(symbol: "pencil", title: "Profili düzenle", action: {
                    app.sheet = nil
                    app.showProfileAdd = true
                }) { EmptyView() }

                if IllustratedBookAccess.isEnabled() {
                    LegacyMPListRow(symbol: "sparkles", title: "Kitap karakteri",
                              description: "Görselli masallarda görünecek karakter", action: {
                        app.sheet = .bookCharacter(profile.id)
                    }) { EmptyView() }
                }

                LegacyMPListRow(symbol: FamilyCharacterCopy.profileRowSymbol,
                          title: FamilyCharacterCopy.profileRowTitle,
                          description: FamilyCharacterCopy.profileRowDescription, action: {
                    app.sheet = .familyCharacters(profile.id)
                }) { EmptyView() }

                if ChildInterests.isShown(StoryChoiceSources.current.interestChoices()) {
                    LegacyMPListRow(symbol: InterestCopy.rowSymbol, title: InterestCopy.sectionTitle, action: {
                        app.sheet = .interests(profile.id)
                    }) { EmptyView() }
                }

                LegacyMPListRow(symbol: "bookmark", title: "Bu çocuğun masalları", action: {
                    profileManager.switchProfile(to: profile)
                    app.sheet = nil
                    app.tab = .library
                }) { EmptyView() }

                if profileManager.profiles.count > 1 {
                    // Deletion takes the child's stories with it and cannot be
                    // undone, so the row only asks; the dialog deletes.
                    LegacyMPListRow(symbol: "trash", title: "Profili sil", isDanger: true, action: {
                        pendingDeletionStoryCount = profileManager.storiesDeleted(with: profile).count
                    }) { EmptyView() }
                }
            }
        }
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
        // Report what actually happened: the toast used to fire even when
        // the deletion was refused.
        switch profileManager.deleteProfile(profile) {
        case .success:
            app.sheet = nil
            app.showToast("Profil silindi", symbol: "trash", tone: .danger)
        case .failure(.lastProfile):
            app.showToast("Son profil silinemez", symbol: "exclamationmark.triangle", tone: .danger)
        }
    }
}
