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
/// 19 Kasım 2026 (İrem, tasarım; GPT teslimi "Okuma köşesi"): selam ve
/// avatar, tam genişlik okuma köşesi sahnesi (Ragi pencere önünde, ekranın tek
/// Ragi'si), "Bu akşam" daveti ve tek birincil düğme, "Başka bir dünya seç",
/// "Kitaplığından" (en çok iki kitap), "Masal bul" (arama + tek öneri). Kaydırınca
/// üstte küçük "Ana sayfa". Zemin sıcak kâğıt (`MP.C.homePaper`). Bileşenler
/// `MPHomeReadingNook.swift`. Yıldız/gün satırı Profil'de kalır.
struct HomeView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    /// Rozet planı R4: yeni rozet ya da kat, selamın üst satırında bir kez.
    @ObservedObject private var badgeNews = MPBadgeNews.shared

    /// Kaydırınca üstte küçük "Ana sayfa" görünür.
    @State private var scrolled = false
    /// Açık çocuğun kahramanı (avatar); giydirilmemişse standart görünüş.
    @State private var heroLook: HeroLook?
    /// "Kitaplığından": bu çocuğun kitaplığından en çok iki kitap.
    @State private var shelf: [LibraryItem] = []

    var body: some View {
        GeometryReader { geo in
            MPTabScroll(tab: .home) {
                content(width: geo.size.width, height: geo.size.height)
            }
            .overlay(alignment: .top) { compactTitle }
        }
        .background(MP.C.homePaper.ignoresSafeArea())
        // Pahalı hesaplar kaydırma sırasında değil, veri değişince yapılır.
        .onAppear(perform: refreshCaches)
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
        let profile = profileManager.currentProfile
        heroLook = profile.flatMap { HeroLookStore().look(for: $0.id) }
        shelf = Self.shelfItems(profile: profile, stories: storyManager.stories, excluding: tonightTitle)
    }

    private func content(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Rozet notu iki kademede de bir kez; selam yalnızca okuyan çocukta.
                MPKidTabHeader(title: headerTitle,
                               eyebrow: badgeNews.homeNote(for: profileManager.currentProfile?.id)) {
                    avatarButton
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.lg)

                // Küçük ekranda sahne kısılır: davet ve düğme kıvrımın üstünde kalsın.
                HomeReadingNook(height: min(width * HomeReadingNook.aspect, height * 0.46))

                HomeTonightInvite(state: tonightState, onPrimary: tonightAction)
                    .padding(.horizontal, MPSpacing.screenH)
                    .homeEntrance(0)
            }
            .mpTracksScroll($scrolled)

            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                if !worldModes.isEmpty { worldSection.homeEntrance(1) }

                if let child = profileManager.currentProfile?.id,
                   SeriesManager.shared.cardState(for: child) != nil {
                    HomeSection(title: "Devam eden seri") { SeriesCard(childID: child) }
                }

                if !shelf.isEmpty { shelfSection(width: width) }

                findSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.xxxl)
        }
        .padding(.bottom, GunlukLayout.bottomClearance)
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    /// Açık çocuğun kademesi; profil yokken okuyan çocuğun düzeni.
    private var level: KidLevel { profileManager.currentProfile?.kidLevel ?? .big }

    // MARK: - Başlık, avatar, küçük başlık

    /// "İyi geceler, İrem"; okul öncesi kademede yalnızca ad.
    private var headerTitle: String {
        level == .little ? activeName : "\(greeting) \(activeName)"
    }

    /// Çocuğun kahramanı; dokununca Profil (19 Kasım 2026, İrem: sekme
    /// başlığında avatar, 7 Kasım'daki "avatar yok" kuralının yerine).
    private var avatarButton: some View {
        Button {
            MPHaptics.tap()
            app.router.openKidCorner()
        } label: {
            HeroAvatarView(look: heroLook ?? .standard, backdrop: MPWorldTone.lav.soft)
                .frame(width: MPSize.minTouchHero, height: MPSize.minTouchHero)
                .clipShape(Circle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel("\(activeName) profilini aç")
    }

    /// Kaydırınca üstte "Ana sayfa"; sayfanın zemininde, ince alt çizgiyle.
    private var compactTitle: some View {
        VStack(spacing: 0) {
            Text("Ana sayfa").mpText(.section).foregroundStyle(MPColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MPSpacing.sm)
            Rectangle().fill(MPColor.borderKid).frame(height: 1)
        }
        .background(MP.C.homePaper.ignoresSafeArea(edges: .top))
        .opacity(scrolled ? 1 : 0)
        .animation(MP.M.gated(MP.M.easeOut), value: scrolled)
        .allowsHitTesting(false)
        .accessibilityHidden(!scrolled)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Başka bir dünya seç

    /// Davet uykuya çağırıyorsa Uyku öncesi burada tekrarlanmaz.
    private var worldModes: [StoryMode] {
        guard case .bedtime = tonightState else { return shownModes }
        return shownModes.filter { $0 != .bedtime }
    }

    private var worldSection: some View {
        HomeSection(title: "Başka bir dünya seç") {
            let count = typeSize.isAccessibilitySize ? 1 : worldModes.count
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm), count: max(1, count)),
                      spacing: MPSpacing.sm) {
                ForEach(worldModes, id: \.self) { mode in
                    HomeWorldTile(title: mode.title, art: mode.homeWorldArt, systemImage: mode.symbol, tone: mode.tone) {
                        MPHaptics.tap()
                        app.startStoryCreation(mode: mode)
                    }
                }
            }
        }
    }

    // MARK: - Kitaplığından

    private func shelfSection(width: CGFloat) -> some View {
        let cover = typeSize.isAccessibilitySize
            ? width - MPSpacing.screenH * 2
            : (width - MPSpacing.screenH * 2 - MPSpacing.sm) / 2
        return HomeSection(title: "Kitaplığından", link: ("Tümünü gör", { app.router.tab = .library })) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.lg))
                : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
            layout {
                ForEach(shelf) { item in
                    HomeShelfBook(item: item, width: cover) { open(item) }
                }
            }
        }
    }

    /// Yarım kitap kaldığı sayfadan, okunmamış kitap ilk sayfadan açılır.
    private func open(_ item: LibraryItem) {
        MPHaptics.tap()
        switch item.kind {
        case .story:
            guard let story = storyManager.getStory(id: item.id) else { return }
            app.read(story, fromStart: item.progress <= 0 || item.progress >= 1)
        case .classic:
            guard let tale = ClassicsLibrary.shared.tale(item.id) else { return }
            app.readClassic(tale)
        }
    }

    /// Kitaplık sekmesiyle aynı model; bu akşamın davetinde sunulan kitap tekrarlanmaz.
    private static func shelfItems(profile: UserProfile?, stories: [Story], excluding title: String?) -> [LibraryItem] {
        let mine = MPStoryGate.visible(stories).filter { $0.belongs(to: profile) }
        let library = ClassicsLibrary.shared
        let classics = ClassicProgressStore.shared.entries.compactMap { id, entry in
            library.tale(id).map { (tale: $0, fraction: entry.isFinished ? 1 : entry.fraction, openedAt: entry.openedAt) }
        }
        let model = LibraryShelfModel.build(
            stories: mine,
            isFavorite: { MPFavorites.shared.contains($0) },
            seriesTotal: { SeriesManager.shared.series(containing: $0)?.episodes.count },
            classics: classics)
        return Array(model.items.filter { $0.title != title }.prefix(2))
    }

    // MARK: - Masal bul

    /// Arama Masallar'da odakla açılır; altında tek editoryal öneri (Original).
    private var findSection: some View {
        HomeSection(title: "Masal bul") {
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                HomeFindField {
                    MPHaptics.tap()
                    app.router.tab = .gunluk
                    app.router.masallarPath = [.search]
                }
                if case .tale(let tale)? = editorialPick {
                    HomePickRow(title: tale.title,
                                meta: "\(tale.origin == .orijinal ? "MagicPaper Original" : tale.byline) · \(tale.minutes) dk",
                                cover: tale.cover, focus: tale.coverFocus) {
                        MPHaptics.tap()
                        app.router.tab = .gunluk
                        app.router.masallarPath = [.tale(tale.id)]
                    }
                }
            }
        }
    }

    /// Önce MagicPaper Original, yoksa haftanın seçkisinden ilk masal.
    private var editorialPick: ClassicItem? {
        let library = ClassicsLibrary.shared
        return (library.items(in: .orijinal) + library.weeklyPicks).first { item in
            if case .tale = item { return true }
            return false
        }
    }

    /// Bu akşamın davetinde adı geçen kitap (kitaplıkta tekrarlanmaz).
    private var tonightTitle: String? {
        switch tonightState {
        case .resume(_, let t, _), .unread(let t, _): return t
        default: return nil
        }
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

    private var classics: ClassicsLibrary { .shared }

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
}

#Preview("11 · Ana sayfa") {
    HomeView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
