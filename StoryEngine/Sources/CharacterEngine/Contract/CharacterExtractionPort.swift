import Foundation

/// A photo handed to extraction. The engine never sees pixels — the host app
/// passes a locator it already owns.
public struct CharacterExtractionInput: Sendable {
    public let ownerProfileID: UUID
    public let displayName: String
    public let ageYears: Int
    public let pronouns: Pronouns
    public let photoLocator: String
    /// Facts the parent typed in. Always outrank anything derived from a photo.
    public let parentProvidedDescriptors: [CharacterDescriptor]
    public let doNotDepict: [String]

    public init(
        ownerProfileID: UUID,
        displayName: String,
        ageYears: Int,
        pronouns: Pronouns,
        photoLocator: String,
        parentProvidedDescriptors: [CharacterDescriptor] = [],
        doNotDepict: [String] = []
    ) {
        self.ownerProfileID = ownerProfileID
        self.displayName = displayName
        self.ageYears = ageYears
        self.pronouns = pronouns
        self.photoLocator = photoLocator
        self.parentProvidedDescriptors = parentProvidedDescriptors
        self.doNotDepict = doNotDepict
    }
}

/// The write side of the Character Engine: turning a photo into a character.
///
/// V1 ships no vision-based implementation. The bridge supplies a profile built
/// from data the app already has; a real extractor drops in behind this port
/// without the Story Engine noticing.
public protocol CharacterExtractionPort: Sendable {
    func extractProfile(from input: CharacterExtractionInput) async throws -> CharacterProfile
}
