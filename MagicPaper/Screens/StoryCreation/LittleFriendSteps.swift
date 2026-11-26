import SwiftUI
import StoryEngine

// Okul öncesi "önce arkadaş" akışı (karar: 25-26 Kasım 2026, Batuhan K1-K4;
// `cocuk-akisi-is-tanimi.md`). Yalnızca beş arkadaş pilotu bu çocuğa yazabildiğinde:
// Kim gelsin? → {Arkadaş} ile ne yapalım? → (konu) → Hazır mısın?. Kararlar
// `StoryCreationSteps.LittlePath`'te; bu dosya yalnızca çizer.
//
// Ragi bu ekranlarda çizilmez (Ragi ve beşli aynı karede olmaz); soruyu sesle
// sorar. Satış, kilit notu, sayaç ve geri sayım yok.

/// Başlık + sağda büyük ses tekrar düğmesi. Soru ekran açılınca bir kez okunur;
/// önceki cümle (arkadaşın tanıtımı) bitmeden başlamaz.
struct LittleSpokenTitle: View {
    let title: String
    /// Okunan cümle; başlıktan uzun olabilir ("… Fark etmez dersen …").
    var spoken: String? = nil

    private var line: String { spoken ?? title }

    var body: some View {
        HStack(alignment: .center, spacing: MPSpacing.md) {
            CreationTitle(title: title)
            MPCircleButton(systemImage: "speaker.wave.2.fill", accessibilityLabel: "Soruyu yeniden dinle",
                           size: MPSize.kidBackLarge) {
                MPSpeech.shared.speak(line)
            }
        }
        .task(id: line) {
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
            .scaleEffect(isChosen && !reduceMotion ? 1.08 : 1)
            .animation(MP.M.gated(MP.M.spring), value: isChosen)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(accessibilityLabel ?? name)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }
}

/// 1 · Kim gelsin? Beş arkadaş sabit sırada ve Sürpriz; en çok altı karo.
struct LittleFriendStep: View {
    let friends: [CompanionChoice]
    var profiles: [UserProfile] = []
    var authoredBands: [AgeBand] = []
    @Binding var selectedProfileID: UUID?
    /// `nil`: Sürpriz.
    let onChoose: (String?) -> Void

    /// Dokunulan karo; tanıtım okunurken ikinci dokunuş yok sayılır.
    @State private var tapped: String??
    @Environment(\.dynamicTypeSize) private var typeSize

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
              count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    if StoryCreationSteps.showsChildPicker(profileCount: profiles.count) {
                        CreationChildPicker(profiles: profiles, authoredBands: authoredBands,
                                            selectedID: $selectedProfileID)
                    }
                    LittleSpokenTitle(title: LittleCreationCopy.friendQuestion)
                }

                LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                    ForEach(StoryCreationSteps.orderedLittleFriends(friends)) { friend in
                        LittleFriendTile(name: friend.name, companionID: friend.id,
                                         isChosen: tapped == .some(friend.id)) {
                            choose(friend.id, line: LittleCreationCopy.intro(for: friend.id, name: friend.name))
                        }
                    }
                    LittleFriendTile(name: "Sürpriz", companionID: nil, isChosen: tapped == .some(nil),
                                     accessibilityLabel: "Sürpriz, arkadaşı biz seçelim") {
                        choose(nil, line: LittleCreationCopy.surpriseIntro)
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
    }

    private func choose(_ id: String?, line: String) {
        guard tapped == nil else { return }
        tapped = .some(id)
        MPHaptics.selection()
        MPSpeech.shared.speak(line, pitch: LittleCreationCopy.pitch(for: id))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            onChoose(id)
            tapped = nil
        }
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

/// 2 · {Arkadaş} ile ne yapalım? Yalnızca beşlinin bu arkadaşla yazabildiği
/// modlar; akşam uyku kartı başta, "Bu akşam" notuyla.
struct LittleFriendModeStep: View {
    let friend: CompanionChoice?
    let modes: [StoryMode]
    var emphasized: StoryMode? = nil
    let onChoose: (StoryMode) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                LittleSpokenTitle(title: LittleCreationCopy.modeQuestion(friendName: friend?.name))

                VStack(spacing: MPSpacing.md) {
                    ForEach(StoryCreationSteps.shownModes(modes, emphasized: emphasized), id: \.self) { mode in
                        Button {
                            MPHaptics.selection()
                            onChoose(mode)
                        } label: {
                            HStack(spacing: MPSpacing.lg) {
                                LittleFriendModeArt(companionID: friend?.id, mode: mode)
                                VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                                    Text(mode.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if mode == emphasized {
                                        Text("Bu akşam").mpText(.footnote).foregroundStyle(MPColor.actionPrimary)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(MPSpacing.lg)
                            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 1.5)
                            .mpKidSurface(mode.tone.soft, edge: mode.tone.edge)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(MPPressStyle())
                        .accessibilityLabel(mode == emphasized
                                            ? "\(mode.title), bu akşam için önerilen" : mode.title)
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
    }
}

/// 4 · Hazır mısın? Seçilen arkadaş (ya da Sürpriz) ve mod; ortada büyük
/// "Başla". Masal yalnızca buradan yazılır.
struct LittleConfirmStep: View {
    let friend: CompanionChoice?
    /// `false`: masal seçilen arkadaşla yazılmayacak, portre yerine Sürpriz.
    let keepsFriend: Bool
    let mode: StoryMode
    let onStart: () -> Void

    private var shownFriend: CompanionChoice? { keepsFriend ? friend : nil }

    private var spoken: String {
        LittleCreationCopy.confirmLine(friendName: friend?.name, keepsFriend: keepsFriend, mode: mode)
            + " " + LittleCreationCopy.startLine
    }

    /// Görünen yükseklik: kartlar ve "Başla" başlığın altındaki boşlukta
    /// dikeyde ortalanır, sayfanın tepesine yığılmaz (26 Kasım 2026, Batuhan).
    /// En büyük yazıda içerik sığmazsa sayfa kayar, düzen bugünkü gibi üstten.
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MPSpacing.xxl) {
                LittleSpokenTitle(title: LittleCreationCopy.confirmTitle, spoken: spoken)

                Spacer(minLength: 0)

                HStack(spacing: MPSpacing.md) {
                    LittleFriendTile(name: shownFriend?.name ?? "Sürpriz", companionID: shownFriend?.id,
                                     accessibilityLabel: shownFriend.map { "\($0.name) geliyor" }
                                         ?? "Sürpriz bir arkadaş geliyor") {}
                        .allowsHitTesting(false)
                    VStack(spacing: MPSpacing.sm) {
                        MPIcon(mode.symbol, size: MP.G.hero, weight: .semibold)
                            .foregroundStyle(mode.tone.deep)
                            .frame(width: MPSize.littlePortrait, height: MPSize.littlePortrait)
                            .accessibilityHidden(true)
                        Text(mode.title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(MPSpacing.md)
                    .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 2)
                    .mpKidSurface(mode.tone.soft, edge: mode.tone.edge)
                    .accessibilityElement(children: .combine)
                }

                MPButton(title: "Başla", systemImage: "play.fill", size: .hero) {
                    MPHaptics.selection()
                    onStart()
                }
                .accessibilityHint(spoken)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
            .frame(minHeight: viewportHeight, alignment: .top)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
    }
}
