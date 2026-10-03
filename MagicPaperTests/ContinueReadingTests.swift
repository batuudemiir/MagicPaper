import XCTest
@testable import MagicPaper

/// "Kaldığın yer" kartı: hangi masal.
///
/// Kart ekranın en büyük yuvası ve tek bir şey iddia ediyor — *en son burada
/// kalmıştın*. Yanlış masalı göstermesi küçük bir kusur değil: çocuğa
/// okumadığı bir masalın ortasını açıyor.
final class ContinueReadingTests: XCTestCase {

    // MARK: - Kullanıcının gördüğü hata

    /// Diziyi sırasıyla okumak "en son okunan"ı vermez.
    ///
    /// `stories` en yeniden eskiye sıralı (`insert(at: 0)`), dolayısıyla eski
    /// kuraldaki `first` **en son yaratılan** yarım masalı seçiyordu. Bu akşam
    /// okunan iki haftalık masal, dün yaratılıp bırakılmış bir masalın arkasında
    /// kalıyordu.
    func testPicksTheMostRecentlyReadNotTheMostRecentlyCreated() {
        var readTonight = started(title: "Bu akşam okunan", pagesRead: 3)
        readTonight.createdAt = daysAgo(14)
        readTonight.lastReadAt = minutesAgo(20)

        var madeYesterday = started(title: "Dün yaratılıp bırakılan", pagesRead: 2)
        madeYesterday.createdAt = daysAgo(1)
        madeYesterday.lastReadAt = daysAgo(1)

        // Ana sayfanın gördüğü sıra: en yeni yaratılan başta.
        let shelf = [madeYesterday, readTonight]

        XCTAssertEqual(MPContinueReading.pick(from: shelf)?.title, "Bu akşam okunan")
    }

    /// İlk sayfa da bir ilerlemedir.
    ///
    /// `mpProgress` sekiz sayfalık bir masalda `lastReadPage == 0` için `0`
    /// verir; eski kural `> 0` istediği için açılıp ilk sayfası okunan masal
    /// hiç açılmamış sayılıyordu.
    func testAStoryLeftOnItsFirstPageCanBeContinued() {
        let justStarted = started(title: "İlk sayfada bırakılan", pagesRead: 1)
        XCTAssertEqual(justStarted.mpProgress, 0, "ön koşul: ilerleme yüzdesi hâlâ 0")
        XCTAssertEqual(MPContinueReading.pick(from: [justStarted])?.title,
                       "İlk sayfada bırakılan")
    }

    // MARK: - Aday olma koşulları

    func testUnopenedStoryIsNotOffered() {
        let fresh = ReaderFixtures.textStory(pages: 8)   // lastReadPage == nil
        XCTAssertNil(MPContinueReading.pick(from: [fresh]))
    }

    /// Biten masalın teklifi "tekrar oku"dur — bu kartın işi değil.
    func testFinishedStoryIsNotOffered() {
        let done = started(title: "Biten", pagesRead: 8)
        XCTAssertTrue(done.isFinished, "ön koşul")
        XCTAssertNil(MPContinueReading.pick(from: [done]))
    }

    /// Tek sayfalık masal okununca biter, yani devam edilecek bir şey kalmaz.
    func testSinglePageStoryIsFinishedNotResumable() {
        var single = ReaderFixtures.textStory(pages: 1)
        single.lastReadPage = 0
        XCTAssertNil(MPContinueReading.pick(from: [single]))
    }

    /// Metni olmayan, takılı kalmış masalın "devamı" yok: okunacak bir şey yok.
    func testUnfinishedGenerationWithoutTextIsNotOffered() {
        var building = started(title: "Yazılıyor", pagesRead: 2)
        building.status = .writingStory
        for i in building.pages.indices { building.pages[i].text = "  " }
        XCTAssertNil(MPContinueReading.pick(from: [building]))
    }

    /// Karar değişti (Faz 9 takip): metni olan takılı masal metin masalı
    /// olarak açılır, dolayısıyla yarım kalmışsa devam edilebilir.
    func testStalledStoryWithTextIsOffered() {
        var building = started(title: "Yazılıyor", pagesRead: 2)
        building.status = .writingStory
        XCTAssertEqual(MPContinueReading.pick(from: [building])?.title, "Yazılıyor")
    }

    func testEmptyStoryIsNotOffered() {
        var empty = ReaderFixtures.textStory(pages: 0)
        empty.lastReadPage = 0
        XCTAssertNil(MPContinueReading.pick(from: [empty]))
    }

    func testNothingToContinue() {
        XCTAssertNil(MPContinueReading.pick(from: []))
    }

    // MARK: - Damgası olmayan masallar (alan eklenmeden önce okunanlar)

    /// Bilinen bir tarih, tahmin edilen bir tarihi yener.
    func testStampedStoryBeatsUnstamped() {
        var stamped = started(title: "Damgalı", pagesRead: 2)
        stamped.createdAt = daysAgo(30)
        stamped.lastReadAt = daysAgo(2)

        var unstamped = started(title: "Damgasız", pagesRead: 2)
        unstamped.createdAt = daysAgo(1)     // daha yeni yaratılmış
        unstamped.lastReadAt = nil           // ama ne zaman okunduğu bilinmiyor

        XCTAssertEqual(MPContinueReading.pick(from: [unstamped, stamped])?.title, "Damgalı")
    }

    /// Damgasızlar kendi aralarında eski davranışı sürdürür: yeni yaratılan önce.
    func testUnstampedStoriesFallBackToCreationOrder() {
        var older = started(title: "Eski", pagesRead: 2)
        older.createdAt = daysAgo(10)
        var newer = started(title: "Yeni", pagesRead: 2)
        newer.createdAt = daysAgo(2)

        XCTAssertEqual(MPContinueReading.pick(from: [older, newer])?.title, "Yeni")
    }

    // MARK: -

    private func started(title: String, pagesRead: Int) -> Story {
        var s = ReaderFixtures.textStory(pages: 8, title: title)
        s.lastReadPage = pagesRead - 1
        return s
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }

    private func minutesAgo(_ n: Int) -> Date {
        Date().addingTimeInterval(-Double(n) * 60)
    }
}
