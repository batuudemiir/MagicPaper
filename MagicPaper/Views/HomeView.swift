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
///
/// 27 Kasım 2026 (Batuhan: "bir şeyler eksik, tam profesyonel bir app gibi"):
/// başlık yeniden boyalı manzara (gradient değil, illüstrasyon; tek Ragi orada),
/// bu akşamın kartı kapaklı ve Ragi'siz, resimli mod karoları, yarım kalanlar,
/// haftanın seçkisi ve Originals rafları. Önceki düzenler için git geçmişi.
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
            refreshHalfRead()
            // Sekmeye dönünce: başka sekmedeyken kaçan bir değişim kalmasın.
            feedStore.refresh()
            refreshNews()
        }
        // Rozet notu bir kez söylenir: ana sayfadan çıkınca düşer.
        .onDisappear { badgeNews.consumeHomeNote(profileManager.currentProfile?.id) }
        .onChange(of: storyManager.stories) { _, _ in refreshCaches(); refreshHalfRead() }
        .onChange(of: profileManager.currentProfile?.id) { _, _ in refreshCaches(); refreshNews(); refreshHalfRead() }
        .onChange(of: feed) { _, _ in refreshNews(); refreshHalfRead() }
        .onReceive(app.router.$sheet) { sheet in if sheet == nil { refreshNews() } }
        .onChange(of: profileManager.currentProfile?.age) { _, _ in
            availableModes = Self.modes(for: profileManager.currentProfile)
        }
    }

    private func refreshCaches() {
        let modes = Self.modes(for: profileManager.currentProfile)
        if modes != availableModes { availableModes = modes }
    }

    /// Dizilim (27 Kasım 2026, Batuhan: "tam profesyonel bir ana sayfa"):
    /// boyalı manzaralı başlık (selam, avatar, zil, arama; ekranın tek Ragi'si
    /// manzarada) · bu akşamın kartı (kapak + tek birincil düğme) · resimli üç
    /// mod karosu · devam eden seri · yarım kalanlar rafı · haftanın seçkisi ·
    /// MagicPaper Originals · okuma yolculuğu. Bölümleri boşluk ayırır.
    private func content(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
            header(topInset: topInset)

            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                HomeTonightCard(state: feed.tonight, cover: feed.cover, onPrimary: tonightAction)
                    .homeEntrance(0)

                if !shownModes.isEmpty { modeSection.homeEntrance(1) }

                if let child = profileManager.currentProfile?.id, feed.hasSeriesCard {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                        .homeEntrance(2)
                }

                if !halfRead.isEmpty { halfReadSection.homeEntrance(3) }

                if !weeklyPicks.isEmpty {
                    shelf(title: "Bu haftanın seçkisi", items: weeklyPicks) { app.router.masallarPath = [] }
                        .homeEntrance(4)
                }

                if !originals.isEmpty {
                    shelf(title: ClassicShelf.orijinal.title, subtitle: ClassicShelf.orijinal.subtitle,
                          titleArt: ClassicShelf.orijinal.titleArt, items: originals) {
                        app.router.masallarPath = [.shelf(.orijinal)]
                    }
                    .homeEntrance(5)
                }

                if level == .big, let journey {
                    ReadingJourneyWidget(journey: journey, showsRagi: false) {
                        if let id = profileManager.currentProfile?.id { app.router.openKidPage(.journey(id)) }
                    }
                    .homeEntrance(6)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.bottom, GunlukLayout.bottomClearance)
    }

    // MARK: - Başlık

    /// Boyalı manzara (27 Kasım 2026; `HomeHeaderScene`, gündüz ve uyku
    /// saatinde gece). Gradient değil, illüstrasyon: alt kenarı sayfanın
    /// kâğıdına boyanarak erir. Üstte avatar (menüyü açar), selam ve çocuğun
    /// adı, sağda zil ve arama; altında yıldız ve okuma günü satırı. Ekranın
    /// tek Ragi'si manzarada.
    private func header(topInset: CGFloat) -> some View {
        HomeHeaderScene(isNight: feed.isNight, topInset: topInset, compact: typeSize.isAccessibilitySize) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                HStack(alignment: .center, spacing: MPSpacing.sm) {
                    Button(action: openMenu) {
                        ProfilePhoto(avatarID: avatarID, size: MPSize.circleButton)
                            .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel("Menü")
                    VStack(alignment: .leading, spacing: 0) {
                        if level == .big {
                            Text(feed.greeting).mpText(.footnote).fontWeight(.bold).foregroundStyle(headerInk)
                        }
                        Text(activeName).font(MP.F.displayLG()).foregroundStyle(headerInk)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .accessibilityElement(children: .combine)
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
                if showsStats {
                    HomeStatLine(stars: feed.stars, streak: feed.streak, onArt: onNightArt)
                }
            }
        }
    }

    /// Gece manzarasında açık yazı; gündüz ve kısa bantta (yazı kâğıtta) koyu.
    private var onNightArt: Bool { feed.isNight && !typeSize.isAccessibilitySize }
    private var headerInk: Color { onNightArt ? MP.C.textOnArt : MPColor.textPrimary }

    /// Açık çocuğun profil resmi (`HeroLookStore`); yoksa sade yer tutucu.
    @State private var avatarID: String?

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

    /// Resimli üç mod karosu yan yana (27 Kasım 2026); en büyük yazıda liste satırları.
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Yeni bir masal yaz")
            if typeSize.isAccessibilitySize {
                VStack(spacing: MPSpacing.sm) {
                    ForEach(shownModes, id: \.self) { mode in
                        HomeModeRow(mode: mode, emphasized: mode == emphasizedMode) { startCreation(mode) }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: MPSpacing.sm) {
                    ForEach(shownModes, id: \.self) { mode in
                        HomeModeArtTile(mode: mode, emphasized: mode == emphasizedMode, isNight: feed.isNight) {
                            startCreation(mode)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func startCreation(_ mode: StoryMode) {
        MPHaptics.tap()
        app.startStoryCreation(mode: mode)
    }

    // MARK: - Yarım kalanlar

    /// Kitaplığın yarım kitapları (`LibraryShelfModel`); bu akşamın kartındaki
    /// masal tekrar edilmez.
    @State private var halfRead: [LibraryItem] = []

    private var halfReadSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Yarım kalanlar", link: ("Tümü", {
                MPHaptics.tap()
                app.router.tab = .library
            }))
            GunlukRow {
                ForEach(halfRead) { item in
                    LibraryHalfReadCover(item: item, width: Self.pickWidth) { openHalfRead(item) }
                }
            }
        }
    }

    private func openHalfRead(_ item: LibraryItem) {
        switch item.kind {
        case .story:
            guard let story = storyManager.getStory(id: item.id) else { return }
            app.read(story)
        case .classic:
            guard let tale = ClassicsLibrary.shared.tale(item.id) else { return }
            app.readClassic(tale)
        }
    }

    private func refreshHalfRead() {
        let profile = profileManager.currentProfile
        let stories = MPStoryGate.visible(storyManager.stories).filter { $0.belongs(to: profile) }
        let library = ClassicsLibrary.shared
        let classics = ClassicProgressStore.shared.entries.compactMap { id, entry in
            library.tale(id).map { (tale: $0, fraction: entry.isFinished ? 1 : entry.fraction, openedAt: entry.openedAt) }
        }
        let model = LibraryShelfModel.build(
            stories: stories,
            isFavorite: { MPFavorites.shared.contains($0) },
            seriesTotal: { SeriesManager.shared.series(containing: $0)?.episodes.count },
            classics: classics)
        var items = model.continueItems(limit: 7)
        // En yenisi bu akşamın kartında ("Kaldığın yerden").
        if case .resume = feed.tonight, !items.isEmpty { items.removeFirst() }
        if items.map(\.id) != halfRead.map(\.id) { halfRead = items }
        avatarID = profile.flatMap { HeroLookStore().look(for: $0.id)?.avatar }
    }

    // MARK: - Okuma günleri

    /// Profil'deki "Okuma yolculuğum" kartı, Ragi'siz (ekranda tek Ragi). Gün
    /// okunmazsa boş daire; sayaç baskısı ya da "kaçırma" dili yok (CLAUDE.md §7).
    @State private var journey: ReadingJourney?

    // MARK: - Haftanın seçkisi

    private var weeklyPicks: [ClassicItem] { Array(ClassicsLibrary.shared.weeklyPicks.prefix(6)) }

    /// MagicPaper Originals rafı: Masallar'daki raf, ana sayfada ilk sekiz kitap.
    private var originals: [ClassicItem] {
        Array(ClassicsLibrary.shared.items(in: .orijinal).prefix(8))
    }

    /// Masallar'dan bir raf: kapaklar yatay kayar, "Tümü" Masallar'da açar.
    private func shelf(title: String, subtitle: String? = nil, titleArt: Image? = nil,
                       items: [ClassicItem], all: @escaping () -> Void) -> some View {
        GunlukSection(title: title, subtitle: subtitle, action: {
            MPHaptics.tap()
            app.router.tab = .gunluk
            all()
        }, titleArt: titleArt) {
            GunlukRow {
                ForEach(items) { item in
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
