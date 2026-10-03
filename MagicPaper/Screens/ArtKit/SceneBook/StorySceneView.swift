import SwiftUI
import UIKit

/// Görselli masalın bir sayfası: hazır sahne + kitap karakteri (+ yol arkadaşı).
///
/// Okuyucu, PDF ve geliştirici galerisi bu tek görünümü kullanır. Katmanlar
/// sürümün sırasıyla çizilir (`scene_library.json → layers`): arka plan →
/// avatar → yol arkadaşı → ön plan. Avatarın ve yol arkadaşının yeri ayak
/// noktası anchor'ıdır (kadraj kesri); piksel saklanmaz.
///
/// Gerçek varlık yoksa yer tutucu çizilir: belirgin ufuk ve zemin, ortam
/// tonu. Gerçek sanat aynı sahne kimliğinin yeni sürümü olarak gelir; kod
/// değişmez.
///
/// Hareket yok. VoiceOver'a sahnenin Türkçe tarifi okunur.
struct StorySceneView: View {
    let scene: ResolvedScene
    var kit: AvatarKit? = .bundled

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                ForEach(Array(scene.version.layers.enumerated()), id: \.offset) { _, layer in
                    layerView(layer, size: size)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .aspectRatio(StorySceneView.aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: MP.R.sm, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scene.altText)
        .accessibilityAddTraits(.isImage)
    }

    /// Sahne kadrajının oranı (4:3). Manifestin `canvas.aspect`'i ile aynı;
    /// `SceneLibraryTests` denetler.
    static let aspectRatio: CGFloat = 4.0 / 3.0

    @ViewBuilder
    private func layerView(_ layer: SceneLibrary.Layer, size: CGSize) -> some View {
        switch layer.role {
        case SceneLayerRole.avatar:
            figure(anchor: scene.version.characterAnchor, size: size) { height in
                AvatarView(spec: scene.avatar, pose: scene.pose, facing: scene.plate.facing, kit: kit)
                    .frame(width: height / AvatarFigure.canvasAspect, height: height)
            }
        case SceneLayerRole.companion:
            if let anchor = scene.version.companionAnchor, scene.plate.companionID != nil {
                figure(anchor: anchor, size: size) { height in
                    CompanionView(kind: scene.plate.companionKind, facing: anchor.facing)
                        .frame(width: height, height: height)
                }
            }
        default:
            if let asset = layer.asset, StoryArtKit.bundleHasAsset(asset) {
                Image(asset).resizable().scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .blendMode(layer.blend == "multiply" ? .multiply : .normal)
            } else if layer.role == SceneLayerRole.background, let art = scene.version.placeholderArt {
                ScenePlaceholderBackground(art: art)
                    .frame(width: size.width, height: size.height)
            }
        }
    }

    /// Figürü ayak noktasından yerleştirir. `scale` kadraj yüksekliğine oranla
    /// figürün yüksekliğidir.
    private func figure<Content: View>(anchor: SceneLibrary.Anchor, size: CGSize,
                                       @ViewBuilder content: (CGFloat) -> Content) -> some View {
        let height = size.height * anchor.scale
        return content(height)
            .position(x: size.width * anchor.x, y: size.height * anchor.y - height / 2)
    }
}

// MARK: - Çözümleme

/// Bir sayfanın çizilebilir sahnesi: plate + manifestteki sürüm + avatar.
///
/// Okuyucu ve PDF, sahnenin çizilip çizilemeyeceğine buradan karar verir:
/// sahne kimliği bulunamaz, onaylı sürüm kalmamış ya da anlık görüntü
/// okunamıyorsa `nil` döner ve sayfa metin sayfası olarak açılır.
struct ResolvedScene: Equatable {
    let plate: ScenePlate
    let scene: SceneLibrary.Scene
    let version: SceneLibrary.Version
    let avatar: AvatarSpec

    var altText: String { scene.altTextTR }

    /// Çizilecek poz: plate'teki poz sahnenin izinli pozlarındaysa o, değilse
    /// sahnenin varsayılanı.
    var pose: String {
        scene.allowedPoses.contains(plate.pose) ? plate.pose : scene.defaultPose
    }

    static func resolve(_ plate: ScenePlate?, illustration: StoryIllustration?,
                        library: SceneLibrary? = .bundled) -> ResolvedScene? {
        guard let plate, let illustration, illustration.isUsable,
              let library, let scene = library.scene(plate.sceneID),
              let version = scene.renderable(pinned: plate.sceneVersion) else { return nil }
        return ResolvedScene(plate: plate, scene: scene, version: version, avatar: illustration.avatar)
    }
}

// MARK: - Dışa aktarma

extension StorySceneView {
    /// Sahnenin görüntüsü — PDF için. `ImageRenderer` ana iş parçacığı ister.
    @MainActor
    static func renderImage(_ scene: ResolvedScene, width: CGFloat, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(
            content: StorySceneView(scene: scene).frame(width: width, height: width / aspectRatio)
        )
        renderer.scale = scale
        return renderer.uiImage
    }
}

// MARK: - Yer tutucu arka plan

/// Gerçek sahne çizimi gelmeden: gökyüzü, uzak ve yakın sıra, zemin ve
/// patika, ortamın küçük işaretleri. Ufuk ve zemin belirgin olsun ki anchor
/// doğruluğu görülebilsin. Düz renk.
struct ScenePlaceholderBackground: View {
    let art: SceneLibrary.PlaceholderArt

    var body: some View {
        let tone = MP.C.sceneTones[art.tone] ?? MP.C.sceneTones["forest"]!
        ZStack {
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let horizon = h * art.horizon
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(tone.sky))

                if art.tone == "garden" {
                    // Ay ve yıldızlar.
                    ctx.fill(Path(ellipseIn: CGRect(x: w * 0.62, y: h * 0.07, width: h * 0.14, height: h * 0.14)),
                             with: .color(tone.accent))
                    for (x, y) in [(0.12, 0.12), (0.3, 0.2), (0.52, 0.09), (0.66, 0.24), (0.9, 0.36)] as [(CGFloat, CGFloat)] {
                        ctx.fill(Path(ellipseIn: CGRect(x: w * x, y: h * y, width: h * 0.012, height: h * 0.012)),
                                 with: .color(tone.accent))
                    }
                }

                // Uzak tepeler.
                var far = Path()
                far.move(to: CGPoint(x: 0, y: horizon))
                far.addCurve(to: CGPoint(x: w * 0.5, y: horizon - h * 0.06),
                             control1: CGPoint(x: w * 0.15, y: horizon - h * 0.16),
                             control2: CGPoint(x: w * 0.32, y: horizon - h * 0.02))
                far.addCurve(to: CGPoint(x: w, y: horizon - h * 0.1),
                             control1: CGPoint(x: w * 0.68, y: horizon - h * 0.11),
                             control2: CGPoint(x: w * 0.86, y: horizon - h * 0.2))
                far.addLine(to: CGPoint(x: w, y: horizon))
                far.closeSubpath()
                ctx.fill(far, with: .color(tone.far))

                // Yakın sıra: orman ve bahçede yuvarlak taçlar, çayırda yumuşak tepe.
                if art.tone == "meadow" {
                    var hill = Path()
                    hill.move(to: CGPoint(x: 0, y: horizon))
                    hill.addQuadCurve(to: CGPoint(x: w * 0.55, y: horizon),
                                      control: CGPoint(x: w * 0.25, y: horizon - h * 0.12))
                    hill.addLine(to: CGPoint(x: 0, y: horizon))
                    ctx.fill(hill, with: .color(tone.near))
                    // Şenlik bayrakları: iki direk arasında bir ip.
                    let left = CGPoint(x: w * 0.58, y: horizon - h * 0.2)
                    let right = CGPoint(x: w * 0.96, y: horizon - h * 0.24)
                    for pole in [left, right] {
                        ctx.fill(Path(CGRect(x: pole.x - w * 0.004, y: pole.y, width: w * 0.008, height: horizon - pole.y)),
                                 with: .color(MP.C.avatarShoe))
                    }
                    var rope = Path()
                    rope.move(to: left)
                    rope.addQuadCurve(to: right, control: CGPoint(x: w * 0.77, y: horizon - h * 0.12))
                    ctx.stroke(rope, with: .color(MP.C.avatarShoe), lineWidth: max(1, w * 0.003))
                    let flags: [Color] = [MP.C.avatarCheek, MP.C.companionBeak, MP.C.calm, MP.C.play]
                    for i in 0..<7 {
                        let t = CGFloat(i + 1) / 8
                        let x = left.x + (right.x - left.x) * t
                        let y = left.y + (right.y - left.y) * t + h * 0.08 * 4 * t * (1 - t) * 0.6
                        var flag = Path()
                        flag.move(to: CGPoint(x: x - w * 0.015, y: y))
                        flag.addLine(to: CGPoint(x: x + w * 0.015, y: y))
                        flag.addLine(to: CGPoint(x: x, y: y + h * 0.05))
                        flag.closeSubpath()
                        ctx.fill(flag, with: .color(flags[i % flags.count]))
                    }
                } else {
                    for (x, r) in [(0.05, 0.09), (0.17, 0.12), (0.3, 0.08), (0.74, 0.1), (0.88, 0.13), (1.0, 0.09)] as [(CGFloat, CGFloat)] {
                        let cx = w * x, rr = h * r
                        ctx.fill(Path(CGRect(x: cx - w * 0.008, y: horizon - rr, width: w * 0.016, height: rr)),
                                 with: .color(tone.accent))
                        ctx.fill(Path(ellipseIn: CGRect(x: cx - rr, y: horizon - rr * 2.4, width: rr * 2, height: rr * 2)),
                                 with: .color(tone.near))
                    }
                }

                // Zemin ve ayak çizgisine uzanan patika.
                ctx.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)), with: .color(tone.ground))
                var path = Path()
                path.move(to: CGPoint(x: w * 0.44, y: horizon))
                path.addLine(to: CGPoint(x: w * 0.52, y: horizon))
                path.addQuadCurve(to: CGPoint(x: w * 0.78, y: h), control: CGPoint(x: w * 0.56, y: h * 0.85))
                path.addLine(to: CGPoint(x: w * 0.12, y: h))
                path.addQuadCurve(to: CGPoint(x: w * 0.44, y: horizon), control: CGPoint(x: w * 0.42, y: h * 0.82))
                path.closeSubpath()
                ctx.fill(path, with: .color(tone.path))
            }

            // Ortamın onaylı süs motifleri, köşelerde ve zeminde.
            GeometryReader { geo in
                ForEach(Array(art.motifs.prefix(3).enumerated()), id: \.offset) { index, motif in
                    let spots: [CGPoint] = [CGPoint(x: 0.1, y: 0.88), CGPoint(x: 0.9, y: 0.86), CGPoint(x: 0.88, y: 0.14)]
                    // Motifler çizgi sanatı: tona göre boyanır ki gece zemininde
                    // kaybolmasın.
                    Image(motif).resizable().renderingMode(.template).scaledToFit()
                        .foregroundStyle(art.tone == "garden" ? tone.path : MP.C.textMuted)
                        .frame(width: geo.size.width * 0.14)
                        .position(x: geo.size.width * spots[index].x, y: geo.size.height * spots[index].y)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Yol arkadaşı

/// Yol arkadaşı. Gerçek varlık yoksa türüne göre sevimli bir yer tutucu;
/// tür tanınmıyorsa hiçbir şey çizilmez (sahne onsuz da geçerli).
///
/// Birim kare tuval, ayak noktası alt orta, sağa bakar; `left` aynalanır.
struct CompanionView: View {
    let kind: String?
    var facing: String = "left"

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width, y: size.height)
            func fill(_ p: Path, _ c: Color) { ctx.fill(p, with: .color(c)) }
            func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
            }
            func eyes(_ cx: CGFloat, _ cy: CGFloat, spread: CGFloat, r: CGFloat) {
                for x in [cx - spread, cx + spread] {
                    fill(oval(x, cy, r, r * 1.12), MP.C.avatarInk)
                    fill(oval(x - r * 0.35, cy - r * 0.4, r * 0.38, r * 0.38), MP.C.avatarHighlight)
                }
            }
            func cheeks(_ cx: CGFloat, _ cy: CGFloat, spread: CGFloat) {
                for x in [cx - spread, cx + spread] {
                    fill(oval(x, cy, 0.035, 0.022), MP.C.avatarCheek.opacity(0.6))
                }
            }

            switch kind {
            case "tilki":
                var tail = Path(ellipseIn: CGRect(x: 0.04, y: 0.42, width: 0.3, height: 0.44))
                tail = tail.applying(CGAffineTransform(rotationAngle: -0.25).concatenating(.init(translationX: -0.1, y: 0.05)))
                fill(tail, MP.C.companionFox)
                fill(oval(0.15, 0.48, 0.07, 0.07), MP.C.companionFoxLight)
                fill(oval(0.5, 0.78, 0.22, 0.2), MP.C.companionFox)
                fill(oval(0.54, 0.82, 0.12, 0.13), MP.C.companionFoxLight)
                for x in [0.4, 0.62] as [CGFloat] {
                    var ear = Path()
                    ear.move(to: CGPoint(x: x - 0.08, y: 0.32))
                    ear.addQuadCurve(to: CGPoint(x: x + 0.08, y: 0.32), control: CGPoint(x: x, y: 0.02))
                    ear.closeSubpath()
                    fill(ear, MP.C.companionFox)
                }
                fill(oval(0.52, 0.42, 0.21, 0.18), MP.C.companionFox)
                fill(oval(0.56, 0.5, 0.12, 0.08), MP.C.companionFoxLight)
                eyes(0.53, 0.4, spread: 0.075, r: 0.032)
                fill(oval(0.58, 0.47, 0.025, 0.018), MP.C.avatarInk)
                cheeks(0.53, 0.49, spread: 0.13)
            case "kirpi":
                var quills = Path()
                for i in 0..<11 {
                    let a = CGFloat.pi * (1.0 + CGFloat(i) / 10)
                    let base = CGPoint(x: 0.46 + cos(a) * 0.3, y: 0.7 + sin(a) * 0.26)
                    quills.addEllipse(in: CGRect(x: base.x - 0.075, y: base.y - 0.075, width: 0.15, height: 0.15))
                }
                fill(quills, MP.C.companionHedgehog)
                fill(oval(0.46, 0.72, 0.3, 0.24), MP.C.companionHedgehog)
                fill(oval(0.66, 0.74, 0.17, 0.15), MP.C.companionHedgehogFace)
                eyes(0.67, 0.7, spread: 0.06, r: 0.028)
                fill(oval(0.8, 0.77, 0.03, 0.025), MP.C.avatarInk)
                cheeks(0.67, 0.79, spread: 0.1)
                for x in [0.36, 0.6] as [CGFloat] { fill(oval(x, 0.95, 0.06, 0.035), MP.C.companionHedgehog) }
            case "tavşan":
                for (x, tilt) in [(0.42, -0.12), (0.6, 0.12)] as [(CGFloat, CGFloat)] {
                    let t = CGAffineTransform(translationX: x, y: 0.22).rotated(by: tilt)
                    fill(oval(0, 0, 0.06, 0.18).applying(t), MP.C.companionRabbit)
                    fill(oval(0, 0.02, 0.03, 0.13).applying(t), MP.C.companionRabbitInner)
                }
                fill(oval(0.5, 0.8, 0.2, 0.18), MP.C.companionRabbit)
                fill(oval(0.3, 0.84, 0.06, 0.06), MP.C.companionRabbit)
                fill(oval(0.52, 0.5, 0.19, 0.17), MP.C.companionRabbit)
                eyes(0.53, 0.48, spread: 0.07, r: 0.03)
                fill(oval(0.55, 0.55, 0.022, 0.016), MP.C.companionRabbitInner)
                cheeks(0.53, 0.56, spread: 0.12)
            case "baykuş":
                fill(oval(0.5, 0.62, 0.27, 0.32), MP.C.companionOwl)
                fill(oval(0.5, 0.72, 0.17, 0.2), MP.C.companionOwlBelly)
                for x in [0.3, 0.7] as [CGFloat] {
                    var tuft = Path()
                    tuft.move(to: CGPoint(x: x - 0.07, y: 0.38))
                    tuft.addQuadCurve(to: CGPoint(x: x + 0.07, y: 0.38), control: CGPoint(x: x, y: 0.2))
                    tuft.closeSubpath()
                    fill(tuft, MP.C.companionOwl)
                }
                for x in [0.4, 0.6] as [CGFloat] {
                    fill(oval(x, 0.5, 0.085, 0.085), MP.C.avatarEyeWhite)
                }
                eyes(0.5, 0.5, spread: 0.1, r: 0.042)
                var beak = Path()
                beak.move(to: CGPoint(x: 0.47, y: 0.58))
                beak.addLine(to: CGPoint(x: 0.53, y: 0.58))
                beak.addLine(to: CGPoint(x: 0.5, y: 0.64))
                beak.closeSubpath()
                fill(beak, MP.C.companionBeak)
                for x in [0.42, 0.58] as [CGFloat] { fill(oval(x, 0.95, 0.05, 0.03), MP.C.companionBeak) }
            default:
                break
            }
        }
        .scaleEffect(x: facing == "left" ? -1 : 1, y: 1)
        .accessibilityHidden(true)
    }
}
