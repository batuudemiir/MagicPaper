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
    @State private var scrolled = false

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ScrollViewReader { reader in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                        // Ana sayfanın sahnesi gibi: vitrin ekranın tepesinden başlar.
                        GunlukHeaderCarousel(
                            slides: slides,
                            topInset: proxy.safeAreaInsets.top,
                            height: GunlukHeaderCarousel.height(
                                screen: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom),
                            onOpen: { path.append(.tale($0.id)) },
                            onRead: { app.readClassic($0) },
                            onSearch: { path.append(.search) })

                        // Ana sayfanın dili: bölümler arası `MPSpacing.xxl`, her raf kendi
                        // kartında (beyaz, lavanta kenar, sert alt kenar).
                        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                            shelfDoors
                            continueSection
                            weeklySection
                            shelfSection(.anadolu, width: 128, height: 176)
                            shelfSection(.klasikler, width: 128, height: 176)
                            bedtimeSection
                        }
                        .padding(.horizontal, MPSpacing.screenH)

                        // Sayfa Ana sayfanın manzarasıyla biter.
                        GunlukSceneFooter(isNight: isBedtime) { heroPromo }
                    }
                    .padding(.bottom, GunlukLayout.bottomClearance)
                    .id(Self.top)
                    .gunlukTracksScroll($scrolled)
                }
                .ignoresSafeArea(edges: .top)
                // Sekmeye yeniden dokunmak: açık sayfalar kapanır, sayfa başa döner.
                .onChange(of: app.tabReselections) { _, _ in
                    guard app.tab == .gunluk else { return }
                    if path.isEmpty {
                        withAnimation(MP.M.gated(MP.M.base)) { reader.scrollTo(Self.top, anchor: .top) }
                    } else {
                        path = []
                    }
                }
                }
            }
            .overlay(alignment: .top) { GunlukStatusBarBackdrop(visible: scrolled) }
            .background(MPColor.backgroundKid.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GunlukRoute.self) { route in
                destination(route)
            }
        }
        .sheet(isPresented: $showCategories) {
            GunlukCategoriesView { shelf, band in
                showCategories = false
                path = [.shelf(shelf, band)]
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(MPRadius.sheet)
            .presentationBackground(MPColor.backgroundKid)
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

    private static let top = "gunluk-top"

    // MARK: - Raf kapıları

    /// "Hangi raftan okuyalım?": Ana sayfadaki "Bu akşam nasıl bir masal
    /// olsun?" kartının dili; düz çiplerin yerine.
    private var shelfDoors: some View {
        GunlukSection(title: "Hangi raftan okuyalım?") {
            GunlukRow(spacing: MPSpacing.sm, inset: MPSpacing.lg) {
                ForEach(Self.doorShelves) { shelf in
                    GunlukShelfTile(title: shelf.chipTitle, symbol: shelf.symbol, tone: shelf.tone,
                                    count: count(shelf)) { path.append(.shelf(shelf)) }
                }
                GunlukShelfTile(title: "Tüm raflar", symbol: "square.grid.2x2", tone: .gray, count: nil) {
                    showCategories = true
                }
                .accessibilityHint("Kategorileri ve yaş seçimini açar")
            }
        }
    }

    private static let doorShelves: [ClassicShelf] = [.klasikler, .anadolu, .fabllar, .uyku, .seriler]

    private func count(_ shelf: ClassicShelf) -> Int {
        library.items(in: shelf).count + (shelf == .uyku ? library.originals(in: .uyku).count : 0)
    }

    private var isBedtime: Bool { MPBedtime.isBedtime(settings: settings) }

    // MARK: - Raflar

    @ViewBuilder
    private var continueSection: some View {
        // Vitrindeki masal burada tekrar etmez ("Kaldığın yerden" slaytı).
        let shown = Set(slides.map(\.tale.id))
        let items = library.continueReading.filter { !shown.contains($0.id) }
        if !items.isEmpty {
            GunlukSection(title: "Kaldığın yerden", symbol: "bookmark", tone: .peach) {
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(items) { item in
                        ContinueClassicCard(item: item) { resume(item.id) }
                    }
                }
            }
        }
    }

    /// Vitrinin slaytları; seçki bunları tekrarlamaz.
    private var slides: [ClassicHeaderSlide] {
        library.headerSlides(isBedtime: isBedtime)
    }

    @ViewBuilder
    private var weeklySection: some View {
        let shown = Set(slides.map(\.tale.id))
        let picks = library.weeklyPicks.filter { !shown.contains($0.id) }
        if !picks.isEmpty {
            GunlukSection(title: "Bu haftanın seçkisi", subtitle: "Editörün bu hafta için seçtikleri",
                          symbol: "star", tone: .yellow) {
                GunlukRow(spacing: MPSpacing.sm, inset: MPSpacing.lg) {
                    ForEach(Array(picks.enumerated()), id: \.element.id) { index, item in
                        RankedPickCard(rank: index + 1, item: item) { open(item) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func shelfSection(_ shelf: ClassicShelf, width: CGFloat, height: CGFloat) -> some View {
        let items = library.items(in: shelf)
        if !items.isEmpty {
            GunlukSection(title: shelf.title, subtitle: shelf.subtitle, symbol: shelf.symbol, tone: shelf.tone,
                          action: { path.append(.shelf(shelf)) }) {
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
            GunlukSection(title: ClassicShelf.uyku.title, subtitle: ClassicShelf.uyku.subtitle, symbol: "moon",
                          night: true, action: { path.append(.shelf(.uyku)) }) {
                // Boyalı kapaklar önde; çizimi bekleyen orijinaller sonda.
                GunlukRow(inset: MPSpacing.lg) {
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: 160, height: 200, onDark: true) { open(item) }
                    }
                    ForEach(originals) { original in
                        ClassicShelfCard(title: original.story.title, meta: original.meta, cover: original.cover.cover,
                                         focus: original.cover.coverFocus, width: 160, height: 200, onDark: true) {
                            app.readOriginal(original.story)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Kahramanı sen ol

    /// Markanın çağrısı: Ana sayfanın hero kartı gibi dolgun mor, sert gece
    /// kenarı. Ragi kartta değil, altındaki manzarada (ekranda tek maskot).
    private var heroPromo: some View {
        Button { app.startStoryCreation() } label: {
            HStack(spacing: MPSpacing.md) {
                MPIcon("wand.and.sparkles", size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                    .background(MPWorldTone.lav.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kahramanı sen ol").mpText(.title3).foregroundStyle(MPColor.textOnAction)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Adınla, sevdiklerinle yepyeni bir masal").mpText(.footnote)
                        .foregroundStyle(MPWorldTone.lav.soft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                MPIcon("chevron.right", size: MP.G.md, weight: .bold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.minTouchParent, height: MPSize.minTouchParent)
                    .background(MPColor.backgroundSurface, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(MPSpacing.lg)
            .mpKidSurface(MPColor.actionPrimary, edge: MPColor.brandNight)
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
