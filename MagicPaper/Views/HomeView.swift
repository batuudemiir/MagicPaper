import SwiftUI

/// 11 · Ana sayfa (`AnaSayfa`).
///
/// Tek soru: "Bu akşam ne okuyoruz?" (karar 7 Kasım 2026). Sıra: çocuğun başlığı,
/// bu akşamın kartı (4 durum), varsa devam eden seri, yeni masal için üç mod,
/// Masallar rafı. Günün masalı ayrı bölüm değil: bu akşamın kartında ve Masallar'da.
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
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared

    var body: some View {
        MPTabScroll(tab: .home) {
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
                MPKidTabHeader(title: activeName, eyebrow: greeting)
                // Satır Profil'e götürür: yıldız ve serinin ayrıntısı orada.
                // Sıfırlar yazılmaz: "0 gün üst üste" kimseye bir şey söylemez.
                if stars > 0 || streak.currentStreak > 0 {
                    Button { MPHaptics.tap(); app.router.openKidCorner() } label: {
                        HomeStatLine(stars: stars, streak: streak.currentStreak)
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityHint("Odamı açar")
                }
            }
            .padding(.top, MPSpacing.lg)

            HomeHeroCard(state: tonightState, isNight: isNight, onPrimary: tonightAction)
                .homeEntrance(0)

            // Modlar kartın hemen altında, kıvrımın üstünde (Faz 7): seri kartı
            // onları aşağı itiyordu.
            if !shownModes.isEmpty { modeStrip.homeEntrance(1) }

            if let child = profileManager.currentProfile?.id,
               SeriesManager.shared.cardState(for: child) != nil {
                HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                    .homeEntrance(2)
            }

            if !gunlukItems.isEmpty {
                HomeGunlukPreview(items: gunlukItems, onOpen: { id in
                    MPHaptics.tap()
                    app.router.tab = .gunluk
                    app.router.masallarPath = [.tale(id)]
                }, action: {
                    MPHaptics.tap()
                    app.router.tab = .gunluk
                })
                .homeEntrance(3)
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.bottom, GunlukLayout.bottomClearance)
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

    // MARK: - Bu akşamın masalı

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

    private func tonightAction() {
        MPHaptics.tap()
        app.openTonight()
    }

    // MARK: - Günlük önizlemesi

    private var classics: ClassicsLibrary { .shared }

    /// Çizimi gelmiş klasikler (en çok 4; keşif Masallar'da); günün klasiği başta.
    @State private var gunlukItems: [HomeGunlukPreview.Item] = []

    private static func makeGunlukItems(_ classics: ClassicsLibrary) -> [HomeGunlukPreview.Item] {
        var tales = classics.catalog.standaloneTales.filter { UIImage(named: $0.cover) != nil }
        if let today = classics.todaysTale, let i = tales.firstIndex(where: { $0.id == today.id }) {
            tales.insert(tales.remove(at: i), at: 0)
        }
        return tales.prefix(4).map {
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
        HomeSection(title: "Yeni bir masal yaz") {
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
    }

    /// Sayfa zemini beyaz (15 Ekim, Apple düzeni); lavanta yalnızca bu akşamın kartında.
    private var pageBackground: Color { MPColor.backgroundSurface }
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
