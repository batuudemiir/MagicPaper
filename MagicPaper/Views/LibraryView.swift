import SwiftUI

/// Kitaplık sekmesi (yenileme: 20 Ekim 2026; zaman çizgisi: 21 Ekim 2026).
///
/// Çocuğun kendi masalları ve Günlük'ten açtığı klasikler, tek yerde. Dil
/// Ana sayfa ve Benim köşem'le aynı: beyaz sayfa, sert alt kenarlı yüzeyler,
/// ekranın tek Ragi'si. Kapaklar `MPBookCover`, hepsi aynı ölçüde.
///
/// Düzen: başlık · Ragi ve arama · süzgeç çipleri · "Kaldığın yerden" ·
/// Serim · "Kitaplarım": tek, başlıksız raf dizisi (iki sütun, sıraların
/// altında ince raf). Apple Books, Kindle ve Audible'daki gibi varsayılan
/// sıra son okunan; küçük menüden yeni yazılan ya da ada göre. Ne zaman
/// okunduğu kapağın altında ("Dün · 4 dk"). Tarih başlıkları denendi,
/// Batuhan estetik bulmadı (21 Ekim). Çip ve arama aynı diziyi daraltır.
///
/// Kendi masalına dokununca Masal aksiyonları (17), klasiğe dokununca okuyucu.
/// İçerik `LibraryShelfModel`'den gelir ve yalnızca veri değişince kurulur.
struct LibraryView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var series = SeriesManager.shared
    @ObservedObject private var classicProgress = ClassicProgressStore.shared
    @ObservedObject private var favorites = MPFavorites.shared

    @State private var model = LibraryShelfModel.empty
    @State private var pendingCount = 0
    @State private var query = ""
    @State private var filter: LibraryFilter = .all
    @State private var sort: LibrarySort = .recent
    @State private var width: CGFloat = 390
    @FocusState private var searchFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                titleBar.homeEntrance(0)
                if model.isEmpty {
                    emptyLibrary.homeEntrance(1)
                } else {
                    VStack(alignment: .leading, spacing: MPSpacing.lg) {
                        greeting
                        LibrarySearchField(text: $query, focused: $searchFocused)
                        if pendingCount > 0 { pendingNote }
                    }
                    .homeEntrance(1)
                    chips.homeEntrance(2)
                    if isBrowsing { highlights }
                    shelf
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            // Son raf yüzen alt çubuğun arkasında kalmasın.
            .padding(.bottom, GunlukLayout.bottomClearance)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        // İçerik kaydırırken değil, veri değişince kurulur.
        .onAppear(perform: refresh)
        .onChange(of: storyManager.stories) { _, _ in refresh() }
        .onChange(of: favorites.ids) { _, _ in refresh() }
        .onChange(of: classicProgress.entries) { _, _ in refresh() }
        .onChange(of: profileManager.currentProfile?.id) { _, _ in refresh() }
        .onChange(of: settings.approve) { _, _ in refresh() }
        .onChange(of: settings.approvedStoryIDs) { _, _ in refresh() }
    }

    /// Raflar mı, ızgara mı: süzgeç ya da arama yoksa raflar.
    private var isBrowsing: Bool {
        filter == .all && query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Üst bölüm

    private var titleBar: some View {
        HStack(alignment: .center, spacing: MPSpacing.sm) {
            Text("Kitaplık").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü") {
                app.requestParentMode()
            }
        }
        .padding(.top, MPSpacing.lg)
    }

    /// Ekranın tek Ragi'si: kitap okur, yanında kitaplığın sakin özeti.
    private var greeting: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.md))
        return layout {
            RagiGreeting(mascot: .reading, width: typeSize.isAccessibilitySize ? 64 : 76)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text("Bugün hangi masalı okuyalım?").mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                Text(summary).mpText(.callout).foregroundStyle(MPColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MPWorldTone.lav.soft.opacity(0.45),
                        in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge.opacity(0.5))
        }
        .accessibilityElement(children: .combine)
    }

    /// "5 masalın, 2 klasik": sayar, baskı yapmaz (CLAUDE.md §7).
    private var summary: String {
        var parts: [String] = []
        if model.storyCount > 0 { parts.append("\(model.storyCount) masalın") }
        if model.classicCount > 0 { parts.append("\(model.classicCount) klasik") }
        return parts.joined(separator: ", ") + " burada."
    }

    private var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MPSpacing.sm) {
                    ForEach(model.availableFilters) { option in
                        GunlukChip(title: option.chipTitle, isSelected: filter == option) {
                            select(option)
                        }
                        .accessibilityLabel(option.title)
                        .id(option)
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.horizontal, -MPSpacing.screenH)
            // Rafın "Tümü" bağlantısıyla seçilen çip kenarda yarım kalmasın.
            .onChange(of: filter) { _, selected in
                withAnimation(MP.M.gated(MP.M.easeOut)) { proxy.scrollTo(selected, anchor: .center) }
            }
        }
    }

    private func select(_ option: LibraryFilter) {
        guard option != filter else { return }
        MPHaptics.selection()
        withAnimation(MP.M.gated(MP.M.easeOut)) { filter = option }
    }

    // MARK: - Öne çıkanlar

    /// Yalnızca süzgeçsiz, aramasız görünümde: yarım kalan kitap ve açık seri.
    @ViewBuilder
    private var highlights: some View {
        if let item = model.continueItems().first {
            HomeSection(title: "Kaldığın yerden", contained: false) {
                LibraryContinueCard(item: item) { open(item, continuing: true) }
            }
            .homeEntrance(3)
        }

        if let child = profileManager.currentProfile?.id, series.openSeries(for: child) != nil {
            HomeSection(title: "Serim") { SeriesCard(childID: child) }
                .homeEntrance(4)
        }
    }

    // MARK: - Kitaplarım

    @ViewBuilder
    private var shelf: some View {
        let items = model.items(for: filter, query: query, sort: sort)
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            MPSectionHeader(title: filter == .all ? "Kitaplarım" : filter.title, trailing: { sortMenu })
            if items.isEmpty {
                noMatch
            } else {
                LibraryShelfGrid(items: items, pageWidth: width,
                                 singleColumn: typeSize.isAccessibilitySize,
                                 open: { open($0) }, menu: { quickActions($0) })
            }
        }
        .homeEntrance(5)
    }

    /// Küçük sıra menüsü; varsayılan son okunan.
    private var sortMenu: some View {
        Menu {
            Picker("Sırala", selection: $sort) {
                ForEach(LibrarySort.allCases) { Text($0.title).tag($0) }
            }
        } label: {
            HStack(spacing: MPSpacing.xxs) {
                Text(sort.title).mpText(.callout)
                MPIcon("chevron.down", size: MP.G.xs, weight: .bold).accessibilityHidden(true)
            }
            .foregroundStyle(MPColor.actionPrimary)
            .frame(minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Sıralama: \(sort.title)")
        .onChange(of: sort) { _, _ in MPHaptics.selection() }
    }

    /// Süzgeç ya da arama boş döndü. Ragi zaten yukarıda; burada yalnızca söz.
    private var noMatch: some View {
        let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: MPSpacing.md) {
            Text(searching ? "Eşleşen kitap yok" : "Burada henüz kitap yok")
                .mpText(.title3).foregroundStyle(MPColor.textPrimary)
            Text(searching ? "\u{201C}\(query)\u{201D} için bir şey bulamadık. Başka bir sözcük dene."
                           : "Okudukça kitapların burada toplanır.")
                .mpText(.body).foregroundStyle(MPColor.textSecondary).multilineTextAlignment(.center)
            MPButton(title: searching ? "Aramayı temizle" : "Bütün kitaplar", kind: .soft, size: .small) {
                query = ""
                select(.all)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xxl)
    }

    // MARK: - Boş kitaplık

    private var emptyLibrary: some View {
        VStack(spacing: MPSpacing.lg) {
            if pendingCount > 0 { pendingNote }
            MPStateView(mascot: .reading, tone: .lav, title: "Kitaplığın henüz boş",
                        message: pendingCount > 0 ? "Onaylanan masallar burada görünür."
                                                  : "İlk masalını yarat ya da Günlük'ten bir klasik aç; burada seni beklesin.") {
                MPButton(title: "İlk masalını yarat", systemImage: "wand.and.sparkles") {
                    app.startStoryCreation()
                }
            }
        }
    }

    /// Sakin bir not: masal kaybolmadı, bir büyüğün onayını bekliyor.
    private var pendingNote: some View {
        HStack(alignment: .top, spacing: MPSpacing.sm) {
            MPIcon("lock", size: MP.G.sm, weight: .semibold)
                .foregroundStyle(MPColor.actionPrimary)
                .accessibilityHidden(true)
            Text(pendingCount == 1
                 ? "1 masal onay bekliyor. Bir büyüğün Ebeveyn bölümünden onaylaması gerekiyor."
                 : "\(pendingCount) masal onay bekliyor. Bir büyüğün Ebeveyn bölümünden onaylaması gerekiyor.")
                .mpText(.callout)
                .foregroundStyle(MPColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(MPSpacing.lg)
        .mpKidSurface(MPWorldTone.lav.soft, edge: MPWorldTone.lav.edge, radius: MPRadius.card)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Kapak menüsü

    /// Kapağa basılı tutunca açılan kısa menü: okuma ve favori. Yazdır ve sil
    /// burada yok: ebeveyn kapısı isteyen işlemler "Masal ayrıntıları"nda
    /// (`StoryActionsSheet`) kalır. Sistem menüsü ikonu yalnızca
    /// `Label(systemImage:)` ile alır, `MPIcon` burada kullanılamaz.
    @ViewBuilder
    private func quickActions(_ item: LibraryItem) -> some View {
        Button { open(item, continuing: true) } label: {
            Label(item.isPartlyRead ? "Okumaya devam et" : "Okumaya başla", systemImage: "book")
        }
        if item.kind == .story {
            if item.progress > 0 {
                Button { readFromStart(item) } label: {
                    Label("Baştan oku", systemImage: "arrow.counterclockwise")
                }
            }
            Button { toggleFavorite(item) } label: {
                Label(item.isFavorite ? "Favorilerden çıkar" : "Favorilere ekle",
                      systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            Divider()
            Button { open(item) } label: {
                Label("Masal ayrıntıları", systemImage: "ellipsis.circle")
            }
        }
    }

    private func readFromStart(_ item: LibraryItem) {
        guard let story = storyManager.getStory(id: item.id) else { return }
        app.read(story, fromStart: true)
    }

    private func toggleFavorite(_ item: LibraryItem) {
        let now = favorites.toggle(item.id)
        MPHaptics.selection()
        app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı", symbol: "heart.fill")
    }

    // MARK: - Açma

    private func open(_ item: LibraryItem, continuing: Bool = false) {
        switch item.kind {
        case .story:
            guard let story = storyManager.getStory(id: item.id) else { return }
            // Devam kartı doğrudan okuyucuya; raftaki kapak seçenekleri açar.
            if continuing { app.read(story) } else { app.actionsStory = story }
        case .classic:
            guard let tale = ClassicsLibrary.shared.catalog.tale(item.id) else { return }
            app.readClassic(tale)
        }
    }

    // MARK: - Veri

    /// Onay kapısı en başta: "hangi masallar var" sorusunun cevabını o verir;
    /// raflar, süzgeç ve arama o cevabın üstünde çalışır.
    private func refresh() {
        let profile = profileManager.currentProfile
        let gate: (UUID) -> Bool = { settings.isApproved($0) }
        let stories = MPStoryGate.visible(storyManager.stories, approvalRequired: settings.approve, isApproved: gate)
            .filter { $0.belongs(to: profile) }
        pendingCount = MPStoryGate.pending(storyManager.stories, approvalRequired: settings.approve, isApproved: gate)
            .filter { $0.belongs(to: profile) }
            .count
        let catalog = ClassicsLibrary.shared.catalog
        let classics = classicProgress.entries.compactMap { id, entry in
            catalog.tale(id).map { (tale: $0, fraction: entry.isFinished ? 1 : entry.fraction, openedAt: entry.openedAt) }
        }
        let next = LibraryShelfModel.build(
            stories: stories,
            isFavorite: { favorites.contains($0) },
            seriesTotal: { series.series(containing: $0)?.episodes.count },
            classics: classics)
        if next != model { model = next }
        if !model.availableFilters.contains(filter) { filter = .all }
    }
}

#Preview("Kitaplık") {
    LibraryView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
