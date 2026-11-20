import Foundation
import EngineFoundation

/// Narrow identity evidence for reviewed authored prose, independent of rendered names.
public enum AuthoredSourceFingerprint {
    public struct Source: Sendable {
        public let templateID: String
        public let variantID: String
        public let text: String

        public init(templateID: String, variantID: String, text: String) {
            self.templateID = templateID
            self.variantID = variantID
            self.text = text
        }
    }

    public static func make(sources: [Source], discovery: CatalogObject) -> String {
        let traits = discovery.traits.map(\.rawValue).sorted()
        let values = ["story-authored-source-v1", String(sources.count)]
            + sources.flatMap { [$0.templateID, $0.variantID, $0.text] }
            + [discovery.id.rawValue, discovery.name, discovery.description, String(traits.count)] + traits
        // Length prefixes keep even embedded separator bytes unambiguous.
        return StableHash.fingerprint(values.map { "\($0.utf8.count):\($0)" })
    }
}
