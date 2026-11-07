import SwiftUI

#if DEBUG
/// Ragi'nin hareket ve ses vitrini (yalnızca DEBUG, `-mpDemo YES -mpRagiStudio YES`).
/// Önizleme videosu buradan kaydedilir; her sahnenin zemini farklı olduğu için video
/// aracı sesi sahne geçişine hizalar (`Tools/record_ragi_preview.swift`).
struct RagiStudioView: View {

    private struct Scene {
        let mascot: Mascot
        let act: RagiAct
        let title: String
        let cue: MPSound.Cue?
        let tone: MPWorldTone
    }

    private static let scenes: [Scene] = [
        Scene(mascot: .waving, act: .wave, title: "Selam", cue: .ragi, tone: .lav),
        Scene(mascot: .happy, act: .cheer, title: "Masal sonu", cue: .ending, tone: .peach),
        Scene(mascot: .pencil, act: .write, title: "Masal yazılıyor", cue: .ready, tone: .mint),
        Scene(mascot: .reading, act: .read, title: "Okuyor", cue: .page, tone: .sky),
        Scene(mascot: .front, act: .idle, title: "Bekliyor", cue: .earned, tone: .yellow),
        Scene(mascot: .walking, act: .walk, title: "Yürüyor", cue: nil, tone: .pink),
        Scene(mascot: .sleeping, act: .sleep, title: "Uyuyor", cue: nil, tone: .green)
    ]

    @State private var index = 0
    @StateObject private var app = MPAppState()

    var body: some View {
        if UserDefaults.standard.bool(forKey: "mpRagiEnding") { endingPreview } else { stage }
    }

    /// Masal sonu örnek masalla (`-mpRagiEnding YES`).
    private var endingPreview: some View {
        StoryEndingLeaf(story: Story(title: "Ay'ın Bahçesi", childName: "İrem", theme: .fantasy, language: .turkish),
                        theme: .cream, accent: MPColor.actionPrimary, isCurrent: true, onClose: {})
            .environmentObject(app)
    }

    private var stage: some View {
        let scene = Self.scenes[index]
        return VStack(spacing: MPSpacing.xxl) {
            MascotImage(mascot: scene.mascot, width: 280, act: scene.act).id(index)
            Text(scene.title).mpText(.page).foregroundStyle(MPColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(scene.tone.soft.ignoresSafeArea())
        .task {
            // Her sahne 4 saniye, bir tur.
            while !Task.isCancelled {
                if let cue = Self.scenes[index].cue { MPSound.play(cue) }
                try? await Task.sleep(for: .seconds(4))
                index = (index + 1) % Self.scenes.count
            }
        }
    }
}
#endif
