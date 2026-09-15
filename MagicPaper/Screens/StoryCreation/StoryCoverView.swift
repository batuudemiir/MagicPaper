import SwiftUI

/// The cover: the first sight of the story that was made.
///
/// Deliberately quiet. The title is the reward for the two choices, and the one
/// button leads into the Reader.
struct StoryCoverView: View {

    let story: Story
    let childName: String
    let onOpen: () -> Void

    @ObservedObject private var profileManager = ProfileManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MP.S.x5) {
                    MPCard(tone: .paper, padding: MP.S.x5) {
                        VStack(alignment: .leading, spacing: MP.S.x4) {
                            MPIcon(story.mpSymbol, size: 30, weight: .semibold)
                                .foregroundStyle(MP.C.brand)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: MP.R.md, style: .continuous)
                                        .fill(MP.C.brand.mpMixedWithWhite(0.14))
                                )

                            Text(story.title)
                                .font(MP.F.displayLG())
                                .mpTightTracking(32)
                                .foregroundStyle(MP.C.textTitle)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: MP.S.x3) {
                                MPAvatar(
                                    name: childName,
                                    color: profileManager.currentProfile?.mpColor,
                                    size: 34
                                )
                                Text("\(childName) için · \(story.pages.count) sayfa")
                                    .font(MP.F.labelSM())
                                    .foregroundStyle(MP.C.textMuted)
                            }
                        }
                    }
                }
                .mpGutter()
                .padding(.top, MP.S.x4)
                .padding(.bottom, MP.S.x6)
            }

            MPButton(title: "Hikâyeyi Başlat", size: .lg, icon: "book", fullWidth: true) {
                onOpen()
            }
            .mpGutter()
            .padding(.bottom, MP.S.x3)
        }
        .accessibilityAction(named: "Hikâyeyi başlat", onOpen)
    }
}
