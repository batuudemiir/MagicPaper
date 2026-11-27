import SwiftUI
import StoryEngine

// Okul öncesi "önce arkadaş" akışı (karar: 25-26 Kasım 2026, Batuhan K1-K4;
// `cocuk-akisi-is-tanimi.md`). Yalnızca beş arkadaş pilotu bu çocuğa yazabildiğinde:
// Kim gelsin? → {Arkadaş} ile ne yapalım? → Kitap oluştur (kısaltma: 26 Kasım
// 2026, Batuhan; konu adımı ve "Hazır mısın?" kalktı). Kararlar
// `StoryCreationSteps.LittlePath`'te; bu dosya yalnızca çizer.
//
// Ragi bu ekranlarda çizilmez (Ragi ve beşli aynı karede olmaz); soruyu sesle
// sorar. Satış, kilit notu, sayaç ve geri sayım yok.

/// Başlık + sağda büyük ses tekrar düğmesi. Cümle ekran açılınca bir kez
/// okunur (stüdyo kaydı varsa o); önceki cümle (arkadaşın tanıtımı) bitmeden başlamaz.
struct LittleSpokenTitle: View {
    /// Okunan cümle; başlık da onun metni.
    let line: MPVoiceLine

    var body: some View {
        HStack(alignment: .center, spacing: MPSpacing.md) {
            CreationTitle(title: line.text)
            MPCircleButton(systemImage: "speaker.wave.2.fill", accessibilityLabel: "Soruyu yeniden dinle",
                           size: MPSize.kidBackLarge) {
                MPSpeech.shared.speak(line)
            }
        }
        .task(id: line.key + line.text) {
            // Tanıtım cümlesi sürüyorsa soruyu onun üstüne söyleme (en çok ~4 sn bekle).
            for _ in 0..<20 where MPSpeech.shared.isSpeaking {
                try? await Task.sleep(for: .milliseconds(200))
            }
            guard !Task.isCancelled else { return }
            MPSpeech.shared.speak(line)
        }
    }
}

/// Bir arkadaşın büyük portre karosu. Dokununca büyür (Hareketi Azalt'ta
/// yalnızca çerçeve) ve adı altında.
struct LittleFriendTile: View {
    let name: String
    /// `nil`: Sürpriz karosu.
    let companionID: String?
    var isChosen = false
    /// Bu çocuğun henüz tanışmadığı arkadaş: köşede "Yeni" (27 Kasım 2026).
    var isNew = false
    var accessibilityLabel: String? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                Group {
                    if let companionID {
                        MPCompanionPortrait(companionID: companionID, fallbackSymbol: "pawprint.fill",
                                            size: MPSize.littlePortrait)
                    } else {
                        MPIcon("wand.and.sparkles", size: MP.G.hero, weight: .semibold)
                            .foregroundStyle(MPWorldTone.yellow.deep)
                            .frame(width: MPSize.littlePortrait, height: MPSize.littlePortrait)
                            .accessibilityHidden(true)
                    }
                }
                Text(name).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 2)
            .mpKidSurface(companionID == nil ? MPWorldTone.yellow.soft : MPWorldTone.lav.soft,
                          edge: companionID == nil ? MPWorldTone.yellow.edge : MPWorldTone.lav.edge)
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous)
                    .strokeBorder(isChosen ? MPColor.actionPrimary : .clear, lineWidth: 4)
            }
            .overlay(alignment: .topTrailing) {
                if isNew {
                    Text(LittleCreationCopy.newFriendBadge).mpText(.footnote)
                        .foregroundStyle(MPColor.textPrimary)
                        .padding(.horizontal, MPSpacing.sm)
                        .padding(.vertical, MPSpacing.xxs)
                        .background(Capsule().fill(MPWorldTone.yellow.soft))
                        .overlay(Capsule().strokeBorder(MPWorldTone.yellow.edge, lineWidth: 1))
                        .padding(MPSpacing.sm)
                        .accessibilityHidden(true)
                }
            }
            .scaleEffect(isChosen && !reduceMotion ? 1.08 : 1)
            .animation(MP.M.gated(MP.M.spring), value: isChosen)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel((accessibilityLabel ?? name) + (isNew ? ", \(LittleCreationCopy.newFriendBadge)" : ""))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// Okul öncesi yolun tek sayfası (26 Kasım 2026, Batuhan: "seçilince aşağıya
/// kaysın, sayfa sayfa yapmak yerine"). Üç bölüm alt alta: Kim gelsin? →
/// {Arkadaş} ile ne yapalım? → Kitap oluştur. Bir seçim yapılınca sıradaki
/// bölüm altta açılır ve sayfa oraya kayar; yapılan seçimler yukarıda seçili
/// kalır, dokunarak değiştirilir. Adım `StoryCreationSteps.LittlePath`'te;
/// bu görünüm yalnızca çizer ve kaydırır.
struct LittleCreationPage: View {
    let path: StoryCreationSteps.LittlePath
    let friends: [CompanionChoice]
    /// Seçilen arkadaş; Sürpriz'de `nil`.
    let friend: CompanionChoice?
    let modes: [StoryMode]
    var emphasized: StoryMode? = nil
    /// Bu çocuğun henüz masalını almadığı arkadaşlar ("Yeni").
    var newFriendIDs: Set<String> = []
    /// Seçilen arkadaşla (Sürpriz'de herhangi biriyle) her kitabı okunmuş
    /// modlar: kartta ebeveyne kısa not, motor en eski okunanı verir.
    var readAllModes: Set<StoryMode> = []
    var profiles: [UserProfile] = []
    var authoredBands: [AgeBand] = []
    @Binding var selectedProfileID: UUID?
    /// `nil`: Sürpriz.
    let onChooseFriend: (String?) -> Void
    let onChooseMode: (StoryMode) -> Void
    let onStart: () -> Void

    private enum Section: Hashable { case friend, mode, start }

    /// Dokunulan karo; tanıtım okunurken ikinci dokunuş yok sayılır.
    @State private var tapped: String??
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
              count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    private var showsModes: Bool { path.step != .friend }
    private var showsStart: Bool { path.step == .start && path.mode != nil }

    /// Arkadaş seçildiyse onun karosu seçili görünür (Sürpriz dahil).
    private func isChosenFriend(_ id: String?) -> Bool {
        if tapped != nil { return tapped == .some(id) }
        return showsModes && path.companionID == id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MPSpacing.xxxl) {
                    friendSection.id(Section.friend)
                    if showsModes {
                        modeSection.id(Section.mode)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    if showsStart, let mode = path.mode {
                        startSection(mode).id(Section.start)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, MPSpacing.screenH)
                .padding(.top, MPSpacing.sm)
                .padding(.bottom, MPSpacing.xxxl)
            }
            .animation(MP.M.gated(MP.M.page), value: path)
            .onChange(of: path.step) { _, step in
                let target: Section = switch step {
                case .friend: .friend
                case .mode: .mode
                case .start: .start
                }
                // Bölüm çizildikten sonra kaydır: yeni bölüm o an ekranda yok.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(MP.M.RagiBeat.frame * 3))
                    withAnimation(MP.M.gated(MP.M.slow)) { proxy.scrollTo(target, anchor: .top) }
                }
            }
        }
    }

    // MARK: - 1 · Kim gelsin?

    private var friendSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xl) {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                if StoryCreationSteps.showsChildPicker(profileCount: profiles.count) {
                    CreationChildPicker(profiles: profiles, authoredBands: authoredBands,
                                        selectedID: $selectedProfileID)
                }
                LittleSpokenTitle(line: LittleCreationCopy.friendQuestion)
            }

            LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                ForEach(StoryCreationSteps.orderedLittleFriends(friends)) { friend in
                    LittleFriendTile(name: friend.name, companionID: friend.id,
                                     isChosen: isChosenFriend(friend.id),
                                     isNew: newFriendIDs.contains(friend.id)) {
                        chooseFriend(friend.id, line: LittleCreationCopy.intro(for: friend.id, name: friend.name))
                    }
                }
                LittleFriendTile(name: "Sürpriz", companionID: nil, isChosen: isChosenFriend(nil),
                                 accessibilityLabel: "Sürpriz, arkadaşı biz seçelim") {
                    chooseFriend(nil, line: LittleCreationCopy.surpriseIntro)
                }
            }
        }
    }

    private func chooseFriend(_ id: String?, line: MPVoiceLine) {
        guard tapped == nil else { return }
        tapped = .some(id)
        MPHaptics.selection()
        MPSpeech.shared.speak(line)
        Task { @MainActor in
            // Karo büyüsün ve tanıtım başlasın; sonra sıradaki soru açılır.
            try? await Task.sleep(for: .seconds(reduceMotion ? MP.M.RagiBeat.reveal : 0.8))
            onChooseFriend(id)
            tapped = nil
        }
    }

    // MARK: - 2 · Ne yapalım?

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.xl) {
            LittleSpokenTitle(line: LittleCreationCopy.modeQuestion(friendName: friend?.name,
                                                                    companionID: friend?.id))
            VStack(spacing: MPSpacing.md) {
                ForEach(StoryCreationSteps.shownModes(modes, emphasized: emphasized), id: \.self) { mode in
                    modeCard(mode)
                }
            }
        }
    }

    private func modeCard(_ mode: StoryMode) -> some View {
        let isChosen = showsStart && path.mode == mode
        return Button {
            MPHaptics.selection()
            onChooseMode(mode)
        } label: {
            HStack(spacing: MPSpacing.lg) {
                LittleFriendModeArt(companionID: friend?.id, mode: mode)
                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                    LittleCardTitle(text: mode.title, alignment: .leading)
                    if mode == emphasized {
                        Text("Bu akşam").mpText(.footnote).foregroundStyle(MPColor.actionPrimary)
                    }
                    if readAllModes.contains(mode) {
                        Text(LittleCreationCopy.readAllNote).mpText(.footnote)
                            .foregroundStyle(MPColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if isChosen {
                    MPIcon("checkmark.circle.fill", size: MP.G.lg, weight: .semibold)
                        .foregroundStyle(MPColor.actionPrimary)
                        .accessibilityHidden(true)
                }
            }
            .padding(MPSpacing.lg)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 1.5)
            .mpKidSurface(mode.tone.soft, edge: mode.tone.edge)
            .overlay {
                RoundedRectangle(cornerRadius: MPRadius.tile, style: .continuous)
                    .strokeBorder(isChosen ? MPColor.actionPrimary : .clear, lineWidth: 4)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel([mode.title, mode == emphasized ? "bu akşam için önerilen" : nil,
                             readAllModes.contains(mode) ? LittleCreationCopy.readAllNote : nil]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    // MARK: - 3 · Kitap oluştur

    /// Soru yok ("Hazır mısın?" kalktı): kim geldiğini ve ne yapıldığını söyleyen
    /// tek cümle ve büyük "Kitap oluştur". Masal yalnızca buradan yazılır.
    private func startSection(_ mode: StoryMode) -> some View {
        let line = LittleCreationCopy.startLine(friendName: friend?.name, companionID: friend?.id, mode: mode)
        return VStack(spacing: MPSpacing.xl) {
            LittleSpokenTitle(line: line)
            MPButton(title: LittleCreationCopy.startButton, systemImage: "book.fill", size: .hero) {
                MPHaptics.selection()
                onStart()
            }
            .accessibilityHint(line.text)
        }
        .frame(maxWidth: .infinity)
        // Düğme alt kenara yapışmasın: altında bir ekranlık nefes (tasarım
        // yasası: okul öncesinde alt kenarda aktif hedef yok).
        .padding(.bottom, MPSpacing.xxxl)
    }
}

/// Portre ve mod simgesi yan yana (çizim gelene kadar); Sürpriz'de yalnızca simge.
struct LittleFriendModeArt: View {
    let companionID: String?
    let mode: StoryMode

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            if let companionID {
                MPCompanionPortrait(companionID: companionID, fallbackSymbol: "pawprint.fill",
                                    size: MPSize.minTouchHero)
            }
            MPIcon(mode.symbol, size: MP.G.hero, weight: .semibold)
                .foregroundStyle(mode.tone.deep)
                .frame(width: MPSize.minTouchHero, height: MPSize.minTouchHero)
        }
        .accessibilityHidden(true)
    }
}

/// Kart adı: sığarsa tek satır; sığmazsa her kelime kendi satırında ve
/// gerekirse küçülür. Kelime ortasından kırılmaz ("Macera / ya", en büyük
/// yazıda; 26 Kasım 2026).
private struct LittleCardTitle: View {
    let text: String
    var alignment: HorizontalAlignment = .center

    var body: some View {
        ViewThatFits(in: .horizontal) {
            line(text)
            VStack(alignment: alignment, spacing: 0) {
                ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                    line(String(word))
                }
            }
        }
        .foregroundStyle(MPColor.textPrimary)
    }

    private func line(_ string: String) -> some View {
        Text(string).mpText(.cardTitle)
            .multilineTextAlignment(alignment == .leading ? .leading : .center)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
