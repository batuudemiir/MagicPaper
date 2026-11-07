import SwiftUI
import StoryEngine
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.magicpaper.kids", category: "StoryCreation")

/// The story creation experience: an intent, then a story.
///
/// Replaces the four-step wizard, which asked for a child, a type, a direction,
/// a world, a companion, and finally whether the story should be illustrated —
/// six decisions that made the product feel like a form.
///
/// The one required decision is the **mode** — Uyku öncesi, Yeni şeyler
/// öğrenelim, Maceraya çıkalım — tapped once, no "Devam et". Then "Masalda kimler
/// olsun?". "Bana sürpriz yap" skips that step and writes the story: that is what
/// a surprise means (karar 7 Kasım 2026).
///
/// Fikir kartları adımı ("Bir gizemin peşine düşelim", "Bana bırak") 21 Ekim
/// 2026'da kaldırıldı. Bayrağın arkasında uyuyordu ve bayrak bir cihazda
/// açık kaldığı için üründen çıkmış sayılan bir ekran telefonda görünüyordu:
/// kapalı bir özellik, silinmiş bir özellik değildir. Motorun fikir yapısı
/// (`CatalogStoryIdea`, `origin.storyIdeaID`) yerinde kaldı — kaydedilmiş
/// masallar onu saklıyor ve temizliği ayrı bir iş.
///
/// A mode chosen on the home screen opens the flow at its second step: the
/// parent has already made the first decision there. "Back" then returns to
/// the modes, so it is never a dead end. The decisions themselves live in
/// `StoryCreationSteps`.
///
/// The child is not a step: the app already has a current profile, and a home
/// with two children changes it in one line (`CreationChildPicker`).
struct StoryCreationFlow: View {

    /// Where the flow is. Linear on purpose — one decision per screen, which is
    /// also what makes it usable by a child later (§27).
    private enum Phase: Equatable {
        /// "Masal kimin için?": yalnızca açıklama ekranından "başka bir çocuk seç".
        case child
        /// Bu çocuğun yaşı için masal yazılmamış (C turu, 21 Ekim 2026).
        ///
        /// Akışın sonu değil bir dalı: desteklenen başka bir çocuk varsa
        /// oraya dönülebiliyor.
        case unsupportedAge
        case mode
        case companion
        /// 21 · Masal yazılıyor; masal hazır olunca aynı ekranda "Masalı oku".
        case preparing
        /// Okuyucu akışın *içinde* açılır.
        ///
        /// Eskiden kapak `app.readerStory`'yi kurup kendi tam ekran sunumunu
        /// kapatıyordu, `ContentView` de ikinci bir tam ekran sunum açıyordu.
        /// Üst üste geçen iki tam ekran sunum, içlerinde ne animasyonlanırsa
        /// animasyonlansın, kitabın açılması gibi hissettirilemez. Aynı görünüm
        /// ağacında olunca kâğıt kesintisiz kalabiliyor (§13).
        case reading(Story)
        case failed
    }

    @EnvironmentObject private var app: MPAppState
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storyManager = StoryGenerationManager.shared

    @State private var phase: Phase
    /// The story built during `.preparing`, read once "Masalı oku" is tapped.
    @State private var preparedStory: Story?
    /// What the masal atölyesi shows about `preparedStory`.
    @State private var preparationFacts: PreparationFacts?
    /// Why the last attempt failed (43 shows a calmer sentence for safety).
    @State private var failureReason: StoryFailureReason?
    /// Always one of the three modes once past step 1 — a surprise is resolved
    /// the moment it is chosen, so the companion step can already fit it.
    @State private var chosenMode: StoryMode?
    @State private var strategy: StorySelectionStrategy = .direct
    @State private var chosenCompanionID: String?
    /// Alt kategori (`CatalogStoryTopic` kimliği); nil "farketmez". "Kimler"
    /// adımında isteğe bağlı (karar: 7 Kasım 2026).
    @State private var chosenTopicID: String?
    /// Modun konuları, mod ya da çocuk değişince bir kez: katalogu tarar.
    @State private var topicChoices: [StoryTopicChoice] = []
    /// Bu masalın yazılacağı çocuk. Akışa özel: aktif profili değiştirmez.
    @State private var chosenProfileID: UUID?
    /// Masal ailem (FAZ 11). Chosen on the companion step, optional, one at
    /// most. A surprise picks the mode, never the cast: this survives it.
    @State private var chosenFamilyID: UUID?
    @State private var familyCharacters: [FamilyCharacter] = []
    @State private var showsFamilyEditor = false
    /// Relations the chosen mode can carry for this child, computed once per
    /// mode rather than on every redraw: it walks every blueprint.
    @State private var familyRelations: Set<FamilyRelationKind> = []

    /// Bu masalın çocuğu: akışta seçildiyse o, yoksa aktif profil.
    ///
    /// Akışın her yeri (yaş bandı, ad, Masal ailem, kaydetme) bunu okur; aktif
    /// profil hiç değişmez. Büyük kardeşe masal yazdırmak uygulamanın geri
    /// kalanını büyük kardeşe çevirmemeli.
    private var profile: UserProfile? {
        chosenProfileID.flatMap { id in profileManager.profiles.first { $0.id == id } }
            ?? profileManager.currentProfile
    }

    private var profiles: [UserProfile] { profileManager.profiles }

    /// - Parameter preset: a mode already chosen on the home screen.
    /// - Parameter family: a Masal ailem character chosen on 14.
    init(preset: StoryMode? = nil, family: UUID? = nil) {
        _chosenFamilyID = State(initialValue: family)
        let age = ProfileManager.shared.currentProfile?.age ?? AgeBandResolver.mvp.upperBound
        let available = StoryChoiceSources.current.availableModes(forAge: age)
        // Yaş kapısı moddan önce: desteklenmeyen bir bantta mod sormak,
        // cevabı hiçbir şeye yaramayacak bir soru sormaktır.
        let supported = StoryCreationSteps.supportsAge(
            age, authored: StoryChoiceSources.current.authoredBands())

        switch StoryCreationSteps.openingPhase(preset: preset, available: available) {
        case .mode:
            _phase = State(initialValue: supported ? .mode : .unsupportedAge)
            _chosenMode = State(initialValue: nil)
        case .companion(let mode):
            _phase = State(initialValue: supported ? .companion : .unsupportedAge)
            _chosenMode = State(initialValue: supported ? mode : nil)
        }
        _chosenProfileID = State(initialValue: ProfileManager.shared.currentProfile?.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsHeader { header }
            content
        }
        // Zemin ana sayfayla aynı düz beyaz (22 Ekim 2026).
        .background(MPColor.backgroundSurface.ignoresSafeArea())
        .animation(MP.M.gated(MP.M.page), value: phase)
        .overlay {
            if showsFamilyEditor, let profile {
                FamilyCharacterEditor(
                    childID: profile.id,
                    childName: profile.name,
                    source: source,
                    onClose: { showsFamilyEditor = false },
                    onSaved: { character in
                        reloadFamily()
                        // Just made for this story, so it comes along —
                        // unless this mode cannot carry its relation.
                        if familyRelations.contains(character.relation.kind) {
                            chosenFamilyID = character.id
                        }
                        showsFamilyEditor = false
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(MP.M.gated(MP.M.easeOut), value: showsFamilyEditor)
        .onAppear {
            reloadFamily()
            refreshFamilyRelations()
        }
        .onChange(of: chosenMode) { _, _ in refreshFamilyRelations() }
        .onChange(of: chosenProfileID) { _, _ in
            chosenFamilyID = nil
            reloadFamily()
            refreshFamilyRelations()
            if phase == .mode && !supportsChosenChild { phase = .unsupportedAge }
        }
    }

    /// A mode change can make the chosen character's relation unavailable.
    /// The selection is cleared then, visibly (the chip is no longer
    /// selected), rather than kept and dropped silently at "Başla".
    private func refreshFamilyRelations() {
        familyRelations = Set(source.availableFamilyRelations(mode: chosenMode, age: age))
        topicChoices = chosenMode.map { source.topicChoices(forAge: age, mode: $0) } ?? []
        if let character = familyCharacters.first(where: { $0.id == chosenFamilyID }),
           !familyRelations.contains(character.relation.kind) {
            chosenFamilyID = nil
        }
    }

    private func reloadFamily() {
        familyCharacters = profile.map { FamilyCharacterStore().characters(for: $0.id) } ?? []
        if let id = chosenFamilyID, !familyCharacters.contains(where: { $0.id == id }) {
            chosenFamilyID = nil
        }
    }

    /// Başlık yalnızca seçim adımlarında: okuyucu, masal yazılıyor ve hata
    /// ekranlarının kendi düzeni var.
    private var showsHeader: Bool {
        switch phase {
        case .child, .mode, .companion: return true
        // Açıklama ekranının kendi kapatma düğmesi var; adım noktaları ise
        // yanlış olurdu, çünkü bu bir adım değil, akışın durduğu yer.
        default: return false
        }
    }

    // MARK: - Chrome

    /// Solda geri/kapat, ortada ince ilerleme çizgisi (22 Ekim 2026). "Adım
    /// 2 / 3" yazısı kalktı; VoiceOver aynı cümleyi okumaya devam ediyor.
    private var header: some View {
        ZStack {
            if let step = stepIndex {
                HStack(spacing: MPSpacing.xs) {
                    ForEach(0..<stepLabels.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? MPColor.actionPrimary : MPColor.borderKid)
                            .frame(height: MPSpacing.xxs)
                    }
                }
                .frame(maxWidth: MPSize.minTouchKid * 3)
                .animation(MP.M.gated(MP.M.easeOut), value: step)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Adım \(step + 1) / \(stepLabels.count), \(stepLabels[step])")
            }
            HStack {
                MPCircleButton(systemImage: showsBack ? "chevron.left" : "xmark",
                               accessibilityLabel: showsBack ? "Geri" : "Kapat", action: goBack)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.sm)
        .padding(.bottom, MPSpacing.md)
    }

    private var showsBack: Bool {
        switch phase {
        case .companion: return true
        default: return false
        }
    }

    private var stepLabels: [String] { StoryCreationSteps.stepLabels }

    /// Nokta sırası etiket listesinden türetiliyor, elle sayılmıyor: iki yerde
    /// ayrı ayrı sayılsaydı bir adım eklendiğinde biri güncellenir öbürü
    /// unutulur ve "Adım 2 / 4" yanlış yazardı.
    private var stepIndex: Int? {
        switch phase {
        case .mode:      return stepLabels.firstIndex(of: "Masal")
        case .companion: return stepLabels.count - 1
        default:         return nil
        }
    }

    private func goBack() {
        switch phase {
        case .companion:
            chosenCompanionID = nil
            resetToModes()
        default:
            dismiss()
        }
    }

    private func resetToModes() {
        chosenMode = nil
        chosenTopicID = nil
        strategy = .direct
        phase = .mode
    }

    // MARK: - Phases

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .child:
            StoryChildStep(profiles: profiles, authoredBands: authoredBands,
                           selectedID: $chosenProfileID) {
                phase = supportsChosenChild ? .mode : .unsupportedAge
            }
        case .unsupportedAge:
            StoryUnsupportedAgeStep(
                childName: profile?.name ?? "",
                childAge: age,
                authoredBands: authoredBands,
                alternatives: supportedAlternatives,
                onPickAnother: { phase = .child },
                onClose: { dismiss() })
        case .mode:
            StoryModeStep(
                modes: allowedModes,
                emphasized: StoryCreationSteps.emphasizedMode(allowedModes,
                                                              isBedtime: MPBedtime.isBedtime(settings: MPSettingsStore.shared)),
                childName: profile?.name ?? "",
                profiles: profiles,
                authoredBands: authoredBands,
                selectedProfileID: $chosenProfileID,
                onChoose: chooseMode,
                onSurprise: surprise
            )
        case .companion:
            CompanionStep(
                ideaID: nil, mode: chosenMode, age: age, childName: profile?.name ?? "",
                childColor: profile?.mpColor, source: source,
                familyCharacters: familyCharacters,
                availableRelations: familyRelations,
                selectedFamilyID: $chosenFamilyID,
                // Free text is a parent's surface: in child mode the child
                // picks from the characters the parent made, and cannot type.
                onAddFamily: app.router.isParentMode ? { showsFamilyEditor = true } : nil,
                topics: topicChoices,
                selectedTopicID: $chosenTopicID,
                onChangeMode: { goBack() }
            ) { companionID in
                chosenCompanionID = companionID
                begin()
            }
        case .preparing:
            StoryPreparationView(
                childName: profile?.name ?? "",
                modeTitle: chosenMode?.title,
                story: preparedStory,
                facts: preparationFacts,
                childColor: profile?.mpColor,
                onRead: { if let story = preparedStory { phase = .reading(story) } },
                onCancel: { dismiss() },
                awaitsApproval: preparedStory.map(awaitsApproval) ?? false
            )

        case .reading(let story):
            // Yeni yapılmış masal her zaman ilk sayfadan açılır.
            StoryReaderView(story: story, startingPage: 0)
                .environmentObject(app)
                .transition(.opacity)
        case .failed:
            StoryCreationFailureView(
                onRetry: { resetToModes() },
                onClose: { dismiss() },
                message: (failureReason ?? .general).message
            )
        }
    }

    /// "Masalları onayla" açıkken çocuğun yazdığı masal onay bekler. Ebeveyn
    /// alanında yazılan masalı ebeveyn zaten görüyor: o masal onaylı girer.
    private func awaitsApproval(_ story: Story) -> Bool {
        let settings = MPSettingsStore.shared
        return settings.approve && !settings.isApproved(story.id)
    }

    // MARK: - Choosing

    private var source: any StoryChoiceSource { StoryChoiceSources.current }

    /// The child's age. `MainContentView` never reaches this flow without a
    /// profile; the fallback is the MVP band's age only so previews render.
    private var age: Int { profile?.age ?? AgeBandResolver.mvp.upperBound }

    /// Bu bantta kurulabilen modlar. Uyku saatinde de üçü (15 Ekim 2026);
    /// Uyku öncesi yalnızca öne çıkar.
    private var allowedModes: [StoryMode] { source.availableModes(forAge: age) }

    /// Masal yazılmış bantlar, içerikten. Ekranda bir cümleye dönüşüyor.
    private var authoredBands: [AgeBand] { source.authoredBands() }

    /// Bu masalın çocuğu için masal yazılmış mı.
    ///
    /// Akışın her girişinde sorulur, bir kez değil: ebeveyn çocuk adımında
    /// desteklenmeyen bir kardeşe geçebilir ve o an da aynı cevap gerekir.
    private var supportsChosenChild: Bool {
        StoryCreationSteps.supportsAge(age, authored: authoredBands)
    }

    /// Masal yazılabilecek diğer çocuklar. Açıklama ekranı "başka bir çocuk
    /// seç" teklifini yalnızca bunlar varken yapıyor.
    private var supportedAlternatives: [UserProfile] {
        guard let id = profile?.id else { return [] }
        return StoryCreationSteps.supportedAlternatives(
            to: id, among: profiles, authored: authoredBands)
    }

    private func chooseMode(_ mode: StoryMode) {
        chosenMode = mode
        strategy = .direct
        chosenTopicID = nil
        phase = .companion
    }

    /// "Bana sürpriz yap": MagicPaper picks the mode, looking at what this
    /// child read last so the surprise is not a repeat.
    private func surprise() {
        guard let profile else { return dismiss() }
        do {
            chosenMode = try source.resolveMode(
                strategy: .surprise,
                requested: nil,
                forAge: age,
                recent: storyManager.recentModes(for: profile)
            )
            strategy = .surprise
            // Sürpriz başka soru sormaz: ebeveyn "sen seç" dedi. Konu ve arkadaş
            // boş kalınca motor bütün içerikten seçiyor, sürprizin istediği şey.
            chosenTopicID = nil
            chosenCompanionID = nil
            // `chosenMode`'un onChange'i `begin` sonrasına kalır; aile adayı
            // yeni moda göre şimdi süzülmeli.
            refreshFamilyRelations()
            begin()
        } catch {
            logger.error("Sürpriz mod seçilemedi: \(storyFailureDetail(error), privacy: .private)")
            failureReason = StoryFailureReason(error)
            phase = .failed
        }
    }

    // MARK: - Building

    /// The chosen Masal ailem character, if this mode can still carry it. A
    /// character chosen and then made unavailable by going back to another
    /// mode is dropped rather than failing the story.
    private var chosenFamily: FamilyCharacter? {
        guard let character = familyCharacters.first(where: { $0.id == chosenFamilyID }) else { return nil }
        return familyRelations.contains(character.relation.kind) ? character : nil
    }

    private func begin() {
        guard let profile else { return dismiss() }
        preparedStory = nil
        preparationFacts = nil
        phase = .preparing

        Task {
            do {
                let story = try await storyManager.createStory(
                    for: profile,
                    mode: chosenMode,
                    strategy: strategy,
                    storyIdeaID: nil,
                    companionID: chosenCompanionID,
                    subOption: chosenTopicID,
                    family: chosenFamily
                )
                if app.router.isParentMode && MPSettingsStore.shared.approve {
                    MPSettingsStore.shared.approveStory(story.id)
                }
                // Composition takes milliseconds; the preparation screen plays
                // the masal atölyesi and offers "Masalı oku" at the cover.
                preparationFacts = .gather(story: story, profile: profile, family: chosenFamily,
                                           isFirstRun: false)
                preparedStory = story
            } catch {
                // §29: the detail goes to the log, never to the parent.
                logger.error("Masal yazılamadı: \(storyFailureDetail(error), privacy: .private)")
                failureReason = StoryFailureReason(error)
                phase = .failed
            }
        }
    }
}
