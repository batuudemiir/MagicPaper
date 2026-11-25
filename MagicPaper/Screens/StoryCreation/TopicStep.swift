import SwiftUI
import StoryEngine

/// "Neyi öğrenelim?" / "Nereye gidelim?": moddan hemen sonra, konusu olan
/// modlarda (karar: Batuhan 19 Kasım 2026; 7 Kasım'daki "konu kimler adımında"
/// kararının yerine). İki kademede aynı büyük karolar: okuyamayan çocuk da
/// simgeye dokunur. Dokunuş adımı geçer; "Fark etmez" konuyu MagicPaper'a bırakır.
///
/// Akışın Ragi'li adımından hemen sonraki seçim adımı olduğu için Ragi yok.
struct TopicStep: View {
    let mode: StoryMode
    let topics: [StoryTopicChoice]
    /// Abonelikle açılan konular (E7): soluk, kilit simgeli, dokunulmaz.
    var lockedTopicIDs: Set<String> = []
    /// Okul öncesi "önce arkadaş" akışı (26 Kasım 2026): soru sesle sorulur,
    /// "Fark etmez" ilk sırada. `nil` ise bugünkü biçim.
    var spokenLine: String? = nil
    /// Kilit notu ("büyüklerle açılır") çocuk ekranında yok (okul öncesi kademe).
    var showsLockNote: Bool = true
    /// `nil`: "Fark etmez".
    let onChoose: (String?) -> Void

    private var isLittleFriendFirst: Bool { spokenLine != nil }

    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
              count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    private var anyTopicTile: some View {
        LittleChoiceTile(title: "Fark etmez", systemImage: "sparkles", tone: .gray,
                         accessibilityLabel: "Fark etmez, konuyu biz seçeriz") {
            MPHaptics.selection()
            onChoose(nil)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                if let spokenLine {
                    LittleSpokenTitle(title: StoryCreationSteps.topicQuestion(for: mode), spoken: spokenLine)
                } else {
                    CreationTitle(title: StoryCreationSteps.topicQuestion(for: mode))
                }

                LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                    if isLittleFriendFirst { anyTopicTile }
                    ForEach(topics) { topic in
                        let locked = lockedTopicIDs.contains(topic.id)
                        LittleChoiceTile(title: topic.name,
                                         systemImage: locked ? "lock.fill" : topic.symbol,
                                         tone: mode.tone,
                                         accessibilityLabel: locked
                                             ? "\(topic.name), büyüklerle açılır" : topic.name) {
                            MPHaptics.selection()
                            onChoose(topic.id)
                        }
                        .disabled(locked)
                        .opacity(locked ? 0.45 : 1)
                    }
                    if !isLittleFriendFirst { anyTopicTile }
                }

                // Kimler adımındaki Masal ailem deseni: kapalı karo soluk, altında tek not.
                if showsLockNote, topics.contains(where: { lockedTopicIDs.contains($0.id) }) {
                    Text("Kilitli olanlar büyüklerle açılır.")
                        .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
    }
}
