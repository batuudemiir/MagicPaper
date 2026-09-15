import Foundation

/// One fact about where the story has got to, written `"key=value"` in the
/// catalog — for example `problem_solved=true` or `problem=crossing`.
///
/// Values stay strings. A typed value system would be more precise and would buy
/// nothing: the engine only ever asks "does the current state match this", and
/// string equality answers that.
public struct StateFact: Codable, Sendable, Hashable, CustomStringConvertible {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key.trimmingCharacters(in: .whitespaces)
        self.value = value.trimmingCharacters(in: .whitespaces)
    }

    /// Parses `"key=value"`. A bare `"key"` means `key=true`, which is how the
    /// shipped catalog writes flags in a few places.
    public init?(expression: String) {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        guard let separator = trimmed.firstIndex(of: "=") else {
            self.init(key: trimmed, value: "true")
            return
        }
        let key = String(trimmed[trimmed.startIndex..<separator])
        let value = String(trimmed[trimmed.index(after: separator)...])
        guard !key.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        self.init(key: key, value: value)
    }

    public var description: String { "\(key)=\(value)" }

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let parsed = StateFact(expression: raw) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "'\(raw)' is not a state expression like \"key=value\"")
            )
        }
        self = parsed
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// The story's running state. Small on purpose: enough to keep a book coherent,
/// not a general-purpose state machine.
public struct NarrativeState: Sendable, Hashable {
    private var facts: [String: String]

    public init(_ facts: [String: String] = [:]) { self.facts = facts }

    public init(applying changes: [StateFact]) {
        facts = [:]
        apply(changes)
    }

    public subscript(key: String) -> String? { facts[key] }
    public var allFacts: [String: String] { facts }
    public var isEmpty: Bool { facts.isEmpty }

    public func satisfies(_ requirement: StateFact) -> Bool {
        facts[requirement.key] == requirement.value
    }

    public func satisfies(_ requirements: [StateFact]) -> Bool {
        requirements.allSatisfy(satisfies)
    }

    public mutating func apply(_ change: StateFact) { facts[change.key] = change.value }

    public mutating func apply(_ changes: [StateFact]) {
        for change in changes { apply(change) }
    }

    public func applying(_ changes: [StateFact]) -> NarrativeState {
        var copy = self
        copy.apply(changes)
        return copy
    }
}
