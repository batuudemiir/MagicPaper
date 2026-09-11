import Foundation

/// One page's worth of beat, chosen from the template.
public struct PlannedBeat: Sendable, Hashable {
    public let beat: TemplateBeat
    public let ordinal: Int
    /// Which repetition of a repeatable beat this is, starting at 0.
    public let occurrence: Int

    public init(beat: TemplateBeat, ordinal: Int, occurrence: Int) {
        self.beat = beat
        self.ordinal = ordinal
        self.occurrence = occurrence
    }
}

/// The beat sequence for one book.
public struct BeatPlan: Sendable, Hashable {
    public let beats: [PlannedBeat]
    public let requestedPageCount: Int
    public let effectivePageCount: Int

    public var wasClamped: Bool { requestedPageCount != effectivePageCount }
    public func beats(role: BeatRole) -> [PlannedBeat] { beats.filter { $0.beat.role == role } }
}

/// Turns "I want a 9-page space story" into a concrete beat sequence.
///
/// Fully deterministic and AI-free. The arc is the template's: openings first,
/// closings last, and repeatable middle beats stretched to fill whatever is
/// left. This is the piece that makes the wizard's length picker actually mean
/// something — the old prompt hard-coded seven beats and ignored the choice.
public struct BeatPlanner: Sendable {
    public init() {}

    public func plan(template: StoryTemplate, requestedPageCount: Int) throws -> BeatPlan {
        let narrative = template.narrative
        guard !narrative.beats.isEmpty else {
            throw StoryEngineError.templateHasNoBeats(template.id)
        }

        let openings = narrative.beats(role: .opening)
        let middles = narrative.beats(role: .middle)
        let closings = narrative.beats(role: .closing)
        let repeatables = middles.filter(\.repeatable)

        // What this template can actually produce, independent of what it claims.
        let structuralMaximum = repeatables.isEmpty
            ? openings.count + middles.count + closings.count
            : Int.max
        let structuralMinimum = max(1, min(openings.count, 1) + min(closings.count, 1))

        let declared = template.constraints.supportedPageCounts
        let lowerBound = max(declared.lowerBound, structuralMinimum)
        let upperBound = min(declared.upperBound, structuralMaximum)
        guard lowerBound <= upperBound else {
            // The template promises page counts its own beats cannot deliver.
            throw StoryEngineError.unsupportedPageCount(
                requested: requestedPageCount,
                supported: declared
            )
        }

        let pageCount = min(max(requestedPageCount, lowerBound), upperBound)

        // Closings are reserved first: a story that stops without an ending is
        // worse than one with a thin middle.
        let closingCount = min(closings.count, max(0, pageCount - 1))
        let openingCount = min(openings.count, pageCount - closingCount)
        let middleCount = pageCount - openingCount - closingCount

        var chosen: [TemplateBeat] = Array(openings.prefix(openingCount))

        // Every middle beat once, in the order the template declares, then
        // repeatables cycle to fill the rest.
        var middleBeats = Array(middles.prefix(middleCount))
        if middleBeats.count < middleCount, !repeatables.isEmpty {
            var index = 0
            while middleBeats.count < middleCount {
                middleBeats.append(repeatables[index % repeatables.count])
                index += 1
            }
        }
        chosen.append(contentsOf: middleBeats)
        chosen.append(contentsOf: closings.suffix(closingCount))

        var occurrences: [String: Int] = [:]
        let planned = chosen.enumerated().map { index, beat -> PlannedBeat in
            let occurrence = occurrences[beat.id, default: 0]
            occurrences[beat.id] = occurrence + 1
            return PlannedBeat(beat: beat, ordinal: index, occurrence: occurrence)
        }

        return BeatPlan(
            beats: planned,
            requestedPageCount: requestedPageCount,
            effectivePageCount: planned.count
        )
    }
}
