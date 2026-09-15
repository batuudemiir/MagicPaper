import Foundation

/// Composes a book title from the blueprint's authored patterns.
///
/// Titles used to be hard-coded strings in the prototype, so every story of a
/// given shape had the same name. A pattern is a template like any other and
/// goes through the same Turkish renderer, which is what makes
/// "Fısıldayan Orman'daki" and "Gece Bahçesi'ndeki" both come out right from one
/// authored line.
public struct TitleComposer: Sendable {
    public init() {}

    public func compose(
        blueprint: CatalogBlueprint,
        slots: [String: TurkishTextRenderer.Slot],
        seed: String
    ) -> String {
        guard !blueprint.titlePatterns.isEmpty else {
            return Self.fallback(slots: slots)
        }

        // Prefer a pattern that renders cleanly. A blueprint may carry a
        // pattern whose slot the bound content does not supply; silently
        // shipping "{{object.name}}" as part of a title is worse than using the
        // next pattern.
        let ordered = Self.rotate(blueprint.titlePatterns, seed: seed, salt: blueprint.id.rawValue)
        for pattern in ordered {
            let rendered = TurkishTextRenderer.render(pattern, slots: slots)
            if rendered.isClean { return rendered.text }
        }
        return Self.fallback(slots: slots)
    }

    /// Rotates rather than picks, so the fallback order is still deterministic
    /// and still varies between children.
    private static func rotate(_ patterns: [String], seed: String, salt: String) -> [String] {
        let start = DeterministicPicker.index(count: patterns.count, seed: seed, salt: salt + ".title")
        return Array(patterns[start...] + patterns[..<start])
    }

    /// Used only when no authored pattern can be rendered. Deliberately plain:
    /// a dull title is recoverable, a broken one is not.
    private static func fallback(slots: [String: TurkishTextRenderer.Slot]) -> String {
        let child = slots["child.name"]?.value ?? ""
        let setting = slots["setting.name"]?.value
        if let setting, !setting.isEmpty {
            return TurkishTextRenderer.render(
                "{{child.name}} ve {{setting.name}}",
                slots: slots
            ).text
        }
        return child.isEmpty ? "Bir Hikâye" : "\(child)'in Hikâyesi"
    }
}
