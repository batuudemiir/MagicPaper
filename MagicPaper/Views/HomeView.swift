import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Sıra teslimdeki gibi: çocuğun başlığı, "Bu akşamın masalı" kartı (4 durum),
/// haftalık okuma şeridi, Ragi'nin sorusu ve mod şeridi, devam eden seri,
/// günün masalı. Dünya şeridinin yerinde modlar duruyor: dünyalar içerik
/// geldikçe eklenecek (karar 7 Ekim 2026).
///
/// Yenileme (13 Ekim 2026): illüstrasyonlu başlık sahnesi (uyku saatinde gece),
/// sahnenin kenarında yıldız ve seri çipleri, sert alt kenarlı kartlar
/// (`MPHomeChrome.swift`).
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared
    @StateObject private var dailyManager = DailyStoryManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Kaydırma ölçüsü: içerik sabitlemesinden etkilenmeyen görünmez işaret.
                Color.clear.frame(height: 0)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { y in
                        // Kaydırma karesi başına durum YAZILMAZ: her yazım sayfanın
                        // tamamını yeniden hesaplatır ve başlık bölgesinde kasma
                        // yapıyordu (16 Ekim). Kaydırmaya bağlı görsel etkiler
                        // `visualEffect` içinde çizim anında hesaplanır; burada
                        // yalnızca bir kez dinlenme konumu, seyrek de eşik geçişi yazılır.
                        if restY == nil { restY = y }
                        // Şerit sahne tamamen saatin altından geçince açılır;
                        // daha önce açılınca gökyüzünün üstünde beyaz blok
                        // gibi görünüyordu (16 Ekim).
                        let past = (restY ?? y) - y > sceneHeight
                        if past != scrolledPastScene { scrolledPastScene = past }
                    }
                content
            }
        }
        .background(pageBackground.ignoresSafeArea())
        // Kartlar saat çubuğunun altından geçerken saat okunur kalsın.
        // Sıfır yükseklikli şeridin zemini yalnızca saat çubuğunun alanına taşar.
        .overlay(alignment: .top) {
            Color.clear.frame(height: 0)
                .background(pageBackground.ignoresSafeArea(edges: .top))
                .opacity(scrolledPastScene ? 1 : 0)
                .animation(MP.M.gated(MP.M.easeOut), value: scrolledPastScene)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        // Pahalı hesaplar kaydırma sırasında değil, veri değişince yapılır.
        .onAppear(perform: refreshCaches)
        .onChange(of: storyManager.stories) { _, _ in refreshCaches() }
        .onChange(of: profileManager.currentProfile?.id) { _, _ in refreshCaches() }
        .onChange(of: profileManager.currentProfile?.age) { _, _ in
            availableModes = Self.modes(for: profileManager.currentProfile)
        }
    }

    private func refreshCaches() {
        let modes = Self.modes(for: profileManager.currentProfile)
        if modes != availableModes { availableModes = modes }
        stars = profileManager.currentProfile.map { MPStars.count(for: $0, stories: storyManager.stories) } ?? 0
        gunlukItems = Self.makeGunlukItems(classics)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
            HomeHeader(greeting: greeting, childName: activeName, isNight: isNight,
                       avatar: { MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor,
                                          size: MPSize.headerAvatar) },
                       onAvatar: { app.openKidCorner() },
                       onLock: { app.requestParentMode() })
                .padding(.top, MPSpacing.md)
                // Saatin altına girmeden kaydırdıkça solar (çizim anında; durum yok).
                .visualEffect { [restY] content, proxy in
                    let y = proxy.frame(in: .global).minY
                    let scrolled = max(0, (restY ?? y) - y)
                    return content.opacity(max(0, 1 - scrolled / MP.S.x8))
                }

            // Sahnenin alt kenarına binen çipler, hemen altında bu akşamın kartı.
            VStack(spacing: MPSpacing.md) {
                // Çipler Benim köşem'e götürür: yıldız ve serinin ayrıntısı orada
                // (basılabilir görünen öğe çalışsın, 16 Ekim denetimi).
                Button { MPHaptics.tap(); app.openKidCorner() } label: {
                    HomeStatChips(stars: stars, streak: streak.currentStreak)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityElement(children: .combine)
                .accessibilityHint("Benim köşemi açar")
                HomeHeroCard(state: tonightState, coverIcon: tonightCover?.icon,
                             coverTone: tonightCover?.tone ?? .yellow, onPrimary: tonightAction)
            }
            .padding(.top, sceneClearance)
            .homeEntrance(0)

            if !shownModes.isEmpty { modeStrip.homeEntrance(1) }

            if !gunlukItems.isEmpty {
                HomeGunlukPreview(items: gunlukItems) {
                    MPHaptics.tap()
                    app.tab = .gunluk
                }
                .homeEntrance(2)
            }

            Button { MPHaptics.tap(); app.openKidCorner() } label: {
                HomeStreakCard(done: streak.thisWeek, streak: streak.currentStreak, todayIndex: todayIndex)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityHint("Benim köşemi açar")
            .homeEntrance(3)

            if let child = profileManager.currentProfile?.id,
               SeriesManager.shared.cardState(for: child) != nil {
                HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                    .homeEntrance(4)
            }

            // Bu akşamın kartı zaten günün masalını gösteriyorsa ikinci kez gösterilmez.
            if let daily = todaysDaily, !heroShowsDaily { dailySection(daily).homeEntrance(5) }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.bottom, MPSpacing.xxxl)
        // Sahne içerikle birlikte kayar; kartlar sabit bir zeminin üstünden geçmez.
        .background(alignment: .top) {
            // Üst pay geniş: aşağı çekince sahne içerikle birlikte iner, açılan
            // boşluğu gökyüzü rengi doldurur (esneme yok, karar 16 Ekim).
            HomeScene(isNight: isNight, height: sceneHeight, bleed: 400, mascotLift: 46)
        }
    }

    /// Sahne ekran genişliğine göre ölçeklenir; çipler sahnenin alt kenarına biner.
    @State private var width: CGFloat = 402
    /// İçeriğin dinlenme konumu (global y); kaydırma etkileri buna göre çizilir.
    @State private var restY: CGFloat?
    @State private var scrolledPastScene = false
    /// Referanstaki gibi ekranın yaklaşık %40'ı (saat çubuğu dahil): çipler ve
    /// bu akşamın kartı ilk bakışta görünür.
    private var sceneHeight: CGFloat { min(max(width * 0.74, 270), 340) }
    /// Başlıktan çiplere kadar: çipler sahnenin alt kenarına biner.
    private var sceneClearance: CGFloat { sceneHeight - 132 }

    /// Uyku saatinde sahne geceye döner; sayfa açık kalır.
    private var isNight: Bool {
        if case .bedtime = tonightState { return true }
        return false
    }

    /// Her sabah 1, sonuna kadar okunan her masal 1 (`MPStars`).
    @State private var stars = 0

    // MARK: - Başlık

    private var activeName: String {
        profileManager.currentProfile?.name ?? "Arkadaşım"
    }

    /// Saate göre selam: akşam açılan bir masal uygulamasına "günaydın"
    /// demek, ürünün ne için var olduğunu bilmemek olurdu.
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11:  return "Günaydın,"
        case 11..<17: return "İyi günler,"
        case 17..<22: return "İyi akşamlar,"
        default:      return "İyi geceler,"
        }
    }

    private var todayIndex: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }

    // MARK: - Bu akşamın masalı

    private var todaysDaily: DailyStory? {
        dailyManager.todaysStory ?? dailyManager.dailyStories.first
    }

    /// Kural `MPTonight`'ta (SCREENS.md 11): widget ve Siri de aynı masalı
    /// seçer. Görünüm yalnızca metne çevirir.
    private var tonight: MPTonightSource.Resolved { MPTonightSource.current(settings: settings) }

    private var tonightState: TonightState {
        switch tonight.tonight() {
        case .bedtime(let bedtime):
            return .bedtime(time: bedtime.clockLabel)
        case .resume(let resume):
            return .resume(progress: resume.progress, title: resume.title,
                           meta: "Sayfa \(resume.page) / \(resume.pageCount)")
        case .unread(let daily):
            return .unread(title: daily.title, meta: "\(daily.minutes) dakika")
        case .readToday:
            return .readToday
        }
    }

    /// "Okunmadı" durumunda hero kartı günün masalını gösterir.
    private var heroShowsDaily: Bool {
        if case .unread = tonightState { return true }
        return false
    }

    private var tonightCover: (icon: String, tone: MPWorldTone)? {
        let tonight = tonight
        switch tonight.tonight() {
        case .resume:
            guard let story = tonight.resumeStory else { return nil }
            return (story.mpWorld.icon, story.mpWorld.tone)
        case .unread:
            return ("book", .sky)
        default:
            return nil
        }
    }

    private func tonightAction() {
        MPHaptics.tap()
        app.openTonight()
    }

    // MARK: - Günlük önizlemesi

    private var classics: ClassicsLibrary { .shared }

    /// Çizimi gelmiş klasikler (en çok 8); günün klasiği başta.
    @State private var gunlukItems: [HomeGunlukPreview.Item] = []

    private static func makeGunlukItems(_ classics: ClassicsLibrary) -> [HomeGunlukPreview.Item] {
        var tales = classics.catalog.standaloneTales.filter { UIImage(named: $0.cover) != nil }
        if let today = classics.todaysTale, let i = tales.firstIndex(where: { $0.id == today.id }) {
            tales.insert(tales.remove(at: i), at: 0)
        }
        return tales.prefix(8).map {
            .init(id: $0.id, title: $0.title, minutes: $0.minutes, asset: $0.cover, focus: $0.coverFocus)
        }
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

    /// Soru ve mod düğmeleri tek kartta; Ragi sahnede olduğu için kart maskotsuz.
    /// Masal yaratmaya giriş: büyük mod kartları (Ragi sahnede; kart maskotsuz).
    private var modeStrip: some View {
        HomeSection(title: "Yeni bir masal yaz", contained: false) {
            let wide = shownModes.count == 1 || typeSize.isAccessibilitySize
            let layout = wide
                ? AnyLayout(VStackLayout(spacing: MPSpacing.sm))
                : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
            layout {
                ForEach(shownModes, id: \.self) { mode in
                    HomeModeCard(title: mode.shortTitle, systemImage: mode.symbol, tone: mode.tone,
                                 art: modeArt(mode), wide: wide, night: isNight && wide,
                                 badge: mode == emphasizedMode ? "Bu akşam" : nil) {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    }
                    .accessibilityLabel(mode == emphasizedMode ? "\(mode.title), bu akşam için önerilen" : mode.title)
                    .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                }
            }
            // "Bu akşam" etiketi kartın üst kenarına biner.
            .padding(.top, emphasizedMode == nil ? 0 : MPSpacing.sm)
        }
    }

    /// Mod kartının sahneciği (`Assets.xcassets/Scenes`); uyku saatinde tek kart
    /// kaldığında Uyku'nun gece hâli.
    private func modeArt(_ mode: StoryMode) -> String {
        mode == .bedtime && isNight && shownModes.count == 1
            ? "Scenes/mode-bedtime-night" : "Scenes/mode-\(mode.rawValue)"
    }

    /// Sayfa zemini beyaz (15 Ekim, Apple düzeni); bölümler açık gri ya da pastel.
    private var pageBackground: Color { MPColor.backgroundSurface }

    // MARK: - Günün masalı

    private func dailySection(_ daily: DailyStory) -> some View {
        Button { MPHaptics.tap(); app.dailyReading = daily } label: {
            HomeSection(title: "Günün masalı") {
                // En büyük yazı boyutlarında görsel metnin üstüne iner;
                // başlık kelime ortasından bölünmez.
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
                    : AnyLayout(HStackLayout(spacing: MPSpacing.lg))
                layout {
                    MPIcon(daily.category.mpSymbol, size: MP.G.xl, weight: .semibold)
                        .foregroundStyle(MPWorldTone.green.deep)
                        .frame(width: 64, height: 64)
                        .background(MPWorldTone.green.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                        Text("Herkes için").mpText(.caption).foregroundStyle(MPColor.textSecondary)
                        Text(daily.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(daily.readingTime) dakika").mpText(.footnote)
                            .foregroundStyle(MPColor.textSecondary)
                    }
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    MPIcon("play.fill", size: MP.G.md, weight: .bold)
                        .foregroundStyle(MPColor.actionPrimary)
                        .frame(width: 44, height: 44)
                        .background(MPColor.backgroundSurface, in: Circle())
                        .overlay(Circle().strokeBorder(MPColor.actionPrimary, lineWidth: 2))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Masalı okur")
    }
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
