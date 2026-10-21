import XCTest
@testable import StoryEngine

/// Uyku arkı (karar: 21 Ekim 2026): uyku öncesi modunun kendi masal yapısı.
///
/// Masal yatakta başlar, doruğu erken ve yumuşaktır, aynı odada en sakin
/// hâliyle biter. Kitap araştırması `c_bedtime_closes_circle` (LOW, 6 kitabın
/// 4'ü) dönüşü destekler; erken doruk privacy-safety'nin koşuludur.
final class BedtimeArcTests: XCTestCase {

    private static let bands = [AgeBand(lowerBound: 3, upperBound: 4), AgeBand(lowerBound: 5, upperBound: 6)]
    private static let seeds = ["a", "b", "c", "d", "e", "f"]

    private func catalog() throws -> ContentCatalog {
        try ContentCatalogLoader().load().catalog
    }

    private func bedtimeStories(_ catalog: ContentCatalog, family: FamilyCast? = nil) throws -> [ComposedStory] {
        var stories: [ComposedStory] = []
        for band in Self.bands {
            for seed in Self.seeds {
                stories.append(try OfflineStoryComposer().compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(
                        childName: "Yeliz", seed: seed, mode: .bedtime, ageBand: band, family: family)))
            }
        }
        return stories
    }

    // MARK: - Which blueprints a mode reaches

    func testBedtimeReachesOnlyBedtimeArcBlueprints() throws {
        let catalog = try catalog()
        let bedtime = try XCTUnwrap(catalog.modeProfile(.bedtime))
        let reached = catalog.blueprints.filter { $0.isBeatAuthored && bedtime.admits($0) }
        XCTAssertFalse(reached.isEmpty)
        XCTAssertTrue(reached.allSatisfy { $0.arc == .bedtime }, "\(reached.map(\.id))")
        // The charge stories that open in a garden no longer reach bedtime.
        XCTAssertFalse(reached.contains { $0.id == "bp_charge_tending_001" })

        for mode in [StoryMode.learning, .adventure] {
            let profile = try XCTUnwrap(catalog.modeProfile(mode))
            XCTAssertFalse(catalog.blueprints.contains { $0.arc == .bedtime && profile.admits($0) }, "\(mode)")
        }
    }

    func testAStoryWithoutAModeIsNeverABedtimeArcStory() throws {
        let catalog = try catalog()
        for band in Self.bands {
            let admitted = BlueprintSelector().admissible(
                catalog: catalog,
                intent: OfflineStoryIntent(childName: "Yeliz", seed: "x", ageBand: band)).blueprints
            XCTAssertTrue(admitted.allSatisfy { $0.arc == .standard }, "\(band): \(admitted.map(\.id))")
        }
    }

    func testBedtimeIsOfferedInEveryBandWithContent() throws {
        let catalog = try catalog()
        for band in Self.bands {
            XCTAssertTrue(BlueprintSelector().availableModes(catalog: catalog, ageBand: band).contains(.bedtime), "\(band)")
        }
    }

    // MARK: - The place

    func testABedtimeStoryOpensAndClosesInTheSameBedroom() throws {
        let catalog = try catalog()
        for story in try bedtimeStories(catalog) {
            XCTAssertTrue(story.isClean, "\(story.blueprintID): \(story.pages.map(\.text))")
            XCTAssertTrue(story.content.setting.traits.contains(.isRestingPlace), "\(story.content.setting.id)")
            let name = story.content.setting.name
            let first = try XCTUnwrap(story.pages.first).text
            let last = try XCTUnwrap(story.pages.last).text
            XCTAssertTrue(first.contains(name), "opening: \(first)")
            XCTAssertTrue(last.contains(name), "closing: \(last)")
            // The little one is named where it is met, never first by a later page.
            let meeting = try XCTUnwrap(story.pages.first { $0.beats.contains(.meetCompanion) })
            XCTAssertTrue(meeting.text.contains(story.content.companion.name), meeting.text)
        }
    }

    func testAStandardStoryNeverOpensInABedroom() throws {
        let catalog = try catalog()
        for mode in [StoryMode.learning, .adventure] {
            for seed in Self.seeds {
                guard let story = try? OfflineStoryComposer().compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(
                        childName: "Yeliz", seed: seed, mode: mode, ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
                else { continue }
                XCTAssertFalse(story.content.setting.traits.contains(.isRestingPlace), "\(mode) \(seed)")
            }
        }
    }

    /// Bedtime lines and standard lines never meet: a bedtime story reads only
    /// lines written for bed, and no other story reads any of them.
    func testTheTwoArcsNeverShareALine() throws {
        let catalog = try catalog()
        let bedtimeLines = Set(catalog.templates.filter { $0.arc == .bedtime }.flatMap(\.variants).map(\.id))
        XCTAssertFalse(bedtimeLines.isEmpty)
        for story in try bedtimeStories(catalog) {
            let used = Set(story.pages.flatMap(\.variantIDs))
            XCTAssertTrue(used.isSubset(of: bedtimeLines), "\(used.subtracting(bedtimeLines))")
        }
        for mode in [StoryMode.learning, .adventure] {
            for seed in Self.seeds {
                guard let story = try? OfflineStoryComposer().compose(
                    catalog: catalog,
                    intent: OfflineStoryIntent(
                        childName: "Yeliz", seed: seed, mode: mode, ageBand: AgeBand(lowerBound: 5, upperBound: 6)))
                else { continue }
                XCTAssertTrue(Set(story.pages.flatMap(\.variantIDs)).isDisjoint(with: bedtimeLines), "\(mode) \(seed)")
            }
        }
    }

    // MARK: - The ending

    /// Nothing is promised for tomorrow to a child falling asleep, with or
    /// without a Masal ailem character (privacy-safety koşul 4).
    func testEveryBedtimeStoryEndsCalmly() throws {
        let catalog = try catalog()
        let families: [FamilyCast?] = [nil] + FamilyRelationKind.allCases.map {
            FamilyCast(name: "Ela", relation: $0,
                       animalKind: $0 == .animal ? catalog.familyAnimalKind("family_animal_cat") : nil)
        }
        for family in families {
            for story in try bedtimeStories(catalog, family: family) {
                let last = try XCTUnwrap(story.pages.last)
                XCTAssertTrue(CalmEnding.isCalm(last.text), "\(last.text)")
                XCTAssertFalse(last.beats.contains(.carryForward))
                if let family {
                    XCTAssertTrue(story.pages.first?.text.contains(family.name) == true)
                    XCTAssertTrue(last.text.contains(family.name), last.text)
                }
            }
        }
    }

    // MARK: - The contour

    /// Every shipped bedtime blueprint passes the contour: peak by two thirds
    /// with two settled pages after it, last page at 0, 3-4 never above 1.
    func testShippedBedtimeBlueprintsHaveTheBedtimeContour() throws {
        let catalog = try catalog()
        let bedtime = catalog.blueprints.filter { $0.arc == .bedtime }
        XCTAssertEqual(Set(bedtime.map(\.ageRange)), Set(Self.bands))
        for blueprint in bedtime {
            let intensities = blueprint.beatSlots.compactMap { $0.emotion?.intensity }
            XCTAssertEqual(intensities.count, blueprint.pageCount, "\(blueprint.id)")
            let peak = try XCTUnwrap(intensities.max())
            let peakPage = try XCTUnwrap(intensities.lastIndex(of: peak)) + 1
            let n = intensities.count
            XCTAssertLessThanOrEqual(peakPage, Int((Double(2 * n) / 3).rounded(.up)), "\(blueprint.id)")
            XCTAssertLessThanOrEqual(peakPage, n - 2, "\(blueprint.id)")
            XCTAssertEqual(intensities.last, 0, "\(blueprint.id)")
            XCTAssertLessThanOrEqual(peak, NarrativeArc.bedtime.intensityCeiling(for: blueprint.ageRange))

            let result = BeatSequenceValidator().validate(
                blueprint.beatSlots, conflictMechanism: blueprint.family?.conflict,
                intensityCeiling: blueprint.arc.intensityCeiling(for: blueprint.ageRange), arc: .bedtime)
            XCTAssertEqual(result.issues.map(\.code), [], "\(blueprint.id): \(result.issues.map(\.message))")
        }
    }

    func testTheContourRulesAreFatal() {
        func slots(_ emotions: [EmotionalState], closing: [StoryBeat] = [.warmClose]) -> [BeatSlot] {
            let beats: [StoryBeat] = [.establishOrdinary, .noticeAnomaly, .meetCompanion, .takeCharge,
                                      .tend, .patientWait, .restore]
            var out = zip(beats, emotions).enumerated().map { index, pair in
                BeatSlot(pageNumber: index + 1, role: .hook, beat: pair.0, emotion: pair.1)
            }
            out.append(BeatSlot(pageNumber: 8, role: .emotionalEnding, beat: closing[0],
                                supportingBeat: closing.count > 1 ? closing[1] : nil, emotion: emotions[7]))
            return out
        }
        func codes(_ slots: [BeatSlot], ceiling: Int = 2) -> Set<String> {
            Set(BeatSequenceValidator()
                .validate(slots, conflictMechanism: .duration, intensityCeiling: ceiling, arc: .bedtime)
                .fatalIssues.map(\.code))
        }

        let good: [EmotionalState] = [.ease, .curiosity, .tenderness, .duty, .surprise, .calm, .relief, .calm]
        XCTAssertEqual(codes(slots(good)), [])

        // The bedtime peak on page 7 of 8: climbing at the end is not a bedtime story.
        var late = good; late[6] = .effort
        XCTAssertTrue(codes(slots(late)).contains("bedtime_peak_too_late"))

        // Unease at the peak.
        var uneasy = good; uneasy[4] = .unease
        XCTAssertTrue(codes(slots(uneasy)).contains("bedtime_uneasy_peak"))

        // A last page at 1 is a permitted landing elsewhere, not at bedtime.
        var tender = good; tender[7] = .tenderness
        XCTAssertTrue(codes(slots(tender)).contains("bedtime_unsettled_close"))

        // Nothing for tomorrow.
        XCTAssertTrue(codes(slots(good, closing: [.warmClose, .carryForward])).contains("bedtime_hook"))

        // 3-4: one page at 2 is over the bedtime ceiling.
        var strong = good; strong[4] = .effort
        XCTAssertTrue(codes(slots(strong), ceiling: NarrativeArc.bedtime.intensityCeiling(
            for: AgeBand(lowerBound: 3, upperBound: 4))).contains("intensity_over_ceiling"))
        XCTAssertFalse(codes(slots(strong), ceiling: NarrativeArc.bedtime.intensityCeiling(
            for: AgeBand(lowerBound: 5, upperBound: 6))).contains("intensity_over_ceiling"))
    }

    /// The same rules leave every standard blueprint alone.
    func testTheContourIsNotAppliedToStandardBlueprints() {
        let late: [BeatSlot] = [
            BeatSlot(pageNumber: 1, role: .hook, beat: .noticeAnomaly, emotion: .ease),
            BeatSlot(pageNumber: 2, role: .companion, beat: .meetCompanion, emotion: .tenderness),
            BeatSlot(pageNumber: 3, role: .problem, beat: .takeCharge, emotion: .duty),
            BeatSlot(pageNumber: 4, role: .attempt, beat: .tend, emotion: .effort),
            BeatSlot(pageNumber: 5, role: .resolution, beat: .patientWait, supportingBeat: .restore, emotion: .patience),
            BeatSlot(pageNumber: 6, role: .emotionalEnding, beat: .warmClose, emotion: .tenderness)
        ]
        let codes = BeatSequenceValidator().validate(late, conflictMechanism: .duration).issues.map(\.code)
        XCTAssertFalse(codes.contains { $0.hasPrefix("bedtime_") }, "\(codes)")
    }

    // MARK: - Safety

    func testTheShippedCatalogHasNoArcIssues() throws {
        let report = try XCTUnwrap(ContentCatalogLoader().load().report.integrity)
        let arcIssues = report.issues.filter { $0.code.hasPrefix("bedtime_") || $0.code.hasPrefix("beat_sequence_bedtime_") }
        XCTAssertEqual(arcIssues.map(\.message), [])
    }

    func testNoBedtimeLineOrPlaceTouchesTheDarkBeingAloneOrFear() throws {
        let catalog = try catalog()
        for setting in catalog.settings where setting.traits.contains(.isRestingPlace) {
            XCTAssertTrue(NarrativeArc.bedtimeExcludedTopics.isDisjoint(with: setting.topics), "\(setting.id)")
        }
        for variant in catalog.templates.filter({ $0.arc == .bedtime }).flatMap(\.variants) {
            XCTAssertTrue(NarrativeArc.bedtimeExcludedTopics.isDisjoint(with: variant.topics), "\(variant.id)")
            let text = variant.text.lowercased(with: Locale(identifier: "tr_TR"))
            for word in ["karanlık", "korku", "kork", "yalnız", "gölge", "canavar"] {
                XCTAssertFalse(text.contains(word), "\(variant.id): \(variant.text)")
            }
        }
    }

    func testAnIntegrityErrorWhenABedtimeLineTouchesTheDark() throws {
        let full = try catalog()
        let templates = try full.templates.map { template -> CatalogTemplate in
            guard template.arc == .bedtime, template.realizesBeat == .warmClose else { return template }
            let variants = try template.variants.map { variant -> CatalogVariant in
                var object = try XCTUnwrap(
                    JSONSerialization.jsonObject(with: JSONEncoder().encode(variant)) as? [String: Any])
                object["topics"] = ["darkness"]
                return try JSONDecoder().decode(CatalogVariant.self, from: JSONSerialization.data(withJSONObject: object))
            }
            return CatalogTemplate(
                id: template.id, role: template.role, realizesBeat: template.realizesBeat,
                compatibleThemes: template.compatibleThemes, variants: variants,
                ageBand: template.ageBand, arc: template.arc)
        }
        let catalog = ContentCatalog(
            version: full.version,
            settings: full.settings, companions: full.companions, objects: full.objects,
            templates: templates, blueprints: full.blueprints,
            storyIdeas: full.storyIdeas, storyModes: full.storyModes,
            familyMoments: full.familyMoments, familyAnimalKinds: full.familyAnimalKinds,
            safetyTopics: full.safetyTopics)
        let report = CatalogIntegrityChecker().check(catalog)
        XCTAssertFalse(report.issues(withCode: "bedtime_topic").isEmpty)
    }
}
