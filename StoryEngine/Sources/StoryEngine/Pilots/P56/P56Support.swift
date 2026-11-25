/// Shared, deterministic support contract for callers and composition.
public enum P56Support {
    public static func unsupportedReasons(for request: P56Request, package: P56Package) -> [String] {
        var reasons = Set(request.contexts)
        if !(5...6).contains(request.age) { reasons.insert("age") }
        if request.childID.isEmpty { reasons.insert("child-id") }
        if (try? P56Personalization.render("{{child.name}}", name: request.name)) == nil { reasons.insert("child-name") }
        // No reviewed SafetyTopic/emotion tags exist; never silently discard a supplied protection.
        if request.contentSafety != nil { reasons.insert("content-safety-not-reviewed") }
        if let companion = request.companionID, !package.companions.contains(where: { $0.id == companion }) {
            reasons.insert("companion")
        }
        if let structure = request.forcedStructure, !package.structures.contains(where: { $0.planLabel == structure }) {
            reasons.insert("structure")
        }
        if !package.books.contains(where: {
            (request.mode == nil || $0.mode == request.mode) &&
            (request.companionID == nil || $0.companionID == request.companionID) &&
            (request.forcedStructure == nil || $0.structureID == request.forcedStructure)
        }) { reasons.insert("selection-outside-pilot") }
        return reasons.sorted()
    }

    public static func companionIDs(age: Int, mode: P56Mode, package: P56Package) -> [String] {
        guard (5...6).contains(age) else { return [] }
        let supported = Set(package.books.filter { $0.mode == mode }.map(\.companionID))
        return ["companion_fox_pilot_001", "companion_hedgehog_pilot_001", "companion_owl_pilot_001",
                "companion_city_cat_001", "companion_bear_001"].filter(supported.contains)
    }
}
