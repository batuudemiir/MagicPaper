import CryptoKit
import Foundation

/// Resolves a saved revision, independently of today's story selection rules.
/// Only local, checksum-pinned bundle files are accepted.
enum StorySpotAssetResolver {
    static func url(for art: StoryPageArt, bundle: Bundle = .main) -> URL? {
        guard art.isBundledSpot,
              let fileName = art.bundledFileName,
              let digest = art.assetDigest else { return nil }
        return validatedURL(fileName: fileName, digest: digest, bundle: bundle)
    }

    static func isSafeFileName(_ name: String) -> Bool {
        name.range(of: "^[A-Za-z0-9][A-Za-z0-9_-]*\\.(png|mpart)$", options: .regularExpression) != nil
    }

    static func validatedURL(fileName: String, digest: String, bundle: Bundle = .main) -> URL? {
        guard isSafeFileName(fileName),
              digest.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil,
              let url = bundle.url(forResource: fileName, withExtension: nil),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let actual = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return actual == digest ? url : nil
    }
}
