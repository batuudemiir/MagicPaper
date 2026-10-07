import SwiftUI

/// 21 · Masal yazılıyor (`Uretim`) ve bitmiş durumu (`state-Uretim-bitti`).
///
/// Çevrimdışı motor masalı milisaniyede kurar; burada beklenen bir iş yok.
/// Aşamalar kısa bir geçiş ritmiyle ilerler (Reduce Motion açıksa hepsi
/// birden tamamlanır) ve masal hazır olunca "Masalı oku" görünür. Aşama
/// adları motorun gerçekte yaptığı işlerdir: kahraman ve kadro bağlanır,
/// yer seçilir, sayfalar yazılır, doğrulayıcı çalışır.
struct StoryPreparationView: View {

    let childName: String
    let modeTitle: String?
    /// Kurulan masal; `nil` iken aşamalar sürer.
    let story: Story?
    let onRead: () -> Void
    let onCancel: () -> Void

    private static let stages: [(title: String, icon: String)] = [
        ("Kahraman hazırlanıyor", "person"),
        ("Dünya kuruluyor", "castle"),
        ("Masal yazılıyor", "pencil"),
        ("Güvenlik kontrolü", "checkmark.shield")
    ]

    @State private var completed = 0

    private var isDone: Bool { story != nil && completed >= Self.stages.count }
    private var progress: Double { Double(completed) / Double(Self.stages.count) }

    private var subtitle: String {
        var parts = [childName]
        if let modeTitle { parts.append(modeTitle) }
        if let story { parts.append("\(story.pages.count) sayfa") }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer(minLength: MPSpacing.lg)

            VStack(spacing: MPSpacing.sm) {
                MascotImage(mascot: .pencil, width: 120)
                Text("Masal yazılıyor").mpText(.title1).foregroundStyle(MPColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle).mpText(.body).foregroundStyle(MPColor.textSecondary)
            }

            StoryProgressRing(progress: progress)

            VStack(spacing: MPSpacing.xs) {
                ForEach(Array(Self.stages.enumerated()), id: \.offset) { index, stage in
                    StageRow(title: stage.title, systemImage: stage.icon,
                             state: index < completed ? .done : (index == completed ? .active : .todo))
                }
            }

            Spacer(minLength: MPSpacing.lg)

            if isDone {
                MPButton(title: "Masalı oku", systemImage: "book", fullWidth: true, action: onRead)
                    .padding(.horizontal, MPSpacing.xxxl)
                    .transition(.opacity)
            } else {
                MPButton(title: "Vazgeç", kind: .ghost, action: onCancel)
            }
        }
        .padding(.horizontal, MPSpacing.screenH + MPSpacing.lg)
        .padding(.bottom, MPSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(MP.M.gated(MP.M.base), value: completed)
        .animation(MP.M.gated(MP.M.base), value: isDone)
        .onChange(of: isDone) { _, done in if done { MPHaptics.success() } }
        .task {
            guard !UIAccessibility.isReduceMotionEnabled else {
                completed = Self.stages.count
                return
            }
            for step in 1...Self.stages.count {
                try? await Task.sleep(nanoseconds: 380_000_000)
                completed = step
            }
        }
    }
}

#Preview("21 · Masal yazılıyor") {
    StoryPreparationView(childName: "İrem", modeTitle: "Uyku öncesi", story: nil, onRead: {}, onCancel: {})
        .background(MPColor.backgroundKid)
}
