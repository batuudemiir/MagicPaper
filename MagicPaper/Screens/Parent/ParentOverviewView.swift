import SwiftUI

/// 29 · Ebeveyn · Özet (`EbeveynPaneli`).
///
/// Ebeveynin sorusu "işe yarıyor mu?". Yapılacak tek iş, onay bekleyen
/// masallar, sayıların önünde durur. Yıldız sayacı yok (karar 7 Ekim 2026).
struct ParentOverviewView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var streak = MPStreak.shared

    @State private var showsLapse = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Özet", subtitle: weekLabel)

                if profileManager.profiles.count > 1 { childPicker }
                if settings.approve && !pendingStories.isEmpty { approvalQueue }
                statsGrid
                dailyChart
                if !recentStories.isEmpty { recentSection }
                subscriptionSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .fullScreenCover(isPresented: $showsLapse, onDismiss: { subscriptionManager.acknowledgeLapse() }) {
            SubscriptionExpiredView(onRenew: {
                showsLapse = false
                app.openPaywall()
            }, onClose: { showsLapse = false })
        }
    }

    // MARK: - Üst bölüm

    /// "Bu hafta · 29 Eylül - 5 Ekim"
    private var weekLabel: String {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "tr_TR")
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()),
              let last = cal.date(byAdding: .day, value: 6, to: week.start) else { return "Bu hafta" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM"
        return "Bu hafta · \(f.string(from: week.start)) - \(f.string(from: last))"
    }

    /// Hangi çocuğun özeti. Seçim etkin çocuğu değiştirir: okuma serisi ve
    /// süreleri çocuk başına tutulur (`MPStreak.activate`).
    private var childPicker: some View {
        MPFlowLayout(spacing: MPSpacing.sm) {
            ForEach(profileManager.profiles) { profile in
                MPChip(title: profile.name,
                       isSelected: profile.id == profileManager.currentProfile?.id) {
                    profileManager.switchProfile(to: profile)
                }
                .frame(minHeight: MPSize.minTouchParent)
                .accessibilityLabel("\(profile.name) için özet")
            }
        }
    }

    // MARK: - Onay kuyruğu

    private var pendingStories: [Story] {
        storyManager.stories.filter { $0.isReadable && !settings.isApproved($0.id) }
    }

    private var approvalQueue: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(spacing: MPSpacing.md) {
                MPIcon("tray", size: 20, weight: .semibold)
                    .foregroundStyle(MPColor.statusWarning)
                    .frame(width: 40, height: 40)
                    .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.sm))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(pendingStories.count) masal onay bekliyor")
                        .mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                    Text("Onaylayana kadar kitaplıkta görünmüyor")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
            }
            ForEach(pendingStories.prefix(5)) { story in
                HStack(spacing: MPSpacing.md) {
                    Text(story.title).mpText(.bodyStrong).foregroundStyle(MPColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    MPButton(title: "Onayla", kind: .soft, size: .small) {
                        settings.approveStory(story.id)
                        app.showToast("Masal onaylandı", symbol: "checkmark")
                    }
                    .accessibilityLabel("\(story.title) masalını onayla")
                }
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColor.statusWarningSoft, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(MPColor.statusWarningBorder, lineWidth: 1.5))
    }

    // MARK: - Sayılar

    private var childStories: [Story] {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: profileManager.currentProfile) }
    }

    private var readThisWeek: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return childStories.filter { ($0.lastReadAt ?? .distantPast) >= start }.count
    }

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: MPSpacing.md), GridItem(.flexible(), spacing: MPSpacing.md)]
        return LazyVGrid(columns: columns, spacing: MPSpacing.md) {
            MPStatTile(systemImage: "clock", tone: .green, value: "\(streak.minutesThisWeek)",
                       unit: "dk", label: "Okuma süresi", area: .parent)
            MPStatTile(systemImage: "book", tone: .lav, value: "\(readThisWeek)",
                       label: "Okunan masal", area: .parent)
            MPStatTile(systemImage: "flame", tone: .peach, value: "\(streak.currentStreak)",
                       unit: "gün", label: "Okuma serisi", area: .parent)
            MPStatTile(systemImage: "book.closed", tone: .mint,
                       value: "\(MPVocabulary.summary(for: childStories).uniqueThisMonth)",
                       label: "Bu ay farklı kelime", area: .parent)
        }
    }

    private var dailyChart: some View {
        let minutes = streak.minutesThisWeekByDay
        let peak = max(minutes.max() ?? 0, 1)
        let todayIndex = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        let days = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
        return MPCard(area: .parent, padding: MPSpacing.xl) {
            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                HStack {
                    Text("Günlük okuma").mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    Spacer()
                    Text("dakika").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                }
                HStack(alignment: .bottom, spacing: MPSpacing.sm) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack(spacing: MPSpacing.sm) {
                            RoundedRectangle(cornerRadius: MPRadius.sm)
                                .fill(i == todayIndex ? MPColor.actionPrimary : MPColor.brandLilac.opacity(0.7))
                                .frame(height: max(MPSpacing.lg, 100 * CGFloat(minutes[i]) / CGFloat(peak)))
                            Text(days[i]).mpText(.caption).foregroundStyle(MPColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 130, alignment: .bottom)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bu haftanın günlük okuma süresi")
        .accessibilityValue(zip(days, minutes).map { "\($0) \($1) dakika" }.joined(separator: ", "))
    }

    // MARK: - Son masallar

    private var recentStories: [Story] {
        childStories
            .sorted { ($0.lastReadAt ?? $0.createdAt) > ($1.lastReadAt ?? $1.createdAt) }
            .prefix(3)
            .map { $0 }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Son masallar", area: .parent,
                            link: ("Kitap yap", { app.parentRoute = .bookExport }))
            MPGroupedList(area: .parent) {
                ForEach(Array(recentStories.enumerated()), id: \.element.id) { index, story in
                    if index > 0 { MPRowDivider(area: .parent) }
                    ParentRowButton(systemImage: story.mpWorld.icon, tone: story.mpWorld.tone,
                                    title: story.title, subtitle: subtitle(for: story)) {
                        app.actionsStory = story
                    }
                }
            }
        }
    }

    private func subtitle(for story: Story) -> String {
        let when = story.lastReadAt ?? story.createdAt
        let day: String
        if Calendar.current.isDateInToday(when) { day = "bugün" }
        else if Calendar.current.isDateInYesterday(when) { day = "dün" }
        else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "tr_TR")
            f.dateFormat = "d MMMM"
            day = f.string(from: when)
        }
        let unfinished = (story.lastReadPage ?? 0) > 0 && (story.lastReadPage ?? 0) < story.pages.count - 1
        return "\(story.childName) · \(day) · " + (unfinished ? "yarım kaldı" : "\(story.pages.count) sayfa")
    }

    // MARK: - Abonelik

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: "Abonelik", area: .parent)
            MPCard(area: .parent) {
                HStack(spacing: MPSpacing.md) {
                    MPIconTile(systemImage: "crown", tone: .yellow, size: 48)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(subscriptionManager.isPremium ? "Hikaye Kahramanı" : "Ücretsiz plan")
                            .mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                        Text(subscriptionManager.isPremium ? "Aylık yenilenir"
                             : (subscriptionManager.hasUnseenLapse ? "Premium süren doldu" : "Temel masallar"))
                            .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    }
                    Spacer(minLength: MPSpacing.sm)
                    if subscriptionManager.hasUnseenLapse && !subscriptionManager.isPremium {
                        MPButton(title: "Ayrıntı", kind: .soft, size: .small) { showsLapse = true }
                    } else {
                        MPButton(title: "Planlar", kind: .soft, size: .small) { app.openPaywall() }
                    }
                }
            }
        }
    }
}

#Preview("29 · Özet") {
    ParentOverviewView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
