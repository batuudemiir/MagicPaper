import Foundation

public struct P56SamplingAttempt: Codable, Sendable {
    public let cell: String
    public let seed: UInt64
    public let bookID: String?
    public let success: Bool
    public let failure: String?
    public let structuralSignature: String?
}

public struct P56SamplingReport: Codable, Sendable {
    public let attempts: Int
    public let successes: Int
    public let failures: Int
    public let failureReasons: [String: Int]
    public let bookCounts: [String: Int]
    public let mechanismCounts: [String: Int]
    public let cellAttempts: [String: Int]
    /// First repeated fixed book within each cell; two books per cell is an explicit ceiling.
    public let firstRepeatAttemptByCell: [String: Int]
    public let uniqueBooks: Int
    public let fixedBooksPerCell: Int
    public let retries: Int
    public let attemptRecords: [P56SamplingAttempt]
    public let repeatedSourcePageOccurrences: Int
    public let repeatedRenderedPageOccurrences: Int
    public let firstRepeatedSourceAttemptByCell: [String: Int]
    public let firstRepeatedRenderedTextAttemptByCell: [String: Int]
}

public enum P56Sampler {
    /// Balanced cell attempts, each seed used once. Failure remains in the denominator.
    public static func run(package: P56Package, count: Int = 1500) -> P56SamplingReport {
        let cells = P56Mode.allCases.flatMap { mode in
            package.companions.sorted { $0.id < $1.id }.map { (mode, $0.id) }
        }
        var failures: [String: Int] = [:], books: [String: Int] = [:], mechanisms: [String: Int] = [:]
        var cellAttempts: [String: Int] = [:], repeats: [String: Int] = [:]
        var seen: [String: Set<String>] = [:]
        var records: [P56SamplingAttempt] = []
        var sourcesSeen: Set<String> = [], textsSeen: Set<String> = []
        var sourceRepeats = 0, textRepeats = 0
        var firstSourceRepeat: [String: Int] = [:], firstTextRepeat: [String: Int] = [:]
        let composer = P56StoryComposer(package: package)
        let attempts = max(0, count)
        for index in 0..<attempts {
            let (mode, companion) = cells[index % cells.count]
            let key = mode.rawValue + "/" + companion
            cellAttempts[key, default: 0] += 1
            do {
                let story = try composer.compose(P56Request(childID: "p56-sampler", name: "İrem", age: 6,
                    seed: UInt64(index / cells.count), mode: mode, companionID: companion))
                if !seen[key, default: []].insert(story.bookID).inserted, repeats[key] == nil {
                    repeats[key] = cellAttempts[key]
                }
                for page in story.pages {
                    if !sourcesSeen.insert(page.provenance.templateID).inserted {
                        sourceRepeats += 1
                        if firstSourceRepeat[key] == nil { firstSourceRepeat[key] = cellAttempts[key] }
                    }
                    if !textsSeen.insert(page.provenance.renderedSHA256).inserted {
                        textRepeats += 1
                        if firstTextRepeat[key] == nil { firstTextRepeat[key] = cellAttempts[key] }
                    }
                }
                records.append(P56SamplingAttempt(cell: key, seed: UInt64(index / cells.count),
                    bookID: story.bookID, success: true, failure: nil,
                    structuralSignature: story.pages.map { $0.beat.rawValue }.joined(separator: ">")))
                books[story.bookID, default: 0] += 1
                mechanisms[story.mechanism, default: 0] += 1
            } catch {
                let reason = String(describing: error)
                failures[reason, default: 0] += 1
                records.append(P56SamplingAttempt(cell: key, seed: UInt64(index / cells.count),
                    bookID: nil, success: false, failure: reason, structuralSignature: nil))
            }
        }
        let failed = failures.values.reduce(0, +)
        return P56SamplingReport(attempts: attempts, successes: attempts - failed, failures: failed,
            failureReasons: failures, bookCounts: books, mechanismCounts: mechanisms, cellAttempts: cellAttempts,
            firstRepeatAttemptByCell: repeats, uniqueBooks: books.count, fixedBooksPerCell: 2, retries: 0,
            attemptRecords: records, repeatedSourcePageOccurrences: sourceRepeats,
            repeatedRenderedPageOccurrences: textRepeats, firstRepeatedSourceAttemptByCell: firstSourceRepeat,
            firstRepeatedRenderedTextAttemptByCell: firstTextRepeat)
    }
}
