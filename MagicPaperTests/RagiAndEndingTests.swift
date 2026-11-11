import XCTest
@testable import MagicPaper

/// Faz 4: Ragi'nin hareket modeli, ses kararı ve "Birlikte konuşalım".
final class RagiAndEndingTests: XCTestCase {

    func testStillNeverMoves() {
        for t in stride(from: 0.0, to: 20, by: 0.37) {
            XCTAssertEqual(RagiMotion.frame(act: .still, t: t, seed: 0.4), RagiFrame())
        }
    }

    func testCheerHopsThenCalms() {
        let hops = stride(from: 0.0, to: RagiMotion.cheerHopsEnd, by: 0.02)
            .map { RagiMotion.frame(act: .cheer, t: $0, seed: 0).hop }
        XCTAssertGreaterThan(hops.max() ?? 0, 0.05)
        // Faz 13: hazırlıkta yerden kalkmaz, yalnızca çömelir.
        XCTAssertEqual(RagiMotion.frame(act: .cheer, t: MP.M.RagiBeat.anticipate / 2, seed: 0).hop, 0)
        XCTAssertLessThan(RagiMotion.frame(act: .cheer, t: MP.M.RagiBeat.anticipate / 2, seed: 0).squash, 0)
        for t in stride(from: RagiMotion.cheerHopsEnd, to: 30, by: 0.5) {
            XCTAssertEqual(RagiMotion.frame(act: .cheer, t: t, seed: 0).hop, 0, "Ragi sürekli zıplamaz")
        }
    }

    func testSleepNeverBlinksOrHops() {
        for t in stride(from: 0.0, to: 30, by: 0.03) {
            let f = RagiMotion.frame(act: .sleep, t: t, seed: 0.7)
            XCTAssertEqual(f.blink, 0)
            XCTAssertEqual(f.hop, 0)
        }
    }

    func testBlinkIsBriefAndRecurs() {
        let samples = stride(from: 0.0, to: 30, by: 0.01).map { RagiMotion.blink(t: $0, seed: 0.3) }
        let closed = samples.filter { $0 > 0 }.count
        XCTAssertGreaterThan(closed, 0)
        XCTAssertLessThan(Double(closed) / Double(samples.count), 0.08)
    }

    func testEveryAwakePoseHasEyes() {
        for mascot in Mascot.allCases where mascot.defaultAct != .sleep {
            XCTAssertFalse(RagiRig.of(mascot).eyes.isEmpty, "\(mascot) kırpamaz")
        }
    }

    func testSoundRules() {
        XCTAssertTrue(MPSound.shouldPlay(enabled: true, bedtime: false, speaking: false))
        XCTAssertFalse(MPSound.shouldPlay(enabled: false, bedtime: false, speaking: false))
        XCTAssertFalse(MPSound.shouldPlay(enabled: true, bedtime: true, speaking: false))
        XCTAssertFalse(MPSound.shouldPlay(enabled: true, bedtime: false, speaking: true))
    }

    @MainActor
    func testEverySoundFileExists() {
        for cue in MPSound.Cue.allCases {
            XCTAssertNotNil(Bundle.main.url(forResource: cue.rawValue, withExtension: "m4a"), cue.rawValue)
        }
    }

    func testTalkPromptsAreTwoStableAndDifferent() {
        let story = ReaderFixtures.textStory(pages: 1)
        let a = StoryTalkPrompts.questions(for: story)
        XCTAssertEqual(a, StoryTalkPrompts.questions(for: story))
        XCTAssertEqual(a.count, 2)
        XCTAssertNotEqual(a[0], a[1])
    }

    func testTalkPromptsNeverQuiz() {
        for _ in 0..<40 {
            for q in StoryTalkPrompts.questions(for: ReaderFixtures.textStory(pages: 1)) {
                XCTAssertTrue(q.hasSuffix("?"))
                XCTAssertFalse(q.lowercased().contains("doğru"))
                XCTAssertFalse(q.lowercased().contains("yapay zeka"))
            }
        }
    }
}

/// Faz 5: yaşa göre yazı boyutu ve 3-6 yaşın kelime vurgusu.
final class ReadingDepthTests: XCTestCase {

    func testReadSizeFollowsAgeBand() {
        XCTAssertEqual(MP.ReadSize.standard(forAge: 4), .cokBuyuk)
        XCTAssertEqual(MP.ReadSize.standard(forAge: 6), .cokBuyuk)
        XCTAssertEqual(MP.ReadSize.standard(forAge: 7), .buyuk)
        XCTAssertEqual(MP.ReadSize.standard(forAge: 10), .normal)
        XCTAssertEqual(MP.ReadSize.standard(forAge: nil), .normal)
    }

    func testBreathWordMarkFindsLineAndWord() {
        let paragraphs = ["Ay doğdu. Kedi uyandı.", "Rüzgâr esti."]
        // İlk paragrafın ikinci cümlesindeki "uyandı".
        let first = paragraphs[0] as NSString
        let location = first.range(of: "uyandı").location
        let mark = ReaderText.breathWordMark(paragraphs: paragraphs, location: location, length: 6)
        XCTAssertEqual(mark?.paragraph, 0)
        XCTAssertEqual(mark?.line, 1)
        let line = (paragraphs[0] as NSString).substring(from: first.range(of: "Kedi").location) as NSString
        XCTAssertEqual(line.substring(with: NSRange(location: mark!.start, length: mark!.end - mark!.start)), "uyandı")

        // İkinci paragraf: "\n\n" ile birleşmiş metindeki konum.
        let joined = paragraphs.joined(separator: "\n\n") as NSString
        let wind = ReaderText.breathWordMark(paragraphs: paragraphs, location: joined.range(of: "esti").location, length: 4)
        XCTAssertEqual(wind?.paragraph, 1)
        XCTAssertEqual(wind?.line, 0)
    }
}
