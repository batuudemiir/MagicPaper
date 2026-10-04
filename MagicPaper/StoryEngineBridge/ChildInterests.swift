import Foundation

/// One "Neleri sever?" chip (FAZ 12), as the profile screens draw it.
///
/// Display text and a stable id. The word comes from the catalog's interest
/// vocabulary, never from the app: a word the app has never heard of still
/// arrives with its own name.
struct InterestChoice: Identifiable, Hashable {
    /// Catalog interest id, e.g. `animals`. What is stored on the profile.
    let id: String
    /// The chip label, e.g. "Hayvanlar".
    let name: String
    /// SF Symbol name; nil draws a plain chip.
    let symbol: String?
}

/// The rules for a child's interests that are not about drawing them.
///
/// Three, pure, so they are tested without a screen:
/// - a parent picks at most `maxSelection`, and none is required;
/// - an edit never drops a stored interest the screen did not show (a word the
///   catalog stops offering stays saved, and comes back if content returns);
/// - only words the catalog offers today are shown and reach the engine.
enum ChildInterests {
    /// More than three dilutes the weight each choice adds, and the point of a
    /// choice is that it shows. Zero is allowed: a parent who does not know yet
    /// is not made to guess.
    static let maxSelection = 3

    /// Fewer offered words than this and the interest screens are hidden
    /// (karar, 4 Ekim 2026): two chips that every story already matches are
    /// not a choice. Stored interests are kept and still weigh selection;
    /// the screens return on their own when content brings a fourth word.
    static let minimumOfferedToShow = 4

    /// Whether "Neleri sever?" and the parent section are shown at all.
    static func isShown(_ choices: [InterestChoice]) -> Bool {
        choices.count >= minimumOfferedToShow
    }

    /// The stored interests the catalog offers today, in the catalog's order.
    /// What the screen shows as selected and what the engine is given.
    static func offered(_ stored: [String], from choices: [InterestChoice]) -> [String] {
        let saved = Set(stored)
        return choices.map(\.id).filter(saved.contains)
    }

    /// What to store after an edit: the edited selection, capped and in the
    /// catalog's order, then whatever was stored but not shown, unchanged.
    static func merging(stored: [String], edited: [String], choices: [InterestChoice]) -> [String] {
        let shown = Set(choices.map(\.id))
        let picked = Array(offered(edited, from: choices).prefix(maxSelection))
        let hidden = stored.filter { !shown.contains($0) }
        return picked + hidden
    }

    /// Whether `id` can be added to `selection` without passing the limit.
    static func canAdd(_ id: String, to selection: [String]) -> Bool {
        selection.contains(id) || selection.count < maxSelection
    }
}
