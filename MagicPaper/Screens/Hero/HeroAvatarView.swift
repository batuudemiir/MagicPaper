import SwiftUI

/// Kahraman büstü (Faz 9, Duolingo dili): kontur yok, düz renk, tek ton gölge,
/// büyük yuvarlak baş, sade ama ifadeli yüz. 200 × 220 birimlik tuvalde katman
/// katman çizilir: arka saç → kıyafet → boyun → kulak → baş → yüz → ön saç →
/// başlık → gözlük. Hareket yok; süs öğesidir, etiketi çevresinden gelir.
struct HeroAvatarView: View {
    let look: HeroLook
    /// Arkada yuvarlak zemin (sohbet balonu, kim okuyor dairesi).
    var backdrop: Color? = nil

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / HeroCanvas.width, size.height / HeroCanvas.height)
            ctx.translateBy(x: (size.width - HeroCanvas.width * s) / 2,
                            y: (size.height - HeroCanvas.height * s) / 2)
            ctx.scaleBy(x: s, y: s)
            if let backdrop {
                ctx.fill(HeroCanvas.ellipse(100, 112, 100, 100), with: .color(backdrop))
                ctx.clip(to: HeroCanvas.ellipse(100, 112, 100, 100))
            } else {
                ctx.clip(to: Path(CGRect(x: 0, y: 0, width: HeroCanvas.width, height: HeroCanvas.height)))
            }
            HeroCanvas(look: look).draw(in: &ctx)
        }
        .aspectRatio(HeroCanvas.width / HeroCanvas.height, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Çizimin kendisi: saf yol hesapları, SwiftUI görünümünden ayrı.
struct HeroCanvas {
    static let width: CGFloat = 200
    static let height: CGFloat = 220

    let look: HeroLook

    private var ink: Color { MP.C.heroInk }
    private var shade: Color { MP.C.heroInk.opacity(0.13) }
    private var white: Color { MP.C.heroWhite }

    private func pick(_ colors: [Color], _ i: Int) -> Color { colors[min(max(i, 0), colors.count - 1)] }

    private var face: Color {
        look.kind == .child ? pick(MP.C.heroSkin, look.skin) : animalFur
    }
    private var animalFur: Color {
        look.kind == .panda ? white : pick(MP.C.heroFur, look.fur)
    }
    private var hairColor: Color { pick(MP.C.heroHair, look.hairColor) }
    private var cloth: Color { pick(MP.C.heroCloth, look.topColor) }
    private var hatColor: Color { pick(MP.C.heroCloth, look.headwearColor) }

    private var showsHair: Bool { look.kind == .child && !look.headwear.hidesHair && look.hair != .none }

    // MARK: Sıra

    func draw(in ctx: inout GraphicsContext) {
        if look.headwear == .hijab { ctx.fill(Self.rrect(34, 30, 132, 190, 62), with: .color(hatColor)) }
        if showsHair { backHair(&ctx) }
        top(&ctx)
        neck(&ctx)
        ears(&ctx)
        ctx.fill(Self.ellipse(100, 98, 52, 58), with: .color(face))
        if look.kind.isAnimal { animalFace(&ctx) }
        features(&ctx)
        if showsHair { frontHair(&ctx) }
        headwear(&ctx)
        glasses(&ctx)
    }

    // MARK: Gövde

    private func neck(_ ctx: inout GraphicsContext) {
        ctx.fill(Self.rrect(84, 146, 32, 38, 10), with: .color(face))
        ctx.fill(Self.rrect(84, 146, 32, 14, 6), with: .color(shade))
    }

    private func top(_ ctx: inout GraphicsContext) {
        let shoulders = Self.rrect(30, 174, 140, 90, 46)
        switch look.top {
        case .overalls:
            ctx.fill(shoulders, with: .color(white))
            ctx.fill(Self.rrect(70, 190, 60, 40, 10), with: .color(cloth))
            ctx.fill(Self.rrect(70, 176, 9, 22, 4), with: .color(cloth))
            ctx.fill(Self.rrect(121, 176, 9, 22, 4), with: .color(cloth))
            ctx.fill(Self.ellipse(80, 198, 3.5, 3.5), with: .color(MP.C.heroGold))
            ctx.fill(Self.ellipse(120, 198, 3.5, 3.5), with: .color(MP.C.heroGold))
        default:
            ctx.fill(shoulders, with: .color(cloth))
        }
        switch look.top {
        case .tshirt, .overalls:
            ctx.fill(Self.ellipse(100, 178, 18, 9), with: .color(face))
        case .hoodie:
            ctx.fill(Self.ellipse(100, 181, 32, 13), with: .color(cloth))
            ctx.fill(Self.ellipse(100, 181, 32, 13), with: .color(shade))
            ctx.fill(Self.ellipse(100, 178, 16, 8), with: .color(face))
            var strings = Path()
            strings.move(to: CGPoint(x: 93, y: 188)); strings.addLine(to: CGPoint(x: 91, y: 206))
            strings.move(to: CGPoint(x: 107, y: 188)); strings.addLine(to: CGPoint(x: 109, y: 206))
            ctx.stroke(strings, with: .color(white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        case .collar:
            ctx.fill(Self.ellipse(100, 178, 16, 8), with: .color(face))
            ctx.fill(Self.ellipse(89, 184, 14, 8, rotation: 18), with: .color(white))
            ctx.fill(Self.ellipse(111, 184, 14, 8, rotation: -18), with: .color(white))
        case .stripes:
            var inner = ctx
            inner.clip(to: shoulders)
            for y in stride(from: 192.0, through: 220.0, by: 14.0) {
                inner.fill(Path(CGRect(x: 0, y: y, width: 200, height: 6)), with: .color(white.opacity(0.85)))
            }
            ctx.fill(Self.ellipse(100, 178, 18, 9), with: .color(face))
        case .sweater:
            ctx.fill(Self.ellipse(100, 178, 23, 11), with: .color(shade))
            ctx.fill(Self.ellipse(100, 177, 17, 8), with: .color(face))
        }
    }

    // MARK: Kulaklar

    private func ears(_ ctx: inout GraphicsContext) {
        switch look.kind {
        case .child:
            for x in [48.0, 152.0] {
                ctx.fill(Self.ellipse(x, 104, 11, 12), with: .color(face))
                ctx.fill(Self.ellipse(x, 104, 6, 7), with: .color(shade))
            }
        case .cat, .fox:
            for side in [-1.0, 1.0] {
                let ear = Self.triangle((100 + side * 48, 82), (100 + side * 40, look.kind == .fox ? 24 : 34), (100 + side * 14, 52))
                ctx.fill(ear, with: .color(face))
                let inner = Self.triangle((100 + side * 42, 74), (100 + side * 38, look.kind == .fox ? 36 : 44), (100 + side * 22, 58))
                ctx.fill(inner, with: .color(look.kind == .fox ? ink.opacity(0.8) : MP.C.heroCheek))
            }
        case .bear, .panda:
            let earColor = look.kind == .panda ? ink : face
            for x in [58.0, 142.0] {
                ctx.fill(Self.ellipse(x, 52, 19, 19), with: .color(earColor))
                ctx.fill(Self.ellipse(x, 52, 10, 10), with: .color(look.kind == .panda ? ink : shade))
            }
        case .bunny:
            for (x, rot) in [(76.0, -10.0), (124.0, 10.0)] {
                ctx.fill(Self.ellipse(x, 30, 13, 38, rotation: rot), with: .color(face))
                ctx.fill(Self.ellipse(x, 32, 6, 26, rotation: rot), with: .color(MP.C.heroCheek))
            }
        }
    }

    // MARK: Hayvan yüzü

    private func animalFace(_ ctx: inout GraphicsContext) {
        switch look.kind {
        case .panda:
            ctx.fill(Self.ellipse(78, 106, 15, 19, rotation: 24), with: .color(ink))
            ctx.fill(Self.ellipse(122, 106, 15, 19, rotation: -24), with: .color(ink))
        case .fox:
            var lower = Path()
            lower.move(to: CGPoint(x: 50, y: 112))
            lower.addQuadCurve(to: CGPoint(x: 100, y: 112), control: CGPoint(x: 80, y: 96))
            lower.addQuadCurve(to: CGPoint(x: 150, y: 112), control: CGPoint(x: 120, y: 96))
            lower.addQuadCurve(to: CGPoint(x: 100, y: 156), control: CGPoint(x: 148, y: 150))
            lower.addQuadCurve(to: CGPoint(x: 50, y: 112), control: CGPoint(x: 52, y: 150))
            ctx.fill(lower, with: .color(white))
        default:
            ctx.fill(Self.ellipse(100, 126, 24, 17), with: .color(white.opacity(0.75)))
        }
        // Burun
        let noseColor = (look.kind == .cat || look.kind == .bunny) ? MP.C.heroCheek : ink
        ctx.fill(Self.rrect(93, 112, 14, 9, 4.5), with: .color(noseColor))
        if look.kind == .cat {
            var whiskers = Path()
            for (y, dy) in [(122.0, -3.0), (128.0, 2.0)] {
                whiskers.move(to: CGPoint(x: 66, y: y + dy)); whiskers.addLine(to: CGPoint(x: 82, y: y))
                whiskers.move(to: CGPoint(x: 134, y: y + dy)); whiskers.addLine(to: CGPoint(x: 118, y: y))
            }
            ctx.stroke(whiskers, with: .color(ink.opacity(0.5)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    // MARK: Yüz

    private func features(_ ctx: inout GraphicsContext) {
        let onDark = look.kind == .panda
        let eyeColor = onDark ? white : ink
        switch look.eyes {
        case .round:
            for x in [80.0, 120.0] { roundEye(&ctx, x, 104, rx: 6, ry: 8, color: eyeColor, onDark: onDark) }
        case .big:
            for x in [80.0, 120.0] { roundEye(&ctx, x, 104, rx: 8.5, ry: 10.5, color: eyeColor, onDark: onDark) }
        case .happy:
            for x in [80.0, 120.0] { arcEye(&ctx, x, 104, up: true, color: eyeColor) }
        case .wink:
            roundEye(&ctx, 80, 104, rx: 6, ry: 8, color: eyeColor, onDark: onDark)
            arcEye(&ctx, 120, 104, up: true, color: eyeColor)
        case .sleepy:
            for x in [80.0, 120.0] { arcEye(&ctx, x, 103, up: false, color: eyeColor) }
        }

        if look.kind == .child {
            // Kaşlar: saç renginde, saçsızsa yumuşak mürekkep.
            var brows = Path()
            for x in [80.0, 120.0] {
                brows.move(to: CGPoint(x: x - 8, y: 90))
                brows.addQuadCurve(to: CGPoint(x: x + 8, y: 90), control: CGPoint(x: x, y: 84))
            }
            ctx.stroke(brows, with: .color(showsHair ? hairColor : ink.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            ctx.fill(Self.ellipse(100, 118, 4.5, 3.2), with: .color(shade))
        }

        // Yanaklar
        for x in [70.0, 130.0] { ctx.fill(Self.ellipse(x, 123, 9, 6), with: .color(MP.C.heroCheek.opacity(0.55))) }
        if look.freckles && look.kind == .child {
            for (x, y) in [(66.0, 116.0), (72, 120), (64, 122), (134, 116), (128, 120), (136, 122)] {
                ctx.fill(Self.ellipse(x, y, 1.6, 1.6), with: .color(MP.C.heroMouth.opacity(0.45)))
            }
        }
        mouth(&ctx)
    }

    private func roundEye(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                          rx: CGFloat, ry: CGFloat, color: Color, onDark: Bool) {
        ctx.fill(Self.ellipse(x, y, rx, ry), with: .color(color))
        if onDark {
            ctx.fill(Self.ellipse(x + 1, y + 1, rx * 0.5, ry * 0.5), with: .color(ink))
        } else {
            ctx.fill(Self.ellipse(x + rx * 0.35, y - ry * 0.4, rx * 0.38, rx * 0.38), with: .color(white))
        }
    }

    private func arcEye(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, up: Bool, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: x - 8, y: y + (up ? 2 : -1)))
        p.addQuadCurve(to: CGPoint(x: x + 8, y: y + (up ? 2 : -1)), control: CGPoint(x: x, y: y + (up ? -9 : 7)))
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }

    private func mouth(_ ctx: inout GraphicsContext) {
        let line = StrokeStyle(lineWidth: 4, lineCap: .round)
        switch look.mouth {
        case .smile:
            var p = Path()
            p.move(to: CGPoint(x: 89, y: 128)); p.addQuadCurve(to: CGPoint(x: 111, y: 128), control: CGPoint(x: 100, y: 140))
            ctx.stroke(p, with: .color(ink), style: line)
        case .grin:
            var d = Path()
            d.move(to: CGPoint(x: 86, y: 127)); d.addLine(to: CGPoint(x: 114, y: 127))
            d.addQuadCurve(to: CGPoint(x: 86, y: 127), control: CGPoint(x: 100, y: 152))
            ctx.fill(d, with: .color(MP.C.heroMouth))
            var inner = ctx
            inner.clip(to: d)
            inner.fill(Self.ellipse(100, 141, 9, 6), with: .color(MP.C.heroTongue))
            inner.fill(Path(CGRect(x: 86, y: 127, width: 28, height: 4)), with: .color(white))
        case .open:
            ctx.fill(Self.ellipse(100, 132, 6.5, 8.5), with: .color(MP.C.heroMouth))
        case .tongue:
            ctx.fill(Self.ellipse(104, 136, 5.5, 6.5), with: .color(MP.C.heroTongue))
            var p = Path()
            p.move(to: CGPoint(x: 89, y: 128)); p.addQuadCurve(to: CGPoint(x: 111, y: 128), control: CGPoint(x: 100, y: 140))
            ctx.stroke(p, with: .color(ink), style: line)
        case .calm:
            var p = Path()
            p.move(to: CGPoint(x: 94, y: 130)); p.addQuadCurve(to: CGPoint(x: 106, y: 130), control: CGPoint(x: 100, y: 135))
            ctx.stroke(p, with: .color(ink), style: line)
        }
    }

    // MARK: Saç

    /// Alnı örten temel saç: tepeden şakaklara, dalgalı kâkül.
    private func cap(fringeY: CGFloat = 72, templeY: CGFloat = 94) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 47, y: templeY))
        p.addCurve(to: CGPoint(x: 100, y: 36), control1: CGPoint(x: 42, y: 58), control2: CGPoint(x: 68, y: 36))
        p.addCurve(to: CGPoint(x: 153, y: templeY), control1: CGPoint(x: 132, y: 36), control2: CGPoint(x: 158, y: 58))
        p.addCurve(to: CGPoint(x: 100, y: fringeY), control1: CGPoint(x: 146, y: fringeY - 4), control2: CGPoint(x: 124, y: fringeY - 10))
        p.addCurve(to: CGPoint(x: 47, y: templeY), control1: CGPoint(x: 76, y: fringeY - 10), control2: CGPoint(x: 54, y: fringeY - 4))
        p.closeSubpath()
        return p
    }

    private func backHair(_ ctx: inout GraphicsContext) {
        let c = hairColor
        switch look.hair {
        case .long:
            ctx.fill(Self.rrect(40, 46, 120, 152, 52), with: .color(c))
            ctx.fill(Self.rrect(40, 46, 120, 152, 52), with: .color(shade))
        case .bob:
            ctx.fill(Self.rrect(42, 44, 116, 108, 46), with: .color(c))
            ctx.fill(Self.rrect(42, 44, 116, 108, 46), with: .color(shade))
        case .afro:
            ctx.fill(Self.ellipse(100, 86, 74, 70), with: .color(c))
        case .curly:
            for x in [46.0, 154.0] { ctx.fill(Self.ellipse(x, 112, 15, 16), with: .color(c)) }
        case .buns:
            for x in [62.0, 138.0] { ctx.fill(Self.ellipse(x, 40, 19, 19), with: .color(c)) }
        case .ponytail:
            ctx.fill(Self.ellipse(162, 104, 16, 34, rotation: 16), with: .color(c))
            ctx.fill(Self.ellipse(162, 104, 16, 34, rotation: 16), with: .color(shade))
        case .braids:
            for side in [-1.0, 1.0] {
                for i in 0..<5 {
                    ctx.fill(Self.ellipse(100 + side * (52 - Double(i)), 122 + Double(i) * 15, 10, 9), with: .color(c))
                }
                ctx.fill(Self.ellipse(100 + side * 48, 197, 6, 4), with: .color(MP.C.heroCheek))
            }
        default:
            break
        }
    }

    private func frontHair(_ ctx: inout GraphicsContext) {
        let c = hairColor
        switch look.hair {
        case .buzz:
            ctx.fill(cap(fringeY: 58, templeY: 84), with: .color(c.opacity(0.92)))
        case .curly:
            for deg in stride(from: 196.0, through: 344.0, by: 21.0) {
                let a = deg * .pi / 180
                ctx.fill(Self.ellipse(100 + cos(a) * 50, 92 + sin(a) * 50, 17, 17), with: .color(c))
            }
        case .spiky:
            var p = Path()
            p.move(to: CGPoint(x: 47, y: 92))
            let peaks: [(CGFloat, CGFloat)] = [(52, 50), (64, 60), (70, 28), (86, 50), (98, 18), (112, 48), (128, 26), (136, 58), (148, 46), (153, 92)]
            for (x, y) in peaks { p.addLine(to: CGPoint(x: x, y: y)) }
            p.addCurve(to: CGPoint(x: 100, y: 72), control1: CGPoint(x: 146, y: 70), control2: CGPoint(x: 124, y: 62))
            p.addCurve(to: CGPoint(x: 47, y: 92), control1: CGPoint(x: 76, y: 62), control2: CGPoint(x: 54, y: 70))
            ctx.fill(p, with: .color(c))
        case .bob:
            var p = cap(fringeY: 76, templeY: 110)
            p.addRect(CGRect(x: 0, y: 0, width: 0, height: 0))
            ctx.fill(p, with: .color(c))
        case .braids:
            ctx.fill(cap(), with: .color(c))
            var part = Path()
            part.move(to: CGPoint(x: 100, y: 38)); part.addLine(to: CGPoint(x: 100, y: 66))
            ctx.stroke(part, with: .color(shade), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        case .ponytail:
            ctx.fill(cap(), with: .color(c))
            ctx.fill(Self.ellipse(152, 84, 6, 6), with: .color(MP.C.heroCheek))
        case .afro:
            ctx.fill(cap(fringeY: 68, templeY: 96), with: .color(c))
        case .short, .long, .buns:
            ctx.fill(cap(), with: .color(c))
        case .none:
            break
        }
        // Saçın parlaklığı: tek, yumuşak bir ışık
        if look.hair != .none && look.hair != .buzz {
            ctx.fill(Self.ellipse(78, 50, 14, 6, rotation: -20), with: .color(white.opacity(0.18)))
        }
    }

    // MARK: Başlık

    private func headwear(_ ctx: inout GraphicsContext) {
        let c = hatColor
        switch look.headwear {
        case .none:
            break
        case .hijab:
            var frame = Path()
            frame.addPath(Self.ellipse(100, 100, 62, 70))
            frame.addPath(Self.ellipse(100, 108, 44, 50))
            ctx.fill(frame, with: .color(c), style: FillStyle(eoFill: true))
            var lower = Path()
            lower.addRect(CGRect(x: 30, y: 150, width: 140, height: 70))
            var inner = ctx
            inner.clip(to: Self.rrect(34, 140, 132, 90, 40))
            inner.fill(lower, with: .color(c))
            ctx.fill(Self.ellipse(100, 100, 62, 70), with: .color(shade.opacity(0.0)))
        case .beanie:
            var dome = Path()
            dome.move(to: CGPoint(x: 42, y: 70))
            dome.addCurve(to: CGPoint(x: 158, y: 70), control1: CGPoint(x: 44, y: 14), control2: CGPoint(x: 156, y: 14))
            dome.closeSubpath()
            ctx.fill(dome, with: .color(c))
            ctx.fill(Self.rrect(40, 62, 120, 22, 11), with: .color(c))
            ctx.fill(Self.rrect(40, 62, 120, 22, 11), with: .color(shade))
            ctx.fill(Self.ellipse(100, 20, 12, 12), with: .color(white))
        case .cap:
            var dome = Path()
            dome.move(to: CGPoint(x: 44, y: 70))
            dome.addCurve(to: CGPoint(x: 156, y: 70), control1: CGPoint(x: 46, y: 22), control2: CGPoint(x: 154, y: 22))
            dome.closeSubpath()
            ctx.fill(dome, with: .color(c))
            ctx.fill(Self.ellipse(132, 70, 40, 9), with: .color(c))
            ctx.fill(Self.ellipse(132, 70, 40, 9), with: .color(shade))
            ctx.fill(Self.ellipse(100, 32, 4, 4), with: .color(shade))
        case .crown:
            let crown = Self.polygon([(62, 60), (64, 26), (82, 44), (100, 18), (118, 44), (136, 26), (138, 60)])
            ctx.fill(crown, with: .color(MP.C.heroGold))
            ctx.fill(Path(CGRect(x: 62, y: 54, width: 76, height: 8)), with: .color(shade))
            for (x, y) in [(64.0, 26.0), (100, 18), (136, 26)] {
                ctx.fill(Self.ellipse(x, y, 5, 5), with: .color(MP.C.heroCheek))
            }
        case .flowers:
            let colors = [MP.C.heroCheek, white, MP.C.heroCloth[4], MP.C.heroGold, MP.C.heroCheek]
            for (i, deg) in stride(from: 205.0, through: 335.0, by: 32.5).enumerated() {
                let a = deg * .pi / 180
                let cx = 100 + cos(a) * 52, cy = 96 + sin(a) * 56
                for p in 0..<5 {
                    let pa = Double(p) * 2 * .pi / 5
                    ctx.fill(Self.ellipse(cx + cos(pa) * 6, cy + sin(pa) * 6, 5, 5), with: .color(colors[i % colors.count]))
                }
                ctx.fill(Self.ellipse(cx, cy, 3.5, 3.5), with: .color(MP.C.heroGold))
            }
        case .wizard:
            var hat = Path()
            hat.move(to: CGPoint(x: 52, y: 66))
            hat.addQuadCurve(to: CGPoint(x: 116, y: 0), control: CGPoint(x: 92, y: 40))
            hat.addQuadCurve(to: CGPoint(x: 148, y: 66), control: CGPoint(x: 120, y: 40))
            hat.closeSubpath()
            ctx.fill(hat, with: .color(c))
            ctx.fill(Self.ellipse(100, 66, 64, 10), with: .color(c))
            ctx.fill(Self.ellipse(100, 66, 64, 10), with: .color(shade))
            ctx.fill(Self.star(104, 40, 8), with: .color(MP.C.heroGold))
        }
    }

    // MARK: Gözlük

    private func glasses(_ ctx: inout GraphicsContext) {
        let stroke = StrokeStyle(lineWidth: 3.5, lineCap: .round)
        var bridge = Path()
        bridge.move(to: CGPoint(x: 93, y: 103)); bridge.addLine(to: CGPoint(x: 107, y: 103))
        switch look.glasses {
        case .none:
            return
        case .round:
            for x in [80.0, 120.0] { ctx.stroke(Self.ellipse(x, 104, 14, 14), with: .color(ink), style: stroke) }
        case .square:
            for x in [80.0, 120.0] { ctx.stroke(Self.rrect(x - 15, 93, 30, 22, 7), with: .color(ink), style: stroke) }
        case .sun:
            for x in [80.0, 120.0] {
                ctx.fill(Self.rrect(x - 15, 94, 30, 20, 9), with: .color(ink.opacity(0.92)))
                ctx.fill(Self.ellipse(x - 6, 99, 4, 2.5), with: .color(white.opacity(0.6)))
            }
        }
        ctx.stroke(bridge, with: .color(ink), style: stroke)
    }

    // MARK: Yol yardımcıları

    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, rotation: Double = 0) -> Path {
        let base = Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        let t = CGAffineTransform(translationX: cx, y: cy).rotated(by: rotation * .pi / 180)
        return base.applying(t)
    }

    static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r, style: .continuous)
    }

    static func triangle(_ a: (CGFloat, CGFloat), _ b: (CGFloat, CGFloat), _ c: (CGFloat, CGFloat)) -> Path {
        polygon([a, b, c])
    }

    static func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        guard let first = points.first else { return p }
        p.move(to: CGPoint(x: first.0, y: first.1))
        for pt in points.dropFirst() { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
        p.closeSubpath()
        return p
    }

    static func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        polygon((0..<10).map { i in
            let a = -Double.pi / 2 + Double(i) * .pi / 5
            let rr = i % 2 == 0 ? r : r * 0.45
            return (cx + cos(a) * rr, cy + sin(a) * rr)
        })
    }
}
