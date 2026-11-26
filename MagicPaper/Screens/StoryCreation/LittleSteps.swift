import SwiftUI
import StoryEngine

// Okul öncesi kademe (`KidLevel.little`) için masal yazma adımları
// (karar: 14 Kasım 2026, Batuhan).
//
// Aynı iki soru, aynı sıra: "Nasıl bir masal olsun?" ve "Kim gelsin?". Fark
// seçimin biçiminde: okuyamayan çocuk büyük resme dokunur ve dokunuş adımı
// geçer. Alt satır ve "Masalı yaz" düğmesi yok; konu kendi adımında
// (`TopicStep`, iki kademede ortak), seçilmeyen her şeyi MagicPaper seçer. Kurallar (`StoryCreationSteps`, aday süzme,
// Masal ailem ilişkileri) okuyan çocuğun adımlarıyla ortak.

/// Büyük resimli seçim karosu: simge, altında tek kısa ad.
struct LittleChoiceTile: View {
    let title: String
    let systemImage: String
    var tone: MPWorldTone = .lav
    /// Karonun altındaki tek kısa not ("Bu akşam").
    var note: String? = nil
    var accessibilityLabel: String? = nil
    /// Yol arkadaşı karosu: çizilmiş portresi varsa simge yerine o görünür
    /// (Tarçın tilkidir, köpek simgesi değil). Portresi olmayan simgede kalır.
    var companionID: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                Group {
                    if let companionID {
                        MPCompanionPortrait(companionID: companionID, fallbackSymbol: systemImage,
                                            size: MPSize.minTouchHero)
                    } else {
                        MPIcon(systemImage, size: MP.G.hero, weight: .semibold)
                            .foregroundStyle(tone.deep)
                    }
                }
                // Simgelerin boyu farklı: sabit kutu, yan yana karolar eşit dursun.
                .frame(width: MPSize.minTouchHero, height: MPSize.minTouchHero)
                .accessibilityHidden(true)
                Text(title).mpText(.cardTitle).foregroundStyle(MPColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if let note {
                    Text(note).mpText(.footnote).foregroundStyle(MPColor.actionPrimary)
                }
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: MPSize.minTouchHero * 2)
            .mpKidSurface(tone.soft, edge: tone.edge)
            .contentShape(Rectangle())
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

/// Birinci adım: üç mod, üç büyük karo. Dokununca geçilir.
struct LittleModeStep: View {
    let modes: [StoryMode]
    var emphasized: StoryMode? = nil
    var profiles: [UserProfile] = []
    var authoredBands: [AgeBand] = []
    @Binding var selectedProfileID: UUID?
    let onChoose: (StoryMode) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                VStack(alignment: .leading, spacing: MPSpacing.sm) {
                    if StoryCreationSteps.showsChildPicker(profileCount: profiles.count) {
                        CreationChildPicker(profiles: profiles, authoredBands: authoredBands,
                                            selectedID: $selectedProfileID)
                    }
                    CreationTitle(title: "Nasıl bir masal olsun?")
                }

                VStack(spacing: MPSpacing.md) {
                    ForEach(StoryCreationSteps.shownModes(modes, emphasized: emphasized), id: \.self) { mode in
                        LittleChoiceTile(
                            title: mode.title, systemImage: mode.symbol, tone: mode.tone,
                            note: mode == emphasized ? "Bu akşam" : nil,
                            accessibilityLabel: mode == emphasized
                                ? "\(mode.title), bu akşam için önerilen" : mode.title
                        ) {
                            MPHaptics.selection()
                            onChoose(mode)
                        }
                    }
                }

                // Akışın tek Ragi'si; "Kim gelsin?" adımı sessiz (23 Ekim 2026).
                MascotSays(mascot: .pencil, text: "Birine dokun!", mascotWidth: 72)
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
    }
}

/// İkinci adım: "Kim gelsin?". Yol arkadaşları, Masal ailem ve sürpriz aynı
/// ızgarada; bir karoya dokunmak masalı yazdırır.
struct LittleCompanionStep: View {
    var mode: StoryMode? = nil
    var age: Int? = nil
    /// Konu adımında seçilen konu (19 Kasım 2026); `nil` ise MagicPaper seçer.
    var topicID: String? = nil
    var source: any StoryChoiceSource = StoryChoiceSources.current
    var familyCharacters: [FamilyCharacter] = []
    var availableRelations: Set<FamilyRelationKind> = []
    /// Yol arkadaşı ya da Masal ailem'den biri; ikisi de `nil` ise MagicPaper seçer.
    let onChoose: (_ companionID: String?, _ familyID: UUID?) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    /// Kaynak hazır olunca artar; adaylar yeniden sorulur (beş arkadaş pilotu).
    @State private var readyTick = 0
    /// Kaynak hazır olmadan bir karoya dokunuldu: son liste bekleniyor.
    @State private var isWaiting = false

    /// Izgara altı karoyu geçmesin: arkadaşlar, en çok iki aile, bir sürpriz.
    /// Arkadaş sayısını kaynak söyler (bugün üç; beş arkadaş pilotunda beş, B5).
    static let maxTiles = 6
    private static let shownFamily = 2

    static func shownCompanions(limit: Int, familyCount: Int) -> Int {
        max(0, min(limit, maxTiles - 1 - familyCount))
    }

    /// Adaylar moda, yaşa ve (seçildiyse) konuya göre süzülür.
    private var candidates: [CompanionChoice] {
        _ = readyTick
        let limit = source.companionDisplayLimit(forIdeaID: nil, age: age, mode: mode, topicID: topicID, family: nil)
        return Array(source.companionChoices(forIdeaID: nil, mode: mode, age: age, topicID: topicID, family: nil)
            .prefix(Self.shownCompanions(limit: limit, familyCount: family.count)))
    }

    /// Yalnızca bu modun taşıyabildiği karakterler: seçilemeyen karo gösterilmez.
    private var family: [FamilyCharacter] {
        Array(familyCharacters.filter { availableRelations.contains($0.relation.kind) }
            .prefix(Self.shownFamily))
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: MPSpacing.md),
              count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                CreationTitle(title: "Kim gelsin?")

                LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                    ForEach(candidates) { companion in
                        LittleChoiceTile(title: companion.name,
                                         systemImage: CompanionStep.symbol(forType: companion.kind),
                                         tone: .lav, companionID: companion.id) {
                            MPHaptics.selection()
                            choose(companion.id, nil)
                        }
                    }
                    ForEach(family) { character in
                        LittleChoiceTile(
                            title: character.name,
                            systemImage: FamilyCharacterCopy.relationSymbol(character.relation.kind),
                            tone: .peach,
                            accessibilityLabel: "\(character.name), \(FamilyCharacterCopy.relation(character.relation.kind))"
                        ) {
                            MPHaptics.selection()
                            choose(nil, character.id)
                        }
                    }
                    LittleChoiceTile(title: "Sürpriz", systemImage: "wand.and.sparkles", tone: .yellow,
                                     accessibilityLabel: "Sürpriz, arkadaşı biz seçelim") {
                        MPHaptics.selection()
                        choose(nil, nil)
                    }
                }
                .disabled(isWaiting)
                .overlay {
                    if isWaiting {
                        ProgressView()
                            .controlSize(.large)
                            .tint(MPColor.actionPrimary)
                            .accessibilityLabel("Arkadaşlar hazırlanıyor")
                    }
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.top, MPSpacing.sm)
            .padding(.bottom, MPSpacing.xxxl)
        }
        // Izgara beklemeden görünür; kaynak hazır olunca son haline döner.
        .task {
            guard !source.isReady else { return }
            await source.waitUntilReady()
            readyTick += 1
        }
    }

    /// Kaynak hazırsa hemen yazar. Değilse kısa bir bekleme: son liste gelince
    /// seçilen arkadaş hâlâ ızgaradaysa yazar, değilse ızgara yenilenir ve
    /// çocuk yeniden seçer. Masal ailem ve sürpriz beklemez.
    private func choose(_ companionID: String?, _ familyID: UUID?) {
        guard let companionID, !source.isReady else { onChoose(companionID, familyID); return }
        isWaiting = true
        Task {
            await source.waitUntilReady()
            readyTick += 1
            isWaiting = false
            if candidates.contains(where: { $0.id == companionID }) { onChoose(companionID, nil) }
        }
    }
}
