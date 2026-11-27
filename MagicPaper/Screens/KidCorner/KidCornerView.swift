import SwiftUI

/// 12 · Profil sekmesi (eski adları Odam ve Benim köşem, kodda `corner`).
///
/// 23 Kasım 2026 (İrem): ana sayfa ve menü sayfalarıyla aynı dil.
/// - Üstte ana sayfanın mor göğü saat çubuğunun altına uzanır: "Profil",
///   "Kim okuyor?" çipleri (tek dokunuş, 7 Kasım 2026), beyaz kimlik kartı
///   (avatar, ad, yıldız katı; kartın tamamı "Profilini düzenle"yi açar).
///   Ekranın tek Ragi'si Okuma yolculuğum kartında (24 Kasım 2026).
/// - Göğün altında ana sayfadaki üç bilgi kartı: yıldız, masal, rozet.
/// - "Büyükler için" ilk ekranda, menü satırı dilinde (14 Kasım 2026 kararı:
///   ebeveynin tek girişi; basılı tutmayla açılır).
/// - Rozetlerim açık vitrin (Duolingo'nun başarılar sayfası gibi): iki sıra
///   büyük arma, ad ve durum; "Tümü" Rozetlerim'e gider. Sayı baskısı,
///   ilerleme çubuğu ya da "az kaldı" yok (ilke 7).
/// - Masal dünyam: menüdeki satırların aynısı (Okuma yolculuğum, çıkartma
///   albümü, harita, Masal ailem, kelimeler, kitaplık renkleri).
struct KidCornerView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var stickerNews = MPStickerNews.shared
    @State private var earned: Set<String> = []
    /// Rozet → kazanıldığı an; Profil'de son kazanılanlar önce.
    @State private var earnedDates: [String: Date] = [:]
    @State private var familyNames: [String] = []
    @State private var stickers: [MPSticker] = []
    /// Çocuğun kahramanı (Faz 9); kurulmadıysa `nil`.
    @State private var heroLook: HeroLook?
    @State private var heroLooks: [UUID: HeroLook] = [:]
    /// Okuma yolculuğum kartının verisi (24 Kasım 2026).
    @State private var journey: ReadingJourney?
    @ObservedObject private var streak = MPStreak.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    private var profile: UserProfile? { profileManager.currentProfile }


    var body: some View {
        // Gök saat çubuğunun altına uzanır (ana sayfa ile aynı kurgu).
        GeometryReader { geo in
            MPTabScroll(tab: .corner) {
                VStack(alignment: .leading, spacing: 0) {
                    header(topInset: geo.safeAreaInsets.top)
                    VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                        // Okuma yolculuğum'un önizlemesi, Büyükler için'in üstünde (24 Kasım 2026, İrem).
                        if let journey, let profile {
                            ReadingJourneyWidget(journey: journey) {
                                app.router.openKidPage(.journey(profile.id))
                            }
                        }
                        grownUpsEntry
                        badgesSection
                        worldSection
                    }
                    .padding(.horizontal, MPSpacing.screenH)
                    .padding(.top, MPSpacing.xl)
                }
                .padding(.bottom, GunlukLayout.bottomClearance)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear {
            refresh()
            // Profil açıldı: yeni rozetler burada görünüyor, sekmedeki nokta kalkar.
            MPBadgeNews.shared.clearDot(profile?.id)
        }
        .onChange(of: profile?.id) { _, _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .mpHeroLookChanged)) { _ in refresh() }
        // Sekme açıkken okuyucu kapanıp yeni rozet kazanılabilir.
        .onChange(of: storyManager.stories) { _, _ in refresh() }
        .onChange(of: streak.readDays) { _, _ in refresh() }
    }

    private func refresh() {
        heroLooks = Dictionary(uniqueKeysWithValues: profileManager.profiles.compactMap { p in
            HeroLookStore().look(for: p.id).map { (p.id, $0) }
        })
        heroLook = profile.flatMap { heroLooks[$0.id] }
        journey = profile.map { ReadingJourney.live(for: $0) }
        guard let profile else { earned = []; earnedDates = [:]; familyNames = []; stickers = []; return }
        stickers = MPStickerAlbum.stickers(for: profile, stories: storyManager.stories)
            .sorted { $0.date > $1.date }
        let ledger = MPBadgeStore().ledger(for: profile, stories: storyManager.stories)
        earned = ledger.earnedIDs
        earnedDates = ledger.earned
        familyNames = FamilyCharacterStore().characters(for: profile.id).map(\.name)
    }

    // MARK: - Gök: başlık, kim okuyor, kimlik, bilgi kartları

    private func header(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("Profil").font(MP.F.displayLG()).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            whoRow
            if let profile { identityBlock(profile) }
            stats
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, topInset + MPSpacing.lg)
        .padding(.bottom, MPSpacing.xs)
        // Düz kâğıt (26 Kasım 2026, Batuhan): mor gök gradienti kalktı.
    }

    /// Profil değiştirme: tek sıra çip, tek dokunuş (7 Kasım 2026). Seçili
    /// çocuk beyaz, çerçeveli ve onay işaretli; renk tek başına bilgi taşımaz.
    private var whoRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MPSpacing.sm) {
                ForEach(profileManager.profiles) { child in
                    let selected = child.id == profile?.id
                    Button {
                        guard !selected else { return }
                        MPHaptics.selection()
                        profileManager.switchProfile(to: child)
                    } label: {
                        HStack(spacing: MPSpacing.xs) {
                            ProfilePhoto(avatarID: heroLooks[child.id]?.avatar, size: MPSize.circleButton)
                            Text(child.name).mpText(.supporting).fontWeight(.bold).lineLimit(1)
                            if selected {
                                MPIcon("checkmark", size: MP.G.sm, weight: .bold).accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(selected ? MPColor.actionPrimary : MPColor.textPrimary)
                        .padding(.leading, MPSpacing.xxs)
                        .padding(.trailing, MPSpacing.md)
                        .frame(minHeight: MP.S.tapMin)
                        .background(selected ? MPColor.backgroundSurface : MPWorldTone.lav.soft, in: Capsule())
                        .overlay(Capsule().strokeBorder(selected ? MPColor.actionPrimary : .clear, lineWidth: 2))
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel(child.name)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                // İkinci çocuk abonelikle (20 Kasım 2026); kilitliyse sakin pencere.
                Button {
                    app.unlock(.multipleChildren, usage: .adding(existing: profileManager.profiles.count)) {
                        app.router.requestProfileAdd()
                    }
                } label: {
                    HStack(spacing: MPSpacing.xs) {
                        MPIcon("plus", size: MP.G.sm, weight: .bold).accessibilityHidden(true)
                        Text("Ekle").mpText(.supporting).fontWeight(.bold)
                    }
                    .foregroundStyle(MPColor.actionPrimary)
                    .padding(.horizontal, MPSpacing.md)
                    .frame(minHeight: MP.S.tapMin)
                    .overlay(Capsule().strokeBorder(MPColor.actionPrimary, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                    .contentShape(Capsule())
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel("Profil ekle")
                .accessibilityHint("Önce bir büyüğün kapıyı açması gerekir")
            }
            .padding(.horizontal, MPSpacing.screenH)
        }
        .padding(.horizontal, -MPSpacing.screenH)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kim okuyor?")
    }

    /// Yıldız puanı: ömür boyu kazanılan, harcamayla düşmez (rozet planı 5b).
    private var stars: Int {
        guard let profile else { return 0 }
        return MPStars.score(for: profile, stories: storyManager.stories)
    }

    private var starLevel: MPStarLevel? { MPStarLevel.current(score: stars) }

    /// Seçilen profil resmi; yoksa kart boş yeri ve "Profil resmini seç"i gösterir.
    private var avatarID: String? { heroLook?.avatar }
    private var hasPhoto: Bool { ProfileAvatar.named(avatarID) != nil }

    private var storyCount: Int {
        guard let profile else { return 0 }
        return storyManager.stories.filter { $0.belongs(to: profile) }.count
    }

    /// Kimlik kartı. Ekranın tek Ragi'si Okuma yolculuğum kartında
    /// (24 Kasım 2026, İrem; önceden kartın arkasından el sallıyordu).
    private func identityBlock(_ profile: UserProfile) -> some View {
        identityCard(profile)
    }

    /// Çocuğun tek kimlik kartı. Kartın tamamı "Profilini düzenle"
    /// penceresini açar; alttaki yazılı ipucu ve avatarın kalemi bunu söyler.
    private func identityCard(_ profile: UserProfile) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
            : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.lg))
        return Button {
            MPHaptics.tap()
            app.avatarPickerProfileID = profile.id
        } label: {
            layout {
                // Profil resmi: seçilmediyse boş yer ve "+" (24 Kasım 2026, İrem).
                ProfilePhoto(avatarID: avatarID, size: 96)
                    .overlay(alignment: .bottomTrailing) {
                        if let starLevel { MPStarLevelArt(level: starLevel, size: 36) }
                    }
                    .overlay(alignment: .topTrailing) {
                        MPIcon(hasPhoto ? "pencil" : "plus", size: MP.G.xs, weight: .bold)
                            .foregroundStyle(MPColor.textOnAction)
                            .frame(width: MP.G.lg, height: MP.G.lg)
                            .background(MPColor.actionPrimary, in: Circle())
                            .overlay(Circle().strokeBorder(MPColor.backgroundSurface, lineWidth: 2))
                    }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(profile.name).mpText(.page).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    Text(starLevel.map { "\($0.title) katı" } ?? "İlk yıldız katı yolda")
                        .mpText(.supporting).fontWeight(.bold).foregroundStyle(MPColor.textSecondary)
                    HStack(spacing: MPSpacing.xxs) {
                        MPIcon(hasPhoto ? "pencil" : "plus", size: MP.G.xs, weight: .bold).accessibilityHidden(true)
                        Text(hasPhoto ? "Profilini düzenle" : "Profil resmini seç").mpText(.footnote).fontWeight(.bold)
                    }
                    .foregroundStyle(MPColor.actionPrimary)
                    .padding(.top, MPSpacing.xxs)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(MPSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.name), \(starLevel.map { "\($0.title) katı" } ?? "ilk yıldız katı yolda")")
        .accessibilityHint("Profil resmini seçmeyi açar")
        .accessibilityAddTraits(.isButton)
    }

    /// Ana sayfadaki bilgi kartlarının aynısı; yalnızca toplananı söyler.
    private var stats: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
        return layout {
            HomeStatCard(systemImage: "star.fill", tone: .yellow, label: "Yıldız", value: "\(stars)", unit: "yıldız")
            HomeStatCard(systemImage: "book.fill", tone: .lav, label: "Masallarım", value: "\(storyCount)", unit: "masal")
            HomeStatCard(systemImage: "rosette", tone: .peach, label: "Rozetler", value: "\(earned.count)", unit: "rozet")
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Büyükler için

    /// Ebeveyn odasının tek girişi (14 Kasım 2026): ilk ekranda, tam satır.
    /// Giriş basılı tutmayla açılır (`ParentalGateView.Kind.hold`).
    private var grownUpsEntry: some View {
        // Lucide kalkan (24 Kasım 2026): "lock.shield" eşlemesizdi, karo boş çiziliyordu.
        HomeListRow(systemImage: "shield", tone: .sky, title: "Büyükler için",
                    subtitle: "Ayarlar, abonelik ve okuma özeti",
                    hint: "Bir büyüğün basılı tutmasıyla açılır") {
            MPHaptics.tap()
            app.router.requestParentMode()
        }
    }

    // MARK: - Rozetlerim (açık vitrin)

    /// Son kazanılan altı arma; altıdan azsa her aileden sıradaki kilitli
    /// rozet. Hepsi "Tümü" ile Rozetlerim'de (rozet planı R3).
    private var shownBadges: [MPBadge] {
        let recent = earnedDates.sorted { ($0.value, $1.key) > ($1.value, $0.key) }
            .compactMap { MPBadgeCatalog.badge($0.key) }
        let locked = MPBadgeFamily.allCases.filter { $0 != .secret }.compactMap { family in
            MPBadgeCatalog.badges(in: family).first { earnedDates[$0.id] == nil }
        }
        return Array((recent + locked).prefix(6))
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            MPSectionHeader(title: "Rozetlerim",
                            link: profile.map { p -> (title: String, action: () -> Void) in
                                (title: "Tümü", action: { app.router.openKidPage(.badges(p.id)) })
                            })
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md, alignment: .top),
                                     count: typeSize.isAccessibilitySize ? 2 : 3),
                      spacing: MPSpacing.xl) {
                ForEach(shownBadges) { badgeCell($0) }
            }
        }
    }

    /// Açık rozet: kartsız, büyük arma, ad ve durum. Kilitli arma gri ve
    /// kilitli; durum yazısı da söyler (renk tek başına bilgi taşımaz).
    private func badgeCell(_ badge: MPBadge) -> some View {
        let unlocked = earned.contains(badge.id)
        let state = unlocked ? (badge.family.isTiered ? "\(badge.tier). kat" : "Kazanıldı") : "Kilitli"
        return Button {
            MPHaptics.tap()
            if let profile { app.router.openKidPage(.badges(profile.id)) }
        } label: {
            VStack(spacing: MPSpacing.xs) {
                MPBadgeArt(badge: badge, unlocked: unlocked, size: 80)
                    .padding(MPSpacing.xs)
                    .background(unlocked ? badge.tone.soft : MPColor.lockedFill, in: Circle())
                    .overlay(alignment: .bottomTrailing) {
                        if !unlocked {
                            MPIcon("lock.fill", size: MP.G.xs, weight: .bold)
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(width: MP.G.lg, height: MP.G.lg)
                                .background(MPColor.backgroundSurface, in: Circle())
                                .accessibilityHidden(true)
                        }
                    }
                Text(badge.displayTitle(unlocked: unlocked))
                    .mpText(.supporting).fontWeight(.bold).multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .foregroundStyle(unlocked ? MPColor.textPrimary : MPColor.textSecondary)
                Text(state).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.displayTitle(unlocked: unlocked))
        .accessibilityValue(MPBadgeTile.spokenState(badge, unlocked: unlocked))
        .accessibilityHint("Rozetlerim sayfasını açar")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Masal dünyam

    /// Menüdeki satırların aynısı: aynı simge, ton ve sıra (`KidMenuSheet`).
    @ViewBuilder
    private var worldSection: some View {
        if let profile {
            let freshSticker = stickerNews.isFresh(profile.id)
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                // Okuma yolculuğum yukarıda kendi kartında (24 Kasım 2026).
                MPSectionHeader(title: "Masal dünyam")
                HomeListRow(systemImage: "seal", tone: .pink, title: "Çıkartma albümüm",
                            subtitle: freshSticker ? "Yeni çıkartma geldi" : stickerSubtitle,
                            emphasized: freshSticker) {
                    open(.stickers(profile.id))
                }
                HomeListRow(systemImage: "textformat", tone: .mint, title: "Yeni kelimelerim", subtitle: wordsSubtitle) {
                    open(.newWords(profile.id))
                }
                HomeListRow(systemImage: "map", tone: .sky, title: "Masal haritam", subtitle: "Gezdiğin masal dünyaları") {
                    open(.storyMap(profile.id))
                }
                HomeListRow(systemImage: "person.2", tone: .peach, title: "Masal ailem", subtitle: familySubtitle) {
                    open(.familyCharacters(profile.id))
                }
                if settings.collectionEnabled {
                    HomeListRow(systemImage: "paintpalette", tone: .green, title: "Kitaplık renklerim",
                                subtitle: "Yıldızlarınla süsle") {
                        open(.decor(profile.id))
                    }
                }
            }
        }
    }

    private func open(_ route: MPKidRoute) {
        MPHaptics.tap()
        app.router.openKidPage(route)
    }

    private var stickerSubtitle: String {
        let count = stickers.count
        return count == 0 ? "Her masal bir çıkartma bırakır" : "\(count) çıkartma"
    }

    private var wordsSubtitle: String {
        guard let profile else { return "" }
        let count = MPVocabulary.collectedWords(in: storyManager.stories.filter { $0.belongs(to: profile) }).count
        return count == 0 ? "Masallarda öğrendiklerin" : "\(count) kelime topladın"
    }

    private var familySubtitle: String {
        switch familyNames.count {
        case 0:  return "Masallarına kimler katılsın?"
        case 1...3: return familyNames.joined(separator: ", ")
        default: return familyNames.prefix(3).joined(separator: ", ") + " ve diğerleri"
        }
    }
}

/// Ekranın Ragi'si: açılışta süzülerek gelir, yavaşça nefes alır, dokununca
/// bir kez zıplar (ana sayfadaki `HomeSceneMascot` ile aynı hareket dili).
/// Reduce Motion açıkken yerinde durur. Süs: erişilebilirlikten gizli.
struct RagiGreeting: View {
    let mascot: Mascot
    var width: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var hop = false

    var body: some View {
        MascotImage(mascot: mascot, width: width)
            .offset(y: hop ? -12 : 0)
            .offset(y: appeared ? 0 : MP.S.x5)
            .opacity(appeared ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !reduceMotion, !hop else { return }
                MPHaptics.tap()
                MPSound.play(.ragi)
                withAnimation(MP.M.spring) { hop = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(MP.M.spring) { hop = false }
                }
            }
            .onAppear {
                if reduceMotion { appeared = true; return }
                withAnimation(MP.M.spring.delay(0.1)) { appeared = true }
            }
            .accessibilityHidden(true)
    }
}

#Preview("12 · Benim köşem") {
    KidCornerView().environmentObject(MPAppState())
}
