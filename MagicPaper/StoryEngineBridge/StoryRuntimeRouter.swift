import Foundation
import StoryEngine

/// Which engine writes a new story (B3, beş arkadaş B hattı; karar K-A, K-B, K-C).
///
/// P56 writes only when the pilot flag is on and P56 supports the whole
/// request; everything else goes to the legacy engine exactly as today, with a
/// fixed reason code. The reason never carries child data.
///
/// This decides for **new** stories only. A saved P56 story is never rewritten
/// by the legacy engine: its source stays `.unsupported` for the historical
/// catalog (C4).
enum StoryRuntimeRoute: Equatable {
    case legacy
    case p56(P56SourceReference)
}

enum StoryRuntimeReason: String, Equatable {
    case flagOff, unsupportedAge, unsupportedRequest, payloadUnavailable, composeFailed
}

struct StoryRuntimeDecision: Equatable {
    let route: StoryRuntimeRoute
    let reason: StoryRuntimeReason?
}

/// What the router needs to know about a request. No child name or id.
struct StoryRuntimeRequest {
    let age: Int
    let mode: StoryMode
    let companionID: String?
    let family: FamilyCharacter?
    let topicID: String?
    let occasion: String?
    /// The profile's real policy (`UserProfile.effectiveSafety`), never dropped.
    let safety: ContentSafety?
}

enum StoryRuntimeFlags {
    /// Internal pilot only (K-C): `-mpFiveFriendsPilot YES` in a Debug build.
    static var fiveFriendsPilot: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "mpFiveFriendsPilot")
        #else
        false
        #endif
    }
}

final class StoryRuntimeRouter {
    /// One router for the app, so the payload is read once for the selection
    /// screen (B5) and the writer (B4).
    static let shared = StoryRuntimeRouter()

    private let isEnabled: Bool
    private let loadSource: () throws -> (P56SourceReference, P56Package)
    private let lock = NSLock()
    private var cached: Result<(P56SourceReference, P56Package), Error>?

    init(isEnabled: Bool = StoryRuntimeFlags.fiveFriendsPilot,
         loadSource: @escaping () throws -> (P56SourceReference, P56Package) = StoryRuntimeRouter.bundledSource) {
        self.isEnabled = isEnabled
        self.loadSource = loadSource
    }

    func decide(_ request: StoryRuntimeRequest) -> StoryRuntimeDecision {
        guard isEnabled else { return StoryRuntimeDecision(route: .legacy, reason: .flagOff) }
        guard case .success(let (reference, package)) = source() else {
            return StoryRuntimeDecision(route: .legacy, reason: .payloadUnavailable)
        }
        let reasons = P56Support.unsupportedReasons(for: Self.p56Request(for: request), package: package)
        if reasons.isEmpty { return StoryRuntimeDecision(route: .p56(reference), reason: nil) }
        return StoryRuntimeDecision(route: .legacy, reason: reasons == ["age"] ? .unsupportedAge : .unsupportedRequest)
    }

    /// The package behind a `.p56` decision, for the writer (B4).
    func package(for reference: P56SourceReference) -> P56Package? {
        guard case .success(let (cachedReference, package)) = source(), cachedReference == reference else { return nil }
        return package
    }

    /// An anonymous request for the support check: no child data, the real
    /// safety policy, and the request's contexts as P56 names them.
    static func p56Request(for request: StoryRuntimeRequest) -> P56Request {
        var contexts: [String] = []
        if request.family != nil { contexts.append("family") }
        if request.topicID != nil { contexts.append("topic") }
        if request.occasion != nil { contexts.append("occasion") }
        return P56Request(childID: "support-check", name: "Deniz", age: request.age, seed: 0,
                          mode: P56Mode(rawValue: request.mode.rawValue), companionID: request.companionID,
                          contexts: contexts, contentSafety: request.safety)
    }

    static func bundledSource() throws -> (P56SourceReference, P56Package) {
        let reference = try P56BundledSource().load()
        let package = try P56SnapshotStore(root: P56BundledSource.defaultStoreDirectory).load(reference)
        return (reference, package)
    }

    private func source() -> Result<(P56SourceReference, P56Package), Error> {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        let result = Result { try loadSource() }
        cached = result
        return result
    }
}
