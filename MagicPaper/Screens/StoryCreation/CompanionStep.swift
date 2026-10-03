import SwiftUI

/// Step 2 — who comes with us?
///
/// The candidates are derived from the idea chosen a moment ago, which is what
/// makes the companion a role rather than decoration: a companion who would
/// dissolve the story's premise is not offered. A companion that can fly does
/// not appear for a story about crossing something on your own, and one that
/// says exactly what it sees does not appear for a story about misreading the
/// evidence — not because this screen knows that, but because the blueprints do.
struct CompanionStep: View {

    let ideaID: String?
    /// The resolved intent. Candidates must be able to carry a story of this
    /// mode — a companion only the wrong mode's blueprints accept is not offered.
    var mode: StoryMode? = nil
    /// The child's age, so candidates come from the band the story is written for.
    var age: Int? = nil
    /// Where the candidates come from. The flow passes its own so both steps
    /// ask the same source.
    var source: any StoryChoiceSource = StoryChoiceSources.current
    /// Nil means "surprise me". §16: this keeps the chosen idea; it does not
    /// start the story over.
    let onChoose: (String?) -> Void

    private static let shown = 3

    private var candidates: [CompanionChoice] {
        Array(source.companionChoices(forIdeaID: ideaID, mode: mode, age: age)
            .prefix(Self.shown))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MP.S.x2) {
                    // "Macera" değil: Uyku öncesinde de bu soru soruluyor.
                    Text("Masalda kimler olsun?")
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                }
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x5)

                VStack(spacing: MP.S.stackGap) {
                    ForEach(candidates) { companion in
                        MPChoiceTile(
                            title: companion.name,
                            description: description(for: companion),
                            symbol: symbol(for: companion),
                            accent: MP.C.brand,
                            layout: .column
                        ) {
                            onChoose(companion.id)
                        }
                        .accessibilityLabel("\(companion.name), \(companion.kind)")
                    }

                    MPChoiceTile(
                        title: "Bana sürpriz yap",
                        description: "En uygun arkadaşı biz seçelim.",
                        symbol: "wand.and.stars",
                        accent: MP.C.reward,
                        layout: .column
                    ) {
                        onChoose(nil)
                    }
                }
            }
            .mpGutter()
            .padding(.bottom, MP.S.x6)
        }
    }

    /// The companion's own line if it has one, otherwise what it is. Never the
    /// trait list — "reassuring" is a casting concept, not something to read.
    private func description(for companion: CompanionChoice) -> String {
        companion.personality.isEmpty
            ? companion.kind.capitalized(with: Locale(identifier: "tr_TR"))
            : companion.personality
    }

    /// Content declares no icon, so this maps from the animal.
    ///
    /// Every animal that has a symbol gets its own. The previous version sent
    /// hedgehog, rabbit, fox and bear all to `pawprint`, so four of the five
    /// companions in the library were drawn identically — on a screen whose
    /// entire job is choosing between three of them. A child picking a
    /// companion by its picture was choosing between three copies of the same
    /// picture.
    ///
    /// The paw stays as the honest fallback for an animal the symbol set has
    /// nothing for, and `CompanionSymbolTests` fails if two shipped companions
    /// ever land on it together — which is the point at which a fallback stops
    /// being a fallback and becomes the collision again.
    static func symbol(forType type: String) -> String {
        switch type.lowercased(with: Locale(identifier: "tr_TR")) {
        case "baykuş", "kuş":   return "bird"
        case "yunus", "balık":  return "fish"
        case "ejderha":         return "flame.fill"
        case "tavşan":          return "hare"
        case "tilki", "köpek":  return "dog"
        case "kedi":            return "cat"
        case "ayı":             return "teddybear"
        case "kaplumbağa":      return "tortoise"
        case "kertenkele":      return "lizard"
        case "robot":           return "cpu"
        case "kelebek":         return "ladybug"
        default:                return "pawprint"
        }
    }

    private func symbol(for companion: CompanionChoice) -> String {
        Self.symbol(forType: companion.kind)
    }
}
