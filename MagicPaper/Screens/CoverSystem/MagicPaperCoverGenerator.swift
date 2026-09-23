import Foundation

/// Produces deterministic cover configurations from book IDs.
///
/// The generator makes every design decision — palette, layout, tile shapes,
/// positions, colors, texture, and signature — from a single stable seed.
/// It never draws anything; it only produces data. The renderer consumes
/// the output.
///
/// ```
/// Book ID → Stable Hash → Seed → Configuration
/// ```
///
/// Same book ID always yields the same configuration, across app restarts,
/// devices, and OS versions.
final class MagicPaperCoverGenerator {

    private let validator = CoverCompositionValidator()

    /// Generates a complete cover configuration for the given book ID.
    ///
    /// This is a pure function: calling it with the same `bookID` and `theme`
    /// always returns an identical configuration.
    func generate(bookID: String, theme: CoverTheme = .forest) -> MagicPaperCoverConfiguration {
        let seed = MagicPaperCoverSeed.seed(for: bookID)
        var rng = SeededRandom(seed: seed)

        // 1. Select palette (uniform — all palettes are equally curated)
        let paletteID = rng.pick(from: CoverPaletteID.allCases)
        let palette = CoverPalette.palette(for: paletteID)

        // 2. Select layout (weighted — stronger layouts appear more often)
        let layout = selectLayout(rng: &rng)

        // 3. Generate tile slots from layout
        let slots = CoverLayoutEngine.generateSlots(layout: layout, rng: &rng)

        // 4. Convert slots into full tile configurations
        let tiles = buildTiles(from: slots, palette: palette, rng: &rng)

        // 5. Generate signature motif (70% chance)
        let signature = buildSignature(rng: &rng)

        // 6. Assemble configuration
        let config = MagicPaperCoverConfiguration(
            id: deterministicUUID(rng: &rng),
            bookID: bookID,
            seed: seed,
            systemVersion: MagicPaperCoverSeed.systemVersion,
            theme: theme,
            layout: layout,
            palette: paletteID,
            tiles: tiles,
            signature: signature
        )

        // 7. Validate (log violations in debug, but always return the config)
        #if DEBUG
        let result = validator.validate(config)
        if !result.isValid {
            print("[CoverSystem] Validation issues for \(bookID): \(result.violations.map(\.rawValue))")
        }
        #endif

        return config
    }

    /// Stateless convenience — no need to instantiate the generator.
    static func configuration(for bookID: String, theme: CoverTheme = .forest) -> MagicPaperCoverConfiguration {
        MagicPaperCoverGenerator().generate(bookID: bookID, theme: theme)
    }

    // MARK: - Layout Selection (Weighted)

    private func selectLayout(rng: inout SeededRandom) -> CoverLayout {
        let weighted = CoverLayout.allCases.map { ($0, $0.selectionWeight) }
        return rng.weightedPick(from: weighted)
    }

    // MARK: - Tile Building

    private func buildTiles(
        from slots: [TileSlot],
        palette: CoverPalette,
        rng: inout SeededRandom
    ) -> [CoverTileConfiguration] {
        let tileColors = palette.tileColors
        var lastColor: MagicPaperCoverColor? = nil

        return slots.enumerated().map { index, slot in
            let shape = selectShape(for: slot, rng: &rng)

            // Pick a color that differs from the previous tile
            var available = tileColors
            if let last = lastColor, available.count > 1 {
                available.removeAll { $0 == last }
            }
            let color = available[rng.nextInt(upperBound: available.count)]
            lastColor = color

            return CoverTileConfiguration(
                id: deterministicUUID(rng: &rng),
                shape: shape,
                x: slot.x,
                y: slot.y,
                width: slot.width,
                height: slot.height,
                rotation: rng.nextDouble(in: -6...6),
                colorToken: color,
                zIndex: index,
                textureIntensity: rng.nextDouble(in: 0.05...0.14),
                cornerRadius: cornerRadius(for: shape, slot: slot, rng: &rng)
            )
        }
    }

    /// Selects a tile shape based on the slot's size and some randomness.
    private func selectShape(
        for slot: TileSlot,
        rng: inout SeededRandom
    ) -> CoverTileShape {
        // Larger tiles tend toward organic/rounded; smaller toward square/fragment
        switch slot.sizeCategory {
        case .xl, .large:
            return rng.weightedPick(from: [
                (.rounded, 0.25),
                (.organic, 0.30),
                (.rectangleHorizontal, 0.15),
                (.rectangleVertical, 0.15),
                (.square, 0.15)
            ])
        case .medium:
            return rng.weightedPick(from: [
                (.square, 0.20),
                (.rectangleHorizontal, 0.20),
                (.rectangleVertical, 0.20),
                (.rounded, 0.15),
                (.organic, 0.15),
                (.paperFragment, 0.10)
            ])
        case .small:
            return rng.weightedPick(from: [
                (.square, 0.30),
                (.rounded, 0.25),
                (.paperFragment, 0.20),
                (.organic, 0.10),
                (.rectangleHorizontal, 0.10),
                (.rectangleVertical, 0.05)
            ])
        }
    }

    /// Corner radius as a fraction of the shorter tile dimension.
    private func cornerRadius(
        for shape: CoverTileShape,
        slot: TileSlot,
        rng: inout SeededRandom
    ) -> Double {
        switch shape {
        case .square, .rectangleHorizontal, .rectangleVertical:
            return rng.nextDouble(in: 0.04...0.10)
        case .rounded:
            return rng.nextDouble(in: 0.18...0.30)
        case .organic:
            return rng.nextDouble(in: 0.12...0.22)
        case .paperFragment:
            return rng.nextDouble(in: 0.02...0.06)
        }
    }

    // MARK: - Signature

    private func buildSignature(rng: inout SeededRandom) -> CoverSignature? {
        // 70% of covers have a motif; 30% have none
        guard rng.chance(0.70) else { return nil }

        let type = rng.pick(from: CoverSignatureType.motifCases)
        let zone = CoverConstants.signatureZone

        return CoverSignature(
            type: type,
            x: rng.nextDouble(in: 0.20...0.80),
            y: rng.nextDouble(in: zone.yStart...zone.yEnd),
            scale: rng.nextDouble(in: 0.015...0.04),
            rotation: rng.nextDouble(in: -15...15)
        )
    }

    // MARK: - Deterministic UUID

    /// Produces a UUID deterministically from the RNG state.
    ///
    /// This ensures that the configuration's `id` and tile `id`s are stable
    /// across regenerations.
    private func deterministicUUID(rng: inout SeededRandom) -> UUID {
        let a = rng.next()
        let b = rng.next()
        let hex = String(format: "%016llX%016llX", a, b)
        let formatted = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.suffix(12))"
        return UUID(uuidString: formatted) ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
}
