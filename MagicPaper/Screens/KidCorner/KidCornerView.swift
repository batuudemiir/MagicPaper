import SwiftUI

/// 12 · Benim köşem (`BenimKosem`).
///
/// Çocuğun kendi sayfası: kim okuyor, okuma sayıları, rozetler, kahraman,
/// Masal ailem. Yıldız sayacı yok (karar 7 Ekim 2026). "Ekle" ebeveyn
/// kapısına gider. "Yeni kelimelerim" kelime ve anlam içeriği gelince
/// görünür (FAZ 17 içerik hattı).
struct KidCornerView: View {
    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var earned: Set<MPMilestone> = []
    @State private var familyNames: [String] = []

    private var profile: UserProfile? { profileManager.currentProfile }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.section) {
                header
                statsRow
                badgesSection
                linksSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(alignment: .top) {
            HeaderWash(height: 290, colors: [MPWorldTone.green.soft, MPWorldTone.sky.soft, MPWorldTone.lav.soft])
        }
        .background(MPColor.backgroundKid.ignoresSafeArea())
        .onAppear(perform: refresh)
        .onChange(of: profile?.id) { _, _ in refresh() }
    }

    private func refresh() {
        guard let profile else { earned = []; familyNames = []; return }
        let store = MPBadgeStore()
        store.update(for: profile.id, reading: MPBadgeStore.reading(
            stories: storyManager.stories, profile: profile, daysInARow: streak.currentStreak))
        earned = store.earned(for: profile.id)
        familyNames = FamilyCharacterStore().characters(for: profile.id).map(\.name)
    }

    // MARK: - Kim okuyor?

    private var header: some View {
        VStack(spacing: MPSpacing.lg) {
            ZStack {
                Text("Benim köşem").mpText(.navTitle).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    Spacer()
                    MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat") {
                        withAnimation(MP.M.gated(MP.M.base)) { app.showKidCorner = false }
                    }
                }
            }
            .padding(.top, MPSpacing.lg)

            Text("Kim okuyor?").mpText(.callout).foregroundStyle(MPColor.textSecondary)

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
                                MPAvatar(name: child.name, color: child.mpColor, size: 72)
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
                    Button { app.requestParentMode() } label: {
                        VStack(spacing: MPSpacing.xs) {
                            MPIcon("plus", size: 26, weight: .semibold)
                                .foregroundStyle(MPColor.textSecondary)
                                .frame(width: 80, height: 80)
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

    private var statsRow: some View {
        HStack(spacing: MPSpacing.md) {
            stat(icon: "flame", tone: .peach, value: streak.currentStreak, label: "gün üst üste")
            stat(icon: "book", tone: .sky, value: finishedCount, label: "masal")
            stat(icon: "trophy", tone: .yellow, value: earned.count, label: "rozet")
        }
    }

    private func stat(icon: String, tone: MPWorldTone, value: Int, label: String) -> some View {
        VStack(spacing: MPSpacing.xxs) {
            MPIcon(icon, size: 24, weight: .semibold).foregroundStyle(tone.deep).accessibilityHidden(true)
            Text("\(value)").mpText(.title2).monospacedDigit().foregroundStyle(MPColor.textPrimary)
            Text(label).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.tile))
        .mpShadow(.card)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Rozetlerim

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Rozetlerim")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md), count: 3),
                      spacing: MPSpacing.md) {
                ForEach(MPMilestone.allCases) { badge in
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
            MPGroupedList(area: .kid) {
                if IllustratedBookAccess.isEnabled() {
                    linkRow(icon: "paintpalette", tone: .sky, title: "Kahramanımı düzenle",
                            subtitle: "Saç, ten rengi, gözlük, kıyafet") {
                        app.sheet = .bookCharacter(profile.id)
                    }
                    MPRowDivider(area: .kid)
                }
                linkRow(icon: "heart", tone: .peach, title: "Masal ailem",
                        subtitle: familySubtitle) {
                    app.sheet = .familyCharacters(profile.id)
                }
            }
        }
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

#Preview("12 · Benim köşem") {
    KidCornerView().environmentObject(MPAppState())
}
