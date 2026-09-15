import SwiftUI

// MARK: - Enums for V1 Story Experience



enum V1StoryWorld: String, CaseIterable, Identifiable {
    case orman = "Ormanda"
    case dag = "Dağlarda"
    case deniz = "Denizin altında"
    case ada = "Gizli bir adada"
    case gokyuzu = "Bulutların arasında"
    case gece = "Gece gökyüzünde"
    case surpriz = "Bana sürpriz yap"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .orman: return "tree"
        case .dag: return "mountain"
        case .deniz: return "fish"
        case .ada: return "sailboat"
        case .gokyuzu: return "cloud"
        case .gece: return "moon"
        case .surpriz: return "wand.and.stars"
        }
    }
    
    var mpWorld: MP.World {
        switch self {
        case .orman: return .orman
        case .dag: return .dinozor
        case .deniz: return .deniz
        case .ada: return .korsan
        case .gokyuzu: return .uzay
        case .gece: return .krallik
        case .surpriz: return MP.World.ordered.randomElement() ?? .krallik
        }
    }
}

enum V1StoryCompanion: String, CaseIterable, Identifiable {
    case tilki = "Tilki"
    case tavsan = "Tavşan"
    case baykus = "Baykuş"
    case ejderha = "Küçük Ejderha"
    case ayicik = "Ayıcık"
    case surpriz = "Bana sürpriz yap"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .tilki, .tavsan, .ayicik: return "pawprint"
        case .baykus: return "bird"
        case .ejderha: return "flame.fill"
        case .surpriz: return "wand.and.stars"
        }
    }
}

/// Masal sihirbazı — 03-SCREENS.md §4 ve üretim ekranı §5.
/// V1 UX - Story Engine Integration
struct StoryWizardView: View {
    let preset: MPWizardPreset

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var step = 0
    @State private var childID: UUID?
    
    @State private var storyWorld: V1StoryWorld?
    @State private var storyCompanion: V1StoryCompanion?
    
    @State private var isGenerating = false
    @State private var pendingStoryID: UUID?

    var body: some View {
        Group {
            if isGenerating {
                StoryGeneratingView(
                    world: storyWorld?.mpWorld ?? .krallik,
                    storyID: pendingStoryID,
                    onCancel: { isGenerating = false; dismiss() },
                    onFinished: { story in
                        dismiss()
                        app.showToast("1 yıldız harcandı", symbol: "star.fill", tone: .reward)
                        app.readerStory = story
                    }
                )
            } else {
                wizard
            }
        }
        .mpScreenBackground()
        .onAppear(perform: applyPreset)
    }

    private func applyPreset() {
        if childID == nil { childID = profileManager.currentProfile?.id }
        step = preset.startStep
        // In V1, preset.world isn't directly mapped, but we start where needed.
    }

    // MARK: - Sihirbaz gövdesi

    private var wizard: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    titleBlock
                    stepContent
                }
                .mpGutter()
                .padding(.bottom, MP.S.x6)
            }
            footer
        }
    }

    private var topBar: some View {
        HStack {
            MPIconButton(
                symbol: step == 0 ? "xmark" : "chevron.left",
                label: step == 0 ? "Kapat" : "Geri"
            ) {
                if step == 0 { dismiss() } else { withAnimation(MP.M.gated(MP.M.easeOut)) { step -= 1 } }
            }
            Spacer(minLength: 0)
            MPStepDots(total: 2, current: step, labels: ["Kim", "Dünya"])
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
        .mpGutter()
        .padding(.top, MP.S.x1)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: MP.S.x2) {
            Text(stepTitle)
                .font(MP.F.displayLG())
                .mpTightTracking(32)
                .foregroundStyle(MP.C.textTitle)
            if !stepSubtitle.isEmpty {
                Text(stepSubtitle)
                    .font(MP.F.bodyMD())
                    .foregroundStyle(MP.C.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, MP.S.x3)
        .padding(.bottom, MP.S.x5)
    }

    private var stepTitle: String {
        step == 0 ? "Kimin için?" : "Hikâyemiz nerede geçsin?"
    }

    private var stepSubtitle: String {
        step == 0 ? "Masalın kahramanı kim olsun?" : ""
    }

    @ViewBuilder
    private var stepContent: some View {
        if step == 0 { whoStep } else { worldCompanionStep }
    }

    // MARK: - Adım 0 — Kim?

    private var whoStep: some View {
        VStack(spacing: MP.S.stackGap) {
            ForEach(profileManager.profiles) { profile in
                MPChoiceTile(
                    title: profile.name,
                    description: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(for: profile)) masal",
                    symbol: "person.crop.circle",
                    accent: profile.mpColor,
                    isSelected: childID == profile.id
                ) {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { 
                        childID = profile.id 
                        step += 1 // Auto advance
                    }
                }
            }

            MPChoiceTile(
                title: "Yeni profil ekle",
                description: "Başka bir çocuk için masal yaz",
                symbol: "plus",
                accent: MP.C.textMuted
            ) {
                app.showProfileAdd = true
            }
        }
    }

    private func storyCount(for profile: UserProfile) -> Int {
        storyManager.stories.filter { $0.belongs(to: profile) }.count
    }

    // MARK: - Adım 1 — Dünya ve arkadaş

    private var worldCompanionStep: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            
            // World selection
            VStack(alignment: .leading, spacing: MP.S.stackGap) {
                MPWrapRow(spacing: MP.S.stackGap) {
                    ForEach(V1StoryWorld.allCases) { w in
                        MPChip(title: w.rawValue, symbol: w.symbol, isSelected: storyWorld == w) {
                            withAnimation(MP.M.gated(MP.M.easeOut)) { storyWorld = w }
                        }
                    }
                }
            }
            
            // Companion selection
            VStack(alignment: .leading, spacing: MP.S.stackGap) {
                MPSectionHeader(title: "Yanında kim olsun?")
                    
                MPWrapRow(spacing: MP.S.stackGap) {
                    ForEach(V1StoryCompanion.allCases) { c in
                        MPChip(title: c.rawValue, symbol: c.symbol, isSelected: storyCompanion == c) {
                            withAnimation(MP.M.gated(MP.M.easeOut)) { storyCompanion = c }
                        }
                    }
                }
            }
            
            // Selected Summary
            if let world = storyWorld, let comp = storyCompanion {
                MPCard(tone: .sunken, padding: MP.S.x4) {
                    HStack(spacing: MP.S.stackGap) {
                        MPAvatar(name: selectedChildName, color: selectedProfile?.mpColor, size: 38)
                        VStack(alignment: .leading, spacing: MP.S.x1) {
                            Text("\(selectedChildName) için macera hazır!")
                                .font(MP.F.bodyMD(.bold))
                                .foregroundStyle(MP.C.textTitle)
                            Text("\(world.rawValue) · \(comp.rawValue)")
                                .font(MP.F.labelSM())
                                .foregroundStyle(MP.C.textMuted)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var selectedProfile: UserProfile? {
        profileManager.profiles.first { $0.id == childID }
    }

    private var selectedChildName: String {
        selectedProfile?.name ?? "Çocuk"
    }

    // MARK: - Alt alan

    private var stars: Int {
        subscriptionManager.isPremium
            ? subscriptionManager.remainingImageStories
            : subscriptionManager.freeTrialCount
    }

    private var canAdvance: Bool {
        step == 0 ? childID != nil : (storyWorld != nil && storyCompanion != nil)
    }

    private var footer: some View {
        VStack(spacing: MP.S.stackGap) {
            if step == 1 {
                HStack(spacing: MP.S.x2) {
                    MPIcon("star.fill", size: 13, weight: .bold)
                        .foregroundStyle(stars > 0 ? MP.C.reward : MP.C.danger)
                    Text(stars > 0
                         ? "1 yıldız harcanacak · \(stars) yıldızın var"
                         : "Yıldızın kalmadı")
                        .font(MP.F.labelSM())
                        .foregroundStyle(stars > 0 ? MP.C.textMuted : MP.C.danger)
                }
            }

            if step < 1 {
                MPButton(
                    title: "Devam et",
                    size: .lg,
                    fullWidth: true,
                    isDisabled: !canAdvance
                ) {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { step += 1 }
                }
            } else {
                MPButton(
                    title: "Görselli masal",
                    size: .lg,
                    icon: "wand.and.stars",
                    fullWidth: true,
                    isDisabled: !canAdvance
                ) {
                    createStory()
                }
            }
        }
        .mpGutter()
        .padding(.top, MP.S.x2)
        .padding(.bottom, MP.S.x3)
        .background(MP.C.surfaceApp)
    }

    // MARK: - Masalı oluştur

    private func createStory() {
        guard stars > 0 else {
            app.openPaywall()
            return
        }
        guard let profile = selectedProfile, let world = storyWorld else { return }

        guard subscriptionManager.useStory(type: .image) else {
            app.openPaywall()
            return
        }

        let reference = MPAvatarRenderer.image(
            letter: String(profile.name.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
            color: UIColor(profile.mpColor)
        )

        isGenerating = true

        let selectedPageCount = MPStoryLength.orta.pageCount
        let selectedTone = MPStoryTone.neseli.title

        Task {
            pendingStoryID = await storyManager.createCustomStory(
                childName: profile.name,
                childProfileID: profile.id,
                age: profile.age,
                gender: .other,
                theme: world.mpWorld.storyTheme,
                language: .turkish,
                image: reference,
                customTitle: nil,
                pageCount: selectedPageCount,
                tone: selectedTone
            )
        }
    }
    
}

// MARK: - Satır sarmalayıcı

struct MPWrapRow<Content: View>: View {
    var spacing: CGFloat = MP.S.stackGap
    @ViewBuilder var content: () -> Content

    var body: some View {
        MPFlowLayout(spacing: spacing) {
            content()
        }
    }
}

struct MPFlowLayout: Layout {
    var spacing: CGFloat = MP.S.stackGap

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = layout(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(0) { $0 + $1.height } +
                     spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let rows = layout(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Avatar → UIImage

enum MPAvatarRenderer {
    static func image(letter: String, color: UIColor, side: CGFloat = 512) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: side * 0.44, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let text = letter as NSString
            let size = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2),
                withAttributes: attrs
            )
        }
    }
}
