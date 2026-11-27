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
        StoryRuntimeRouter(isEnabled: enabled, loadSource: { P56VerifiedSource(try Self.fixture.get()) }, archive: nil)
    }

    /// Yükü okunmuş kaynak: geçici beşli değil, son liste.
    private func source(safety: ContentSafety? = nil, enabled: Bool = true) async -> FiveFriendsChoiceSource {
        let source = FiveFriendsChoiceSource(base: base, router: router(enabled: enabled), safety: { safety })
        await source.waitUntilReady()
        return source
    }

    // MARK: - Sıra ve adımlar (kısaltma: 26 Kasım 2026, Batuhan)

    /// Kim gelsin? → Ne yapalım? → Kitap oluştur. Konu adımı yok, her modda üç adım.
    func testLittleOrderIsFriendModeStart() {
        for mode in StoryMode.allCases {
            var path = StoryCreationSteps.LittlePath()
            XCTAssertEqual(path.step, .friend)
            XCTAssertEqual(path.chooseFriend(kestane), .show(.mode))
            XCTAssertEqual(path.chooseMode(mode), .show(.start))
            XCTAssertEqual(path.labels, ["Kim", "Masal", "Kitap"])
            XCTAssertEqual(path.stepIndex, 2)
            XCTAssertEqual(path.start(), .begin)
        }
    }

    /// Son adıma kadar masal yazılmaz: yalnızca "Kitap oluştur" `.begin` verir.
    func testNoStoryBeforeTheStartStep() {
        var path = StoryCreationSteps.LittlePath()
        var outcomes: [StoryCreationSteps.LittlePath.Outcome] = [path.start()]
        outcomes.append(path.chooseFriend(simit)); outcomes.append(path.start())
        outcomes.append(path.chooseMode(.adventure))
        XCTAssertFalse(outcomes.contains(.begin))
        XCTAssertEqual(path.start(), .begin)
    }

    /// Geri seçimleri korur; ilk adımda akışı kapatır.
    func testBackKeepsChoices() {
        var path = StoryCreationSteps.LittlePath()
        XCTAssertEqual(path.back(), .close)
        _ = path.chooseFriend(yildiz)
        _ = path.chooseMode(.learning)
        XCTAssertEqual(path.back(), .show(.mode))
        XCTAssertEqual(path.back(), .show(.friend))
        XCTAssertEqual(path.companionID, yildiz)
        XCTAssertEqual(path.mode, .learning)
        // Aynı arkadaşa yeniden dokunmak seçimleri silmez; başka arkadaş siler.
        _ = path.chooseFriend(yildiz)
        XCTAssertEqual(path.mode, .learning)
        _ = path.chooseFriend(simit)
        XCTAssertNil(path.mode)
    }

    /// Sürpriz arkadaş: mod yine sorulur; arkadaşı motor seçer.
    func testSurpriseStillAsksForTheMode() async {
        var path = StoryCreationSteps.LittlePath()
        XCTAssertEqual(path.chooseFriend(nil), .show(.mode))
        XCTAssertNil(path.companionID)
        let anyModes = await source().pilotModes(forCompanionID: nil, age: 5)
        XCTAssertFalse(anyModes.isEmpty)
    }

    /// Konu sorulmadığı için istek beşliye gider: seçilen arkadaş masalda kalır.
    func testChosenFriendKeepsTheP56Route() async throws {
        for friend in [kestane, bogurtlen, tarcin, yildiz, simit] {
            let modes = await source().pilotModes(forCompanionID: friend, age: 5)
            let mode = try XCTUnwrap(modes.first, friend)
            guard case .p56 = await router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: friend,
                                                                  family: nil, topicID: nil, occasion: nil,
                                                                  safety: nil)).route
            else { return XCTFail("\(friend) beşliyle yazılmalı") }
        }
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
    func testModelessListIsTheUnionOfWritableFriends() async {
        for safety in [nil, ContentSafety.mostProtective] as [ContentSafety?] {
            let wrapped = await source(safety: safety)
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
                var writable = false
                for mode in base.availableModes(forAge: 5) {
                    if case .p56 = await router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: id, family: nil,
                                                                            topicID: nil, occasion: nil, safety: safety)).route {
                        writable = true
                    }
                }
                XCTAssertTrue(writable, "\(id) hiçbir modda yazılamıyor")
            }
        }
    }

    /// Seçilen arkadaşla mod listesi: yalnız yazılabilen modlar.
    func testModesForAFriendAreOnlyWritableOnes() async {
        let wrapped = await source(safety: .mostProtective)
        for friend in wrapped.pilotFriendChoices(age: 5) {
            let modes = wrapped.pilotModes(forCompanionID: friend.id, age: 5)
            XCTAssertFalse(modes.isEmpty, friend.id)
            for mode in base.availableModes(forAge: 5) {
                let route = await router().decide(StoryRuntimeRequest(age: 5, mode: mode, companionID: friend.id, family: nil,
                                                                topicID: nil, occasion: nil, safety: .mostProtective)).route
                let writable: Bool = { if case .p56 = route { return true } else { return false } }()
                XCTAssertEqual(modes.contains(mode), writable, "\(friend.id) \(mode)")
            }
        }
    }

    // MARK: - Beşli kapalıyken

    /// Bayrak kapalı, beşliyi bilmeyen kaynak ya da yazılamayan yaş: bugünkü sıra.
    func testWithoutFiveFriendsTheLittleFlowIsTodays() async {
        let off = await source(enabled: false).pilotFriendChoices(age: 5)
        XCTAssertTrue(off.isEmpty)
        XCTAssertTrue(base.pilotFriendChoices(age: 5).isEmpty)
        let threeYearOld = await source().pilotFriendChoices(age: 3)
        XCTAssertTrue(threeYearOld.isEmpty)
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
        var lines = LittleCreationCopy.allLines()
        lines.append(LittleCreationCopy.intro(for: "x", name: "Böğürtlen"))
        lines.append(LittleCreationCopy.modeQuestion(friendName: "Böğürtlen"))
        for line in lines {
            XCTAssertLessThanOrEqual(line.text.split(separator: " ").count, LittleCreationCopy.maxWords, line.text)
            XCTAssertFalse(line.text.lowercased().contains("yeşil"), "düğme rengi söylenmez")
            XCTAssertFalse(line.text.contains("Hazır"), "Hazır mısın? sorusu kalktı")
        }
    }

    /// Her seslendirme satırının ayrı, kurala uyan bir dosya adı var: 29 kayıt.
    func testEveryVoiceLineHasAUniqueValidKey() {
        let lines = LittleCreationCopy.allLines()
        XCTAssertEqual(lines.count, 29)
        XCTAssertEqual(Set(lines.map(\.key)).count, lines.count, "dosya adları tekil")
        for line in lines {
            XCTAssertTrue(MPVoiceClips.isValidKey(line.key), line.key)
            XCTAssertTrue(line.key.hasPrefix(LittleCreationCopy.keyPrefix), line.key)
            XCTAssertFalse(line.key.contains("diger"), "beşlinin her satırı kendi adıyla: \(line.key)")
        }
        XCTAssertEqual(LittleCreationCopy.startLine(friendName: "Kestane", companionID: kestane, mode: .adventure),
                       MPVoiceLine(key: "ses_olustur_basla_kestane_macera", text: "Kestane ile maceraya çıkıyoruz!"))
        XCTAssertEqual(LittleCreationCopy.intro(for: tarcin, name: "Tarçın").key, "ses_olustur_tanitim_tarcin")
    }

    /// `docs/SESLENDIRME.md` koddaki listeyle aynı: her satırın adı ve cümlesi orada.
    func testVoiceScriptDocumentMatchesTheCode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let doc = try String(contentsOf: root.appendingPathComponent("docs/SESLENDIRME.md"), encoding: .utf8)
        for line in LittleCreationCopy.allLines() {
            XCTAssertTrue(doc.contains("`\(line.key)`"), line.key)
            XCTAssertTrue(doc.contains(line.text), line.text)
        }
    }

    /// Kayıt yoksa satır cihaz sesine kalır: paket boşken adres yok.
    func testMissingRecordingFallsBackToDeviceVoice() {
        XCTAssertNil(MPVoiceClips.url(for: "ses_olustur_yok_boyle_bir_dosya"))
        XCTAssertFalse(MPVoiceClips.isValidKey("ses_oluştur"))
        XCTAssertFalse(MPVoiceClips.isValidKey(""))
    }
}
