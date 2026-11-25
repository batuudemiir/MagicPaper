import XCTest
import CryptoKit
import StoryEngine
@testable import MagicPaper

/// Okul öncesi "önce arkadaş" akışı (26 Kasım 2026, Batuhan K1-K4;
/// `cocuk-akisi-is-tanimi.md`): sıra, liste, söz ve bayrak kapalıyken bugünkü akış.
@MainActor
final class LittleFriendFirstTests: XCTestCase {
    private static let fixture: Result<(P56SourceReference, P56Package), Error> = Result {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let bytes = try Data(contentsOf: root.appendingPathComponent("Content/Pilots/\(P56PinnedSource.packageVersion)/payload.json"))
        let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let package = try P56PackageLoader.load(payload: bytes, expectedSHA256: digest)
        return (package.sourceReference, package)
    }

    private let kestane = "companion_hedgehog_pilot_001"
    private let bogurtlen = "companion_bear_001"
    private let tarcin = "companion_fox_pilot_001"
    private let yildiz = "companion_owl_pilot_001"
    private let simit = "companion_city_cat_001"
    private var base: OfflineStoryService { OfflineStoryService.shared }

    private func router(enabled: Bool = true) -> StoryRuntimeRouter {
        StoryRuntimeRouter(isEnabled: enabled, loadSource: { try Self.fixture.get() }, archive: nil)
    }

    private func source(safety: ContentSafety? = nil, enabled: Bool = true) -> FiveFriendsChoiceSource {
        FiveFriendsChoiceSource(base: base, router: router(enabled: enabled), safety: { safety })
    }

    // MARK: - Sıra ve adımlar

    func testLittleOrderIsFriendModeTopicConfirm() {
        var path = StoryCreationSteps.LittlePath()
        XCTAssertEqual(path.step, .friend)
        XCTAssertEqual(path.chooseFriend(kestane), .show(.mode))
        XCTAssertEqual(path.chooseMode(.learning, hasTopicStep: true), .show(.topic))
        XCTAssertEqual(path.labels, ["Kim", "Masal", "Konu", "Hazır"])
        XCTAssertEqual(path.chooseTopic(nil), .show(.confirm))
        XCTAssertEqual(path.stepIndex, 3)
        XCTAssertEqual(path.start(), .begin)
    }

    /// Uyku öncesinde konu yok: üç adım.
    func testWithoutTopicTheConfirmFollowsTheMode() {
        var path = StoryCreationSteps.LittlePath()
        _ = path.chooseFriend(tarcin)
        XCTAssertEqual(path.chooseMode(.bedtime, hasTopicStep: false), .show(.confirm))
        XCTAssertEqual(path.labels, ["Kim", "Masal", "Hazır"])
        XCTAssertEqual(path.stepIndex, 2)
    }

    /// Onay adımına kadar masal yazılmaz: yalnızca "Başla" `.begin` verir.
    func testNoStoryBeforeTheConfirmStep() {
        var path = StoryCreationSteps.LittlePath()
        var outcomes: [StoryCreationSteps.LittlePath.Outcome] = [path.start()]
        outcomes.append(path.chooseFriend(simit)); outcomes.append(path.start())
        outcomes.append(path.chooseMode(.adventure, hasTopicStep: true)); outcomes.append(path.start())
        outcomes.append(path.chooseTopic("x"))
        XCTAssertFalse(outcomes.contains(.begin))
        XCTAssertEqual(path.start(), .begin)
    }

    /// Geri seçimleri korur; ilk adımda akışı kapatır.
    func testBackKeepsChoices() {
        var path = StoryCreationSteps.LittlePath()
        XCTAssertEqual(path.back(), .close)
        _ = path.chooseFriend(yildiz)
        _ = path.chooseMode(.learning, hasTopicStep: true)
        _ = path.chooseTopic("t")
        XCTAssertEqual(path.back(), .show(.topic))
        XCTAssertEqual(path.back(), .show(.mode))
        XCTAssertEqual(path.back(), .show(.friend))
        XCTAssertEqual(path.companionID, yildiz)
        XCTAssertEqual(path.mode, .learning)
        XCTAssertEqual(path.topicID, "t")
        // Aynı arkadaşa yeniden dokunmak seçimleri silmez; başka arkadaş siler.
        _ = path.chooseFriend(yildiz)
        XCTAssertEqual(path.mode, .learning)
        _ = path.chooseFriend(simit)
        XCTAssertNil(path.mode)
        XCTAssertNil(path.topicID)
    }

    func testConfirmBackSkipsMissingTopicStep() {
        var path = StoryCreationSteps.LittlePath()
        _ = path.chooseFriend(nil)
        _ = path.chooseMode(.bedtime, hasTopicStep: false)
        XCTAssertEqual(path.back(), .show(.mode))
    }

    /// Sürpriz arkadaş: mod yine sorulur; arkadaşı motor seçer.
    func testSurpriseStillAsksForTheMode() {
        var path = StoryCreationSteps.LittlePath()
        XCTAssertEqual(path.chooseFriend(nil), .show(.mode))
        XCTAssertNil(path.companionID)
        XCTAssertFalse(source().pilotModes(forCompanionID: nil, age: 5).isEmpty)
        XCTAssertEqual(StoryCreationSteps.littleCast(chosen: nil, topicID: nil, legacyCandidates: [simit]),
                       .init(companionID: nil, keepsFriend: false))
    }

    // MARK: - Liste

    func testFixedCanonicalOrderNotLastChosen() {
        let shuffled = [simit, tarcin, bogurtlen, yildiz, kestane].map {
            CompanionChoice(id: $0, name: $0, kind: "", personality: "")
        }
        XCTAssertEqual(StoryCreationSteps.orderedLittleFriends(shuffled).map(\.id),
                       [kestane, bogurtlen, tarcin, yildiz, simit])
        XCTAssertEqual(StoryCreationSteps.littleFriendLimit + 1, LittleCompanionStep.maxTiles, "beşli + Sürpriz")
    }

    /// Modsuz liste: yalnız P56'nın en az bir modda yazabildikleri.
    func testModelessListIsTheUnionOfWritableFriends() {
        for safety in [nil, ContentSafety.mostProtective] as [ContentSafety?] {
            let wrapped = source(safety: safety)
            let listed = Set(wrapped.pilotFriendChoices(age: 5).map(\.id))
            XCTAssertFalse(listed.isEmpty)
            var union = Set<String>()
            for mode in base.availableModes(forAge: 5) {
                let limit = wrapped.companionDisplayLimit(forIdeaID: nil, age: 5, mode: mode, topicID: nil, family: nil)
                union.formUnion(wrapped.companionChoices(forIdeaID: nil, mode: mode, age: 5, topicID: nil, family: nil)
                    .prefix(limit).map(\.id))
            }
            XCTAssertEqual(listed, union)
            for id in listed {
                XCTAssertTrue(base.availableModes(forAge: 5).contains { mode in
                    if case .p56 = router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: id, family: nil,
                                                                      topicID: nil, occasion: nil, safety: safety)).route {
                        return true
                    }
                    return false
                }, "\(id) hiçbir modda yazılamıyor")
            }
        }
    }

    /// Seçilen arkadaşla mod listesi: yalnız yazılabilen modlar.
    func testModesForAFriendAreOnlyWritableOnes() {
        let wrapped = source(safety: .mostProtective)
        for friend in wrapped.pilotFriendChoices(age: 5) {
            let modes = wrapped.pilotModes(forCompanionID: friend.id, age: 5)
            XCTAssertFalse(modes.isEmpty, friend.id)
            for mode in base.availableModes(forAge: 5) {
                let route = router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: friend.id, family: nil,
                                                                topicID: nil, occasion: nil, safety: .mostProtective)).route
                let writable: Bool = { if case .p56 = route { return true } else { return false } }()
                XCTAssertEqual(modes.contains(mode), writable, "\(friend.id) \(mode)")
            }
        }
    }

    // MARK: - Konu (K4)

    /// "Fark etmez" ile istek beşliye gider ve arkadaş korunur.
    func testAnyTopicKeepsTheP56Route() throws {
        let cast = StoryCreationSteps.littleCast(chosen: simit, topicID: nil, legacyCandidates: [])
        XCTAssertEqual(cast, .init(companionID: simit, keepsFriend: true))
        let mode = try XCTUnwrap(source().pilotModes(forCompanionID: simit, age: 5).first)
        guard case .p56 = router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: cast.companionID,
                                                              family: nil, topicID: nil, occasion: nil, safety: nil)).route
        else { return XCTFail("Fark etmez P56'yı korumalı") }
    }

    /// Konu seçilince istek eski motora gider; arkadaş eski katalogda bu konuda
    /// yazılabiliyorsa onunla yazılır, değilse onay ekranı Sürpriz gösterir.
    func testTopicGoesToLegacyAndKeepsTheFriendOnlyWhenWritable() async throws {
        var checked = 0
        for mode in base.availableModes(forAge: 5) {
            for topic in base.topicChoices(forAge: 5, mode: mode) {
                guard case .legacy = router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: simit,
                                                                          family: nil, topicID: topic.id,
                                                                          occasion: nil, safety: nil)).route
                else { return XCTFail("konu \(topic.id) eski motora gitmeli") }
                let legacy = source().legacyWritableCompanionIDs(mode: mode, age: 5, topicID: topic.id)
                for friend in [simit, bogurtlen] {
                    let cast = StoryCreationSteps.littleCast(chosen: friend, topicID: topic.id, legacyCandidates: legacy)
                    XCTAssertEqual(cast.keepsFriend, legacy.contains(friend))
                    XCTAssertEqual(cast.companionID, legacy.contains(friend) ? friend : nil)
                    // Sözün tutulduğunu gerçek yazımla doğrula (her arkadaş için bir örnek).
                    if cast.keepsFriend, checked < 4 {
                        let profile = UserProfile(name: "Deniz", age: 5)
                        let context = StoryContextBuilder().build(
                            for: profile, library: [], mode: mode, strategy: .direct, storyIdeaID: nil,
                            companionID: cast.companionID, subOption: topic.id, family: nil, occasion: nil)
                        let composed = try base.compose(context, seed: "7")
                        XCTAssertEqual(composed.story.content.companion.id.rawValue, friend,
                                       "\(friend) \(mode) \(topic.id)")
                        checked += 1
                    }
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "Simit ya da Böğürtlen en az bir konuda eski motorla yazılabilmeli")
        XCTAssertEqual(StoryCreationSteps.littleCast(chosen: simit, topicID: "t", legacyCandidates: [tarcin]),
                       .init(companionID: nil, keepsFriend: false))
        XCTAssertEqual(StoryCreationSteps.littleCast(chosen: simit, topicID: "t", legacyCandidates: [simit]),
                       .init(companionID: simit, keepsFriend: true))
    }

    // MARK: - Beşli kapalıyken

    /// Bayrak kapalı, beşliyi bilmeyen kaynak ya da yazılamayan yaş: bugünkü sıra.
    func testWithoutFiveFriendsTheLittleFlowIsTodays() {
        XCTAssertTrue(source(enabled: false).pilotFriendChoices(age: 5).isEmpty)
        XCTAssertTrue(base.pilotFriendChoices(age: 5).isEmpty)
        XCTAssertTrue(source().pilotFriendChoices(age: 3).isEmpty)
        XCTAssertFalse(StoryCreationSteps.littleUsesFriendFirst(pilotFriends: [], hasPresetFamily: false))
        let one = [CompanionChoice(id: kestane, name: "Kestane", kind: "", personality: "")]
        XCTAssertTrue(StoryCreationSteps.littleUsesFriendFirst(pilotFriends: one, hasPresetFamily: false))
        XCTAssertFalse(StoryCreationSteps.littleUsesFriendFirst(pilotFriends: one, hasPresetFamily: true),
                       "Masal ailem'le açılan akış bugünkü sırada")
        // Bugünkü adım etiketleri değişmedi.
        XCTAssertEqual(StoryCreationSteps.stepLabels(hasTopicStep: true), ["Masal", "Konu", "Kimler"])
    }

    // MARK: - Ses

    func testSpokenLinesAreShort() {
        var lines = [LittleCreationCopy.friendQuestion, LittleCreationCopy.surpriseIntro,
                     LittleCreationCopy.startLine, LittleCreationCopy.confirmTitle,
                     LittleCreationCopy.modeQuestion(friendName: nil)]
        for id in StoryCreationSteps.littleFriendOrder {
            lines.append(LittleCreationCopy.intro(for: id, name: "Böğürtlen"))
            lines.append(LittleCreationCopy.modeQuestion(friendName: "Böğürtlen"))
            lines.append(LittleCreationCopy.anyTopicLine(friendName: "Böğürtlen") ?? "")
            for mode in StoryMode.allCases {
                for keeps in [true, false] {
                    lines.append(LittleCreationCopy.confirmLine(friendName: "Böğürtlen", keepsFriend: keeps, mode: mode))
                }
                lines.append(LittleCreationCopy.confirmLine(friendName: nil, keepsFriend: false, mode: mode))
            }
        }
        for line in lines {
            XCTAssertLessThanOrEqual(line.split(separator: " ").count, LittleCreationCopy.maxWords, line)
            XCTAssertFalse(line.lowercased().contains("yeşil"), "düğme rengi söylenmez")
        }
        XCTAssertNil(LittleCreationCopy.anyTopicLine(friendName: nil))
        XCTAssertEqual(LittleCreationCopy.confirmLine(friendName: "Simit", keepsFriend: false, mode: .learning),
                       "Bu konuda yeni bir arkadaş gelecek.")
    }
}
