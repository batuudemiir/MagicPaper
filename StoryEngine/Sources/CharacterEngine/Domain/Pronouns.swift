import Foundation

/// Explicit pronoun set. Never inferred from a name or from a photo.
public struct Pronouns: Codable, Sendable, Hashable {
    public let subject: String      // she / he / they / o
    public let object: String       // her / him / them / onu
    public let possessive: String   // her / his / their / onun

    public init(subject: String, object: String, possessive: String) {
        self.subject = subject
        self.object = object
        self.possessive = possessive
    }

    public static let theyThem = Pronouns(subject: "they", object: "them", possessive: "their")
    public static let sheHer = Pronouns(subject: "she", object: "her", possessive: "her")
    public static let heHim = Pronouns(subject: "he", object: "him", possessive: "his")

    /// Turkish is genderless in the third person; a single form covers every child.
    public static let turkish = Pronouns(subject: "o", object: "onu", possessive: "onun")
}
