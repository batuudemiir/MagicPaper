import Foundation

/// What the pool can write today, band by mode by parent setting (H0,
/// `docs/HAVUZ_PLANI.md`).
///
/// Asked of the real selector and binder, not counted from the JSON: a
/// blueprint counts only when `BlueprintSelector.admissible` admits it and
/// `OfflineContentBinder` binds content for it. Topics are what
/// `availableTopics` offers; mechanisms are counted by
/// `CatalogBlueprint.mechanismKey`, the same key the topic gate counts.
public struct CoverageReport: Sendable {

    /// The two parent settings the plan measures.
    public enum Safety: String, Sendable, CaseIterable {
        /// The default: calm level, every topic avoided.
        case mostProtective
        /// No filter at all.
        case unfiltered

        public var value: ContentSafety? {
            switch self {
            case .mostProtective: return .mostProtective
            case .unfiltered: return nil
            }
        }
    }

    public struct Cell: Sendable, Equatable {
        public let band: AgeBand
        public let mode: StoryMode
        public let safety: Safety
        /// Blueprints that are admitted and bind, by id, sorted.
        public let blueprints: [ContentID]
        public let mechanisms: Set<String>
        /// Topics the chip step offers, by id, sorted.
        public let topics: [ContentID]
        /// Whether a finished story of this band and mode can be continued.
        public let continues: Bool
    }

    public let cells: [Cell]

    public init(catalog: ContentCatalog, selector: BlueprintSelector = BlueprintSelector()) {
        var cells: [Cell] = []
        for band in AgeBandResolver.bands {
            for mode in StoryMode.allCases {
                for safety in Safety.allCases {
                    cells.append(Self.cell(catalog: catalog, selector: selector, band: band, mode: mode, safety: safety))
                }
            }
        }
        self.cells = cells
    }

    public func cell(band: AgeBand, mode: StoryMode, safety: Safety) -> Cell? {
        cells.first { $0.band == band && $0.mode == mode && $0.safety == safety }
    }

    static func cell(
        catalog: ContentCatalog, selector: BlueprintSelector,
        band: AgeBand, mode: StoryMode, safety: Safety
    ) -> Cell {
        let intent = OfflineStoryIntent(
            childName: "", seed: "coverage", mode: mode, ageBand: band, safety: safety.value)
        let binder = OfflineContentBinder()
        let buildable = selector.admissible(catalog: catalog, intent: intent).blueprints.filter {
            (try? binder.bind(blueprint: $0, catalog: catalog, intent: intent)) != nil
        }
        let arc: NarrativeArc = mode == .bedtime ? .bedtime : .standard
        return Cell(
            band: band, mode: mode, safety: safety,
            blueprints: buildable.map(\.id).sorted { $0.rawValue < $1.rawValue },
            mechanisms: Set(buildable.map(\.mechanismKey)),
            topics: selector.availableTopics(catalog: catalog, intent: intent).map(\.id)
                .sorted { $0.rawValue < $1.rawValue },
            continues: !SeriesPlanner.continuations(mode: mode, band: band, arc: arc, catalog: catalog).isEmpty)
    }

    /// The matrix as text, for a person to read in the test log.
    public var table: String {
        var lines = ["bant  mod        ayar             blueprint  mekanizma  seri  konular"]
        for cell in cells {
            let topics = cell.topics.map(\.rawValue).joined(separator: ", ")
            lines.append([
                cell.band.description.padding(toLength: 5, withPad: " ", startingAt: 0),
                cell.mode.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0),
                cell.safety.rawValue.padding(toLength: 16, withPad: " ", startingAt: 0),
                String(cell.blueprints.count).padding(toLength: 10, withPad: " ", startingAt: 0),
                String(cell.mechanisms.count).padding(toLength: 10, withPad: " ", startingAt: 0),
                (cell.continues ? "var" : "yok").padding(toLength: 5, withPad: " ", startingAt: 0),
                topics.isEmpty ? "-" : topics,
            ].joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}
