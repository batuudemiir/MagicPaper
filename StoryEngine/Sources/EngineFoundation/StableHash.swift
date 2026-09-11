import Foundation

/// Deterministic hashing for fingerprints and seeds.
///
/// Swift's `Hashable` is seeded per process, so it cannot be used for anything
/// that has to stay equal across launches. Scene fingerprints and image seeds
/// both do — a story reopened tomorrow must not decide its illustrations are
/// stale — so they go through FNV-1a here instead.
public enum StableHash {
    private static let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
    private static let prime: UInt64 = 0x100000001b3

    public static func hash(_ values: [String]) -> UInt64 {
        var result = offsetBasis
        for value in values {
            for byte in value.utf8 {
                result ^= UInt64(byte)
                result = result &* prime
            }
            // Separator, so ["ab","c"] and ["a","bc"] differ.
            result ^= 0x1F
            result = result &* prime
        }
        return result
    }

    public static func hash(_ values: String...) -> UInt64 { hash(values) }

    /// Hex form used wherever a fingerprint is stored or compared.
    public static func fingerprint(_ values: [String]) -> String {
        String(format: "%016llx", hash(values))
    }

    public static func fingerprint(_ values: String...) -> String { fingerprint(values) }
}
