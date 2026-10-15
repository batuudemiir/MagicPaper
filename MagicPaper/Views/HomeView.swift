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
                        // İlk ölçüm dinlenme konumu; üstüne çekilen kadar sahne esner.
                        if restY == nil { restY = y }
                        let rest = restY ?? y
                        pull = max(0, y - rest)
                        // Sahne yarıya kadar kaydıysa saat çubuğunun altına zemin gelir.
                        let past = rest - y > sceneHeight / 2
                        if past != scrolledPastScene { scrolledPastScene = past }
                    }
                content
            }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        // Kartlar saat çubuğunun altından geçerken saat okunur kalsın.
        // Sıfır yükseklikli şeridin zemini yalnızca saat çubuğunun alanına taşar.
        .overlay(alignment: .top) {
            Color.clear.frame(height: 0)
                .background(MPColor.backgroundKid.ignoresSafeArea(edges: .top))
                .opacity(scrolledPastScene ? 1 : 0)
                .animation(MP.M.gated(MP.M.easeOut), value: scrolledPastScene)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
            HomeHeader(greeting: greeting, childName: activeName, isNight: isNight,
                       avatar: { MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor,
                                          size: MPSize.headerAvatar) },
                       onAvatar: { app.openKidCorner() },
                       onLock: { app.requestParentMode() })
                .padding(.top, MPSpacing.md)

            // Sahnenin alt kenarına binen çipler, hemen altında bu akşamın kartı.
            VStack(spacing: MPSpacing.md) {
                HomeStatChips(stars: stars, streak: streak.currentStreak)
                HomeHeroCard(state: tonightState, coverIcon: tonightCover?.icon,
                             coverTone: tonightCover?.tone ?? .yellow, onPrimary: tonightAction)
            }
            .padding(.top, sceneClearance)

            Button { MPHaptics.tap(); app.openKidCorner() } label: {
                HomeStreakCard(done: streak.thisWeek, streak: streak.currentStreak, todayIndex: todayIndex)
            }
            .buttonStyle(MPPressStyle())
            .accessibilityHint("Benim köşemi açar")

            if !shownModes.isEmpty { modeStrip }

            if let child = profileManager.currentProfile?.id,
               SeriesManager.shared.cardState(for: child) != nil {
                HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
            }

            // Bu akşamın kartı zaten günün masalını gösteriyorsa ikinci kez gösterilmez.
            if let daily = todaysDaily, !heroShowsDaily { dailySection(daily) }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.bottom, MPSpacing.xxxl)
        // Sahne içerikle birlikte kayar; kartlar sabit bir zeminin üstünden geçmez.
        .background(alignment: .top) {
            HomeScene(isNight: isNight, height: sceneHeight, bleed: 80, mascotLift: 46, pull: pull)
        }
        // Aşağı çekerken hiçbir öğe kaymaz: içerik çekilen mesafe kadar geri
        // tutulur, yalnızca sahne görseli yerinde büyür. Ölçüm üstteki
        // ayrı işaretten okunur; bu kaydırma ölçümü etkilemez.
        .offset(y: -pull)
    }

    /// Sahne ekran genişliğine göre ölçeklenir; çipler sahnenin alt kenarına biner.
    @State private var width: CGFloat = 402
    /// Esneyen başlık: içeriğin dinlenme konumu ve aşağı çekilen mesafe.
    @State private var restY: CGFloat?
    @State private var pull: CGFloat = 0
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
    private var stars: Int {
        profileManager.currentProfile.map { MPStars.count(for: $0, stories: storyManager.stories) } ?? 0
    }

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

    // MARK: - Mod şeridi

    private var shownModes: [StoryMode] {
        let age = profileManager.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        let available = StoryCreationSteps.allowedModes(StoryChoiceSources.current.availableModes(forAge: age),
                                                        isBedtime: MPBedtime.isBedtime(settings: settings))
        return StoryCreationSteps.shownModes(available)
    }

    /// Soru ve mod düğmeleri tek kartta; Ragi sahnede olduğu için kart maskotsuz.
    private var modeStrip: some View {
        HomeSection(title: "Bu akşam nasıl bir masal olsun?") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                     count: typeSize.isAccessibilitySize ? 1 : 3),
                      spacing: MPSpacing.sm) {
                ForEach(shownModes, id: \.self) { mode in
                    HomeModeTile(title: mode.shortTitle, systemImage: mode.symbol, tone: mode.tone) {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    }
                    .accessibilityLabel(mode.title)
                    .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                }
            }
        }
    }

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
