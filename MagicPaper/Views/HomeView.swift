import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Sıra teslimdeki gibi: çocuğun başlığı, "Bu akşamın masalı" kartı (4 durum),
/// haftalık okuma şeridi, Ragi'nin sorusu ve mod şeridi, devam eden seri,
/// günün masalı. Dünya şeridinin yerinde modlar duruyor: dünyalar içerik
/// geldikçe eklenecek (karar 7 Ekim 2026).
///
/// Yenileme (13 Ekim 2026): bulutlu gökyüzü bandı (uyku saatinde gece),
/// başlıkta yıldız sayacı, sert alt kenarlı kartlar (`MPHomeChrome.swift`).
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
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                HomeHeader(greeting: greeting, childName: activeName, isNight: isNight,
                           avatar: { MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor,
                                              size: MPSize.headerAvatar) },
                           onAvatar: { app.showKidCorner = true },
                           onLock: { app.requestParentMode() })
                    .padding(.top, MPSpacing.md)

                // Sahnenin alt kenarına binen çipler, hemen altında bu akşamın kartı.
                VStack(spacing: MPSpacing.md) {
                    HomeStatChips(stars: stars, streak: streak.currentStreak)
                    HomeHeroCard(state: tonightState, coverIcon: tonightCover?.icon,
                                 coverTone: tonightCover?.tone ?? .yellow, onPrimary: tonightAction)
                }
                .padding(.top, sceneClearance)

                Button { app.showKidCorner = true } label: {
                    HomeStreakCard(done: streak.thisWeek, streak: streak.currentStreak, todayIndex: todayIndex)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityHint("Benim köşemi açar")

                if !shownModes.isEmpty { modeStrip }

                if let child = profileManager.currentProfile?.id,
                   SeriesManager.shared.cardState(for: child) != nil {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                }

                if let daily = todaysDaily { dailySection(daily) }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
            // Bant içerikle birlikte kayar; kartlar sabit bir zeminin üstünden geçmez.
            .background(alignment: .top) { HomeScene(isNight: isNight, height: sceneHeight, bleed: 120) }
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }

    /// Sahne ekran genişliğine göre ölçeklenir; çipler sahnenin alt kenarına biner.
    @State private var width: CGFloat = 402
    private var sceneHeight: CGFloat { width * 1.12 }
    /// Başlıktan çiplere kadar sahnenin açık kalan kısmı.
    private var sceneClearance: CGFloat { max(sceneHeight - 230, 160) }

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
        app.openTonight()
    }

    // MARK: - Mod şeridi

    private var shownModes: [StoryMode] {
        let age = profileManager.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        let available = StoryCreationSteps.allowedModes(StoryChoiceSources.current.availableModes(forAge: age),
                                                        isBedtime: MPBedtime.isBedtime(settings: settings))
        return StoryCreationSteps.shownModes(available)
    }

    /// Ekranda tek Ragi: hero kartında maskot varsa soru maskotsuz bir başlık olur.
    private var modeStrip: some View {
        // Soru ve düğmeler aynı kartta.
        HomeSection(title: "Bu akşam nasıl bir masal olsun?") {
            // Ragi sahnede; ekranda tek maskot.
            EmptyView()
        } content: {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm),
                                     count: typeSize.isAccessibilitySize ? 1 : 3),
                      spacing: MPSpacing.sm) {
                ForEach(shownModes, id: \.self) { mode in
                    HomeModeTile(title: mode.shortTitle, systemImage: mode.symbol, tone: mode.tone) {
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
        Button { app.dailyReading = daily } label: {
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
