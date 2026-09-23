import Foundation
import EngineFoundation

// MARK: - "Copy, do not rebuild"

/// Tools for a migration that moves stored characters between backing stores.
///
/// The rule such a migration has to obey is that it **copies** versions rather
/// than rebuilding them. `CharacterVersionID` and `CharacterAsset.id` are fresh
/// UUIDs, not functions of their content, so a rebuilt version carries a new id
/// even when every field is identical — and every story pinned to the old id
/// then fails to resolve. The child stops looking like herself in books that
/// are already on the shelf.
///
/// Plain equality is not enough to police that. `CharacterVersion` is
/// `Equatable` *including* its id, so a rebuild is unequal to its original —
/// but so is a legitimate edit, and the two cases need different responses. The
/// fingerprint below separates them: same fingerprint with a different id is a
/// rebuild (a bug), different fingerprint is a real change (expected).
extension CharacterVersion {
    /// Deterministic digest of what this snapshot *says*, ignoring who it is.
    ///
    /// Identifiers and timestamps are excluded: they are the properties a
    /// rebuild changes, so including them would hide exactly the case this
    /// exists to expose. Uses `StableHash` rather than `Hashable`, which is
    /// seeded per process and therefore useless across launches.
    public var contentFingerprint: String {
        var parts: [String] = [
            "version:\(versionNumber)",
            "provenance:\(provenance.rawValue)",
            "age:\(identity.ageYears)",
            "pronouns:\(identity.pronouns.subject)/\(identity.pronouns.object)/\(identity.pronouns.possessive)",
            "seed:\(identity.identitySeed)"
        ]

        // Sorted, because descriptor order is presentation, not identity: a
        // store that round-trips them in a different order has still copied.
        parts += identity.descriptors
            .map { "descriptor:\($0.category.rawValue)=\($0.normalizedValue)" }
            .sorted()
        parts += identity.doNotDepict
            .map { "doNotDepict:\(DescriptorNormalization.normalize($0))" }
            .sorted()

        parts += [
            "style:\(styleProfile.illustrationStyleID)",
            "palette:\(styleProfile.palettePresetID)"
        ]
        parts += styleProfile.renderingNotes.map { "note:\($0)" }.sorted()
        parts += styleProfile.negativeTraits.map { "negative:\($0)" }.sorted()

        parts += [
            "assetSeed:\(assetSet.identitySeed)",
            "stylePreset:\(assetSet.stylePresetID)",
            "master:\(assetSet.masterReference?.locator ?? "-")",
            "fullBody:\(assetSet.fullBodyReference?.locator ?? "-")",
            "face:\(assetSet.faceReference?.locator ?? "-")"
        ]
        parts += assetSet.expressionReferences
            .map { "expression:\($0.key.rawValue)=\($0.value.locator)" }
            .sorted()

        return StableHash.fingerprint(parts)
    }
}

/// Why a profile was not a faithful copy of another. Empty means it was.
public enum CharacterCopyDefect: Sendable, Hashable, CustomStringConvertible {
    /// A version present in the original is missing from the copy.
    case missingVersion(CharacterVersionID)
    /// A version says the same thing but carries a different id — the migration
    /// rebuilt it instead of copying it, and every story pinned to the original
    /// id is now unresolvable.
    case rebuiltVersion(original: CharacterVersionID, fingerprint: String)
    /// A version kept its id but its content moved. History is append-only;
    /// this rewrites a book that is already on the shelf.
    case rewrittenVersion(CharacterVersionID)
    /// The character's own id moved, orphaning every story it appears in.
    case characterIDChanged
    /// The active pointer no longer names a version that exists.
    case danglingActiveVersion(CharacterVersionID)

    public var description: String {
        switch self {
        case .missingVersion(let id):
            return "version \(id) was dropped"
        case .rebuiltVersion(let original, let fingerprint):
            return "version \(original) was rebuilt, not copied (content \(fingerprint) survived, id did not)"
        case .rewrittenVersion(let id):
            return "version \(id) kept its id but changed content"
        case .characterIDChanged:
            return "character id changed"
        case .danglingActiveVersion(let id):
            return "active version \(id) is not in the version list"
        }
    }
}

extension CharacterProfile {
    /// Every version's content digest, keyed by the id that must survive.
    public var versionFingerprints: [CharacterVersionID: String] {
        Dictionary(uniqueKeysWithValues: versions.map { ($0.id, $0.contentFingerprint) })
    }

    /// Checks that `self` is `original` moved, not `original` remade.
    ///
    /// Written for a persistence migration to assert on after it writes and
    /// before it marks itself succeeded. It reports every defect rather than
    /// the first, so one run tells a migration everything it got wrong.
    ///
    /// Adding versions is allowed — a migration that also brings a character
    /// forward is still faithful as long as it did not touch the old ones.
    /// Dropping, rebuilding or rewriting one is not.
    public func copyDefects(from original: CharacterProfile) -> [CharacterCopyDefect] {
        var defects: [CharacterCopyDefect] = []

        if id != original.id { defects.append(.characterIDChanged) }

        let mine = versionFingerprints
        // Content that arrived under some other id — the rebuild signature.
        let survivingContent = Set(mine.values)

        for version in original.versions {
            guard let fingerprint = mine[version.id] else {
                let content = version.contentFingerprint
                if survivingContent.contains(content) {
                    defects.append(.rebuiltVersion(original: version.id, fingerprint: content))
                } else {
                    defects.append(.missingVersion(version.id))
                }
                continue
            }
            if fingerprint != version.contentFingerprint {
                defects.append(.rewrittenVersion(version.id))
            }
        }

        if version(id: activeVersionID) == nil {
            defects.append(.danglingActiveVersion(activeVersionID))
        }

        return defects
    }

    /// Convenience over `copyDefects(from:)` for a call site that only branches.
    public func preservesVersionIdentity(of original: CharacterProfile) -> Bool {
        copyDefects(from: original).isEmpty
    }
}
