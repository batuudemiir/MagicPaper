import SwiftUI

/// Günlük — hatıra ve süreklilik yüzeyi.
///
/// Bir oyunlaştırma panosu değil. Rozetler ve kupa hedefleri kaldırıldı
/// (ürün kararı 2026-09-23, CLAUDE.md §7): "3 hikâye daha okuyalım, kupayı
/// tamamlayalım" duygusu MagicPaper'ın duygusu değil. Burada sayı varsa bir
/// ödül değil, birlikte yaşanan bir şeyin hatırasıdır.
///
/// Sıra: okuma sürekliliği, bugün için bir hikâye, bugünün masalı, son
/// hikâyeler, bu ayın özeti. Ana Sayfa bu kartları TEKRARLAMIYOR, yalnızca
/// seriyi tek satırda özetleyip buraya getiriyor.
struct DailyStoriesView: View {
    @EnvironmentObject private var app: MPAppState
    @StateObject private var dailyManager = DailyStoryManager.shared
    @StateObject private var streak = MPStreak.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @State private var reading: DailyStory?

    var body: some View {
        VStack(spacing: 0) {
            MPNavBar(title: "Günlük", subtitle: "Birlikte okuduklarınız")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.sectionGap) {
                    streakCard
                    createPrompt
                    todaySection
                    recentSection
                    monthSummary
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
                    MPIcon("book", size: 22, weight: .semibold)
                        .foregroundStyle(MP.C.play)
                    Text(continuityLine)
                        .font(MP.F.displaySM())
                        .foregroundStyle(MP.C.textTitle)
                        .fixedSize(horizontal: false, vertical: true)
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
                let theme: CoverTheme = {
                    switch story.category {
                    case .nature:      return .forest
                    case .adventure:   return .pirate
                    case .bedtime:     return .fairytale
                    case .morning:     return .garden
                    case .educational: return .ocean
                    case .values:      return .kingdom
                    }
                }()
                MPStoryCard(
                    title: story.title,
                    meta: story.mpMeta,
                    symbol: story.category.mpSymbol,
                    accent: story.category.mpAccent,
                    mosaicCover: MagicPaperCoverGenerator.configuration(for: story.id.uuidString, theme: theme),
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

    /// Süreklilik bir hatırlatma değil, bir cümle (CLAUDE.md §7).
    private var continuityLine: String {
        switch streak.currentStreak {
        case 0:  return "Okuma yolculuğunuz burada başlıyor."
        case 1:  return "Dün ya da bugün birlikte okudunuz."
        default: return "\(streak.currentStreak) gün üst üste birlikte okudunuz."
        }
    }

    // MARK: - Bugün

    private var childName: String { profileManager.currentProfile?.name ?? "" }

    private var createPrompt: some View {
        MPCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("BUGÜN")
                    .font(MP.F.labelSM())
                    .foregroundStyle(MP.C.textMuted)
                Text(childName.isEmpty
                     ? "Bugün için bir hikâye oluşturalım mı?"
                     : "\(childName) için bir hikâye oluşturalım mı?")
                    .font(MP.F.displaySM())
                    .foregroundStyle(MP.C.textTitle)
                    .fixedSize(horizontal: false, vertical: true)
                MPButton(title: "Hikâye Oluştur", icon: "wand.and.stars", fullWidth: true) {
                    app.startStoryCreation()
                }
            }
        }
    }

    // MARK: - Son hikâyeler

    /// Bu çocuğun hikâyeleri, en son okunan ya da yaratılan önce.
    private var childStories: [Story] {
        storyManager.stories
            .filter { $0.belongs(to: profileManager.currentProfile) && $0.isReadable }
            .sorted { ($0.lastReadAt ?? $0.createdAt) > ($1.lastReadAt ?? $1.createdAt) }
    }

    @ViewBuilder
    private var recentSection: some View {
        let recent = Array(childStories.prefix(3))
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                MPSectionHeader(title: "Son hikâyeler")
                VStack(spacing: 12) {
                    ForEach(recent) { story in
                        MPStoryCard(
                            title: story.title,
                            meta: MPText.relativeDayLabel(story.lastReadAt ?? story.createdAt),
                            symbol: story.mpSymbol,
                            accent: story.mpAccent,
                            coverTitle: story.mpCoverStyle == .magicPaperMosaic ? nil : story.title,
                            mosaicCover: story.mpCoverStyle == .magicPaperMosaic ? story.mpMosaicCover : nil,
                            badge: nil,
                            progress: nil,
                            layout: .row
                        ) {
                            app.readerStory = story
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bu ay

    /// Bu ay bu çocuk için yaratılan hikâye sayısı — bir hedef değil, bir hatıra.
    /// Sıfırken hiç gösterilmez: boş bir sayaç, doldurulması gereken bir şeye
    /// benzer.
    @ViewBuilder
    private var monthSummary: some View {
        let calendar = Calendar.current
        let count = childStories.filter {
            calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month)
        }.count
        if count > 0 {
            MPCard(tone: .sunken, padding: 18) {
                Text("Bu ay birlikte \(count) hikâye")
                    .font(MP.F.bodyMD(.semibold))
                    .foregroundStyle(MP.C.textMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Günlük masal okuyucusu

/// Günlük masallar tek parça metindir; okuma yüzeyi ana okuyucuyla aynı
/// tema ve punto kurallarını kullanır.
struct DailyStoryReaderView: View {
    let story: DailyStory

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dailyManager = DailyStoryManager.shared
    @StateObject private var streak = MPStreak.shared
    @State private var openedAt: Date?
    /// Ön planda geçen toplam süre. Arka plana geçip dönmek oturumu bölmez.
    @State private var sessionSeconds: Double = 0
    @State private var streakMarked = false
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
        // Günün işaretlenmesi buradan da kalktı. Ana okuyucuyla aynı anlam:
        // günü işaretleyen şey masalın açılması değil, anlamlı bir okuma
        // oturumu. Günlük masal tek parça metin olduğu için çevrilecek sayfa
        // yok — ölçüt yalnızca süre (`MPReadingSession.minimumSeconds`).
        //
        // `markAsRead` ayrı bir defterdir: "bugünün masalı görüldü mü"
        // sorusunun cevabı, seri değil. Yerinde kalıyor.
        .onAppear {
            dailyManager.markAsRead(storyId: story.id)
            openedAt = Date()
        }
        .onDisappear(perform: commitReading)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                commitReading()
            } else if openedAt == nil {
                openedAt = Date()
            }
        }
    }

    /// Ön planda geçen süreyi deftere yazar ve oturumun anlamlı olup
    /// olmadığını değerlendirir.
    private func commitReading() {
        guard let openedAt else { return }
        let elapsed = max(Date().timeIntervalSince(openedAt), 0)
        self.openedAt = nil
        sessionSeconds += elapsed
        streak.addReadingTime(elapsed)

        guard !streakMarked else { return }
        if streak.markReadingSession(
            MPReadingSession(secondsRead: sessionSeconds, pagesTurned: 0)
        ) {
            streakMarked = true
        }
    }
}
