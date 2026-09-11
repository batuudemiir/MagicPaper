import Foundation
import EngineFoundation

/// How a story was produced.
///
/// Not for the reader — this is for the person six months from now asking why
/// one book looks different from another, whether a regression came from a
/// template change or a model change, and whether a reported problem is
/// reproducible. Without it, "the illustrations got worse last week" is
/// unanswerable.
public struct GenerationProvenance: Codable, Sendable, Hashable {
    public let engineVersion: String
    public let templateVersion: SemanticVersion
    public let promptCompilerVersion: String
    public let textProvider: String?
    public let textModel: String?
    public let imageProvider: String?
    public let imageModel: String?
    /// Present when generation was deterministic. `nil` means the seed varied
    /// and the output is not expected to reproduce.
    public let seed: UInt64?
    public let generatedAt: Date

    public init(
        engineVersion: String = EngineVersion.current,
        templateVersion: SemanticVersion,
        promptCompilerVersion: String = EngineVersion.promptCompiler,
        textProvider: String? = nil,
        textModel: String? = nil,
        imageProvider: String? = nil,
        imageModel: String? = nil,
        seed: UInt64? = nil,
        generatedAt: Date
    ) {
        self.engineVersion = engineVersion
        self.templateVersion = templateVersion
        self.promptCompilerVersion = promptCompilerVersion
        self.textProvider = textProvider
        self.textModel = textModel
        self.imageProvider = imageProvider
        self.imageModel = imageModel
        self.seed = seed
        self.generatedAt = generatedAt
    }

    /// Fills in provider and model from what the usage ledger actually recorded,
    /// rather than from what the engine intended to use.
    public static func derive(
        templateVersion: SemanticVersion,
        ledger: UsageLedger,
        seed: UInt64?,
        generatedAt: Date
    ) -> GenerationProvenance {
        let textCall = ledger.records.last { !$0.isImageCall && $0.operation != .imageValidation }
        let imageCall = ledger.records.last { $0.isImageCall }

        return GenerationProvenance(
            templateVersion: templateVersion,
            textProvider: textCall?.provider,
            textModel: textCall?.model,
            imageProvider: imageCall?.provider,
            imageModel: imageCall?.model,
            seed: seed,
            generatedAt: generatedAt
        )
    }
}

/// Version stamps for the parts of the engine whose behaviour can change output.
///
/// Bumped by hand when deterministic behaviour changes, which is exactly when a
/// golden fixture needs updating too.
public enum EngineVersion {
    /// The engine as a whole.
    public static let current = "1.0.0"

    /// The prompt compiler specifically. Separate because a change here alters
    /// every image request without any template or model changing, and that is
    /// a distinction worth being able to make when investigating a regression.
    public static let promptCompiler = "1.0.0"
}
