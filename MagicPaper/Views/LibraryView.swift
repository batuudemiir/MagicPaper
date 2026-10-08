import SwiftUI

/// 16 · Kitaplık (`Kutuphane`) ve 42 · Boş kitaplık (`BosKitaplik`).
///
/// Arama, filtre çipleri (Tümü · Favoriler · Yarım kalanlar), seri bandı,
/// iki sütun kapak ızgarası. Kapağa dokununca Masal aksiyonları (17).
/// Kitaplık etkin çocuğun; çocuk Benim köşem'den değişir.
struct LibraryView: View {
    /// En büyük yazı boyutlarında kapaklar tek sütun.
    @Environment(\.dynamicTypeSize) private var typeSize
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var series = SeriesManager.shared
    @StateObject private var favorites = MPFavorites.shared

    enum Filter: String, CaseIterable {
        case all = "Tümü", favorite = "Favoriler", unfinished = "Yarım kalanlar"
    }

    @State private var query = ""
    @State private var filter: Filter = .all

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if myStories.isEmpty {
                MPStateView(mascot: .reading, tone: .lav, title: "Kitaplığın henüz boş",
                            message: "İlk masalını yarat, burada seni beklesin.") {
                    MPButton(title: "İlk masalını yarat", systemImage: "wand.and.sparkles") {
                        app.startStoryCreation()
                    }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.lg) {
                        searchField
                        chips
                        if filter == .all, query.isEmpty { seriesBand }
                        if visibleStories.isEmpty { noMatch } else { grid }
                    }
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
    }

    // MARK: - Üst bölüm

    private var topBar: some View {
        MPTopBar(title: "Kitaplık") {
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü") { app.requestParentMode() }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.sm)
        .padding(.bottom, MPSpacing.md)
    }

    private var searchField: some View {
        HStack(spacing: MPSpacing.md) {
            MPIcon("magnifyingglass", size: 20, weight: .semibold).foregroundStyle(MPColor.textSecondary)
                .accessibilityHidden(true)
            TextField("Masal ara", text: $query)
                .font(.mp(.bodyStrong))
                .foregroundStyle(MPColor.textPrimary)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    MPIcon("xmark", size: 14, weight: .bold).foregroundStyle(MPColor.textSecondary)
                }
                .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.horizontal, MPSpacing.lg)
        .frame(minHeight: MPSize.inputHeight)
        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.input))
        .overlay(RoundedRectangle(cornerRadius: MPRadius.input).strokeBorder(MPColor.borderKid, lineWidth: 1.5))
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MPSpacing.sm) {
                ForEach(Filter.allCases, id: \.self) { f in
                    MPChip(title: f.rawValue, isSelected: filter == f) {
                        MPHaptics.selection()
                        withAnimation(MP.M.gated(MP.M.easeOut)) { filter = f }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.horizontal, -MPSpacing.screenH)
    }

    @ViewBuilder
    private var seriesBand: some View {
        if let child = profileManager.currentProfile?.id,
           let open = series.openSeries(for: child),
           let progress = series.readProgress(for: child) {
            Button { withAnimation(MP.M.gated(MP.M.base)) { app.seriesChildID = child } } label: {
                HStack(spacing: MPSpacing.md) {
                    MPIcon("pawprint", size: 24, weight: .semibold)
                        .foregroundStyle(MPWorldTone.peach.deep)
                        .frame(width: 48, height: 48)
                        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.md))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seri · \(progress.read) / \(progress.total) bölüm")
                            .mpText(.eyebrow).foregroundStyle(MPWorldTone.peach.deep)
                        Text(open.firstStoryTitle).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    }
                    Spacer(minLength: 0)
                    MPChevron().accessibilityHidden(true)
                }
                .padding(MPSpacing.md)
                .background(MPWorldTone.peach.soft, in: RoundedRectangle(cornerRadius: MPRadius.card))
            }
            .buttonStyle(MPPressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Seri masalı açar")
        }
    }

    // MARK: - Izgara

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.lg),
                                 count: typeSize.isAccessibilitySize ? 1 : 2),
                  spacing: MPSpacing.lg) {
            ForEach(visibleStories) { story in
                Button { app.actionsStory = story } label: {
                    MPStoryCover(title: story.title, systemImage: story.mpWorld.icon, tone: story.mpWorld.tone,
                                 badge: badge(for: story),
                                 actionTitle: isPartlyRead(story) ? "Devam" : "Oku",
                                 illustration: story.mpKitCoverAsset.map { Image($0) })
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel(story.title)
                .accessibilityValue(badge(for: story) ?? "")
                .accessibilityHint("Masalın seçeneklerini açar")
            }
        }
    }

    private func isPartlyRead(_ story: Story) -> Bool { story.mpProgress > 0 && story.mpProgress < 1 }

    private func badge(for story: Story) -> String? {
        if story.isIllustrated { return "Görselli" }
        if let episode = SeriesCopy.episodeBadge(story) { return episode }
        if isPartlyRead(story) { return "Yarım" }
        return nil
    }

    @ViewBuilder
    private var noMatch: some View {
        VStack(spacing: MPSpacing.md) {
            Text(query.isEmpty ? (filter == .favorite ? "Favori masal yok" : "Yarım kalan masal yok")
                               : "Eşleşen masal yok")
                .mpText(.title3).foregroundStyle(MPColor.textPrimary)
            Text(query.isEmpty ? (filter == .favorite ? "Bir masalı kalple işaretleyince burada toplanır."
                                                      : "Yarıda bıraktığın masallar burada durur.")
                               : "\u{201C}\(query)\u{201D} için bir şey bulamadık.")
                .mpText(.body).foregroundStyle(MPColor.textSecondary).multilineTextAlignment(.center)
            MPButton(title: query.isEmpty ? "Tümünü göster" : "Aramayı temizle", kind: .soft, size: .small) {
                query = ""
                filter = .all
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, MPSpacing.xxxl)
    }

    // MARK: - Liste

    /// Onay kapısı en başta: kapı "hangi masallar var" sorusunun cevabını
    /// değiştirir; arama ve filtre o cevabın üzerinde çalışır.
    private var myStories: [Story] {
        MPStoryGate.visible(storyManager.stories, approvalRequired: settings.approve,
                            isApproved: { settings.isApproved($0) })
            .filter { $0.belongs(to: profileManager.currentProfile) }
    }

    private var visibleStories: [Story] {
        var list = myStories
        switch filter {
        case .all: break
        case .favorite: list = list.filter { favorites.contains($0.id) }
        case .unfinished: list = list.filter(isPartlyRead)
        }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            // Türkçe katlama: i/ı ayrımı için zorunlu.
            let needle = MPText.foldedForSearch(trimmed)
            list = list.filter { MPText.foldedForSearch($0.title).contains(needle) }
        }
        return list
    }
}

#Preview("16 · Kitaplık") {
    LibraryView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
