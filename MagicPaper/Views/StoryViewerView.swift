import SwiftUI

/// Okuyucu — 03-SCREENS.md §6.
/// Uygulamadaki tek "koyu mod" burada yaşar: tema yalnızca okuma yüzeyine
/// uygulanır, uygulama geneline değil.
struct StoryViewerView: View {
    let story: Story

    @EnvironmentObject private var app: MPAppState
    @EnvironmentObject private var settings: MPSettingsStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var favorites = MPFavorites.shared
    @StateObject private var streak = MPStreak.shared
    @StateObject private var speech = MPSpeech.shared

    @State private var page = 0
    @State private var turning = false
    @State private var slide: CGFloat = 0
    /// Okuma süresi ölçümü — ebeveyn panelindeki "Bu hafta okuma" bundan beslenir.
    @State private var openedAt: Date?
    /// Okuma ayarları okuyucunun kendi katmanında açılır (cover'ın üstünde).
    @State private var showReaderSettings = false

    private var theme: MP.ReadTheme { app.readTheme }
    private var pages: [StoryPage] { story.pages }
    private var total: Int { max(pages.count, 1) }
    private var isLast: Bool { page >= total - 1 }
    private var accent: Color { story.mpAccent }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            progressBar
            pageArea
            if isLast { endCard }
            bottomControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
        .overlay {
            if showReaderSettings {
                ReaderSettingsSheet(onClose: {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { showReaderSettings = false }
                })
                .environmentObject(app)
                .environmentObject(settings)
            }
        }
        .animation(MP.M.gated(MP.M.base), value: theme)
        .onAppear {
            // Kayıtlı ilerlemeden aç.
            page = min(max(story.lastReadPage ?? 0, 0), total - 1)
            streak.markReadToday()
            openedAt = Date()
            if settings.readAloud { speech.speak(currentText) }
        }
        .onDisappear {
            commitReadingTime()
            speech.stop()
        }
    }

    // MARK: - Üst satır

    private var topBar: some View {
        HStack(spacing: 10) {
            MPIconButton(symbol: "chevron.left", label: "Kapat",
                         tone: theme == .night ? .glass : .paper) { dismiss() }

            VStack(spacing: 0) {
                Text(story.title)
                    .font(MP.F.caption())
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text("Sayfa \(page + 1) / \(total)")
                    .font(MP.F.caption())
                    .foregroundStyle(theme.foreground.opacity(0.7))
            }
            .frame(maxWidth: .infinity)

            MPIconButton(symbol: favorites.contains(story.id) ? "heart.fill" : "heart",
                         label: "Favori",
                         tone: favorites.contains(story.id) ? .brand
                               : (theme == .night ? .glass : .paper)) {
                let now = favorites.toggle(story.id)
                app.showToast(now ? "Favorilere eklendi" : "Favorilerden çıkarıldı",
                              symbol: "heart.fill")
            }

            MPIconButton(symbol: "textformat.size", label: "Okuma ayarları",
                         tone: theme == .night ? .glass : .paper) {
                withAnimation(MP.M.gated(MP.M.spring)) { showReaderSettings = true }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.vertical, 4)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(theme == .night ? MP.Palette.gece500 : MP.C.surfaceSunken)
                Capsule()
                    .fill(accent)
                    .frame(width: geo.size.width * (Double(page + 1) / Double(total)))
            }
        }
        .frame(height: 4)
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, 8)
        .animation(MP.M.gated(MP.M.base), value: page)
    }

    // MARK: - Sayfa alanı

    private var pageArea: some View {
        GeometryReader { geo in
            VStack(spacing: 26) {
                Spacer(minLength: 0)
                illustration
                Text(currentText)
                    .font(MP.F.read(app.readSize.points))
                    .lineSpacing(app.readSize.lineSpacing)
                    .foregroundStyle(theme.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 30)
            .opacity(turning ? 0 : 1)
            .offset(x: slide)
            .contentShape(Rectangle())
            // Sol yarı önceki, sağ yarı sonraki sayfa.
            .onTapGesture { location in
                if location.x < geo.size.width / 2 { goPrev() } else { goNext() }
            }
        }
    }

    private var currentText: String {
        guard pages.indices.contains(page) else { return "" }
        return pages[page].text
    }

    @ViewBuilder
    private var illustration: some View {
        // Gerçek sayfa görseli varsa gösterilir; yoksa dünya ikonu + tema tonu.
        if pages.indices.contains(page),
           let file = pages[page].imageUrl ?? pages[page].imageFileName,
           let image = FileManagerService.shared.loadImage(fileName: file) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 170, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        } else {
            MPIcon(story.mpSymbol, size: 76, weight: .semibold)
                .foregroundStyle(accent)
                .frame(width: 170, height: 170)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(accent.opacity(0.16))
                )
        }
    }

    // MARK: - Bitiş kartı

    private var endCard: some View {
        MPCard(tone: theme == .night ? .night : .reward, padding: 16) {
            HStack(spacing: 12) {
                MPIcon("trophy.fill", size: 22, weight: .semibold)
                    .foregroundStyle(MP.C.reward)
                Text("Masal bitti, iyi geceler")
                    .font(MP.F.bodyMD(.bold))
                    .foregroundStyle(theme == .night ? MP.Palette.gece100 : MP.C.textTitle)
                Spacer(minLength: 0)
                MPButton(title: "Kapat", tone: .reward, size: .sm) { dismiss() }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.bottom, 10)
    }

    // MARK: - Alt kontroller

    private var bottomControls: some View {
        HStack {
            MPIconButton(symbol: "chevron.left", label: "Önceki sayfa", size: 54,
                         tone: page > 0 ? .paper : .sunken) { goPrev() }
            Spacer(minLength: 0)
            MPIconButton(symbol: speech.isSpeaking && !speech.isPaused
                                 ? "pause.fill" : "speaker.wave.2",
                         label: speech.isSpeaking && !speech.isPaused
                                ? "Sesli okumayı duraklat" : "Sesli oku",
                         size: 54, tone: .glass) {
                speech.toggle(currentText)
            }
            Spacer(minLength: 0)
            MPIconButton(symbol: "chevron.right", label: "Sonraki sayfa", size: 54,
                         tone: .brand) { goNext() }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.bottom, 12)
    }

    // MARK: - Sayfa çevirme

    private func goNext() {
        guard page < total - 1 else { return }
        turn(to: page + 1, direction: -1)
    }

    private func goPrev() {
        guard page > 0 else { return }
        turn(to: page - 1, direction: 1)
    }

    private func turn(to target: Int, direction: CGFloat) {
        withAnimation(.easeOut(duration: 0.13)) {
            turning = true
            slide = 14 * direction
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            let wasSpeaking = speech.isSpeaking && !speech.isPaused
            page = target
            slide = -14 * direction
            saveProgress()
            // Sesli okuma açıkken yeni sayfa kendiliğinden okunur.
            if wasSpeaking {
                speech.speak(currentText)
            } else if settings.readAloud {
                speech.speak(currentText)
            }
            withAnimation(.easeOut(duration: 0.13)) {
                turning = false
                slide = 0
            }
        }
    }

    private func commitReadingTime() {
        guard let openedAt else { return }
        streak.addReadingTime(Date().timeIntervalSince(openedAt))
        self.openedAt = nil
    }

    /// İlerleme asla geri gitmez.
    private func saveProgress() {
        let previous = story.lastReadPage ?? 0
        storyManager.updateLastReadPage(storyId: story.id, page: max(previous, page))
    }
}
