import SwiftUI

/// Üretim / bekleme ekranı — 03-SCREENS.md §5.
/// İlerleme prototipteki sabit zamanlamayla değil, üretim hattının gerçek
/// durumuyla (StoryStatus) sürülür.
struct StoryGeneratingView: View {
    let world: MP.World
    let storyID: UUID?
    let onCancel: () -> Void
    let onFinished: (Story) -> Void

    @StateObject private var storyManager = StoryGenerationManager.shared
    @State private var handedOff = false

    private struct Stage {
        let title: String
        let symbol: String
    }

    private let stages: [Stage] = [
        Stage(title: "Kahraman hazırlanıyor", symbol: "person.crop.circle"),
        Stage(title: "Dünya kuruluyor", symbol: "building.columns"),
        Stage(title: "Hikâye yazılıyor", symbol: "pencil"),
        Stage(title: "Sayfalar diziliyor", symbol: "book")
    ]

    private var story: Story? {
        guard let storyID else { return nil }
        return storyManager.stories.first { $0.id == storyID }
    }

    /// Etkin aşama indeksi.
    private var activeStage: Int {
        switch story?.status {
        case .none, .some(.uploading): return 0
        case .some(.writingStory):     return 2
        case .some(.generatingImages): return 3
        case .some(.completed):        return stages.count
        case .some(.failed):           return -1
        }
    }

    /// Gerçek ilerleme: çizilen sayfa sayısına göre.
    private var progress: Double {
        guard let story else { return 0.06 }
        switch story.status {
        case .uploading:   return 0.10
        case .writingStory: return 0.35
        case .generatingImages:
            let total = max(story.pages.count, 1)
            let done = story.pages.filter { $0.imageUrl != nil }.count
            return 0.5 + 0.45 * (Double(done) / Double(total))
        case .completed:   return 1
        case .failed:      return 0
        }
    }

    private var failed: Bool { story?.status == .failed }

    var body: some View {
        VStack(spacing: MP.S.sectionGap) {
            Spacer(minLength: 0)

            if failed {
                failureBlock
            } else {
                MPProgressRing(
                    value: progress,
                    size: 146,
                    thickness: 13,
                    color: world.accent,
                    label: "%\(Int((progress * 100).rounded()))",
                    caption: "hazırlanıyor"
                )

                VStack(spacing: 10) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        stageRow(index: index, stage: stage)
                    }
                }
            }

            Spacer(minLength: 0)

            MPButton(title: failed ? "Kapat" : "Vazgeç", variant: .ghost, size: .sm, action: onCancel)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mpScreenBackground()
        .onChange(of: story?.status) { _, status in
            guard status == .completed, !handedOff, let story else { return }
            handedOff = true
            // Son sayfa da yerine oturduktan sonra okuyucuya geç.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                onFinished(story)
            }
        }
    }

    @ViewBuilder
    private func stageRow(index: Int, stage: Stage) -> some View {
        let isDone = index < activeStage
        let isActive = index == activeStage

        HStack(spacing: 12) {
            MPIcon(isDone ? "checkmark" : stage.symbol, size: 19, weight: .semibold)
                .foregroundStyle(isDone ? MP.C.calm : (isActive ? MP.C.brand : MP.C.textFaint))
                .frame(width: 22)

            Text(stage.title)
                .font(MP.F.bodySM(.bold))
                .foregroundStyle(MP.C.textTitle)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(MPStageRowSkin(isActive: isActive))
        .opacity(isDone || isActive ? 1 : 0.45)
        .animation(MP.M.gated(MP.M.easeOut), value: activeStage)
    }

    /// Hata durumu — tasarımda kapsam dışıydı, gerçek hattın ihtiyacı olduğu için eklendi.
    private var failureBlock: some View {
        VStack(spacing: 14) {
            MPIcon("exclamationmark.triangle.fill", size: 34, weight: .semibold)
                .foregroundStyle(MP.C.danger)
                .frame(width: 72, height: 72)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MP.C.playSoft))

            Text("Masal oluşturulamadı")
                .font(MP.F.displayMD())
                .foregroundStyle(MP.C.textTitle)

            Text("Bağlantını kontrol edip tekrar dene.")
                .font(MP.F.bodyMD())
                .foregroundStyle(MP.C.textMuted)
                .multilineTextAlignment(.center)
        }
    }
}

/// Etkin aşama satırı beyaz kart olur ve 3px alt kenar kazanır.
private struct MPStageRowSkin: ViewModifier {
    let isActive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content.mpEdge(fill: MP.C.surfaceCard, edge: MP.C.edgeCard, radius: MP.R.md)
        } else {
            content
        }
    }
}
