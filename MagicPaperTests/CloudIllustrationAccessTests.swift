import XCTest
import StoryEngine
@testable import MagicPaper

/// Görsel bulut yolu (Firebase + fal.ai) bayrak arkasında: varsayılan kapalı,
/// kapalıyken ne motor kurulur ne boru hattı çalışır.
@MainActor
final class CloudIllustrationAccessTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        suiteName = "CloudIllustrationAccessTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    private struct NeverCalledProvider: StoryAIProvider {
        func complete(_ request: AICompletionRequest) async throws -> AICompletionResponse {
            XCTFail("Bayrak kapalıyken metin sağlayıcısı çağrılmamalı")
            throw StoryEngineError.providerFailed(operation: request.operation, errorClass: .permanent, message: "unused")
        }
    }

    func testFlagDefaultsToOff() {
        XCTAssertFalse(CloudIllustrationAccess.isEnabled(defaults: defaults))
    }

    func testFlagCanBeEnabledOnlyInDebug() {
        CloudIllustrationAccess.setDeveloperFlag(true, defaults: defaults)
        #if DEBUG
        XCTAssertTrue(CloudIllustrationAccess.isEnabled(defaults: defaults))
        #else
        XCTAssertFalse(CloudIllustrationAccess.isEnabled(defaults: defaults))
        #endif
    }

    func testContainerRefusesWhenFlagIsOff() {
        let result = StoryEngineContainer.make(textProvider: NeverCalledProvider(), defaults: defaults)
        guard case .failure(let reason) = result else {
            return XCTFail("Bayrak kapalıyken motor kurulmamalı")
        }
        XCTAssertEqual(reason, .cloudIllustrationDisabled)
    }

    func testPipelineRefusesPhotoUploadWhenFlagIsOff() async {
        do {
            _ = try await CloudIllustrationPipeline.uploadChildPhoto(UIImage(), defaults: defaults)
            XCTFail("Bayrak kapalıyken yükleme reddedilmeli")
        } catch {
            XCTAssertEqual(error as? CloudIllustrationError, .disabled)
        }
    }

    func testPipelineRefusesImageGenerationWhenFlagIsOff() async {
        let page = StoryPage(title: "t", text: "x", imagePrompt: "y")
        do {
            _ = try await CloudIllustrationPipeline.generateImages(
                for: [page], referencePhotoUrl: "ref", theme: .fantasy, defaults: defaults, onPage: { _ in })
            XCTFail("Bayrak kapalıyken çizim reddedilmeli")
        } catch {
            XCTAssertEqual(error as? CloudIllustrationError, .disabled)
        }
    }
}
