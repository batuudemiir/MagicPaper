import Foundation

/// One row of the table every child's reading will build (FAZ 14 madde 4).
///
/// Counts only, per blueprint, from anonymous reading events. The server
/// (after FAZ 16) turns a row into a Thompson-sampling draw — completions and
/// re-reads as successes over starts — and publishes it as the blueprint's
/// `aggregateWeight` in a catalog package (FAZ 15). The app never computes
/// it: the engine reads the weight, nothing more, so a bad table can only
/// make a blueprint likelier or rarer, never unavailable.
public struct BlueprintOutcome: Codable, Sendable, Hashable {
    public let blueprintID: ContentID
    public let starts: Int
    public let completions: Int
    public let rereads: Int

    public init(blueprintID: ContentID, starts: Int, completions: Int, rereads: Int) {
        self.blueprintID = blueprintID
        self.starts = starts
        self.completions = completions
        self.rereads = rereads
    }
}
