import SwiftUI

// MARK: - Cover View

/// Renders a generative children's-book cover from a `MagicPaperCoverConfiguration`.
///
/// Instead of abstract tiles, this renders a layered scene composition:
/// background sky → distant landscape → mid-ground elements → foreground
/// → title typography. The scene is determined by the configuration's
/// `theme` (forest, ocean, space, etc.).
///
/// Every visual decision is deterministic — same configuration always
/// produces the same visual output.
struct MagicPaperCoverView: View {

    let configuration: MagicPaperCoverConfiguration

    /// When set, renders the story title in Zone A.
    var title: String? = nil

    /// Controls brand line visibility.
    var showsBrand: Bool = true

    /// When true, the view fills its proposed size instead of enforcing 2:3.
    var fillsProposedSize: Bool = false

    private var palette: CoverPalette {
        CoverPalette.palette(for: configuration.palette)
    }

    var body: some View {
        if fillsProposedSize {
            coverContent
        } else {
            coverContent
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
        }
    }

    private var coverContent: some View {
        GeometryReader { geo in
            coverCanvas(size: geo.size)
        }
        .clipped()
        .accessibilityElement(children: .contain)
    }

    /// All scene data is pre-computed here, then passed to pure rendering sub-views.
    private func coverCanvas(size: CGSize) -> some View {
        let scene = CoverSceneData(
            theme: configuration.theme,
            palette: palette,
            seed: configuration.seed,
            size: size
        )

        return ZStack {
            // Layer 1: Sky gradient
            LinearGradient(
                colors: scene.skyColors,
                startPoint: .top,
                endPoint: .bottom
            )

            // Layer 2: Subtle grain
            Image(uiImage: ReaderGrain.tile)
                .resizable(resizingMode: .tile)
                .opacity(0.04)
                .blendMode(.multiply)
                .allowsHitTesting(false)

            // Layer 3: Celestial element (moon/sun)
            celestialView(scene: scene, size: size)

            // Layer 4: Back landscape layer
            landscapeLayer(
                path: scene.backLandscapePath(in: size),
                color: scene.backLandscapeColor
            )

            // Layer 5: Mid landscape layer
            landscapeLayer(
                path: scene.midLandscapePath(in: size),
                color: scene.midLandscapeColor
            )

            // Layer 6: Theme motifs (trees, boats, castles, etc.)
            motifLayer(scene: scene, size: size)

            // Layer 7: Foreground landscape
            landscapeLayer(
                path: scene.foregroundPath(in: size),
                color: scene.foregroundColor
            )

            // Layer 8: Title
            if let title, !title.isEmpty {
                coverTitle(title: title, size: size)
            }
        }
    }

    // MARK: - Landscape

    private func landscapeLayer(path: Path, color: Color) -> some View {
        path.fill(color)
            .overlay {
                Image(uiImage: ReaderGrain.tile)
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .blendMode(.multiply)
                    .clipShape(path)
            }
    }

    // MARK: - Celestial

    @ViewBuilder
    private func celestialView(scene: CoverSceneData, size: CGSize) -> some View {
        let cx = scene.celestialX * size.width
        let cy = scene.celestialY * size.height
        let r = scene.celestialSize * size.width

        if scene.hasMoon {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF5EED5, alpha: 0.85))
                    .frame(width: r, height: r)
                Circle()
                    .fill(scene.skyColors.first ?? .clear)
                    .frame(width: r * 0.75, height: r * 0.75)
                    .offset(x: r * 0.18, y: -r * 0.1)
            }
            .position(x: cx, y: cy)
        } else {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xF5DFA0, alpha: 0.9),
                            Color(hex: 0xE8C870, alpha: 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: r * 0.8
                    )
                )
                .frame(width: r * 1.6, height: r * 1.6)
                .position(x: cx, y: cy)
        }
    }

    // MARK: - Motifs (data-driven, no inout)

    @ViewBuilder
    private func motifLayer(scene: CoverSceneData, size: CGSize) -> some View {
        switch scene.theme {
        case .forest:
            ForEach(Array(scene.trees.enumerated()), id: \.offset) { _, tree in
                treeView(tree: tree, size: size)
            }
        case .ocean:
            boatView(boat: scene.boat, size: size)
            ForEach(0..<scene.waveLineYs.count, id: \.self) { i in
                waveLineView(y: scene.waveLineYs[i], size: size)
            }
        case .space:
            ForEach(Array(scene.stars.enumerated()), id: \.offset) { _, star in
                Circle()
                    .fill(Color.white.opacity(star.opacity))
                    .frame(width: star.size, height: star.size)
                    .position(x: star.x * size.width, y: star.y * size.height)
            }
        case .kingdom:
            castleView(x: scene.castleX, size: size)
        case .snowland:
            ForEach(Array(scene.stars.enumerated()), id: \.offset) { _, flake in
                Circle()
                    .fill(Color.white.opacity(flake.opacity))
                    .frame(width: flake.size * 1.3, height: flake.size * 1.3)
                    .position(x: flake.x * size.width, y: flake.y * size.height)
            }
            ForEach(Array(scene.trees.enumerated()), id: \.offset) { _, tree in
                treeView(tree: tree, size: size)
            }
        case .fairytale:
            ForEach(Array(scene.stars.enumerated()), id: \.offset) { _, sparkle in
                Circle()
                    .fill(Color(hex: 0xF5DFA0, alpha: sparkle.opacity))
                    .frame(width: sparkle.size, height: sparkle.size)
                    .position(x: sparkle.x * size.width, y: sparkle.y * size.height)
            }
            mushroomView(x: scene.castleX, y: 0.66, size: size)
        default:
            ForEach(Array(scene.trees.enumerated()), id: \.offset) { _, tree in
                treeView(tree: tree, size: size)
            }
        }
    }

    // MARK: - Tree

    private func treeView(tree: CoverSceneData.TreeData, size: CGSize) -> some View {
        let px = tree.x * size.width
        let py = tree.y * size.height
        let tw = tree.w * size.width
        let th = tree.h * size.height

        return ZStack {
            // Trunk
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: 0x4A3A2A, alpha: 0.7))
                .frame(width: tw * 0.15, height: th * 0.35)
                .position(x: px, y: py + th * 0.15)

            // Canopy
            canopyPath(px: px, py: py, tw: tw, th: th)
                .fill(Color(hex: 0x2E5438, alpha: 0.85))
        }
    }

    private func canopyPath(px: CGFloat, py: CGFloat, tw: CGFloat, th: CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: px, y: py - th * 0.35))
            p.addQuadCurve(
                to: CGPoint(x: px - tw * 0.5, y: py + th * 0.05),
                control: CGPoint(x: px - tw * 0.55, y: py - th * 0.1)
            )
            p.addQuadCurve(
                to: CGPoint(x: px + tw * 0.5, y: py + th * 0.05),
                control: CGPoint(x: px, y: py + th * 0.12)
            )
            p.addQuadCurve(
                to: CGPoint(x: px, y: py - th * 0.35),
                control: CGPoint(x: px + tw * 0.55, y: py - th * 0.1)
            )
        }
    }

    // MARK: - Boat

    private func boatView(boat: CoverSceneData.BoatData, size: CGSize) -> some View {
        let px = boat.x * size.width
        let py = boat.y * size.height
        let bw = boat.w * size.width
        let bh = bw * 0.35

        return ZStack {
            // Hull
            Path { p in
                p.move(to: CGPoint(x: px - bw * 0.4, y: py))
                p.addLine(to: CGPoint(x: px + bw * 0.4, y: py))
                p.addLine(to: CGPoint(x: px + bw * 0.25, y: py + bh))
                p.addLine(to: CGPoint(x: px - bw * 0.25, y: py + bh))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x8B6B4A, alpha: 0.85))

            // Mast
            Rectangle()
                .fill(Color(hex: 0x5A4A3A, alpha: 0.8))
                .frame(width: 2, height: bw * 0.8)
                .position(x: px, y: py - bw * 0.35)

            // Sail
            Path { p in
                p.move(to: CGPoint(x: px + 2, y: py - bw * 0.7))
                p.addQuadCurve(
                    to: CGPoint(x: px + 2, y: py - bw * 0.05),
                    control: CGPoint(x: px + bw * 0.4, y: py - bw * 0.35)
                )
                p.addLine(to: CGPoint(x: px + 2, y: py - bw * 0.7))
            }
            .fill(Color.white.opacity(0.75))
        }
    }

    // MARK: - Wave line

    private func waveLineView(y: CGFloat, size: CGSize) -> some View {
        Path { p in
            let w = size.width
            let py = y * size.height
            p.move(to: CGPoint(x: 0, y: py))
            for i in 0..<30 {
                let t = CGFloat(i) / 30.0
                let x = t * w
                let wiggle = sin(t * .pi * 6) * size.height * 0.006
                p.addLine(to: CGPoint(x: x, y: py + wiggle))
            }
        }
        .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }

    // MARK: - Castle

    private func castleView(x: CGFloat, size: CGSize) -> some View {
        let px = x * size.width
        let py: CGFloat = 0.48 * size.height
        let w = size.width * 0.22
        let h = w * 0.7

        return Path { p in
            p.move(to: CGPoint(x: px - w * 0.5, y: py))
            p.addLine(to: CGPoint(x: px - w * 0.5, y: py - h * 0.6))
            p.addLine(to: CGPoint(x: px - w * 0.4, y: py - h * 0.6))
            p.addLine(to: CGPoint(x: px - w * 0.4, y: py - h))
            p.addLine(to: CGPoint(x: px - w * 0.3, y: py - h * 0.85))
            p.addLine(to: CGPoint(x: px - w * 0.2, y: py - h))
            p.addLine(to: CGPoint(x: px - w * 0.2, y: py - h * 0.6))
            p.addLine(to: CGPoint(x: px + w * 0.2, y: py - h * 0.6))
            p.addLine(to: CGPoint(x: px + w * 0.2, y: py - h * 0.9))
            p.addLine(to: CGPoint(x: px + w * 0.35, y: py - h * 1.1))
            p.addLine(to: CGPoint(x: px + w * 0.5, y: py - h * 0.9))
            p.addLine(to: CGPoint(x: px + w * 0.5, y: py - h * 0.6))
            p.addLine(to: CGPoint(x: px + w * 0.5, y: py))
            p.closeSubpath()
        }
        .fill(Color(hex: 0x3A2A4A, alpha: 0.6))
    }

    // MARK: - Mushroom

    private func mushroomView(x: CGFloat, y: CGFloat, size: CGSize) -> some View {
        let px = x * size.width
        let py = y * size.height
        let mw = size.width * 0.06

        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0xE8D8C0, alpha: 0.8))
                .frame(width: mw * 0.3, height: mw * 0.5)
                .position(x: px, y: py + mw * 0.15)

            Ellipse()
                .fill(Color(hex: 0xC85A5A, alpha: 0.7))
                .frame(width: mw, height: mw * 0.5)
                .position(x: px, y: py - mw * 0.08)
        }
    }

    // MARK: - Title

    @ViewBuilder
    private func coverTitle(title: String, size: CGSize) -> some View {
        VStack(spacing: size.height * 0.015) {
            Text(title)
                .font(.custom(MP.F.display, size: titleFontSize(for: size)).weight(.bold))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .multilineTextAlignment(.center)
                .lineSpacing(size.height * 0.008)
                .lineLimit(3)
                .minimumScaleFactor(0.55)

            if showsBrand {
                Text("MagicPaper Kids")
                    .font(.custom(MP.F.body, size: max(size.width * 0.036, 7)).weight(.bold))
                    .tracking(size.width * 0.01)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, size.width * 0.10)
        .frame(maxWidth: .infinity)
        .frame(height: size.height * 0.24)
        .position(x: size.width / 2, y: size.height * 0.14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isHeader)
    }

    private func titleFontSize(for size: CGSize) -> CGFloat {
        max(size.width * 0.095, 14)
    }
}

// MARK: - Scene Data (pure data, no views)

/// Pre-computed scene properties derived deterministically from theme + palette + seed.
/// All random decisions happen here so the view layer is pure rendering.
struct CoverSceneData {
    let theme: CoverTheme
    let skyColors: [Color]
    let backLandscapeColor: Color
    let midLandscapeColor: Color
    let foregroundColor: Color
    let celestialY: CGFloat
    let celestialX: CGFloat
    let celestialSize: CGFloat
    let hasMoon: Bool

    // Pre-computed motif data
    let trees: [TreeData]
    let stars: [StarData]
    let boat: BoatData
    let waveLineYs: [CGFloat]
    let castleX: CGFloat

    // Hill variation
    let hv1: CGFloat
    let hv2: CGFloat
    let hv3: CGFloat

    struct TreeData {
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
        let h: CGFloat
    }

    struct StarData {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    struct BoatData {
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
    }

    init(theme: CoverTheme, palette: CoverPalette, seed: UInt64, size: CGSize) {
        self.theme = theme
        var rng = SeededRandom(seed: seed &+ 7) // offset from main seed for visual variety

        self.hv1 = CGFloat(rng.nextDouble(in: 0.0...1.0))
        self.hv2 = CGFloat(rng.nextDouble(in: 0.0...1.0))
        self.hv3 = CGFloat(rng.nextDouble(in: 0.0...1.0))
        self.celestialY = CGFloat(rng.nextDouble(in: 0.08...0.22))
        self.celestialX = CGFloat(rng.nextDouble(in: 0.65...0.88))
        self.celestialSize = CGFloat(rng.nextDouble(in: 0.08...0.14))
        self.hasMoon = rng.chance(0.6)

        // Pre-compute trees
        var treeBuf: [TreeData] = []
        let treeCount: Int
        switch theme {
        case .forest: treeCount = 5 + rng.nextInt(upperBound: 4)
        case .snowland: treeCount = 3 + rng.nextInt(upperBound: 2)
        case .garden, .farm: treeCount = 2 + rng.nextInt(upperBound: 3)
        default: treeCount = 3 + rng.nextInt(upperBound: 3)
        }
        for _ in 0..<treeCount {
            let th = CGFloat(rng.nextDouble(in: 0.10...0.22))
            treeBuf.append(TreeData(
                x: CGFloat(rng.nextDouble(in: 0.06...0.94)),
                y: CGFloat(rng.nextDouble(in: 0.48...0.66)),
                w: th * CGFloat(rng.nextDouble(in: 0.35...0.55)),
                h: th
            ))
        }
        self.trees = treeBuf

        // Pre-compute stars/snowflakes/sparkles
        var starBuf: [StarData] = []
        let starCount: Int
        switch theme {
        case .space: starCount = 25
        case .snowland: starCount = 15
        case .fairytale: starCount = 12
        default: starCount = 0
        }
        for _ in 0..<starCount {
            starBuf.append(StarData(
                x: CGFloat(rng.nextDouble(in: 0.05...0.95)),
                y: CGFloat(rng.nextDouble(in: 0.06...0.55)),
                size: CGFloat(rng.nextDouble(in: 1.5...4.0)),
                opacity: rng.nextDouble(in: 0.25...0.75)
            ))
        }
        self.stars = starBuf

        // Boat
        self.boat = BoatData(
            x: CGFloat(rng.nextDouble(in: 0.25...0.55)),
            y: 0.56,
            w: 0.18
        )

        // Wave lines
        var waves: [CGFloat] = []
        for i in 0..<3 {
            waves.append(CGFloat(0.72 + Double(i) * 0.07 + rng.nextDouble(in: -0.01...0.01)))
        }
        self.waveLineYs = waves

        // Castle position
        self.castleX = CGFloat(rng.nextDouble(in: 0.30...0.55))

        // Theme-specific colors
        switch theme {
        case .forest:
            self.skyColors = [Color(hex: 0x2D3A4A), Color(hex: 0x5B7065), Color(hex: 0x8BA88F)]
            self.backLandscapeColor = Color(hex: 0x4A6B52)
            self.midLandscapeColor = Color(hex: 0x3D5A44)
            self.foregroundColor = Color(hex: 0x2E4435)

        case .ocean:
            self.skyColors = [Color(hex: 0x3A5168), Color(hex: 0x6B8EA0), Color(hex: 0x8FB5C4)]
            self.backLandscapeColor = Color(hex: 0x4A7E91)
            self.midLandscapeColor = Color(hex: 0x3A6B7D)
            self.foregroundColor = Color(hex: 0x2A5566)

        case .space:
            self.skyColors = [Color(hex: 0x0F1B2D), Color(hex: 0x1A2744), Color(hex: 0x2A3B5C)]
            self.backLandscapeColor = Color(hex: 0x3B2D5A)
            self.midLandscapeColor = Color(hex: 0x2A2045)
            self.foregroundColor = Color(hex: 0x1A1535)

        case .kingdom:
            self.skyColors = [Color(hex: 0x4A3858), Color(hex: 0x7B6088), Color(hex: 0xC4A0B0)]
            self.backLandscapeColor = Color(hex: 0x6B7A5A)
            self.midLandscapeColor = Color(hex: 0x5A6A4A)
            self.foregroundColor = Color(hex: 0x4A5A3A)

        case .snowland:
            self.skyColors = [Color(hex: 0x3A4C5E), Color(hex: 0x7A98AA), Color(hex: 0xB0C8D5)]
            self.backLandscapeColor = Color(hex: 0xC5D5DE)
            self.midLandscapeColor = Color(hex: 0xB0C0CC)
            self.foregroundColor = Color(hex: 0xDDE8EE)

        case .garden:
            self.skyColors = [Color(hex: 0x5A7A88), Color(hex: 0x8AABB5), Color(hex: 0xD5C8A0)]
            self.backLandscapeColor = Color(hex: 0x7AAA6A)
            self.midLandscapeColor = Color(hex: 0x5A8A4A)
            self.foregroundColor = Color(hex: 0x4A7A3A)

        case .fairytale:
            self.skyColors = [Color(hex: 0x4A3868), Color(hex: 0x8A68A8), Color(hex: 0xC8A0C0)]
            self.backLandscapeColor = Color(hex: 0x6A8A60)
            self.midLandscapeColor = Color(hex: 0x5A7A50)
            self.foregroundColor = Color(hex: 0x4A6A40)

        case .pirate:
            self.skyColors = [Color(hex: 0x3A4858), Color(hex: 0x7A6A50), Color(hex: 0xC8A870)]
            self.backLandscapeColor = Color(hex: 0x4A7080)
            self.midLandscapeColor = Color(hex: 0x3A6070)
            self.foregroundColor = Color(hex: 0x2A5060)

        case .prehistoric:
            self.skyColors = [Color(hex: 0x4A4030), Color(hex: 0x7A6A50), Color(hex: 0xB0A080)]
            self.backLandscapeColor = Color(hex: 0x6A7A50)
            self.midLandscapeColor = Color(hex: 0x5A6A40)
            self.foregroundColor = Color(hex: 0x4A5A30)

        case .farm:
            self.skyColors = [Color(hex: 0x5A7A90), Color(hex: 0x8AB0C0), Color(hex: 0xD0C8A0)]
            self.backLandscapeColor = Color(hex: 0x6A9A50)
            self.midLandscapeColor = Color(hex: 0x5A8A40)
            self.foregroundColor = Color(hex: 0x4A7A30)

        case .robot:
            self.skyColors = [Color(hex: 0x1A2A3A), Color(hex: 0x3A4A5A), Color(hex: 0x5A6A7A)]
            self.backLandscapeColor = Color(hex: 0x4A5A6A)
            self.midLandscapeColor = Color(hex: 0x3A4A5A)
            self.foregroundColor = Color(hex: 0x2A3A4A)

        case .circus:
            self.skyColors = [Color(hex: 0x3A2848), Color(hex: 0x6A4878), Color(hex: 0xC888A0)]
            self.backLandscapeColor = Color(hex: 0x5A7A50)
            self.midLandscapeColor = Color(hex: 0x4A6A40)
            self.foregroundColor = Color(hex: 0x3A5A30)
        }
    }

    // MARK: - Landscape Paths

    func backLandscapePath(in size: CGSize) -> Path {
        rollingHillPath(in: size, baseY: 0.45 + hv1 * 0.08, amplitude: 0.06 + hv2 * 0.04, frequency: 1.5 + hv3 * 0.5, phase: hv1 * .pi)
    }

    func midLandscapePath(in size: CGSize) -> Path {
        rollingHillPath(in: size, baseY: 0.55 + hv2 * 0.06, amplitude: 0.05 + hv1 * 0.03, frequency: 2.0 + hv3 * 0.8, phase: hv2 * .pi * 1.3)
    }

    func foregroundPath(in size: CGSize) -> Path {
        switch theme {
        case .ocean:
            return wavePath(in: size, baseY: 0.68 + hv3 * 0.04)
        default:
            return rollingHillPath(in: size, baseY: 0.72 + hv3 * 0.04, amplitude: 0.03 + hv2 * 0.02, frequency: 2.5 + hv1 * 1.0, phase: hv3 * .pi * 0.7)
        }
    }

    private func rollingHillPath(in size: CGSize, baseY: CGFloat, amplitude: CGFloat, frequency: CGFloat, phase: CGFloat) -> Path {
        Path { p in
            let w = size.width
            let h = size.height
            let steps = 40
            p.move(to: CGPoint(x: 0, y: h))
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * w
                let y = h * (baseY + amplitude * sin(t * frequency * .pi * 2 + phase))
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.closeSubpath()
        }
    }

    private func wavePath(in size: CGSize, baseY: CGFloat) -> Path {
        Path { p in
            let w = size.width
            let h = size.height
            let steps = 50
            p.move(to: CGPoint(x: 0, y: h))
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let x = t * w
                let wave1 = sin(t * 3.0 * .pi * 2 + hv1 * .pi) * 0.025
                let wave2 = sin(t * 5.0 * .pi * 2 + hv2 * .pi) * 0.012
                let y = h * (baseY + wave1 + wave2)
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.closeSubpath()
        }
    }
}

// MARK: - Thumbnail Variant

extension MagicPaperCoverView {

    /// A compact variant for library card thumbnails — no title, fills given frame.
    static func thumbnail(
        for configuration: MagicPaperCoverConfiguration
    ) -> MagicPaperCoverView {
        MagicPaperCoverView(
            configuration: configuration,
            title: nil,
            showsBrand: false,
            fillsProposedSize: true
        )
    }
}
