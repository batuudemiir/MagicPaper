import Foundation

// MARK: - Cover Layout Engine

/// Generates tile slots for each of the 12 cover layouts.
///
/// Every layout produces a list of `TileSlot`s — positions and sizes in
/// normalized coordinates. The generator later fills in shape, color,
/// rotation, and texture. Layouts only decide *where* tiles go.
enum CoverLayoutEngine {

    /// The cover's aspect ratio (width ÷ height = 2/3).
    private static let ar: Double = CoverConstants.aspectRatio

    /// Generates tile positions and sizes for the given layout.
    static func generateSlots(
        layout: CoverLayout,
        rng: inout SeededRandom
    ) -> [TileSlot] {
        switch layout {
        case .balancedGrid:       return balancedGrid(rng: &rng)
        case .verticalStack:      return verticalStack(rng: &rng)
        case .diagonalFlow:       return diagonalFlow(rng: &rng)
        case .cornerCluster:      return cornerCluster(rng: &rng)
        case .centralIsland:      return centralIsland(rng: &rng)
        case .scatteredPieces:    return scatteredPieces(rng: &rng)
        case .bottomHeavy:        return bottomHeavy(rng: &rng)
        case .topHeavy:           return topHeavy(rng: &rng)
        case .overlappingBlocks:  return overlappingBlocks(rng: &rng)
        case .frame:              return frame(rng: &rng)
        case .staircase:          return staircase(rng: &rng)
        case .asymmetricBalance:  return asymmetricBalance(rng: &rng)
        }
    }

    // MARK: - Size Helpers

    /// Random tile width for a given size category (fraction of cover width).
    private static func tileWidth(
        _ category: TileSizeCategory,
        rng: inout SeededRandom
    ) -> Double {
        switch category {
        case .small:  return rng.nextDouble(in: 0.12...0.20)
        case .medium: return rng.nextDouble(in: 0.20...0.32)
        case .large:  return rng.nextDouble(in: 0.30...0.48)
        case .xl:     return rng.nextDouble(in: 0.45...0.60)
        }
    }

    /// Converts a width to height for the given shape preference.
    private static func tileHeight(
        forWidth w: Double,
        shape: ShapeHint,
        rng: inout SeededRandom
    ) -> Double {
        switch shape {
        case .square:
            return w * ar * rng.nextDouble(in: 0.92...1.08)
        case .wideRect:
            return w * ar * rng.nextDouble(in: 0.50...0.72)
        case .tallRect:
            return w * ar * rng.nextDouble(in: 1.25...1.65)
        case .varied:
            return w * ar * rng.nextDouble(in: 0.65...1.35)
        }
    }

    private enum ShapeHint {
        case square, wideRect, tallRect, varied
    }

    /// Creates a tile slot, clamping within safe bounds.
    private static func makeSlot(
        x: Double, y: Double,
        category: TileSizeCategory,
        shape: ShapeHint = .varied,
        rng: inout SeededRandom
    ) -> TileSlot {
        let w = tileWidth(category, rng: &rng)
        let h = tileHeight(forWidth: w, shape: shape, rng: &rng)
        return TileSlot(
            x: max(0.02, min(x, 0.96 - w)),
            y: max(0.26, min(y, 0.96 - h)),
            width: w,
            height: h,
            sizeCategory: category
        )
    }

    /// Adds small position jitter for handmade feel.
    private static func jitter(
        _ value: Double,
        amount: Double = 0.03,
        rng: inout SeededRandom
    ) -> Double {
        value + rng.nextDouble(in: (-amount)...amount)
    }

    // MARK: - 01: Balanced Grid

    private static func balancedGrid(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Row 1: one large + one medium tile
        let row1Y = rng.nextDouble(in: 0.30...0.34)
        slots.append(makeSlot(x: jitter(0.08, rng: &rng), y: row1Y,
                              category: .large, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(0.52, rng: &rng), y: jitter(row1Y, rng: &rng),
                              category: .medium, shape: .tallRect, rng: &rng))

        // Row 2: two medium tiles + optional small
        let row2Y = rng.nextDouble(in: 0.52...0.58)
        slots.append(makeSlot(x: jitter(0.07, rng: &rng), y: row2Y,
                              category: .medium, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.48, rng: &rng), y: jitter(row2Y, rng: &rng),
                              category: .medium, shape: .square, rng: &rng))

        // Small tile in gap
        slots.append(makeSlot(x: jitter(0.72, rng: &rng), y: jitter(row2Y + 0.06, rng: &rng),
                              category: .small, shape: .square, rng: &rng))

        // Optional 6th/7th tile in bottom area
        if rng.chance(0.7) {
            slots.append(makeSlot(x: jitter(0.25, rng: &rng), y: rng.nextDouble(in: 0.74...0.80),
                                  category: .small, shape: .wideRect, rng: &rng))
        }
        if rng.chance(0.4) {
            slots.append(makeSlot(x: jitter(0.60, rng: &rng), y: rng.nextDouble(in: 0.76...0.82),
                                  category: .small, shape: .varied, rng: &rng))
        }

        return slots
    }

    // MARK: - 02: Vertical Stack

    private static func verticalStack(rng: inout SeededRandom) -> [TileSlot] {
        let count = rng.nextInt(in: 5...8)
        var slots: [TileSlot] = []
        let yStep = 0.58 / Double(count)

        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            let xBase = 0.15 + sin(t * .pi * 1.3) * 0.25
            let yBase = 0.30 + Double(i) * yStep

            let category: TileSizeCategory
            if i == 1 || i == 3 { category = .large }
            else if i == 0 || i == count - 1 { category = .small }
            else { category = .medium }

            let shape: ShapeHint = (i % 2 == 0) ? .wideRect : .tallRect
            slots.append(makeSlot(
                x: jitter(xBase, amount: 0.05, rng: &rng),
                y: jitter(yBase, amount: 0.02, rng: &rng),
                category: category, shape: shape, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 03: Diagonal Flow

    private static func diagonalFlow(rng: inout SeededRandom) -> [TileSlot] {
        let count = rng.nextInt(in: 6...8)
        var slots: [TileSlot] = []

        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            // Diagonal from upper-left to lower-right across Zone B
            let xBase = 0.05 + t * 0.55
            let yBase = 0.30 + t * 0.50
            // Perpendicular jitter
            let perp = rng.nextDouble(in: -0.08...0.08)

            let category: TileSizeCategory
            if i == 2 || i == 4 { category = .large }
            else if i == 0 || i == count - 1 { category = .small }
            else { category = .medium }

            slots.append(makeSlot(
                x: jitter(xBase + perp, amount: 0.03, rng: &rng),
                y: jitter(yBase - perp * 0.5, amount: 0.02, rng: &rng),
                category: category, shape: .varied, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 04: Corner Cluster

    private static func cornerCluster(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Pick a corner quadrant for the cluster
        let useRight = rng.chance(0.5)
        let useBottom = rng.chance(0.6) // slight preference for bottom
        let clusterX = useRight ? 0.45 : 0.06
        let clusterY = useBottom ? 0.52 : 0.30

        // Main cluster: 1 large + 2 medium
        slots.append(makeSlot(x: jitter(clusterX, amount: 0.04, rng: &rng),
                              y: jitter(clusterY, amount: 0.03, rng: &rng),
                              category: .large, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(clusterX + 0.18, amount: 0.04, rng: &rng),
                              y: jitter(clusterY + 0.12, amount: 0.03, rng: &rng),
                              category: .medium, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(clusterX - 0.04, amount: 0.03, rng: &rng),
                              y: jitter(clusterY + 0.22, amount: 0.03, rng: &rng),
                              category: .medium, shape: .tallRect, rng: &rng))

        // Counterbalance: 2–3 small tiles in the opposite region
        let oppX = useRight ? 0.08 : 0.62
        let oppY = useBottom ? 0.30 : 0.65
        slots.append(makeSlot(x: jitter(oppX, amount: 0.05, rng: &rng),
                              y: jitter(oppY, amount: 0.04, rng: &rng),
                              category: .small, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(oppX + 0.12, amount: 0.04, rng: &rng),
                              y: jitter(oppY + 0.10, amount: 0.04, rng: &rng),
                              category: .small, shape: .varied, rng: &rng))

        if rng.chance(0.6) {
            slots.append(makeSlot(x: jitter(oppX - 0.04, amount: 0.03, rng: &rng),
                                  y: jitter(oppY + 0.18, amount: 0.04, rng: &rng),
                                  category: .small, shape: .wideRect, rng: &rng))
        }

        return slots
    }

    // MARK: - 05: Central Island

    private static func centralIsland(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Central anchor
        let cx = rng.nextDouble(in: 0.18...0.28)
        let cy = rng.nextDouble(in: 0.38...0.45)
        slots.append(makeSlot(x: cx, y: cy, category: .xl, shape: .square, rng: &rng))

        // Surrounding medium tiles
        let offsets: [(Double, Double)] = [
            (-0.12, -0.14), (0.30, -0.06), (0.32, 0.18),
            (-0.10, 0.22), (0.12, 0.28)
        ]
        for (dx, dy) in offsets.prefix(rng.nextInt(in: 3...5)) {
            slots.append(makeSlot(
                x: jitter(cx + dx, amount: 0.04, rng: &rng),
                y: jitter(cy + dy, amount: 0.03, rng: &rng),
                category: .medium, shape: .varied, rng: &rng
            ))
        }

        // 1–2 small satellite tiles
        for _ in 0..<rng.nextInt(in: 1...2) {
            slots.append(makeSlot(
                x: rng.nextDouble(in: 0.06...0.78),
                y: rng.nextDouble(in: 0.28...0.82),
                category: .small, shape: .square, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 06: Scattered Pieces

    private static func scatteredPieces(rng: inout SeededRandom) -> [TileSlot] {
        let count = rng.nextInt(in: 6...10)
        var slots: [TileSlot] = []

        // Use a 3×4 invisible grid for alignment discipline
        let cols = 3
        let rows = 4
        let cellW = 0.86 / Double(cols)
        let cellH = 0.62 / Double(rows)
        var cells = [(Int, Int)]()
        for r in 0..<rows {
            for c in 0..<cols {
                cells.append((c, r))
            }
        }
        cells = rng.shuffled(cells)

        let desired = min(count, cells.count)
        for i in 0..<desired {
            let (c, r) = cells[i]
            let xBase = 0.07 + Double(c) * cellW + cellW * 0.15
            let yBase = 0.30 + Double(r) * cellH + cellH * 0.15

            let category: TileSizeCategory
            if i == 0 { category = .large }
            else if i < 3 { category = .medium }
            else { category = .small }

            slots.append(makeSlot(
                x: jitter(xBase, amount: 0.04, rng: &rng),
                y: jitter(yBase, amount: 0.03, rng: &rng),
                category: category, shape: .varied, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 07: Bottom Heavy

    private static func bottomHeavy(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Bottom zone (y 0.50–0.85): large + medium tiles
        slots.append(makeSlot(x: jitter(0.08, amount: 0.04, rng: &rng),
                              y: rng.nextDouble(in: 0.52...0.58),
                              category: .large, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.50, amount: 0.05, rng: &rng),
                              y: rng.nextDouble(in: 0.50...0.56),
                              category: .medium, shape: .tallRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.10, amount: 0.04, rng: &rng),
                              y: rng.nextDouble(in: 0.68...0.74),
                              category: .medium, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(0.46, amount: 0.05, rng: &rng),
                              y: rng.nextDouble(in: 0.70...0.78),
                              category: .medium, shape: .wideRect, rng: &rng))

        // Top accent tiles (y 0.30–0.48): 1–2 small tiles
        slots.append(makeSlot(x: jitter(0.55, amount: 0.08, rng: &rng),
                              y: rng.nextDouble(in: 0.30...0.38),
                              category: .small, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(0.14, amount: 0.06, rng: &rng),
                              y: rng.nextDouble(in: 0.34...0.44),
                              category: .small, shape: .wideRect, rng: &rng))

        // Optional 7th/8th tile
        if rng.chance(0.6) {
            slots.append(makeSlot(x: jitter(0.68, amount: 0.06, rng: &rng),
                                  y: rng.nextDouble(in: 0.62...0.72),
                                  category: .small, shape: .varied, rng: &rng))
        }
        if rng.chance(0.3) {
            slots.append(makeSlot(x: jitter(0.32, amount: 0.05, rng: &rng),
                                  y: rng.nextDouble(in: 0.80...0.84),
                                  category: .small, shape: .square, rng: &rng))
        }

        return slots
    }

    // MARK: - 08: Top Heavy

    private static func topHeavy(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Upper-middle zone (y 0.30–0.56): main mass
        slots.append(makeSlot(x: jitter(0.10, amount: 0.04, rng: &rng),
                              y: rng.nextDouble(in: 0.30...0.36),
                              category: .large, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.48, amount: 0.06, rng: &rng),
                              y: rng.nextDouble(in: 0.32...0.38),
                              category: .medium, shape: .square, rng: &rng))
        slots.append(makeSlot(x: jitter(0.08, amount: 0.04, rng: &rng),
                              y: rng.nextDouble(in: 0.44...0.52),
                              category: .medium, shape: .tallRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.42, amount: 0.05, rng: &rng),
                              y: rng.nextDouble(in: 0.46...0.54),
                              category: .medium, shape: .wideRect, rng: &rng))

        // Lower accent: 1–2 small tiles
        slots.append(makeSlot(x: jitter(0.25, amount: 0.08, rng: &rng),
                              y: rng.nextDouble(in: 0.68...0.78),
                              category: .small, shape: .square, rng: &rng))

        if rng.chance(0.6) {
            slots.append(makeSlot(x: jitter(0.58, amount: 0.08, rng: &rng),
                                  y: rng.nextDouble(in: 0.72...0.80),
                                  category: .small, shape: .varied, rng: &rng))
        }
        if rng.chance(0.4) {
            slots.append(makeSlot(x: jitter(0.70, amount: 0.06, rng: &rng),
                                  y: rng.nextDouble(in: 0.40...0.50),
                                  category: .small, shape: .wideRect, rng: &rng))
        }

        return slots
    }

    // MARK: - 09: Overlapping Blocks

    private static func overlappingBlocks(rng: inout SeededRandom) -> [TileSlot] {
        let count = rng.nextInt(in: 5...8)
        var slots: [TileSlot] = []

        // Start with an anchor tile
        let startX = rng.nextDouble(in: 0.12...0.28)
        let startY = rng.nextDouble(in: 0.32...0.42)
        slots.append(makeSlot(x: startX, y: startY, category: .large, shape: .square, rng: &rng))

        // Each subsequent tile overlaps the previous one
        var prevX = startX
        var prevY = startY
        for i in 1..<count {
            let dx = rng.nextDouble(in: 0.08...0.18) * (rng.chance(0.6) ? 1 : -0.3)
            let dy = rng.nextDouble(in: 0.06...0.14)
            prevX += dx
            prevY += dy

            let category: TileSizeCategory
            if i == 1 || i == 3 { category = .medium }
            else if i == count - 1 { category = .small }
            else { category = rng.chance(0.5) ? .medium : .small }

            slots.append(makeSlot(
                x: jitter(prevX, amount: 0.04, rng: &rng),
                y: jitter(prevY, amount: 0.03, rng: &rng),
                category: category, shape: .varied, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 10: Frame

    private static func frame(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []

        // Tiles arranged loosely around the perimeter of Zone B
        // Top edge
        slots.append(makeSlot(x: jitter(0.06, amount: 0.03, rng: &rng),
                              y: rng.nextDouble(in: 0.30...0.36),
                              category: .medium, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.50, amount: 0.06, rng: &rng),
                              y: rng.nextDouble(in: 0.28...0.34),
                              category: .small, shape: .square, rng: &rng))

        // Right edge
        slots.append(makeSlot(x: jitter(0.62, amount: 0.06, rng: &rng),
                              y: rng.nextDouble(in: 0.38...0.46),
                              category: .medium, shape: .tallRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.58, amount: 0.06, rng: &rng),
                              y: rng.nextDouble(in: 0.58...0.66),
                              category: .small, shape: .square, rng: &rng))

        // Bottom edge
        slots.append(makeSlot(x: jitter(0.35, amount: 0.08, rng: &rng),
                              y: rng.nextDouble(in: 0.74...0.80),
                              category: .large, shape: .wideRect, rng: &rng))
        slots.append(makeSlot(x: jitter(0.06, amount: 0.03, rng: &rng),
                              y: rng.nextDouble(in: 0.72...0.78),
                              category: .small, shape: .square, rng: &rng))

        // Left edge
        slots.append(makeSlot(x: jitter(0.04, amount: 0.03, rng: &rng),
                              y: rng.nextDouble(in: 0.46...0.56),
                              category: .medium, shape: .tallRect, rng: &rng))

        // Optional extra tiles
        if rng.chance(0.5) {
            slots.append(makeSlot(x: jitter(0.72, amount: 0.05, rng: &rng),
                                  y: rng.nextDouble(in: 0.74...0.80),
                                  category: .small, shape: .varied, rng: &rng))
        }
        if rng.chance(0.5) {
            slots.append(makeSlot(x: jitter(0.30, amount: 0.06, rng: &rng),
                                  y: rng.nextDouble(in: 0.28...0.34),
                                  category: .small, shape: .wideRect, rng: &rng))
        }
        if rng.chance(0.3) {
            slots.append(makeSlot(x: jitter(0.04, amount: 0.02, rng: &rng),
                                  y: rng.nextDouble(in: 0.64...0.70),
                                  category: .small, shape: .square, rng: &rng))
        }

        return slots
    }

    // MARK: - 11: Staircase

    private static func staircase(rng: inout SeededRandom) -> [TileSlot] {
        let count = rng.nextInt(in: 5...8)
        var slots: [TileSlot] = []
        let goRight = rng.chance(0.5)

        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            let xBase: Double
            if goRight {
                xBase = 0.06 + t * 0.52
            } else {
                xBase = 0.58 - t * 0.52
            }
            let yBase = 0.30 + t * 0.50

            let category: TileSizeCategory
            if i == 0 || i == count / 2 { category = .large }
            else if i < count - 1 { category = .medium }
            else { category = .small }

            let shape: ShapeHint
            switch i % 3 {
            case 0: shape = .square
            case 1: shape = .wideRect
            default: shape = .tallRect
            }

            slots.append(makeSlot(
                x: jitter(xBase, amount: 0.04, rng: &rng),
                y: jitter(yBase, amount: 0.03, rng: &rng),
                category: category, shape: shape, rng: &rng
            ))
        }

        return slots
    }

    // MARK: - 12: Asymmetric Balance

    private static func asymmetricBalance(rng: inout SeededRandom) -> [TileSlot] {
        var slots: [TileSlot] = []
        let weightLeft = rng.chance(0.5)

        // Heavy side: 4–5 tiles
        let heavyX = weightLeft ? 0.05 : 0.38
        let heavyRange = weightLeft ? 0.0...0.18 : 0.0...0.20

        // Large anchor
        slots.append(makeSlot(
            x: jitter(heavyX, amount: 0.03, rng: &rng),
            y: rng.nextDouble(in: 0.30...0.38),
            category: .large, shape: .square, rng: &rng
        ))

        // Medium tiles on heavy side
        slots.append(makeSlot(
            x: jitter(heavyX + rng.nextDouble(in: heavyRange), amount: 0.03, rng: &rng),
            y: rng.nextDouble(in: 0.52...0.60),
            category: .medium, shape: .tallRect, rng: &rng
        ))
        slots.append(makeSlot(
            x: jitter(heavyX + rng.nextDouble(in: heavyRange) + 0.18, amount: 0.04, rng: &rng),
            y: rng.nextDouble(in: 0.44...0.52),
            category: .medium, shape: .wideRect, rng: &rng
        ))
        slots.append(makeSlot(
            x: jitter(heavyX + 0.05, amount: 0.04, rng: &rng),
            y: rng.nextDouble(in: 0.70...0.78),
            category: .medium, shape: .varied, rng: &rng
        ))

        // Light side: 2–3 small counterbalancing tiles
        let lightX = weightLeft ? 0.58 : 0.08
        slots.append(makeSlot(
            x: jitter(lightX, amount: 0.06, rng: &rng),
            y: rng.nextDouble(in: 0.40...0.52),
            category: .small, shape: .square, rng: &rng
        ))
        slots.append(makeSlot(
            x: jitter(lightX + 0.08, amount: 0.06, rng: &rng),
            y: rng.nextDouble(in: 0.60...0.72),
            category: .small, shape: .varied, rng: &rng
        ))

        // Optional extra tiles
        if rng.chance(0.55) {
            slots.append(makeSlot(
                x: jitter(lightX - 0.04, amount: 0.04, rng: &rng),
                y: rng.nextDouble(in: 0.74...0.82),
                category: .small, shape: .wideRect, rng: &rng
            ))
        }
        if rng.chance(0.45) {
            slots.append(makeSlot(
                x: jitter(heavyX + 0.22, amount: 0.05, rng: &rng),
                y: rng.nextDouble(in: 0.34...0.42),
                category: .small, shape: .square, rng: &rng
            ))
        }

        return slots
    }
}
