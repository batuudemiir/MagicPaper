import SwiftUI
import UIKit

/// Kitap karakteri — tek bir pozda, tek bir yöne bakarak (B2, Faz 2).
///
/// Katmanlar kitin sırasıyla üst üste konur (`avatar_kit.json → layerOrder`):
/// arka saç → gövde (ten) → kıyafet → yüz → ön saç → aksesuar. Renk değişimi
/// şablon boyamayla yapılır; varlık sayısı poz × biçimle sınırlı kalır, renk ×
/// biçim çarpımına çıkmaz.
///
/// İki çizim yolu:
/// - **Gerçek varlık.** Pozun zorunlu katmanlarının hepsi `Assets.xcassets/Avatar/`
///   altında varsa. Ad sözleşmesi `AvatarArt.assetName`.
/// - **Yer tutucu.** Biri bile eksikse `AvatarFigure`'ın vektör formları.
///   Yarım bir karışım çizilmez: aynı karakterin bir sayfada gerçek, ötekinde
///   geometrik olması tutarlılığı bozar.
///
/// Süs öğesidir; VoiceOver etiketi onu çevreleyen sahneden ya da kurulum
/// ekranından gelir. Hareket yok.
struct AvatarView: View {
    let spec: AvatarSpec
    var pose: String = "standing"
    /// `left` | `right`. Çizim sağa bakar; `left` aynalanır.
    var facing: String = "right"
    var kit: AvatarKit? = .bundled

    var body: some View {
        let resolved = kit?.resolved(spec) ?? spec
        let poseID = AvatarFigure.poseIDs.contains(pose) ? pose : "standing"
        let palette = AvatarArt.Palette(spec: resolved, kit: kit)

        Group {
            if let layers = AvatarArt.realLayers(pose: poseID, spec: resolved, kit: kit) {
                ZStack {
                    ForEach(layers, id: \.name) { layer in
                        AvatarArt.image(layer, palette: palette)
                    }
                }
            } else {
                AvatarPlaceholder(skeleton: AvatarFigure.skeleton(for: poseID),
                                  spec: resolved, palette: palette)
            }
        }
        .aspectRatio(1 / AvatarFigure.canvasAspect, contentMode: .fit)
        .scaleEffect(x: facing == "left" ? -1 : 1, y: 1)
        .accessibilityHidden(true)
    }
}

// MARK: - Dışa aktarma

extension AvatarView {
    /// Avatarın tuval boyutunda (512 × 768, şeffaf) görüntüsü.
    ///
    /// B1'in köprüsü: ileride `CharacterAssetSet.masterReference` olacak. Bu tur
    /// hiçbir yere bağlanmaz.
    @MainActor
    static func renderImage(spec: AvatarSpec, pose: String = "standing", facing: String = "right",
                            kit: AvatarKit? = .bundled) -> UIImage? {
        let width = CGFloat(kit?.canvas.width ?? 512)
        let height = CGFloat(kit?.canvas.height ?? 768)
        let renderer = ImageRenderer(
            content: AvatarView(spec: spec, pose: pose, facing: facing, kit: kit)
                .frame(width: width, height: height)
        )
        renderer.scale = 1
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

// MARK: - Varlık sözleşmesi

/// Gerçek avatar varlıklarının adı ve boyanması.
enum AvatarArt {

    /// `Avatar/<poz>_<katman>[_<varyant>]`. Varyant: saç katmanlarında saç
    /// biçimi, kıyafette kıyafet biçimi (`shape`), aksesuarda aksesuar kimliği.
    /// Boyanan katmanın çizgisi ayrı bir `_line` varlığıdır ve boyanmaz.
    static func assetName(pose: String, layer: String, variant: String? = nil) -> String {
        "Avatar/\(pose)_\(layer)" + (variant.map { "_\($0)" } ?? "")
    }

    /// Hangi katmanın hangi renkle boyandığı. `nil` = boyanmaz.
    enum Tint { case skin, hair, outfit }

    static func tint(for layer: String) -> Tint? {
        switch layer {
        case "body": return .skin
        case "outfit": return .outfit
        case "hairBack", "hairFront": return .hair
        default: return nil
        }
    }

    struct Layer: Equatable {
        let name: String
        let tint: Tint?
        /// Boyanmayan çizgi katmanı, varsa.
        let line: String?
    }

    struct Palette {
        let skin: Color
        let hair: Color
        let outfit: Color

        init(spec: AvatarSpec, kit: AvatarKit?) {
            func color(_ group: AvatarKit.Group, _ id: String?) -> Color {
                kit?.option(group, id: id)?.colorToken.flatMap { MP.C.avatarParts[$0] } ?? MP.C.textMuted
            }
            skin = color(.skinTone, spec.skinTone)
            hair = color(.hairColor, spec.hairColor)
            outfit = color(.outfit, spec.outfit)
        }

        func color(_ tint: Tint) -> Color {
            switch tint {
            case .skin: return skin
            case .hair: return hair
            case .outfit: return outfit
            }
        }
    }

    /// Pozun gerçek katmanları — zorunlulardan biri eksikse `nil`.
    ///
    /// Zorunlu: gövde, yüz, ön saç, kıyafet. Arka saç saç biçimine göre
    /// olmayabilir; aksesuar yalnızca seçildiyse aranır.
    @MainActor
    static func realLayers(pose: String, spec: AvatarSpec, kit: AvatarKit?,
                           assetExists: (String) -> Bool = AvatarArt.bundleHasAsset) -> [Layer]? {
        guard let kit else { return nil }
        let shape = kit.option(.outfit, id: spec.outfit)?.shape ?? "tshirt"
        var layers: [Layer] = []
        for layer in kit.layerOrder {
            let variant: String?
            let required: Bool
            switch layer {
            case "hairBack":  variant = spec.hairStyle; required = false
            case "hairFront": variant = spec.hairStyle; required = true
            case "outfit":    variant = shape;          required = true
            case "accessory":
                guard let accessory = spec.accessory else { continue }
                variant = accessory; required = false
            default:          variant = nil;            required = true
            }
            let name = assetName(pose: pose, layer: layer, variant: variant)
            guard assetExists(name) else {
                if required { return nil }
                continue
            }
            let line = name + "_line"
            layers.append(Layer(name: name, tint: tint(for: layer),
                                line: assetExists(line) ? line : nil))
        }
        return layers
    }

    @ViewBuilder
    static func image(_ layer: Layer, palette: Palette) -> some View {
        if let tint = layer.tint {
            Image(layer.name).resizable().renderingMode(.template)
                .foregroundStyle(palette.color(tint))
        } else {
            Image(layer.name).resizable()
        }
        if let line = layer.line {
            Image(line).resizable()
        }
    }

    /// Varlık kataloğu sorgusu, sonucu saklanarak: okuyucu her sayfa
    /// çevirişinde aynı adları sorar.
    @MainActor
    static func bundleHasAsset(_ name: String) -> Bool {
        if let known = existence[name] { return known }
        let found = UIImage(named: name) != nil
        existence[name] = found
        return found
    }

    @MainActor private static var existence: [String: Bool] = [:]
}

// MARK: - Yer tutucu

/// `AvatarFigure` formlarını boyar.
///
/// Gerçek varlık sözleşmesindeki katman sırasını (arka saç → gövde → kıyafet →
/// yüz → ön saç → aksesuar) izler, ama bir yer tutucunun okunur olması için
/// iki yerde ondan ayrılır: arka kol ve bacak gövdenin arkasında kalır, sırt
/// çantasının kendisi gövdenin arkasında, askısı önündedir. Sözleşme gerçek
/// varlıklar içindir.
private struct AvatarPlaceholder: View {
    let skeleton: AvatarFigure.Skeleton
    let spec: AvatarSpec
    let palette: AvatarArt.Palette

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width, y: size.width)
            ctx.concatenate(AvatarFigure.figureTransform(skeleton))
            let s = skeleton
            func round(_ width: CGFloat) -> StrokeStyle {
                StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
            }
            func fill(_ path: CGPath, _ color: Color) { ctx.fill(Path(path), with: .color(color)) }
            func stroke(_ path: CGPath, _ color: Color, _ width: CGFloat) {
                ctx.stroke(Path(path), with: .color(color), style: round(width))
            }
            func leg(_ l: AvatarFigure.Limb, in g: inout GraphicsContext) {
                g.stroke(Path(AvatarFigure.limbPath(l)), with: .color(MP.C.avatarPants), style: round(AvatarFigure.legWidth))
                g.fill(Path(AvatarFigure.shoePath(l)), with: .color(MP.C.avatarShoe))
            }
            func arm(_ l: AvatarFigure.Limb, in g: inout GraphicsContext) {
                g.stroke(Path(AvatarFigure.limbPath(l)), with: .color(palette.skin), style: round(AvatarFigure.armWidth))
                g.fill(Path(AvatarFigure.handPath(l)), with: .color(palette.skin))
                g.stroke(Path(AvatarFigure.upperLimbPath(l, fraction: 0.5)), with: .color(palette.outfit),
                         style: round(AvatarFigure.armWidth * 1.3))
            }
            /// Arka uzuvlar ayrı bir katmanda çizilir ve gölge yalnızca o katmanın
            /// piksellerine düşer (`sourceAtop`): taşmaz, üst üste binmez.
            func backLimbs() {
                ctx.drawLayer { layer in
                    leg(s.legs[0], in: &layer)
                    arm(s.arms[0], in: &layer)
                    layer.blendMode = .sourceAtop
                    layer.fill(Path(CGRect(x: -1, y: -1, width: 3, height: 4)), with: .color(MP.C.avatarShade))
                }
            }

            // Arka saç — bir ton koyu.
            let hairBack = AvatarFigure.hairPath(style: spec.hairStyle, front: false, s)
            fill(hairBack, palette.hair)
            fill(hairBack, MP.C.avatarShade)

            // Sırt çantasının gövdesi, gövdenin arkasında.
            if spec.accessory == "acc_backpack" {
                fill(AvatarFigure.backpackPath(s), MP.C.avatarBag)
            }

            // Arka uzuvlar, gövde, ön uzuvlar.
            backLimbs()
            leg(s.legs[1], in: &ctx)

            let torso = AvatarFigure.torsoPath(s)
            fill(torso, palette.outfit)
            var underChin = ctx
            underChin.clip(to: Path(torso))
            underChin.fill(Path(AvatarFigure.neckShadowPath(s)), with: .color(MP.C.avatarShade))
            if spec.accessory == "acc_backpack" {
                stroke(AvatarFigure.backpackStrapPath(s), MP.C.avatarBag, 0.035)
            }
            arm(s.arms[1], in: &ctx)

            // Baş: kulaklar ve yüz.
            fill(AvatarFigure.earsPath(s), palette.skin)
            fill(AvatarFigure.innerEarsPath(s), MP.C.avatarShade)
            let head = AvatarFigure.headPath(s)
            fill(head, palette.skin)

            // Yüz: göz, kaş, burun, ağız, yanak.
            let eyes = AvatarFigure.eyes(s)
            fill(eyes.whites, MP.C.avatarEyeWhite)
            fill(eyes.irises, MP.C.avatarIris)
            fill(eyes.pupils, MP.C.avatarInk)
            fill(eyes.highlights, MP.C.avatarHighlight)
            stroke(eyes.lids, MP.C.avatarInk, s.eyesClosed ? 0.016 : 0.013)
            stroke(AvatarFigure.eyebrowsPath(s), palette.hair, 0.02)
            stroke(AvatarFigure.eyebrowsPath(s), MP.C.avatarShade, 0.02)
            fill(AvatarFigure.nosePath(s), MP.C.avatarShade)
            let mouth = AvatarFigure.mouthPath(s)
            fill(mouth, MP.C.avatarMouth)
            if let tongue = AvatarFigure.tonguePath(s) {
                var inMouth = ctx
                inMouth.clip(to: Path(mouth))
                inMouth.fill(Path(tongue), with: .color(MP.C.avatarTongue))
            }
            fill(AvatarFigure.cheeksPath(s), MP.C.avatarCheek.opacity(0.55))

            // Ön saç, parlaması ve bağları.
            fill(AvatarFigure.hairPath(style: spec.hairStyle, front: true, s), palette.hair)
            stroke(AvatarFigure.hairHighlightPath(s), MP.C.avatarHighlight.opacity(0.35), 0.03)
            if let ties = AvatarFigure.hairTiesPath(style: spec.hairStyle, s) {
                fill(ties, palette.outfit)
            }

            // Kafa aksesuarları.
            switch spec.accessory {
            case "acc_glasses":
                stroke(AvatarFigure.glassesPath(s), MP.C.avatarInk, 0.016)
            case "acc_beanie":
                let beanie = AvatarFigure.beaniePath(s)
                fill(beanie, palette.outfit)
                fill(beanie, MP.C.avatarShade)
            default:
                break
            }
        }
    }
}

#if DEBUG
#Preview("Kitap karakteri — 8 poz") {
    let spec = AvatarSpec(skinTone: "skin_brown", hairStyle: "hair_curly", hairColor: "haircolor_black",
                          outfit: "outfit_green", accessory: "acc_glasses")
    ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: MP.S.x4) {
            ForEach(AvatarFigure.poseIDs, id: \.self) { pose in
                AvatarView(spec: spec, pose: pose).frame(height: 200)
            }
        }
        .padding(MP.S.x4)
    }
    .background(MP.C.surfaceApp)
}
#endif
