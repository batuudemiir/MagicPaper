import SwiftUI

/// 12 · Benim köşem (`BenimKosem`). FAZ 20'den beri alt barın "Köşem" sekmesi.
///
/// Çocuğun kendi sayfası: kim okuyor, okuma sayıları, rozetler, kahraman,
/// Masal ailem, Yeni kelimelerim (15). 13 Ekim 2026'dan beri alt bardaki
/// "Köşem" sekmesi; kapat düğmesi yok, kilit ebeveyn kapısına, "Ekle" kapıdan
/// sonra doğrudan profil eklemeye gider; kahramanı düzenlemek kapıdan geçer.
/// Yıldızlar yalnızca kazanılır ve gösterilir (`MPStars`).
///
/// 22 Ekim 2026: iOS profil sayfası düzeni. Beyaz sayfada açık gri, gölgesiz
/// ve kenarsız bloklar (ana sayfa ve masal yazma adımlarıyla aynı); Ragi ve
/// karşılama balonsuz; sayılar üç ayrı kutucuk; Masal dünyam gruplu liste.
struct KidCornerView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var earned: Set<MPMilestone> = []
    @State private var familyNames: [String] = []
    @State private var gate = false
    @State private var afterGate: (() -> Void)?
    @Environment(\.dynamicTypeSize) private var typeSize

    private var profile: UserProfile? { profileManager.currentProfile }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // Ana sayfanın düzeni (16 Ekim): beyaz zemin, başlık içeriğine
            // yapışık (12), bölümler arası 32; ekranın tek Ragi'si üstte.
            VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                VStack(alignment: .leading, spacing: MPSpacing.xl) {
                    titleBar
                    greeting
                }
                whoSection
                statsRow
                // Yapılacak işler (bağlantılar) bakılacak şeylerden (rozetler)
                // önce: bulunabilirlik (16 Ekim denetimi).
                linksSection
                badgesSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .onAppear(perform: refresh)
        // Kahramanı düzenlemek ebeveyn kapısından geçer (Masal ailem'deki
        // düzenleme gibi); görmek ve seçmek serbest.
        .fullScreenCover(isPresented: $gate, onDismiss: {
            let action = afterGate
            afterGate = nil
            action?()
        }) {
            ParentalGateView(onSuccess: { gate = false }, onCancel: { afterGate = nil; gate = false })
        }
        .onChange(of: profile?.id) { _, _ in refresh() }
        // Sekme açıkken okuyucu kapanıp yeni rozet kazanılabilir.
        .onChange(of: storyManager.stories) { _, _ in refresh() }
    }

    private func refresh() {
        guard let profile else { earned = []; familyNames = []; return }
        earned = Set(MPBadgeStore().ledger(for: profile, stories: storyManager.stories).earnedMilestones)
        familyNames = FamilyCharacterStore().characters(for: profile.id).map(\.name)
    }

    // MARK: - Başlık ve Ragi

    /// Sekmenin büyük başlığı solda, kilit (ebeveyn kapısı) sağda: Günlük
    /// sekmesinin başlığıyla aynı düzen.
    private var titleBar: some View {
        HStack(alignment: .center, spacing: MPSpacing.sm) {
            Text("Benim köşem").mpText(.pageTitle).foregroundStyle(MPColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            MPCircleButton(systemImage: "lock", accessibilityLabel: "Ebeveyn bölümü") {
                app.requestParentMode()
            }
        }
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
                    .mpText(.title2).foregroundStyle(MPColor.textPrimary)
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
        HomeSection(title: "Kim okuyor?", contained: false) {
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
                                MPAvatar(name: child.name, color: child.mpColor, size: MPSize.minTouchKid)
                                    .padding(MPSpacing.xxs)
                                    .overlay(Circle().strokeBorder(selected ? MPColor.actionPrimary : .clear, lineWidth: 3))
                                Text(child.name).mpText(.callout).fontWeight(.black)
                                    .foregroundStyle(MPColor.textPrimary).lineLimit(1)
                            }
                            .frame(minWidth: MPSize.minTouchKid)
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityLabel(child.name)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    Button { app.requestProfileAdd() } label: {
                        VStack(spacing: MPSpacing.xs) {
                            MPIcon("plus", size: MP.G.xl, weight: .semibold)
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(width: MPSize.minTouchKid + MPSpacing.sm, height: MPSize.minTouchKid + MPSpacing.sm)
                                .overlay(Circle().strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [5, 4])))
                            Text("Ekle").mpText(.callout).fontWeight(.black).foregroundStyle(MPColor.textSecondary)
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

    private var finishedCount: Int {
        storyManager.stories.filter { $0.isFinished && $0.belongs(to: profile) }.count
    }

    private var stars: Int {
        guard let profile else { return 0 }
        return MPStars.count(for: profile, stories: storyManager.stories)
    }

    /// Sayılar tek, düz bir bilgi panelinde: kutuların ayrı sert kenarı yok,
    /// çünkü dokunulmuyorlar (basılabilir görünen ama çalışmayan öğe olmasın).
    /// En büyük yazı boyutlarında her sayı tek satır, alt alta.
    private var statsRow: some View {
        let ax = typeSize.isAccessibilitySize
        let layout = ax
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: MPSpacing.sm))
            : AnyLayout(HStackLayout(alignment: .top, spacing: MPSpacing.sm))
        return VStack(spacing: MPSpacing.sm) {
            layout {
                stat(value: stars, label: "yıldız", row: ax) { MPStarMark(size: 20) }
                stat(value: streak.currentStreak, label: "gün üst üste", row: ax) {
                    MPIcon("flame", size: MP.G.md, weight: .semibold).foregroundStyle(MPWorldTone.peach.deep)
                }
                stat(value: finishedCount, label: "masal", row: ax) {
                    MPIcon("book", size: MP.G.md, weight: .semibold).foregroundStyle(MPWorldTone.sky.deep)
                }
            }
            Text("Her sabah 1 yıldız gelir. Her masal 1 yıldız.")
                .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    /// Tek sayı kutucuğu: açık gri, gölgesiz (dokunulmuyor, düğme gibi durmaz).
    private func stat<Glyph: View>(value: Int, label: String, row: Bool,
                                   @ViewBuilder glyph: () -> Glyph) -> some View {
        let layout = row
            ? AnyLayout(HStackLayout(spacing: MPSpacing.md))
            : AnyLayout(VStackLayout(spacing: MPSpacing.xxs))
        return layout {
            glyph().accessibilityHidden(true)
            Text("\(value)").mpText(.title2).monospacedDigit().foregroundStyle(MPColor.textPrimary)
            Text(label).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: row ? .leading : .center)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.sm)
        .background(MPColor.backgroundSunken,
                    in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rozetlerim

    /// Bütün rozetler, kazanılmamışlar kilitli (karar 13 Ekim 2026). İlerleme
    /// çubuğu ya da "az kaldı" metni yok (CLAUDE.md ilke 7).
    private var badgesSection: some View {
        HomeSection(title: "Rozetlerim", contained: false,
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
            HomeSection(title: "Masal dünyam", contained: false) {
                // Satırlar tek panelde; panel tek parça olsun diye tek kap.
                VStack(spacing: 0) {
                    if IllustratedBookAccess.isEnabled() {
                        linkRow(icon: "paintpalette", tone: .sky, title: "Kahramanımı düzenle",
                                subtitle: "Saç, ten rengi, gözlük, kıyafet") {
                            guarded { app.sheet = .bookCharacter(profile.id) }
                        }
                        MPRowDivider(area: .kid)
                    }
                    linkRow(icon: "heart", tone: .peach, title: "Masal ailem",
                            subtitle: familySubtitle) {
                        app.sheet = .familyCharacters(profile.id)
                    }
                    MPRowDivider(area: .kid)
                    linkRow(icon: "book.closed", tone: .mint, title: "Yeni kelimelerim",
                            subtitle: wordsSubtitle) {
                        app.sheet = .newWords(profile.id)
                    }
                }
                .padding(.vertical, MPSpacing.xxs)
                .background(MPColor.backgroundSunken,
                            in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
            }
        }
    }

    /// Ebeveyn modunda doğrudan, çocuk modunda kapı açılınca çalışır.
    private func guarded(_ action: @escaping () -> Void) {
        if app.isParentMode { action(); return }
        afterGate = action
        gate = true
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
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MPListRow(systemImage: icon, tone: tone, title: title, subtitle: subtitle)
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
    @State private var breathing = false
    @State private var hop = false

    var body: some View {
        MascotImage(mascot: mascot, width: width)
            .scaleEffect(breathing ? 1.025 : 1, anchor: .bottom)
            .offset(y: hop ? -12 : 0)
            .offset(y: appeared ? 0 : MP.S.x5)
            .opacity(appeared ? 1 : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !reduceMotion, !hop else { return }
                MPHaptics.tap()
                withAnimation(MP.M.spring) { hop = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(MP.M.spring) { hop = false }
                }
            }
            .onAppear {
                if reduceMotion { appeared = true; return }
                withAnimation(MP.M.spring.delay(0.1)) { appeared = true }
                withAnimation(MP.M.idle.delay(0.6)) { breathing = true }
            }
            .accessibilityHidden(true)
    }
}

#Preview("12 · Benim köşem") {
    KidCornerView().environmentObject(MPAppState())
}
