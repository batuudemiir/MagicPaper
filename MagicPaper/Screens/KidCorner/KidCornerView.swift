import SwiftUI

/// 12 · Odam sekmesi (eski Profil, `BenimKosem`, kodda `corner`; ad: 11 Kasım 2026).
///
/// Çocuğun kendi sayfası: kim okuyor, okuma sayıları, rozetler, kahraman,
/// Masal ailem, Yeni kelimelerim (15). Profil değiştirme sayfanın en üstünde,
/// tek dokunuş (7 Kasım 2026, Batuhan). "Ekle" kapıdan sonra doğrudan profil
/// eklemeye gider; kahramanı düzenlemek kapıdan geçer. Yıldızlar yalnızca
/// kazanılır ve gösterilir (`MPStars`).
///
/// 13 Kasım 2026 (Batuhan): yeni kurgu. Çocuğun kimliği tek yerde: "Kim
/// okuyor?" başlığın altında tek sıra çip, altında tek kimlik kartı (kahraman,
/// ad, yıldız, Dolap). Ragi küçük, balonla. "Masal dünyam" satır yerine karo:
/// koleksiyonlar ilk ekranda görünsün. 22 Ekim'in gruplu listesi kalktı.
struct KidCornerView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var settings = MPSettingsStore.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var stickerNews = MPStickerNews.shared
    @State private var earned: Set<MPMilestone> = []
    @State private var familyNames: [String] = []
    /// Albümün son çıkartmaları (en yenisi başta); karoda üçü görünür.
    @State private var stickers: [MPSticker] = []
    /// Çocuğun kahramanı (Faz 9); kurulmadıysa `nil`.
    @State private var heroLook: HeroLook?
    @State private var heroLooks: [UUID: HeroLook] = [:]
    /// İçerik saat çubuğunun altına girdi mi (`MPStatusBarBackdrop`).
    @State private var scrolled = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var profile: UserProfile? { profileManager.currentProfile }

    var body: some View {
        MPTabScroll(tab: .corner) {
            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                // Kimlik tek blok: kim okuyor, kahramanı, Ragi'nin sözü.
                VStack(alignment: .leading, spacing: MPSpacing.lg) {
                    titleBar
                    whoRow
                    if let profile { identityCard(profile) }
                    greeting
                }
                // Yapılacak işler (karolar) bakılacak şeylerden (rozetler)
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
        guard let profile else { earned = []; familyNames = []; stickers = []; return }
        stickers = MPStickerAlbum.stickers(for: profile, stories: storyManager.stories)
            .sorted { $0.date > $1.date }
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
        MPKidTabHeader(title: "Profil")
            .padding(.top, MPSpacing.lg)
    }

    /// Ekranın tek Ragi'si: küçük, balonla rozetleri söyler (karar 16 Ekim
    /// 2026: Ragi her çocuk ekranında).
    private var greeting: some View {
        MascotSays(mascot: .waving, text: greetingText)
    }

    /// Sakin karşılama: kazanılanı söyler, "az kaldı" demez (CLAUDE.md §7).
    private var greetingText: String {
        earned.isEmpty
            ? "Masal okudukça rozetlerin burada toplanır."
            : "\(earned.count) rozetin var, hepsi burada."
    }

    // MARK: - Kim okuyor?

    /// Profil değiştirme: başlığın hemen altında tek sıra çip, tek dokunuş
    /// (7 Kasım 2026). Seçili çocuk çerçeveli ve onay işaretli; renk tek
    /// başına bilgi taşımaz.
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
                            Group {
                                if let hero = heroLooks[child.id] {
                                    HeroAvatarView(look: hero, backdrop: MPWorldTone.lav.soft)
                                        .frame(width: MPSize.circleButton, height: MPSize.circleButton)
                                } else {
                                    MPAvatar(name: child.name, color: child.mpColor, size: MPSize.circleButton)
                                }
                            }
                            .accessibilityHidden(true)
                            Text(child.name).mpText(.supporting).fontWeight(.bold).lineLimit(1)
                            if selected {
                                MPIcon("checkmark", size: MP.G.sm, weight: .bold).accessibilityHidden(true)
                            }
                        }
                        .foregroundStyle(selected ? MPColor.actionPrimary : MPColor.textPrimary)
                        .padding(.leading, MPSpacing.xxs)
                        .padding(.trailing, MPSpacing.md)
                        .frame(minHeight: MP.S.tapMin)
                        .background(selected ? MPColor.cardSoft : MPWorldTone.gray.soft, in: Capsule())
                        .overlay(Capsule().strokeBorder(selected ? MPColor.actionPrimary : .clear, lineWidth: 2))
                    }
                    .buttonStyle(MPPressStyle())
                    .accessibilityLabel(child.name)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                Button { app.router.requestProfileAdd() } label: {
                    HStack(spacing: MPSpacing.xs) {
                        MPIcon("plus", size: MP.G.sm, weight: .bold).accessibilityHidden(true)
                        Text("Ekle").mpText(.supporting).fontWeight(.bold)
                    }
                    .foregroundStyle(MPColor.textSecondary)
                    .padding(.horizontal, MPSpacing.md)
                    .frame(minHeight: MP.S.tapMin)
                    .overlay(Capsule().strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
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

    // MARK: - Kimlik kartı

    /// Kumbaradaki yıldız: kazanılan eksi süslere harcanan (Faz 9).
    private var stars: Int {
        guard let profile else { return 0 }
        let earned = MPStars.count(for: profile, stories: storyManager.stories)
        return MPStarWalletStore().wallet(for: profile.id).balance(earned: earned)
    }

    /// Çocuğun tek kimlik kartı: kahraman, ad, yıldız ve Dolap. Kartın tamamı
    /// Dolap'ı açar; "Dolabı aç" ikincil düğme görünümünde ama ayrı hedef değil
    /// (kart içinde düğme olmaz). En büyük yazı boyutlarında kahraman üste çıkar.
    private func identityCard(_ profile: UserProfile) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.md))
            : AnyLayout(HStackLayout(alignment: .center, spacing: MPSpacing.lg))
        return Button {
            MPHaptics.tap()
            app.router.openKidPage(.wardrobe(profile.id))
        } label: {
            layout {
                HeroAvatarView(look: heroLook ?? .standard, backdrop: MPWorldTone.lav.soft)
                    .frame(width: 104, height: 104)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text(profile.name).mpText(.page).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(2).minimumScaleFactor(0.7)
                    HStack(spacing: MPSpacing.xs) {
                        MPStarMark(size: 16)
                        Text("\(stars) yıldız").mpText(.supporting).fontWeight(.bold).monospacedDigit()
                            .foregroundStyle(MPColor.textSecondary)
                    }
                    HStack(spacing: MPSpacing.xs) {
                        MPIcon("sparkles", size: MP.G.sm, weight: .bold)
                        Text(heroLook == nil ? "Kahramanını giydir" : "Dolabı aç").mpText(.button)
                    }
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(maxWidth: .infinity, minHeight: MPSize.chipHeightKid)
                    .background(MPColor.cardSoft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                    .padding(.top, MPSpacing.xs)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.name), \(stars) yıldız")
        .accessibilityHint("Dolabı açar")
        .accessibilityAddTraits(.isButton)
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

    // MARK: - Masal dünyam

    /// Koleksiyonlar karolarda (13 Kasım 2026): üstte geniş çıkartma albümü,
    /// altında ikişerli diğerleri. En büyük yazı boyutlarında tek sütun.
    @ViewBuilder
    private var linksSection: some View {
        if let profile {
            HomeSection(title: "Masal dünyam") {
                VStack(spacing: MPSpacing.sm) {
                    stickerTile(profile)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm, alignment: .top),
                                             count: typeSize.isAccessibilitySize ? 1 : 2),
                              spacing: MPSpacing.sm) {
                        // Faz 10: masal dünyası hatırlar.
                        worldTile(icon: "map", tone: .mint, title: "Masal haritam",
                                  subtitle: "Masallarda gittiğin yerler") {
                            app.router.openKidPage(.storyMap(profile.id))
                        }
                        worldTile(icon: "heart", tone: .peach, title: "Masal ailem", subtitle: familySubtitle) {
                            app.router.openKidPage(.familyCharacters(profile.id))
                        }
                        worldTile(icon: "book.closed", tone: .sky, title: "Yeni kelimelerim", subtitle: wordsSubtitle) {
                            app.router.openKidPage(.newWords(profile.id))
                        }
                        if settings.collectionEnabled {
                            worldTile(icon: "sparkles", tone: .lav, title: "Süsler",
                                      subtitle: "Yıldızlarınla kitaplığını süsle") {
                                app.router.openKidPage(.decor(profile.id))
                            }
                        }
                    }
                }
            }
        }
    }

    /// Faz 9: albüm. Son üç çıkartma karonun sağında; taze çıkartmayı alt yazı
    /// da söyler (renk tek başına bilgi taşımaz).
    private func stickerTile(_ profile: UserProfile) -> some View {
        let fresh = stickerNews.isFresh(profile.id)
        return Button {
            MPHaptics.tap()
            app.router.openKidPage(.stickers(profile.id))
        } label: {
            HStack(spacing: MPSpacing.md) {
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Çıkartma albümüm").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Text(fresh ? "Yeni çıkartma" : stickerSubtitle).mpText(.footnote)
                        .fontWeight(fresh ? .bold : .regular)
                        .foregroundStyle(fresh ? MPColor.actionPrimary : MPColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize {
                    HStack(spacing: -MPSpacing.sm) {
                        ForEach(stickers.prefix(3)) { StickerView(sticker: $0, size: MPSize.circleButton) }
                    }
                }
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: MPSize.choiceRowKid, alignment: .leading)
            .background(MPWorldTone.yellow.soft, in: RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Çıkartma albümüm, \(fresh ? "yeni çıkartma" : stickerSubtitle)")
        .accessibilityAddTraits(.isButton)
    }

    private func worldTile(icon: String, tone: MPWorldTone, title: String, subtitle: String,
                           action: @escaping () -> Void) -> some View {
        Button { MPHaptics.tap(); action() } label: {
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                MPIcon(icon, size: MP.G.lg, weight: .semibold).foregroundStyle(tone.deep)
                    .padding(.bottom, MPSpacing.xs)
                    .accessibilityHidden(true)
                Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                // İki satır ayrılır: yan yana karolar aynı boyda dursun.
                Text(subtitle).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .lineLimit(2, reservesSpace: true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(tone.soft, in: RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous))
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// Ebeveyn modunda doğrudan, çocuk modunda kapı açılınca çalışır.
    private func guarded(_ action: @escaping () -> Void) {
        app.router.requestGate(then: action)
    }

    private var stickerSubtitle: String {
        let count = stickers.count
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
