import SwiftUI

// MARK: - Günlük masal okuyucusu

/// Günün masalı (Ana sayfadaki kart). Günlük masallar tek parça metindir;
/// okuma yüzeyi ana okuyucuyla aynı tema, punto ve üst çubuk kurallarını
/// kullanır. "Günlük" sekmesi Ana sayfaya katıldı (FAZ 17), liste ekranı yok.
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
            HStack(spacing: MPSpacing.sm) {
                MPCircleButton(systemImage: "xmark", accessibilityLabel: "Kapat",
                               tint: theme.foreground,
                               fill: theme == .night ? MPColor.readerNightTrack : MPColor.backgroundSurface) { dismiss() }
                VStack(spacing: 0) {
                    Text(story.title).mpText(.callout).foregroundStyle(theme.foreground).lineLimit(1)
                    Text(story.mpMeta).mpText(.caption).foregroundStyle(theme.muted)
                }
                .frame(maxWidth: .infinity)
                MPCircleButton(systemImage: "textformat.size", accessibilityLabel: "Okuma ayarları",
                               tint: theme.foreground,
                               fill: theme == .night ? MPColor.readerNightTrack : MPColor.backgroundSurface) {
                    showReaderSettings = true
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.vertical, MPSpacing.xs)

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
                    MPIcon(story.category.mpSymbol, size: 64, weight: .semibold)
                        .foregroundStyle(MPWorldTone.lav.deep)
                        .frame(width: 150, height: 150)
                        .background(MPWorldTone.lav.soft, in: RoundedRectangle(cornerRadius: MPRadius.hero, style: .continuous))
                        .accessibilityHidden(true)

                    Text(story.content)
                        .font(MP.F.read(app.readSize.points))
                        .lineSpacing(app.readSize.lineSpacing)
                        .foregroundStyle(theme.body)
                        .multilineTextAlignment(.center)

                    if !story.moralLesson.isEmpty {
                        HStack(spacing: MPSpacing.md) {
                            MPIcon("sparkles", size: 22, weight: .semibold)
                                .foregroundStyle(MPWorldTone.yellow.deep)
                                .accessibilityHidden(true)
                            Text(story.moralLesson).mpText(.bodyStrong)
                                .foregroundStyle(MPColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(MPSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(MPWorldTone.yellow.soft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                    }
                }
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.vertical, MPSpacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $showReaderSettings) {
            ReaderSettingsSheet(onClose: { showReaderSettings = false })
                .environmentObject(app)
                .environmentObject(MPSettingsStore.shared)
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
