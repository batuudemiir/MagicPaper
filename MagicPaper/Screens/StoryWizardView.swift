import SwiftUI

/// Masal sihirbazı — 03-SCREENS.md §4 ve üretim ekranı §5.
/// Üç tam ekran adım, her adımda tek soru. Sistemde dropdown/picker yoktur.
struct StoryWizardView: View {
    let preset: MPWizardPreset

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var storyManager = StoryGenerationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var step = 0
    @State private var childID: UUID?
    @State private var world: MP.World?
    @State private var length: MPStoryLength = .orta
    @State private var tone: MPStoryTone = .neseli
    @State private var isGenerating = false
    @State private var pendingStoryID: UUID?

    var body: some View {
        Group {
            if isGenerating {
                StoryGeneratingView(
                    world: world ?? .krallik,
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
        if let w = preset.world { world = w }
        step = preset.startStep
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
                .padding(.horizontal, MP.S.screenGutter)
                .padding(.bottom, 24)
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
            MPStepDots(total: 3, current: step, labels: ["Kim", "Nerede", "Nasıl"])
            Spacer(minLength: 0)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, 4)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stepTitle)
                .font(MP.F.displayLG())
                .mpTightTracking(32)
                .foregroundStyle(MP.C.textTitle)
            Text(stepSubtitle)
                .font(MP.F.bodyMD())
                .foregroundStyle(MP.C.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Kim için?"
        case 1: return "Nerede geçiyor?"
        default: return "Nasıl bir masal?"
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 0: return "Masalın kahramanı kim olsun?"
        case 1: return "Macera hangi dünyada geçsin?"
        default: return "Uzunluğu ve tonu seç, hemen yazalım."
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: whoStep
        case 1: whereStep
        default: howStep
        }
    }

    // MARK: - Adım 0 — Kim?

    private var whoStep: some View {
        VStack(spacing: 12) {
            ForEach(profileManager.profiles) { profile in
                MPChoiceTile(
                    title: profile.name,
                    description: "\(profile.mpAgeRange.shortLabel) yaş · \(storyCount(for: profile)) masal",
                    symbol: "person.crop.circle",
                    accent: profile.mpColor,
                    isSelected: childID == profile.id
                ) {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { childID = profile.id }
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
        storyManager.stories.filter { $0.childName == profile.name }.count
    }

    // MARK: - Adım 1 — Nerede?

    private var whereStep: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(MP.World.ordered) { w in
                let locked = w.isPremium && !subscriptionManager.isPremium
                MPChoiceTile(
                    title: w.name,
                    symbol: w.symbol,
                    accent: w.accent,
                    isSelected: world == w,
                    isLocked: locked,
                    layout: .column
                ) {
                    if locked {
                        app.openPaywall()
                    } else {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { world = w }
                    }
                }
            }
        }
    }

    // MARK: - Adım 2 — Nasıl?

    private var howStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            MPCard(tone: .sunken, padding: 14) {
                HStack(spacing: 12) {
                    MPAvatar(name: selectedChildName, color: selectedProfile?.mpColor, size: 38)
                    Text("\(selectedChildName) · \(world?.name ?? "Dünya seçilmedi")")
                        .font(MP.F.bodyMD(.bold))
                        .foregroundStyle(MP.C.textTitle)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    MPButton(title: "Değiştir", variant: .ghost, size: .sm) {
                        withAnimation(MP.M.gated(MP.M.easeOut)) { step = 0 }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Uzunluk")
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textTitle)

                ForEach(MPStoryLength.allCases) { option in
                    let locked = option.isPremium && !subscriptionManager.isPremium
                    MPChoiceTile(
                        title: option.title,
                        description: option.detail,
                        symbol: option.symbol,
                        isSelected: length == option,
                        isLocked: locked
                    ) {
                        if locked {
                            app.openPaywall()
                        } else {
                            withAnimation(MP.M.gated(MP.M.easeOut)) { length = option }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Ton")
                    .font(MP.F.labelMD())
                    .foregroundStyle(MP.C.textTitle)

                MPWrapRow(spacing: 10) {
                    ForEach(MPStoryTone.allCases) { t in
                        MPChip(title: t.title, isSelected: tone == t) {
                            withAnimation(MP.M.gated(MP.M.easeOut)) { tone = t }
                        }
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
        switch step {
        case 0: return childID != nil
        case 1: return world != nil
        default: return true
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            if step == 2 {
                HStack(spacing: 6) {
                    MPIcon("star.fill", size: 13, weight: .bold)
                        .foregroundStyle(stars > 0 ? MP.C.reward : MP.C.danger)
                    Text(stars > 0
                         ? "1 yıldız harcanacak · \(stars) yıldızın var"
                         : "Yıldızın kalmadı")
                        .font(MP.F.labelSM())
                        .foregroundStyle(stars > 0 ? MP.C.textMuted : MP.C.danger)
                }
            }

            MPButton(
                title: step < 2 ? "Devam et" : "Masalı oluştur",
                size: .lg,
                icon: step == 2 ? "wand.and.stars" : nil,
                fullWidth: true,
                isDisabled: !canAdvance
            ) {
                if step < 2 {
                    withAnimation(MP.M.gated(MP.M.easeOut)) { step += 1 }
                } else {
                    createStory()
                }
            }
        }
        .padding(.horizontal, MP.S.screenGutter)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(MP.C.surfaceApp)
    }

    // MARK: - Masalı oluştur

    private func createStory() {
        // Yıldız yoksa masal oluşturulmaz, paywall açılır (akış 2).
        guard stars > 0 else {
            app.openPaywall()
            return
        }
        guard let profile = selectedProfile, let world else { return }

        // Kotayı gerçekten düş. Eskiden dönüş değeri yok sayılıyordu; ücretsiz
        // kullanıcı tek görselli hakkını kullandıktan sonra da masal üretiliyor,
        // yıldız sayacı ile gerçek kilit birbirini tutmuyordu.
        guard subscriptionManager.useStory(type: .image) else {
            app.openPaywall()
            return
        }

        // Tasarım gereği çocuk fotoğrafı toplanmaz; üretim hattına referans
        // görsel olarak harf madalyonu gönderilir.
        let reference = MPAvatarRenderer.image(
            letter: String(profile.name.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
            color: UIColor(profile.mpColor)
        )

        isGenerating = true

        // Sihirbazın üçüncü adımındaki iki cevap da üretime gider:
        // uzunluk sayfa sayısına, ton da yazım yönergesine dönüşür.
        let selectedPageCount = length.pageCount
        let selectedTone = tone.title

        Task {
            pendingStoryID = await storyManager.createCustomStory(
                childName: profile.name,
                age: profile.age,
                gender: .other,
                theme: world.storyTheme,
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
//
// Chip şeritleri satıra sığmadığında alt satıra taşar (prototipte "Ton"
// chip'leri ikinci satıra kayıyor). Düz bir HStack burada chip'leri sıkıştırıp
// etiketleri iki satıra bölüyordu.

struct MPWrapRow<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: () -> Content

    var body: some View {
        MPFlowLayout(spacing: spacing) {
            content()
        }
    }
}

/// Satıra sığmayanı alta indiren basit akış yerleşimi.
struct MPFlowLayout: Layout {
    var spacing: CGFloat = 10

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

/// Harf madalyonunu üretim hattının beklediği referans görsele çevirir.
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
