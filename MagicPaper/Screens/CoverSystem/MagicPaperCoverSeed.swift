import Foundation

// MARK: - Cover Seed

/// Deterministic seed derivation for the MagicPaper Cover System.
///
/// Every cover decision flows from this seed. The hash input includes the
/// system version so that algorithm changes in V2 don't silently alter
/// covers that were generated under V1.
enum MagicPaperCoverSeed {

    /// Bump this when the generator algorithm changes in a way that would
    /// produce different visual output for the same book ID.
    static let systemVersion = "1.0"

    /// Derives a stable 64-bit seed from a book identifier.
    ///
    /// The same `bookID` always produces the same seed, across app launches,
    /// devices, and OS versions. Swift's built-in `Hashable` is explicitly
    /// avoided because its hash is not stable across processes.
    static func seed(for bookID: String) -> UInt64 {
        let input = "MagicPaperCover.\(systemVersion):\(bookID)"
        return fnv1a(input)
    }

    // MARK: - FNV-1a (64-bit)

    /// Fowler–Noll–Vo 1a hash — simple, fast, deterministic, platform-independent.
    private static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325   // FNV offset basis
        let prime: UInt64 = 0x100000001b3        // FNV prime
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}

// MARK: - Seeded Random Number Generator

/// A deterministic pseudo-random number generator using xorshift64.
///
/// Given the same seed, the sequence of outputs is always identical.
/// This is the sole source of "randomness" in the cover system.
struct SeededRandom {

    private var state: UInt64

    init(seed: UInt64) {
        // Zero is a fixed point for xorshift; ensure we never start there.
        self.state = seed == 0 ? 1 : seed
    }

    /// Advances the state and returns the next pseudo-random 64-bit value.
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Returns a `Double` in [0, 1).
    mutating func nextDouble() -> Double {
        Double(next() % 1_000_000) / 1_000_000.0
    }

    /// Returns an `Int` in [0, upperBound).
    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// Returns a `Double` uniformly distributed in `range`.
    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }

    /// Returns an `Int` uniformly distributed in `range`.
    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        guard range.lowerBound < range.upperBound else { return range.lowerBound }
        return range.lowerBound + nextInt(upperBound: range.upperBound - range.lowerBound + 1)
    }

    /// Picks a random element from a non-empty array.
    mutating func pick<T>(from array: [T]) -> T {
        array[nextInt(upperBound: array.count)]
    }

    /// Picks an element using weighted probabilities.
    mutating func weightedPick<T>(from items: [(T, Double)]) -> T {
        let totalWeight = items.reduce(0.0) { $0 + $1.1 }
        var roll = nextDouble() * totalWeight
        for (item, weight) in items {
            roll -= weight
            if roll <= 0 { return item }
        }
        return items.last!.0
    }

    /// Returns a deterministically shuffled copy of the array.
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var result = array
        for i in stride(from: result.count - 1, through: 1, by: -1) {
            let j = nextInt(upperBound: i + 1)
            result.swapAt(i, j)
        }
        return result
    }

    /// Returns `true` with the given probability (0…1).
    mutating func chance(_ probability: Double) -> Bool {
        nextDouble() < probability
    }
}
