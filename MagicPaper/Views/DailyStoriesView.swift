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
                    badgesSection
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
                    ForEach(Array(streak.thisWeek.enumerated()), id: \.offset) { index, done in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(done ? MP.C.play : MP.C.surfaceSunken)
                                    .frame(width: 34, height: 34)
                                if done {
                                    MPIcon("checkmark", size: 16, weight: .bold)
                                        .foregroundStyle(MP.Palette.kagit0)
                                }
                            }
                            Text(MPStreak.weekdayLabels[index])
                                .font(MP.F.caption())
                                .foregroundStyle(MP.C.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Bugünün masalı

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Bugünün masalı",
                            subtitle: "Her gün kısa, yeni bir masal")

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

    // MARK: - Rozetler

    /// Rozetler bu sayfaya ait: hepsi alışkanlıkla kazanılıyor ve alışkanlığın
    /// sayfası burası. Ebeveyn panelinde bir kopyası yok — aynı şeyi iki yerde
    /// göstermek, bu ekranlarda tekrar tekrar düzelttiğimiz kusurdu.
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MPSectionHeader(title: "Bu ayın rozetleri")

            HStack(spacing: 12) {
                badge(symbol: "trophy.fill", label: "7 gün",
                      color: MP.C.reward, earned: streak.currentStreak >= 7)
                badge(symbol: "book", label: "10 masal",
                      color: MP.C.calm, earned: readCount >= 10)
                badge(symbol: "flame.fill", label: "30 gün",
                      color: MP.C.play, earned: streak.currentStreak >= 30)
            }
        }
    }

    private var readCount: Int {
        dailyManager.dailyStories.filter { $0.isRead }.count
    }

    private func badge(symbol: String, label: String, color: Color, earned: Bool) -> some View {
        MPCard(padding: 14) {
            VStack(spacing: 8) {
                MPIcon(symbol, size: 26, weight: .semibold)
                    .foregroundStyle(earned ? color : MP.C.textFaint)
                Text(label)
                    .font(MP.F.labelSM())
                    .foregroundStyle(MP.C.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(earned ? 1 : 0.5)
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
