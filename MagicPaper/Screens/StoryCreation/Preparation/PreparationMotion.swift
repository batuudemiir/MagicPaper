import SwiftUI
import StoryEngine

// 21 · Masal yazılıyor ekranının hareketi (26 Kasım 2026, Batuhan: "daha
// animasyonlu bir tasarım"). Sıra ve süre yine `StoryPreparationScript`'te;
// buradaki parçalar yalnızca o adımları görünür kılar:
//
// - `PreparationSky`: moda göre arkadan süzülen kâğıt yıldızlar, ışıltılar ya da yapraklar.
// - `NotebookCoverOpening`: defterin kapağı ekran açılınca soldan açılır.
// - `PageTurn`: her adımda defterin üstünden bir sayfa çevrilir.
// - `StarPath`: adım noktaları yerine ilerleyen bir yıldız yolu.
// - `CoverFlip`: masal hazır olunca kapak dönerek gelir.
//
// Hepsi Reduce Motion'da durur ya da çapraz geçişe döner (tasarım yasası,
// "Hareket"); süreler `MP.M`'den. Ragi'ye hareket eklenmez: onun kuklası kendi.

/// Arkadan süzülen kâğıt parçaları. Sürekli ama yavaş; uyku vaktinde daha az ve
/// daha yavaş. Hareketi Azalt'ta yerinde duran birkaç yıldız.
struct PreparationSky: View {
    let mode: StoryMode?
    var isBedtime = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    private struct Piece {
        let x: Double, speed: Double, phase: Double, size: Double, sway: Double, kind: Kind
    }

    private enum Kind { case star, dot, leaf }

    /// Sabit tohum: her açılışta aynı gök, rastgele titreme yok.
    private static let pieces: [Piece] = {
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        func next() -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Double(state >> 11) / Double(1 << 53)
        }
        return (0..<22).map { i in
            Piece(x: next(), speed: 0.035 + next() * 0.05, phase: next(), size: 6 + next() * 9,
                  sway: next() * .pi * 2, kind: i % 3 == 0 ? .star : (i % 3 == 1 ? .dot : .leaf))
        }
    }()

    private var tones: [Color] {
        switch mode {
        case .bedtime:   return [MPWorldTone.yellow.deep, MPWorldTone.lav.deep, MPWorldTone.sky.deep]
        case .adventure: return [MPWorldTone.green.deep, MPWorldTone.peach.deep, MPWorldTone.yellow.deep]
        case .learning:  return [MPWorldTone.yellow.deep, MPWorldTone.pink.deep, MPWorldTone.lav.deep]
        case nil:        return [MPWorldTone.lav.deep, MPWorldTone.yellow.deep, MPWorldTone.pink.deep]
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: MP.M.RagiBeat.frame, paused: reduceMotion)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSince(start) * (isBedtime ? 0.6 : 1)
            Canvas { canvas, size in
                let count = isBedtime || reduceMotion ? Self.pieces.count / 2 : Self.pieces.count
                for (i, piece) in Self.pieces.prefix(count).enumerated() {
                    // Aşağıdan yukarı; tepeye ve dibe yaklaşınca söner.
                    let rise = (piece.phase + t * piece.speed).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1.05 - rise * 1.1)
                    let x = size.width * piece.x + sin(t * 0.8 + piece.sway) * 14
                    let edgeFade = min(1, min(rise, 1 - rise) * 5)
                    let twinkle = piece.kind == .star ? 0.75 + 0.25 * sin(t * 2.4 + piece.sway) : 1
                    var c = canvas
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(sin(t * 0.6 + piece.sway) * 0.6))
                    c.opacity = 0.55 * edgeFade
                    let s = piece.size * twinkle
                    let color = tones[i % tones.count]
                    switch shape(for: piece.kind) {
                    case .star:
                        c.fill(PaperStar().path(in: CGRect(x: -s, y: -s, width: s * 2, height: s * 2)),
                               with: .color(color))
                    case .dot:
                        c.fill(Path(ellipseIn: CGRect(x: -s / 3, y: -s / 3, width: s / 1.5, height: s / 1.5)),
                               with: .color(color))
                    case .leaf:
                        c.fill(Path(roundedRect: CGRect(x: -s / 2, y: -s / 4, width: s, height: s / 2),
                                    cornerRadius: s / 4), with: .color(color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Uyku masalında yaprak yok, yıldız var; macerada yaprak çok.
    private func shape(for kind: Kind) -> Kind {
        switch (mode, kind) {
        case (.bedtime, .leaf): return .star
        case (.learning, .leaf): return .dot
        default: return kind
        }
    }
}

/// Defterin kapağı: ekran açılınca soldaki sırtından açılır ve kaybolur.
/// Hareketi Azalt'ta kapak hiç çizilmez; defter açık gelir.
struct NotebookCoverOpening: ViewModifier {
    let tone: MPWorldTone
    let symbol: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    RoundedRectangle(cornerRadius: MP.R.card, style: .continuous)
                        .fill(tone.deep)
                        .overlay {
                            MPIcon(symbol, size: MP.G.hero, weight: .semibold)
                                .foregroundStyle(MP.C.surfaceCard)
                        }
                        .rotation3DEffect(.degrees(open ? -110 : 0), axis: (x: 0, y: 1, z: 0),
                                          anchor: .leading, perspective: 0.45)
                        .opacity(open ? 0 : 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .task {
                guard !reduceMotion, !open else { return }
                try? await Task.sleep(for: .seconds(MP.M.RagiBeat.reveal))
                withAnimation(MP.M.page) { open = true }
            }
    }
}

/// Her adımda defterin üstünden bir sayfa çevrilir: sağdan kalkar, sola yatar.
struct PageTurn<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase: CaseIterable { case rest, lift, turned }

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                RoundedRectangle(cornerRadius: MP.R.card, style: .continuous)
                    .fill(MP.C.surfaceCard)
                    .overlay {
                        RoundedRectangle(cornerRadius: MP.R.card, style: .continuous)
                            .strokeBorder(MP.C.borderHairline, lineWidth: 1)
                    }
                    .phaseAnimator(Phase.allCases, trigger: trigger) { page, phase in
                        page
                            .rotation3DEffect(.degrees(phase == .turned ? -170 : (phase == .lift ? -12 : 0)),
                                              axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.5)
                            .opacity(phase == .lift ? 0.9 : 0)
                    } animation: { phase in
                        switch phase {
                        case .lift: MP.M.press
                        case .turned: MP.M.page
                        case .rest: nil
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Adımların yolu: dolan bir çizgi ve ucunda kâğıt yıldız. Yüzde ve süre
/// söylemez; bilgi durum cümlesinde, yol süs.
struct StarPath: View {
    let count: Int
    let current: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: CGFloat {
        guard count > 0 else { return 0 }
        return CGFloat(min(current + 1, count)) / CGFloat(count)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let star = MP.S.x5
            ZStack(alignment: .leading) {
                Capsule().fill(MP.C.borderHairline).frame(height: MP.S.x2)
                Capsule().fill(MP.C.brand).frame(width: max(MP.S.x2, width * fraction), height: MP.S.x2)
                PaperStar()
                    .fill(MPWorldTone.yellow.deep)
                    .frame(width: star, height: star)
                    .rotationEffect(.degrees(reduceMotion ? 0 : Double(current) * 72))
                    .offset(x: min(max(0, width * fraction - star / 2), width - star))
            }
            .frame(height: star)
        }
        .frame(height: MP.S.x5)
        .animation(MP.M.gated(MP.M.spring) ?? MP.M.base, value: current)
        .accessibilityHidden(true)
    }
}

/// Masal hazır: kapak dikey eksende dönerek, biraz küçükten gelir.
struct CoverFlip: ViewModifier {
    let angle: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .scaleEffect(scale)
            .opacity(angle >= 89 ? 0 : 1)
    }
}

extension AnyTransition {
    /// Kapağın gelişi; Hareketi Azalt'ta çapraz geçiş.
    static func coverFlip(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .modifier(active: CoverFlip(angle: 90, scale: 0.7), identity: CoverFlip(angle: 0, scale: 1)),
            removal: .opacity)
    }
}
