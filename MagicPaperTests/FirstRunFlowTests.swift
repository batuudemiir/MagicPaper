import XCTest
@testable import MagicPaper

/// Faz 8: ilk açılış sırası. "Önce masal" bayrağı kapalıyken bugünkü sıra,
/// açıkken giriş ilk masaldan sonra.
final class FirstRunFlowTests: XCTestCase {

    private func inputs(signedIn: Bool = false, hasProfiles: Bool = false, storyFirst: Bool = false) -> AppGate.Inputs {
        AppGate.Inputs(onboardingDone: true, signedIn: signedIn, deferredSignIn: false,
                       consentCurrent: signedIn, restoreSettled: true,
                       hasProfiles: hasProfiles, hasCurrentProfile: hasProfiles, storyFirst: storyFirst)
    }

    func testFlagOffKeepsSignInBeforeTheChild() {
        XCTAssertEqual(AppGate.resolve(inputs()), .signIn)
        XCTAssertEqual(AppGate.resolve(inputs(hasProfiles: true)), .signIn)
    }

    func testStoryFirstLetsTheChildInBeforeSignIn() {
        XCTAssertEqual(AppGate.resolve(inputs(storyFirst: true)), .createProfile)
        XCTAssertEqual(AppGate.resolve(inputs(hasProfiles: true, storyFirst: true)), .app)
    }

    func testAfterTheFirstStorySignInIsAsked() {
        // İlk masal bitince `storyFirst` düşer: giriş sorulur, masal kaybolmaz.
        XCTAssertEqual(AppGate.resolve(inputs(hasProfiles: true, storyFirst: false)), .signIn)
    }

    func testSignedInParentsAreUnaffected() {
        XCTAssertEqual(AppGate.resolve(inputs(signedIn: true, hasProfiles: true, storyFirst: true)), .app)
    }

    func testStoryFirstIsOffByDefault() {
        let defaults = UserDefaults(suiteName: "FirstRunFlowTests")!
        defaults.removePersistentDomain(forName: "FirstRunFlowTests")
        XCTAssertFalse(MPRemoteFlags.value(.storyBeforeAccount, default: false, defaults: defaults))
    }

    func testTrustCopyStaysTrue() {
        // Yalnızca doğru olan söylenir: "yapay zeka" ve hız iddiası yok.
        let copy = OnboardingCopy.trust.lowercased()
        XCTAssertFalse(copy.contains("yapay zeka"))
        XCTAssertFalse(copy.contains("anında"))
        XCTAssertTrue(copy.contains("reklam yok"))
    }
}
