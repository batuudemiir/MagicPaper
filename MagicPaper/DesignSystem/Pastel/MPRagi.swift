// MPRagi.swift
// Ragi'nin hareketi. Çizim aynı, üstüne kukla: nefes, göz kırpma, baş, kuyruk ve kol.
// Kurallar ve poz tablosu: docs/RAGI.md. Ekranlar bunu `MascotImage` üstünden kullanır.

import SwiftUI

/// Ragi'nin o anki işi. Poz değil, hareket; tek duygu kuralı poz seçiminde kalır.
enum RagiAct: String, CaseIterable {
    case still, idle, wave, cheer, read, write, sleep, walk
}

extension Mascot {
    /// Pozun doğal hareketi. Ekran isterse başka bir hareket verir.
    var defaultAct: RagiAct {
        switch self {
        case .waving: .wave
        case .reading, .onBook: .read
        case .pencil: .write
        case .sleeping, .sleepy: .sleep
        case .walking: .walk
        default: .idle
        }
    }
}

/// Bir anın hareket değerleri. Açılar radyan, `hop` ve `squash` Ragi'nin genişliğine oran.
struct RagiFrame: Equatable {
    var head = 0.0, tail = 0.0, arm = 0.0
    var breath = 0.0
    var hop = 0.0, squash = 0.0
    /// 0 açık, 1 kapalı.
    var blink = 0.0
}

/// Saf hareket modeli: zamandan değere. Çizimden ve SwiftUI'dan bağımsız, test edilir.
enum RagiMotion {

    static func frame(act: RagiAct, t: Double, seed: Double) -> RagiFrame {
        guard act != .still else { return RagiFrame() }
        var f = RagiFrame()
        let beat = MP.M.RagiBeat.self
        f.breath = wave(t, period: act == .sleep ? beat.sleepBreath : beat.breath) * (act == .sleep ? 0.022 : 0.012)
        f.blink = act == .sleep ? 0 : blink(t: t, seed: seed)
        f.tail = wave(t + seed * 3, period: beat.tail) * (act == .sleep ? 0.012 : 0.06)
        f.head = wave(t + seed * 5, period: beat.head) * (act == .sleep ? 0 : 0.016)

        switch act {
        case .wave:
            // İki kez sallar, sonra kolu yavaşça dinlenir; ara ara yeniden selam verir.
            let local = t.truncatingRemainder(dividingBy: beat.waveEvery)
            if local < beat.waveLength {
                let envelope = sin(.pi * local / beat.waveLength)
                f.arm = wave(local, period: beat.waveSwing) * 0.2 * envelope
                f.head += 0.03 * envelope
            }
        case .cheer:
            // İki küçük zıplama; sonra sakin nefes. Sürekli zıplamaz.
            if t < beat.hop * 2 {
                let phase = (t / beat.hop).truncatingRemainder(dividingBy: 1)
                let height = t < beat.hop ? 0.085 : 0.05
                f.hop = sin(.pi * phase) * height
                // Yere değerken kısa basılır, havada uzar.
                f.squash = (phase < 0.12 || phase > 0.88) ? -0.03 : 0.02
                f.head += wave(t, period: beat.hop) * 0.04
            }
        case .read:
            f.head += wave(t, period: beat.read) * 0.022
        case .write:
            f.arm = wave(t, period: beat.write) * 0.05
            f.head += wave(t, period: beat.read) * 0.015
        case .walk:
            f.hop = abs(wave(t, period: beat.step)) * 0.012
        case .idle, .sleep, .still:
            break
        }
        return f
    }

    /// Her `blinkEvery` civarı bir kırpma; `seed` iki Ragi'yi aynı anda kırptırmaz.
    static func blink(t: Double, seed: Double) -> Double {
        let beat = MP.M.RagiBeat.self
        let every = beat.blinkEvery + seed * 1.6
        let phase = (t + seed * every).truncatingRemainder(dividingBy: every)
        guard phase < beat.blink else { return 0 }
        return sin(.pi * phase / beat.blink)
    }

    private static func wave(_ t: Double, period: Double) -> Double {
        sin(2 * .pi * t / period)
    }
}

/// Bir pozun kukla bilgisi. Koordinatlar görselin genişlik ve yüksekliğine oran;
/// yarıçaplar genişliğe oran. Boş kemik hiç oynamaz.
struct RagiRig {
    struct Bone { let pivot: CGPoint, center: CGPoint, radius: CGFloat }
    struct Eye { let center: CGPoint, rx: CGFloat, ry: CGFloat }

    var head: Bone?
    var tail: Bone?
    var arm: Bone?
    var eyes: [Eye] = []

    private static func bone(_ px: CGFloat, _ py: CGFloat, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Bone {
        Bone(pivot: CGPoint(x: px, y: py), center: CGPoint(x: cx, y: cy), radius: r)
    }
    private static func eye(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Eye {
        Eye(center: CGPoint(x: x, y: y), rx: rx, ry: ry)
    }

    /// Yeni çizim gelince yalnızca bu tablo değişir.
    static func of(_ mascot: Mascot) -> RagiRig {
        switch mascot {
        case .front:
            RagiRig(head: bone(0.63, 0.48, 0.64, 0.26, 0.42), tail: bone(0.42, 0.74, 0.14, 0.66, 0.4),
                    eyes: [eye(0.565, 0.335, 0.066, 0.078), eye(0.775, 0.31, 0.066, 0.078)])
        case .waving:
            RagiRig(head: bone(0.49, 0.5, 0.55, 0.28, 0.42), tail: bone(0.76, 0.78, 0.94, 0.74, 0.22),
                    arm: bone(0.24, 0.5, 0.06, 0.34, 0.2),
                    eyes: [eye(0.39, 0.295, 0.08, 0.075), eye(0.62, 0.375, 0.085, 0.08)])
        case .threeQuarter:
            RagiRig(head: bone(0.68, 0.47, 0.7, 0.26, 0.4), tail: bone(0.34, 0.74, 0.12, 0.68, 0.34),
                    eyes: [eye(0.65, 0.3, 0.075, 0.08), eye(0.85, 0.25, 0.06, 0.07)])
        case .reading:
            RagiRig(head: bone(0.52, 0.52, 0.5, 0.26, 0.45), tail: bone(0.2, 0.86, 0.06, 0.86, 0.2),
                    eyes: [eye(0.43, 0.42, 0.075, 0.05), eye(0.73, 0.42, 0.06, 0.05)])
        case .pencil:
            RagiRig(head: bone(0.48, 0.52, 0.5, 0.3, 0.42), arm: bone(0.68, 0.66, 0.84, 0.5, 0.3),
                    eyes: [eye(0.4, 0.405, 0.075, 0.07), eye(0.64, 0.33, 0.07, 0.065)])
        case .onBook:
            RagiRig(head: bone(0.4, 0.52, 0.42, 0.3, 0.32), tail: bone(0.72, 0.62, 0.9, 0.5, 0.22),
                    eyes: [eye(0.285, 0.3, 0.05, 0.06), eye(0.48, 0.365, 0.06, 0.07)])
        case .walking:
            RagiRig(head: bone(0.66, 0.5, 0.76, 0.26, 0.28), tail: bone(0.4, 0.66, 0.14, 0.66, 0.3),
                    eyes: [eye(0.74, 0.3, 0.05, 0.065), eye(0.88, 0.24, 0.035, 0.055)])
        case .happy:
            RagiRig(head: bone(0.5, 0.95, 0.5, 0.45, 0.9),
                    eyes: [eye(0.365, 0.54, 0.075, 0.09), eye(0.73, 0.46, 0.075, 0.09)])
        case .curious:
            RagiRig(head: bone(0.5, 0.95, 0.5, 0.42, 0.9),
                    eyes: [eye(0.52, 0.505, 0.08, 0.085), eye(0.78, 0.4, 0.06, 0.075)])
        case .calm:
            RagiRig(head: bone(0.5, 0.95, 0.5, 0.45, 0.9),
                    eyes: [eye(0.37, 0.53, 0.08, 0.09), eye(0.68, 0.53, 0.08, 0.09)])
        case .surprised:
            RagiRig(head: bone(0.5, 0.95, 0.5, 0.45, 0.9),
                    eyes: [eye(0.4, 0.48, 0.09, 0.09), eye(0.717, 0.455, 0.08, 0.09)])
        case .thinking:
            RagiRig(head: bone(0.5, 0.95, 0.5, 0.38, 0.8),
                    eyes: [eye(0.52, 0.5, 0.08, 0.085), eye(0.78, 0.38, 0.065, 0.075)])
        case .sleeping, .sleepy:
            RagiRig()
        }
    }
}

private struct RagiHoldsStillKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    /// Görüntü testleri için: Ragi kımıldamaz, kare her koşuda aynı.
    var ragiHoldsStill: Bool {
        get { self[RagiHoldsStillKey.self] }
        set { self[RagiHoldsStillKey.self] = newValue }
    }
}

/// Canlı Ragi. Reduce Motion, düşük güç modunda ve `still` işinde düz çizim: anlam kaybolmaz,
/// Ragi yerinde durur.
struct RagiPuppet: View {
    let mascot: Mascot
    let width: CGFloat
    let act: RagiAct

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.ragiHoldsStill) private var holdsStill
    @State private var start = Date()
    @State private var seed = Double.random(in: 0...1)

    private var moves: Bool {
        guard act != .still, !reduceMotion, !holdsStill, !ProcessInfo.processInfo.isLowPowerModeEnabled else { return false }
        #if DEBUG
        // UI testleri sürekli hareket eden ekranda durgunluk beklerken takılır.
        if MPDebugLaunch.isDemo && !MPDebugLaunch.ragiStudio { return false }
        #endif
        return true
    }

    var body: some View {
        if moves {
            TimelineView(.animation(minimumInterval: MP.M.RagiBeat.frame)) { context in
                let f = RagiMotion.frame(act: act, t: context.date.timeIntervalSince(start), seed: seed)
                drawing(blink: f.blink)
                    .modifier(RagiBonesEffect(rig: RagiRig.of(mascot), frame: f, width: width))
                    .scaleEffect(x: 1 - f.breath * 0.5 - f.squash * 0.6,
                                 y: 1 + f.breath + f.squash, anchor: .bottom)
                    .offset(y: -f.hop * width)
            }
            .onChange(of: act) { _, _ in start = Date() }
        } else {
            drawing(blink: 0)
        }
    }

    private func drawing(blink: Double) -> some View {
        Image(mascot.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .overlay {
                if blink > 0 { RagiEyelids(eyes: RagiRig.of(mascot).eyes, closed: blink) }
            }
    }
}

/// Göz kapakları: göz bandının rengiyle kapanır, altta ince bir kirpik çizgisi kalır.
private struct RagiEyelids: View {
    let eyes: [RagiRig.Eye]
    let closed: Double

    var body: some View {
        Canvas { context, size in
            for eye in eyes {
                let rx = eye.rx * size.width
                let ry = eye.ry * size.width
                let c = CGPoint(x: eye.center.x * size.width, y: eye.center.y * size.height)
                // Kapak yukarıdan iner: yükseklik büyür, merkez yukarıda başlar.
                let height = 2 * ry * closed
                let rect = CGRect(x: c.x - rx, y: c.y - ry, width: 2 * rx, height: height)
                context.fill(Path(ellipseIn: rect), with: .color(MP.C.ragiLid))
                if closed > 0.7 {
                    var lash = Path()
                    lash.move(to: CGPoint(x: c.x - rx * 0.7, y: c.y))
                    lash.addQuadCurve(to: CGPoint(x: c.x + rx * 0.7, y: c.y),
                                      control: CGPoint(x: c.x, y: c.y + ry * 0.45))
                    context.stroke(lash, with: .color(MP.C.ragiLash),
                                   style: StrokeStyle(lineWidth: max(1, size.width * 0.012), lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RagiBonesEffect: ViewModifier {
    let rig: RagiRig
    let frame: RagiFrame
    let width: CGFloat

    func body(content: Content) -> some View {
        content.visualEffect { [rig, frame, width] effect, proxy in
            let size = proxy.size
            let (hp, ha) = Self.args(rig.head, frame.head, size)
            let (tp, ta) = Self.args(rig.tail, frame.tail, size)
            let (ap, aa) = Self.args(rig.arm, frame.arm, size)
            return effect.distortionEffect(
                ShaderLibrary.ragiBones(hp, ha, tp, ta, ap, aa),
                maxSampleOffset: CGSize(width: width * 0.25, height: width * 0.25))
        }
    }

    nonisolated private static func args(_ bone: RagiRig.Bone?, _ angle: Double, _ size: CGSize) -> (Shader.Argument, Shader.Argument) {
        guard let bone else { return (.float3(0, 0, 0), .float3(0, 0, 0)) }
        return (.float3(bone.pivot.x * size.width, bone.pivot.y * size.height, angle),
                .float3(bone.center.x * size.width, bone.center.y * size.height, bone.radius * size.width))
    }
}
