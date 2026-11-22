import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Tek soru: "Bu akşam ne okuyoruz?" (karar 7 Kasım 2026). Sıra: çocuğun başlığı,
/// bu akşamın kartı (4 durum), yeni masal için üç mod, varsa devam eden seri.
/// Günün masalı ayrı bölüm değil: bu akşamın kartında ve Masallar'da.
///
/// Yenileme (13 Ekim 2026): illüstrasyonlu başlık sahnesi (uyku saatinde gece),
/// sahnenin kenarında yıldız ve seri çipleri, sert alt kenarlı kartlar
/// (`MPHomeChrome.swift`).
///
/// 22 Ekim 2026 (Batuhan onayı): iOS düzeni. Düz beyaz sayfa, sola yaslı büyük
/// başlık ve altında tek satır yıldız/seri; tam genişlik sahne bu akşamın
/// kartının içine taşındı (Ragi orada, ekranın tek maskotu). Modlar resimli
/// kartlar yerine masal yazma adımlarıyla aynı satırlar. 7 Kasım 2026: bölümler
/// panelsiz, lavanta (`cardSoft`) yalnızca bu akşamın kartında.
///
/// 14 Kasım 2026 (Batuhan): iki kademe (`KidLevel`). Okul öncesi çocukta selam
/// ve yıldız satırı yok, mod karoları büyük; sayfa ad, bu akşamın kartı ve üç
/// karodan ibaret. Masallar önizlemesi iki kademede de kalktı: keşfin yeri
/// Masallar sekmesi.
///
/// 19 Kasım 2026 (İrem, tasarım): tam genişlik sahne sayfanın tepesine döndü
/// (`HomeHeaderScene`), selam ve ad sahnenin üstünde; 22 Ekim'deki "sahne bu
/// akşamın kartında" düzeninin yerine. Kart artık sahnesiz, Ragi başlıkta.
///
/// 21 Kasım 2026 (`docs/ANA_SAYFA_HAZIRLIK.md` A3, A4): selam, bu akşamın
/// durumu, gece, yıldız, gün ve seri kartı `HomeFeedStore`'dan gelir. Depo
/// ekranın okuduğu her kaynağı dinler ve saat ilerleyince (yatma saati, gece
/// yarısı, selam saatleri) kendiliğinden yenilenir. Görünüş değişmedi.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    /// Rozet planı R4: yeni rozet ya da kat, selamın üst satırında bir kez.
    @ObservedObject private var badgeNews = MPBadgeNews.shared
    /// Ekranın kararları ve canlı verisi (`HomeFeed`).
    @StateObject private var feedStore = HomeFeedStore()
    private var feed: HomeFeed { feedStore.feed }

    var body: some View {
        // Sahne saat çubuğunun altına uzanır (19 Kasım 2026): kaydırma üst güvenli
        // alanı yok sayar, başlık güvenli alanın altından başlar.
        GeometryReader { geo in
            MPTabScroll(tab: .home) {
                content(topInset: geo.safeAreaInsets.top)
            }
            .ignoresSafeArea(edges: .top)
        }
        // Saat çubuğunun altında şerit yok: içerik iOS'un standart davranışıyla
        // altından akar. Beyaz şerit renkli kartların üstünde blok gibi
        // görünüyordu (Batuhan, 16 Ekim).
        .background(pageBackground.ignoresSafeArea())
        // Pahalı hesaplar kaydırma sırasında değil, veri değişince yapılır.
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
        VStack(alignment: .leading, spacing: MPSpacing.xl) {
            // 19 Kasım 2026 (İrem): selam ve ad tam genişlik sahnenin üstünde
            // (`HomeHeaderScene`); ekranın tek Ragi'si orada, kart sahnesiz.
            HomeHeaderScene(isNight: isNight, topInset: topInset, compact: largeType) {
                // Rozet notu iki kademede de bir kez; selam yalnızca okuyan çocukta.
                // En büyük yazıda selam düşer (A5): kartın düğmesi ilk ekranda kalsın.
                // Başlık orada sahnenin altında, kâğıtta: açık yazı yok.
                MPKidTabHeader(title: activeName,
                               eyebrow: badgeNews.homeNote(for: profileManager.currentProfile?.id)
                                   ?? (level == .little || largeType ? nil : feed.greeting),
                               onArt: isNight && !largeType) {
                    // Yıldız ve gün başlığın sağında (13 Kasım 2026).
                    if showsStats, !largeType { statLine(compact: true, onArt: isNight) }
                }
            }

            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                VStack(alignment: .leading, spacing: MPSpacing.md) {
                    HomeHeroCard(state: feed.tonight, isNight: isNight, showsScene: false,
                                 art: feed.cover, onPrimary: tonightAction)
                    // En büyük yazıda yıldız ve gün kartın altında (A5): ad
                    // daralmaz, kartın düğmesi aşağı itilmez.
                    if showsStats, largeType { statLine(compact: false, onArt: false) }
                }
                .homeEntrance(0)

                // Modlar kartın hemen altında, kıvrımın üstünde (Faz 7): seri kartı
                // onları aşağı itiyordu.
                if !shownModes.isEmpty { modeStrip.homeEntrance(1) }

                if let child = profileManager.currentProfile?.id, feed.hasSeriesCard {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                        .homeEntrance(2)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.bottom, GunlukLayout.bottomClearance)
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Açık çocuğun kademesi; profil yokken okuyan çocuğun düzeni.
    private var level: KidLevel { profileManager.currentProfile?.kidLevel ?? .big }

    /// Okul öncesi çocuk sayıyı okuyamaz: yıldız ve gün satırı Profil'de kalır.
    private var showsStats: Bool { level == .big }

    /// Satır Odam'a götürür: yıldız ve serinin ayrıntısı orada.
    /// Sıfırlar yazılmaz: "0 gün üst üste" kimseye bir şey söylemez.
    @ViewBuilder
    private func statLine(compact: Bool, onArt: Bool) -> some View {
        if feed.stars > 0 || feed.streak > 0 {
            Button { MPHaptics.tap(); app.router.openKidCorner() } label: {
                HomeStatLine(stars: feed.stars, streak: feed.streak, compact: compact, onArt: onArt)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityHint("Profili açar")
        }
    }

    /// Uyku saatinde başlık sahnesi geceye döner; sayfa açık kalır.
    private var isNight: Bool { feed.isNight }

    /// Erişilebilirlik yazı boyutları: sahne kısa bant, başlık kâğıtta (A5).
    private var largeType: Bool { typeSize.isAccessibilitySize }

    // MARK: - Başlık

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    // MARK: - Bu akşamın masalı

    /// Kartın kapağı `HomeFeed.cover`'da (A6): yarım masal, günün masalı.
    private func tonightAction() {
        MPHaptics.tap()
        app.openTonight()
    }

    // MARK: - Mod şeridi

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

    /// Masal yaratmaya giriş (13 Kasım 2026, Batuhan): yan yana üç karo, öne
    /// çıkan mod "Bu akşam" etiketli. Karo akışı o modla, ikinci adımdan açar.
    /// En büyük yazı boyutlarında 22 Ekim'in satırları: karoya ad sığmaz.
    private var modeStrip: some View {
        HomeSection(title: "Yeni bir masal yaz") {
            if typeSize.isAccessibilitySize { modeRows } else { modeTiles }
        }
    }

    private var modeTiles: some View {
        HStack(alignment: .top, spacing: MPSpacing.sm) {
            ForEach(shownModes, id: \.self) { mode in
                HomeModeTile(title: mode.title, systemImage: mode.symbol, tone: mode.tone,
                             badge: mode == emphasizedMode ? "Bu akşam" : nil, fillHeight: true,
                             large: level == .little) {
                    MPHaptics.tap()
                    app.startStoryCreation(mode: mode)
                }
                .accessibilityLabel(mode == emphasizedMode ? "\(mode.title), bu akşam için önerilen" : mode.title)
                .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        // Etiket karonun üst kenarına biner: başlığa değmesin.
        .padding(.top, emphasizedMode == nil ? 0 : MPSpacing.xs)
    }

    private var modeRows: some View {
            VStack(spacing: 0) {
                ForEach(Array(shownModes.enumerated()), id: \.element) { index, mode in
                    if index > 0 { MPRowDivider(area: .kid) }
                    Button {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    } label: {
                        MPListRow(systemImage: mode.symbol, tone: mode.tone, title: mode.title,
                                  subtitle: mode == emphasizedMode ? "Bu akşam için önerilen" : mode.promise)
                            .frame(minHeight: MPSize.minTouchHero)
                    }
                    .buttonStyle(MPPressStyle(.highlight))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(mode == emphasizedMode ? "\(mode.title), bu akşam için önerilen" : mode.title)
                    .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                }
            }
            // Satırın kendi boşluğu sayfa kenarıyla hizalansın: panel yok.
            .padding(.horizontal, -MPSpacing.md)
    }

    /// Sayfa zemini sıcak kâğıt (22 Kasım 2026, İrem; 15 Ekim'deki beyazın
    /// yerine): başlık sahnesi buna erir. Lavanta yalnızca bu akşamın kartında.
    private var pageBackground: Color { MP.C.homePaper }
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
