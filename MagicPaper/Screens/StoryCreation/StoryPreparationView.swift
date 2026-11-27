import SwiftUI

/// 21 · Masal yazılıyor (`Uretim`) ve bitmiş durumu (`state-Uretim-bitti`):
/// masal atölyesi (`docs/MASAL_ATOLYESI_PLANI.md`, karar 16 Ekim 2026).
///
/// Çevrimdışı motor masalı milisaniyede kurar. Ekran bu işi saklamaz,
/// gösterir: kadro sayfaya girer, mod masala dokunur, masalın gerçek ilk
/// cümlesi mürekkeple yazılır, Ragi masalı bir kez daha okur, kapak gelir.
/// Sıra, metin ve süre `StoryPreparationScript`'ten; bu görünüm yalnızca oynatır.
///
/// Ritüel 6-8 sn, her masalda "Masalı aç" ile atlanabilir (karar 7 Kasım 2026).
/// Kapak kısa görünür, sonra masal kendiliğinden açılır; "Sonra oku" kitaplıkta
/// bırakır. VoiceOver açıkken kendiliğinden açılmaz: duyuruyu kesmesin.
/// Reduce Motion açıkken adımlar aynı sırayla, hareket yerine çapraz geçişle gelir.
///
/// Hareketli sahne (26 Kasım 2026, Batuhan): arkada moda göre süzülen kâğıt
/// yıldızlar, açılan defter kapağı, her adımda çevrilen sayfa, ilerleyen yıldız
/// yolu ve dönerek gelen kapak (`PreparationMotion.swift`).
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

    /// Kapağın ölçüsü: 2:3, en küçük iPhone'a da sığar.
    private static let coverSize = CGSize(width: 260, height: 390)

    @State private var index = 0
    @State private var skipped = false
    @State private var showsSkip = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

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
        ZStack {
            PreparationSky(mode: facts?.mode, isBedtime: facts?.isBedtime ?? false)
                .ignoresSafeArea()
            page
        }
        .animation(MP.M.base, value: index)
        .animation(MP.M.gated(MP.M.page) ?? MP.M.base, value: isDone)
        .animation(MP.M.base, value: showsSkip)
        .onChange(of: isDone) { _, done in
            guard done else { return }
            MPHaptics.success()
            AccessibilityNotification.Announcement("Masal hazır.").post()
        }
        .onAppear {
            AccessibilityNotification.Announcement(title).post()
        }
        .task(id: facts) { await play() }
        .task(id: facts?.storyOrdinal) {
            guard let facts else { return }
            try? await Task.sleep(for: .seconds(StoryPreparationScript.skipDelay(for: facts)))
            if !Task.isCancelled && !isDone { showsSkip = true }
        }
        .task(id: isDone) {
            guard isDone else { return }
            MPSound.play(.ready)
            guard !voiceOver else { return }
            try? await Task.sleep(for: .seconds(StoryPreparationScript.coverHold))
            if !Task.isCancelled { onRead() }
        }
    }

    private var page: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: MP.S.x5) {
                    Spacer(minLength: MP.S.x3)

                    Text(isDone ? (steps.last?.line ?? "Masal hazır.") : title)
                        .mpText(.page).foregroundStyle(MPColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .contentTransition(.opacity)

                    stage

                    if !isDone {
                        Text(step?.line ?? waitingLine)
                            .mpText(.cardTitle).foregroundStyle(MPColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(index)
                            .transition(.opacity)
                            .accessibilityHidden(true)

                        StarPath(count: max(steps.count - 1, 1), current: min(index, max(steps.count - 2, 0)))
                            .frame(maxWidth: MPSize.minTouchHero * 3)
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
    }

    // MARK: - Sahne

    /// Defter; kapağa gelince masalın kendi kapağı. Ragi defterin üstünde,
    /// yazarken kalemiyle, okurken kitabıyla.
    @ViewBuilder
    private var stage: some View {
        if isDone, let story {
            // Kapak ortada, sabit ölçüde (27 Kasım 2026, Batuhan: kapak
            // ortalanmıyordu). Kâğıt yıldızlar yerleşimi etkilemesin diye arkada.
            StoryCover(story: story, childName: childName)
                .frame(width: Self.coverSize.width, height: Self.coverSize.height)
                .clipShape(RoundedRectangle(cornerRadius: MP.R.card, style: .continuous))
                .mpShadow(MP.Sh.lifted)
                .background {
                    // Gündüz bir kez kâğıt yıldız; uyku vaktinde ve Hareketi Azalt'ta yok.
                    if !reduceMotion && !(facts?.isBedtime ?? false) {
                        PaperBurst()
                            .frame(width: Self.coverSize.width * 2, height: Self.coverSize.height * 1.4)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .transition(.coverFlip(reduceMotion: reduceMotion))
        } else {
            VStack(spacing: MP.S.x3) {
                MascotImage(mascot: beat == .reread ? .reading : .pencil, width: 80)
                    .contentTransition(.opacity)
                PreparationNotebook(
                    facts: facts,
                    beat: beat,
                    beats: steps.map(\.beat),
                    childColor: childColor,
                    inkDuration: min(MP.M.inkDuration, (step?.hold ?? MP.M.inkDuration) * 0.85)
                )
                .modifier(PageTurn(trigger: index))
                .modifier(NotebookCoverOpening(tone: facts?.mode?.tone ?? .lav,
                                               symbol: facts?.mode?.symbol ?? "book.closed"))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step?.line ?? waitingLine)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Eylemler

    @ViewBuilder
    private var actions: some View {
        if isDone {
            VStack(spacing: MPSpacing.xxs) {
                MPButton(title: "Masalı oku", systemImage: "book", fullWidth: true, action: onRead)
                MPButton(title: "Sonra oku", kind: .ghost, action: onCancel)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .transition(.opacity)
        } else {
            HStack(spacing: MPSpacing.md) {
                MPButton(title: cancelTitle, kind: .ghost, action: onCancel)
                if showsSkip {
                    MPButton(title: "Masalı aç", kind: .ghost, action: skip)
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
        if story != nil { onRead() }
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
