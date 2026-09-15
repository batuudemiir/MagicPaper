import SwiftUI
import StoryEngine

/// Step 1 — which little story should we begin?
///
/// Not "where shall it happen" and not a list of themes. The cards are narrative
/// promises: each can become several different stories, and the engine decides
/// which. Nothing here names a world, a blueprint or a theme, because none of
/// those are the parent's decision to make.
struct StoryIdeaStep: View {

    let age: Int
    /// Nil means "surprise me" — a first-class engine mode, not a random card.
    let onChoose: (String?) -> Void

    /// §7: three plus Surprise. Curated, not a menu; the screen owns the number
    /// so changing it does not mean re-authoring content.
    private static let shown = 3

    private var ideas: [CatalogStoryIdea] {
        Array(OfflineStoryService.shared.storyIdeas(forAge: age).prefix(Self.shown))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MP.S.x2) {
                    Text("Bugün hangi hikâyeye başlayalım?")
                        .font(MP.F.displayLG())
                        .mpTightTracking(32)
                        .foregroundStyle(MP.C.textTitle)
                    Text("Birini seç, gerisini biz hazırlayalım.")
                        .font(MP.F.bodyMD())
                        .foregroundStyle(MP.C.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, MP.S.x3)
                .padding(.bottom, MP.S.x5)

                VStack(spacing: MP.S.stackGap) {
                    ForEach(ideas) { idea in
                        MPChoiceTile(
                            title: idea.display,
                            description: idea.supportingText,
                            symbol: idea.illustration,
                            accent: MP.C.brand,
                            layout: .column
                        ) {
                            onChoose(idea.id.rawValue)
                        }
                        .accessibilityLabel("\(idea.display). \(idea.supportingText)")
                    }

                    MPChoiceTile(
                        title: "Bana sürpriz yap",
                        description: "Bugünün hikâyesini biz seçelim.",
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
}
