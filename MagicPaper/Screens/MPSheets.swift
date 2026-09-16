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
        storyManager.stories.filter { $0.belongs(to: p) }.count
    }
}

// MARK: - Masal aksiyon sheet'i — 03-SCREENS.md §7

struct StoryActionsSheet: View {
    let story: Story

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var favorites = MPFavorites.shared

    @State private var exportFile: MPExportFile?
    @State private var isExporting = false

    private var isFavorite: Bool { favorites.contains(story.id) }

    var body: some View {
        MPSheet(onClose: { app.sheet = nil }) {
            VStack(alignment: .leading, spacing: 0) {
                header.padding(.bottom, 18)

                VStack(spacing: 4) {
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
                        app.sheet = nil
                        app.showToast("Masal silindi", symbol: "trash", tone: .danger)
                    }) { EmptyView() }
                }
            }
        } footer: {
            MPButton(
                title: (story.mpProgress > 0 && story.mpProgress < 1) ? "Okumaya devam et" : "Oku",
                size: .lg,
                icon: "book",
                fullWidth: true
            ) {
                app.sheet = nil
                app.readerStory = story
            }
        }
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
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
            let url = MPStoryPDF.makePDF(for: snapshot)
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

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            MPIcon(story.mpSymbol, size: 38, weight: .semibold)
                .foregroundStyle(story.mpAccent)
                .frame(width: 84, height: 84)
                .background(
                    RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                        .fill(story.mpAccent.opacity(0.16))
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .lineLimit(3)

                HStack(spacing: 6) {
                    MPBadge(title: "\(story.pages.count) sayfa", tone: .neutral)
                    if story.isIllustrated {
                        MPBadge(title: "Görselli", tone: .reward, symbol: "crown.fill")
                    }
                }
                if !story.childName.isEmpty {
                    MPBadge(title: story.childName, tone: .brand, symbol: "person.crop.circle")
                }
            }
            Spacer(minLength: 0)
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

    var body: some View {
        MPSheet(title: profile.name, onClose: { app.sheet = nil }) {
            VStack(spacing: 4) {
                MPListRow(symbol: "pencil", title: "Profili düzenle", action: {
                    app.sheet = nil
                    app.showProfileAdd = true
                }) { EmptyView() }

                MPListRow(symbol: "bookmark", title: "Bu çocuğun masalları", action: {
                    profileManager.switchProfile(to: profile)
                    app.sheet = nil
                    app.tab = .library
                }) { EmptyView() }

                if profileManager.profiles.count > 1 {
                    MPListRow(symbol: "trash", title: "Profili sil", isDanger: true, action: {
                        // Report what actually happened: the toast used to
                        // fire even when the deletion was refused.
                        switch profileManager.deleteProfile(profile) {
                        case .success:
                            app.sheet = nil
                            app.showToast("Profil silindi", symbol: "trash", tone: .danger)
                        case .failure(.lastProfile):
                            app.showToast("Son profil silinemez", symbol: "exclamationmark.triangle", tone: .danger)
                        }
                    }) { EmptyView() }
                }
            }
        }
    }
}
