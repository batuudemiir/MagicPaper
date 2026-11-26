import Foundation

public enum P56Personalization {
    /// Only explicit proper-name tokens in the authored synthetic fixture become slots.
    /// Parent text and digest stay immutable; the output gets a separate rendered digest.
    static func template(fromSyntheticText text: String) throws -> String {
        let pattern = "(?<![\\w])Deniz(?:[’'](in|e|i|de|den))?(?![\\w’'])"
        let regex = try NSRegularExpression(pattern: pattern)
        let source = text as NSString
        var result = text
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)).reversed() {
            let suffix = match.range(at: 1)
            let replacement = "{{child.name}}" + (suffix.location == NSNotFound ? "" : "'" + source.substring(with: suffix))
            guard let range = Range(match.range, in: result) else { throw P56Error.integrity("name-token-range") }
            result.replaceSubrange(range, with: replacement)
        }
        guard !result.contains("Deniz") else { throw P56Error.integrity("unmapped-name-form") }
        return result
    }

    public static func render(_ template: String, name: String) throws -> String {
        guard !name.isEmpty, name == name.trimmingCharacters(in: .whitespacesAndNewlines),
              name.count <= 60, name.allSatisfy({ $0.isLetter || $0 == " " || $0 == "-" }),
              name.contains(where: \.isLetter) else { throw P56Error.unsupported("child-name") }
        let result = TurkishTextRenderer.render(template, slots: ["child.name": .init(name, isProperNoun: true)])
        guard result.isClean, !result.text.contains("{{") else { throw P56Error.integrity("rendering") }
        return result.text
    }
}
