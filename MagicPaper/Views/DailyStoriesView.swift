import SwiftUI

/// Günlük — alışkanlık tarafı.
///
/// Kendi sekmesinde: seri, bugünün masalı ve rozetler burada toplanıyor. Ana
/// Sayfa bu sayfanın kartlarını TEKRARLAMIYOR, yalnızca seriyi tek satırda
/// özetleyip buraya getiriyor — aynı kartı iki sekmede göstermek, bu ekranların
/// ilk hâlindeki sorundu.
struct DailyStoriesView: View {
    @EnvironmentObject private var app: MPAppState
    @StateObject private var dailyManager = DailyStoryManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var reading: DailyStory?

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Günlük", subtitle: "Her gün bir masal alışkanlığı")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    streakCard
                    todaySection
                    goalsSection
                }
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
        .mpScreenBackground()
        .fullScreenCover(item: $reading) { story in
            DailyStoryReaderView(story: story)
                .environmentObject(app)
        }
    }

    // MARK: - Seri kartı

    private var streakCard: some View {
        MPCard(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    MPIcon("flame.fill", size: 22, weight: .semibold)
                        .foregroundStyle(MP.C.play)
                    Text("\(streak.currentStreak) günlük seri")
                        .font(MP.F.displaySM())
                        .foregroundStyle(MP.C.textTitle)
                }

                HStack(spacing: 0) {
                    ForEach(Array(streak.weekStates.enumerated()), id: \.offset) { index, state in
                        VStack(spacing: 6) {
                            dayDot(state)
                            Text(MPStreak.weekdayLabels[index])
                                .font(MP.F.caption())
                                .foregroundStyle(state == .today ? MP.C.textTitle : MP.C.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    /// Dört durum, dört görünüm.
    ///
    /// Bugün, okunmamışken bile boş bir daire değil: kesikli bir halka, yani
    /// "burası seni bekliyor". Gelecek günler soluk; kaçırılan günler ne soluk
    /// ne dolu — yalnızca boş. Amaç suçlamak değil, bugünü göstermek.
    @ViewBuilder
    private func dayDot(_ state: MPStreak.DayState) -> some View {
        switch state {
        case .done:
            ZStack {
                Circle().fill(MP.C.play).frame(width: 34, height: 34)
                MPIcon("checkmark", size: 16, weight: .bold)
                    .foregroundStyle(MP.Palette.kagit0)
            }
        case .today:
            Circle()
                .strokeBorder(MP.C.brand, style: StrokeStyle(lineWidth: 2.5, dash: [4, 3]))
                .frame(width: 34, height: 34)
        case .missed:
            Circle().fill(MP.C.surfaceSunken).frame(width: 34, height: 34)
        case .upcoming:
            // Dolu değil, çizgi. %50 opaklıkla dolu bir daire denenmişti ve
            // kaçırılan günden ayırt edilemiyordu — bu paletin içinde iki
            // açık bej ton yan yana aynı renk. Fark tonda değil BİÇİMDE
            // olmalı: henüz gelmemiş bir gün boş bir çerçevedir.
            Circle()
                .strokeBorder(MP.C.borderHairline, lineWidth: 2)
                .frame(width: 34, height: 34)
        }
    }

    // MARK: - Bugünün masalı

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Bugünün masalı")

            if let story = dailyManager.todaysStory ?? dailyManager.dailyStories.first {
                MPStoryCard(
                    title: story.title,
                    meta: story.mpMeta,
                    symbol: story.category.mpSymbol,
                    accent: story.category.mpAccent,
                    badge: "Günlük",
                    layout: .row
                ) {
                    reading = story
                }
            } else {
                MPCard(tone: .sunken, padding: 22) {
                    Text("Bugün için masal hazırlanıyor.")
                        .font(MP.F.bodyMD(.semibold))
                        .foregroundStyle(MP.C.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    // MARK: - Sıradaki hedef

    /// Üç ölü kupa yerine, ulaşılabilir olan tek hedef.
    ///
    /// Önceki hâli üç rozeti de hep gösteriyordu ve iki günlük serisi olan bir
    /// çocuk için üçü de kilitliydi: %50 opaklıkta üç gri kart, hiçbiri ne kadar
    /// kaldığını söylemiyor. Kilitli bir ödül, uzaklığı görünmediğinde ödül
    /// değil; yalnızca sahip olunmayan bir şeyin listesi.
    ///
    /// Kazanılanlar kalır — kazanılmış bir rozeti gizlemek onu geri almaktır.
    /// Kazanılmamışlardan yalnızca EN YAKIN olanı, ilerlemesiyle gösterilir.
    private struct Goal {
        let symbol: String
        let label: String
        let color: Color
        let current: Int
        let target: Int
        var isEarned: Bool { current >= target }
    }

    private var goals: [Goal] {
        [
            Goal(symbol: "trophy.fill", label: "7 günlük seri", color: MP.C.reward,
                 current: streak.currentStreak, target: 7),
            Goal(symbol: "book", label: "10 masal", color: MP.C.calm,
                 current: readCount, target: 10),
            Goal(symbol: "flame.fill", label: "30 günlük seri", color: MP.C.play,
                 current: streak.currentStreak, target: 30)
        ]
    }

    @ViewBuilder
    private var goalsSection: some View {
        let earned = goals.filter(\.isEarned)
        let next = goals.first { !$0.isEarned }

        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: earned.isEmpty ? "Sıradaki hedef" : "Rozetler")

            if let next {
                MPCard(padding: 18) {
                    HStack(spacing: 14) {
                        MPIcon(next.symbol, size: 22, weight: .semibold)
                            .foregroundStyle(next.color)
                            .frame(width: 42, height: 42)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(next.color.opacity(0.16))
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(next.label)
                                .font(MP.F.bodyMD(.bold))
                                .foregroundStyle(MP.C.textTitle)
                            // Sayı açıkça yazılıyor: "2 / 7" bir çubuğun
                            // söyleyemediğini söyler — kaç tane kaldığını.
                            Text("\(next.current) / \(next.target)")
                                .font(MP.F.labelSM())
                                .foregroundStyle(MP.C.textMuted)
                            Capsule().fill(MP.C.surfaceSunken)
                                .frame(height: 8)
                                .overlay(alignment: .leading) {
                                    GeometryReader { geo in
                                        Capsule().fill(next.color)
                                            .frame(width: geo.size.width
                                                   * min(1, Double(next.current) / Double(next.target)))
                                    }
                                }
                        }
                    }
                }
            }

            if !earned.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(earned.enumerated()), id: \.offset) { _, goal in
                        MPCard(padding: 14) {
                            VStack(spacing: 8) {
                                MPIcon(goal.symbol, size: 26, weight: .semibold)
                                    .foregroundStyle(goal.color)
                                Text(goal.label)
                                    .font(MP.F.labelSM())
                                    .foregroundStyle(MP.C.textMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private var readCount: Int {
        dailyManager.dailyStories.filter { $0.isRead }.count
    }
}

// MARK: - Günlük masal okuyucusu

/// Günlük masallar tek parça metindir; okuma yüzeyi ana okuyucuyla aynı
/// tema ve punto kurallarını kullanır.
struct DailyStoryReaderView: View {
    let story: DailyStory

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dailyManager = DailyStoryManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var openedAt: Date?
    @State private var showReaderSettings = false

    private var theme: MP.ReadTheme { app.readTheme }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                MPIconButton(symbol: "chevron.left", label: "Kapat",
                             tone: theme == .night ? .glass : .paper) { dismiss() }

                VStack(spacing: 0) {
                    Text(story.title)
                        .font(MP.F.caption())
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    Text(story.mpMeta)
                        .font(MP.F.caption())
                        .foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity)

                MPIconButton(symbol: "textformat.size", label: "Okuma ayarları",
                             tone: theme == .night ? .glass : .paper) {
                    withAnimation(MP.M.gated(MP.M.spring)) { showReaderSettings = true }
                }
            }
            .padding(.horizontal, MP.S.screenGutter)
            .padding(.vertical, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    MPIcon(story.category.mpSymbol, size: 76, weight: .semibold)
                        .foregroundStyle(story.category.mpAccent)
                        .frame(width: 170, height: 170)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(story.category.mpAccent.opacity(0.16))
                        )

                    Text(story.content)
                        .font(MP.F.read(app.readSize.points))
                        .lineSpacing(app.readSize.lineSpacing)
                        .foregroundStyle(theme.body)
                        .multilineTextAlignment(.center)

                    if !story.moralLesson.isEmpty {
                        MPCard(tone: theme == .night ? .night : .reward, padding: 16) {
                            HStack(spacing: 10) {
                                MPIcon("sparkles", size: 22, weight: .semibold)
                                    .foregroundStyle(MP.C.reward)
                                Text(story.moralLesson)
                                    .font(MP.F.bodySM(.bold))
                                    .foregroundStyle(theme == .night ? MP.Palette.gece100 : MP.C.textTitle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
        .overlay {
            if showReaderSettings {
                ReaderSettingsSheet(onClose: {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { showReaderSettings = false }
                })
                .environmentObject(app)
                .environmentObject(MPSettingsStore.shared)
            }
        }
        .animation(MP.M.gated(MP.M.base), value: theme)
        .onAppear {
            dailyManager.markAsRead(storyId: story.id)
            streak.markReadToday()
            openedAt = Date()
        }
        .onDisappear {
            if let openedAt {
                streak.addReadingTime(Date().timeIntervalSince(openedAt))
                self.openedAt = nil
            }
        }
    }
}
