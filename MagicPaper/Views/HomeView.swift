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
///
/// 22 Ekim 2026 (Batuhan onayı): iOS düzeni. Düz beyaz sayfa, sola yaslı büyük
/// başlık ve altında tek satır yıldız/seri; tam genişlik sahne bu akşamın
/// kartının içine taşındı (Ragi orada, ekranın tek maskotu). Modlar resimli
/// kartlar yerine masal yazma adımlarıyla aynı satırlar; bölümler lavanta (`cardSoft`).
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
            content
        }
        // Saat çubuğunun altında şerit yok: içerik iOS'un standart davranışıyla
        // altından akar. Beyaz şerit renkli kartların üstünde blok gibi
        // görünüyordu (Batuhan, 16 Ekim).
        .background(pageBackground.ignoresSafeArea())
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
            VStack(alignment: .leading, spacing: 0) {
                HomeHeader(greeting: greeting, childName: activeName,
                           avatar: { MPAvatar(name: activeName, color: profileManager.currentProfile?.mpColor,
                                              size: MPSize.headerAvatar) },
                           onAvatar: { app.openKidCorner() },
                           onLock: { app.requestParentMode() })
                // Satır Benim köşem'e götürür: yıldız ve serinin ayrıntısı orada.
                Button { MPHaptics.tap(); app.openKidCorner() } label: {
                    HomeStatLine(stars: stars, streak: streak.currentStreak)
                }
                .buttonStyle(MPPressStyle())
                .accessibilityHint("Benim köşemi açar")
            }
            .padding(.top, MPSpacing.md)

            HomeHeroCard(state: tonightState, isNight: isNight, onPrimary: tonightAction)
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
    }

    /// Uyku saatinde kartın sahnesi geceye döner; sayfa açık kalır.
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

    /// Masal yaratmaya giriş: masal yazma adımlarıyla aynı satırlar, tek gri
    /// listede (22 Ekim 2026; önceden resimli büyük kartlar). Satır akışı o
    /// modla, ikinci adımdan açar.
    private var modeStrip: some View {
        HomeSection(title: "Yeni bir masal yaz", contained: false) {
            VStack(spacing: 0) {
                ForEach(Array(shownModes.enumerated()), id: \.element) { index, mode in
                    if index > 0 { MPRowDivider(area: .kid) }
                    Button {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    } label: {
                        MPListRow(systemImage: mode.symbol, tone: mode.tone, title: mode.title,
                                  subtitle: mode == emphasizedMode ? "Bu akşam için önerilen" : mode.promise)
                            .frame(minHeight: MPSize.minTouchKid)
                    }
                    .buttonStyle(MPPressStyle(.highlight))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(mode == emphasizedMode ? "\(mode.title), bu akşam için önerilen" : mode.title)
                    .accessibilityHint("Masalda kimlerin olacağını seçmeye geçer")
                }
            }
            .padding(.vertical, MPSpacing.xxs)
            .background(MPColor.cardSoft,
                        in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        }
    }

    /// Sayfa zemini beyaz (15 Ekim, Apple düzeni); bölümler lavanta (`cardSoft`).
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
