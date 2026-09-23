import SwiftUI

// MARK: - Cover Gallery Preview

/// Development-only gallery for inspecting the cover system.
///
/// Generates 100 deterministic sample covers and displays them in a
/// scrollable 3-column grid. Includes a debug overlay showing each
/// cover's layout, palette, seed, tile count, and signature.
///
/// Use this to verify:
/// 1. Every cover looks like MagicPaper (brand consistency).
/// 2. No two covers are identical (variety).
/// 3. Title areas remain readable.
/// 4. Color palettes feel warm and editorial.
/// 5. The whole library looks like one publishing collection.
#if DEBUG
struct MagicPaperCoverGalleryPreview: View {

    @State private var showDebugOverlay = true
    @State private var columns = 3
    @State private var testResults: String = ""
    @State private var showingTests = false

    private let sampleIDs: [String] = (1...100).map { String(format: "Story-%03d", $0) }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                // Test results banner
                if !testResults.isEmpty {
                    Text(testResults)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(testResults.contains("✗") ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(sampleIDs, id: \.self) { bookID in
                        coverCard(bookID: bookID)
                    }
                }
                .padding()
            }
            .navigationTitle("Cover Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showDebugOverlay ? "Hide Debug" : "Show Debug") {
                        showDebugOverlay.toggle()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("2 Columns") { columns = 2 }
                        Button("3 Columns") { columns = 3 }
                        Button("4 Columns") { columns = 4 }
                        Divider()
                        Button("Run Tests") { runTests() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func coverCard(bookID: String) -> some View {
        let themes = CoverTheme.allCases
        let index = sampleIDs.firstIndex(of: bookID) ?? 0
        let theme = themes[index % themes.count]
        let config = MagicPaperCoverGenerator.configuration(for: bookID, theme: theme)

        VStack(spacing: 4) {
            ZStack(alignment: .bottomLeading) {
                MagicPaperCoverView(
                    configuration: config,
                    title: bookID
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if showDebugOverlay {
                    debugOverlay(config: config)
                }
            }
            .aspectRatio(2.0 / 3.0, contentMode: .fit)

            Text(bookID)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func debugOverlay(config: MagicPaperCoverConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            debugLine("L", config.layout.rawValue)
            debugLine("P", config.palette.rawValue)
            debugLine("T", "\(config.tiles.count)")
            debugLine("S", String(format: "%llX", config.seed).prefix(6))
            if let sig = config.signature {
                debugLine("M", sig.type.rawValue)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(3)
    }

    @ViewBuilder
    private func debugLine(_ label: String, _ value: some StringProtocol) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 7, design: .monospaced))
        }
    }

    // MARK: - Tests

    private func runTests() {
        var results: [String] = []

        // Test 1: Determinism — same ID × 100 = identical
        let testID = "DeterminismTest-42"
        let baseline = MagicPaperCoverGenerator.configuration(for: testID)
        var determinismPassed = true
        for _ in 0..<100 {
            let check = MagicPaperCoverGenerator.configuration(for: testID)
            if check.seed != baseline.seed
                || check.layout != baseline.layout
                || check.palette != baseline.palette
                || check.tiles.count != baseline.tiles.count {
                determinismPassed = false
                break
            }
        }
        results.append(determinismPassed ? "✓ Determinism (100×)" : "✗ Determinism FAILED")

        // Test 2: Uniqueness — 100 different IDs = no duplicate seeds
        var seeds = Set<UInt64>()
        var uniqueLayouts = Set<String>()
        for id in sampleIDs {
            let config = MagicPaperCoverGenerator.configuration(for: id)
            seeds.insert(config.seed)
            uniqueLayouts.insert(config.layout.rawValue)
        }
        let uniquePassed = seeds.count == sampleIDs.count
        results.append(uniquePassed ? "✓ Unique seeds (\(seeds.count)/\(sampleIDs.count))" : "✗ Duplicate seeds found")
        results.append("✓ Layout variety: \(uniqueLayouts.count)/\(CoverLayout.allCases.count) used")

        // Test 3: Validation — no invalid configurations
        var invalidCount = 0
        var violations: [String: Int] = [:]
        for id in sampleIDs {
            let config = MagicPaperCoverGenerator.configuration(for: id)
            let result = CoverCompositionValidator().validate(config)
            if !result.isValid {
                invalidCount += 1
                for v in result.violations {
                    violations[v.rawValue, default: 0] += 1
                }
            }
        }
        if invalidCount == 0 {
            results.append("✓ All 100 configs valid")
        } else {
            results.append("✗ \(invalidCount) invalid configs: \(violations)")
        }

        // Test 4: Tile count ranges
        var tileCountOK = true
        for id in sampleIDs {
            let config = MagicPaperCoverGenerator.configuration(for: id)
            if config.tiles.count < 5 || config.tiles.count > 10 {
                tileCountOK = false
                break
            }
        }
        results.append(tileCountOK ? "✓ Tile counts in range" : "✗ Tile count out of range")

        // Test 5: Color count per cover
        var colorCountOK = true
        for id in sampleIDs {
            let config = MagicPaperCoverGenerator.configuration(for: id)
            let colors = Set(config.tiles.map(\.colorToken))
            if colors.count < 2 || colors.count > 5 {
                colorCountOK = false
                break
            }
        }
        results.append(colorCountOK ? "✓ Color counts valid" : "✗ Color count violation")

        // Test 6: Palette distribution
        var paletteCounts: [CoverPaletteID: Int] = [:]
        for id in sampleIDs {
            let config = MagicPaperCoverGenerator.configuration(for: id)
            paletteCounts[config.palette, default: 0] += 1
        }
        let paletteInfo = paletteCounts.map { "\($0.key.rawValue.prefix(6)): \($0.value)" }
            .sorted().joined(separator: ", ")
        results.append("✓ Palettes: \(paletteInfo)")

        // Test 7: Signature distribution
        let sigCount = sampleIDs.filter { id in
            MagicPaperCoverGenerator.configuration(for: id).signature != nil
        }.count
        results.append("✓ Signatures: \(sigCount)/100 (\(sigCount)% with motif)")

        testResults = results.joined(separator: "\n")
    }
}

// MARK: - Preview

#Preview("Cover Gallery") {
    MagicPaperCoverGalleryPreview()
}

#Preview("Forest Cover") {
    let config = MagicPaperCoverGenerator.configuration(for: "Story-007", theme: .forest)
    MagicPaperCoverView(configuration: config, title: "Yelz'in Fısıldayan Orman'daki Yardımcıları")
        .frame(width: 300, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 8)
        .padding()
}

#Preview("Ocean Cover") {
    let config = MagicPaperCoverGenerator.configuration(for: "Story-012", theme: .ocean)
    MagicPaperCoverView(configuration: config, title: "Mercan Denizi'ne Cesur Yolculuk")
        .frame(width: 300, height: 450)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(radius: 8)
        .padding()
}

#Preview("All Themes") {
    let themes: [(CoverTheme, String)] = [
        (.forest, "Sihirli Orman"),
        (.ocean, "Deniz Macerası"),
        (.space, "Yıldızlara Yolculuk"),
        (.kingdom, "Sihirli Krallık"),
        (.snowland, "Kar Diyarı"),
        (.garden, "Gizli Bahçe"),
        (.fairytale, "Peri Masalı"),
        (.pirate, "Korsan Adası"),
        (.prehistoric, "Dinozor Vadisi"),
        (.farm, "Çiftlik Günlüğü"),
        (.robot, "Robot Arkadaşım"),
        (.circus, "Büyülü Sirk"),
    ]
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(themes, id: \.0.rawValue) { theme, title in
                let config = MagicPaperCoverGenerator.configuration(for: "Theme-\(theme.rawValue)", theme: theme)
                VStack(spacing: 6) {
                    MagicPaperCoverView(configuration: config, title: title)
                        .frame(width: 180, height: 270)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 4)
                    Text(theme.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
#endif
