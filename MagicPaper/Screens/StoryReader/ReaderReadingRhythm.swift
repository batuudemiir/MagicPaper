import Foundation

/// A visual slice of an unchanged source paragraph, in local UTF-16 coordinates.
struct ReaderRhythmBlock: Equatable {
    enum Kind: Equatable { case body, opening, quiet, refrain }
    let text: String
    let sourceParagraph: Int
    let sourceRange: Range<Int>
    let kind: Kind

    var quiet: Bool { kind == .quiet || kind == .refrain }

    /// Nil for future blocks; an empty range at the end means already read.
    func localMark(_ mark: ReadAlongMark?, in paragraphs: [String]) -> Range<Int>? {
        guard let mark, Self.substring(paragraphs, paragraph: sourceParagraph, range: sourceRange) != nil,
              mark.start >= 0, mark.end >= mark.start, paragraphs.indices.contains(mark.paragraph),
              Self.substring(paragraphs, paragraph: mark.paragraph, range: mark.start..<mark.end) != nil,
              mark.paragraph >= sourceParagraph else { return nil }
        if mark.paragraph > sourceParagraph || mark.start >= sourceRange.upperBound {
            return sourceRange.count..<sourceRange.count
        }
        guard mark.end > sourceRange.lowerBound else { return nil }
        let start = max(mark.start, sourceRange.lowerBound) - sourceRange.lowerBound
        let end = min(mark.end, sourceRange.upperBound) - sourceRange.lowerBound
        return start..<end
    }

    static func substring(_ paragraphs: [String], paragraph: Int, range: Range<Int>) -> String? {
        guard paragraphs.indices.contains(paragraph), range.lowerBound >= 0 else { return nil }
        let source = paragraphs[paragraph]
        guard range.upperBound <= source.utf16.count else { return nil }
        // Foundation range conversion can round a surrogate-interior offset.
        // Require exact Character boundaries, including the final empty boundary.
        let boundaries = Set(source.indices.map { $0.utf16Offset(in: source) } + [source.utf16.count])
        guard boundaries.contains(range.lowerBound), boundaries.contains(range.upperBound),
              let swiftRange = Range(NSRange(location: range.lowerBound, length: range.count), in: source) else { return nil }
        return String(source[swiftRange])
    }
}

enum ReaderReadingRhythm {
    private static let roles: Set<String> = ["hook", "discovery", "companion", "problem", "attempt", "challenge", "resolution", "celebration", "emotional_ending", "bedtime_transition"]
    private static let quietRoles: Set<String> = ["resolution", "celebration", "emotional_ending", "bedtime_transition"]

    static func isEligible(composition: ReaderPageComposition, accessibility: Bool,
                           compactHeight: Bool, viewport: CGSize) -> Bool {
        composition != .scene && !accessibility && !compactHeight
            && viewport.width.isFinite && viewport.height.isFinite
            && viewport.width > 0 && viewport.height > 0
    }

    static func blocks(paragraphs: [String], reading: StoryPageReading?,
                       layout: ReaderTextLayout) -> [ReaderRhythmBlock]? {
        guard let reading, reading.schemaVersion == 1, roles.contains(reading.role),
              !paragraphs.isEmpty, paragraphs.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { return nil }
        let sentences = paragraphs.map { ReaderText.sentenceRanges(in: $0) }
        guard sentences.allSatisfy({ !$0.isEmpty }) else { return nil }
        let count = sentences.reduce(0) { $0 + $1.count }
        let refrain = refrainRange(reading.refrain, paragraphs: paragraphs, sentences: sentences)
        var output: [ReaderRhythmBlock] = []
        for p in paragraphs.indices {
            let blocks = paragraphBlocks(p, paragraphs: paragraphs, sentences: sentences, reading: reading,
                                         layout: layout, sentenceCount: count, refrain: refrain)
            guard coversParagraph(blocks, paragraph: paragraphs[p], index: p) else { return nil }
            output += blocks
        }
        return output.isEmpty ? nil : output
    }

    private static func coversParagraph(_ blocks: [ReaderRhythmBlock], paragraph: String, index: Int) -> Bool {
        guard !blocks.isEmpty else { return false }
        var boundary = 0
        for block in blocks {
            guard block.sourceParagraph == index, block.sourceRange.lowerBound == boundary,
                  block.sourceRange.upperBound > boundary,
                  block.sourceRange.upperBound <= paragraph.utf16.count else { return false }
            boundary = block.sourceRange.upperBound
        }
        return boundary == paragraph.utf16.count
            && blocks.map(\.text).joined().utf8.elementsEqual(paragraph.utf8)
    }

    private static func paragraphBlocks(_ p: Int, paragraphs: [String], sentences: [[Range<Int>]],
                                        reading: StoryPageReading, layout: ReaderTextLayout,
                                        sentenceCount: Int, refrain: Range<Int>?) -> [ReaderRhythmBlock] {
        let units = sentences[p]
        let finalParagraph = p == paragraphs.count - 1
        let opening = reading.role == "hook" || reading.role == "discovery"
        var output: [ReaderRhythmBlock] = []
        var i = 0
        while i < units.count {
            let isRefrain = finalParagraph && refrain?.lowerBound == units[i].lowerBound
            let insideRefrain = finalParagraph && refrain.map { units[i].lowerBound >= $0.lowerBound } == true
            let isQuiet = finalParagraph && !insideRefrain && i == units.count - 1
                && quietRoles.contains(reading.role) && sentenceCount > 1
            let isOpening = p == 0 && i == 0 && opening && layout == .paragraphs
            var end = i + 1
            if isRefrain && layout == .paragraphs { end = units.count }
            else if layout == .paragraphs && !isQuiet && !isOpening {
                end = min(i + 2, units.count)
                if finalParagraph, end > i + 1,
                   (refrain?.lowerBound == units[end - 1].lowerBound
                    || (refrain == nil && quietRoles.contains(reading.role) && end == units.count)) { end -= 1 }
            }
            let start = i == 0 ? 0 : units[i].lowerBound
            let stop = end == units.count ? paragraphs[p].utf16.count : units[end].lowerBound
            guard start >= 0, stop > start, stop <= paragraphs[p].utf16.count else { return [] }
            let range = start..<stop
            guard let text = ReaderRhythmBlock.substring(paragraphs, paragraph: p, range: range) else { return [] }
            let kind: ReaderRhythmBlock.Kind = isRefrain ? .refrain : isQuiet ? .quiet : isOpening ? .opening : .body
            output.append(.init(text: text, sourceParagraph: p, sourceRange: range, kind: kind))
            i = end
        }
        return output
    }

    /// Only an exact, authored final suffix at existing sentence boundaries qualifies.
    private static func refrainRange(_ refrain: String?, paragraphs: [String],
                                     sentences: [[Range<Int>]]) -> Range<Int>? {
        guard let refrain, !refrain.isEmpty, let paragraph = paragraphs.last,
              paragraph.hasSuffix(refrain), let final = sentences.last?.last,
              final.upperBound == paragraph.utf16.count else { return nil }
        let start = paragraph.utf16.count - refrain.utf16.count
        guard sentences.last?.contains(where: { $0.lowerBound == start }) == true else { return nil }
        return start..<paragraph.utf16.count
    }
}
