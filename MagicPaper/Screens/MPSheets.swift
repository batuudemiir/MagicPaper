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
    /// Ses, hız ve titreşim "Daha fazla"nın altında.
    @State private var showsMore = false

    private let sizes = MP.ReadSize.allCases

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xl) {
                Text("Okuma ayarları").mpText(.title3).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                group("Kâğıt") {
                    paperSwatches
                    if settings.autoNight && MPBedtime.isBedtime(settings: settings) {
                        Text("Şu an uyku saati: kâğıt Gece.")
                            .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    }
                    MPGroupedList(area: .kid) {
                        toggleRow(icon: "circle.grid.3x3", tone: .peach, title: "Kâğıt dokusu",
                                  subtitle: nil, isOn: $settings.paperGrain)
                        MPRowDivider(area: .kid)
                        toggleRow(icon: "moon", tone: .lav, title: "Uyku saatinde Gece",
                                  subtitle: "Uyku saatinden sonra kâğıt kendiliğinden kararır",
                                  isOn: $settings.autoNight)
                    }
                }

                group("Yazı") {
                    sizeSlider
                    Text("Satır aralığı").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    MPSegmented(options: MP.ReadSpacing.allCases.map { ($0, $0.label) },
                                selection: Binding(get: { settings.readSpacing },
                                                   set: { settings.readSpacing = $0 }))
                    MPGroupedList(area: .kid) {
                        toggleRow(icon: "textformat.alt", tone: .sky, title: "Kolay okuma",
                                  subtitle: "Harflerin arası açılır",
                                  isOn: $settings.easyReading)
                    }
                }

                moreSection
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
        // Yarım sayfa açılır: masal arkada görünür kalır, kâğıt ve yazı
        // değişince arkada hemen döner. Kalan ayarlar için yukarı çekilir.
        // Arka plan kâğıt, cam değil (CLAUDE.md, Derinlik: sheet cam olmaz).
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(MPRadius.sheet)
        .presentationBackground(MPColor.backgroundKid)
    }

    // MARK: - Kâğıt

    /// Beş kâğıt, her biri "Aa" yazan küçük bir sayfa. Seçili olan çerçeveli
    /// ve adı kalın: seçim yalnızca renkle verilmez.
    private var paperSwatches: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: MP.S.x10 - MP.S.x2), spacing: MPSpacing.sm)],
                  spacing: MPSpacing.sm) {
            ForEach(MP.ReadTheme.allCases) { theme in
                let on = app.readTheme == theme
                Button { app.readTheme = theme } label: {
                    VStack(spacing: MPSpacing.xxs) {
                        Text("Aa")
                            .font(MP.F.displaySM())
                            .foregroundStyle(theme.foreground)
                            .frame(maxWidth: .infinity)
                            .frame(height: MP.S.x9)
                            .background(theme.paper, in: RoundedRectangle(cornerRadius: MPRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: MPRadius.sm)
                                .strokeBorder(on ? MPColor.actionPrimary : MPColor.borderKid,
                                              lineWidth: on ? 2 : 1))
                        Text(theme.label)
                            .font(MP.F.caption(on ? .heavy : .semibold))
                            .foregroundStyle(on ? MPColor.textPrimary : MPColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("\(theme.label) kâğıt")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    // MARK: - Yazı

    /// Dört duraklı sürgü: iki ucunda küçük ve büyük "A".
    private var sizeSlider: some View {
        HStack(spacing: MPSpacing.md) {
            Text("A").font(MP.F.labelSM(.heavy)).foregroundStyle(MPColor.textPrimary)
                .accessibilityHidden(true)
            Slider(value: Binding(
                get: { Double(sizes.firstIndex(of: app.readSize) ?? 1) },
                set: { value in
                    let size = sizes[min(sizes.count - 1, max(0, Int(value.rounded())))]
                    guard size != app.readSize else { return }
                    app.readSize = size
                    settings.readSize = size
                }),
                   in: 0...Double(sizes.count - 1), step: 1)
                .tint(MPColor.actionPrimary)
                .accessibilityLabel("Yazı boyutu")
                .accessibilityValue(app.readSize.rawValue)
            Text("A").font(MP.F.displaySM()).foregroundStyle(MPColor.textPrimary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: MP.S.tapMin)
    }

    // MARK: - Daha fazla

    @ViewBuilder
    private var moreSection: some View {
        Button { showsMore.toggle() } label: {
            HStack {
                Text("Daha fazla").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                Spacer()
                MPIcon("chevron.down", size: MP.G.sm, weight: .bold)
                    .foregroundStyle(MPColor.textSecondary)
                    .rotationEffect(.degrees(showsMore ? 180 : 0))
            }
            .frame(minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel("Daha fazla ayar")
        .accessibilityValue(showsMore ? "Açık" : "Kapalı")
        .animation(MP.M.gated(MP.M.easeOut), value: showsMore)

        if showsMore {
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
                toggleRow(icon: "speaker.wave.2", tone: .sky, title: "Sesli okuma",
                          subtitle: "Sayfa açılınca kendiliğinden okunur", isOn: $settings.readAloud)
                MPRowDivider(area: .kid)
                toggleRow(icon: "sparkles", tone: .lav, title: "Dokunsal geri bildirim",
                          subtitle: "Sayfa çevrilince hafif bir dokunuş", isOn: $settings.haptics)
            }
        }
    }

    private func toggleRow(icon: String, tone: MPWorldTone, title: String, subtitle: String?,
                           isOn: Binding<Bool>) -> some View {
        MPListRow(systemImage: icon, tone: tone, title: title, subtitle: subtitle) {
            Toggle(isOn: isOn) { EmptyView() }
                .toggleStyle(MPSwitchStyle()).fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isOn.wrappedValue ? "Açık" : "Kapalı")
        .accessibilityAction { isOn.wrappedValue.toggle() }
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
