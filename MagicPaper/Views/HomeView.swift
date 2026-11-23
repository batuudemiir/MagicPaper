import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Tek soru: "Bu akşam ne okuyoruz?" (karar 7 Kasım 2026).
///
/// 23 Kasım 2026 (İrem, yeni düzen; prototip `design-preview/app/home.js`,
/// bileşenler `MPHomeBoard.swift`): üstte mor gökten beyaza inen başlık; solda
/// menü, sağda bildirim ve arama (`MPCircleButton`), "Merhaba, <ad>", el sallayan
/// Ragi ve üç bilgi kartı (yıldız, okuma günü, masallar). Ortada koyu mor bu
/// akşamın kartı (Ragi'nin ayakları kartın alt çizgisinde), altında "Yeni bir
/// masal yaz" liste satırları ve varsa devam eden seri. Gece/gündüz sahnesi yok.
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
        }
        // Rozet notu bir kez söylenir: ana sayfadan çıkınca düşer.
        .onDisappear { badgeNews.consumeHomeNote(profileManager.currentProfile?.id) }
        .onChange(of: storyManager.stories) { _, _ in refreshCaches() }
        .onChange(of: profileManager.currentProfile?.id) { _, _ in refreshCaches() }
        .onChange(of: profileManager.currentProfile?.age) { _, _ in
            availableModes = Self.modes(for: profileManager.currentProfile)
        }
    }

    private func refreshCaches() {
        let modes = Self.modes(for: profileManager.currentProfile)
        if modes != availableModes { availableModes = modes }
    }

    private func content(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(topInset: topInset)

            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                HomeTonightBoard(state: feed.tonight, onPrimary: tonightAction)
                    // Ragi kartın üstüne taşar: bilgi kartlarıyla arasında yer.
                    .padding(.top, typeSize.isAccessibilitySize ? MPSpacing.xl : MPSpacing.xxxl)
                    .homeEntrance(0)

                if !shownModes.isEmpty { modeSection.homeEntrance(1) }

                if let child = profileManager.currentProfile?.id, feed.hasSeriesCard {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                        .homeEntrance(2)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.bottom, GunlukLayout.bottomClearance)
    }

    // MARK: - Başlık

    private func header(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            HStack(spacing: MPSpacing.sm) {
                MPCircleButton(systemImage: "line.3.horizontal", accessibilityLabel: "Menü", action: openMenu)
                Spacer(minLength: 0)
                MPCircleButton(systemImage: "bell", accessibilityLabel: hasNews ? "Bildirimler, yeni rozet var" : "Bildirimler",
                               action: openNews)
                    .overlay(alignment: .topTrailing) {
                        // Alt çubuktaki gibi sessiz marka noktası: yeni rozet var.
                        if hasNews {
                            Circle().fill(MP.C.brand)
                                .frame(width: MP.S.x2 + MP.S.x1, height: MP.S.x2 + MP.S.x1)
                                .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
                                .offset(x: -MP.S.x1, y: MP.S.x1)
                                .accessibilityHidden(true)
                        }
                    }
                MPCircleButton(systemImage: "magnifyingglass", accessibilityLabel: "Masal ara", action: openSearch)
            }

            HStack(alignment: .bottom, spacing: MPSpacing.sm) {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Merhaba, \(activeName)").font(MP.F.displayLG()).foregroundStyle(MP.C.textOnArt)
                        .lineLimit(2).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    if level == .big {
                        Text(subtitle).mpText(.supporting).fontWeight(.semibold).foregroundStyle(MP.C.textOnArtMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize {
                    // Ragi bilgi kartlarının arkasına iner (kartlar sonra çizilir).
                    MascotImage(mascot: .waving, width: MPSize.minTouchHero * 2)
                        .padding(.bottom, -MPSpacing.xxxl)
                        .accessibilityHidden(true)
                }
            }

            if showsStats { stats }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.xs)
        .padding(.bottom, MPSpacing.xs)
        .background(
            LinearGradient(stops: MP.C.homeSky, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
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

    private var hasNews: Bool { badgeNews.homeNote(for: profileManager.currentProfile?.id) != nil }

    /// Menü (23 Kasım 2026, `KidMenuSheet`): var olan sayfalar ve okuma yolculuğu.
    private func openMenu() {
        MPHaptics.tap()
        app.router.sheet = .menu
    }

    /// Bildirim: yeni rozetler Profil'de.
    private func openNews() {
        MPHaptics.tap()
        app.router.openKidCorner()
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

    /// Başlık ve artı (baştan masal yazma), altında modlar liste satırı olarak.
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Yeni bir masal yaz") {
                MPCircleButton(systemImage: "plus", accessibilityLabel: "Masal yaz") {
                    MPHaptics.tap()
                    app.startStoryCreation()
                }
            }
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
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
