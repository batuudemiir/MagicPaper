import SwiftUI
import UIKit

/// Uyku modunda okunacak masal: başlık ve sayfa metinleri.
struct MPSleepSession: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let pages: [String]
    /// Masalın kimliği ve okunan her sayfanın masaldaki dizini: ailenin sesiyle
    /// kaydı varsa o çalınır (FAZ 18). Günün masalında yok.
    let storyID: UUID?
    let pageIndexes: [Int]

    init(title: String, pages: [String], storyID: UUID? = nil) {
        self.title = title
        let kept = pages.enumerated().filter { !$0.element.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        self.pages = kept.map(\.element)
        self.pageIndexes = kept.map(\.offset)
        self.storyID = storyID
    }

    init(story: Story) {
        self.init(title: story.title, pages: story.pages.map(\.text), storyID: story.id)
    }

    init(daily: DailyStory) {
        self.init(title: daily.title, pages: ReaderStory.paragraphs(of: daily.content))
    }
}

/// Uyku modunun saati: kapanma süresi ve ekranın kararması.
///
/// Son iki dakikada ekran yavaşça kararır; süre dolunca ses durur ve uyku
/// modu kapanır. Masal süreden önce biterse de kapanır.
struct MPSleepTimer: Equatable {
    static let choices = [10, 15, 20]
    static let dimWindow: TimeInterval = 120
    static let maxDim: Double = 0.85
    /// "Ekranı karart" ile (Faz 11): neredeyse siyah, yine de dokunulur.
    static let handDim: Double = 0.97

    var minutes: Int = 15

    var duration: TimeInterval { TimeInterval(minutes * 60) }

    func isOver(after elapsed: TimeInterval) -> Bool { elapsed >= duration }

    /// 0 (aydınlık) ile `maxDim` arası. Reduce Motion'da yarım dakikalık
    /// adımlarla, akıcı değil.
    func dim(after elapsed: TimeInterval, stepped: Bool = false) -> Double {
        let start = duration - Self.dimWindow
        guard elapsed > start else { return 0 }
        var t = min(1, (elapsed - start) / Self.dimWindow)
        if stepped { t = (t * 4).rounded(.down) / 4 }
        return t * Self.maxDim
    }
}

/// 26 · Uyku modu (`UykuModu`).
///
/// Koyu gece, ay ve uyuyan Ragi. Masal sayfa sayfa sesli okunur; ekran son
/// iki dakikada kararır, süre dolunca ya da masal bitince kapanır. Uyku
/// modu sürerken ekran kendiliğinden kilitlenmez; kapanınca eski hâline döner.
/// Telefon kilitlenirse masal okunmaya devam eder; kilit ekranında Live
/// Activity kalan süreyi ve Durdur'u gösterir (FAZ 19, `MPSleepPlayback`).
struct SleepModeView: View {
    let session: MPSleepSession

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var playback: MPSleepPlayback

    @Environment(\.dynamicTypeSize) private var typeSize
    /// "Ekranı karart" (Faz 11): tek dokunuşla neredeyse siyah; dokununca uyanır.
    @State private var handDimmed = false

    init(session: MPSleepSession) {
        self.session = session
        _playback = StateObject(wrappedValue: MPSleepPlayback(session: session))
    }

    private var timer: MPSleepTimer { playback.timer }
    private var elapsed: TimeInterval { playback.elapsed }
    private var isPlaying: Bool { playback.isPlaying }
    private var finished: Bool { playback.finished }

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            night
            // En büyük yazı boyutlarında içerik kaydırılır, sıkışıp kesilmez.
            GeometryReader { geo in
            ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    HStack {
                        MPCircleButton(systemImage: "xmark", accessibilityLabel: "Uyku modundan çık",
                                       bordered: false, tint: MPColor.readerNightText,
                                       fill: MPColor.readerNightTrack, action: close)
                        Spacer()
                        MPCircleButton(systemImage: "moon.zzz", accessibilityLabel: "Ekranı karart",
                                       bordered: false, tint: MPColor.readerNightText,
                                       fill: MPColor.readerNightTrack, action: dimByHand)
                    }
                    Label("Uyku modu", systemImage: "moon")
                        .mpText(.supporting).fontWeight(.heavy)
                        .foregroundStyle(MPColor.readerNightSecondary)
                        .labelStyle(SleepLabelStyle())
                }

                Spacer(minLength: MPSpacing.lg)

                ZStack(alignment: .bottom) {
                    Circle().fill(MPColor.brandStar.opacity(0.9))
                        .frame(width: 150, height: 150)
                        .offset(y: -50)
                    MascotImage(mascot: .sleeping, width: typeSize.isAccessibilitySize ? 140 : 200)
                }
                .accessibilityHidden(true)

                VStack(spacing: MPSpacing.sm) {
                    Text(finished ? "İyi uykular" : "Sesli okunuyor")
                        .mpText(.eyebrow).foregroundStyle(MPColor.readerNightSecondary)
                    Text(session.title).mpText(.page).foregroundStyle(MPColor.readerNightText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(finished ? "Ekran yavaşça kararır, masal bitince kapanır."
                         : "Ekran yavaşça kararır. \(playback.remainingMinutes) dk sonra kapanır.")
                        .mpText(.body).foregroundStyle(MPColor.readerNightSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: MPSpacing.lg)

                Button(action: playback.togglePlay) {
                    MPIcon(isPlaying ? "pause.fill" : "play.fill", size: 30, weight: .bold)
                        .foregroundStyle(MPColor.readerNightText)
                        // Ekranın tek büyük kontrolü (Faz 11, uyku kapısı).
                        .frame(width: MPSize.minTouchHero + MPSpacing.lg,
                               height: MPSize.minTouchHero + MPSpacing.lg)
                        .background(MPColor.readerNightTrack, in: Circle())
                }
                .buttonStyle(MPPressStyle())
                .accessibilityLabel(isPlaying ? "Duraklat" : "Oynat")

                VStack(spacing: MPSpacing.sm) {
                    Text("Kapanma süresi").mpText(.supporting).foregroundStyle(MPColor.readerNightSecondary)
                    MPSegmented(options: MPSleepTimer.choices.map { ($0, "\($0) dk") },
                                selection: $playback.timer.minutes, track: MPColor.readerNightTrack,
                                selectedFill: MPColor.readerNightSecondary.opacity(0.35),
                                selectedText: MPColor.readerNightText,
                                text: MPColor.readerNightSecondary)
                        .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 260)
                        .accessibilityLabel("Kapanma süresi")
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.bottom, MPSpacing.lg)
            .frame(minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            }

            // Kararma: ekranın üstünde. Süre ve masalın sonu dokunuşları
            // engellemez; elle karartılan ekran dokununca uyanır.
            MPColor.backgroundNight
                .opacity(dimLevel)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(MP.M.gated(MP.M.slow), value: dimLevel)

            if handDimmed {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture(perform: wake)
                    .accessibilityElement()
                    .accessibilityLabel("Ekranı aydınlat")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(.default, wake)
            }
        }
        .onAppear(perform: start)
        .onDisappear(perform: stop)
        .onReceive(tick) { _ in playback.tick() }
    }

    private var night: some View {
        ZStack {
            MPColor.backgroundNight.ignoresSafeArea()
            Circle().fill(MPColor.backgroundNightGlow.opacity(0.55))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(y: -80)
            ForEach(0..<14, id: \.self) { i in
                Circle().fill(MPColor.readerNightText.opacity(0.5))
                    .frame(width: 3, height: 3)
                    .position(x: CGFloat((i * 97) % 380) + 10, y: CGFloat((i * 151) % 520) + 40)
            }
        }
        .accessibilityHidden(true)
    }

    /// Süre, masalın sonu ya da el: hangisi daha karanlıksa.
    private var dimLevel: Double {
        if handDimmed { return MPSleepTimer.handDim }
        return max(timer.dim(after: elapsed, stepped: reduceMotion), playback.closingDim)
    }

    private func dimByHand() {
        handDimmed = true
        MPScreenBrightness.set(MPScreenBrightness.night)
    }

    private func wake() {
        handDimmed = false
        MPScreenBrightness.set(MPScreenBrightness.evening)
    }

    private func start() {
        UIApplication.shared.isIdleTimerDisabled = true
        // Sıcak renk yetmez, parlaklık da düşmeli (Chang 2015).
        MPScreenBrightness.save()
        MPScreenBrightness.set(MPScreenBrightness.evening)
        playback.onClose = { dismiss() }
        playback.start()
    }

    private func stop() {
        playback.stop()
        MPScreenBrightness.restore()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func close() {
        playback.close()
    }
}

/// Uyku modunda ekran parlaklığı (Faz 11). Açılışta kaydedilir, kapanışta
/// geri verilir; yalnızca düşürür, asla açılıştakinden parlak yapmaz.
@MainActor
enum MPScreenBrightness {
    /// Uyku modu açıkken.
    static let evening: CGFloat = 0.35
    /// "Ekranı karart" ile.
    static let night: CGFloat = 0.02

    private static var saved: CGFloat?

    private static var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    static func save() {
        guard saved == nil, let screen else { return }
        saved = screen.brightness
    }

    static func set(_ level: CGFloat) {
        guard let screen else { return }
        screen.brightness = min(level, saved ?? screen.brightness)
    }

    static func restore() {
        guard let saved, let screen else { return }
        screen.brightness = saved
        self.saved = nil
    }
}

private struct SleepLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MPSpacing.xs) {
            configuration.icon.foregroundStyle(MPColor.brandStar)
            configuration.title
        }
    }
}

#Preview("26 · Uyku modu") {
    SleepModeView(session: MPSleepSession(title: "Ay Işığında Uyuyan Orman",
                                          pages: ["Bir varmış bir yokmuş."]))
        .environmentObject(MPAppState())
}
