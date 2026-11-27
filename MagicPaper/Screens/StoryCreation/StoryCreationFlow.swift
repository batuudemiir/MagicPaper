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
        /// "Neyi öğrenelim?" / "Nereye gidelim?" (19 Kasım 2026): yalnızca
        /// modun konusu varken.
        case topic
        case companion
        /// Okul öncesi "önce arkadaş" yolu (26 Kasım 2026, Batuhan K1-K4;
        /// kısaltma aynı gün: Kim → Ne yapalım → Kitap oluştur):
        /// hangi adımda olduğu `littlePath`'te. Yalnızca beşli bu çocuğa
        /// yazabildiğinde; yoksa okul öncesi akış bugünkü `.mode` sırasında.
        case little
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
    /// Özel günler (E6): bu çocuğun bugün etkin ve bu modda yazılabilen günleri.
    @State private var occasionChoices: [SpecialDayKind] = []
    @State private var chosenOccasion: SpecialDayKind?
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
    /// Okul öncesi "önce arkadaş" yolu ve onu besleyen listeler.
    @State private var littlePath = StoryCreationSteps.LittlePath()
    /// Beşlinin bu çocuğa en az bir modda yazabildiği arkadaşlar; boşsa yol yok.
    @State private var pilotFriends: [CompanionChoice] = []

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

    /// Adımların biçimi (`KidLevel`): okul öncesi çocukta resimli karolar.
    /// Ebeveyn alanında yazılan masalda hep yazılı adımlar: orada seçen ebeveyn
    /// ve konu ile "Yeni karakter" yalnızca o adımlarda var.
    private var level: KidLevel {
        app.router.isParentMode ? .big : (profile?.kidLevel ?? .big)
    }

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
            let topics = StoryChoiceSources.current.topicChoices(forAge: age, mode: mode)
            _topicChoices = State(initialValue: topics)
            _phase = State(initialValue: supported ? (topics.isEmpty ? .companion : .topic) : .unsupportedAge)
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
            enterLittleFriendFirstIfPossible()
        }
        .onChange(of: chosenMode) { _, _ in refreshFamilyRelations() }
        .onChange(of: chosenProfileID) { _, _ in
            chosenFamilyID = nil
            reloadFamily()
            refreshFamilyRelations()
            if phase == .little { phase = .mode }
            if phase == .mode && !supportsChosenChild { phase = .unsupportedAge }
            enterLittleFriendFirstIfPossible()
        }
    }

    /// Okul öncesi çocuk, ilk adımda ve beşli ona yazabiliyorsa "önce arkadaş"
    /// yoluna geçer. Ana sayfadan modla açılış (`preset`) ve ebeveyn alanı
    /// bugünkü gibi kalır: onlar `.mode`'dan açılmaz ya da `level` büyük.
    private func enterLittleFriendFirstIfPossible() {
        guard phase == .mode, level == .little else { return }
        pilotFriends = source.pilotFriendChoices(age: age)
        guard StoryCreationSteps.littleUsesFriendFirst(pilotFriends: pilotFriends,
                                                       hasPresetFamily: chosenFamilyID != nil) else { return }
        littlePath = StoryCreationSteps.LittlePath()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { phase = .little }
    }

    /// A mode change can make the chosen character's relation unavailable.
    /// The selection is cleared then, visibly (the chip is no longer
    /// selected), rather than kept and dropped silently at "Başla".
    private func refreshFamilyRelations() {
        familyRelations = Set(source.availableFamilyRelations(mode: chosenMode, age: age))
        topicChoices = chosenMode.map { source.topicChoices(forAge: age, mode: $0) } ?? []
        occasionChoices = Self.occasionChoices(
            active: profile.map { SpecialDayStore().activeKinds(for: $0.id) } ?? [],
            writable: chosenMode.map { source.occasionChoices(forAge: age, mode: $0) } ?? [])
        if let chosen = chosenOccasion, !occasionChoices.contains(chosen) { chosenOccasion = nil }
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
        case .child, .mode, .topic, .companion, .little: return true
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
                               accessibilityLabel: showsBack ? "Geri" : "Kapat",
                               // Okul öncesi yolda geri oku büyük: en az 2×2 cm.
                               size: phase == .little ? MPSize.kidBackLarge : MPSize.circleButton,
                               action: goBack)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, MPSpacing.screenH)
        .padding(.top, MPSpacing.sm)
        .padding(.bottom, MPSpacing.md)
    }

    private var showsBack: Bool {
        switch phase {
        case .topic, .companion: return true
        // Okul öncesi yol tek sayfa: seçimler yerinde değişir, geri adımı yok.
        case .little: return false
        default: return false
        }
    }

    /// Konu adımı bu modda var mı: noktalar ve "Geri" buna göre.
    private var hasTopicStep: Bool { !topicChoices.isEmpty }

    private var stepLabels: [String] {
        phase == .little ? littlePath.labels : StoryCreationSteps.stepLabels(hasTopicStep: hasTopicStep)
    }

    /// Nokta sırası etiket listesinden türetiliyor, elle sayılmıyor: iki yerde
    /// ayrı ayrı sayılsaydı bir adım eklendiğinde biri güncellenir öbürü
    /// unutulur ve "Adım 2 / 4" yanlış yazardı.
    private var stepIndex: Int? {
        switch phase {
        case .mode:      return stepLabels.firstIndex(of: "Masal")
        case .topic:     return stepLabels.firstIndex(of: "Konu")
        case .companion: return stepLabels.count - 1
        case .little:    return littlePath.stepIndex
        default:         return nil
        }
    }

    private func goBack() {
        switch phase {
        case .little:
            MPSpeech.shared.stop()
            dismiss()
        case .companion where hasTopicStep && strategy == .direct:
            chosenCompanionID = nil
            chosenTopicID = nil
            phase = .topic
        case .companion, .topic:
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
        case .mode where level == .little:
            LittleModeStep(
                modes: allowedModes,
                emphasized: StoryCreationSteps.emphasizedMode(allowedModes,
                                                              isBedtime: MPBedtime.isBedtime(settings: MPSettingsStore.shared)),
                profiles: profiles,
                authoredBands: authoredBands,
                selectedProfileID: $chosenProfileID,
                onChoose: chooseMode
            )
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
        case .topic:
            if let mode = chosenMode {
                TopicStep(
                    mode: mode, topics: topicChoices,
                    lockedTopicIDs: app.isUnlocked(.premiumWorlds) ? [] : Capability.lockedTopicIDs
                ) { topicID in
                    chosenTopicID = topicID
                    phase = .companion
                }
            }
        case .companion where level == .little:
            LittleCompanionStep(
                mode: chosenMode, age: age, topicID: chosenTopicID, source: source,
                familyCharacters: openFamilyCharacters,
                availableRelations: familyRelations
            ) { companionID, familyID in
                chosenCompanionID = companionID
                // Aile karosu seçilmediyse 14'ten gelen ön seçim yerinde kalır.
                if let familyID { chosenFamilyID = familyID }
                begin()
            }
        case .companion:
            CompanionStep(
                ideaID: nil, mode: chosenMode, age: age, topicID: chosenTopicID,
                childName: profile?.name ?? "",
                childColor: profile?.mpColor, source: source,
                familyCharacters: openFamilyCharacters,
                availableRelations: familyRelations,
                selectedFamilyID: $chosenFamilyID,
                // Free text is a parent's surface: in child mode the child
                // picks from the characters the parent made, and cannot type.
                // Masal ailem: ücretsizde bir kişi, fazlası abonelikle (20 Kasım 2026).
                onAddFamily: app.router.isParentMode
                    && app.isUnlocked(.familyCast, usage: .adding(existing: familyCharacters.count))
                    ? { showsFamilyEditor = true } : nil,
                occasions: occasionChoices,
                selectedOccasion: $chosenOccasion,
                onChangeMode: { goBack() }
            ) { companionID in
                chosenCompanionID = companionID
                begin()
            }
        case .little:
            littleContent
        case .preparing:
            StoryPreparationView(
                childName: profile?.name ?? "",
                modeTitle: chosenMode?.title,
                story: preparedStory,
                facts: preparationFacts,
                childColor: profile?.mpColor,
                onRead: { if let story = preparedStory { phase = .reading(story) } },
                onCancel: { dismiss() }
            )

        case .reading(let story):
            // Yeni yapılmış masal her zaman ilk sayfadan açılır.
            StoryReaderView(story: story, startingPage: 0)
                .environmentObject(app)
                .transition(.opacity)
        case .failed:
            StoryCreationFailureView(
                // "Tekrar dene" okul öncesi çocuğu yine arkadaştan başlatır.
                onRetry: { resetToModes(); enterLittleFriendFirstIfPossible() },
                onClose: { dismiss() },
                message: (failureReason ?? .general).message
            )
        }
    }

    // MARK: - Okul öncesi: önce arkadaş (26 Kasım 2026)

    /// Tek sayfa: seçim yapılınca sıradaki soru altta açılır (`LittleCreationPage`).
    private var littleContent: some View {
        LittleCreationPage(
            path: littlePath,
            friends: pilotFriends,
            friend: littleFriend,
            modes: littleModes,
            emphasized: StoryCreationSteps.emphasizedMode(
                littleModes, isBedtime: MPBedtime.isBedtime(settings: MPSettingsStore.shared)),
            newFriendIDs: littleNewFriendIDs,
            readAllModes: littleReadAllModes,
            profiles: profiles,
            authoredBands: authoredBands,
            selectedProfileID: $chosenProfileID,
            onChooseFriend: { apply(littlePath.chooseFriend($0)) },
            onChooseMode: { apply(littlePath.chooseMode($0)) },
            onStart: { apply(littlePath.start()) }
        )
    }

    /// Bu çocuğun beşliden hiç masal almadığı arkadaşlar (27 Kasım 2026).
    /// Hiç P56 masalı olmayan çocukta rozet yok: herkes yeni, rozet bir şey söylemez.
    private var littleNewFriendIDs: Set<String> {
        guard let profile else { return [] }
        let met = P56RecentBooks.metCompanionIDs(forChild: profile.id, in: storyManager.stories)
        guard !met.isEmpty else { return [] }
        return Set(pilotFriends.map(\.id)).subtracting(met)
    }

    /// Seçilen arkadaşla her kitabı bu çocuğa verilmiş modlar.
    private var littleReadAllModes: Set<StoryMode> {
        guard let profile, littlePath.step != .friend else { return [] }
        let recent = P56RecentBooks.ids(forChild: profile.id, in: storyManager.stories)
        guard !recent.isEmpty else { return [] }
        return Set(littleModes.filter { mode in
            P56RecentBooks.hasReadAll(source.pilotBookIDs(mode: mode, companionID: littlePath.companionID, age: age),
                                      recent: recent)
        })
    }

    /// Seçilen arkadaş; Sürpriz'de `nil`.
    private var littleFriend: CompanionChoice? {
        littlePath.companionID.flatMap { id in pilotFriends.first { $0.id == id } }
    }

    /// Beşlinin bu arkadaşla yazabildiği modlar; boşsa (olmaması gerekir) bandın modları.
    private var littleModes: [StoryMode] {
        let modes = source.pilotModes(forCompanionID: littlePath.companionID, age: age)
            .filter(allowedModes.contains)
        return modes.isEmpty ? allowedModes : modes
    }

    /// Yolun her dokunuşu buradan geçer: adım değişir, masal yalnızca `.begin`'de yazılır.
    private func apply(_ outcome: StoryCreationSteps.LittlePath.Outcome) {
        switch outcome {
        case .close:
            dismiss()
        case .show:
            break
        case .begin:
            guard let mode = littlePath.mode else { return }
            MPSpeech.shared.stop()
            chosenMode = mode
            strategy = .direct
            // Konu sorulmaz: istek beşliye gider, seçilen arkadaş masalda kalır.
            chosenTopicID = nil
            chosenCompanionID = littlePath.companionID
            chosenOccasion = nil
            refreshFamilyRelations()
            begin()
        }
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
        chosenOccasion = nil
        // `onChange(of: chosenMode)` sonra da tazeler; adım kararı şimdi gerekli.
        topicChoices = source.topicChoices(forAge: age, mode: mode)
        phase = topicChoices.isEmpty ? .companion : .topic
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
            // Sürpriz özel gün yazmaz: gün ebeveynin ya da çocuğun seçimidir.
            chosenOccasion = nil
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

    /// The chosen special day for the engine; a new sibling carries the
    /// sibling the parent picked, if it is still in the child's Masal ailem.
    private var chosenOccasionRequest: OccasionRequest? {
        guard let kind = chosenOccasion, let profile else { return nil }
        let day = SpecialDayStore().days(for: profile.id).first { $0.kind == kind }
        let sibling = day?.siblingID.flatMap { id in familyCharacters.first { $0.id == id } }
        return kind.request(sibling: sibling)
    }

    /// Chips: the child's active days the engine can write in this mode and
    /// age, in the store's order.
    static func occasionChoices(active: [SpecialDayKind], writable: [String]) -> [SpecialDayKind] {
        active.filter { writable.contains($0.occasionID) }
    }

    /// Masal ailem'den yeni masala katılabilecekler (20 Kasım 2026):
    /// ücretsizde ilk kişi, abonelikle hepsi. Diğerleri ve onlarla yazılmış
    /// masallar yerinde kalır, yalnızca yeni masala katılmaz.
    private var openFamilyCharacters: [FamilyCharacter] {
        familyCharacters.enumerated()
            .filter { app.isUnlocked(.familyCast, usage: .using(position: $0.offset)) }
            .map(\.element)
    }

    private func begin() {
        guard let profile else { return dismiss() }
        preparedStory = nil
        preparationFacts = nil
        phase = .preparing

        Task {
            // Kapak açılışı bitsin, sonra kur (kurulum ana iş parçacığında).
            try? await Task.sleep(for: .seconds(StoryPreparationScript.composeDelay))
            do {
                let story = try await storyManager.createStory(
                    for: profile,
                    mode: chosenMode,
                    strategy: strategy,
                    storyIdeaID: nil,
                    companionID: chosenCompanionID,
                    subOption: chosenTopicID,
                    family: chosenFamily,
                    occasion: chosenOccasionRequest
                )
                // E7: the story is in the library, so the free day closes (or a
                // trial star is spent). A subscriber spends nothing.
                LiveEntitlementService.shared.consume(.unlimitedTextStories)
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
