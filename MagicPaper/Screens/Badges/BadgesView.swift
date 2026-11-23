import SwiftUI

/// Rozetlerim (rozet planı R3, 4.3): Profil'deki "Tümü ›" ile itilen sayfa.
///
/// Yukarıdan aşağı: Yıldız katı, kademeli yollar (aile başına tek kart, en
/// yüksek kazanılan kat), tek rozetler aile aile, Masal anıları. Kilitli rozet
/// gri + kilit, gizli rozet "?"; ilerleme çubuğu ve "az kaldı" yok (ilke 7).
/// Ekranın tek Ragi'si üstte, balonla.
struct BadgesView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var ledger = MPBadgeLedger()
    @State private var opened: MPBadgeSheetItem?

    private var earned: Set<String> { ledger.earnedIDs }
    private var score: Int { MPStars.score(for: profile, stories: storyManager.stories) }

    var body: some View {
        // Menü sayfalarının ortak çatısı (23 Kasım 2026): mor gök, beyaz tanıtım kartı.
        MPSkyPage(title: "Rozetlerim", onBack: { app.router.closeKidPage() }) {
            MPSkyIntro(mascot: .happy,
                       headline: "\(earned.count) / \(MPBadgeCatalog.all.count) rozet",
                       message: MPBadgeCopy.greeting(earned: earned.count))
                .accessibilityValue("\(MPBadgeCatalog.all.count) rozetten \(earned.count) tanesi kazanıldı")
        } content: {
            starLevelCard
            pathsSection
            ForEach(MPBadgeFamily.allCases.filter { !$0.isTiered }, id: \.self) { family in
                singlesSection(family)
            }
            memoriesSection
        }
        .onAppear(perform: refresh)
        .onChange(of: storyManager.stories) { _, _ in refresh() }
        .sheet(item: $opened) { item in
            MPBadgeDetailSheet(item: item, ledger: ledger, score: score) { opened = nil }
        }
    }

    private func refresh() {
        ledger = MPBadgeStore().ledger(for: profile, stories: storyManager.stories)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md), count: typeSize.isAccessibilitySize ? 1 : 3)
    }

    // MARK: - Yıldız katı

    private var starLevelCard: some View {
        let level = MPStarLevel.current(score: score)
        return Button {
            MPHaptics.tap()
            opened = .starLevels
        } label: {
            HStack(spacing: MPSpacing.lg) {
                MPStarLevelArt(level: level, size: 72)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    Text("Yıldız katın").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    Text(level?.title ?? "İlk kat yolda").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    HStack(spacing: MPSpacing.xs) {
                        MPStarMark(size: 14)
                        Text("\(score) yıldız").mpText(.supporting).fontWeight(.bold).monospacedDigit()
                            .foregroundStyle(MPColor.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                MPChevron()
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpKidSurface(MPWorldTone.yellow.soft, edge: MPWorldTone.yellow.edge)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yıldız katın: \(level?.title ?? "henüz kat yok"), \(score) yıldız")
        .accessibilityHint("Bütün katları açar")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Kademeli yollar

    private var pathsSection: some View {
        HomeSection(title: "Yollar") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
                                     count: typeSize.isAccessibilitySize ? 1 : 2),
                      spacing: MPSpacing.md) {
                ForEach(MPBadgeFamily.allCases.filter(\.isTiered), id: \.self) { family in
                    pathCard(family)
                }
            }
        }
    }

    /// Ailenin tek kartı: en yüksek kazanılan kat; hiçbiri yoksa ilk kat kilitli.
    private func pathCard(_ family: MPBadgeFamily) -> some View {
        let badges = MPBadgeCatalog.badges(in: family)
        let top = badges.last { earned.contains($0.id) }
        let shown = top ?? badges[0]
        return Button {
            MPHaptics.tap()
            opened = .family(family)
        } label: {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                MPBadgeArt(badge: shown, unlocked: top != nil)
                Text(family.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                Text(top?.title ?? "Kilitli").mpText(.footnote)
                    .foregroundStyle(MPColor.textSecondary).lineLimit(2)
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mpKidSurface(top != nil ? shown.tone.soft : MPColor.lockedFill,
                          edge: top != nil ? shown.tone.edge : MPColor.lockedCircle)
        }
        .buttonStyle(MPPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(family.title)
        .accessibilityValue(top.map { "\($0.title), \($0.tier). kat" } ?? "Kilitli")
        .accessibilityHint("Bütün katları açar")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Tek rozetler

    private func singlesSection(_ family: MPBadgeFamily) -> some View {
        let badges = MPBadgeCatalog.badges(in: family)
        let count = badges.filter { earned.contains($0.id) }.count
        return HomeSection(title: family.title, note: "\(count) / \(badges.count)",
                           noteSpoken: "\(badges.count) rozetten \(count) tanesi kazanıldı") {
            LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                ForEach(badges) { badge in
                    MPBadgeTile(badge: badge, unlocked: earned.contains(badge.id)) { opened = .badge(badge) }
                }
            }
        }
    }

    // MARK: - Masal anıları

    @ViewBuilder
    private var memoriesSection: some View {
        let service = OfflineStoryService.shared
        let names = Dictionary(service.allPlaces().map { ($0.id, $0.place.name) }, uniquingKeysWith: { a, _ in a })
        let memories = MPBadgeMemories.build(ledger: ledger,
                                             stories: storyManager.stories.filter { $0.belongs(to: profile) },
                                             placeName: { names[$0] },
                                             companionName: { service.companionName(id: $0) })
        if !memories.isEmpty {
            HomeSection(title: "Masal anıları") {
                VStack(alignment: .leading, spacing: MPSpacing.md) {
                    ForEach(memories) { memory in
                        HStack(spacing: MPSpacing.md) {
                            MPIconTile(systemImage: memory.icon, tone: memory.tone, size: 44, filled: true)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                Text(memory.title).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                                Text(memory.value).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

// MARK: - Ayrıntı

enum MPBadgeSheetItem: Identifiable, Equatable {
    case badge(MPBadge)
    case family(MPBadgeFamily)
    case starLevels

    var id: String {
        switch self {
        case .badge(let b): return "badge-\(b.id)"
        case .family(let f): return "family-\(f.rawValue)"
        case .starLevels: return "starLevels"
        }
    }
}

/// Rozet, kademeli yol ya da Yıldız katı ayrıntısı (sistem sheet'i). Kilitli
/// olan yalnızca nasıl açıldığını söyler, kalanı söylemez (R0 kararı 2).
struct MPBadgeDetailSheet: View {
    let item: MPBadgeSheetItem
    let ledger: MPBadgeLedger
    let score: Int
    let onClose: () -> Void

    var body: some View {
        MPSheet(title: title, onClose: onClose) {
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                switch item {
                case .badge(let badge):
                    single(badge)
                case .family(let family):
                    ForEach(MPBadgeCatalog.badges(in: family)) { row($0) }
                case .starLevels:
                    Text("\(score) yıldızın var. Süslere harcadığın yıldızlar bu sayıdan düşmez.")
                        .mpText(.body).foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(MPStarLevel.all) { levelRow($0) }
                }
            }
        }
    }

    private var title: String {
        switch item {
        case .badge(let b): return b.displayTitle(unlocked: ledger.earned[b.id] != nil)
        case .family(let f): return f.title
        case .starLevels: return "Yıldız katları"
        }
    }

    private func single(_ badge: MPBadge) -> some View {
        let date = ledger.earned[badge.id]
        return VStack(spacing: MPSpacing.md) {
            MPBadgeArt(badge: badge, unlocked: date != nil, size: 120)
            Text(date.map(MPBadgeCopy.earnedLine) ?? badge.lockedHint)
                .mpText(.body).multilineTextAlignment(.center)
                .foregroundStyle(MPColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func row(_ badge: MPBadge) -> some View {
        let date = ledger.earned[badge.id]
        return HStack(spacing: MPSpacing.md) {
            MPBadgeArt(badge: badge, unlocked: date != nil, size: 48)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(badge.displayTitle(unlocked: date != nil)).mpText(.cardTitle)
                    .foregroundStyle(date != nil ? MPColor.textPrimary : MPColor.textSecondary)
                Text(date.map(MPBadgeCopy.earnedLine) ?? badge.lockedHint)
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if date == nil {
                MPIcon("lock.fill", size: MP.G.xs).foregroundStyle(MPColor.textSecondary).accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(date == nil ? "Kilitli" : "Kazanıldı")
    }

    private func levelRow(_ level: MPStarLevel) -> some View {
        let date = ledger.starLevels[level.id]
        let reached = date != nil || score >= level.threshold
        return HStack(spacing: MPSpacing.md) {
            MPStarLevelArt(level: reached ? level : nil, size: 48)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text(level.title).mpText(.cardTitle)
                    .foregroundStyle(reached ? MPColor.textPrimary : MPColor.textSecondary)
                Text(date.map(MPBadgeCopy.reachedLine) ?? (reached ? "Ulaştın." : level.lockedHint))
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            Spacer(minLength: 0)
            if !reached {
                MPIcon("lock.fill", size: MP.G.xs).foregroundStyle(MPColor.textSecondary).accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(reached ? "Ulaşıldı" : "Kilitli")
    }
}
