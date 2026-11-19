import SwiftUI
import StoreKit

/// 29 · Büyükler için (eski Özet, `EbeveynPaneli`).
///
/// 14 Kasım 2026: ebeveyn odası tek sayfa. Sırası: bu hafta (cümle, sayılar,
/// grafik, son masallar) → okuma ve uyku → abonelik → daha fazla (Masal
/// güvenliği ve Ayarlar, itilen alt sayfalar). Sekme çubuğu yok.
///
/// Ebeveynin sorusu "işe yarıyor mu?". Onay kuyruğu yok (masal onayı 14 Kasım
/// 2026'da kalktı). Yıldız sayacı yok (karar 7 Ekim 2026).
struct ParentOverviewView: View {
    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var streak = MPStreak.shared

    @State private var showsLapse = false
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.section) {
                MPParentHeader(title: "Büyükler için", subtitle: weekLabel)
                    // Huni: ebeveyn "Büyükler için"i buldu (Faz 6).
                    .onAppear { MPFunnel().record(.parentRoom) }
                    // Faz 14: değerlendirme isteği yalnızca burada, kurallar `MPReviewPolicy`'de.
                    .task { await askForReviewIfDue() }

                if profileManager.profiles.count > 1 { childPicker }
                // Sayılardan önce tek cümle (Faz 7).
                Text(ParentInsight.sentence(stories: readThisWeek, minutes: streak.minutesThisWeek,
                                            streak: streak.currentStreak))
                    .mpText(.body).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                statsGrid
                dailyChart
                if !recentStories.isEmpty { recentSection }
                ParentReadingRules()
                subscriptionSection
                moreSection
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.lg)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .background(MPColor.backgroundParent.ignoresSafeArea())
        .navigationDestination(isPresented: $showsLapse) {
            SubscriptionExpiredView(onRenew: {
                showsLapse = false
                app.openPaywall()
            }, onClose: { showsLapse = false })
            .toolbar(.hidden, for: .navigationBar)
        }
        .onChange(of: showsLapse) { _, shown in
            if !shown { subscriptionManager.acknowledgeLapse() }
        }
    }

    // MARK: - Üst bölüm

    /// "Bu hafta · 29 Eylül - 5 Ekim"
    /// Özet açıldıktan kısa süre sonra, sayfa yerleşince.
    private func askForReviewIfDue() async {
        let finished = storyManager.stories.filter(\.isFinished).count
        guard MPReviewPolicy.shouldAskNow(finished: finished) else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        MPReviewPolicy.recordAsked()
        requestReview()
    }

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

    // MARK: - Sayılar

    private var childStories: [Story] {
        storyManager.stories.filter { $0.isReadable && $0.belongs(to: profileManager.currentProfile) }
    }

    /// Başlıktaki haftayla aynı: Pazartesi-Pazar (Faz 7; önceden kayan 7 gün).
    private var readThisWeek: Int {
        guard let week = ParentInsight.weekInterval() else { return 0 }
        return childStories.filter { week.contains($0.lastReadAt ?? .distantPast) }.count
    }

    /// Bu hafta albüme giren çıkartmalar: biten masallar ve klasikler.
    private var stickersThisWeek: Int {
        guard let week = ParentInsight.weekInterval() else { return 0 }
        return MPStickerAlbum.stickers(for: profileManager.currentProfile, stories: storyManager.stories)
            .filter { week.contains($0.date) }.count
    }

    private var statsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: MPSpacing.md), GridItem(.flexible(), spacing: MPSpacing.md)]
        return LazyVGrid(columns: columns, spacing: MPSpacing.md) {
            MPStatTile(systemImage: "clock", tone: .green, value: "\(streak.minutesThisWeek)",
                       unit: "dk", label: "Okuma süresi", area: .parent)
            MPStatTile(systemImage: "book", tone: .lav, value: "\(readThisWeek)",
                       label: "Okunan masal", area: .parent)
            MPStatTile(systemImage: "flame", tone: .peach, value: "\(streak.currentStreak)",
                       unit: "gün", label: "Üst üste gün", area: .parent)
            // Vizyon planı düzen 11: ebeveyn çocuğun bu hafta ne topladığını görür.
            // Kelimeler çocuğun "Yeni kelimelerim" sayfasında duruyor.
            MPStatTile(systemImage: "star", tone: .yellow, value: "\(stickersThisWeek)",
                       label: "Bu hafta çıkartma", area: .parent)
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
                            Text(days[i]).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
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
                            link: ("Kitap yap", { app.unlock(.pdfBook) { app.router.parentRoute = .bookExport } }))
            MPGroupedList(area: .parent) {
                ForEach(Array(recentStories.enumerated()), id: \.element.id) { index, story in
                    if index > 0 { MPRowDivider(area: .parent) }
                    ParentRowButton(systemImage: story.mpWorld.icon, tone: story.mpWorld.tone,
                                    title: story.title, subtitle: subtitle(for: story)) {
                        app.actionsStory = story
                    }
                }
            }
            // Aile sesi (Faz 5): henüz kayıt yoksa sakin bir davet.
            if FamilyFeatureAccess.isEnabled(.voiceRecording) && VoiceRecordingStore.shared.sets.isEmpty {
                MPGroupedList(area: .parent) {
                    ParentRowButton(systemImage: "mic", tone: .peach, title: "Masalı kendi sesinle oku",
                                    subtitle: "Çocuğun masalı senin sesinle dinlesin.") {
                        app.unlock(.ownVoice) { app.router.parentRoute = .voiceRecording }
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

    // MARK: - Daha fazla

    private var moreSection: some View {
        ParentSection(title: "Daha fazla") {
            ParentRowButton(systemImage: "checkmark.shield", tone: .mint, title: "Masal güvenliği",
                            subtitle: "Heyecan sınırı, kaçınılacak konular, yıldızlar") {
                app.router.parentRoute = .safety
            }
            MPRowDivider(area: .parent)
            ParentRowButton(systemImage: "gearshape", tone: .lav, title: "Ayarlar",
                            subtitle: "Profiller, aile, bildirimler, hesap, destek") {
                app.router.parentRoute = .settings
            }
        }
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
                        MPButton(title: "Ayrıntı", kind: .secondary, size: .small) { showsLapse = true }
                    } else {
                        MPButton(title: "Planlar", kind: .secondary, size: .small) { app.openPaywall() }
                    }
                }
            }
        }
    }
}

#Preview("29 · Büyükler için") {
    ParentOverviewView()
        .environmentObject(MPAppState())
        .environmentObject(MPSettingsStore.shared)
}
