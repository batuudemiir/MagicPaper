import SwiftUI

/// Günlük içindeki sayfalar.
enum GunlukRoute: Hashable {
    /// `nil`: hepsi. Yaş bandı Kategoriler'den gelir.
    case shelf(ClassicShelf?, MPAgeRange? = nil)
    case search
    case tale(UUID)
    case series(UUID)
    /// Çocuk sayfaları (`MPKidRoute`) bu sekmede açılırsa.
    case kid(MPKidRoute)
}

/// Günlük · ücretsiz masallar (FAZ 20, `Gunluk`).
///
/// 13 Kasım 2026: başlık, raf çipleri, öne çıkan kitap, aynı ölçüde kapak
/// rafları (Original, seçki, klasikler, Anadolu, fabllar), gece bölgesi (Uyku vakti, "Kendi masalını yaz").
struct GunlukView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var library = ClassicsLibrary.shared
    @EnvironmentObject private var settings: MPSettingsStore
    @State private var showCategories = false
    @State private var scrolled = false

    var body: some View {
        NavigationStack(path: $app.router.masallarPath) {
            ScrollViewReader { reader in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                        // Bölümleri kart değil boşluk ayırır; kart yalnızca
                        // dokunulan öğelerde (karar: 7 Kasım 2026).
                        VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                            // 13 Kasım 2026: tam ekran vitrin yerine başlık, raf
                            // çipleri ve öne çıkan kitap; altında hep aynı ölçüde
                            // kapak rafları (kitap her yerde aynı kitap).
                            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                                titleBar
                                shelfChips
                                GunlukHeaderCarousel(
                                    slides: slides,
                                    onOpen: { app.router.masallarPath.append(.tale($0.id)) },
                                    onRead: { app.readClassic($0) })
                            }
                            // MagicPaper Original: boşsa hiç çizilmez.
                            shelfSection(.orijinal)
                            weeklySection
                            shelfSection(.klasikler)
                            shelfSection(.anadolu)
                            shelfSection(.fabllar)
                        }
                        .padding(.horizontal, MPSpacing.screenH)

                        // Sayfa gece gökyüzüyle biter: Uyku vakti, "Kahramanı sen ol"
                        // ve manzara tek renkte, vitrinin karşılığı olan bir sahne.
                        GunlukNightZone {
                            bedtimeSection
                            GunlukSceneFooter { heroPromo }
                        }
                    }
                    .padding(.bottom, GunlukLayout.bottomClearance)
                    .id(Self.top)
                    .mpTracksScroll($scrolled)
                }
                // Sekmeye yeniden dokunmak: açık sayfalar kapanır, sayfa başa döner.
                .onChange(of: app.router.tabReselections) { _, _ in
                    guard app.router.tab == .gunluk else { return }
                    if app.router.masallarPath.isEmpty {
                        withAnimation(MP.M.gated(MP.M.base)) { reader.scrollTo(Self.top, anchor: .top) }
                    } else {
                        app.router.masallarPath = []
                    }
                }
            }
            .overlay(alignment: .top) { MPStatusBarBackdrop(visible: scrolled, fill: MPColor.backgroundSurface) }
            .background(MPColor.backgroundSurface.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GunlukRoute.self) { route in
                destination(route)
            }
        }
        .sheet(isPresented: $showCategories) {
            GunlukCategoriesView { shelf, band in
                showCategories = false
                app.router.masallarPath = [.shelf(shelf, band)]
            }
            .mpSheet(.full)
        }
    }

    @ViewBuilder
    private func destination(_ route: GunlukRoute) -> some View {
        switch route {
        case .shelf(let shelf, let band):
            GunlukShelfView(shelf: shelf, ageBand: band, path: $app.router.masallarPath)
        case .search:
            GunlukShelfView(shelf: nil, startsSearching: true, path: $app.router.masallarPath)
        case .tale(let id):
            if let tale = library.tale(id) {
                ClassicDetailView(tale: tale, path: $app.router.masallarPath)
            }
        case .series(let id):
            if let series = library.catalog.series(id) {
                ClassicSeriesView(series: series, path: $app.router.masallarPath)
            }
        case .kid(let page):
            KidPageView(route: page)
        }
    }

    private static let top = "gunluk-top"

    private var titleBar: some View {
        MPKidTabHeader(title: "Masallar") {
            MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara") {
                app.router.masallarPath.append(.search)
            }
        }
        .padding(.top, MPSpacing.lg)
    }

    // MARK: - Raf çipleri

    /// Bütün raflar başlığın altında tek satırda; "Tüm raflar" kategorileri
    /// ve yaş seçimini açar.
    private var shelfChips: some View {
        GunlukRow(spacing: MPSpacing.sm) {
            GunlukShelfChip(title: "Tüm raflar", symbol: "square.grid.2x2", tone: .gray) {
                showCategories = true
            }
            .accessibilityHint("Kategorileri ve yaş seçimini açar")
            ForEach(Self.doorShelves) { shelf in
                GunlukShelfChip(title: shelf.chipTitle, symbol: shelf.symbol, tone: shelf.tone) {
                    app.router.masallarPath.append(.shelf(shelf))
                }
                .accessibilityLabel("\(shelf.chipTitle), \(count(shelf)) masal")
            }
        }
    }

    private static let doorShelves: [ClassicShelf] = [.klasikler, .anadolu, .fabllar, .uyku, .seriler]

    private func count(_ shelf: ClassicShelf) -> Int {
        library.items(in: shelf).count + (shelf == .uyku ? library.originals(in: .uyku).count : 0)
    }

    private var isBedtime: Bool { MPBedtime.isBedtime(settings: settings) }

    // MARK: - Raflar


    /// Vitrinin slaytları; seçki bunları tekrarlamaz.
    private var slides: [ClassicHeaderSlide] {
        library.headerSlides(isBedtime: isBedtime)
    }

    @ViewBuilder
    private var weeklySection: some View {
        let shown = Set(slides.map(\.tale.id))
        let picks = library.weeklyPicks.filter { !shown.contains($0.id) }
        if !picks.isEmpty {
            GunlukSection(title: "Bu haftanın seçkisi", subtitle: "Editörün bu hafta için seçtikleri") {
                GunlukRow {
                    ForEach(picks) { item in
                        ClassicShelfCard(item: item, width: Self.coverWidth, height: Self.coverHeight) { open(item) }
                    }
                }
            }
        }
    }

    /// Bütün rafların kapak ölçüsü: kitap her rafta aynı boyda durur.
    private static let coverWidth: CGFloat = 128
    private static let coverHeight: CGFloat = 176

    @ViewBuilder
    private func shelfSection(_ shelf: ClassicShelf) -> some View {
        let items = library.items(in: shelf)
        if !items.isEmpty {
            GunlukSection(title: shelf.title, subtitle: shelf.subtitle,
                          action: { app.router.masallarPath.append(.shelf(shelf)) }) {
                GunlukRow {
                    ForEach(items) { item in
                        ClassicShelfCard(item: item, width: Self.coverWidth, height: Self.coverHeight) { open(item) }
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
                          night: true, surface: false, action: { app.router.masallarPath.append(.shelf(.uyku)) }) {
                // Boyalı kapaklar önde; çizimi bekleyen orijinaller sonda.
                GunlukRow(inset: MPSpacing.screenH) {
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

    // MARK: - Kendi masalını yaz

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
                    Text("Kendi masalını yaz").mpText(.section).foregroundStyle(MPColor.textOnAction)
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
        case .tale(let tale): app.router.masallarPath.append(.tale(tale.id))
        case .series(let series, _): app.router.masallarPath.append(.series(series.id))
        }
    }
}
