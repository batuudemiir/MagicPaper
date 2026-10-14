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
    @ObservedObject private var favorites = MPFavorites.shared
    @State private var path: [GunlukRoute] = []
    @State private var showCategories = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                // Ana sayfanın dili: bölümler arası `MPSpacing.xxl`, her raf kendi
                // kartında (beyaz, lavanta kenar, sert alt kenar).
                VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                    VStack(alignment: .leading, spacing: MPSpacing.lg + 2) {
                        header
                        chips
                    }
                    if let today = library.todaysTale {
                        VStack(spacing: MPSpacing.md + 2) {
                            ClassicHeroCard(tale: today) { path.append(.tale(today.id)) }
                            heroActions(today)
                        }
                    }
                    continueSection
                    weeklySection
                    shelfSection(.anadolu, title: "Anadolu'dan", width: 128, height: 176)
                    shelfSection(.klasikler, title: "Dünya klasikleri", width: 128, height: 176)
                    bedtimeSection
                    heroPromo
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.bottom, GunlukLayout.bottomClearance)
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

    // MARK: - Başlık ve çipler

    private var header: some View {
        HStack(alignment: .bottom) {
            Text("Günlük").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: MPSpacing.sm)
            MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara",
                           bordered: false, fill: MPColor.backgroundSunken) {
                path.append(.search)
            }
        }
        .padding(.top, MPSpacing.xl)
    }

    private var chips: some View {
        GunlukRow(spacing: MPSpacing.sm) {
            GunlukChip(title: "Hepsi", isSelected: true) {}
            ForEach([ClassicShelf.klasikler, .anadolu, .uyku]) { shelf in
                GunlukChip(title: shelf.chipTitle) { path.append(.shelf(shelf)) }
            }
            GunlukChip(title: "Kategoriler", trailingChevron: true) { showCategories = true }
        }
    }

    // MARK: - Günün masalı

    private func heroActions(_ tale: ClassicTale) -> some View {
        let saved = favorites.contains(tale.id)
        return HStack(spacing: MPSpacing.md - 2) {
            // Tasarımdaki düz mor "Oku" (tasarım yasası: butonda gradient yok).
            Button { app.readClassic(tale) } label: {
                HStack(spacing: MPSpacing.sm) {
                    MPIcon("play", size: 18, weight: .bold).accessibilityHidden(true)
                    Text("Oku").mpText(.button)
                }
                .foregroundStyle(MPColor.textOnAction)
                .frame(maxWidth: .infinity, minHeight: MPSize.buttonHeight)
                .mpKidSurface(MPColor.actionPrimary, edge: MPColor.brandNight, radius: MPSize.buttonHeight / 2)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel("\(tale.title) masalını oku")
            Button {
                let now = favorites.toggle(tale.id)
                MPHaptics.tap()
                app.showToast(now ? "Listene eklendi" : "Listenden çıkarıldı", symbol: now ? "checkmark" : "minus")
            } label: {
                MPIcon(saved ? "checkmark" : "plus", size: MP.G.md, weight: .bold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.buttonHeight, height: MPSize.buttonHeight)
                    .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge, radius: MPSize.buttonHeight / 2)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityLabel(saved ? "Listemden çıkar" : "Listeme ekle")
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

// MARK: - Günün masalı kartı

/// Tam taşan boyalı kapak, altta karartma ve masalın adı. Uygulamada
/// illüstrasyon üstünde metin taşıyan iki yerden biri (öteki `MPArtHero`).
struct ClassicHeroCard: View {
    let tale: ClassicTale
    var eyebrow: String = "Günün masalı"
    var height: CGFloat = 452
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ClassicCoverImage(asset: tale.cover, focus: tale.coverFocus, seed: tale.title)
                .frame(height: height)
                .frame(maxWidth: .infinity)
                // Tasarımdaki gibi: karartma yüksekliğin %40'ında başlar, alt kenarda
                // en koyu (MP.Scrim.peak); metin doğrudan resmin üstünde durur.
                .overlay {
                    LinearGradient(stops: [.init(color: MP.Scrim.ink.opacity(0), location: 0.4),
                                           .init(color: MP.Scrim.solid, location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text(eyebrow).mpText(.eyebrow).foregroundStyle(MP.C.textOnArtMuted)
                        Text(tale.title).mpText(.heroTitle).foregroundStyle(MP.C.textOnArt)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(tale.fullMeta).mpText(.callout).foregroundStyle(MP.C.textOnArtMuted)
                    }
                    .padding(MPSpacing.xl + 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                // Ana sayfanın hero kartı gibi: derinlik sert alt kenardan.
                .mpKidSurface(MPColor.brandNight, edge: MPColor.brandNight)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(eyebrow): \(tale.title). \(tale.fullMeta)")
        .accessibilityHint("Masalın sayfasını açar")
    }
}
