import SwiftUI

/// 12 · Odam sekmesi (eski Profil, `BenimKosem`, kodda `corner`; ad: 11 Kasım 2026).
///
/// Çocuğun kendi sayfası: kim okuyor, okuma sayıları, rozetler, kahraman,
/// Masal ailem, Yeni kelimelerim (15). Profil değiştirme sayfanın en üstünde,
/// tek dokunuş (7 Kasım 2026, Batuhan). "Ekle" kapıdan sonra doğrudan profil
/// eklemeye gider; kahramanı düzenlemek kapıdan geçer. Yıldızlar yalnızca
/// kazanılır ve gösterilir (`MPStars`).
///
/// 22 Ekim 2026: iOS profil sayfası düzeni. Ragi ve karşılama balonsuz; Masal
/// dünyam gruplu liste. 7 Kasım 2026: panel ve kutu yok, bölümleri boşluk ayırır.
struct KidCornerView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var stickerNews = MPStickerNews.shared
    @State private var earned: Set<MPMilestone> = []
    @State private var familyNames: [String] = []
    /// Çocuğun kahramanı (Faz 9); kurulmadıysa `nil`.
    @State private var heroLook: HeroLook?
    @State private var heroLooks: [UUID: HeroLook] = [:]
    /// İçerik saat çubuğunun altına girdi mi (`MPStatusBarBackdrop`).
    @State private var scrolled = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var profile: UserProfile? { profileManager.currentProfile }

    var body: some View {
        MPTabScroll(tab: .corner) {
            // Ana sayfanın düzeni (16 Ekim): beyaz zemin, bölümler arası 32. Profil
            // değiştirme en üstte; Ragi seçili çocuğu selamlar.
            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    titleBar
                    whoSection
                }
                greeting
                if let profile {
                    HeroStageCard(look: heroLook) {
                        MPHaptics.tap()
                        app.router.openKidPage(.wardrobe(profile.id))
                    }
                }
                starBank
                // Yapılacak işler (bağlantılar) bakılacak şeylerden (rozetler)
                // önce: bulunabilirlik (16 Ekim denetimi).
                linksSection
                badgesSection
                grownUpsEntry
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, GunlukLayout.bottomClearance)
            .mpTracksScroll($scrolled)
        }
        // Kaydırınca yazı saatin arkasından geçmesin; zemin sayfanın beyazı,
        // tepedeyken görünmez (23 Ekim 2026).
        .overlay(alignment: .top) { MPStatusBarBackdrop(visible: scrolled, fill: MPColor.backgroundSurface) }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear(perform: refresh)
        .onChange(of: profile?.id) { _, _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .mpHeroLookChanged)) { _ in refresh() }
        // Sekme açıkken okuyucu kapanıp yeni rozet kazanılabilir.
        .onChange(of: storyManager.stories) { _, _ in refresh() }
    }

    private func refresh() {
        heroLooks = Dictionary(uniqueKeysWithValues: profileManager.profiles.compactMap { p in
            HeroLookStore().look(for: p.id).map { (p.id, $0) }
        })
        heroLook = profile.flatMap { heroLooks[$0.id] }
        guard let profile else { earned = []; familyNames = []; return }
        earned = Set(MPBadgeStore().ledger(for: profile, stories: storyManager.stories).earnedMilestones)
        familyNames = FamilyCharacterStore().characters(for: profile.id).map(\.name)
    }

    // MARK: - Büyükler için

    /// Ebeveyn odasının tek girişi (karar: 7 Kasım 2026): sayfanın en altında,
    /// sakin ve küçük; çocuğu çağırmaz, arayan ebeveyn bulur. Gizli hareket değil:
    /// ebeveyn bulamazsa destek sorunu olur. Kapıdan geçer.
    private var grownUpsEntry: some View {
        Button { MPHaptics.tap(); app.router.requestParentMode() } label: {
            HStack(spacing: MPSpacing.xs) {
                MPIcon("lock", size: MP.G.sm, weight: .semibold).accessibilityHidden(true)
                Text("Büyükler için").mpText(.footnote)
            }
            .foregroundStyle(MPColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: MP.S.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityLabel("Büyükler için, ebeveyn bölümü")
    }

    // MARK: - Başlık ve Ragi

    private var titleBar: some View {
        MPKidTabHeader(title: "Odam")
            .padding(.top, MPSpacing.lg)
    }

    /// Ekranın tek Ragi'si: el sallar, yanında sakin bir karşılama balonu
    /// (karar 16 Ekim 2026: Ragi her çocuk ekranında ön planda).
    private var greeting: some View {
        // En büyük yazı boyutlarında Ragi küçülüp metnin üstüne çıkar.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.lg))
        return layout {
            RagiGreeting(mascot: .waving, width: typeSize.isAccessibilitySize ? 80 : 96)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text("Merhaba \(profile?.name ?? "Arkadaşım")!")
                    .mpText(.page).foregroundStyle(MPColor.textPrimary)
                Text(greetingText).mpText(.body).foregroundStyle(MPColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    /// Sakin karşılama: kazanılanı söyler, "az kaldı" demez (CLAUDE.md §7).
    private var greetingText: String {
        earned.isEmpty
            ? "Masal okudukça rozetlerin burada toplanır."
            : "\(earned.count) rozetin var, hepsi burada."
    }

    // MARK: - Kim okuyor?

    private var whoSection: some View {
        HomeSection(title: "Kim okuyor?") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: MPSpacing.xl) {
                    ForEach(profileManager.profiles) { child in
                        let selected = child.id == profile?.id
                        Button {
                            guard !selected else { return }
                            MPHaptics.selection()
                            profileManager.switchProfile(to: child)
                        } label: {
                            VStack(spacing: MPSpacing.xs) {
                                Group {
                                    if let hero = heroLooks[child.id] {
                                        HeroAvatarView(look: hero, backdrop: MPWorldTone.lav.soft)
                                            .frame(width: MPSize.minTouchKid, height: MPSize.minTouchKid)
                                    } else {
                                        MPAvatar(name: child.name, color: child.mpColor, size: MPSize.minTouchKid)
                                    }
                                }
                                    .padding(MPSpacing.xxs)
                                    .overlay(Circle().strokeBorder(selected ? MPColor.actionPrimary : .clear, lineWidth: 3))
                                Text(child.name).mpText(.supporting).fontWeight(.black)
                                    .foregroundStyle(MPColor.textPrimary).lineLimit(1)
                            }
                            .frame(minWidth: MPSize.minTouchKid)
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityLabel(child.name)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    Button { app.router.requestProfileAdd() } label: {
                        VStack(spacing: MPSpacing.xs) {
                            MPIcon("plus", size: MP.G.xl, weight: .semibold)
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(width: MPSize.minTouchKid + MPSpacing.sm, height: MPSize.minTouchKid + MPSpacing.sm)
                                .overlay(Circle().strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                            Text("Ekle").mpText(.supporting).fontWeight(.black).foregroundStyle(MPColor.textSecondary)
                        }
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel("Profil ekle")
                    .accessibilityHint("Önce bir büyüğün kapıyı açması gerekir")
                }
                .padding(.horizontal, MPSpacing.screenH)
            }
            .padding(.horizontal, -MPSpacing.screenH)
        }
    }

    // MARK: - Sayılar

    /// Kumbaradaki yıldız: kazanılan eksi süslere harcanan (Faz 9).
    private var stars: Int {
        guard let profile else { return 0 }
        let earned = MPStars.count(for: profile, stories: storyManager.stories)
        return MPStarWalletStore().wallet(for: profile.id).balance(earned: earned)
    }

    /// Yıldız kumbarası (Faz 7): tek satır, sayı ve nasıl kazanıldığı. Üst üste
    /// gün buradan kalktı, Ana sayfanın satırında; masal sayısı Kitaplık'ta.
    /// Harcama Faz 9'da (Dolap); o zamana kadar satır dokunulmaz.
    private var starBank: some View {
        HStack(spacing: MPSpacing.md) {
            MPStarMark(size: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MP.S.x1) {
                Text("\(stars) yıldız").mpText(.section).monospacedDigit()
                    .foregroundStyle(MPColor.textPrimary)
                Text("Her sabah 1, her masal 1.").mpText(.supporting)
                    .foregroundStyle(MPColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(minHeight: MPSize.minTouchHero)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rozetlerim

    /// Bütün rozetler, kazanılmamışlar kilitli (karar 13 Ekim 2026). İlerleme
    /// çubuğu ya da "az kaldı" metni yok (CLAUDE.md ilke 7).
    private var badgesSection: some View {
        HomeSection(title: "Rozetlerim",
                    note: "\(earned.count) / \(MPMilestone.allCases.count)",
                    noteSpoken: "\(MPMilestone.allCases.count) rozetten \(earned.count) tanesi kazanıldı") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
                                     count: typeSize.isAccessibilitySize ? 1 : 3),
                      spacing: MPSpacing.md) {
                ForEach(MPMilestone.gridOrder(earned: earned)) { badge in
                    MPBadgeCard(systemImage: badge.icon, title: badge.title, tone: badge.tone,
                                isUnlocked: earned.contains(badge))
                }
            }
        }
    }

    // MARK: - Bağlantılar

    @ViewBuilder
    private var linksSection: some View {
        if let profile {
            HomeSection(title: "Masal dünyam") {
                // Satırlar tek panelde; panel tek parça olsun diye tek kap.
                VStack(spacing: 0) {
                    // Faz 10: masal dünyası hatırlar.
                    linkRow(icon: "map", tone: .mint, title: "Masal haritam",
                            subtitle: "Masallarda gittiğin yerler") {
                        app.router.openKidPage(.storyMap(profile.id))
                    }
                    MPRowDivider(area: .kid)
                    // Faz 9: Odam'ın koleksiyonu.
                    linkRow(icon: "star", tone: .yellow, title: "Çıkartma albümüm",
                            subtitle: stickerNews.isFresh(profile.id) ? "Yeni çıkartma" : stickerSubtitle,
                            fresh: stickerNews.isFresh(profile.id)) {
                        app.router.openKidPage(.stickers(profile.id))
                    }
                    MPRowDivider(area: .kid)
                    if settings.collectionEnabled {
                        linkRow(icon: "sparkles", tone: .lav, title: "Süsler",
                                subtitle: "Yıldızlarınla kitaplığını süsle") {
                            app.router.openKidPage(.decor(profile.id))
                        }
                        MPRowDivider(area: .kid)
                    }
                    linkRow(icon: "heart", tone: .peach, title: "Masal ailem",
                            subtitle: familySubtitle) {
                        app.router.openKidPage(.familyCharacters(profile.id))
                    }
                    MPRowDivider(area: .kid)
                    linkRow(icon: "book.closed", tone: .mint, title: "Yeni kelimelerim",
                            subtitle: wordsSubtitle) {
                        app.router.openKidPage(.newWords(profile.id))
                    }
                }
                // Satırın kendi boşluğu sayfa kenarıyla hizalansın: panel yok.
                .padding(.horizontal, -MPSpacing.md)
            }
        }
    }

    /// Ebeveyn modunda doğrudan, çocuk modunda kapı açılınca çalışır.
    private func guarded(_ action: @escaping () -> Void) {
        app.router.requestGate(then: action)
    }

    private var stickerSubtitle: String {
        let count = MPStickerAlbum.stickers(for: profile, stories: storyManager.stories).count
        return count == 0 ? "Her masal bir çıkartma bırakır" : "\(count) çıkartma"
    }

    private var wordsSubtitle: String {
        guard let profile else { return "" }
        let count = MPVocabulary.collectedWords(in: storyManager.stories.filter { $0.belongs(to: profile) }).count
        return count == 0 ? "Masallarda geçen kelimeler" : "\(count) kelime topladın"
    }

    private var familySubtitle: String {
        switch familyNames.count {
        case 0:  return "Masallarına kimler katılsın?"
        case 1...3: return familyNames.joined(separator: ", ")
        default: return familyNames.prefix(3).joined(separator: ", ") + " ve diğerleri"
        }
    }

    private func linkRow(icon: String, tone: MPWorldTone, title: String, subtitle: String,
                         fresh: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPListRow(systemImage: icon, tone: tone, title: title, subtitle: subtitle)
                // Taze çıkartma: renk tek başına bilgi taşımaz, alt yazı da "Yeni çıkartma" der.
                .overlay(alignment: .topLeading) {
                    if fresh {
                        Circle().fill(MP.C.brand)
                            .frame(width: MP.S.x2, height: MP.S.x2)
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: MPSize.minTouchKid)
        }
        .buttonStyle(MPPressStyle(.highlight))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
