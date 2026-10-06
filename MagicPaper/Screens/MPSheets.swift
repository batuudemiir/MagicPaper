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
                    MPListRow(
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
            MPButton(title: "Yeni profil ekle", variant: .outline, icon: "plus", fullWidth: true) {
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

            MPListRow(
                symbol: "heart",
                iconColor: isFavorite ? MP.C.brand : MP.C.textMuted,
                title: isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                action: {
                    let now = favorites.toggle(story.id)
                    app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı",
                                  symbol: "heart.fill")
                }
            ) { EmptyView() }

            MPListRow(symbol: "printer", title: "Yazdır veya PDF indir",
                      action: { export() }) { EmptyView() }

            MPListRow(symbol: "square.and.arrow.up", title: "Paylaş",
                      action: { export() }) { EmptyView() }

            MPListRow(symbol: "trash", title: "Masalı sil", isDanger: true, action: {
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
            MPListRow(symbol: "sparkles", iconColor: MP.C.brand, title: SeriesCopy.continueButton,
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

// MARK: - Okuma ayarları sheet'i — 03-SCREENS.md §6

struct ReaderSettingsSheet: View {
    /// Okuyucu tam ekran cover olarak sunulduğu için bu sheet, ContentView'ın
    /// paylaşılan katmanında değil, okuyucunun **kendi içinde** açılır — aksi
    /// hâlde cover'ın arkasında kalıyordu.
    let onClose: () -> Void

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore

    var body: some View {
        MPSheet(title: "Okuma ayarları", onClose: onClose) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tema").font(MP.F.labelMD()).foregroundStyle(MP.C.textTitle)
                    MPSegmentedControl(
                        options: MP.ReadTheme.allCases.map { ($0, $0.label) },
                        selection: $app.readTheme
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Yazı boyutu").font(MP.F.labelMD()).foregroundStyle(MP.C.textTitle)
                    MPWrapRow(spacing: 10) {
                        ForEach(MP.ReadSize.allCases) { size in
                            MPChip(title: size.rawValue, isSelected: app.readSize == size) {
                                app.readSize = size
                                settings.readSize = size
                            }
                        }
                    }
                }

                MPListRow(
                    symbol: "speaker.wave.2",
                    title: "Sesli okuma",
                    description: "Masalı sesli oku"
                ) {
                    MPSwitch(isOn: $settings.readAloud, label: "Sesli okuma")
                }

                MPListRow(
                    symbol: "sparkles",
                    title: "Dokunsal geri bildirim",
                    description: "Sayfa çevrilince hafif bir dokunuş"
                ) {
                    MPSwitch(isOn: $settings.haptics, label: "Dokunsal geri bildirim")
                }
            }
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
                MPListRow(symbol: "pencil", title: "Profili düzenle", action: {
                    app.sheet = nil
                    app.showProfileAdd = true
                }) { EmptyView() }

                if IllustratedBookAccess.isEnabled() {
                    MPListRow(symbol: "sparkles", title: "Kitap karakteri",
                              description: "Görselli masallarda görünecek karakter", action: {
                        app.sheet = .bookCharacter(profile.id)
                    }) { EmptyView() }
                }

                MPListRow(symbol: FamilyCharacterCopy.profileRowSymbol,
                          title: FamilyCharacterCopy.profileRowTitle,
                          description: FamilyCharacterCopy.profileRowDescription, action: {
                    app.sheet = .familyCharacters(profile.id)
                }) { EmptyView() }

                MPListRow(symbol: "bookmark", title: "Bu çocuğun masalları", action: {
                    profileManager.switchProfile(to: profile)
                    app.sheet = nil
                    app.tab = .library
                }) { EmptyView() }

                if profileManager.profiles.count > 1 {
                    // Deletion takes the child's stories with it and cannot be
                    // undone, so the row only asks; the dialog deletes.
                    MPListRow(symbol: "trash", title: "Profili sil", isDanger: true, action: {
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
