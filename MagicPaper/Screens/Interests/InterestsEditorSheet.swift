import SwiftUI

/// Bir çocuğun ilgi alanlarını düzenleme sayfası (FAZ 12), Ebeveyn > Çocuklar'dan.
///
/// Yalnızca bugün sunulan kelimeler gösterilir. Profilde saklı olup artık
/// sunulmayan bir kelime kaydederken silinmez (`ChildInterests.merging`).
struct InterestsEditorSheet: View {
    let profile: UserProfile
    var source: any StoryChoiceSource = StoryChoiceSources.current

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var profileManager = ProfileManager.shared

    @State private var choices: [InterestChoice] = []
    @State private var selection: [String] = []

    var body: some View {
        MPSheet(title: InterestCopy.editorTitle(child: profile.name), onClose: close) {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                Text(InterestCopy.editorNote)
                    .font(MP.F.bodySM())
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                InterestChipGrid(choices: choices, selection: $selection)
            }
        } footer: {
            MPButton(title: InterestCopy.save, fullWidth: true, action: save)
        }
        .onAppear {
            choices = source.interestChoices()
            selection = ChildInterests.offered(profile.interests, from: choices)
        }
    }

    private func save() {
        let merged = ChildInterests.merging(stored: profile.interests, edited: selection, choices: choices)
        profileManager.setInterests(merged, for: profile.id)
        MPHaptics.success()
        app.showToast(InterestCopy.saved)
        close()
    }

    private func close() { app.sheet = nil }
}
