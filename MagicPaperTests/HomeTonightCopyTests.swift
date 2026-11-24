import XCTest
import SwiftUI
@testable import MagicPaper

/// Ana sayfanın akşam kartı ve başlığı (24 Kasım 2026).
final class HomeTonightCopyTests: XCTestCase {

    // MARK: - Kart metni

    /// Masal bitirmek bir olay: okunduysa kart yeni masal önermez, kitaplığa çağırır.
    func testReadTodayIsCalmWhetherOrNotANewStoryCanBeWritten() {
        for canWrite in [true, false] {
            let copy = HomeTonightCopy.make(.readToday(canWrite: canWrite))
            XCTAssertEqual(copy.title, "Yarın yeni bir masal var")
            XCTAssertEqual(copy.tag, "Kitaplığın hazır")
            XCTAssertEqual(copy.button, "Kitaplığına bak")
            XCTAssertEqual(copy.icon, "books.vertical")
            XCTAssertFalse(copy.tag.contains("daha"))
        }
    }

    func testBedtimeCopyIsUnchanged() {
        let copy = HomeTonightCopy.make(.bedtime(time: "20.30"))
        XCTAssertEqual(copy.eyebrow, "Saat 20.30")
        XCTAssertEqual(copy.title, "Uyku masalı zamanı")
        XCTAssertEqual(copy.tag, "Kısa ve sakin")
        XCTAssertEqual(copy.button, "Uyku masalı yaz")
    }

    func testUnreadAndResumeCarryTheirStory() {
        let unread = HomeTonightCopy.make(.unread(title: "Ay Köprüsü", meta: "5 dk"))
        XCTAssertEqual(unread.title, "Ay Köprüsü")
        XCTAssertEqual(unread.button, "Masalı oku")
        let resume = HomeTonightCopy.make(.resume(progress: 0.4, title: "Ay Köprüsü", meta: "5 dk"))
        XCTAssertEqual(resume.button, "Devam et")
    }

    // MARK: - Selam

    /// Selam ve alt satırı göğün koyu kısmında: her durak beyaz yazıya ≥ 4.5:1.
    func testTheGreetingSitsOnASkyDarkEnoughForWhiteText() {
        XCTAssertFalse(MP.C.homeSkyTop.isEmpty)
        for stop in MP.C.homeSkyTop {
            for text in [MP.C.textOnArt, MP.C.textOnArtMuted] {
                XCTAssertGreaterThanOrEqual(Self.contrast(Self.rgb(text), Self.rgb(stop.color)), 4.5,
                                            "durak \(stop.location)")
            }
        }
    }

    /// Geçiş koyu durağın bittiği yerden başlar: kopukluk yok.
    func testTheFadeStartsWhereTheDarkSkyEnds() {
        let end = Self.rgb(MP.C.homeSkyTop.last!.color), start = Self.rgb(MP.C.homeSkyFade.first!.color)
        XCTAssertEqual(end.r, start.r, accuracy: 0.001)
        XCTAssertEqual(end.g, start.g, accuracy: 0.001)
        XCTAssertEqual(end.b, start.b, accuracy: 0.001)
    }

    private static func rgb(_ color: Color) -> (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    private static func luminance(_ c: (r: Double, g: Double, b: Double)) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    private static func contrast(_ a: (r: Double, g: Double, b: Double),
                                 _ b: (r: Double, g: Double, b: Double)) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}
