import SwiftUI

/// Renders a signature motif for the MagicPaper cover system.
///
/// Signatures are very small (1.5–4% of cover width) hand-drawn decorative
/// marks placed in Zone C. They are never the focal point of the cover.
struct CoverSignatureView: View {
    let signature: CoverSignature
    let coverSize: CGSize

    var body: some View {
        Group {
            switch signature.type {
            case .none:
                EmptyView()
            case .tinyStar:
                TinyStarShape()
                    .stroke(strokeColor, style: strokeStyle)
            case .paperSparkle:
                PaperSparkleShape()
                    .stroke(strokeColor, style: strokeStyle)
            case .crescent:
                CrescentShape()
                    .stroke(strokeColor, lineWidth: 1.5)
            case .leaf:
                LeafShape()
                    .stroke(strokeColor, style: strokeStyle)
            case .tinyFlower:
                TinyFlowerShape()
                    .stroke(strokeColor, lineWidth: 1.2)
            case .dotConstellation:
                DotConstellationShape()
                    .fill(strokeColor)
            }
        }
        .frame(width: motifSize, height: motifSize)
        .rotationEffect(.degrees(signature.rotation))
        .position(
            x: signature.x * coverSize.width,
            y: signature.y * coverSize.height
        )
        .opacity(0.55)
    }

    /// The physical size of the motif in points.
    private var motifSize: CGFloat {
        coverSize.width * signature.scale
    }

    /// Warm brown stroke — consistent across all motifs.
    private var strokeColor: Color {
        MagicPaperCoverColor.warmBrown.color
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
    }
}

// MARK: - Motif Shapes

/// Five-pointed star with deterministic slight irregularity.
private struct TinyStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.38

        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = -.pi / 2 + Double(i) * .pi / 5
            // Subtle imperfection: ±3% radius variation per point
            let variation = 1.0 + Double(i % 3) * 0.03 - 0.03
            let r = radius * variation
            let pt = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            if i == 0 { path.move(to: pt) }
            else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

/// Four-pointed sparkle/diamond star.
private struct PaperSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY

        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: cy),
            control: CGPoint(x: cx + rect.width * 0.08, y: cy - rect.height * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx, y: rect.maxY),
            control: CGPoint(x: cx + rect.width * 0.08, y: cy + rect.height * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: cy),
            control: CGPoint(x: cx - rect.width * 0.08, y: cy + rect.height * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx, y: rect.minY),
            control: CGPoint(x: cx - rect.width * 0.08, y: cy - rect.height * 0.08)
        )

        return path
    }
}

/// Thin crescent moon.
private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2

        path.addArc(center: center, radius: r,
                    startAngle: .degrees(-90), endAngle: .degrees(90),
                    clockwise: false)
        path.addArc(center: CGPoint(x: center.x - r * 0.35, y: center.y),
                    radius: r * 0.88,
                    startAngle: .degrees(90), endAngle: .degrees(-90),
                    clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// Simple leaf with a center vein line.
private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)

        // Left curve
        path.move(to: bottom)
        path.addQuadCurve(to: top,
                          control: CGPoint(x: rect.minX - rect.width * 0.1, y: rect.midY))
        // Right curve
        path.addQuadCurve(to: bottom,
                          control: CGPoint(x: rect.maxX + rect.width * 0.1, y: rect.midY))

        // Center vein
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY * 0.95))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.15))

        return path
    }
}

/// Five-petal simple flower.
private struct TinyFlowerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let petalR = min(rect.width, rect.height) * 0.22
        let dist = petalR * 1.1

        for i in 0..<5 {
            let angle = Double(i) * 2.0 * .pi / 5.0 - .pi / 2.0
            let cx = center.x + cos(angle) * dist
            let cy = center.y + sin(angle) * dist
            path.addEllipse(in: CGRect(
                x: cx - petalR, y: cy - petalR,
                width: petalR * 2, height: petalR * 2
            ))
        }

        // Center dot
        let dotR = petalR * 0.5
        path.addEllipse(in: CGRect(
            x: center.x - dotR, y: center.y - dotR,
            width: dotR * 2, height: dotR * 2
        ))

        return path
    }
}

/// Three to five small dots in a loose cluster.
private struct DotConstellationShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dotR = min(rect.width, rect.height) * 0.09

        // Fixed constellation positions (deterministic, no randomness)
        let positions: [(Double, Double)] = [
            (0.30, 0.25), (0.70, 0.35), (0.45, 0.55), (0.22, 0.72)
        ]

        for (fx, fy) in positions {
            let cx = rect.minX + rect.width * fx
            let cy = rect.minY + rect.height * fy
            path.addEllipse(in: CGRect(
                x: cx - dotR, y: cy - dotR,
                width: dotR * 2, height: dotR * 2
            ))
        }

        return path
    }
}
