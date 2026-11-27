import Foundation
import StoryEngine

/// Writes one P56 story from the same context the legacy engine would use
/// (B4, beş arkadaş B hattı).
///
/// Here the child's real name and id go into the request, because this is the
/// story itself; the router's support check never sees them. A failure is
/// thrown to the caller, which writes with the legacy engine from the same
/// context, so the chosen companion, mode, topic, family and safety stay as
/// the parent picked them.
struct P56StoryWriter {
    private let compose: (P56Request, P56Package) throws -> P56ComposedStory

    init(compose: @escaping (P56Request, P56Package) throws -> P56ComposedStory = {
        try P56StoryComposer(package: $1).compose($0)
    }) {
        self.compose = compose
    }

    func write(
        context: StoryContext,
        mode: StoryMode,
        strategy: StorySelectionStrategy?,
        safety: ContentSafety?,
        package: P56Package,
        seed: String?,
        recentBookIDs: [String] = [],
        glancedBookIDs: [String] = [],
        companionWeights: [String: Int] = [:]
    ) throws -> Story {
        var contexts: [String] = []
        if context.family != nil { contexts.append("family") }
        if context.subOption != nil { contexts.append("topic") }
        if context.occasion != nil { contexts.append("occasion") }
        let request = P56Request(
            childID: context.childProfileID.uuidString,
            name: context.childName,
            age: context.age,
            seed: Self.seed(from: seed),
            mode: P56Mode(rawValue: mode.rawValue),
            companionID: context.companionID,
            contexts: contexts,
            contentSafety: safety,
            recentBookIDs: recentBookIDs,
            glancedBookIDs: glancedBookIDs,
            companionWeights: companionWeights)
        let composed = try compose(request, package)
        return P56StoryMapper.story(from: composed, childProfileID: context.childProfileID, strategy: strategy)
    }

    /// The app's seed is a string; P56's is a number. Digits are read as the
    /// number, anything else hashes deterministically (FNV-1a, 64 bit); no
    /// seed means a fresh random one, as the legacy engine does.
    static func seed(from text: String?) -> UInt64 {
        guard let text else { return UInt64.random(in: 0 ... UInt64.max) }
        if let number = UInt64(text) { return number }
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
