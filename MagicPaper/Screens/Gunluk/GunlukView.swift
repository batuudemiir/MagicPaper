import SwiftUI

/// Günlük içindeki sayfalar.
enum GunlukRoute: Hashable {
    /// `nil`: hepsi. Yaş bandı Kategoriler'den gelir.
    case shelf(ClassicShelf?, MPAgeRange? = nil)
    case search
    case tale(UUID)
    case series(UUID)
}

/// Günlük · ücretsiz masallar (FAZ 20, `Gunluk`).
///
/// Sıra İrem'in tasarımında: başlık ve arama, çipler, Günün masalı,
/// Kaldığın yerden, Bu haftanın seçkisi, Anadolu'dan, Dünya klasikleri,
/// Uyku vakti, "Kahramanı sen ol".
struct GunlukView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var library = ClassicsLibrary.shared
    @EnvironmentObject private var settings: MPSettingsStore
    @State private var path: [GunlukRoute] = []
    @State private var showCategories = false

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                        // Ana sayfanın sahnesi gibi: vitrin ekranın tepesinden başlar.
                        GunlukHeaderCarousel(
                            slides: library.headerSlides(isBedtime: MPBedtime.isBedtime(settings: settings)),
                            topInset: proxy.safeAreaInsets.top,
                            height: GunlukHeaderCarousel.height(
                                screen: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom,
                                topInset: proxy.safeAreaInsets.top),
                            onOpen: { path.append(.tale($0.id)) },
                            onRead: { app.readClassic($0) },
                            onSearch: { path.append(.search) })

                        // Ana sayfanın dili: bölümler arası `MPSpacing.xxl`, her raf kendi
                        // kartında (beyaz, lavanta kenar, sert alt kenar).
                        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                            chips
                            continueSection
                            weeklySection
                            shelfSection(.anadolu, title: "Anadolu'dan", width: 128, height: 176)
                            shelfSection(.klasikler, title: "Dünya klasikleri", width: 128, height: 176)
                            bedtimeSection
                            heroPromo
                        }
                        .padding(.horizontal, MPSpacing.screenH)
                    }
                    .padding(.bottom, GunlukLayout.bottomClearance)
                }
                .ignoresSafeArea(edges: .top)
            }
            .background(MPColor.backgroundKid.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GunlukRoute.self) { route in
                destination(route)
            }
        }
        .fullScreenCover(isPresented: $showCategories) {
            GunlukCategoriesView { shelf, band in
                showCategories = false
                path = [.shelf(shelf, band)]
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: GunlukRoute) -> some View {
        switch route {
        case .shelf(let shelf, let band):
            GunlukShelfView(shelf: shelf, ageBand: band, path: $path)
        case .search:
            GunlukShelfView(shelf: nil, startsSearching: true, path: $path)
        case .tale(let id):
            if let tale = library.catalog.tale(id) {
                ClassicDetailView(tale: tale, path: $path)
            }
        case .series(let id):
            if let series = library.catalog.series(id) {
                ClassicSeriesView(series: series, path: $path)
            }
        }
    }

    // MARK: - Çipler

    private var chips: some View {
        GunlukRow(spacing: MPSpacing.sm) {
            GunlukChip(title: "Hepsi", isSelected: true) {}
            ForEach([ClassicShelf.klasikler, .anadolu, .uyku]) { shelf in
                GunlukChip(title: shelf.chipTitle) { path.append(.shelf(shelf)) }
            }
            GunlukChip(title: "Kategoriler", trailingChevron: true) { showCategories = true }
        }
    }

    // MARK: - Raflar

    @ViewBuilder
    private var continueSection: some View {
        let items = library.continueReading
        if !items.isEmpty {
            GunlukSection(title: "Kaldığın yerden") {
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(items) { item in
                        ContinueClassicCard(item: item) { resume(item.id) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var weeklySection: some View {
        let picks = library.weeklyPicks
        if !picks.isEmpty {
            GunlukSection(title: "Bu haftanın seçkisi") {
                GunlukRow(spacing: MPSpacing.sm, inset: MPSpacing.lg) {
                    ForEach(Array(picks.enumerated()), id: \.element.id) { index, item in
                        RankedPickCard(rank: index + 1, item: item) { open(item) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func shelfSection(_ shelf: ClassicShelf, title: String, width: CGFloat, height: CGFloat) -> some View {
        let items = library.items(in: shelf)
        if !items.isEmpty {
            GunlukSection(title: title, action: { path.append(.shelf(shelf)) }) {
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: width, height: height) { open(item) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bedtimeSection: some View {
        let items = library.items(in: .uyku)
        let originals = library.originals(in: .uyku)
        if !items.isEmpty || !originals.isEmpty {
            GunlukSection(title: "Uyku vakti", action: { path.append(.shelf(.uyku)) }) {
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(originals) { original in
                        ClassicShelfCard(title: original.story.title, meta: original.meta, cover: original.cover.cover,
                                         focus: original.cover.coverFocus, width: 160, height: 200) {
                            app.readOriginal(original.story)
                        }
                    }
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: 160, height: 200) { open(item) }
                    }
                }
            }
        }
    }

    // MARK: - Kahramanı sen ol

    private var heroPromo: some View {
        Button { app.startStoryCreation() } label: {
            HStack(spacing: MPSpacing.md + 2) {
                MascotImage(mascot: .pencil, width: 92).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kahramanı sen ol").mpText(.button).foregroundStyle(MPColor.textPrimary)
                    Text("Adınla yepyeni bir masal").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MPIcon("chevron.right", size: MP.G.md, weight: .bold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                    .background(MPWorldTone.lav.soft, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(.vertical, MPSpacing.md)
            .padding(.leading, MPSpacing.md - 2)
            .padding(.trailing, MPSpacing.lg)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yeni bir masal yaratır")
    }

    // MARK: - Gezinme

    private func open(_ item: ClassicItem) {
        switch item {
        case .tale(let tale): path.append(.tale(tale.id))
        case .series(let series, _): path.append(.series(series.id))
        }
    }

    /// "Kaldığın yerden": doğrudan okuyucuya.
    private func resume(_ id: UUID) {
        if let tale = library.catalog.tale(id) {
            app.readClassic(tale)
        } else if let original = library.original(id) {
            app.readOriginal(original.story)
        }
    }
}
