import XCTest
@testable import StoryEngine

/// The corpus must not be able to say something the engine cannot hear.
///
/// This is the project's most durable failure mode and it has now happened
/// three times with three different keys. `castRoles` was authored, carefully,
/// against an engine that did not decode it. Then `conflictKinds`: a whole
/// family's obstacles were being partitioned by conflict shape — including a
/// deliberate, correct exclusion of `duration` from the general obstacles —
/// while the composer, unable to read the key, handed those obstacles to
/// anybody. And `afterClosing`, which is *not* a synonym for `afterBeat` and
/// would have been read as one.
///
/// Every instance was silent. Nothing failed, nothing warned, the stories
/// generated, and the authoring simply had no effect. A count of variants
/// cannot detect it and neither can a render test, because the text is fine —
/// it is merely the wrong text, chosen for a reason nobody can see.
final class CorpusKeyCoverageTests: XCTestCase {

    private func corpusVariantKeys() throws -> [String: Set<String>] {
        let bundle = Bundle.module
        let urls = try XCTUnwrap(
            bundle.urls(forResourcesWithExtension: "json", subdirectory: nil),
            "No resources found.")
        var byFile: [String: Set<String>] = [:]
        for url in urls where url.lastPathComponent.hasPrefix("beat_") {
            let data = try Data(contentsOf: url)
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let variants = root?["variants"] as? [[String: Any]] ?? []
            for variant in variants {
                byFile[url.lastPathComponent, default: []].formUnion(variant.keys)
            }
        }
        return byFile
    }

    func testTheCorpusIsActuallyPresentToCheck() throws {
        let keys = try corpusVariantKeys()
        XCTAssertGreaterThan(keys.count, 20, "Found \(keys.count) beat files; expected the corpus.")
    }

    /// Every key the corpus writes is a key the engine reads.
    ///
    /// When this fails the fix is never to add the key to an ignore list. It is
    /// either to decode and act on it, or to go back to the authors and say the
    /// engine has no use for it so they can stop writing it — a key that means
    /// nothing is worse than no key, because it reads like a constraint.
    func testEveryKeyTheCorpusDeclaresIsOneTheEngineReads() throws {
        let decoded = CatalogVariant.decodedKeys
        var unread: [String: Set<String>] = [:]
        for (file, keys) in try corpusVariantKeys() {
            let missing = keys.subtracting(decoded)
            if !missing.isEmpty { unread[file] = missing }
        }
        XCTAssertTrue(
            unread.isEmpty,
            "The corpus declares keys the engine ignores. The authoring has no effect and "
            + "nothing says so:\n"
            + unread.sorted { $0.key < $1.key }
                .map { "  \($0.key): \($0.value.sorted().joined(separator: ", "))" }
                .joined(separator: "\n"))
    }

    /// The other direction, as a warning in test form: a filter the engine
    /// enforces that no variant ever declares is a constraint with nothing to
    /// constrain. Not a failure — the engine may legitimately lead the content —
    /// but it should be a deliberate state rather than a forgotten one.
    func testEveryFilterTheEngineEnforcesIsExercisedSomewhere() throws {
        let declared = try corpusVariantKeys().values.reduce(into: Set<String>()) {
            $0.formUnion($1)
        }
        let enforced: Set<String> = [
            "castRoles", "conflictKinds", "register", "afterBeat", "afterClosing",
            "afterState", "settingTraits", "discoveryTraits",
            "capabilityRequire", "capabilityForbid", "lengthClass"
        ]
        let unexercised = enforced.subtracting(declared).sorted()
        XCTAssertTrue(
            unexercised.isEmpty,
            "The engine filters on keys nothing declares: \(unexercised). "
            + "Either content is missing or the filter is.")
    }

    /// `duration` is the case that proves the point: its exclusion from the
    /// general obstacles was a correct editorial decision that silently became a
    /// pool of one, because nothing was reading the key that expressed it.
    ///
    /// Which shapes need supply is **derived from the blueprints**, not from the
    /// enum. The first version of this test asked every `ConflictMechanism` for
    /// four obstacles and reported `internal: 0` as a defect — but Family II
    /// never uses `obstacle_raises` at all. Its conflict is the child's own
    /// hesitation; there is nothing standing in the way to raise, which is the
    /// entire point of the family. Demanding obstacles for it would have had the
    /// corpus authors write lines that contradict the family they were for.
    ///
    /// That is the same mistake this file exists to catch, made by the check
    /// rather than by the content: an assumption about what the vocabulary must
    /// mean, held instead of read off what actually uses it.
    func testEveryConflictShapeAnObstacleIsAskedForHasLinesWrittenForIt() throws {
        let catalog = try ContentCatalogLoader().load().catalog
        let obstacles = catalog.templates
            .filter { $0.realizesBeat == .obstacleRaises }
            .flatMap(\.variants)
        XCTAssertFalse(obstacles.isEmpty, "No obstacle_raises variants to check.")

        let asked = Set(
            catalog.blueprints
                .filter { $0.isBeatAuthored && $0.beatSlots.flatMap(\.beats).contains(.obstacleRaises) }
                .compactMap { $0.family?.conflict })
        XCTAssertFalse(asked.isEmpty, "No blueprint raises an obstacle; nothing is being checked.")

        var thin: [String] = []
        for mechanism in asked.sorted(by: { $0.rawValue < $1.rawValue }) {
            let count = obstacles.filter { $0.suits(conflict: mechanism) }.count
            if count < 4 { thin.append("\(mechanism.rawValue): \(count)") }
        }
        XCTAssertTrue(thin.isEmpty,
                      "Conflict shapes a blueprint actually raises an obstacle for, with fewer "
                      + "than four lines — every story of that family reads the same page: "
                      + "\(thin)")
    }
}
