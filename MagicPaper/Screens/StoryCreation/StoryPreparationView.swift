import SwiftUI

/// 21 · Masal yazılıyor (`Uretim`) ve bitmiş durumu (`state-Uretim-bitti`):
/// masal atölyesi (`docs/MASAL_ATOLYESI_PLANI.md`, karar 16 Ekim 2026).
///
/// Çevrimdışı motor masalı milisaniyede kurar. Ekran bu işi saklamaz,
/// gösterir: kadro sayfaya girer, mod masala dokunur, masalın gerçek ilk
/// cümlesi mürekkeple yazılır, Ragi masalı bir kez daha okur, kapak gelir.
/// Sıra, metin ve süre `StoryPreparationScript`'ten; bu görünüm yalnızca oynatır.
///
/// İlk masalda ritüelin tamamı (~10 sn), sonra kısalır ve "Hemen aç" ile
/// atlanabilir. Reduce Motion açıkken adımlar aynı sırayla, hareket yerine
/// çapraz geçişle gelir.
struct StoryPreparationView: View {

    let childName: String
    let modeTitle: String?
    /// Kurulan masal; `nil` iken defter açık bekler.
    let story: Story?
    /// Masal kurulunca akışın topladığı gerçekler; `nil` iken defter bekler.
    var facts: PreparationFacts? = nil
    var childColor: Color? = nil
    let onRead: () -> Void
    let onCancel: () -> Void
    /// 10 · İlk masal: "Elif'in ilk masalı yazılıyor", "Sonra oku".
    var title: String = "Masal yazılıyor"
    var cancelTitle: String = "Vazgeç"
    /// "Masalları onayla" açıksa masal hazır olunca okunmaz: ebeveyn
    /// bölümünden onaylanması gerektiği söylenir (karar 8 Ekim 2026).
    var awaitsApproval: Bool = false

    @State private var index = 0
    @State private var skipped = false
    @State private var showsSkip = false
    /// Ragi'nin nefesi; yalnızca Reduce Motion kapalıyken.
    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var steps: [StoryPreparationScript.Step] {
        facts.map(StoryPreparationScript.steps(for:)) ?? []
    }

    private var step: StoryPreparationScript.Step? {
        steps.indices.contains(index) ? steps[index] : nil
    }

    private var beat: StoryPreparationScript.Beat { step?.beat ?? .openBook }

    /// Masal var ve kapağa gelindi. Gerçekleri olmayan bir masal (olmaması
    /// gerekir) beklemeden kapağa geçer.
    private var isDone: Bool {
        guard story != nil else { return false }
        return facts == nil || beat == .bind
    }

    /// Masal gelmeden önceki satır: yalnızca çocuğun adını bilir.
    private var waitingLine: String {
        "Ragi, \(SeriesCopy.genitive(childName)) masal defterini açıyor."
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: MP.S.x5) {
                    Spacer(minLength: MP.S.x3)

                    Text(isDone ? (steps.last?.line ?? "Masal hazır.") : title)
                        .mpText(.title1).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .contentTransition(.opacity)

                    stage

                    if !isDone {
                        Text(step?.line ?? waitingLine)
                            .mpText(.bodyStrong).foregroundStyle(MPColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(index)
                            .transition(.opacity)
                            .accessibilityHidden(true)

                        StepDots(count: max(steps.count - 1, 1), current: min(index, max(steps.count - 2, 0)))
                    }

                    Spacer(minLength: MP.S.x5)

                    actions
                }
                .padding(.horizontal, MPSpacing.screenH + MPSpacing.lg)
                .padding(.bottom, MPSpacing.lg)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .animation(MP.M.base, value: index)
        .animation(MP.M.base, value: isDone)
        .animation(MP.M.base, value: showsSkip)
        .onChange(of: isDone) { _, done in
            guard done else { return }
            MPHaptics.success()
            AccessibilityNotification.Announcement(awaitsApproval ? "Masal hazır, onay bekliyor." : "Masal hazır.").post()
        }
        .onAppear {
            AccessibilityNotification.Announcement(title).post()
        }
        .task(id: facts) { await play() }
        .task(id: facts?.storyOrdinal) {
            guard let facts, let delay = StoryPreparationScript.skipDelay(for: facts) else { return }
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled && !isDone { showsSkip = true }
        }
    }

    // MARK: - Sahne

    /// Defter; kapağa gelince masalın kendi kapağı. Ragi defterin üstünde,
    /// yazarken kalemiyle, okurken kitabıyla.
    @ViewBuilder
    private var stage: some View {
        if isDone, let story {
            StoryCover(story: story, childName: childName)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .frame(maxHeight: 420)
                .clipShape(RoundedRectangle(cornerRadius: MP.R.card, style: .continuous))
                .mpShadow(MP.Sh.lifted)
                .transition(.opacity)
        } else {
            VStack(spacing: MP.S.x3) {
                MascotImage(mascot: beat == .reread ? .reading : .pencil, width: 80)
                    .offset(y: breathing ? -MP.S.x1 : 0)
                    .animation(reduceMotion ? nil : MP.M.idle, value: breathing)
                    .onAppear { if !reduceMotion { breathing = true } }
                    .contentTransition(.opacity)
                PreparationNotebook(
                    facts: facts,
                    beat: beat,
                    beats: steps.map(\.beat),
                    childColor: childColor,
                    inkDuration: min(MP.M.inkDuration, (step?.hold ?? MP.M.inkDuration) * 0.85)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step?.line ?? waitingLine)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Eylemler

    @ViewBuilder
    private var actions: some View {
        if isDone && awaitsApproval {
            VStack(spacing: MPSpacing.md) {
                HStack(alignment: .top, spacing: MPSpacing.sm) {
                    MPIcon("lock", size: MP.G.md, weight: .semibold)
                        .foregroundStyle(MPColor.actionPrimary)
                        .accessibilityHidden(true)
                    Text("Masal hazır. Okumadan önce bir büyüğün Ebeveyn bölümünden onaylaması gerekiyor.")
                        .mpText(.bodyStrong)
                        .foregroundStyle(MPColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(MPSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MPColor.actionSoft, in: RoundedRectangle(cornerRadius: MPRadius.card, style: .continuous))
                .accessibilityElement(children: .combine)
                MPButton(title: "Tamam", fullWidth: true, action: onCancel)
                    .padding(.horizontal, MPSpacing.xxxl)
            }
            .transition(.opacity)
        } else if isDone {
            MPButton(title: "Masalı oku", systemImage: "book", fullWidth: true, action: onRead)
                .padding(.horizontal, MPSpacing.xxxl)
                .transition(.opacity)
        } else {
            HStack(spacing: MPSpacing.md) {
                MPButton(title: cancelTitle, kind: .ghost, action: onCancel)
                if showsSkip {
                    MPButton(title: "Hemen aç", kind: .ghost, action: skip)
                        .accessibilityHint("Masalın yazılmasını beklemeden açar")
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Oynatma

    private func play() async {
        guard facts != nil else { return }
        let steps = self.steps
        skipped = false
        for i in steps.indices {
            if skipped || Task.isCancelled { break }
            index = i
            let hold = steps[i].hold
            if hold > 0 { try? await Task.sleep(for: .seconds(hold)) }
        }
        if !Task.isCancelled { index = max(steps.count - 1, 0) }
    }

    /// Kalan adımlar tek geçişle tamamlanır; liste atlanmaz, yalnızca hızlanır.
    private func skip() {
        skipped = true
        showsSkip = false
        index = max(steps.count - 1, 0)
    }
}

/// Sakin ilerleme: kaç adım olduğunu ve nerede olunduğunu gösterir, ne yüzde
/// ne süre söyler. Bilgi ayrıca durum cümlesinde; noktalar süs.
private struct StepDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: MP.S.x2) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? MP.C.brand : MP.C.borderHairline)
                    .frame(width: i == current ? MP.S.x5 : MP.S.x2, height: MP.S.x2)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("21 · Masal yazılıyor") {
    StoryPreparationView(
        childName: "Ela", modeTitle: "Uyku öncesi", story: nil,
        facts: PreparationFacts(childName: "Ela", companion: .init(name: "Tarçın", kind: "tilki"),
                                familyName: "Mia", mode: .bedtime, hasNewWord: false,
                                firstSentence: "Ela, ay ışığının pencereden süzüldüğünü gördü.",
                                pageCount: 8, storyOrdinal: 1, isFirstRun: false, isBedtime: false),
        onRead: {}, onCancel: {})
        .background(MPColor.backgroundKid)
}
