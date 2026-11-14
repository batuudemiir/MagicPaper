import XCTest
@testable import MagicPaper

/// Ebeveyn denetimleri: ekranda yazan şeyin gerçekten olması.
///
/// Bu üç anahtar (hatırlatma, ekran süresi, onay) uygulamada bir yıl boyunca
/// **açık** göründü ve hiçbiri bir şey yapmadı. Testlerin buradaki işi bir
/// regresyonu yakalamak değil: anahtarların arkasında artık bir kural olduğunu
/// söylemek. Kural silinirse ekran yine bir şey vaat ediyor olacak.
final class ParentControlsTests: XCTestCase {

    // MARK: - Günlük okuma bütçesi

    /// Limit kapalıyken ölçülecek bir şey yoktur — "çok büyük bir sayı" değil.
    func testDisabledBudgetHasNoRemainder() {
        let budget = MPReadingBudget(isEnabled: false, dailyLimitMinutes: 30,
                                     secondsBeforeSession: 99_999)
        XCTAssertNil(budget.remainingSeconds(sessionSeconds: 0))
        XCTAssertFalse(budget.isExhausted(sessionSeconds: 99_999))
    }

    func testRemainderCountsTodayPlusThisSession() {
        let budget = MPReadingBudget(isEnabled: true, dailyLimitMinutes: 30,
                                     secondsBeforeSession: 10 * 60)
        XCTAssertEqual(budget.remainingSeconds(sessionSeconds: 0), 20 * 60)
        XCTAssertEqual(budget.remainingSeconds(sessionSeconds: 5 * 60), 15 * 60)
    }

    func testBudgetIsExhaustedWhenTheDayIsSpent() {
        let budget = MPReadingBudget(isEnabled: true, dailyLimitMinutes: 30,
                                     secondsBeforeSession: 29 * 60)
        XCTAssertFalse(budget.isExhausted(sessionSeconds: 30))
        XCTAssertTrue(budget.isExhausted(sessionSeconds: 60))
    }

    /// Bütçesi zaten dolmuş bir gün, okuyucu açılır açılmaz doludur.
    /// (Okuyucu bu durumda masalı hiç açmadan kapanış yaprağını gösterir.)
    func testAlreadySpentBeforeOpening() {
        let budget = MPReadingBudget(isEnabled: true, dailyLimitMinutes: 15,
                                     secondsBeforeSession: 20 * 60)
        XCTAssertTrue(budget.isExhausted(sessionSeconds: 0))
        XCTAssertEqual(budget.remainingSeconds(sessionSeconds: 0), 0,
                       "aşılmış bütçe negatife düşmez")
    }

    /// Ekranda seçilebilen her değerin gerçek bir bütçe olması gerekir.
    /// Sıfır dakikalık bir "limit", masalı açılmadan kapatan bir ayar olurdu.
    func testEveryOfferedLimitIsUsable() {
        for minutes in MPReadingBudget.choices {
            let budget = MPReadingBudget(isEnabled: true, dailyLimitMinutes: minutes,
                                         secondsBeforeSession: 0)
            XCTAssertEqual(budget.remainingSeconds(sessionSeconds: 0), Double(minutes) * 60)
            XCTAssertFalse(budget.isExhausted(sessionSeconds: 0))
        }
    }

    // MARK: - Raf süzgeci

    /// Masal onayı kalktı (14 Kasım 2026): okunabilen her masal rafta.
    func testEveryReadableStoryIsVisible() {
        let stories = [story(.completed), story(.completed), story(.writingStory)]
        XCTAssertEqual(MPStoryGate.visible(stories).count, 3)
    }

    private func story(_ status: StoryStatus) -> Story {
        var s = ReaderFixtures.textStory(pages: 2)
        s.status = status
        return s
    }
}
