import XCTest
@testable import MagicPaper

/// 26 · Uyku modu: kapanma süresi ve kararma.
final class SleepTimerTests: XCTestCase {

    func testTheScreenStaysLitUntilTheLastTwoMinutes() {
        let timer = MPSleepTimer(minutes: 10)
        XCTAssertEqual(timer.dim(after: 0), 0)
        XCTAssertEqual(timer.dim(after: 8 * 60), 0)
        XCTAssertGreaterThan(timer.dim(after: 9 * 60), 0)
        XCTAssertEqual(timer.dim(after: 10 * 60), MPSleepTimer.maxDim, accuracy: 0.0001)
    }

    func testDimmingOnlyGrows() {
        let timer = MPSleepTimer(minutes: 15)
        let values = stride(from: 0.0, through: 900, by: 10).map { timer.dim(after: $0) }
        XCTAssertEqual(values, values.sorted())
    }

    func testReducedMotionDimsInSteps() {
        let timer = MPSleepTimer(minutes: 10)
        let steps = Set(stride(from: 480.0, through: 600, by: 1).map { timer.dim(after: $0, stepped: true) })
        XCTAssertLessThanOrEqual(steps.count, 5)
    }

    func testTheTimerEndsAtItsDuration() {
        let timer = MPSleepTimer(minutes: 20)
        XCTAssertFalse(timer.isOver(after: 20 * 60 - 1))
        XCTAssertTrue(timer.isOver(after: 20 * 60))
    }

    func testASessionSkipsEmptyPages() {
        let session = MPSleepSession(title: "T", pages: ["Bir.", "  ", "İki."])
        XCTAssertEqual(session.pages, ["Bir.", "İki."])
    }
}
