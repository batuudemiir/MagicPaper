import SwiftUI
import StoryEngine

/// 14 · Masal ailem (`MasalAilem`): çocuğun tekrar eden karakterleri ve kaç
/// masalda göründükleri (FAZ 11). Benim köşem'den açılır. Kahraman kartı tam
/// genişlik, diğerleri iki sütun, "Yeni karakter" kesikli kart. Bir masal tek
/// bir Masal ailem karakteri taşıdığı için seçim tek (tasarımda çoklu);
/// "Bu karakterle masal yaz" Yarat'ı o karakter seçili açar. Düzenleyici aynı
/// katmanda, listenin yerine açılır.
struct FamilyCharactersView: View {
    let profile: UserProfile

    @EnvironmentObject private var app: MPAppState
    @ObservedObject private var storyManager = StoryGenerationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize

    private enum Mode: Equatable {
        case list
        case adding
        case editing(FamilyCharacter)
    }

    @State private var mode: Mode = .list
    /// Görmek ve seçmek serbest; ekleme, düzenleme ve silme çocuk modunda
    /// ebeveyn kapısından geçer (karar 16 Ekim 2026, FAZ 11 kuralıyla uyumlu).
    @State private var characters: [FamilyCharacter] = []

    private let store = FamilyCharacterStore()
    private var source: any StoryChoiceSource { StoryChoiceSources.current }

    var body: some View {
        Group {
            switch mode {
            case .list:
                list
            case .adding:
                editor(nil)
            case .editing(let character):
                editor(character)
            }
        }
        .onAppear(perform: reload)
    }

    /// Masal ailem'e ekleme ve düzenleme kapıdan geçer: ad yazmak ve silmek
    /// ebeveynin işi. Kitap karakterinin görünüşü kapısız (14 Kasım 2026).
    /// Ebeveyn modunda doğrudan çalışır.
    private func guarded(_ action: @escaping () -> Void) {
        app.router.requestGate(then: action)
    }

    /// 14: bir masal tek bir Masal ailem karakteri taşır, seçim tek.
    @State private var selectedID: UUID?
    private static let tones: [MPWorldTone] = [.peach, .sky, .lav, .yellow, .mint, .pink, .green]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: MPSpacing.sm), count: 2)

    /// Çocuk alanında menü sayfalarının ortak çatısı (23 Kasım 2026): mor gök,
    /// göğün altında kahraman kartı, karakterler beyaz zeminde pastel karelerle.
    /// Ebeveyn alanında aynı içerik `MPParentHeader` altında, Ragi'siz.
    @ViewBuilder
    private var list: some View {
        Group {
            if app.router.isParentMode {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                        MPParentHeader(title: FamilyCharacterCopy.screenTitle,
                                       subtitle: "Masallarında tekrar görünen karakterler",
                                       onBack: { app.router.closeKidPage() })
                        VStack(alignment: .leading, spacing: MPSpacing.xxl) {
                            heroCard
                            listContent
                        }
                        .padding(.horizontal, MPSpacing.screenH)
                    }
                    .padding(.bottom, MPSpacing.xxxl)
                }
                .background(MPColor.backgroundSurface.ignoresSafeArea())
            } else {
                MPSkyPage(title: FamilyCharacterCopy.screenTitle, bottomPadding: MPSpacing.xxxl,
                          onBack: { app.router.closeKidPage() }) {
                    heroCard
                } content: {
                    listContent
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { selectedBar }
        .animation(MP.M.gated(MP.M.base), value: selectedID)
    }

    @ViewBuilder
    private var listContent: some View {
        let kinds = source.familyAnimalKindChoices()
        let full = characters.count >= FamilyCharacter.maxPerChild
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            MPSectionHeader(title: FamilyCharacterCopy.profileRowDescription)
            LazyVGrid(columns: columns, spacing: MPSpacing.sm) {
                ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                    card(character, kinds: kinds, tone: Self.tones[index % Self.tones.count])
                }
                if !full { addTile }
            }
            if characters.isEmpty {
                Text(FamilyCharacterCopy.emptyDescription)
                    .mpText(.body).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if full {
                Text(FamilyCharacterCopy.limitReached)
                    .mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Ebeveyn alanında Ragi yok (Design law); çocuk sayfasının tek Ragi'si.
        if !app.router.isParentMode {
            MascotSays(mascot: .waving,
                       text: full ? FamilyCharacterCopy.ragiFull : FamilyCharacterCopy.ragiInvite,
                       mascotWidth: 72)
        }
    }

    /// Seçili karakterin alt çubuğu: "Bu karakterle masal yaz".
    @ViewBuilder
    private var selectedBar: some View {
        if let selected = characters.first(where: { $0.id == selectedID }) {
            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: MPSpacing.lg) {
                    Text("\(selected.name) seçili").mpText(.supporting).foregroundStyle(MPColor.textSecondary)
                    Button("Düzenle") { guarded { mode = .editing(selected) } }
                        .mpText(.supporting).foregroundStyle(MPColor.actionPrimary)
                        .frame(minHeight: MPSize.minTouchParent)
                }
                MPButton(title: "Bu karakterle masal yaz", systemImage: "wand.and.sparkles", fullWidth: true) {
                    app.router.closeKidPage()
                    app.startStoryCreation(family: selected.id)
                }
            }
            .padding(.horizontal, MPSpacing.screenH)
            .padding(.vertical, MPSpacing.md)
            .frame(maxWidth: .infinity)
            .background(MPColor.backgroundSurface)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    /// Çocuğun kendisi: her masalda kahraman. Ana sayfanın hero kartı gibi
    /// sayfanın tek dolgun mor yüzeyi. "Düzenle" kahraman oluşturucuya gider
    /// (görselli kitap açıkken).
    private var heroCard: some View {
        HStack(spacing: MPSpacing.lg) {
            // Profildeki yüzün aynısı (seçilen avatar ya da kahraman; 24 Kasım 2026).
            Group {
                if let look = HeroLookStore().look(for: profile.id) {
                    HeroAvatarView(look: look, backdrop: MPWorldTone.lav.soft)
                        .frame(width: 64, height: 64)
                } else {
                    MPAvatar(name: profile.name, color: profile.mpColor, size: 64)
                }
            }
            .padding(MPSpacing.xxs)
            .background(MPWorldTone.lav.soft, in: Circle())
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: MPSpacing.xxs) {
                Text("Kahraman").mpText(.eyebrow).foregroundStyle(MPColor.actionPrimary)
                Text(profile.name).mpText(.section).foregroundStyle(MPColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Her masalda").mpText(.footnote).foregroundStyle(MPColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if IllustratedBookAccess.isEnabled() {
                MPButton(title: "Düzenle", kind: .secondary, size: .small) { app.router.openKidPage(.bookCharacter(profile.id)) }
                    .accessibilityLabel("Kahramanı düzenle")
            }
        }
        .padding(MPSpacing.lg)
        // Göğün altında beyaz tanıtım kartı (menü sayfalarıyla aynı, 23 Kasım 2026).
        .mpKidSurface(MPColor.backgroundSurface, edge: MPWorldTone.lav.edge)
        .accessibilityElement(children: .combine)
    }

    /// "Yeni karakter": karakter kareleriyle aynı ölçüde, kesikli çerçeveli.
    private var addTile: some View {
        // Ücretsizde bir kişi, fazlası abonelikle (20 Kasım 2026); var olanlar
        // düzenlenebilir ve kalır.
        Button {
            app.unlock(.familyCast, usage: .adding(existing: characters.count)) { guarded { mode = .adding } }
        } label: {
            VStack(spacing: MPSpacing.sm) {
                MPIcon("plus", size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(MPColor.actionPrimary)
                    .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                    .background(MPWorldTone.lav.soft, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                Text(FamilyCharacterCopy.addButton).mpText(.supporting).foregroundStyle(MPColor.actionPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 168)
            .overlay(RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous)
                .strokeBorder(MPColor.borderDashed, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
        }
        .buttonStyle(MPPressStyle())
    }

    /// Karakter karesi: ana sayfanın mod düğmesi gibi kenarsız pastel zemin,
    /// beyaz kutuda ikon. Seçim mor halka ve tik ile (renge ek olarak tik).
    private func card(_ character: FamilyCharacter, kinds: [FamilyAnimalKindChoice], tone: MPWorldTone) -> some View {
        let count = FamilyCharacterAppearances.count(of: character.id, in: storyManager.stories)
        let relation = FamilyCharacterCopy.relationLine(character.relation, kinds: kinds)
        let isSelected = selectedID == character.id
        let shape = RoundedRectangle(cornerRadius: MPRadius.input, style: .continuous)
        return Button {
            MPHaptics.selection()
            selectedID = isSelected ? nil : character.id
        } label: {
            VStack(spacing: MPSpacing.sm) {
                MPIcon(FamilyCharacterCopy.relationSymbol(character.relation.kind), size: MP.G.xl, weight: .semibold)
                    .foregroundStyle(tone.deep)
                    .frame(width: MPSize.iconTile, height: MPSize.iconTile)
                    .background(MPColor.backgroundSurface, in: RoundedRectangle(cornerRadius: MPRadius.md, style: .continuous))
                Text(character.name).mpText(.section).foregroundStyle(MPColor.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
                // İki ayrı satır: kareler aynı satırda aynı yükseklikte kalır.
                VStack(spacing: 0) {
                    Text(relation).mpText(.footnote).foregroundStyle(MPColor.textPrimary)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    Text(FamilyCharacterCopy.appearances(count)).mpText(.footnote).foregroundStyle(MPColor.textSecondary)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                }
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
            }
            .padding(MPSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 168, alignment: .top)
            .background(tone.soft, in: shape)
            .overlay { shape.strokeBorder(isSelected ? MPColor.actionPrimary : .clear, lineWidth: 3) }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    MPIcon("checkmark", size: MP.G.xs, weight: .heavy)
                        .foregroundStyle(MPColor.textOnAction)
                        .frame(width: 24, height: 24)
                        .background(MPColor.actionPrimary, in: Circle())
                        .padding(MPSpacing.sm)
                }
            }
        }
        .buttonStyle(MPPressStyle())
        .accessibilityLabel(FamilyCharacterCopy.rowAccessibility(name: character.name, relation: relation, count: count))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: "Düzenle") { guarded { mode = .editing(character) } }
    }

    private func editor(_ character: FamilyCharacter?) -> some View {
        FamilyCharacterEditor(
            childID: profile.id,
            childName: profile.name,
            editing: character,
            onClose: { mode = .list },
            onSaved: { _ in
                app.showToast(character == nil ? FamilyCharacterCopy.saved : FamilyCharacterCopy.updated)
                reload()
                mode = .list
            },
            onRemoved: {
                app.showToast(FamilyCharacterCopy.removed, symbol: "minus.circle")
                reload()
                mode = .list
            }
        )
    }

    private func reload() {
        characters = store.characters(for: profile.id)
    }
}
