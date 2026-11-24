import Foundation

/// Portable SHA-256 over exact bytes. Separate from legacy non-cryptographic fingerprints.
public enum P56Digest {
    public static func sha256(_ data: Data) -> String {
        var bytes = Array(data)
        let length = UInt64(bytes.count) * 8
        bytes.append(0x80)
        while bytes.count % 64 != 56 { bytes.append(0) }
        bytes += (0..<8).reversed().map { UInt8(truncatingIfNeeded: length >> ($0 * 8)) }
        var hash: [UInt32] = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                              0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]
        for offset in stride(from: 0, to: bytes.count, by: 64) {
            compress(Array(bytes[offset..<(offset + 64)]), into: &hash)
        }
        return hash.map { String(format: "%08x", $0) }.joined()
    }

    private static func rotate(_ value: UInt32, _ bits: UInt32) -> UInt32 {
        (value >> bits) | (value << (32 - bits))
    }

    private static func compress(_ bytes: [UInt8], into hash: inout [UInt32]) {
        var words = [UInt32](repeating: 0, count: 64)
        for i in 0..<16 {
            let j = i * 4
            words[i] = UInt32(bytes[j]) << 24 | UInt32(bytes[j+1]) << 16 | UInt32(bytes[j+2]) << 8 | UInt32(bytes[j+3])
        }
        for i in 16..<64 {
            let a = rotate(words[i-15], 7) ^ rotate(words[i-15], 18) ^ (words[i-15] >> 3)
            let b = rotate(words[i-2], 17) ^ rotate(words[i-2], 19) ^ (words[i-2] >> 10)
            words[i] = words[i-16] &+ a &+ words[i-7] &+ b
        }
        var v = hash
        for i in 0..<64 {
            let s1 = rotate(v[4], 6) ^ rotate(v[4], 11) ^ rotate(v[4], 25)
            let choice = (v[4] & v[5]) ^ (~v[4] & v[6])
            let t1 = v[7] &+ s1 &+ choice &+ constants[i] &+ words[i]
            let s0 = rotate(v[0], 2) ^ rotate(v[0], 13) ^ rotate(v[0], 22)
            let majority = (v[0] & v[1]) ^ (v[0] & v[2]) ^ (v[1] & v[2])
            v = [t1 &+ s0 &+ majority, v[0], v[1], v[2], v[3] &+ t1, v[4], v[5], v[6]]
        }
        for i in 0..<8 { hash[i] = hash[i] &+ v[i] }
    }

    private static let constants: [UInt32] = [
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2]
}
