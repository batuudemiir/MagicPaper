import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Tek soru: "Bu akşam ne okuyoruz?" (karar 7 Kasım 2026).
///
/// 23 Kasım 2026 (İrem, yeni düzen; prototip `design-preview/app/home.js`,
/// bileşenler `MPHomeBoard.swift`): üstte mor gökten beyaza inen başlık; solda
/// menü, sağda bildirim ve arama (`MPCircleButton`), "Merhaba, <ad>" ve üç bilgi kartı (yıldız, okuma günü, masallar). Ortada koyu mor bu
/// akşamın kartı (Ragi'nin ayakları kartın alt çizgisinde), altında "Yeni bir
/// masal yaz" liste satırları ve varsa devam eden seri. Gece/gündüz sahnesi yok.
///
/// 26 Kasım 2026 (Batuhan): mor gök gradienti kalktı, başlık düz kâğıtta ve
/// koyu yazıyla; İrem'in öğeleri ve dizilimi kaldı. Bu akşamın kartı boyalı
/// kapakla kahraman öğe oldu; altına haftanın okuma günleri ve Masallar'dan
/// haftanın seçkisi eklendi. Zil "Yenilikler" sayfasını açar (`HomeNews`).
/// Önceki düzenler (sahneli başlık, Okuma köşesi) için git geçmişi.
///
/// Veri `HomeFeedStore`'dan (21 Kasım, A3/A4): selam, bu akşamın durumu, yıldız,
/// gün, masal sayısı ve seri kartı; saat ve kaynaklar değişince yenilenir.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    /// Rozet planı R4: yeni rozet ya da kat; bildirim noktası ve başlıkta bir kez.
    @ObservedObject private var badgeNews = MPBadgeNews.shared
    /// Ekranın kararları ve canlı verisi (`HomeFeed`).
    @StateObject private var feedStore = HomeFeedStore()
    private var feed: HomeFeed { feedStore.feed }

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Başlığın göğü saat çubuğunun altına uzanır: kaydırma üst güvenli alanı
        // yok sayar, düğmeler güvenli alanın altından başlar.
        GeometryReader { geo in
            MPTabScroll(tab: .home) {
                content(topInset: geo.safeAreaInsets.top)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear {
            refreshCaches()
            // Sekmeye dönünce: başka sekmedeyken kaçan bir değişim kalmasın.
            feedStore.refresh()
            refreshNews()
        }
        // Rozet notu bir kez söylenir: ana sayfadan çıkınca düşer.
        .onDisappear { badgeNews.consumeHomeNote(profileManager.currentProfile?.id) }
        .onChange(of: storyManager.stories) { _, _ in refreshCaches() }
        .onChange(of: profileManager.currentProfile?.id) { _, _ in refreshCaches(); refreshNews() }
        .onChange(of: feed) { _, _ in refreshNews() }
        .onReceive(app.router.$sheet) { sheet in if sheet == nil { refreshNews() } }
        .onChange(of: profileManager.currentProfile?.age) { _, _ in
            availableModes = Self.modes(for: profileManager.currentProfile)
        }
    }

    private func refreshCaches() {
        let modes = Self.modes(for: profileManager.currentProfile)
        if modes != availableModes { availableModes = modes }
    }

    /// Dizilim (26 Kasım 2026): başlık ve bilgi kartları · bu akşamın kahraman
    /// kartı · haftanın okuma günleri · "Yeni bir masal yaz" · devam eden seri ·
    /// Masallar'dan haftanın seçkisi. Bölümleri boşluk ayırır, panel değil.
    private func content(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(topInset: topInset)

            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                HomeTonightBoard(state: feed.tonight, cover: feed.cover, onPrimary: tonightAction)
                    // Ragi kartın üstüne taşar: bilgi kartlarıyla arasında yer.
                    .padding(.top, typeSize.isAccessibilitySize ? MPSpacing.xl : MPSpacing.xxxl)
                    .homeEntrance(0)

                if level == .big, let journey {
                    ReadingJourneyWidget(journey: journey, showsRagi: false) {
                        if let id = profileManager.currentProfile?.id { app.router.openKidPage(.journey(id)) }
                    }
                    .homeEntrance(1)
                }

                if !shownModes.isEmpty { modeSection.homeEntrance(2) }

                if let child = profileManager.currentProfile?.id, feed.hasSeriesCard {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                        .homeEntrance(3)
                }

                if !weeklyPicks.isEmpty { weeklySection.homeEntrance(4) }
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.bottom, GunlukLayout.bottomClearance)
    }

    // MARK: - Başlık

    /// Düz kâğıt başlık (26 Kasım 2026, Batuhan: mor gök gradienti kalktı).
    /// İrem'in öğeleri ve dizilimi aynı: solda menü, sağda zil ve arama,
    /// altında selam ve üç bilgi kartı. Yazı koyu, zemin sayfanın kendisi.
    private func header(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            HStack(spacing: MPSpacing.sm) {
                MPCircleButton(systemImage: "line.3.horizontal", accessibilityLabel: "Menü", action: openMenu)
                Spacer(minLength: 0)
                MPCircleButton(systemImage: "bell", accessibilityLabel: news.isEmpty ? "Yenilikler" : "Yenilikler, yeni bir şey var",
                               action: openNews)
                    .overlay(alignment: .topTrailing) {
                        // Sessiz marka noktası: görülmemiş bir yenilik var.
                        if hasUnseenNews {
                            Circle().fill(MP.C.brand)
                                .frame(width: MP.S.x2 + MP.S.x1, height: MP.S.x2 + MP.S.x1)
                                .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
                                .offset(x: -MP.S.x1, y: MP.S.x1)
                                .accessibilityHidden(true)
                        }
                    }
                MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara", action: openSearch)
            }

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text("\(feed.greeting) \(activeName)").font(MP.F.displayLG()).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(2).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                if level == .big {
                    Text(subtitle).mpText(.supporting).fontWeight(.semibold).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsStats { stats }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.xs)
    }

    private var stats: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
        return layout {
            HomeStatCard(systemImage: "star.fill", tone: .yellow, label: "Yıldız", value: "\(feed.stars)", unit: "yıldız")
            HomeStatCard(systemImage: "flame.fill", tone: .peach, label: "Okuma", value: "\(feed.streak)", unit: "gün üst üste")
            HomeStatCard(systemImage: "book.fill", tone: .lav, label: "Masallarım", value: "\(feed.stories)", unit: "masal")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Selamın altı: yeni rozet notu bir kez, yoksa saate göre soru.
    private var subtitle: String {
        if let note = badgeNews.homeNote(for: profileManager.currentProfile?.id) { return note }
        return feed.greeting == "İyi akşamlar," || feed.greeting == "İyi geceler,"
            ? "Bu akşam hangi masalı okuyalım?" : "Bugün hangi masalı okuyalım?"
    }

    /// Zilin listesi ve noktası (`HomeNews`); ana sayfa görünür olunca yenilenir.
    @State private var news = HomeNews(items: [])
    @State private var hasUnseenNews = false

    private func refreshNews() {
        let child = profileManager.currentProfile?.id
        news = HomeNews.live(childID: child)
        journey = profileManager.currentProfile.map { ReadingJourney.live(for: $0) }
        hasUnseenNews = news.hasUnseen(seen: HomeNewsSeen.ids(for: child))
    }

    /// Menü (23 Kasım 2026, `KidMenuSheet`): var olan sayfalar ve okuma yolculuğu.
    private func openMenu() {
        MPHaptics.tap()
        app.router.sheet = .menu
    }

    /// Zil: "Yenilikler" sayfası (26 Kasım 2026; önceden yalnızca Profil'e geçiyordu).
    private func openNews() {
        MPHaptics.tap()
        hasUnseenNews = false
        app.router.sheet = .news
    }

    /// Arama Masallar'da odakla açılır.
    private func openSearch() {
        MPHaptics.tap()
        app.router.tab = .gunluk
        app.router.masallarPath = [.search]
    }

    /// Açık çocuğun kademesi; profil yokken okuyan çocuğun düzeni.
    private var level: KidLevel { profileManager.currentProfile?.kidLevel ?? .big }

    /// Okul öncesi çocuk sayıyı okuyamaz: bilgi kartları Profil'de kalır.
    private var showsStats: Bool { level == .big }

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    // MARK: - Bu akşamın masalı

    private func tonightAction() {
        MPHaptics.tap()
        app.openTonight()
    }

    // MARK: - Yeni bir masal yaz

    /// Yaşa uygun modlar. Motor bütün kataloğu güvenlik kurallarına karşı
    /// tarar (yüzlerce ms): gövdede hesaplanınca her yeniden çizim, kaydırma
    /// sırasında 166 ms'lik donmalar yapıyordu (16 Ekim, cihaz ölçümü). Bu
    /// yüzden yalnızca profil ya da yaş değişince hesaplanıp saklanır.
    @State private var availableModes: [StoryMode] = []

    private static func modes(for profile: UserProfile?) -> [StoryMode] {
        let age = profile?.age ?? AgeBandResolver.mvp.upperBound
        return StoryChoiceSources.current.availableModes(forAge: age)
    }

    /// Uyku saatinde Uyku öncesi önde; diğer modlar da seçilebilir (15 Ekim 2026).
    private var emphasizedMode: StoryMode? {
        StoryCreationSteps.emphasizedMode(availableModes, isBedtime: MPBedtime.isBedtime(settings: settings))
    }

    private var shownModes: [StoryMode] {
        StoryCreationSteps.shownModes(availableModes, emphasized: emphasizedMode)
    }

    /// Başlık, altında modlar liste satırı olarak.
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // "+" kalktı (24 Kasım 2026): "Masal yaz" dairesi ve mod satırları aynı işi yapıyor.
            MPSectionHeader(title: "Yeni bir masal yaz")
            VStack(spacing: MPSpacing.sm) {
                ForEach(shownModes, id: \.self) { mode in
                    HomeModeRow(mode: mode, emphasized: mode == emphasizedMode) {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    }
                }
            }
        }
    }

    // MARK: - Okuma günleri

    /// Profil'deki "Okuma yolculuğum" kartı, Ragi'siz (ekranda tek Ragi). Gün
    /// okunmazsa boş daire; sayaç baskısı ya da "kaçırma" dili yok (CLAUDE.md §7).
    @State private var journey: ReadingJourney?

    // MARK: - Haftanın seçkisi

    private var weeklyPicks: [ClassicItem] { Array(ClassicsLibrary.shared.weeklyPicks.prefix(6)) }

    /// Masallar'ın seçkisi ana sayfada küçük bir raf; "Tümü" Masallar'ı açar.
    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Bu haftanın seçkisi", link: ("Tümü", {
                MPHaptics.tap()
                app.router.tab = .gunluk
                app.router.masallarPath = []
            }))
            GunlukRow {
                ForEach(weeklyPicks) { item in
                    ClassicShelfCard(item: item, width: Self.pickWidth, height: Self.pickWidth * MPBookCover.aspect) {
                        MPHaptics.tap()
                        app.router.tab = .gunluk
                        switch item {
                        case .tale(let tale): app.router.masallarPath = [.tale(tale.id)]
                        case .series(let series, _): app.router.masallarPath = [.series(series.id)]
                        }
                    }
                }
            }
        }
    }

    private static let pickWidth: CGFloat = 112
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
