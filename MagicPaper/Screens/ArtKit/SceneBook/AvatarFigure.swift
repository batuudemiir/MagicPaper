import CoreGraphics
import Foundation

/// Yer tutucu kitap karakterinin geometrisi (B2, Faz 2).
///
/// Sevimli çocuk karakterinin bilinen kuralları üzerine kurulu ("bebek şeması",
/// chibi oranları):
/// - 2,5 baş boyu: kafa toplam boyun yaklaşık %40'ı, omuzlar kafadan dar.
/// - Gözler yüzün alt yarısında, aralıklı ve iri; beyaz göz + iris + iki ışık.
/// - Küçük kalkık burun, açık gülümseme, pembe yanak.
/// - Kısa, tombul uzuvlar; eldiven gibi eller, yuvarlak ayakkabı; armut gövde.
/// - Hacimli saç kütlesi, yana süpürülmüş perçem; sivri köşe yok.
///
/// Gerçek illüstrasyon gelene kadar sistemin uçtan uca çalışması içindir;
/// gerçek varlık geldiğinde `AvatarView` bu geometriyi kullanmaz.
///
/// Birim: tuval genişliği = 1, yüksekliği = 1.5 (512 × 768). Figür üç çeyrek
/// önden, sağa dönük çizilir; sola bakış aynalanır. Kafa yerel koordinatı:
/// merkez kafanın ortası, +y aşağı.
///
/// Saf CoreGraphics: renk, SwiftUI ya da varlık bilgisi yok.
enum AvatarFigure {

    static let canvasAspect: CGFloat = 1.5
    /// Kafanın yarı genişliği ve yarı yüksekliği.
    static let headRadius: CGFloat = 0.30
    static let headHalfHeight: CGFloat = 0.275
    static let armWidth: CGFloat = 0.10
    static let handRadius: CGFloat = 0.055
    static let legWidth: CGFloat = 0.14
    /// Yüzün dönük olduğu yana kayma — üç çeyrek bakış.
    static let faceShift: CGFloat = 0.025

    /// Üç noktalı uzuv: omuz → dirsek → el ya da kalça → diz → ayak bileği.
    struct Limb: Equatable {
        let root: CGPoint
        let joint: CGPoint
        let end: CGPoint
    }

    struct Skeleton: Equatable {
        let head: CGPoint
        /// Derece. Negatif = yukarı/geriye bakış (sağa bakan figür için).
        let headTilt: CGFloat
        let torsoTop: CGPoint
        let torsoBottom: CGPoint
        let torsoWidth: CGFloat
        /// İlki arka (uzak) kol.
        let arms: [Limb]
        /// İlki arka (uzak) bacak.
        let legs: [Limb]
        let eyesClosed: Bool
        /// Tüm figürün ölçeği, ayak noktası (0.5, 1.46) etrafında. Yatan figür
        /// tuvale sığsın diye küçültülür.
        var scale: CGFloat = 1
    }

    static let footPoint = CGPoint(x: 0.5, y: 1.46)

    /// Bilinen pozlar. Bilinmeyen poz `standing` çizilir.
    static let poseIDs = ["standing", "walking", "reaching", "lookingUp",
                          "pointing", "celebrating", "sitting", "sleeping"]

    static func skeleton(for pose: String) -> Skeleton {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        func limb(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Limb { Limb(root: a, joint: b, end: c) }
        let standingLegs = [limb(p(0.42, 1.05), p(0.42, 1.22), p(0.42, 1.38)),
                            limb(p(0.58, 1.05), p(0.58, 1.22), p(0.58, 1.38))]
        let openLegs = [limb(p(0.42, 1.05), p(0.40, 1.22), p(0.38, 1.38)),
                        limb(p(0.58, 1.05), p(0.60, 1.22), p(0.62, 1.38))]
        let hangingBackArm = limb(p(0.33, 0.73), p(0.29, 0.86), p(0.28, 0.98))

        switch pose {
        case "walking":
            return Skeleton(head: p(0.53, 0.41), headTilt: 3,
                            torsoTop: p(0.52, 0.69), torsoBottom: p(0.50, 1.08), torsoWidth: 0.36,
                            arms: [limb(p(0.35, 0.74), p(0.26, 0.84), p(0.21, 0.94)),
                                   limb(p(0.69, 0.74), p(0.78, 0.83), p(0.84, 0.92))],
                            legs: [limb(p(0.44, 1.05), p(0.36, 1.21), p(0.28, 1.37)),
                                   limb(p(0.57, 1.05), p(0.65, 1.21), p(0.71, 1.38))],
                            eyesClosed: false)
        case "reaching":
            return Skeleton(head: p(0.57, 0.43), headTilt: 10,
                            torsoTop: p(0.55, 0.71), torsoBottom: p(0.48, 1.08), torsoWidth: 0.36,
                            arms: [limb(p(0.38, 0.76), p(0.56, 0.84), p(0.72, 0.87)),
                                   limb(p(0.72, 0.76), p(0.83, 0.81), p(0.91, 0.84))],
                            legs: [limb(p(0.42, 1.05), p(0.40, 1.22), p(0.38, 1.38)),
                                   limb(p(0.55, 1.05), p(0.60, 1.22), p(0.62, 1.38))],
                            eyesClosed: false)
        case "lookingUp":
            return Skeleton(head: p(0.49, 0.40), headTilt: -20,
                            torsoTop: p(0.50, 0.68), torsoBottom: p(0.50, 1.08), torsoWidth: 0.36,
                            arms: [limb(p(0.33, 0.73), p(0.22, 0.83), p(0.14, 0.90)),
                                   limb(p(0.67, 0.73), p(0.78, 0.83), p(0.86, 0.90))],
                            legs: standingLegs, eyesClosed: false)
        case "pointing":
            return Skeleton(head: p(0.50, 0.40), headTilt: -5,
                            torsoTop: p(0.50, 0.68), torsoBottom: p(0.50, 1.08), torsoWidth: 0.36,
                            arms: [hangingBackArm,
                                   limb(p(0.67, 0.73), p(0.79, 0.64), p(0.89, 0.53))],
                            legs: openLegs, eyesClosed: false)
        case "celebrating":
            return Skeleton(head: p(0.50, 0.41), headTilt: -6,
                            torsoTop: p(0.50, 0.69), torsoBottom: p(0.50, 1.08), torsoWidth: 0.36,
                            arms: [limb(p(0.33, 0.73), p(0.20, 0.62), p(0.12, 0.50)),
                                   limb(p(0.67, 0.73), p(0.80, 0.62), p(0.88, 0.50))],
                            legs: [limb(p(0.42, 1.05), p(0.36, 1.20), p(0.32, 1.33)),
                                   limb(p(0.58, 1.05), p(0.64, 1.20), p(0.68, 1.33))],
                            eyesClosed: false)
        case "sitting":
            // Bir kütüğün ya da basamağın kenarında: gövde hafif geriye yaslı,
            // uyluklar kalçanın ortasından öne, baldırlar dizden aşağı, eller
            // dizlerde.
            return Skeleton(head: p(0.46, 0.65), headTilt: -4,
                            torsoTop: p(0.46, 0.93), torsoBottom: p(0.50, 1.25), torsoWidth: 0.36,
                            arms: [limb(p(0.31, 0.98), p(0.34, 1.11), p(0.50, 1.17)),
                                   limb(p(0.62, 0.98), p(0.68, 1.10), p(0.75, 1.17))],
                            legs: [limb(p(0.46, 1.20), p(0.68, 1.21), p(0.70, 1.39)),
                                   limb(p(0.57, 1.21), p(0.80, 1.21), p(0.83, 1.39))],
                            eyesClosed: false)
        case "sleeping":
            // Sırt üstü, yüz yukarı, dizler kalkık, eller karnın üstünde. Yatan
            // çocuk boyu tuval genişliğini aştığı için ayak noktası etrafında
            // küçültülür; sahnede bir yatağın ya da yastığın üstünde durur.
            return Skeleton(head: p(0.19, 0.98), headTilt: -90,
                            torsoTop: p(0.47, 1.00), torsoBottom: p(0.89, 1.00), torsoWidth: 0.36,
                            arms: [limb(p(0.52, 0.88), p(0.65, 0.86), p(0.71, 0.95)),
                                   limb(p(0.52, 1.12), p(0.63, 1.10), p(0.71, 1.02))],
                            legs: [limb(p(0.87, 0.94), p(0.98, 0.78), p(1.04, 0.96)),
                                   limb(p(0.87, 1.06), p(1.00, 0.86), p(1.07, 1.06))],
                            eyesClosed: true, scale: 0.70)
        default: // standing
            return Skeleton(head: p(0.50, 0.40), headTilt: 0,
                            torsoTop: p(0.50, 0.68), torsoBottom: p(0.50, 1.08), torsoWidth: 0.36,
                            arms: [hangingBackArm,
                                   limb(p(0.67, 0.73), p(0.71, 0.86), p(0.72, 0.98))],
                            legs: standingLegs, eyesClosed: false)
        }
    }

    // MARK: - Dönüşümler

    /// Figürün tamamının ölçeği (yalnızca yatan pozda 1'den farklı).
    static func figureTransform(_ s: Skeleton) -> CGAffineTransform {
        CGAffineTransform(translationX: footPoint.x, y: footPoint.y)
            .scaledBy(x: s.scale, y: s.scale)
            .translatedBy(x: -footPoint.x, y: -footPoint.y)
    }

    /// Kafanın yerel koordinatından figüre: döndür, sonra kafanın yerine taşı.
    static func headTransform(_ s: Skeleton) -> CGAffineTransform {
        CGAffineTransform(translationX: s.head.x, y: s.head.y)
            .rotated(by: s.headTilt * .pi / 180)
    }

    private static func inHead(_ path: CGPath, _ s: Skeleton) -> CGPath {
        var t = headTransform(s)
        return path.copy(using: &t) ?? path
    }

    private static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGRect {
        CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry)
    }

    // MARK: - Gövde

    static func limbPath(_ l: Limb) -> CGPath {
        let path = CGMutablePath()
        path.move(to: l.root)
        path.addLine(to: l.joint)
        path.addLine(to: l.end)
        return path
    }

    /// Uzvun kökten eklemin bir kesrine kadar olan kısmı — kısa kolun yeri.
    static func upperLimbPath(_ l: Limb, fraction: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: l.root)
        path.addLine(to: CGPoint(x: l.root.x + (l.joint.x - l.root.x) * fraction,
                                 y: l.root.y + (l.joint.y - l.root.y) * fraction))
        return path
    }

    static func handPath(_ arm: Limb) -> CGPath {
        CGPath(ellipseIn: ellipse(arm.end.x, arm.end.y, handRadius, handRadius), transform: nil)
    }

    /// Ayakkabı: bacağın yönüne dik, yuvarlak bir tabak; dik duran bacakta
    /// burnu figürün baktığı yana hafifçe çıkar.
    static func shoePath(_ leg: Limb) -> CGPath {
        let dx = leg.end.x - leg.joint.x, dy = leg.end.y - leg.joint.y
        let len = max(hypot(dx, dy), 0.001)
        let ux = dx / len, uy = dy / len
        let upright = abs(uy) > abs(ux)
        let center = CGPoint(x: leg.end.x + ux * 0.035 + (upright ? 0.02 : 0),
                             y: leg.end.y + uy * 0.035)
        let angle = atan2(uy, ux) - .pi / 2
        var t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: angle)
        return CGPath(ellipseIn: ellipse(0, 0, 0.085, 0.05), transform: &t)
    }

    /// Gövde: üstte dar, altta geniş armut; eksen boyunca döner.
    static func torsoPath(_ s: Skeleton) -> CGPath {
        let dx = s.torsoBottom.x - s.torsoTop.x
        let dy = s.torsoBottom.y - s.torsoTop.y
        let h = max(hypot(dx, dy), 0.001)
        let tw = s.torsoWidth, bw = s.torsoWidth * 1.17
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -tw / 2 + 0.03, y: 0))
        path.addLine(to: CGPoint(x: tw / 2 - 0.03, y: 0))
        path.addQuadCurve(to: CGPoint(x: bw / 2, y: h * 0.75), control: CGPoint(x: tw / 2 + 0.03, y: h * 0.12))
        path.addQuadCurve(to: CGPoint(x: bw / 2 - 0.08, y: h), control: CGPoint(x: bw / 2 + 0.01, y: h))
        path.addLine(to: CGPoint(x: -bw / 2 + 0.08, y: h))
        path.addQuadCurve(to: CGPoint(x: -bw / 2, y: h * 0.75), control: CGPoint(x: -bw / 2 - 0.01, y: h))
        path.addQuadCurve(to: CGPoint(x: -tw / 2 + 0.03, y: 0), control: CGPoint(x: -tw / 2 - 0.03, y: h * 0.12))
        path.closeSubpath()
        var t = CGAffineTransform(translationX: s.torsoTop.x, y: s.torsoTop.y)
            .rotated(by: atan2(dy, dx) - .pi / 2)
        return path.copy(using: &t) ?? path
    }

    /// Çenenin gövdeye düşürdüğü gölge.
    static func neckShadowPath(_ s: Skeleton) -> CGPath {
        inHead(CGPath(ellipseIn: ellipse(0, headHalfHeight + 0.01, 0.13, 0.05), transform: nil), s)
    }

    // MARK: - Kafa

    static func headPath(_ s: Skeleton) -> CGPath {
        inHead(CGPath(ellipseIn: ellipse(0, 0, headRadius, headHalfHeight), transform: nil), s)
    }

    static func earsPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        for side: CGFloat in [-1, 1] {
            path.addEllipse(in: ellipse(side * 0.29, 0.05, 0.07, 0.075))
        }
        return inHead(path, s)
    }

    static func innerEarsPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        for side: CGFloat in [-1, 1] {
            path.addEllipse(in: ellipse(side * 0.30, 0.05, 0.035, 0.04))
        }
        return inHead(path, s)
    }

    /// Göz merkezleri, kafa yereli. Yüzün alt yarısında ve aralıklı.
    static let eyeCenters: [CGPoint] = [CGPoint(x: faceShift - 0.115, y: 0.05),
                                        CGPoint(x: faceShift + 0.115, y: 0.05)]

    /// Gözün parçaları — beyaz, iris, göz bebeği, ışık. Kapalı gözde yalnızca
    /// `lids` dolu gelir.
    struct Eyes {
        let whites: CGPath
        let irises: CGPath
        let pupils: CGPath
        let highlights: CGPath
        /// Üst kapak çizgisi ya da kapalı göz yayı. Çizgi olarak çizilir.
        let lids: CGPath
    }

    static func eyes(_ s: Skeleton) -> Eyes {
        let whites = CGMutablePath(), irises = CGMutablePath(), pupils = CGMutablePath()
        let highlights = CGMutablePath(), lids = CGMutablePath()
        for c in eyeCenters {
            if s.eyesClosed {
                lids.move(to: CGPoint(x: c.x - 0.05, y: c.y))
                lids.addQuadCurve(to: CGPoint(x: c.x + 0.05, y: c.y), control: CGPoint(x: c.x, y: c.y + 0.045))
                continue
            }
            whites.addEllipse(in: ellipse(c.x, c.y, 0.056, 0.066))
            let iris = CGPoint(x: c.x + 0.008, y: c.y + 0.008)
            irises.addEllipse(in: ellipse(iris.x, iris.y, 0.043, 0.048))
            pupils.addEllipse(in: ellipse(iris.x, iris.y, 0.022, 0.025))
            highlights.addEllipse(in: ellipse(iris.x - 0.016, iris.y - 0.019, 0.016, 0.016))
            highlights.addEllipse(in: ellipse(iris.x + 0.015, iris.y + 0.016, 0.0075, 0.0075))
            lids.move(to: CGPoint(x: c.x - 0.058, y: c.y - 0.012))
            lids.addQuadCurve(to: CGPoint(x: c.x + 0.058, y: c.y - 0.012), control: CGPoint(x: c.x, y: c.y - 0.085))
        }
        return Eyes(whites: inHead(whites, s), irises: inHead(irises, s), pupils: inHead(pupils, s),
                    highlights: inHead(highlights, s), lids: inHead(lids, s))
    }

    static func eyebrowsPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        for c in eyeCenters {
            path.move(to: CGPoint(x: c.x - 0.04, y: c.y - 0.1))
            path.addQuadCurve(to: CGPoint(x: c.x + 0.04, y: c.y - 0.1), control: CGPoint(x: c.x, y: c.y - 0.13))
        }
        return inHead(path, s)
    }

    static func nosePath(_ s: Skeleton) -> CGPath {
        inHead(CGPath(ellipseIn: ellipse(faceShift, 0.135, 0.024, 0.016), transform: nil), s)
    }

    /// Açık gülümseme: düz üst kenar, yuvarlak alt. Uykuda küçük, kapalı bir ağız.
    static func mouthPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        if s.eyesClosed {
            path.move(to: CGPoint(x: faceShift - 0.03, y: 0.18))
            path.addQuadCurve(to: CGPoint(x: faceShift + 0.03, y: 0.18), control: CGPoint(x: faceShift, y: 0.2))
            path.addQuadCurve(to: CGPoint(x: faceShift - 0.03, y: 0.18), control: CGPoint(x: faceShift, y: 0.19))
        } else {
            path.move(to: CGPoint(x: faceShift - 0.055, y: 0.17))
            path.addLine(to: CGPoint(x: faceShift + 0.055, y: 0.17))
            path.addQuadCurve(to: CGPoint(x: faceShift - 0.055, y: 0.17), control: CGPoint(x: faceShift, y: 0.27))
        }
        path.closeSubpath()
        return inHead(path, s)
    }

    static func tonguePath(_ s: Skeleton) -> CGPath? {
        guard !s.eyesClosed else { return nil }
        return inHead(CGPath(ellipseIn: ellipse(faceShift, 0.205, 0.03, 0.016), transform: nil), s)
    }

    static func cheeksPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        for side: CGFloat in [-1, 1] {
            path.addEllipse(in: ellipse(faceShift + side * 0.2, 0.135, 0.048, 0.03))
        }
        return inHead(path, s)
    }

    // MARK: - Saç

    /// Alnı örten kubbe ve yana süpürülmüş perçem — her biçimin ön kütlesi.
    private static func capPath() -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.315, y: 0.03))
        path.addCurve(to: CGPoint(x: 0, y: -0.305), control1: CGPoint(x: -0.33, y: -0.17),
                      control2: CGPoint(x: -0.19, y: -0.305))
        path.addCurve(to: CGPoint(x: 0.315, y: -0.01), control1: CGPoint(x: 0.19, y: -0.305),
                      control2: CGPoint(x: 0.33, y: -0.17))
        // Perçem: sağdan sola süpürülen üç yumuşak tutam.
        path.addQuadCurve(to: CGPoint(x: 0.12, y: -0.085), control: CGPoint(x: 0.24, y: -0.02))
        path.addQuadCurve(to: CGPoint(x: -0.05, y: -0.06), control: CGPoint(x: 0.03, y: -0.135))
        path.addQuadCurve(to: CGPoint(x: -0.2, y: -0.07), control: CGPoint(x: -0.12, y: -0.13))
        path.addQuadCurve(to: CGPoint(x: -0.315, y: 0.03), control: CGPoint(x: -0.3, y: -0.1))
        path.closeSubpath()
        return path
    }

    /// Saç kütlesi. `front` = kafanın önüne düşen kısım, değilse kafanın
    /// arkasındaki kütle (bir ton koyu çizilir).
    static func hairPath(style: String, front: Bool, _ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) { path.addEllipse(in: ellipse(x, y, r, r)) }

        switch (style, front) {
        case ("hair_curly", false):
            for deg in stride(from: 150.0, through: 390.0, by: 20.0) {
                let a = CGFloat(deg) * .pi / 180
                circle(cos(a) * 0.29, sin(a) * 0.25 - 0.02, 0.085)
            }
        case ("hair_curly", true):
            path.addPath(capPath())
            for (x, y) in [(-0.2, -0.17), (-0.06, -0.21), (0.09, -0.21), (0.22, -0.16)] as [(CGFloat, CGFloat)] {
                circle(x, y, 0.085)
            }
        case ("hair_shoulder", false):
            path.addRoundedRect(in: CGRect(x: -0.36, y: -0.3, width: 0.72, height: 0.7),
                                cornerWidth: 0.2, cornerHeight: 0.2)
        case ("hair_ponytail", false):
            path.addEllipse(in: ellipse(0, -0.05, 0.33, 0.28))
            path.addEllipse(in: ellipse(-0.33, -0.12, 0.1, 0.15))
        case ("hair_braided", false):
            path.addEllipse(in: ellipse(0, -0.05, 0.33, 0.28))
            for side: CGFloat in [-1, 1] {
                for i in 0..<4 {
                    path.addEllipse(in: ellipse(side * 0.3, 0.14 + CGFloat(i) * 0.075, 0.055, 0.045))
                }
            }
        case (_, false):
            path.addEllipse(in: ellipse(0, -0.05, 0.33, 0.28))
        default:
            path.addPath(capPath())
        }
        return inHead(path, s)
    }

    /// Saçın parlaması: kubbenin üstünde ince bir yay.
    static func hairHighlightPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x: 0, y: 0), radius: 0.235,
                    startAngle: .pi * 1.18, endAngle: .pi * 1.36, clockwise: false)
        return inHead(path, s)
    }

    /// Saç bağı — at kuyruğu ve örgülerde. Kıyafet rengiyle boyanır.
    static func hairTiesPath(style: String, _ s: Skeleton) -> CGPath? {
        let path = CGMutablePath()
        switch style {
        case "hair_ponytail":
            path.addEllipse(in: ellipse(-0.26, -0.14, 0.035, 0.035))
        case "hair_braided":
            for side: CGFloat in [-1, 1] {
                path.addEllipse(in: ellipse(side * 0.3, 0.42, 0.03, 0.025))
            }
        default:
            return nil
        }
        return inHead(path, s)
    }

    // MARK: - Aksesuar

    static func glassesPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        for c in eyeCenters {
            path.addEllipse(in: ellipse(c.x, c.y, 0.075, 0.075))
        }
        path.move(to: CGPoint(x: eyeCenters[0].x + 0.075, y: 0.04))
        path.addQuadCurve(to: CGPoint(x: eyeCenters[1].x - 0.075, y: 0.04), control: CGPoint(x: faceShift, y: 0.02))
        return inHead(path, s)
    }

    /// Bere: kafaya oturan kubbe, kıvrık kenar ve ponpon.
    static func beaniePath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.32, y: -0.08))
        path.addQuadCurve(to: CGPoint(x: 0.32, y: -0.08), control: CGPoint(x: 0, y: -0.58))
        path.closeSubpath()
        path.addRoundedRect(in: CGRect(x: -0.34, y: -0.13, width: 0.68, height: 0.09),
                            cornerWidth: 0.045, cornerHeight: 0.045)
        path.addEllipse(in: ellipse(0, -0.34, 0.045, 0.045))
        return inHead(path, s)
    }

    /// Sırt çantasının gövdenin arkasında kalan gövdesi.
    static func backpackPath(_ s: Skeleton) -> CGPath {
        let mid = CGPoint(x: (s.torsoTop.x + s.torsoBottom.x) / 2, y: (s.torsoTop.y + s.torsoBottom.y) / 2)
        let path = CGMutablePath()
        path.addRoundedRect(in: CGRect(x: mid.x - s.torsoWidth / 2 - 0.07, y: mid.y - 0.17,
                                       width: 0.2, height: 0.3),
                            cornerWidth: 0.06, cornerHeight: 0.06)
        return path
    }

    /// Sırt çantasının göğüsten geçen askısı.
    static func backpackStrapPath(_ s: Skeleton) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: s.torsoTop.x - s.torsoWidth / 2 + 0.06, y: s.torsoTop.y + 0.01))
        path.addQuadCurve(to: CGPoint(x: s.torsoTop.x - s.torsoWidth / 2 + 0.05, y: s.torsoTop.y + 0.24),
                          control: CGPoint(x: s.torsoTop.x - s.torsoWidth / 2 + 0.09, y: s.torsoTop.y + 0.12))
        return path
    }
}
