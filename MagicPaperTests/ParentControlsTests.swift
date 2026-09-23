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

    // MARK: - Onay kapısı

    func testGateIsOpenWhenApprovalIsOff() {
        let stories = [story(.completed), story(.completed)]
        let visible = MPStoryGate.visible(stories, approvalRequired: false,
                                          isApproved: { _ in false })
        XCTAssertEqual(visible.count, 2)
    }

    /// Kuyruk vardı, kapı yoktu: onaylanmamış masal kütüphanede duruyordu.
    func testUnapprovedCompletedStoryIsHidden() {
        let approved = story(.completed)
        let waiting = story(.completed)
        let visible = MPStoryGate.visible([approved, waiting],
                                          approvalRequired: true,
                                          isApproved: { $0 == approved.id })
        XCTAssertEqual(visible.map(\.id), [approved.id])
    }

    /// Üretilmekte olan masal "onay bekliyor" değildir: ebeveyne onaylayacak
    /// bir şey vermeden çocuktan bir şey saklamak olurdu.
    func testUnfinishedStoriesAreNotGated() {
        let generating = story(.writingStory)
        let visible = MPStoryGate.visible([generating], approvalRequired: true,
                                          isApproved: { _ in false })
        XCTAssertEqual(visible.count, 1)
    }

    private func story(_ status: StoryStatus) -> Story {
        var s = ReaderFixtures.textStory(pages: 2)
        s.status = status
        return s
    }
}
