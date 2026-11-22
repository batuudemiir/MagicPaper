import SwiftUI

/// Tam boy kahramanın çizimi (`kahraman.js`'in birebir karşılığı, 22 Kasım 2026).
///
/// Her şey 240 × 360 birimlik ortak sahnede: boyalı PNG parçalar (`HeroFigure/*`
/// asset'leri) ve kodla çizilen beden, yüz, örtü, gözlük, çanta, çizilen giysiler.
/// Katman sırası: beden → ayakkabı → alt → üst ya da tek parça → çanta → yüz →
/// saç → başlık → gözlük. Başörtüsü saçı örter; şapka saçın tepesini keser.
/// Tam boy, yakın yüz ve profil büstü aynı çizimin üç kadrajıdır.
struct HeroFigureArt {
    let figure: HeroFigure
    var catalog: HeroFigureCatalog = .shared

    /// Kadraj: sahnenin görünen dikdörtgeni (SVG `viewBox`).
    enum Frame: Equatable {
        case body, face, bust
        case custom(CGRect)

        var rect: CGRect {
            switch self {
            case .body: CGRect(x: 47, y: 4, width: 146, height: 343)
            case .face: CGRect(x: 53, y: 15, width: 134, height: 147)
            case .bust: CGRect(x: 51, y: 15, width: 138, height: 169)
            case .custom(let rect): rect
            }
        }
    }

    /// Kadrajı `size`'a sığdırır (ortalanmış, oran korunur) ve çizer.
    func draw(in context: inout GraphicsContext, frame: Frame, size: CGSize) {
        let box = frame.rect
        let s = min(size.width / box.width, size.height / box.height)
        var ctx = context
        ctx.translateBy(x: (size.width - box.width * s) / 2 - box.minX * s,
                        y: (size.height - box.height * s) / 2 - box.minY * s)
        ctx.scaleBy(x: s, y: s)
        ctx.clip(to: Path(box))
        draw(in: &ctx)
    }

    // MARK: - Renkler

    private func hex(_ slot: HeroFigure.Slot, fallback: UInt32) -> HeroRGB {
        catalog.option(figure[slot], in: slot)?.hex.flatMap(HeroRGB.init(string:)) ?? HeroRGB(fallback)
    }
    private var skin: HeroRGB { hex(.skin, fallback: 0xDB9D71) }
    private var iris: HeroRGB { hex(.eye, fallback: 0x754633) }
    private var hairColor: HeroRGB { hex(.dye, fallback: 0x76442F) }
    private var shade: HeroRGB { skin.tint(HeroInk.shadeTarget, 0.27) }
    private var lip: HeroRGB { skin.tint(HeroInk.lipTarget, 0.65) }
    private var brow: HeroRGB { hairColor.tint(HeroInk.browTarget, 0.30) }

    /// "top-7" → 7
    private static func nth(_ id: String) -> Int { Int(id.split(separator: "-").last ?? "") ?? 0 }

    // MARK: - Sıra

    func draw(in ctx: inout GraphicsContext) {
        body(&ctx)
        shoes(&ctx)
        clothes(&ctx)
        bag(&ctx)
        faceBase(&ctx)
        features(&ctx)
        if !figure.isHijab { hair(&ctx) }
        covering(&ctx)
        glasses(&ctx)
    }

    // MARK: - Beden

    private func body(_ ctx: inout GraphicsContext) {
        fill(&ctx, "M110 128Q115 144 110 150Q120 164 130 150Q125 142 130 128Z", shade)
        flesh(&ctx, "M99 208Q115 210 116 225L111 320Q105 327 98 320L99 268Q94 235 99 208Z")
        flesh(&ctx, "M124 213Q133 207 143 214Q149 245 141 272L141 320Q135 328 128 320L125 264Z")
        flesh(&ctx, "M99 155Q92 154 86 170L76 211Q72 219 76 223Q80 228 84 222L85 216Q86 220 88 216L88 209L101 174Z")
        flesh(&ctx, "M141 155Q148 154 154 170L164 211Q168 219 164 223Q160 228 156 222L155 216Q154 220 152 216L152 209L139 174Z")
    }

    private func shoes(_ ctx: inout GraphicsContext) {
        let heights: [CGFloat] = [31, 22, 17, 38, 18, 19]
        let n = Self.nth(figure[.shoe])
        guard heights.indices.contains(n - 1) else { return }
        let h = heights[n - 1]
        image(&ctx, figure[.shoe], 94, 338 - h, 53, h)
    }

    private func clothes(_ ctx: inout GraphicsContext) {
        if !figure.wearsOnePiece {
            let bottom = Self.nth(figure[.bottom])
            let bounds: [[CGFloat]] = [[93, 213, 54, 101], [81, 212, 79, 55], [91, 213, 58, 44],
                                       [80, 212, 80, 83], [94, 213, 53, 102], [89, 213, 62, 99]]
            if bottom >= 1 && bottom <= 6 {
                let b = bounds[bottom - 1]
                image(&ctx, figure[.bottom], b[0], b[1], b[2], b[3])
            } else if bottom >= 7 {
                drawnBottom(&ctx, bottom)
            }
            let top = Self.nth(figure[.top])
            if top >= 1 && top <= 6 {
                image(&ctx, figure[.top], 79, 147, 82, 81)
            } else if top >= 7 {
                drawnTop(&ctx, top)
            }
        } else {
            let coords: [[CGFloat]] = [[77, 148, 86, 119], [80, 148, 80, 112], [76, 148, 88, 139],
                                       [78, 148, 84, 124], [75, 148, 90, 132], [72, 147, 96, 172]]
            let one = Self.nth(figure[.one])
            guard coords.indices.contains(one - 1) else { return }
            if figure[.one] == "one-6" {
                stroke(&ctx, "M100 158Q86 163 78 214M140 158Q154 163 162 214", HeroInk.spaceSleeve, 10)
            }
            let c = coords[one - 1]
            image(&ctx, figure[.one], c[0], c[1], c[2], c[3])
            if figure[.one] == "one-6" {
                fleshEllipse(&ctx, 79, 229, 3.8, 5)
                fleshEllipse(&ctx, 161, 229, 3.8, 5)
            }
        }
    }

    private func drawnTop(_ ctx: inout GraphicsContext, _ i: Int) {
        guard HeroInk.tops.indices.contains(i - 7) else { return }
        let c = HeroInk.tops[i - 7]
        fill(&ctx, "M108 148Q120 159 132 148L147 154Q153 159 160 187L148 192L151 227Q120 235 89 227L92 192L80 187Q86 161 94 154Z", c)
        stroke(&ctx, "M110 150Q120 160 130 150", c.tint(HeroInk.foldInk, 0.35), 2)
        stroke(&ctx, "M93 224q26 5 54 0", c.tint(HeroInk.foldInk, 0.22))
        switch i {
        case 7:
            for y in [172, 181, 190, 199, 208, 217] { stroke(&ctx, "M92 \(y)q26 4 56 0", HeroInk.stripe, 3) }
        case 8:
            fill(&ctx, "M101 152Q117 137 137 152L130 165L120 159L112 166Z", HeroInk.hood)
            stroke(&ctx, "M110 205q10 3 20 0l5 9q-16 4 -30 0z", HeroInk.pocket)
        case 9, 10:
            stroke(&ctx, "M120 155v72", c.tint(HeroInk.placket, 0.35), 2)
            for y in [174, 187, 200, 213] { ellipse(&ctx, 123, CGFloat(y), 1.6, 1.6, HeroInk.button) }
            stroke(&ctx, "M95 204q6 3 13 0M132 204q6 3 13 0", HeroInk.cuff, 3)
        case 11:
            fill(&ctx, "M120 173l3 8 9 1 -7 6 2 9 -7 -5 -8 5 2 -9 -6 -6 8 -1z", HeroInk.star)
        case 12:
            fill(&ctx, "M106 152q3 16 14 6 11 10 15 -6l-15 5z", HeroInk.collar)
            stroke(&ctx, "M95 218q25 5 50 0", HeroInk.hem, 2.6)
        default:
            break
        }
    }

    private func drawnBottom(_ ctx: inout GraphicsContext, _ i: Int) {
        guard HeroInk.bottoms.indices.contains(i - 7) else { return }
        let c = HeroInk.bottoms[i - 7]
        if i == 8 || i == 10 {
            fill(&ctx, "M98 215Q118 221 142 215L157 266Q120 277 83 266Z", c)
            for (j, x) in [98, 112, 126, 140].enumerated() {
                let dx = (Double(j) - 1.5) * 4
                stroke(&ctx, "M\(x) 225l\(dx) 39", c.tint(HeroInk.pleat, 0.25))
            }
        } else {
            fill(&ctx, "M96 214H144L144 314Q136 318 126 314L119 251L113 314Q103 317 95 313Z", c)
            stroke(&ctx, "M99 221h39M139 230l1 78", c.tint(HeroInk.seam, 0.35), 2)
        }
    }

    private func bag(_ ctx: inout GraphicsContext) {
        let n = Self.nth(figure[.bag])
        guard figure[.bag] != "none", HeroInk.bags.indices.contains(n - 1) else { return }
        let c = HeroInk.bags[n - 1]
        stroke(&ctx, "M101 152Q120 187 145 207", HeroInk.strap, 4)
        fill(&ctx, "M135 198q10 -2 20 1l1 22q-9 5 -22 0z", c)
        fill(&ctx, "M134 198q11 -4 22 1l-2 8q-9 5 -20 -2z", c.tint(HeroInk.bagLight, 0.22))
        ellipse(&ctx, 146, 207, 1.6, 1.6, HeroInk.clasp)
    }

    // MARK: - Yüz

    private static let heads = [
        "M82 92Q80 55 120 54Q160 55 158 92Q159 122 140 135Q120 149 99 136Q81 124 82 92Z",
        "M85 90Q82 54 120 52Q158 54 155 90Q156 123 139 137Q120 152 101 137Q84 121 85 90Z",
        "M82 90Q83 55 120 54Q157 55 158 90L155 120Q151 138 129 141Q105 146 91 132Q82 122 82 90Z",
        "M80 89Q80 54 120 53Q158 54 160 89Q161 110 143 128Q128 145 120 146Q110 143 96 130Q78 113 80 89Z"
    ]

    private func faceBase(_ ctx: inout GraphicsContext) {
        fleshEllipse(&ctx, 82, 102, 6.5, 9)
        fleshEllipse(&ctx, 158, 102, 6.5, 9)
        let face = Self.nth(figure[.face])
        flesh(&ctx, Self.heads[min(max(face, 1), Self.heads.count) - 1])
        blush(&ctx, 95, 113)
        blush(&ctx, 145, 113)
    }

    private func features(_ ctx: inout GraphicsContext) {
        eye(&ctx, x: 105, mirror: false)
        eye(&ctx, x: 135, mirror: true)

        let browIndex = min(max(Self.nth(figure[.brow]), 1), 4)
        let widths: [CGFloat] = [2.5, 2.4, 3.7, 2.5]
        let lefts = ["M97 88q7 -5 14 -2", "M97 87l14 -1", "M96 88q7 -6 16 -2", "M99 88q5 -5 10 -3"]
        let expression = Self.nth(figure[.expression])
        stroke(&ctx, lefts[browIndex - 1], brow, widths[browIndex - 1])
        var mirrored = ctx
        mirrored.translateBy(x: 240, y: expression == 3 ? -2 : 0)
        mirrored.scaleBy(x: -1, y: 1)
        stroke(&mirrored, lefts[browIndex - 1], brow, widths[browIndex - 1])

        let noses = ["M119 105q-3 7 2 7", "M117 110q-2 6 5 4q3 -1 2 -3", "M120 104q0 6 -3 9q3 2 6 0"]
        stroke(&ctx, noses[min(max(Self.nth(figure[.nose]), 1), 3) - 1], shade, 1.9)

        if expression == 2 {
            fill(&ctx, "M110 121q11 4 21 -1q-2 12 -12 10q-7 -1 -9 -9z", lip)
            fill(&ctx, "M113 122q9 2 16 0q-5 4 -15 3z", HeroInk.teeth)
        } else {
            stroke(&ctx, expression == 3 ? "M115 124q5 -3 11 -1" : "M110 122q10 9 21 -1", lip, 2)
        }

        let detail = figure[.detail]
        if detail == "mark-1" || detail == "mark-4" {
            var freckles = ctx
            freckles.opacity = 0.55
            for (x, y) in [(95, 111), (100, 113), (105, 111), (136, 111), (142, 113), (147, 110), (97, 115), (140, 116)] {
                ellipse(&freckles, CGFloat(x), CGFloat(y), 0.9, 0.8, brow)
            }
        }
        if detail == "mark-2" { stroke(&ctx, "M107 124q0 3 3 3M133 124q0 3 -2 3", shade, 1.3) }
        if detail == "mark-3" || detail == "mark-4" { ellipse(&ctx, 143, 120, 1.35, 1.3, brow) }
    }

    private func eye(_ ctx: inout GraphicsContext, x: CGFloat, mirror: Bool) {
        let shape = min(max(Self.nth(figure[.eyeShape]), 1), 3)
        let sy: [CGFloat] = [1, 0.72, 0.85]
        let sx: [CGFloat] = [1, 1.16, 1.04]
        var e = ctx
        e.translateBy(x: x, y: 100)
        e.scaleBy(x: (mirror ? -1 : 1) * sx[shape - 1], y: sy[shape - 1])
        fill(&e, "M-8 1Q-7 -8 0 -8Q8 -8 8 1Q6 7 0 7Q-6 7 -8 1Z", HeroInk.eyeWhite)
        ellipse(&e, 0.3, 0, 5.8, 7, iris)
        ellipse(&e, 0.4, 0.2, 3.1, 4.4, HeroInk.pupil)
        ellipse(&e, -1.2, -2.4, 1.6, 1.7, HeroInk.eyeShine)
        stroke(&e, "M-8 0Q-5 -10 3 -8Q7 -7 8 -3", brow, 1.8)
    }

    // MARK: - Saç ve başlık

    private func hair(_ ctx: inout GraphicsContext) {
        var layer = ctx
        // Şapkanın tepesinden topuz çıkmasın: saçın üstü kesilir.
        if figure.isHat { layer.clip(to: Path(CGRect(x: 0, y: 78, width: 240, height: 280))) }
        let id = figure[.hair]
        if id == "crop" {
            fill(&layer, "M81 93Q76 53 119 51Q161 52 159 94Q149 76 136 78Q113 69 97 79Q89 80 81 93Z", hairColor)
            return
        }
        guard id != "bald" else { return }
        if id == "hair-4" {
            fill(&layer, "M82 92Q77 51 119 50Q162 50 158 94Q151 79 140 79Q122 70 104 80Q90 78 82 92Z", hairColor)
        }
        let fits: [[CGFloat]] = [[73, 44, 94, 79], [68, 41, 104, 88], [73, 50, 94, 130],
                                 [53, 45, 134, 85], [60, 48, 120, 110], [74, 23, 92, 94]]
        let n = Self.nth(id)
        guard fits.indices.contains(n - 1) else { return }
        let f = fits[n - 1]
        let rect = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
        if figure[.dye] == "chestnut" {
            layer.draw(Image("HeroFigure/\(id)"), in: rect)
        } else if let dyed = HeroHairDye.image(hair: id, colors: dyeTable) {
            layer.draw(Image(uiImage: dyed), in: rect)
        }
    }

    /// Saç boyası: gri tonlamadan dört duraklı tabloya (`kahraman.js` filtresi).
    private var dyeTable: [HeroRGB] {
        [hairColor.tint(HeroInk.dyeDeep, 0.75), hairColor.tint(HeroInk.dyeDark, 0.25),
         hairColor.tint(HeroInk.dyeLight, 0.35), hairColor.tint(HeroInk.dyeBright, 0.7)]
    }

    private func covering(_ ctx: inout GraphicsContext) {
        let n = Self.nth(figure[.head])
        if figure.isHijab, HeroInk.scarves.indices.contains(n - 1) {
            let c = HeroInk.scarves[n - 1]
            ctx.fill(HeroSVGPath.path("M74 101Q71 49 119 45Q167 45 166 99Q163 128 173 158Q155 173 135 168L105 159L83 166Q66 158 70 145Q76 124 74 101ZM86 99Q88 78 119 66Q150 76 154 99Q153 125 135 136Q120 146 106 137Q88 125 86 99Z"),
                     with: .color(c.color), style: FillStyle(eoFill: true))
            stroke(&ctx, "M75 139q9 18 31 19M134 162q18 -9 23 -28", c.tint(HeroInk.scarfFold, 0.25), 2)
        } else if figure.isHat {
            let fits: [[CGFloat]] = [[67, 28, 104, 51], [72, 21, 96, 62], [56, 24, 128, 60],
                                     [70, 27, 100, 57], [61, 24, 118, 60], [64, 24, 112, 61]]
            guard fits.indices.contains(n - 1) else { return }
            let f = fits[n - 1]
            image(&ctx, figure[.head], f[0], f[1], f[2], f[3])
        }
    }

    private func glasses(_ ctx: inout GraphicsContext) {
        let i = Self.nth(figure[.glasses])
        guard figure[.glasses] != "none", HeroInk.glasses.indices.contains(i - 1) else { return }
        let c = HeroInk.glasses[i - 1]
        for x in [CGFloat(105), 135] {
            let lens: Path
            switch i {
            case 6: lens = HeroSVGPath.path("M\(x - 10) 97l5 -6h11l5 6 -3 11 -11 2 -7 -5z")
            case 2: lens = HeroSVGPath.path("M\(x - 11) 94q11 -3 22 0l-2 11q-9 7 -18 0z")
            case 4: lens = HeroSVGPath.path("M\(x - 12) 91q13 2 23 4l-2 9q-11 12 -19 0z")
            default:
                let ry: CGFloat = i == 3 ? 8 : 10
                lens = Path(ellipseIn: CGRect(x: x - 11, y: 99 - ry, width: 22, height: ry * 2))
            }
            ctx.stroke(lens, with: .color(c.color), style: Self.round(2.3))
        }
        stroke(&ctx, "M116 98Q120 94 124 98M93 97l-7 -3M147 97l7 -3", c, 2.1)
    }

    // MARK: - Fırçalar

    private static func round(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    private func fill(_ ctx: inout GraphicsContext, _ d: String, _ c: HeroRGB) {
        ctx.fill(HeroSVGPath.path(d), with: .color(c.color))
    }

    private func stroke(_ ctx: inout GraphicsContext, _ d: String, _ c: HeroRGB, _ width: CGFloat = 1.5) {
        ctx.stroke(HeroSVGPath.path(d), with: .color(c.color), style: Self.round(width))
    }

    private func ellipse(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: HeroRGB) {
        ctx.fill(Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)), with: .color(c.color))
    }

    /// Ten: her şeklin kendi kutusunda açıktan gölgeye (SVG `objectBoundingBox`, x2=.85 y2=1).
    private func flesh(_ ctx: inout GraphicsContext, _ d: String) {
        fleshFill(&ctx, HeroSVGPath.path(d))
    }

    private func fleshEllipse(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) {
        fleshFill(&ctx, Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2)))
    }

    private func fleshFill(_ ctx: inout GraphicsContext, _ path: Path) {
        let box = path.boundingRect
        let gradient = Gradient(stops: [.init(color: skin.tint(HeroInk.skinLight, 0.13).color, location: 0),
                                        .init(color: skin.color, location: 0.55),
                                        .init(color: shade.color, location: 1)])
        ctx.fill(path, with: .linearGradient(gradient, startPoint: CGPoint(x: box.minX, y: box.minY),
                                             endPoint: CGPoint(x: box.minX + box.width * 0.85, y: box.maxY)))
    }

    /// Yanak: 12 × 7'lik elipste merkezden kenara sönen pembe.
    private func blush(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat) {
        var b = ctx
        b.translateBy(x: x, y: y)
        b.scaleBy(x: 1, y: 7.0 / 12.0)
        let color = skin.tint(HeroInk.blush, 0.55).color
        let gradient = Gradient(stops: [.init(color: color.opacity(0.82), location: 0),
                                        .init(color: skin.color.opacity(0), location: 1)])
        b.fill(Path(ellipseIn: CGRect(x: -12, y: -12, width: 24, height: 24)),
               with: .radialGradient(gradient, center: .zero, startRadius: 0, endRadius: 12))
    }

    private func image(_ ctx: inout GraphicsContext, _ id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        ctx.draw(Image("HeroFigure/\(id)"), in: CGRect(x: x, y: y, width: w, height: h))
    }
}

// MARK: - SVG yolu

/// `kahraman.js`'in yol metinlerini okur: M L H V Q C Z, büyük (mutlak) ve küçük
/// (göreli) harfler, örtük tekrar ("l5 -6 -3 11" iki çizgi). Yay (A) yok:
/// teslimde yalnızca gözlük camında vardı, orada elips çizilir.
enum HeroSVGPath {
    private enum Token: Equatable {
        case command(Character)
        case number(CGFloat)
    }

    private static let commands: Set<Character> = ["M", "m", "L", "l", "H", "h", "V", "v", "Q", "q", "C", "c", "Z", "z"]

    private static func tokens(_ d: String) -> [Token] {
        var result: [Token] = []
        var number = ""
        func flush() {
            if let value = Double(number) { result.append(.number(CGFloat(value))) }
            number = ""
        }
        for ch in d {
            if commands.contains(ch) {
                flush()
                result.append(.command(ch))
            } else if ch == "-" {
                // Yeni sayı başlar; üssün eksisi ("1e-3") teslimde yok.
                flush()
                number = "-"
            } else if ch == "." {
                if number.contains(".") { flush() }
                number.append(ch)
            } else if ch.isNumber {
                number.append(ch)
            } else {
                flush()
            }
        }
        flush()
        return result
    }

    static func path(_ d: String) -> Path {
        let list = tokens(d)
        var path = Path()
        var i = 0
        var current = CGPoint.zero
        var start = CGPoint.zero
        var command: Character = "M"

        func number() -> CGFloat? {
            guard i < list.count, case .number(let value) = list[i] else { return nil }
            i += 1
            return value
        }
        func point(relative: Bool) -> CGPoint? {
            guard let x = number(), let y = number() else { return nil }
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while i < list.count {
            if case .command(let c) = list[i] {
                command = c
                i += 1
                if c == "Z" || c == "z" {
                    path.closeSubpath()
                    current = start
                    continue
                }
            }
            let relative = command.isLowercase
            switch command {
            case "M", "m":
                guard let p = point(relative: relative) else { return path }
                path.move(to: p)
                current = p
                start = p
                command = relative ? "l" : "L"
            case "L", "l":
                guard let p = point(relative: relative) else { return path }
                path.addLine(to: p)
                current = p
            case "H", "h":
                guard let x = number() else { return path }
                current = CGPoint(x: relative ? current.x + x : x, y: current.y)
                path.addLine(to: current)
            case "V", "v":
                guard let y = number() else { return path }
                current = CGPoint(x: current.x, y: relative ? current.y + y : y)
                path.addLine(to: current)
            case "Q", "q":
                guard let control = point(relative: relative), let end = point(relative: relative) else { return path }
                path.addQuadCurve(to: end, control: control)
                current = end
            case "C", "c":
                guard let c1 = point(relative: relative), let c2 = point(relative: relative),
                      let end = point(relative: relative) else { return path }
                path.addCurve(to: end, control1: c1, control2: c2)
                current = end
            default:
                i += 1
            }
        }
        return path
    }
}

// MARK: - Görünüm

/// Tam boy kahraman ya da kadrajı. Süs: etiketi çevresinden gelir.
struct HeroFigureView: View {
    let figure: HeroFigure
    var frame: HeroFigureArt.Frame = .body

    var body: some View {
        Canvas { ctx, size in
            HeroFigureArt(figure: figure).draw(in: &ctx, frame: frame, size: size)
        }
        .aspectRatio(frame.rect.width / frame.rect.height, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
