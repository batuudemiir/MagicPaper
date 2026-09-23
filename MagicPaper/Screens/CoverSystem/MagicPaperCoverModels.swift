import Foundation

// MARK: - Cover Configuration

/// The complete description of a single book cover.
///
/// This is a pure data object — it describes *what* to draw, not *how* to draw it.
/// The generator produces it; the renderer consumes it. Neither knows the other.
struct MagicPaperCoverConfiguration: Codable, Identifiable {
    let id: UUID
    let bookID: String
    let seed: UInt64
    let systemVersion: String
    let theme: CoverTheme
    let layout: CoverLayout
    let palette: CoverPaletteID
    let tiles: [CoverTileConfiguration]
    /// `nil` when the seed decides no motif (≈30% of covers).
    let signature: CoverSignature?
}

// MARK: - Tile Configuration

/// A single paper tile in the mosaic composition.
struct CoverTileConfiguration: Codable, Identifiable {
    let id: UUID
    let shape: CoverTileShape

    /// Top-left x, normalized 0…1 (fraction of cover width).
    let x: Double
    /// Top-left y, normalized 0…1 (fraction of cover height).
    let y: Double
    /// Fraction of cover width.
    let width: Double
    /// Fraction of cover height.
    let height: Double

    /// Rotation in degrees, typically −8°…+8°.
    let rotation: Double
    /// The palette color assigned to this tile.
    let colorToken: MagicPaperCoverColor
    /// Drawing order — higher values are drawn later (on top).
    let zIndex: Int
    /// Paper texture intensity, 0.05…0.14.
    let textureIntensity: Double
    /// Corner rounding, fraction of the tile's shorter dimension.
    let cornerRadius: Double
}

// MARK: - Tile Shapes

/// Visual geometry of a paper tile.
///
/// None of these should appear mathematically perfect — the renderer adds
/// subtle deterministic distortion to every tile.
enum CoverTileShape: String, Codable, CaseIterable {
    /// Equal width and height.
    case square
    /// Width > height.
    case rectangleHorizontal
    /// Height > width.
    case rectangleVertical
    /// Square or rectangle with pronounced rounding.
    case rounded
    /// Subtly irregular, handmade geometry via Path control-point jitter.
    case organic
    /// Torn-edge paper fragment with irregular corners.
    case paperFragment
}

// MARK: - Cover Layout

/// The compositional strategy for tile placement.
///
/// Each layout produces a distinct visual pattern while sharing the same
/// MagicPaper brand language. Weights control how often each layout appears
/// in the library; stronger layouts are favoured.
enum CoverLayout: String, Codable, CaseIterable {
    case balancedGrid
    case verticalStack
    case diagonalFlow
    case cornerCluster
    case centralIsland
    case scatteredPieces
    case bottomHeavy
    case topHeavy
    case overlappingBlocks
    case frame
    case staircase
    case asymmetricBalance

    /// Selection weight — higher values make the layout more likely.
    var selectionWeight: Double {
        switch self {
        case .balancedGrid:       return 1.0
        case .bottomHeavy:        return 1.0
        case .asymmetricBalance:  return 1.0
        case .overlappingBlocks:  return 0.85
        case .diagonalFlow:       return 0.85
        case .verticalStack:      return 0.65
        case .centralIsland:      return 0.65
        case .cornerCluster:      return 0.45
        case .scatteredPieces:    return 0.45
        case .topHeavy:           return 0.45
        case .frame:              return 0.3
        case .staircase:          return 0.3
        }
    }

    /// Valid tile count range for this layout.
    var tileCountRange: ClosedRange<Int> {
        switch self {
        case .balancedGrid:       return 5...7
        case .verticalStack:      return 5...8
        case .diagonalFlow:       return 6...8
        case .cornerCluster:      return 5...7
        case .centralIsland:      return 6...9
        case .scatteredPieces:    return 6...10
        case .bottomHeavy:        return 6...8
        case .topHeavy:           return 5...7
        case .overlappingBlocks:  return 5...8
        case .frame:              return 6...10
        case .staircase:          return 5...8
        case .asymmetricBalance:  return 6...9
        }
    }
}

// MARK: - Signature

/// A small decorative motif placed in Zone C (bottom area).
struct CoverSignature: Codable {
    let type: CoverSignatureType
    /// Normalized x position (fraction of cover width).
    let x: Double
    /// Normalized y position (fraction of cover height).
    let y: Double
    /// Scale relative to cover width, 0.015…0.04.
    let scale: Double
    /// Rotation in degrees.
    let rotation: Double
}

/// Hand-drawn decorative motifs rendered as vector paths.
///
/// `.none` is valid — approximately 30% of covers carry no motif.
enum CoverSignatureType: String, Codable, CaseIterable {
    case none
    case tinyStar
    case paperSparkle
    case crescent
    case leaf
    case tinyFlower
    case dotConstellation

    /// The subset that actually draws something.
    static var motifCases: [CoverSignatureType] {
        allCases.filter { $0 != .none }
    }
}

// MARK: - Cover Style

/// Determines which rendering path a story's cover uses.
///
/// This is an explicit presentation decision — asset existence must not
/// implicitly define story type.
enum StoryCoverStyle {
    /// Generative paper-mosaic cover (text-only stories).
    case magicPaperMosaic
    /// Story has its own illustration cover.
    case illustrated
    /// Pre-existing stories that predate the mosaic system.
    case legacy
}

// MARK: - Cover Theme

/// The visual scene a cover depicts, derived from the story's world.
///
/// Each theme produces a distinct landscape composition using layered
/// paper forms and simple illustrative motifs. All themes share the
/// same MagicPaper brand language but tell visually different stories.
enum CoverTheme: String, Codable, CaseIterable {
    /// Layered hills, trees, path, moon/stars, leaves
    case forest
    /// Layered waves, boat, sun/moon, coral, fish
    case ocean
    /// Stars, planets, rocket, nebula clouds
    case space
    /// Rolling hills, castle silhouette, banner
    case kingdom
    /// Flowers, butterflies, sun, garden path
    case garden
    /// Mountains, snow, northern lights
    case snowland
    /// Dunes, fossils, ferns, volcano silhouette
    case prehistoric
    /// Clouds, sparkles, mushrooms, fairy wings
    case fairytale
    /// Ship, island, treasure, compass
    case pirate
    /// Barn, fence, rolling fields, windmill
    case farm
    /// Gears, circuits, antenna, cityscape
    case robot
    /// Tent, flags, stars, bunting
    case circus

    /// Maps a story world to a cover theme.
    static func from(world: MP.World) -> CoverTheme {
        switch world {
        case .orman:    return .forest
        case .deniz:    return .ocean
        case .uzay:     return .space
        case .krallik:  return .kingdom
        case .kahraman: return .kingdom
        case .dinozor:  return .prehistoric
        case .peri:     return .fairytale
        case .korsan:   return .pirate
        case .kar:      return .snowland
        case .ciftlik:  return .farm
        case .robot:    return .robot
        case .sirk:     return .circus
        }
    }
}

// MARK: - Validation

/// The result of running composition rules against a cover configuration.
struct CoverValidationResult {
    let isValid: Bool
    let violations: [CoverValidationViolation]
}

/// Hard-constraint violations that the validator can detect.
///
/// These are objective, measurable problems — not aesthetic judgements.
enum CoverValidationViolation: String {
    case titleAreaObstructed
    case tooFewColors
    case tooManyColors
    case tooFewTiles
    case tooManyTiles
    case noVisualAnchor
    case excessiveOverlap
    case tileOutOfBounds
    case signatureCollidesWithTitle
    case invalidGeometry
}

// MARK: - Tile Slot (Internal)

/// An intermediate tile position/size computed by the layout engine.
///
/// The generator fills in shape, color, texture, and rotation after the
/// layout engine decides where tiles go.
struct TileSlot {
    var x: Double       // top-left x, normalized 0…1
    var y: Double       // top-left y, normalized 0…1
    var width: Double   // fraction of cover width
    var height: Double  // fraction of cover height
    var sizeCategory: TileSizeCategory
}

/// Tile size categories based on fraction of cover width.
enum TileSizeCategory {
    /// 12–20% of cover width.
    case small
    /// 20–32% of cover width.
    case medium
    /// 30–48% of cover width.
    case large
    /// 45–65% of cover width.
    case xl
}

// MARK: - Layout Constants

/// Shared geometric constants for the cover system.
enum CoverConstants {
    /// Cover aspect ratio (width ÷ height).
    static let aspectRatio: Double = 2.0 / 3.0

    /// Title safe area — tiles should minimally overlap this zone.
    static let titleSafeArea = (x: 0.08, y: 0.05, width: 0.84, height: 0.20)

    /// Main mosaic zone — starts below title safe area with breathing room.
    static let mosaicZone = (yStart: 0.28, yEnd: 0.88)

    /// Signature zone.
    static let signatureZone = (yStart: 0.75, yEnd: 0.94)

    /// Safe margins.
    static let marginH: Double = 0.07
    static let marginV: Double = 0.06

    /// Converts a width (fraction of cover width) to the equivalent height
    /// (fraction of cover height) for a visually square tile.
    static func heightForWidth(_ w: Double) -> Double {
        w * aspectRatio
    }
}
